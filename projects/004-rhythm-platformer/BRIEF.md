# Beatrunner (working title)

- ID: 004
- Type: game
- Start: 2026-11-27 · Target ship date: TBD (launch date set only after the fun gate passes)
- Status: prototype (fun-check greybox v0.1.0 built 2026-11-27)

## Goal
A short, very polished, single-player 2D action platformer in the genre the user loves (Rayman
Legends): movement that feels great on its own, and **music levels where the song drives the
level**. About 2–3 h, ~$9.99, keyboard + controller + Steam Deck (1280x800), Win/Linux/Mac.
An original game: our own hero (Pip, a round blob with headphones), our own levels and our own
procedurally generated music. Nothing from Rayman (characters, names, levels, art, music) is used.

## The hook
**Run to the beat.** In music levels the hero auto-runs at a speed locked to the song's audio
clock, so every jump sits on a kick, every punchable drum on a clap, every bounce pad on a
downbeat, and the collectible notes chime up a pentatonic scale as you chain them. Hitting an
action on the beat gives extra juice (PERFECT pop, flash, sparkle). Dying drops you back to the
last checkpoint with a count-in and the music re-synced, so retrying feels like rejoining a song.

## The fun gate (week 1, blocks all production work)
The user plays the v0.1.0 greybox for ~10 minutes on their Mac (`playtest/PLAYTEST.md`) and
answers the five questions. **Go** only if both are true:
1. Movement: running around the sandbox is fun *without* a goal (they replay a section because
   it feels good), and no move feels floaty, sticky or unfair.
2. Music level: they want to replay it for a cleaner run (fewer deaths / more "on beat"), and
   they can feel the actions landing on the music.
**No-go / reshape** if either is "meh". Movement no-go → retune `game/data/movement.json` and
re-test before anything else. Music no-go → try a non-auto-run variant (player controls speed,
beats only gate obstacles) before abandoning the hook.
No store page, art, real music or polish until the gate passes
(`memories/process/no-production-work-before-fun-gate-passes`).

## Why this (evidence)
- The user chose it: favourite game Rayman Legends for its movement feel, music levels and charm
  (`memories/design/user-loves-platformer-movement-music-levels-charm`, prompts/2026-11-26_001_factory-setup.md prompt 17).
- Two data-picked concepts in genres the user doesn't enjoy failed at the first playtest
  (`projects/002-cozy-organizing-sim/POSTMORTEM.md`, `projects/003-rockhound/POSTMORTEM.md`,
  `memories/process/check-team-enjoys-genre-before-building`).
- Market caution: 2D platformers are saturated on Steam
  (`memories/market/small-scope-winning-tags-organizing-jobsim-incremental-coop`), so the rhythm
  hook and feel have to carry the game; short-form video is the main free channel and rhythm
  runs clip well (`memories/marketing/short-form-video-is-primary-free-channel`).
- Price band and length: `memories/market/small-scope-price-7-to-15-dollars-never-under-5`,
  `memories/market/small-scope-hits-are-small-builds-single-player-3-to-9-hours`,
  `memories/marketing/steam-refund-two-hours-short-games`.

## Scope (for the month, if the gate passes)
Must have:
- The controller as in the greybox: run curves, variable jump, coyote + buffer, apex hang,
  fast-fall, wall slide/jump/run, dash, punch, glide; all tuning in `game/data/movement.json`.
- 3 worlds × (4 movement levels + 1 music level), each music level an original track with a
  generated beat map; checkpoints, collectible notes, on-beat scoring.
- Charm pass: hero animation, 3 world palettes, juice (already: squash/stretch, dust,
  afterimages, hitstop, camera look-ahead/shake).
- Controller/Deck, rebinding, settings, save, Steam achievements.

Cut list (first to go if we slip, in order):
1. Third world (ship 2 worlds × 5 levels).
2. Collectible-based unlocks / secret areas.
3. Per-level on-beat leaderboards and grades.
4. Music level variants (reverse/hard mode).
5. Glide and wall-run (keep jump, wall jump, dash, punch).

## Success metrics
Fun gate pass first. Then: playtesters replay the music level unprompted; Steam wishlists ≥ 5k
before launch; ≥ 85% positive in the first 30 days.
