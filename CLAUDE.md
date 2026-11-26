# Game Factory — Rules for Claude

Mission: ship one highly polished game to Steam **every month**, and get measurably
better at it each cycle by compounding what we learn.

## Non-negotiable rules

1. **Log every prompt.** Every user prompt is saved verbatim to `prompts/` before work
   starts, using the naming and format in `prompts/README.md`. No exceptions, including
   short follow-ups ("yes", "do it") — record them in the session's prompt file.
2. **Read memory first.** At the start of every session, read `memories/INDEX.md` and the
   memory files relevant to the task. Don't repeat a mistake that is already written down.
3. **Write memory last.** Before ending a session, add any new durable learning to the
   right file in `memories/` (format in `memories/README.md`) and update `memories/INDEX.md`.
   A learning is durable if it would change how we act on a *future* project.
4. **Document every iteration.** Each work session on a project produces a new file in
   `projects/<id>/iterations/` (format in `projects/_template/iterations/README.md`):
   goal, what was done, results, what we learned, next steps.
5. **Commit as you go.** Commit after each meaningful step with a clear message.
   Prompts, iterations and memories are committed in the same change as the work they describe.
6. **One active project at a time.** `projects/ACTIVE` names the current project folder.
   Update it when the focus changes.
7. **Evidence over opinion.** Market and design claims cite a source (URL, dataset, or
   playtest note). Raw scraped data goes in `research/raw/`, never edited by hand;
   derived data goes in `research/processed/` with the script that produced it.
8. **Scope for the month.** Every game project has a written scope in its `BRIEF.md`
   with a cut list. If the schedule slips, cut features — never polish.
9. **Promote patterns to playbooks.** When a process works twice, write it up in
   `playbooks/` so the next project starts from it instead of from scratch.

## Repository map

| Path | Purpose |
|---|---|
| `CLAUDE.md` | These rules. Change only with the user's agreement. |
| `prompts/` | Verbatim log of every prompt, one file per session. |
| `memories/` | Durable, cross-project learnings (market, design, tech, marketing, process). |
| `playbooks/` | Repeatable processes (monthly cycle, Steam launch checklist, …). |
| `projects/_template/` | Copy this to start a new project. |
| `projects/NNN-name/` | One folder per project: brief, iterations, research, assets, postmortem. |
| `tools/` | Shared scripts usable across projects (scrapers, build/upload helpers). |

## Starting a new project

1. `cp -r projects/_template projects/NNN-short-name` (next free number).
2. Fill in `BRIEF.md`; write `projects/ACTIVE`.
3. Create `iterations/001.md` for the first session.

## Finishing a project

Write `POSTMORTEM.md` (what went well, what didn't, numbers), then move every durable
lesson into `memories/` and any reusable process into `playbooks/`.

## Legacy code

`app/`, `migrations/`, `tests/`, `config.py`, `manage.py`, `dev-requirement` and
`readme.md` are a pre-existing, unrelated Flask app. Leave them alone unless the user says otherwise.
