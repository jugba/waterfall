# Memory index

Read this at the start of every session. One line per memory: `path — learning (confidence)`.

## process
- `process/ask-user-via-input-dialogs` — ask for input through dialogs, never plain chat (high)
- `process/memory-files-named-by-topic` — one memory per file, named `<area>/<topic-slug>.md` (high)
- `process/delegate-to-subagents-keep-main-context` — main session orchestrates; research, data, drafting and implementation go to parallel subagents (high)
- `process/steam-review-lead-time-three-weeks` — submit Steam build ≥4 weeks before launch; reviews take up to 12 business days (high)
- `process/steam-direct-fee-pay-two-games-ahead` — pay each $100 Steam Direct fee ≥30 days ahead; pay for game N+2 when N launches (medium)

## market
- `market/small-scope-steam-hit-base-rate-under-1-percent` — only 0.81% of releases become small-scope hits (≥1k reviews, ≥80%); median hit ≈$340k net (est.) (high)
- `market/small-scope-winning-tags-organizing-jobsim-incremental-coop` — Organizing/Mining/Investigation/Job Sim/Co-op/Relaxing/Incremental over-index; 2D platformer, arcade, tactics saturated (medium)
- `market/small-scope-price-7-to-15-dollars-never-under-5` — price $7.99–14.99; <$5 is 42% of releases with 1/6 the hit rate (medium)
- `market/small-scope-hits-are-small-builds-single-player-3-to-9-hours` — hits are ≤2 GB, single-player, 3–9 h; co-op = reach + variance (medium)
- `market/release-tuesday-to-thursday-not-weekends` — Thu/Tue launch; weekend releases almost never hit (medium)
- `market/early-access-graduates-inflate-new-release-lists` — 22% of ≥1k-review "new releases" are EA grads/re-releases; filter by first-review date (high)
- `market/steam-search-review-count-is-english-only` — search-row review counts are language-filtered; all-language totals ≈1.39× (high)
- `market/steamspy-has-no-data-for-most-new-games` — SteamSpy owners/tags empty for ~3/4 of new games; use Steam search tags + histogram (high)
## design
## tech
- `tech/godot-gdscript-is-default-engine` — default engine is Godot 4 + GDScript; deviate only with a written reason (medium)
- `tech/godot-headless-build-recipe` — Godot imports/tests/exports fully headless here from GitHub release binaries (high)
- `tech/container-network-blocks-steam-hosts` — SteamCMD, Steam partner site and .NET SDK hosts are blocked; deploy from GitHub Actions (high)
- `tech/steam-upload-ci-steam-deploy-action` — upload via game-ci/steam-deploy to a beta branch, human sets live (medium)
- `tech/steam-ai-disclosure-player-facing-only` — disclose AI art/audio/text players consume; AI-written code exempt (medium)
- `tech/git-lfs-for-binary-assets` — binaries in LFS, Godot text files in git, no .godot/ or builds (medium)
- `tech/gut-fails-tests-on-unasserted-engine-errors` — GUT 9.7 fails tests on unexpected engine errors/push_error; assert intended ones, avoid error-logging APIs (high)
- `tech/godot-generate-project-settings-headless` — generate InputMap/bus layout via headless script + ProjectSettings.save(); joypad device -1 (high)
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
