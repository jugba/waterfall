# Hookmaw (working title)

- ID: 005
- Type: game
- Start: 2026-11-27 · Target ship date: **TBD** (launch date is set only after the fun gate passes)
- Status: prototype (fun-check greybox v0.1.0 built 2026-11-27)

## Goal
A short, premium, single-player top-down action game about one verb: **throw a hook, yank prey in,
eat it, grow**. You are Morsel, a tiny glowing deep-sea blob whose lure *is* its hook. Every meal
makes you visibly bigger and stronger; eating an archetype grafts its trait onto your body
(shell plates, fins, horns, spines); every couple of minutes you evolve how the hook works; after
about 10 minutes of waves you are finally big enough to hook the Lantern Leviathan.
Keyboard + mouse and controller / Steam Deck (1280x800), Win/Linux/Mac.

### Title options (pick one before any store work; none name-checked yet, the Steam hosts are
blocked from the container, so check on store.steampowered.com + a TM search by hand)
1. **Hookmaw** (working title): the hook + the mouth, says the verb in one word.
2. **Lure & Gulp**: friendlier, cozy-leaning, reads well on a capsule.
3. **Abyss Snack**: funny, says "you are small and the sea is big".

### Originality
Inspired by the *mechanic* reviewed in `projects/_research/butcher-hero-app-review.md` (hook,
pull, eat, grow, absorb traits). Nothing of Butcher Hero is used: no name, characters, art, UI,
levels or text. Our theme (deep sea, a lure-hook blob, a lantern-fish boss), our names, our
shapes and our structure (one arena, waves, size-gated boss, evolution choices) are original.

## Premium positioning: "no timers, just eating"
The review's dominant complaints are respawn timers (5–24 h), pay-walled islands, misleading IAP and
online-only play; the praise is all about the 30-second loop (`butcher-hero-app-review.md`).
So Hookmaw sells the loop and none of the business model:
- **No timers, no energy, no waiting, no paywalls, no IAP, offline.** Enemies never "respawn later";
  the next wave arrives the moment you clear this one.
- **Continuous play:** a run is one unbroken ~10-minute feast to the boss, then endless mode.
  Death costs one wave, not the run (you restart the wave at the size you had when it began).
- Price band $7.99–14.99 (`memories/market/small-scope-price-7-to-15-dollars-never-under-5`);
  needs > 2 h of value (several arenas/bosses) or a low price
  (`memories/marketing/steam-refund-two-hours-short-games`).

## Why top-down (not side-on)
- The hook is aimed in **360°** with mouse or right stick; prey comes from every side, so
  positioning and the dodge matter. Side-on adds gravity and platforming that compete with the hook.
- Growth reads best top-down: the camera zooms out as you grow, so the world visibly shrinks around you.
- Trade-off: the user's favourite genre is the side-on platformer
  (`memories/design/user-loves-platformer-movement-music-levels-charm`). If the fun gate says
  "the hook is great but I miss platforming", a side-on variant is the first reshape to try.

## The fun gate (week 1, blocks all production work)
The user plays v0.1.0 for ~10–15 minutes (`playtest/PLAYTEST.md`) and answers the five questions.
**Go** only if all three are true:
1. **The hook feels great on its own**: throwing, the catch hitstop, yanking and the chomp are
   satisfying enough that they'd do it for a minute with no goal.
2. **Growing feels good**: they notice and enjoy getting bigger, the traits and the evolutions.
3. **One more run**: after the boss (or a death) they want to play again.
**No-go / reshape** if any is "meh": hook feel → retune `game/data/balance.json` (hook speed,
yank impulse, hitstop) and re-test; growth → stronger per-meal growth / more body changes;
structure → try the side-on variant or a roguelite map of arenas before abandoning.
No store page, art, music or polish before the gate passes
(`memories/process/no-production-work-before-fun-gate-passes`).
Known risk: the user found an incremental "boring" (`projects/003-rockhound/POSTMORTEM.md`), so
this prototype puts **active, physical moment-to-moment play first** (aim, dodge, timing), and
growth is a by-product of playing, never of waiting.

## Why this (evidence)
- Proven loop with real demand: Butcher Hero 4.69★ from 11,668 ratings; praise is for the loop,
  1★ reviews are about timers/paywalls (`projects/_research/butcher-hero-app-review.md`).
- The team must enjoy the genre (`memories/process/check-team-enjoys-genre-before-building`);
  this is an action game with moment-to-moment skill, not an idle/incremental.
- Pacing promises are tests (`memories/design/encode-pacing-promises-as-unit-tests`).

## Scope (for the month, if the gate passes)
Must have:
- The greybox loop as built: hook physics, struggle/yank, eat FX, growth curve, 4 traits with body
  changes, 4 hook evolutions, 5 archetypes, waves, size-gated boss with multi-bite fight.
- 3 arenas (deep reef → trench → abyss), each ~10 min to its boss, one new archetype each.
- Charm pass: real creature art, animated eat, music + SFX, hand-made arena dressing.
- Settings (shake, aim assist, rebinding), save/records, controller/Deck, Steam achievements.

Cut list (first to go if we slip, in order):
1. Third arena (ship 2 arenas + endless).
2. Endless-mode leaderboard (keep local records).
3. Fourth evolution tree level (keep one level per form).
4. Extra archetype per arena (reuse the five with new traits).
5. Hand-made arena dressing (keep procedural decor).

## Success metrics
- Fun gate: three "go" answers from the user.
- Playtest: a first-time player reaches the boss in 9–12 min and wants another run.
- Launch (if pursued): ≥ 4k wishlists at launch, ≥ 85% positive in the first 30 days.
