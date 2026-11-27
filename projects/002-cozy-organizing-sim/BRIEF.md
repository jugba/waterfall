# Knolling Co. (working title)

- ID: 002
- Type: game
- Start: 2026-11-30 · Target ship date: 2027-02-11 (Thursday)
- Status: abandoned 2026-11-27 (no-go at week-1 playtest — see POSTMORTEM.md)

## Goal
Ship a polished 2D top-down organizing job sim on Steam (Windows + Linux/Deck) at $7.99: clients'
bags, drawers and toolboxes are tipped onto your desk; you clean and sort them into a perfect knolling
flat-lay, photograph it, and pack everything back. Done = 30 jobs, about 4 h to credits, Deck Verified
requested, ≥90% positive in the first 30 days.

## Why this (evidence)
- Direction chosen from `projects/001-steam-market-research/reports/market-report.md` (direction 1).
  Concept chosen from three in `concepts.md` (scores 21 vs 17 vs 17).
- Organizing is the top-lift tag for small-scope hits (5.4×); Relaxing + Job Simulator is the best pair
  (17.9×) [`memories/market/small-scope-winning-tags-organizing-jobsim-incremental-coop`].
- Comparables: Librarian ($5.99, 29.7k reviews, 93%), DinoBones ($5.99, 2.9k, 95%), Sort Them Ducks
  ($5.99, 2.6k, 92%), Supermarket Chaos ($4.99, 4.1k, 90%), Moldwasher (2D, $8.99, 1.1k, 92%).
  Data: `projects/001-steam-market-research/research/processed/games_analyzed.csv`.
- Differentiation: the 2026 hits are first-person "walk and put back" clones (Organizing releases per
  quarter went 7 → 15 → 60 → 192 in 2026; `concepts.md` §1.2 pattern 9). Ours uses the top-down view of
  #knolling / "satisfying" videos, a freeform neatness score instead of one correct answer, and a packing
  puzzle (`memories/design/*`).
- Hook reads in a muted 5-second clip (dump → grid timelapse)
  [`memories/marketing/short-form-video-is-primary-free-channel`].
- Price $7.99 for 3–5 h [`memories/market/small-scope-price-7-to-15-dollars-never-under-5`]; >2 h before
  credits [`memories/marketing/steam-refund-two-hours-short-games`].
- Fits the pipeline: one core system, data-driven content, flat 2D sprites with no animated characters
  (`concepts.md` §3).

## Design summary
- **Loop per job (6–12 min):** dump (physics scatter) → sort on a soft grid with magnetic alignment →
  one-gesture fixes (wipe, untangle, sharpen, cap) → photo with neatness score (alignment, spacing,
  grouping by type/colour/size, symmetry; visible reasons for each point) → pack back into the container
  (rotate, fit, close the lid) → client note + pay.
