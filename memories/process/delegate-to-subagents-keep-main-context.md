# Delegate heavy work to subagents so the main session's context lasts

- Area: process
- Date / source: 2026-11-26, user instruction (prompts/2026-11-26_001_factory-setup.md, prompt 8)
- Confidence: high
- Apply when: any task involves research, large files, long runs, drafting or implementation.

The main session orchestrates: it briefs subagents, reviews their reports and commits.
Independent tasks run in parallel in the background. See CLAUDE.md rule 11.
