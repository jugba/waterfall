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
