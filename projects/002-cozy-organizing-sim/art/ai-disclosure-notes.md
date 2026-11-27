# Knolling Co. — AI asset log (supports the Steam AI disclosure)

Why: Steam's content survey asks us to describe pre-generated AI content that players see (item
sprites here); AI-written code is exempt (`memories/tech/steam-ai-disclosure-player-facing-only`,
Valve rules rewritten Jan 2026). The log also shows how much human editing each asset had, which
matters for copyright (US Copyright Office, Part 2: https://copyright.gov/newsnet/2025/1060.html).
Keep `assets/LICENSES.md` in sync: one line per shipped asset (source, licence, AI yes/no).

## What to record per AI asset
| Field | What | Why |
|---|---|---|
| asset id | items.json id (= file name) | joins log ↔ files ↔ LICENSES.md |
| shipped file(s) | `game/assets/art/items/<id>.png` | what players see |
| tool + model/version | e.g. "Recraft V3, web, 2026-12-02" | disclosure; reproducibility; terms in force |
| plan / licence | e.g. "Recraft Pro, commercial rights" + saved terms PDF path | proves commercial right on that date |
| prompt | template version + subject slot (full text if the template changed) | reproducibility |
| negative / settings | seed, style reference used, size, other params | consistency, reruns |
| date generated | ISO date | terms in force on that date |
| raw output | `assets/art/ai-raw/<id>/<n>.png` (never shipped, kept in LFS) | before/after evidence |
| human edits | what was changed: redraw %, recolour, vectorised, outline, removed shadow/text | copyright posture; quality |
| editor + time | who, minutes spent | human-authorship evidence; cost tracking |
| status | candidate / accepted / shipped / replaced | so the disclosure matches the build |

Rules: never ship a sprite with no log line; variants made by recolouring inherit the parent's line
("recolour of `pencil_yellow`"); hand-made sprites (like the 12 SVG targets) are logged as **AI: no**
in LICENSES.md, not here. Before submitting the build, filter this table on `status = shipped` and
write the survey text from it.

## Draft Steam disclosure text (update before submission)
"Pre-generated: some item illustrations were created with the help of AI image tools and then
cleaned up and recoloured by hand to match our style. The logo, capsule and key art are made by
human artists. No AI content is generated live during play."

## Log
| asset id | tool + version | plan / licence | prompt (template v + subject) | seed / settings | date | raw output | human edits | editor, min | status |
|---|---|---|---|---|---|---|---|---|---|
| *(example)* `marker_green` | Recraft V3 (web) | Pro, commercial rights; terms PDF `art/terms/recraft-2026-12-02.pdf` | v1 · "chunky permanent marker with a ridged cap and blank white label" | style ref `_preview-2x.png`, 4 candidates, picked #3 | 2026-12-02 | `assets/art/ai-raw/marker_green/3.svg` | removed cast shadow, snapped fills to green ramp, outline 6 px, redrew cap | —, 15 | candidate |

No AI assets have been generated yet (2026-11-27). The 12 sprites in `assets/art/items/` are
hand-coded SVGs (`art/tools/make_item_svgs.py`), AI: no.
