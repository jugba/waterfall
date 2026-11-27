# Postmortem — 002 Knolling Co. (abandoned at week-1 playtest)

## Numbers
- Time from concept pick to no-go: ~1 day (2026-11-26 → 2026-11-27).
- Built: greybox v0.1.0 (3 jobs, freeform neatness scorer, 35 tests, Win/Linux/macOS builds),
  store page draft, art direction + 12 SVG sprites, partial v0.2.0 polish.
- Playtest: user played the Mac build → "not an enjoyable game at all". Reason given: **the
  genre itself** (organizing games aren't fun to them, regardless of polish).

## What went well
- The go/no-go gate worked: we stopped after one day of build instead of four weeks.
- Pipeline proven end to end: template → playable build on the user's Mac in hours.
- Reusable leftovers: freeform scorer approach, palette/colour-blind check tooling, store-page
  and capsule-brief structure, Mac Gatekeeper instructions.

## What went wrong
- We picked the genre purely from market data. Nobody on the team checked first whether
  they enjoy playing that genre.
- Store page, art and polish work started in parallel *before* the fun check passed, so that
  effort was wasted.

## Lessons moved to memories/
- `process/check-team-enjoys-genre-before-building`
- `process/no-production-work-before-fun-gate-passes`

## Playbook changes
- monthly-cycle: fun gate at the end of week 1 blocks store page, art and polish work (except
  anything with a hard external deadline).
