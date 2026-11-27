# Running 4–5 heavy subagents in parallel can exhaust the 5-hour usage limit

- Area: process
- Date / source: 2026-11-27, projects/002 — store page, art, polish and game-003 agents all
  stopped mid-task with "hit your 5-hour limit" (HTTP 429) after a long session.
- Confidence: medium
- Apply when: planning parallel delegation late in a busy session.

Partial work survives on disk; resume each agent with SendMessage after the reset rather
than starting new ones. Commit partial output as WIP first. Prefer 2–3 concurrent heavy
agents and give each a "write deliverables early, polish last" order so a stop loses less.
