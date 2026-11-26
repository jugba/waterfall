#!/usr/bin/env python3
"""Summarise candidates.csv + games.csv into the tables used by reports/market-report.md.

Definitions (decided 2026-11-26, see BRIEF.md):
  Success      = review_count >= 1000 and review_pct >= 80 (review_count from the Steam search row).
  Small scope  = success, not major publisher, type game, price <= $20, storage <= 10 GB or unknown.
Added in iteration 002 (sanity checks, see "Data checks" section of the output):
  Core target  = small scope AND paid AND "new launch" (first Steam review no earlier than
                 45 days before the window release date, i.e. not an Early Access graduate
                 or re-release whose reviews mostly predate the window).
  Revenue est. = total reviews x 30 (range 20-60) x list price x 0.5 net.
                 Source: memories/marketing/boxleiter-multiplier-about-30x-for-recent-games.
                 These are ESTIMATES (+-50% per game at best).

Inputs : processed/candidates.csv, processed/games.csv,
         raw/tags/populartags_english.json, raw/histogram/<appid>.json.gz (scripts/fetch_extra.py)
Outputs: markdown on stdout (-> processed/analysis.md), processed/summary.json,
         processed/games_analyzed.csv (games.csv + derived columns), processed/tag_opportunity.csv
Usage  : python3 -I research/scripts/analyze.py > research/processed/analysis.md
"""
import csv, gzip, json, math, re, statistics as st
from collections import Counter, defaultdict
from datetime import date, datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAND = ROOT / "processed" / "candidates.csv"
GAMES = ROOT / "processed" / "games.csv"
TAGS = ROOT / "raw" / "tags" / "populartags_english.json"
HIST = ROOT / "raw" / "histogram"
OUT = ROOT / "processed" / "summary.json"
OUT_GAMES = ROOT / "processed" / "games_analyzed.csv"
OUT_TAGS = ROOT / "processed" / "tag_opportunity.csv"

WINDOW_START = date(2025, 11, 26)
WINDOW_END = date(2026, 11, 26)
MULT, MULT_LO, MULT_HI, NET = 30, 20, 60, 0.5
JOKE_PRICE = 100.0  # list prices above this are joke/placeholder listings; excluded from price stats

# Publishers that enrich.py's MAJOR list missed (found by inspecting the top of games.csv).
EXTRA_MAJOR = ["cognosphere", "bungie", "io interactive", "nc", "kakao games", "devsisters",
               "com2us", "cygames", "level-5", "square enix", "kadokawa", "shueisha"]
NON_FULL_GAME = re.compile(r"\b(prologue|demo|playtest|benchmark)\b", re.I)
REMASTER = re.compile(r"remaster|remake|anniversary|reforged|definitive|enhanced|legacy edition|"
                      r"complete edition|resurrected|\bhd\b", re.I)
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def num(x, default=None):
    try:
        v = float(x)
        return default if math.isnan(v) else v
    except (TypeError, ValueError):
        return default


def split(field, g):
    return [x.strip() for x in (g.get(field) or "").split(";") if x.strip()]


def med(vals, nd=1):
    v = [x for x in vals if x is not None]
    return round(st.median(v), nd) if v else ""


def pct(a, b, nd=0):
    return f"{a / b:.{nd}%}" if b else "–"


def money(x):
    if x is None or x == "":
        return "–"
    if x >= 1e6:
        return f"${x / 1e6:.1f}M"
    if x >= 1e3:
        return f"${x / 1e3:.0f}k"
    return f"${x:.0f}"


def table(title, rows, headers, note=None):
    print(f"\n### {title}\n")
    if note:
        print(note + "\n")
    print("| " + " | ".join(headers) + " |")
    print("|" + "---|" * len(headers))
    for r in rows:
        print("| " + " | ".join(str(c) for c in r) + " |")


def price_band(p):
    if p is None: return "unknown"
    if p == 0: return "free"
    for hi, lab in ((5, "$0.01–4.99"), (10, "$5–9.99"), (15, "$10–14.99"), (20, "$15–19.99"),
                    (30, "$20–29.99"), (50, "$30–49.99")):
        if p < hi: return lab
    return "$50+"


BANDS = ["free", "$0.01–4.99", "$5–9.99", "$10–14.99", "$15–19.99", "$20–29.99", "$30–49.99", "$50+", "unknown"]


