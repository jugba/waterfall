# Prompt log

Every prompt given to Claude is recorded here verbatim, so we can see how instructions
evolved and reuse the ones that worked.

- One file per session: `YYYY-MM-DD_NNN_short-slug.md` (NNN = running number across the repo).
- Prompts are copied **exactly** as written (typos included), in order.
- Under each prompt, add a one-line `Outcome:` once the work is done.
- Prompts that worked especially well get copied into `prompts/library/` as reusable templates.

## Template

```markdown
# <Session title>
- Date: YYYY-MM-DD
- Project: projects/NNN-name (or "factory")

## Prompt 1
> verbatim text

Outcome: …
```
