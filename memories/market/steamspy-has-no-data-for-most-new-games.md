# SteamSpy returns empty owners/tags for about 3/4 of recent games; take tags from Steam search and reviews from Steam endpoints

- Area: market
- Date / source: 2026-11-26, projects/001-steam-market-research (iteration 002): research/processed/analysis.md, reports/market-report.md
- Confidence: high
- Apply when: designing any data collection for Steam market research.

For 568 of 744 games released 2025-11 → 2026-11 with ≥1k reviews, SteamSpy returned:
- `positive/negative = 0`;
- owners of "0 .. 20,000";
- an empty tag list.

Only playtime fields were populated. Do not use SteamSpy owners. Better sources:
- Steam search rows (`data-ds-tagids`) give the top ~6 tags of every game.
- `store.steampowered.com/tagdata/populartags/english` maps those tag ids to names.
- The review histogram gives all-language review counts and the first-review date.
