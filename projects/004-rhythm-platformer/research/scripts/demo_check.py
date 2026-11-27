"""Demo / trailer presence for 2D-platformer- and Rhythm-tagged paid releases with >=100 reviews.
Input: ../raw/appdetails_genre/<appid>.json (Steam appdetails, fetched 2026-11-27) and
_ids_group_reviews_pct.csv (appid, P=platformer tag / R=Rhythm tag, search reviews, pct) built from
001's candidates.csv. Caveat: appdetails lists only demos still live, many are removed after launch.
Output: ../processed/demo_presence.csv"""
import csv, json
from pathlib import Path
from collections import defaultdict
R = Path(__file__).resolve().parents[1]
agg = defaultdict(lambda: [0, 0, 0])
for line in open(R / "raw/appdetails_genre/_ids_group_reviews_pct.csv"):
    id, g, rc, p = line.strip().split(",")
    d = json.load(open(R / f"raw/appdetails_genre/{id}.json")).get(id) or {}
    if not d.get("success") or d["data"].get("is_free"):
        continue
    rc, p = int(rc), int(p)
    band = "hit >=1k & >=80%" if rc >= 1000 and p >= 80 else ">=1k <80%" if rc >= 1000 else "300-999" if rc >= 300 else "100-299"
    a = agg[(g, band)]
    a[0] += 1; a[1] += bool(d["data"].get("demos")); a[2] += len(d["data"].get("movies") or [])
with open(R / "processed/demo_presence.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["group", "band", "paid_games", "demo_live", "demo_share", "avg_trailers"])
    for (g, b), (n, dm, mv) in sorted(agg.items()):
        w.writerow(["2D platformer tags" if g == "P" else "Rhythm tag", b, n, dm, round(dm / n, 2), round(mv / n, 1)])
