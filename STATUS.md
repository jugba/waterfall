# Factory status — read this first on every resume

_Last updated: 2026-11-27 by the main session. Keep it current: update it whenever work starts,
finishes or waits on the user._

## Active projects (user chose parallel prototypes, 2026-11-27)
- `projects/004-rhythm-platformer` — **Beatrunner**, original rhythm platformer. Phase: **waiting on the user's fun gate**.
- `projects/005-hook-and-grow` — original premium hook→pull→eat→grow action game (inspired by the
  Butcher Hero review, `projects/_research/butcher-hero-app-review.md`; no timers/paywalls). Phase: **greybox**.

## Running work
| Work | Who | Started | Output |
|---|---|---|---|
| 005 hook-and-grow greybox + Mac/Win/Linux builds | subagent | 2026-11-27 | `projects/005-hook-and-grow/` |

## Next steps (in order)
1. Beatrunner 0.1.0 greybox delivered to the user 2026-11-27 (51 tests, Mac/Win/Linux builds).
2. When the 005 greybox is done: review, commit, send the Mac build.
3. Wait for the user's fun-gate verdicts on 004 and 005. No store page, art or polish work before that.

## Waiting on the user
- Fun-gate verdict on Beatrunner.
- Steamworks partner onboarding (not started as of 2026-11-26; takes 15–30 days).

## Closed projects
- 001 Steam market research — done.
- 002 Knolling Co. — abandoned (genre not fun to the user).
- 003 Rockhound — abandoned (boring).

## Automation
- Hourly resume check-in: scheduled task "Game factory: hourly resume check-in" (fires at :41 each hour).
- Environment "waterfall" setup script installs Godot 4.7.1 + templates on fresh containers.

## Resume checklist (used by the hourly check-in)
1. `git status`; commit and push any partial work as WIP.
2. Re-read this file and `memories/INDEX.md`.
3. For each item in "Running work": if its agent stopped (usage limit or restart), resume it with
   SendMessage; if it can't be resumed, start a new agent from the brief and the files on disk.
4. If nothing is running and everything is waiting on the user, do nothing (one-line reply).
