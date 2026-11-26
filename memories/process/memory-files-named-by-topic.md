# Name memory files by topic, one memory per file

- Area: process
- Date / source: 2026-11-26, user instruction (prompts/2026-11-26_001_factory-setup.md, prompt 5)
- Confidence: high
- Apply when: writing or looking up any memory.

Each memory lives at `memories/<area>/<topic-slug>.md`, so a glob or filename search
finds it without opening files (e.g. `memories/market/*pricing*`). No numeric IDs.
