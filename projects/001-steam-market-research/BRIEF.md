# 001 — Steam market research (last 12 months)

- ID: 001
- Type: research
- Start: 2026-11-26
- Window studied: games released on Steam 2025-11-26 → 2026-11-26
- Status: report delivered 2026-11-26 (reports/market-report.md); awaiting direction choice

## Goal
Build a dataset and report of successful Steam releases from the past 12 months, so we
can choose what kind of game the factory should build first — specifically, games a
small team could plausibly ship in about one month.

## Definition of "successful" (confirmed by user 2026-11-26)
- At least **1,000 user reviews** (very roughly 30k–60k+ copies sold, using the usual
  30–60 sales-per-review estimates), and
- Review score of at least **80% positive**.
- Two segments are reported separately:
  1. **All successes** — gives the overall market picture.
  2. **Small-scope successes** — not from a major publisher, price ≤ $20, and
     install size ≤ 10 GB (or unknown). This is our real target.

## Data to collect per game
App id, name, release date, developer, publisher, price, discounts at launch, genres,
user tags (with votes), review count and % positive, estimated owners (SteamSpy),
peak/average playtime, languages, Early Access yes/no, single/multiplayer, Steam
Deck status, store description length, number of screenshots/trailers, DLC count.

## Sources (public, rate-limited, used politely)
- Steam Store search results (candidate list by release date) — `store.steampowered.com/search`
- Steam Store `appdetails` API — metadata, price, genres
- Review score and count: taken from the Steam search result row (the `appreviews`
  API redirected to the store homepage on 2026-11-26)
- SteamSpy API — owner estimates, tags, playtime
- Not used: SteamDB (its terms forbid scraping). Paid tools: not used (user chose free public sources only).

## Outputs
- `research/raw/` — untouched API responses (JSON), dated
- `research/processed/games.csv` — one row per game
- `research/scripts/` — reproducible scraper and analysis scripts
- `reports/market-report.md` — findings: top genres/tags, price bands, release-month
  patterns, what small-scope hits have in common, and 3–5 candidate game directions
- New topic files in `memories/market/`

## Success metrics
- Covers every Steam game in the window that meets the success bar (no manual cherry-picking).
- Each claim in the report traces back to the dataset or a cited source.
