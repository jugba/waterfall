#!/usr/bin/env python3
"""Summarise games.csv into the tables used by reports/market-report.md.

Success  = review_count >= 1000 and review_pct >= 80 (decided 2026-11-26).
Small scope = success, not major publisher, price <= $20, storage <= 10 GB (or unknown).
Output: research/processed/summary.json and printed markdown tables.
"""
import csv, json, statistics as st
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAND = ROOT / "processed" / "candidates.csv"
GAMES = ROOT / "processed" / "games.csv"
OUT = ROOT / "processed" / "summary.json"


def num(x, default=None):
    try:
        return float(x)
    except (TypeError, ValueError):
        return default


def is_success(g):
    return num(g["review_count"], 0) >= 1000 and num(g["review_pct"], 0) >= 80


def is_small(g):
    p, s = num(g["price_usd"]), num(g["storage_gb"])
    return (is_success(g) and g["major_publisher"] == "0" and g["type"] == "game"
            and p is not None and p <= 20 and (s is None or s <= 10))


def split(field, g):
    return [x.strip() for x in g[field].split(";") if x.strip()]


def table(title, rows, headers):
    print(f"\n### {title}\n")
    print("| " + " | ".join(headers) + " |")
    print("|" + "---|" * len(headers))
    for r in rows:
        print("| " + " | ".join(str(c) for c in r) + " |")


def tag_lift(games, success, field, min_n=15, top=25):
    """Share of successes having the tag vs share among all >=1000-review games."""
    allc, sc = Counter(), Counter()
    for g in games:
        for t in set(split(field, g)):
            allc[t] += 1
    for g in success:
        for t in set(split(field, g)):
            sc[t] += 1
    rows = []
    for t, n in sc.most_common():
        if n < min_n:
            continue
        rows.append((t, n, f"{n / len(success):.0%}", f"{n / allc[t]:.0%}"))
    return rows[:top]


def price_band(p):
    if p is None: return "unknown"
    if p == 0: return "free"
    for hi, lab in ((5, "$0.01–4.99"), (10, "$5–9.99"), (15, "$10–14.99"), (20, "$15–19.99"), (30, "$20–29.99"), (50, "$30–49.99")):
        if p < hi: return lab
    return "$50+"


def main():
    cands = list(csv.DictReader(CAND.open()))
    games = [g for g in csv.DictReader(GAMES.open()) if g["type"] in ("game", "")]
    success = [g for g in games if is_success(g)]
    small = [g for g in success if is_small(g)]
    summary = {"released_in_window": len(cands),
               "with_1000_reviews": len(games),
               "successes": len(success),
               "small_scope_successes": len(small)}
    print("## Funnel\n")
    for k, v in summary.items():
        print(f"- {k}: {v}")

    for label, grp in (("All successes", success), ("Small-scope successes", small)):
        table(f"Top genres — {label}", tag_lift(games, grp, "genres", min_n=3, top=15),
              ["Genre", "Games", "Share of group", "Hit rate (≥80% among ≥1k-review games)"])
        table(f"Top tags — {label}", tag_lift(games, grp, "top_tags", min_n=5, top=30),
              ["Tag", "Games", "Share of group", "Hit rate"])
        bands = Counter(price_band(num(g["price_usd"])) for g in grp)
        order = ["free", "$0.01–4.99", "$5–9.99", "$10–14.99", "$15–19.99", "$20–29.99", "$30–49.99", "$50+", "unknown"]
        table(f"Price bands — {label}", [(b, bands[b], f"{bands[b]/len(grp):.0%}") for b in order if bands[b]],
              ["Price", "Games", "Share"])
        months = Counter(g["release_date"][:7] for g in grp)
        table(f"Release month — {label}", sorted(months.items()), ["Month", "Games"])
        def med(field):
            v = [num(g[field]) for g in grp if num(g[field]) not in (None, 0)]
            return round(st.median(v), 1) if v else ""
        table(f"Medians — {label}", [
            ("Price (USD, paid)", med("price_usd")),
            ("Reviews", med("review_count")),
            ("Review %", med("review_pct")),
            ("SteamSpy owners (midpoint)", med("ss_owners_mid")),
            ("Median playtime (min)", med("ss_median_playtime_min")),
            ("Storage (GB)", med("storage_gb")),
            ("Languages", med("languages")),
            ("Screenshots", med("screenshots")),
            ("Trailers", med("trailers")),
            ("Early Access share", f"{sum(g['early_access']=='1' for g in grp)/len(grp):.0%}"),
            ("Self-published share", f"{sum(g['self_published']=='1' for g in grp)/len(grp):.0%}"),
            ("Single-player share", f"{sum(g['single_player']=='1' for g in grp)/len(grp):.0%}"),
            ("Multiplayer share", f"{sum(g['multiplayer']=='1' for g in grp)/len(grp):.0%}"),
            ("Co-op share", f"{sum(g['coop']=='1' for g in grp)/len(grp):.0%}"),
            ("Mac / Linux share", f"{sum(g['mac']=='1' for g in grp)/len(grp):.0%} / {sum(g['linux']=='1' for g in grp)/len(grp):.0%}"),
        ], ["Metric", "Value"])
        summary[label] = {"count": len(grp)}

    top = sorted(small, key=lambda g: -num(g["review_count"], 0))[:60]
    table("Top 60 small-scope successes by review count", [
        (g["name"], g["release_date"], g["price_usd"], g["review_count"], g["review_pct"],
         g["developers"][:30], "; ".join(split("top_tags", g)[:5])) for g in top],
        ["Game", "Released", "Price", "Reviews", "%", "Developer", "Top tags"])
    OUT.write_text(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
