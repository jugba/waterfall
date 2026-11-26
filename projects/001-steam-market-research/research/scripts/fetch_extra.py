#!/usr/bin/env python3
"""Fetch two extra raw datasets used by analyze.py for sanity checks (added in iteration 002).

1. Steam tag id -> name list (store tagdata endpoint), so candidates.csv tagids can be named.
   -> research/raw/tags/populartags_english.json
2. Steam review histogram per enriched game (store appreviewhistogram endpoint). Its
   `start_date` is the date of the first review and its rollups give up/down counts per
   period, so we can tell games that really launched in the window from Early Access
   graduates / re-releases whose reviews mostly predate it.
   -> research/raw/histogram/<appid>.json.gz

Raw responses are stored untouched. Cached files are not re-fetched. ~1 request/second.
Usage: python3 fetch_extra.py
"""
import csv, gzip, json, sys, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = ROOT / "processed" / "games.csv"
UA = "Mozilla/5.0 (research script; polite)"
TAGS_URL = "https://store.steampowered.com/tagdata/populartags/english"
HIST_URL = "https://store.steampowered.com/appreviewhistogram/{id}?l=english&review_score_preference=0"


def get(url, retries=4):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read()
            json.loads(body)  # validate
            return body
        except Exception as e:
            wait = 20 * (attempt + 1)
            print(f"  {url}: {e!r}, retry in {wait}s", file=sys.stderr, flush=True)
            time.sleep(wait)
    return None


def main():
    tags = ROOT / "raw" / "tags" / "populartags_english.json"
    tags.parent.mkdir(parents=True, exist_ok=True)
    if not tags.exists():
        body = get(TAGS_URL)
        if body:
            tags.write_bytes(body)
    hdir = ROOT / "raw" / "histogram"
    hdir.mkdir(parents=True, exist_ok=True)
    ids = [g["appid"] for g in csv.DictReader(GAMES.open())]
    for i, appid in enumerate(ids, 1):
        out = hdir / f"{appid}.json.gz"
        if out.exists():
            continue
        body = get(HIST_URL.format(id=appid))
        if body:
            out.write_bytes(gzip.compress(body))
        time.sleep(1.0)
        if i % 50 == 0:
            print(f"  {i}/{len(ids)}", flush=True)
    print("done")


if __name__ == "__main__":
    main()
