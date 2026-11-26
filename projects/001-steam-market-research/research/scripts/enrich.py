#!/usr/bin/env python3
"""Enrich candidate games that have at least MIN_REVIEWS reviews with Steam appdetails
and SteamSpy data. Raw responses cached gzipped in research/raw/{appdetails,steamspy}/.

Output: research/processed/games.csv (one row per enriched game).
Usage: python3 enrich.py [--min-reviews 1000]
"""
import argparse, csv, gzip, json, re, sys, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAND = ROOT / "processed" / "candidates.csv"
OUT = ROOT / "processed" / "games.csv"
UA = "Mozilla/5.0 (research script; polite)"
SOURCES = {
    "appdetails": ("https://store.steampowered.com/api/appdetails?appids={id}&cc=us&l=english", 1.6),
    "steamspy": ("https://steamspy.com/api.php?request=appdetails&appid={id}", 1.1),
}

# Large corporate publishers, excluded from the small-scope segment. Indie labels
# (Devolver, Team17, tinyBuild, Raw Fury, Hooded Horse, ...) are deliberately NOT here.
MAJOR = [p.lower() for p in """
Electronic Arts|Ubisoft|Activision|Blizzard|Microsoft|Xbox Game Studios|Bethesda|Sony|
PlayStation|Square Enix|Capcom|Bandai Namco|SEGA|Konami|Take-Two|2K|Rockstar|Warner Bros|
Embracer|THQ Nordic|Plaion|Deep Silver|Koch|Nexon|NetEase|Tencent|Krafton|Level Infinite|
CD PROJEKT|Paradox Interactive|Focus Entertainment|Nacon|505 Games|Gearbox|Valve|
NCSOFT|Smilegate|Pearl Abyss|Netmarble|Kakao|miHoYo|HoYoverse|Riot Games|Epic Games|Nintendo|
KOEI TECMO|Atlus|Spike Chunsoft|Aspyr|Frontier Developments|Saber Interactive|Remedy|
Arc System Works|Amazon Games|Tencent Games|Garena|Perfect World|Gaijin
""".replace("\n", "").split("|") if p.strip()]


def fetch(source, appid, retries=5):
    url, delay = SOURCES[source]
    cache = ROOT / "raw" / source / f"{appid}.json.gz"
    if cache.exists():
        return json.loads(gzip.decompress(cache.read_bytes()))
    cache.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url.format(id=appid), headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read()
            data = json.loads(body)
            if data is None:  # appdetails returns null when rate limited
                raise ValueError("null body")
            cache.write_bytes(gzip.compress(body))
            time.sleep(delay)
            return data
        except Exception as e:
            wait = 30 * (attempt + 1)
            print(f"  {source} {appid}: {e!r}, retry in {wait}s", file=sys.stderr, flush=True)
            time.sleep(wait)
    return None


def storage_gb(reqs):
    text = reqs.get("minimum", "") if isinstance(reqs, dict) else ""
    m = re.search(r"Storage:?</strong>\s*([\d.,]+)\s*(GB|MB)", text, re.I) or \
        re.search(r"(?:Hard Drive|Hard Disk Space|Storage)[^\d]{0,40}([\d.,]+)\s*(GB|MB)", text, re.I)
    if not m:
        return ""
    v = float(m.group(1).replace(",", "."))
    return round(v / 1024 if m.group(2).upper() == "MB" else v, 2)


def owners_mid(s):
    nums = [int(x.replace(",", "")) for x in re.findall(r"[\d,]+", s or "")]
    return (nums[0] + nums[1]) // 2 if len(nums) == 2 else ""


def row_for(c):
    appid = c["appid"]
    ad = (fetch("appdetails", appid) or {}).get(appid, {})
    d = ad.get("data", {}) if ad.get("success") else {}
    ss = fetch("steamspy", appid) or {}
    genres = [x["description"] for x in d.get("genres", [])]
    cats = [x["description"] for x in d.get("categories", [])]
    tags = ss.get("tags") or {}
    tags = sorted(tags.items(), key=lambda kv: -kv[1]) if isinstance(tags, dict) else []
    price = d.get("price_overview", {})
    pubs = d.get("publishers", [])
    devs = d.get("developers", [])
    major = any(re.search(r"\b" + re.escape(m) + r"\b", p.lower()) for p in pubs + devs for m in MAJOR)
    return {
        "appid": appid,
        "name": d.get("name") or c["name"],
        "type": d.get("type", ""),
        "release_date": c["release_date"],
        "developers": "; ".join(devs),
        "publishers": "; ".join(pubs),
        "self_published": int(bool(devs) and set(devs) == set(pubs)),
        "major_publisher": int(major),
        "is_free": int(bool(d.get("is_free"))),
        "price_usd": price.get("initial", 0) / 100 if price else (0 if d.get("is_free") else ""),
        "review_count": c["review_count"],
        "review_pct": c["review_pct"],
        "review_label": c["review_label"],
        "steam_recommendations": d.get("recommendations", {}).get("total", ""),
        "ss_positive": ss.get("positive", ""),
        "ss_negative": ss.get("negative", ""),
        "ss_owners": ss.get("owners", ""),
        "ss_owners_mid": owners_mid(ss.get("owners")),
        "ss_avg_playtime_min": ss.get("average_forever", ""),
        "ss_median_playtime_min": ss.get("median_forever", ""),
        "ss_ccu": ss.get("ccu", ""),
        "genres": "; ".join(genres),
        "early_access": int("Early Access" in genres),
        "top_tags": "; ".join(t for t, _ in tags[:12]),
        "categories": "; ".join(cats),
        "single_player": int("Single-player" in cats),
        "multiplayer": int(any(x in cats for x in ("Multi-player", "Online PvP", "PvP"))),
        "coop": int(any("Co-op" in x for x in cats)),
        "controller": d.get("controller_support", ""),
        "languages": len(re.findall(r"[^,]+", re.sub(r"<[^>]+>|\*|languages with full audio support", "", d.get("supported_languages", "")))),
        "storage_gb": storage_gb(d.get("pc_requirements")),
        "screenshots": len(d.get("screenshots", [])),
        "trailers": len(d.get("movies", [])),
        "dlc_count": len(d.get("dlc", [])),
        "metacritic": d.get("metacritic", {}).get("score", ""),
        "required_age": d.get("required_age", ""),
        "win": c["win"], "mac": c["mac"], "linux": c["linux"],
        "short_description": d.get("short_description", ""),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-reviews", type=int, default=1000)
    a = ap.parse_args()
    cands = [c for c in csv.DictReader(CAND.open())
             if c["review_count"] and int(c["review_count"]) >= a.min_reviews]
    print(f"{len(cands)} candidates with >= {a.min_reviews} reviews", flush=True)
    rows = []
    for i, c in enumerate(cands, 1):
        rows.append(row_for(c))
        if i % 25 == 0:
            print(f"  {i}/{len(cands)}", flush=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows)} rows to {OUT}")


if __name__ == "__main__":
    main()
