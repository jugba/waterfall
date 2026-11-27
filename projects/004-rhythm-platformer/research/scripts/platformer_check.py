"""Platformer / rhythm market check for project 004.

Reads project 001's processed data (never edits it):
  candidates.csv  - every release 2025-11-26..2026-11-26 with top ~6-7 search tag ids
  games_analyzed.csv - the 744 games with >=1k reviews + derived flags (success/core/revenue est.)
  raw/tags/populartags_english.json - tag id -> name
Writes:
  ../processed/tag_combo_rates.csv  - releases / >=100 / >=1k / success / core per tag set
  ../processed/genre_games.csv      - every >=1k-review game carrying a platformer/rhythm/music/runner tag
  ../processed/genre_mid.csv        - platformer+rhythm/music releases with >=50 reviews (near-misses)
Definitions follow 001's analyze.py: success = >=1k search reviews and >=80%;
core = success & not major publisher & paid <=$20 & <=10 GB & first review <=45 days before release.
Revenue = all-language reviews x 30 (20-60) x list price x 0.5 (memories/marketing/boxleiter-...).
"""
import csv, json, re
from pathlib import Path
from datetime import date

HERE = Path(__file__).resolve().parent
P1 = HERE.parents[2] / "001-steam-market-research" / "research"
OUT = HERE.parent / "processed"

tagname = {t["tagid"]: t["name"] for t in json.load(open(P1 / "raw/tags/populartags_english.json"))}
tagid = {v: k for k, v in tagname.items()}

cands, seen = [], set()
for c in csv.DictReader(open(P1 / "processed/candidates.csv")):
    if c["appid"] in seen or not c["release_date"]:
        continue
    d = date.fromisoformat(c["release_date"])
    if not (date(2025, 11, 26) <= d <= date(2026, 11, 26)):
        continue
    seen.add(c["appid"])
    c["tags"] = {int(t) for t in re.findall(r"\d+", c["tagids"] or "")}
    c["rc"] = float(c["review_count"] or 0)
    cands.append(c)

rows = list(csv.reader(open(P1 / "processed/games_analyzed.csv")))
hdr = {}
for i, h in enumerate(rows[0]):
    hdr.setdefault(h, i)  # first occurrence (file has duplicated derived columns)
games = {r[hdr["appid"]]: {h: r[i] for h, i in hdr.items()} for r in rows[1:]}
T = lambda v: v in ("1", "True", "true")
for c in cands:
    g = games.get(c["appid"])
    c["g"] = g
    c["success"] = bool(g and T(g["success"]))
    c["core"] = bool(g and T(g["core"]))

N = len(cands)
base = dict(rel=N, ge100=sum(c["rc"] >= 100 for c in cands), ge1k=sum(c["rc"] >= 1000 for c in cands),
            success=sum(c["success"] for c in cands), core=sum(c["core"] for c in cands))

def stats(label, pred):
    s = [c for c in cands if pred(c)]
    n = len(s)
    r = dict(set=label, releases=n, ge100=sum(c["rc"] >= 100 for c in s), ge1k=sum(c["rc"] >= 1000 for c in s),
             success=sum(c["success"] for c in s), core=sum(c["core"] for c in s))
    for k in ("ge100", "success", "core"):
        r[f"{k}_per_1000"] = round(1000 * r[k] / n, 1) if n else 0
        r[f"{k}_lift"] = round((r[k] / n) / (base[k] / N), 2) if n else 0
    return r

has = lambda *names: (lambda c: all(tagid[x] in c["tags"] for x in names))
anyof = lambda *names: (lambda c: any(tagid[x] in c["tags"] for x in names))
PLAT = ("2D Platformer", "Platformer", "Precision Platformer", "Puzzle Platformer", "3D Platformer")
PLAT2D = ("2D Platformer", "Platformer", "Precision Platformer", "Puzzle Platformer")
RHY = ("Rhythm", "Music", "Music-Based Procedural Generation")
sets = [("ALL RELEASES", lambda c: True)]
for t in ("2D Platformer", "Platformer", "Precision Platformer", "Puzzle Platformer", "3D Platformer", "Runner",
          "Rhythm", "Music", "Music-Based Procedural Generation", "Great Soundtrack", "Cute", "Colorful",
          "Cartoony", "Hand-drawn", "Short", "Fast-Paced"):
    sets.append((t, has(t)))
