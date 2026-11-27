# Factory setup and first project
- Date: 2026-11-26
- Project: factory, projects/001-steam-market-research

## Prompt 1
> New project. A game factory for shipping highly polished games to steam once a month. We need to setup the projects in a way that we are building on what we learn.  Can't you please document every prompt in a prompts folder, create a CLAUDE.md with the rules, the should be memories folder, and iterations folder where you document each iteration of the current game project, we need to commit these to git which we will connect to a remote repo later. Let me see your proposed folder structure, the first project is to scrap all information about successful game release on steam in the past 12 months to that we have an idea of what will be building.

Outcome: Created folder structure, CLAUDE.md, prompts/, memories/, playbooks/,
project template and projects/001-steam-market-research with its brief and plan
(iteration 001). Scraping not started yet — awaiting approval of structure and plan.

## Prompt 2
> (Stop hook) There are 1 unpushed commit(s) on branch 'claude/game-factory-setup-y912qi'. Please push these changes to the remote repository.

Outcome: Push refused (403, no GitHub access yet). Asked user to connect GitHub.

## Prompt 3
> GitHub connected now, please always used input dislodges when you need inputs from me. Thanks

Outcome: Added rule 10 to CLAUDE.md and memory `process/ask-user-via-input-dialogs`. Pushed branch.

## Dialog answers (project 001 settings)
> Success bar: ≥1,000 reviews, ≥80%
> Segment: Yes, both groups (Recommended)
> Sources: Free public only (Recommended)

Outcome: BRIEF.md updated; iteration 002 (data collection) started.

## Prompt 4
> (Stop hook) There are uncommitted changes in the repository. Please commit and push these changes to the remote branch.

Outcome: The change was the live collector log; untracked it and git-ignored research/*.log.

## Prompt 5
> Please give your memory contextual names so it's easy for you to find things

Outcome: Memories restructured to one file per memory at `memories/<area>/<topic-slug>.md`;
numeric IDs dropped; INDEX, README, CLAUDE.md rule 3 and template updated.

## Prompt 6
> (Stop hook) There are untracked files in the repository. Please commit and push these changes to the remote branch.

Outcome: Committed candidates.csv (30,708 games) and the partial raw enrichment cache.

## Prompt 7
> What else's can you be working on? Are you able to use subagents?

Outcome: Confirmed subagents are available; offered parallel workstreams via dialog.

## Dialog answer (parallel workstreams)
> Steam launch rules, Engine & tech stack, Marketing benchmarks, Game repo template

Outcome: Three research subagents started (launch rules, engine, marketing); the game repo
template waits for the engine recommendation.

## Prompt 8
> Update your main CLAUDE.md, with runs to aggressively delegate to subagents so that the main session context last

Outcome: Added CLAUDE.md rule 11 (delegate aggressively; main session orchestrates) and memory
`process/delegate-to-subagents-keep-main-context`.

## Prompt 9 (hook)
> (Stop hook) There are uncommitted changes in the repository. Please commit and push these changes to the remote branch.

Outcome: Committed in-progress subagent output as WIP.

## Dialog answer (engine)
> Godot 4.7 + GDScript (Recommended)

Outcome: Engine decided; game template subagent started. Recorded in memories/tech/godot-gdscript-is-default-engine.

## Prompts 10–13 (hooks)
> (Stop hook) commit/push reminders ×4 while subagents were writing files.

Outcome: Committed and pushed each time (WIP where work was unreviewed).

## Dialog answer (first game direction)
> Cozy organizing / job sim (Recommended)

Outcome: Project 002 created from template; ACTIVE switched; concept subagent started.

## Dialog answers (project 002 decisions)
> Concept: Knolling Co. (Recommended)
> Steamworks partner account: Not yet
> Art: Human capsule, AI-assisted items (Recommended)
> Next Fest Feb 2027: Save it for game 003 (Recommended)

Outcome: Decisions recorded in projects/002 BRIEF.md; greybox prototype subagent started.

## (no new user prompt) Greybox prototype delivered
Outcome: Committed prototype; enabled git-lfs locally; allowed lfs.github.com in the
"waterfall" environment so LFS assets push; added greybox mp4.

## Dialog answers (playtest + parallel work)
> Playtest: Send me builds but know that I use a Mac
> Parallel: Store page draft, Art direction + AI sprites, Production polish, Game 003 market prep

Outcome: macOS playtest build + kit delegated first (game code), then production polish;
store page, art direction and game 003 prep started in parallel.

## Prompt 14
> Continue

Outcome: All 4 subagents (store page, art, polish, game 003) had stopped on the account's
5-hour usage limit; committed partial work as WIP and resumed each agent.

## Prompt 15
> I get this when I try to run the game "KnollingCo" can't be opened because Apple cannot check it for malicious software."

Outcome: Gave Open Anyway / xattr steps; added the warning text to PLAYTEST.md; memory
`tech/macos-gatekeeper-unnotarized-builds-need-open-anyway`. Game 003 dialog went unanswered (pending).

## Prompt 16
> It opened, playing it now, its is not an enjoyable game at all, what are the options for other games we can make?

Outcome: Go/no-go = NO-GO for Knolling Co. Stopped the polish agent; asked what wasn't fun and
which direction to take instead.

## Dialog answers (after no-go)
> Why not fun: The genre itself
> New game: Rockhound (Recommended)

Outcome: 002 abandoned with postmortem + 2 process memories + fun-gate rule in monthly-cycle;
project 003-rockhound created and set ACTIVE; brief + greybox delegated.

## Prompt 17
> So that's also boring to play, can we create a platformer like rayman legend instead?

Outcome: 003 Rockhound abandoned (postmortem); taste memory revised; asked what the user loves
about Rayman Legends and how to handle scope/market risk.

## Dialog answers (platformer direction)
> What you love: Movement feel, Music levels, Art & charm
> Approach: Tight, one-hook game (Recommended)
> Players: Single-player first (Recommended)

Outcome: Project 004-rhythm-platformer created, ACTIVE; movement + music-level greybox and a
quick market check of rhythm platformers delegated.
