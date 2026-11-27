# Rockhound (working title)

- ID: 003
- Type: game
- Start: 2026-11-27 · Target ship date: TBD after fun gate
- Status: prototype

## Goal
A short, tactile geode-cracking incremental for Steam at **$7.99**: dig rocks, crack them open
for a random crystal reveal, polish and sell, upgrade toward automation. About 3–4 h to credits
plus catalogue completion. Single-player, 2D, mouse + full controller, 1280x800 (Deck), Win/Linux/Mac.

**Fun gate first.** No store page, art, audio sourcing or polish until the user has played the
greybox and says the first 5 minutes are fun (`memories/process/no-production-work-before-fun-gate-passes`,
`memories/process/check-team-enjoys-genre-before-building`; why: `projects/002-cozy-organizing-sim/POSTMORTEM.md`).
Gate build: `playtest/PLAYTEST.md`. If it fails, reshape toward concept B (claw machine), which reuses
the rarity, upgrade and save code (`projects/_research/game-003-direction.md` §3).

## Why this (evidence)
All from `projects/_research/game-003-direction.md` (concept A, score 26/30):
- Mining tag 4.9× core-hit lift; Physics + Incremental 9.1×; Relaxing + Incremental 5.7× (`projects/001-steam-market-research` tag_opportunity.csv).
- No geode/rockhound title with ≥200 reviews in 30,708 releases; the reveal hook of Scritchy Scratchy /
  Bills Must Be Paid without the cooling Gambling tag (`memories/market/gambling-tag-cooling-incremental-supply-rising-2026`).
- Geode-cracking clips are a proven viral format (~7M views on one TikTok; source in the research doc).
- Comparables: Big Dig ($7.99, 1,009 reviews, 96%), Sludgineers ($6.99, 2,234, 90%), Space Rock Breaker ($2.99, 5,073, 96%).
- Price band: `memories/market/small-scope-price-7-to-15-dollars-never-under-5`.
- Next Fest Feb 2027 is the intended fest for this game, but only if Steamworks onboarding and the
  Coming Soon page land in time (research doc §0); no dates are committed until the fun gate passes.

## Scope
Must have (the greybox already has the first version of each):
- Dig: hold on the rock face to chip chunks; chunks drop geodes whose shell hints at rarity.
- Crack: hold to strike; cracks spread, light leaks out (coloured for rare+), burst reveal, slow-mo for rare+.
- Rarity table in data (`game/data/balance.json`), pity timer, visible odds in the collection book.
- Sell → money → upgrades: pick power, extra geodes, luck, polish (hold-and-release minigame), auto-digger (idle).
- Collection book with sets that give permanent value bonuses; depth levels that raise value.
- Save/load, controller, settings, pause.

After the gate (if it passes): quarries 2–3, tumbler idle, conveyor, demo cap (first lease paid),
real crack shader/fracture, crystal art, recorded crack/pop audio, Steam achievements.

Cut list (first to go if we slip): roguelite rent layer → quarry 4 and the mystery → endless mode →
saw cut (keep polish) → minerals 60→40 → conveyor visual (keep the auto-digger).
**Never cut:** the crack-and-reveal feel, its sound, and the first automation.

## Success metrics
- Fun gate: the user (and 2–3 testers) choose to keep cracking past 5 minutes and describe the reveal
  positively without prompting (`playtest/PLAYTEST.md`).
- Hook test: 3–5 crack clips posted; kill/reshape if all stay under ~2k views (research doc §3).
- Launch metrics (set after the gate): wishlists at Next Fest, reviews and score in the first 30 days.