sets += [
    ("Any platformer tag", anyof(*PLAT)),
    ("Any 2D-style platformer tag (excl. 3D)", anyof(*PLAT2D)),
    ("Rhythm or Music", anyof("Rhythm", "Music")),
    ("Platformer-any + Rhythm/Music", lambda c: anyof(*PLAT)(c) and anyof(*RHY)(c)),
    ("Platformer-any + Rhythm", lambda c: anyof(*PLAT)(c) and has("Rhythm")(c)),
    ("Platformer-any + Cute or Colorful", lambda c: anyof(*PLAT)(c) and anyof("Cute", "Colorful")(c)),
    ("Platformer-any + Cartoony or Hand-drawn", lambda c: anyof(*PLAT)(c) and anyof("Cartoony", "Hand-drawn")(c)),
    ("Platformer-any + Short", lambda c: anyof(*PLAT)(c) and has("Short")(c)),
    ("Platformer-any + Great Soundtrack", lambda c: anyof(*PLAT)(c) and has("Great Soundtrack")(c)),
    ("Platformer-any + Fast-Paced", lambda c: anyof(*PLAT)(c) and has("Fast-Paced")(c)),
    ("Rhythm/Music + Action", lambda c: anyof(*RHY)(c) and has("Action")(c)),
    ("Rhythm/Music + Cute or Colorful", lambda c: anyof(*RHY)(c) and anyof("Cute", "Colorful")(c)),
    ("Runner + Rhythm/Music", lambda c: has("Runner")(c) and anyof(*RHY)(c)),
]
res = [stats(l, p) for l, p in sets]
with open(OUT / "tag_combo_rates.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(res[0])); w.writeheader(); w.writerows(res)

GEN = set(PLAT) | set(RHY) | {"Runner"}
out = []
for c in cands:
    g = c["g"]
    if not g or not any(tagid[x] in c["tags"] for x in GEN):
        continue
    out.append(dict(appid=c["appid"], name=g["name"], release_date=g["release_date"], price=g["price_usd"],
                    search_reviews=g["review_count"], total_reviews=g["total_reviews"], pct=g["review_pct"],
                    success=int(c["success"]), core=int(c["core"]), launch_type=g["launch_type"],
                    major=g["major"], early_access=g["early_access"], storage_gb=g["storage_gb"],
                    median_playtime_h=round(float(g["ss_median_playtime_min"] or 0) / 60, 1),
                    rev_net_lo=g["rev_net_lo"], rev_net_est=g["rev_net_est"], rev_net_hi=g["rev_net_hi"],
                    publishers=g["publishers"], tags="; ".join(tagname.get(t, f"#{t}") for t in sorted(c["tags"])),
                    short_description=g["short_description"]))
out.sort(key=lambda r: -float(r["total_reviews"] or 0))
with open(OUT / "genre_games.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(out[0])); w.writeheader(); w.writerows(out)

mid = [dict(appid=c["appid"], name=c["name"], release_date=c["release_date"], search_reviews=int(c["rc"]),
            pct=c["review_pct"], price_cents=c["price_final_cents"], discount=c["discount_pct"],
            tags="; ".join(tagname.get(t, f"#{t}") for t in sorted(c["tags"])))
       for c in cands if c["rc"] >= 50 and anyof(*PLAT)(c) and anyof(*RHY)(c)]
mid += [dict(appid=c["appid"], name=c["name"], release_date=c["release_date"], search_reviews=int(c["rc"]),
             pct=c["review_pct"], price_cents=c["price_final_cents"], discount=c["discount_pct"],
             tags="[rhythm-only] " + "; ".join(tagname.get(t, f"#{t}") for t in sorted(c["tags"])))
        for c in cands if c["rc"] >= 100 and anyof(*RHY)(c) and not anyof(*PLAT)(c)]
mid.sort(key=lambda r: -r["search_reviews"])
with open(OUT / "genre_mid.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(mid[0])); w.writeheader(); w.writerows(mid)
print("base", base)
for r in res:
    print(r)
