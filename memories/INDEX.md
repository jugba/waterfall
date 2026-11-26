# Memory index

Read this at the start of every session. One line per memory: `path — learning (confidence)`.

## process
- `process/ask-user-via-input-dialogs` — ask for input through dialogs, never plain chat (high)
- `process/memory-files-named-by-topic` — one memory per file, named `<area>/<topic-slug>.md` (high)
- `process/delegate-to-subagents-keep-main-context` — main session orchestrates; research, data, drafting and implementation go to parallel subagents (high)
- `process/steam-review-lead-time-three-weeks` — submit Steam build ≥4 weeks before launch; reviews take up to 12 business days (high)
- `process/steam-direct-fee-pay-two-games-ahead` — pay each $100 Steam Direct fee ≥30 days ahead; pay for game N+2 when N launches (medium)

## market
## design
## tech
- `tech/godot-gdscript-is-default-engine` — default engine is Godot 4 + GDScript; deviate only with a written reason (medium)
- `tech/godot-headless-build-recipe` — Godot imports/tests/exports fully headless here from GitHub release binaries (high)
- `tech/container-network-blocks-steam-hosts` — SteamCMD, Steam partner site and .NET SDK hosts are blocked; deploy from GitHub Actions (high)
- `tech/steam-upload-ci-steam-deploy-action` — upload via game-ci/steam-deploy to a beta branch, human sets live (medium)
- `tech/steam-ai-disclosure-player-facing-only` — disclose AI art/audio/text players consume; AI-written code exempt (medium)
- `tech/git-lfs-for-binary-assets` — binaries in LFS, Godot text files in git, no .godot/ or builds (medium)
## marketing
- `marketing/coming-soon-page-live-five-weeks-before-launch` — Coming Soon page live ~5 weeks before launch (official min 2 weeks) (medium)
- `marketing/steam-release-blocks-discounts-30-days` — release blocks discounts 30 days except ≤40% launch discount; release ≥30 days before a seasonal sale (high)
- `marketing/next-fest-once-per-game-plan-which-game` — Next Fest is once per unreleased game with a demo; assign fests to specific games (high)
- `marketing/steam-refund-two-hours-short-games` — <2h playtime refunds; short games need >2h value or low price (high)
