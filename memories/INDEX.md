# Memory index

Read this at the start of every session. One line per memory: `path — learning (confidence)`.

## process
- `process/ask-user-via-input-dialogs` — ask for input through dialogs, never plain chat (high)
- `process/memory-files-named-by-topic` — one memory per file, named `<area>/<topic-slug>.md` (high)
- `process/delegate-to-subagents-keep-main-context` — main session orchestrates; research, data, drafting and implementation go to parallel subagents (high)
- `process/parallel-subagents-burn-usage-limit` — 4–5 heavy parallel agents can hit the 5-hour limit; resume via SendMessage, cap at 2–3 (medium)
- `process/steam-review-lead-time-three-weeks` — submit Steam build ≥4 weeks before launch; reviews take up to 12 business days (high)
- `process/steam-direct-fee-pay-two-games-ahead` — pay each $100 Steam Direct fee ≥30 days ahead; pay for game N+2 when N launches (medium)

- `process/check-team-enjoys-genre-before-building` — market lift isn't enough; confirm the team enjoys the genre first; organizing and incremental are out, platformers in (high)
- `process/no-production-work-before-fun-gate-passes` — no store/art/polish until the week-1 fun gate passes; playable build in 1–2 days (high)

## market
- `market/small-scope-steam-hit-base-rate-under-1-percent` — only 0.81% of releases become small-scope hits (≥1k reviews, ≥80%); median hit ≈$340k net (est.) (high)
- `market/small-scope-winning-tags-organizing-jobsim-incremental-coop` — Organizing/Mining/Investigation/Job Sim/Co-op/Relaxing/Incremental over-index; 2D platformer, arcade, tactics saturated (medium)
- `market/small-scope-price-7-to-15-dollars-never-under-5` — price $7.99–14.99; <$5 is 42% of releases with 1/6 the hit rate (medium)
- `market/small-scope-hits-are-small-builds-single-player-3-to-9-hours` — hits are ≤2 GB, single-player, 3–9 h; co-op = reach + variance (medium)
- `market/release-tuesday-to-thursday-not-weekends` — Thu/Tue launch; weekend releases almost never hit (medium)
- `market/early-access-graduates-inflate-new-release-lists` — 22% of ≥1k-review "new releases" are EA grads/re-releases; filter by first-review date (high)
- `market/steam-search-review-count-is-english-only` — search-row review counts are language-filtered; all-language totals ≈1.39× (high)
- `market/steamspy-has-no-data-for-most-new-games` — SteamSpy owners/tags empty for ~3/4 of new games; use Steam search tags + histogram (high)
- `market/gambling-tag-cooling-incremental-supply-rising-2026` — Gambling-tag hit rate fell below base by Q3 2026 while Incremental supply rose to 9.3% of releases; keep the reveal, drop the casino skin; Mining still under-supplied (medium)
## design
- `design/organizing-hits-count-the-mess-and-unlock-speed` — organizing hits pitch a counted mess ("3,072 books"), show the fill-up, and unlock speed-ups (medium)
- `design/second-verb-needed-as-organizing-supply-explodes` — Organizing releases 7→192/quarter in 2026; add a craft/repair/deduce/pack verb or new view (medium)
- `design/freeform-scoring-beats-single-solution-in-cozy-puzzles` — single-solution cozy puzzles score 72–79%, freeform ones 94–99% (low)
- `design/knolling-scorer-groups-by-neighbours-at-smallest-gap` — tidiness grouping = aligned neighbours at the smallest gap, best of type/colour; centre-kNN fails tidy rows (medium)
- `design/rotating-sprites-need-light-neutral-shading` — items that rotate get symmetric form shading and no baked shadow; the engine draws one soft shadow (medium)
- `design/encode-pacing-promises-as-unit-tests` — test first-upgrade time, pity gap and roll odds against balance JSON with seeded sims (medium)
- `design/colour-sort-palette-check-cvd-delta-e` — colour-scored palettes: check ΔE00 ≥10 under protan/deutan/tritan simulation, spread lightness, keep a non-colour route (high)
## tech
- `tech/godot-gdscript-is-default-engine` — default engine is Godot 4 + GDScript; deviate only with a written reason (medium)
- `tech/godot-headless-build-recipe` — Godot imports/tests/exports fully headless here from GitHub release binaries (high)
- `tech/container-network-blocks-steam-hosts` — SteamCMD, Steam partner site and .NET SDK hosts are blocked; deploy from GitHub Actions (high)
- `tech/steam-upload-ci-steam-deploy-action` — upload via game-ci/steam-deploy to a beta branch, human sets live (medium)
- `tech/steam-ai-disclosure-player-facing-only` — disclose AI art/audio/text players consume; AI-written code exempt (medium)
- `tech/git-lfs-for-binary-assets` — binaries in LFS, Godot text files in git, no .godot/ or builds (medium)
- `tech/gut-fails-tests-on-unasserted-engine-errors` — GUT 9.7 fails tests on unexpected engine errors/push_error; assert intended ones, avoid error-logging APIs (high)
- `tech/godot-generate-project-settings-headless` — generate InputMap/bus layout via headless script + ProjectSettings.save(); joypad device -1 (high)
- `tech/godot-headless-capture-xvfb-write-movie` — screenshots/clips in the container: xvfb-run + opengl3 + --write-movie + an --autoplay user arg (high)
- `tech/godot-macos-export-unsigned-from-linux` — Linux exports a universal ad-hoc-signed macOS .app zip; needs import_etc2_astc=true; unnotarized, players allow once (high)
- `tech/godot-2d-glow-additive-layers-behind-and-in-front` — fake glow with ADD-blend draw layers + radial gradient; big glow behind the subject or it washes out (high)
- `tech/macos-gatekeeper-unnotarized-builds-need-open-anyway` — unsigned Mac builds need Open Anyway / xattr; notarize for release (high)