- **Meta:** pay buys speed-up tools (sorting trays, auto-align ruler, colour-sort brush, sweep, bigger
  desk); 5 client tiers (pencil case → magician's trunk); ~300-item catalogue ("Unknown" → identified);
  photo album; recurring clients whose bags change between visits.
- **Controls:** mouse drag; controller cursor + grab, d-pad nudge to grid, shoulder buttons rotate.
  1280×800, text ≥28 px, no timed input.
- **Art:** top-down flat 2D; one sprite per item, with dirt/shadow/highlight by shader; 5 desk surfaces;
  15–20 containers; clients only as Polaroids and notes. Item sprites AI-assisted then hand-cleaned or
  licensed; capsule, logo and key art human-made. Every asset logged in `assets/LICENSES.md`; Steam
  content survey discloses pre-generated AI art [`memories/tech/steam-ai-disclosure-player-facing-only`].
- **Audio:** per-material click/snap sounds (the satisfying layer), 3–4 lo-fi music tracks (licensed).

## Scope
Must have:
- Core loop: dump, sort with snapping and alignment, neatness scorer with on-screen reasons, packing, payday.
- 30 jobs across 4 client tiers, defined as data (JSON); ~200 items minimum.
- 6 speed-up tools; item catalogue; credits after job 30.
- Full controller support, Steam Deck pass at 1280×800, Steam achievements (≈15), Steam Cloud saves.
- Settings, pause, save/load from `_template`; English + string table ready for translation.
- Store assets: capsules, ≥5 screenshots, 1 trailer (gameplay-first).

Should have:
- 5th client tier, ~300 items, two more fix micro-actions.
- 8 extra languages (FR, DE, ES, PT-BR, RU, JA, KO, ZH-Hans): the UI is light, so translation is cheap.
- "Free desk" mode: procedurally mixed messes, untimed, endless.
- Recurring-client story beats.

Cut list (first to go if we slip, in order):
1. Free-desk mode (keep a "replay any job" button instead).
2. Photo album export / share.
3. 5th client tier.
4. Recurring-client story (generic client notes only).
5. Fix micro-actions down to 2 types.
6. Items 300 → 200; extra languages down to ZH-Hans + JA + DE.
Never cut: packing, neatness-score reasons, controller support.

## Schedule (T = Thu 2027-02-11; from `playbooks/monthly-cycle.md` and `playbooks/steam-launch-checklist.md`)
| Date | Development | Steam / marketing |
|---|---|---|
| Mon Nov 30 – Fri Dec 4 (T-10w) | Paper design, item list, art style test (10 sprites) | **Pay $100 Steam Direct fee now** (must be ≥30 days before T, i.e. by Jan 12); capsule art brief; title check |
| Dec 7 – 11 (T-9w) | Prototype: drag/snap/grid, scorer, 3 greybox containers. **Go/no-go: fun in 5 minutes** | Post 3–5 greybox clips (hook test); kill/reshape if all stay under ~2k views |
| Dec 14 – 18 (T-8w) | Vertical slice (one tier, juicy) | Content survey incl. AI disclosure; store page draft; **submit store page review by Fri Dec 18** (7 business days, US holidays ahead) |
| Dec 21 – Jan 8 (T-7w → T-5w) | Content production: tiers 2–4, tools, catalogue (holiday weeks: plan reduced capacity) | **Thu Jan 7: Coming Soon page live**; trailer v1; creator list |
| Thu Jan 14 (T-4w) | **Feature-complete build submitted for review** (launched via Steam Play ≥5 min) | Clips 3–5/week, creator outreach |
| Jan 18 – Feb 5 (T-3w → T-1w) | Polish, playtests, bugs, Deck testing | Launch discount configured (10–15%, 7 days); Deck review requested; press kit |
| Thu Feb 11 (T) | Launch | Wishlist emails automatic; launch event; post on Developer Homepage |
| Feb 11 – Mar 13 | Patch from feedback | 30-day discount cooldown ends Mar 13 → eligible for **Spring Sale Mar 18–25** (launch is 35 days before it) |

Calendar notes:
- Feb 11 is a Thursday (best weekday [`memories/market/release-tuesday-to-thursday-not-weekends`]) and is
  35 days before the Spring Sale, outside the 30-day window [`memories/marketing/steam-release-blocks-discounts-30-days`].
  Latest safe date is Tue Feb 16; Tue Feb 9 is the fallback if we are early.
- Feb 2027 Next Fest (Feb 22 – Mar 1) is *not* for this game: it will already be released. It suits game
  003 if 003 launches after the Spring Sale (~Thu Apr 1), with registration by Jan 10
  [`memories/marketing/next-fest-once-per-game-plan-which-game`].
- Shop Keeper Fest (Jan 25 – Feb 1) overlaps our Coming Soon window; check eligibility for upcoming games
  with no Shop Keeper tag (unverified).

## Success metrics
- Hook test (by Dec 18): at least one prototype clip >10k views; 5-minute playtest rated fun by 3 of 4 testers.
- Wishlists at launch: ≥3,000 (target), ≥7,000 (stretch). Track per platform with UTM links.
- Week-1 sales ≥ 0.10× launch wishlists [`memories/marketing/wishlist-conversion-0-1-to-0-15x-first-week`].
- Reviews in first 30 days: ≥100 (top-10% of releases), ≥90% positive.
- Refund rate <10%; median playtime >2 h.
- Year-1 net revenue: typical case $12k–60k (100–500 reviews); hit case $120k–360k (1k–3k reviews), using
  reviews × 30 × $7.99 × 0.5 [`memories/marketing/boxleiter-multiplier-about-30x-for-recent-games`].
- Developer Homepage followers gained (factory KPI).

## Decisions (user, 2026-11-26)
- Concept: **Knolling Co.**
- Steamworks partner account: **not yet created** → user to start onboarding now (15–30 days).
  Launch date 2027-02-11 is **at risk**; fallback Tue 2027-02-16 (last date eligible for Spring Sale),
  else after the Spring Sale.
- Art: human-made capsule + logo; AI-assisted item sprites; complete Steam AI disclosure.
- Next Fest Feb 2027: not for 002; reserved for game 003.
