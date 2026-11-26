# About 1 in 5 "new releases" with ≥1k reviews are Early Access graduates or re-releases; filter them by first-review date

- Area: market
- Date / source: 2026-11-26, projects/001-steam-market-research (iteration 002): research/processed/analysis.md, reports/market-report.md
- Confidence: high
- Apply when: building any "what launched successfully in period X" dataset or choosing comparables.

Steam's release date is the 1.0 date. Of the 744 games released 2025-11 → 2026-11 with ≥1,000 reviews, 162 (22%) had their first Steam review more than 45 days earlier. Examples: Valheim, Palworld, Enshrouded, Timberborn, TCG Card Shop Simulator, Rhythm Doctor. Their review counts reflect years of sales.

Detect them by comparing the review histogram's `start_date` with the release date. Exclude them from "new launch" benchmarks; keep them only as genre-demand evidence. Doing so moved our small-scope target from 332 to 250 hits.