## marketing
- `marketing/coming-soon-page-live-five-weeks-before-launch` — Coming Soon page live ~5 weeks before launch (official min 2 weeks) (medium)
- `marketing/steam-release-blocks-discounts-30-days` — release blocks discounts 30 days except ≤40% launch discount; release ≥30 days before a seasonal sale (high)
- `marketing/next-fest-once-per-game-plan-which-game` — Next Fest is once per unreleased game with a demo; assign fests to specific games (high)
- `marketing/steam-refund-two-hours-short-games` — <2h playtime refunds; short games need >2h value or low price (high)
- `marketing/wishlist-conversion-0-1-to-0-15x-first-week` — plan week-1 sales at 0.10–0.15x launch wishlists, year-1 at ~0.7x; week-1 review score is the swing factor (medium)
- `marketing/popular-upcoming-unreachable-after-june-2026` — Popular Upcoming needs ~80k wishlists since 2026-06; invest in tags/capsule for Personal Calendar instead (low)
- `marketing/boxleiter-multiplier-about-30x-for-recent-games` — estimate units as reviews × 30 (20–60 by score/price), not the old 80x (medium)
- `marketing/capsule-art-first-in-marketing-budget` — first marketing money goes to capsule art, before trailer, ads or PR (medium)
- `marketing/no-paid-ads-for-games-under-10-dollars` — at ~$1/wishlist, ads break even at best for ≤$10 games; only small capped tests (medium)
- `marketing/developer-homepage-followers-compound-across-releases` — link every game to one Developer Homepage; its followers get release emails (medium)
- `marketing/short-form-video-is-primary-free-channel` — TikTok/Shorts/Reels are the main free channel and the hook test (medium)
- `marketing/next-fest-registration-needs-coming-soon-page-live` — Next Fest requires the page public as Coming Soon *at registration*; submit the store page ~3 weeks before the deadline (medium-high)
- `marketing/store-screenshots-16-9-capture-from-16-10-game` — Steam screenshots are 16:9 ≥1920×1080; 16:10 Deck-native games need an expand-aspect 16:9 capture mode early (medium)
- `marketing/name-check-via-steam-search-json-organizing-words-taken` — name-check via Steam search JSON (match title substrings, then appdetails); Tidy/Sort/Neat/Unpack/Everything names taken; user runs TM search (high)