# ---------------------------------------------------------------- loading
def load_tags():
    try:
        return {int(t["tagid"]): t["name"] for t in json.loads(TAGS.read_text())}
    except FileNotFoundError:
        return {}


def load_hist(appid):
    f = HIST / f"{appid}.json.gz"
    if not f.exists():
        return None
    try:
        return json.loads(gzip.decompress(f.read_bytes())).get("results")
    except Exception:
        return None


def cand_list_price(c):
    """Search rows show the current (possibly discounted) price; undo the discount."""
    cents, disc = num(c["price_final_cents"]), num(c["discount_pct"], 0)
    if cents is None:
        return None
    if disc and disc < 100:
        cents = cents / (1 - disc / 100)
    return round(cents / 100, 2)


def main():
    tagname = load_tags()
    cands = list(csv.DictReader(CAND.open()))
    raw_games = list(csv.DictReader(GAMES.open()))
    checks = []  # (check, finding, action)

    # ------------------------------------------------------------ candidate checks
    ids = [c["appid"] for c in cands]
    dup = len(ids) - len(set(ids))
    checks.append(("Duplicate appids in candidates.csv", str(dup), "none needed" if not dup else "deduplicated"))
    seen, cl = set(), []
    for c in cands:
        if c["appid"] in seen:
            continue
        seen.add(c["appid"])
        c["date"] = date.fromisoformat(c["release_date"]) if c["release_date"] else None
        c["tags"] = [int(t) for t in re.findall(r"\d+", c["tagids"] or "")]
        c["list_price"] = cand_list_price(c)
        c["rc"] = num(c["review_count"], 0)
        c["rp"] = num(c["review_pct"])
        cl.append(c)
    cands = cl
    out_of_window = [c for c in cands if not c["date"] or not (WINDOW_START <= c["date"] <= WINDOW_END)]
    checks.append(("Release dates outside 2025-11-26..2026-11-26 or missing", str(len(out_of_window)),
                   "excluded" if out_of_window else "none needed"))
    cands = [c for c in cands if c not in out_of_window]
    joke = [c for c in cands if (c["list_price"] or 0) > JOKE_PRICE]
    checks.append((f"Candidate list price > ${JOKE_PRICE:.0f} (joke/placeholder listings)",
                   f"{len(joke)}, none with ≥10 reviews" if not any(c["rc"] for c in joke) else str(len(joke)),
                   "excluded from price statistics"))
    notags = sum(1 for c in cands if not c["tags"])
    checks.append(("Candidates without tag ids", str(notags), "kept; ignored in tag tables"))
    unnamed = {t for c in cands for t in c["tags"]} - set(tagname)
    checks.append(("Tag ids without a name in Steam's tag list", str(len(unnamed)),
                   "shown as #id" if unnamed else "none"))
    cand_by_id = {c["appid"]: c for c in cands}

    # ------------------------------------------------------------ game checks + derived columns
    games = []
    nonfull, steamspy_ok, nonenglish, prior, remaster_n, hist_missing = [], 0, [], [], [], 0
    for g in raw_games:
        if g["type"] not in ("game", ""):
            continue
        if NON_FULL_GAME.search(g["name"]) and num(g["price_usd"], 0) == 0:
            nonfull.append(g["name"])
            continue
        g["rc"] = num(g["review_count"], 0)
        g["rp"] = num(g["review_pct"], 0)
        g["price"] = num(g["price_usd"])
        g["storage"] = num(g["storage_gb"])
        g["date"] = date.fromisoformat(g["release_date"])
        c = cand_by_id.get(g["appid"], {})
        g["tags"] = [tagname.get(t, f"#{t}") for t in c.get("tags", [])]
        pubs = [p.strip().lower() for p in split("publishers", g)]
        devs = [d.strip().lower() for d in split("developers", g)]
        extra = any(re.search(r"\b" + re.escape(m) + r"\b", p) for p in pubs + devs for m in EXTRA_MAJOR)
        g["major"] = g["major_publisher"] == "1" or extra
        g["self_pub_loose"] = bool(devs) and any(d in pubs for d in devs)
        # Review count cross-checks. Search row count appears language-filtered (English);
        # appdetails `recommendations.total` is all languages.
        rec = num(g["steam_recommendations"])
        ssn = (num(g["ss_positive"], 0) or 0) + (num(g["ss_negative"], 0) or 0)
        if ssn > 0:
            steamspy_ok += 1
        g["total_reviews"] = max(g["rc"], rec or 0)
        g["english_share"] = round(g["rc"] / g["total_reviews"], 2) if g["total_reviews"] else ""
        if rec and rec >= 2 * g["rc"]:
            nonenglish.append(g)
        # Launch type from the review histogram (first review date).
        h = load_hist(g["appid"])
        g["first_review"] = ""
        g["pre_release_share"] = ""
        g["launch_type"] = "unknown"
        if h and h.get("start_date"):
            first = datetime.fromtimestamp(h["start_date"], timezone.utc).date()
            g["first_review"] = first.isoformat()
            ups = [(datetime.fromtimestamp(r["date"], timezone.utc).date(),
                    r["recommendations_up"] + r["recommendations_down"]) for r in h.get("rollups", [])]
            tot = sum(n for _, n in ups)
            cutoff = g["date"] - timedelta(days=45)
            before = sum(n for d, n in ups if d < cutoff.replace(day=1)) if h.get("rollup_type") == "month" \
                else sum(n for d, n in ups if d < cutoff)
            g["pre_release_share"] = round(before / tot, 2) if tot else ""
            g["launch_type"] = "new" if first >= cutoff else "prior_reviews"
        else:
            hist_missing += 1
        if g["launch_type"] == "prior_reviews":
            prior.append(g)
        g["remaster_name"] = bool(REMASTER.search(g["name"]))
        if g["remaster_name"]:
            remaster_n.append(g["name"])
        # Success flags
        g["success"] = g["rc"] >= 1000 and g["rp"] >= 80
        g["small"] = (g["success"] and not g["major"] and g["type"] == "game" and g["price"] is not None
                      and g["price"] <= 20 and (g["storage"] is None or g["storage"] <= 10))
        g["core"] = g["small"] and (g["price"] or 0) > 0 and g["launch_type"] == "new"
        # Revenue estimate (gross list price x units x net share)
        p = g["price"] or 0
        g["units_est"] = round(g["total_reviews"] * MULT)
        g["rev_net_est"] = round(g["total_reviews"] * MULT * p * NET)
        g["rev_net_lo"] = round(g["total_reviews"] * MULT_LO * p * NET)
        g["rev_net_hi"] = round(g["total_reviews"] * MULT_HI * p * NET)
        g["days_live"] = (WINDOW_END - g["date"]).days
        pt = num(g["ss_median_playtime_min"])
        g["playtime"] = pt if pt and pt > 0 else None
        games.append(g)

    checks.append(("Non-game rows in games.csv (type != game: DLC, music, demo)",
                   str(sum(1 for g in raw_games if g['type'] not in ('game', ''))), "excluded"))
    checks.append(("Free prologues/demos listed as games (≥1k reviews)", f"{len(nonfull)}: {', '.join(nonfull)}" or "0",
                   "excluded"))
    checks.append(("Games with ≥1k reviews in candidates vs rows in games.csv",
                   f"{sum(1 for c in cands if c['rc'] >= 1000)} vs {len(raw_games)}", "match" ))
    checks.append(("Missing price in games.csv", ", ".join(g["name"] for g in games if g["price"] is None),
                   "kept; excluded from small scope (price unknown)"))
    checks.append(("Missing install size", str(sum(1 for g in games if g["storage"] is None)),
                   "treated as ≤10 GB per definition"))
    checks.append(("SteamSpy rows with real data (positive+negative > 0)", f"{steamspy_ok} of {len(games)}",
                   "SteamSpy owners/tags unusable for most games; owners not used; tags taken from search tagids instead"))
    checks.append(("Search review count < ½ of appdetails total (all-language) recommendations",
                   f"{len(nonenglish)} (e.g. {', '.join(g['name'] for g in sorted(nonenglish, key=lambda g: g['english_share'])[:4])})",
                   "search count is language-filtered (≈English); success bar kept on it, revenue uses the larger all-language total"))
    checks.append(("Games whose first Steam review predates release by >45 days (EA graduates / re-releases)",
                   f"{len(prior)} of {len(games)} ({pct(len(prior), len(games))})",
                   "kept in 'all'/'small' (per definition); excluded from 'core target'"))
    checks.append(("Names that look like remasters/re-releases", f"{len(remaster_n)}", "flagged in games_analyzed.csv"))
    checks.append(("Review histogram missing", str(hist_missing), "launch_type = unknown → not core"))
    checks.append(("Major publishers missed by enrich.py's list (Bungie, HoYoverse/COGNOSPHERE, NCSOFT as 'NC', …)",
                   str(sum(1 for g in games if g['major'] and g['major_publisher'] != '1')), "re-flagged as major"))

    success = [g for g in games if g["success"]]
    small = [g for g in success if g["small"]]
    core = [g for g in small if g["core"]]
    gby = {g["appid"]: g for g in games}
    for c in cands:
        gg = gby.get(c["appid"])
        c["success"] = bool(gg and gg["success"])
        c["small"] = bool(gg and gg["small"])
        c["core"] = bool(gg and gg["core"])

    # ------------------------------------------------------------ output
    print("# Analysis output — 001 Steam market research\n")
    print(f"Generated by `research/scripts/analyze.py`. Window {WINDOW_START}..{WINDOW_END}. "
          "Revenue figures are ESTIMATES: reviews × 30 (20–60) × list price × 0.5 net "
          "(memories/marketing/boxleiter-multiplier-about-30x-for-recent-games).")
    table("Data checks", checks, ["Check", "Finding", "Action"])

    n10 = sum(1 for c in cands if c["rc"] >= 10)
    n100 = sum(1 for c in cands if c["rc"] >= 100)
    n1k = len(games)
    funnel = [
        ("Released in window (Steam search, type game)", len(cands), "100%"),
        ("≥10 reviews (has a review score)", n10, pct(n10, len(cands), 1)),
        ("≥100 reviews", n100, pct(n100, len(cands), 1)),
        ("≥1,000 reviews (enriched)", n1k, pct(n1k, len(cands), 1)),
        ("Success: ≥1,000 reviews and ≥80%", len(success), pct(len(success), len(cands), 1)),
        ("Small-scope success", len(small), pct(len(small), len(cands), 2)),
        ("Core target: small-scope, paid, new launch (no prior EA reviews)", len(core), pct(len(core), len(cands), 2)),
    ]
    table("Funnel", funnel, ["Stage", "Games", "Share of releases"])
    summary = {"released_in_window": len(cands), "with_10_reviews": n10, "with_100_reviews": n100,
               "with_1000_reviews": n1k, "successes": len(success), "small_scope_successes": len(small),
               "core_target": len(core)}

    # Review-count distribution among all releases
    rcs = sorted(c["rc"] for c in cands)
    q = lambda p: int(rcs[min(len(rcs) - 1, int(p * len(rcs)))])
    table("Review-count percentiles across all releases (search count; 0 = fewer than 10)",
          [(f"p{p*100:g}", q(p)) for p in (0.5, 0.75, 0.9, 0.95, 0.98, 0.99, 0.995)], ["Percentile", "Reviews"])

    # Segment medians
    def seg_stats(grp):
        paid = [g for g in grp if (g["price"] or 0) > 0]
        return [
            ("Games", len(grp)),
            ("Median list price (paid)", med([g["price"] for g in paid], 2)),
            ("Median reviews (search)", med([g["rc"] for g in grp], 0)),
            ("Median total reviews (all languages)", med([g["total_reviews"] for g in grp], 0)),
            ("Median review %", med([g["rp"] for g in grp], 0)),
            ("Median est. net revenue (paid)", money(med([g["rev_net_est"] for g in paid], 0) or None)),
            ("Median SteamSpy median playtime (h)", med([g["playtime"] / 60 for g in grp if g["playtime"]], 1)),
            ("Median install size (GB)", med([g["storage"] for g in grp], 1)),
            ("Median languages", med([num(g["languages"]) for g in grp], 0)),
            ("Median screenshots / trailers", f"{med([num(g['screenshots']) for g in grp], 0)} / {med([num(g['trailers']) for g in grp], 0)}"),
            ("Early Access (still) share", pct(sum(g['early_access'] == '1' for g in grp), len(grp))),
            ("Prior reviews before window release (EA grad / re-release)", pct(sum(g['launch_type'] == 'prior_reviews' for g in grp), len(grp))),
            ("Self-published (dev == publisher)", pct(sum(g['self_published'] == '1' for g in grp), len(grp))),
            ("Self-published (dev among publishers)", pct(sum(g['self_pub_loose'] for g in grp), len(grp))),
            ("Major publisher", pct(sum(g['major'] for g in grp), len(grp))),
            ("Free to play", pct(sum((g['price'] or 0) == 0 for g in grp), len(grp))),
            ("Single-player / Multiplayer / Co-op", f"{pct(sum(g['single_player']=='1' for g in grp), len(grp))} / {pct(sum(g['multiplayer']=='1' for g in grp), len(grp))} / {pct(sum(g['coop']=='1' for g in grp), len(grp))}"),
            ("Full controller support", pct(sum(g['controller'] == 'full' for g in grp), len(grp))),
            ("Mac / Linux builds", f"{pct(sum(g['mac']=='1' for g in grp), len(grp))} / {pct(sum(g['linux']=='1' for g in grp), len(grp))}"),
        ]
    fails = [g for g in games if not g["success"]]
    segs = [("≥1k, <80%", fails), ("All successes", success), ("Small-scope", small), ("Core target", core)]
    cols = [seg_stats(s) for _, s in segs]
    table("Segment profile", [(cols[0][i][0],) + tuple(c[i][1] for c in cols) for i in range(len(cols[0]))],
          ["Metric"] + [n for n, _ in segs])

    # ---------------- tag opportunity (candidate base)
    base_rate_s = len(success) / len(cands)
    base_rate_c = len(core) / len(cands)
    tstats = defaultdict(lambda: {"n": 0, "n100": 0, "n1k": 0, "succ": 0, "small": 0, "core": 0, "rcs": []})
    for c in cands:
        for t in set(c["tags"]):
            s = tstats[t]
            s["n"] += 1
            s["n100"] += c["rc"] >= 100
            s["n1k"] += c["rc"] >= 1000
            s["succ"] += c["success"]
            s["small"] += c["small"]
            s["core"] += c["core"]
            s["rcs"].append(c["rc"])
    trows = []
    for t, s in tstats.items():
        if s["n"] < 150:
            continue
        hit = s["succ"] / s["n"]
        chit = s["core"] / s["n"]
        trows.append({
            "tag": tagname.get(t, f"#{t}"), "tagid": t, "releases": s["n"],
            "share_of_releases": round(s["n"] / len(cands), 4),
            "ge100": s["n100"], "ge1k": s["n1k"], "successes": s["succ"], "small": s["small"], "core": s["core"],
            "success_per_1000": round(1000 * hit, 1), "core_per_1000": round(1000 * chit, 1),
            "lift_success": round(hit / base_rate_s, 2), "lift_core": round(chit / base_rate_c, 2) if base_rate_c else 0,
            "p90_reviews": int(sorted(s["rcs"])[int(0.9 * len(s["rcs"]))]),
        })
    with OUT_TAGS.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(trows[0].keys()))
        w.writeheader()
        w.writerows(sorted(trows, key=lambda r: -r["releases"]))
    hdr = ["Tag", "Releases", "≥100 rev", "Successes", "Small", "Core", "Success /1000", "Core /1000", "Lift (succ)", "Lift (core)", "p90 reviews"]
    fmt = lambda r: (r["tag"], r["releases"], r["ge100"], r["successes"], r["small"], r["core"], r["success_per_1000"],
                     r["core_per_1000"], r["lift_success"], r["lift_core"], r["p90_reviews"])
    note = (f"Base rates: {1000*base_rate_s:.1f} successes and {1000*base_rate_c:.2f} core-target successes per 1,000 releases. "
            "Lift = tag rate ÷ base rate. Tags from the Steam search row (top ~6 tags per game). Tags with ≥150 releases only.")
    table("Tag opportunity — most-released tags (saturation view)", [fmt(r) for r in sorted(trows, key=lambda r: -r["releases"])[:40]], hdr, note)
    opp = [r for r in trows if r["core"] >= 4]
    table("Tag opportunity — highest core-target lift (≥4 core hits)", [fmt(r) for r in sorted(opp, key=lambda r: -r["lift_core"])[:40]], hdr)
    sat = [r for r in trows if r["releases"] >= 800]
    table("Saturated tags — many releases, lowest success lift (≥800 releases)", [fmt(r) for r in sorted(sat, key=lambda r: r["lift_success"])[:20]], hdr)

    # Tag pairs among core target vs base
    pairs_base, pairs_core = Counter(), Counter()
    skip = {492, 19, 21, 597, 4182, 599, 9, 122, 3871, 4191}  # very generic tags
    for c in cands:
        ts = sorted(set(t for t in c["tags"] if t not in skip))
        for i in range(len(ts)):
            for j in range(i + 1, len(ts)):
                pairs_base[(ts[i], ts[j])] += 1
                if c["core"]:
                    pairs_core[(ts[i], ts[j])] += 1
    prow = []
    for p, n in pairs_core.most_common():
        if n < 4:
            break
        b = pairs_base[p]
        prow.append((f"{tagname.get(p[0], p[0])} + {tagname.get(p[1], p[1])}", b, n, round(1000 * n / b, 1),
                     round((n / b) / base_rate_c, 1)))
    table("Tag pairs most common among core-target hits (generic tags removed)", sorted(prow, key=lambda r: -r[2])[:30],
          ["Pair", "Releases", "Core hits", "Core /1000", "Lift"])

    # Genres (games.csv only, ≥1k-review games)
    gc, gs, gsm = Counter(), Counter(), Counter()
    for g in games:
        for x in set(split("genres", g)):
            gc[x] += 1; gs[x] += g["success"]; gsm[x] += g["small"]
    table("Steam genres among ≥1k-review games", [(x, gc[x], gs[x], pct(gs[x], gc[x]), gsm[x]) for x, _ in gc.most_common(15)],
          ["Genre", "≥1k games", "Successes", "Success rate (≥80%)", "Small-scope"])

    # ---------------- price
    prow = []
    for b in BANDS:
        cs = [c for c in cands if price_band(c["list_price"]) == b and (c["list_price"] or 0) <= JOKE_PRICE]
        if not cs:
            continue
        rv = [c["rc"] for c in cs if c["rc"] >= 10]
        sg = [g for g in success if price_band(g["price"]) == b]
        prow.append((b, len(cs), pct(len(cs), len(cands)), sum(c["rc"] >= 100 for c in cs), sum(c["rc"] >= 1000 for c in cs),
                     sum(c["success"] for c in cs), round(1000 * sum(c["success"] for c in cs) / len(cs), 1),
                     sum(c["small"] for c in cs), sum(c["core"] for c in cs), med(rv, 0),
                     money(med([g["rev_net_est"] for g in sg], 0) or None)))
    table("Price bands — whole release base (list price; search row)", prow,
          ["Band", "Releases", "Share", "≥100 rev", "≥1k rev", "Successes", "Succ /1000", "Small", "Core", "Median reviews (≥10)", "Median est. net rev of successes"],
          "Price elasticity proxy: success rate per 1,000 releases and median review count by band.")
    # playtime vs price
    pt = []
    for b in BANDS:
        grp = [g for g in games if price_band(g["price"]) == b and g["playtime"]]
        if grp:
            pt.append((b, len(grp), med([g["playtime"] / 60 for g in grp], 1),
                       med([g["playtime"] / 60 / g["price"] for g in grp if g["price"]], 2) if b != "free" else "–"))
    table("Playtime vs price (≥1k-review games, SteamSpy median playtime)", pt, ["Band", "Games", "Median playtime (h)", "Hours per $"])

    # ---------------- EA vs full
    ea_c = [c for c in cands if 493 in c["tags"]]
    nea_c = [c for c in cands if 493 not in c["tags"]]
    table("Early Access vs full release (search tag 'Early Access')", [
        ("Early Access", len(ea_c), sum(c["rc"] >= 1000 for c in ea_c), sum(c["success"] for c in ea_c), round(1000 * sum(c["success"] for c in ea_c) / len(ea_c), 1), sum(c["core"] for c in ea_c)),
        ("Not Early Access", len(nea_c), sum(c["rc"] >= 1000 for c in nea_c), sum(c["success"] for c in nea_c), round(1000 * sum(c["success"] for c in nea_c) / len(nea_c), 1), sum(c["core"] for c in nea_c)),
    ], ["Type", "Releases", "≥1k", "Successes", "Succ /1000", "Core"])
    lt = Counter((g["launch_type"], g["success"]) for g in games)
    table("Launch type among ≥1k-review games", [(t, lt[(t, True)] + lt[(t, False)], lt[(t, True)], pct(lt[(t, True)], lt[(t, True)] + lt[(t, False)]))
                                                 for t in ("new", "prior_reviews", "unknown") if lt[(t, True)] + lt[(t, False)]],
          ["Launch type", "≥1k games", "Successes", "Success rate"])

    # ---------------- timing
    wd = []
    for i, d in enumerate(WEEKDAYS):
        cs = [c for c in cands if c["date"].weekday() == i]
        wd.append((d, len(cs), pct(len(cs), len(cands)), sum(c["success"] for c in cs), round(1000 * sum(c["success"] for c in cs) / len(cs), 1) if cs else 0, sum(c["core"] for c in cs)))
    table("Release weekday", wd, ["Weekday", "Releases", "Share", "Successes", "Succ /1000", "Core"])
    mo = []
    for m in sorted({c["release_date"][:7] for c in cands}):
        cs = [c for c in cands if c["release_date"][:7] == m]
        mo.append((m, len(cs), sum(c["rc"] >= 1000 for c in cs), sum(c["success"] for c in cs), round(1000 * sum(c["success"] for c in cs) / len(cs), 1), sum(c["core"] for c in cs)))
    table("Release month", mo, ["Month", "Releases", "≥1k", "Successes", "Succ /1000", "Core"],
          "Right-censored: games released in the last 1–2 months have had little time to reach 1,000 reviews.")

    # ---------------- scope signals
    def bucket(v, edges, labels):
        if v is None: return "unknown"
        for e, l in zip(edges, labels):
            if v <= e: return l
        return labels[-1]
    for title, key, edges, labels in (
        ("Install size", "storage", (1, 2, 5, 10, 20, 1e9), ("≤1 GB", "1–2 GB", "2–5 GB", "5–10 GB", "10–20 GB", ">20 GB")),
        ("Languages", "langs", (1, 5, 10, 15, 1e9), ("1", "2–5", "6–10", "11–15", "16+")),
        ("Median playtime (SteamSpy)", "pt_h", (1, 2, 5, 10, 20, 1e9), ("≤1 h", "1–2 h", "2–5 h", "5–10 h", "10–20 h", ">20 h")),
    ):
        rows = []
        for g in games:
            g["langs"] = num(g["languages"])
            g["pt_h"] = g["playtime"] / 60 if g["playtime"] else None
        for l in labels + ("unknown",):
            grp = [g for g in games if bucket(g[key], edges, labels) == l]
            if grp:
                rows.append((l, len(grp), sum(g["success"] for g in grp), pct(sum(g["success"] for g in grp), len(grp)),
                             sum(g["small"] for g in grp), sum(g["core"] for g in grp)))
        table(f"Scope signal — {title} (≥1k-review games)", rows, ["Bucket", "≥1k games", "Successes", "Success rate", "Small", "Core"])

    # multiplayer
    mrows = []
    for lab, f in (("Single-player only", lambda g: g["single_player"] == "1" and g["multiplayer"] == "0" and g["coop"] == "0"),
                   ("Has co-op", lambda g: g["coop"] == "1"), ("Has multiplayer (PvP/MP)", lambda g: g["multiplayer"] == "1")):
        grp = [g for g in games if f(g)]
        mrows.append((lab, len(grp), pct(sum(g["success"] for g in grp), len(grp)), sum(g["small"] for g in grp), sum(g["core"] for g in grp)))
    table("Player mode (≥1k-review games)", mrows, ["Mode", "≥1k games", "Success rate", "Small", "Core"])

    # Revenue distribution for core target
    rv = sorted(g["rev_net_est"] for g in core)
    if rv:
        qq = lambda p: rv[min(len(rv) - 1, int(p * len(rv)))]
        table("Estimated net revenue — core target (central 30× case)",
              [(f"p{int(p*100)}", money(qq(p))) for p in (0.1, 0.25, 0.5, 0.75, 0.9)] + [("Sum", money(sum(rv)))],
              ["Percentile", "Est. net revenue"])

    # ---------------- candidate directions (tag-rule clusters; a game can be in several)
    DIRS = {
        "Cozy organizing / job sim": {"Organizing", "Job Simulator", "Cleaning", "Cozy"},
        "Incremental / gambling roguelite": {"Incremental", "Idler", "Gambling"},
        "Online co-op comedy (friendslop)": {"Online Co-Op"},
        "Detective / investigation puzzle": {"Investigation", "Detective", "Mystery"},
        "Shopkeeper / management sim": {"Shop Keeper", "Management", "Trading"},
        "Short indie horror": {"Psychological Horror", "Survival Horror", "Horror"},
        "Roguelike deckbuilder": {"Deckbuilding", "Roguelike Deckbuilder", "Card Battler"},
        "2D platformer": {"2D Platformer", "Platformer"},
        "Bullet heaven / survivors-like": {"Bullet Heaven", "Bullet Hell"},
    }
    name_to_id = {v: k for k, v in tagname.items()}
    drows = []
    for d, tset in DIRS.items():
        ids_ = {name_to_id[t] for t in tset if t in name_to_id}
        cs = [c for c in cands if ids_ & set(c["tags"])]
        paid = [c for c in cs if (c["list_price"] or 0) > 0]
        cg = [g for g in core if set(g["tags"]) & tset]
        rv_ = sorted(g["rev_net_est"] for g in cg)
        qd = lambda p: rv_[min(len(rv_) - 1, int(p * len(rv_)))] if rv_ else None
        drows.append((d, ", ".join(sorted(tset)), len(cs), len(paid), sum(c["rc"] >= 100 for c in cs), len(cg),
                      round(1000 * len(cg) / len(cs), 1) if cs else 0, round(len(cg) / len(cs) / base_rate_c, 2) if cs else 0,
                      med([g["price"] for g in cg], 2), money(qd(0.25)), money(qd(0.5)), money(qd(0.75)),
                      sum(g["coop"] == "1" for g in cg), "; ".join(g["name"] for g in sorted(cg, key=lambda g: -g["rc"])[:6])))
        summary.setdefault("directions", {})[d] = {"releases": len(cs), "core": len(cg), "median_rev_net_est": qd(0.5)}
    table("Candidate directions — tag-rule clusters (any listed tag)", drows,
          ["Direction", "Tags (any)", "Releases", "Paid releases", "≥100 rev", "Core hits", "Core /1000", "Lift",
           "Median price (core)", "p25 est. net", "Median est. net", "p75 est. net", "Core w/ co-op", "Biggest core hits"])

    # ---------------- lists
    def glist(grp, n):
        return [(g["name"], g["release_date"], g["price_usd"], int(g["rc"]), int(g["total_reviews"]), g["review_pct"],
                 g["launch_type"], g["developers"][:28], ", ".join(g["tags"][:6]),
                 f"{money(g['rev_net_lo'])}–{money(g['rev_net_hi'])}") for g in sorted(grp, key=lambda g: -g["rc"])[:n]]
    lh = ["Game", "Released", "Price", "Reviews (search)", "Reviews (all lang)", "%", "Launch", "Developer", "Tags", "Est. net rev (20–60×)"]
    table("Top 30 successes overall", glist(success, 30), lh)
    table("Core-target successes (all, by reviews)", glist(core, 400), lh)
    table("Small-scope successes with prior reviews (EA graduates / re-releases, excluded from core)",
          glist([g for g in small if g["launch_type"] != "new" or (g["price"] or 0) == 0], 60), lh)

    # ---------------- write derived files
    extra = ["tags", "major", "self_pub_loose", "total_reviews", "english_share", "first_review", "pre_release_share",
             "launch_type", "remaster_name", "success", "small", "core", "units_est", "rev_net_est", "rev_net_lo",
             "rev_net_hi", "days_live"]
    with OUT_GAMES.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(list(raw_games[0].keys()) + extra)
        for g in games:
            w.writerow([g[k] for k in raw_games[0].keys()] +
                       ["; ".join(g[k]) if k == "tags" else (int(g[k]) if isinstance(g[k], bool) else g[k]) for k in extra])
    summary["base_success_per_1000"] = round(1000 * base_rate_s, 2)
    summary["base_core_per_1000"] = round(1000 * base_rate_c, 3)
    summary["core_median_rev_net_est"] = med(rv, 0) if rv else None
    OUT.write_text(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
