#!/usr/bin/env python3
"""Walk Steam store search (games only, newest first) and record every game released
inside the study window, with the review summary shown in the search row.

Raw pages are cached gzipped in research/raw/search/ (git-ignored: large, re-fetchable).
Output: research/processed/candidates.csv (every game in the window).

Usage: python3 collect_candidates.py [--start 2025-11-26] [--end 2026-11-26]
"""
import argparse, csv, gzip, html, json, re, sys, time, urllib.request
from datetime import datetime, date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "raw" / "search"
OUT = ROOT / "processed" / "candidates.csv"
URL = ("https://store.steampowered.com/search/results/?sort_by=Released_DESC&category1=998"
       "&infinite=1&start={start}&count=100&cc=us&l=english&ndl=1")
UA = "Mozilla/5.0 (research script; polite, 1 req/s)"

ROW = re.compile(r'<a href="https://store\.steampowered\.com/(app|bundle|sub)/[^"]*"(.*?)</a>', re.S)


def fetch(start, retries=5):
    cache = RAW / f"page_{start:06d}.json.gz"
    if cache.exists():
        return json.loads(gzip.decompress(cache.read_bytes()))
    for attempt in range(retries):
        try:
            req = urllib.request.Request(URL.format(start=start), headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read()
            data = json.loads(body)
            cache.write_bytes(gzip.compress(body))
            time.sleep(1.0)
            return data
        except Exception as e:  # network hiccup / rate limit: back off
            wait = 10 * (attempt + 1)
            print(f"  start={start} error {e!r}, retry in {wait}s", file=sys.stderr)
            time.sleep(wait)
    raise RuntimeError(f"giving up at start={start}")


def parse_date(s):
    s = s.strip()
    for fmt in ("%b %d, %Y", "%d %b, %Y", "%b %Y"):
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            pass
    return None  # "Coming soon", "Q1 2027", "To be announced", ...


def g(pat, text, default=""):
    m = re.search(pat, text, re.S)
    return html.unescape(m.group(1).strip()) if m else default


def parse_rows(results_html):
    for kind, body in ROW.findall(results_html):
        if kind != "app":
            continue
        tip = g(r'data-tooltip-html="([^"]*)"', body)
        pct = g(r"(\d+)% of the", tip)
        cnt = g(r"of the ([\d,]+) user reviews", tip).replace(",", "")
        yield {
            "appid": g(r'data-ds-appid="(\d+)"', body),
            "name": g(r'<span class="title">(.*?)</span>', body),
            "released_raw": g(r'search_released[^>]*>(.*?)<', body),
            "review_label": tip.split("<br>")[0] if tip else "",
            "review_pct": pct,
            "review_count": cnt,
            "price_final_cents": g(r'data-price-final="(\d+)"', body),
            "discount_pct": g(r'data-discount="(\d+)"', body),
            "tagids": g(r'data-ds-tagids="(\[[^\]]*\])"', body),
            "win": int("platform_img win" in body),
            "mac": int("platform_img mac" in body),
            "linux": int("platform_img linux" in body),
        }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2025-11-26")
    ap.add_argument("--end", default="2026-11-26")
    a = ap.parse_args()
    lo, hi = date.fromisoformat(a.start), date.fromisoformat(a.end)
    RAW.mkdir(parents=True, exist_ok=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)

    rows, seen, start, old_streak = [], set(), 0, 0
    while True:
        data = fetch(start)
        page = list(parse_rows(data.get("results_html", "")))
        if not page:
            break
        for r in page:
            d = parse_date(r["released_raw"])
            r["release_date"] = d.isoformat() if d else ""
            if d and d < lo:
                old_streak += 1
            elif d:
                old_streak = 0
            if d and lo <= d <= hi and r["appid"] not in seen:
                seen.add(r["appid"])
                rows.append(r)
        print(f"start={start} last={page[-1]['released_raw']!r} kept={len(rows)}", flush=True)
        if old_streak >= 300:  # well past the window (search order is not perfectly strict)
            break
        start += 100

    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows)} games to {OUT}")


if __name__ == "__main__":
    main()
