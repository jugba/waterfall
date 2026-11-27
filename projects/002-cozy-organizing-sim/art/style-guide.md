# Knolling Co. — item art style guide (v1, 2026-11-27)

Scope: the ~80 base item sprites (~200 catalogue entries with colour variants) that are tipped onto the
cutting mat. Capsule, logo and key art are human-made and follow their own brief (BRIEF.md, Decisions).
Style targets: `assets/art/items/*.svg` (12 hand-coded sprites, made by `art/tools/make_item_svgs.py`,
not AI) and the contact sheets `assets/art/items/_preview-1x.png` / `_preview-2x.png`.

## 1. Look in one sentence
A tidy flat-lay seen from directly above: **flat vector shapes, soft form shading with no light
direction, a darker same-hue outline, and one soft drop shadow drawn by the engine** — like a
#knolling photo rendered as a sticker sheet. Cozy = rounded corners, warm off-white paper, saturated
but not neon colours, no grime in the base sprite (dirt is a shader, BRIEF.md "Art").

Readability targets (both must pass before a sprite is accepted):
- **Steam Deck 1280×800**: every item is recognisable by silhouette at 32 px per cell (`_preview-1x.png`).
- **Vertical short-form video** (1080×1920, muted, small phone screen): an item's *colour key* reads
  from across the room; capture clips at 2560×1600 (see §5) and crop, so 2x textures are native.

## 2. Palette (the 12 colour keys)
Grouping by colour is a scoring axis (`game/scripts/neatness.gd`), so every item has exactly one colour
key from `Catalog.COLOURS` and that key must be the item's dominant *chromatic* colour.

| Key | Highlight | **Base** | Shade | Outline | L* |
|---|---|---|---|---|---|
| red | #ec7c69 | **#d85a48** | #bc3c2e | #721711 | 54 |
| orange | #ffad5d | **#ee8f2e** | #d17400 | #8a4900 | 68 |
| yellow | #fff680 | **#f6da4c** | #d8be21 | #9c891b | 87 |
| green | #abeab1 | **#86d08f** | #67b573 | #457c4d | 77 |
| teal | #51ac96 | **#11937b** | #007962 | #004535 | 54 |
| blue | #71a0f9 | **#3a86ec** | #006dd4 | #003e85 | 56 |
| purple | #8767cf | **#6b4ac2** | #4d30ab | #190b60 | 41 |
| pink | #ffd1f8 | **#f8b2df** | #dd96c4 | #9b6889 | 80 |
| brown | #915a38 | **#7a4019** | #602800 | #340a00 | 34 |
| black | #404248 | **#2a2c33** | #15181e | #5c5e66 (lighter rim) | 18 |
| grey | #a7b3c1 | **#8a99a9** | #707f8f | #434e59 | 63 |
| white | #fcf9f2 | **#fbf8ef** | #dfdbd2 | #a7a59e | 98 |

Ramps come from `art/tools/palette_check.py --ramps` (Lab: highlight L+10, shade L−10, outline L−30;
black gets a *lighter* outline so it separates from the dark mat and from shadow).

Neutral materials (never a colour key; low chroma so they don't compete): steel #eef1f4 / #c9d0d8 /
#a2abb6 / #5f6873, wood #f7e3c0 / #ecca95 / #d3ac72 / #946d3d, graphite #3b3e45, paper = white ramp.

**How the palette was checked** (`art/tools/palette_check.py`, output `art/palette-cvd-check.csv`):
all 66 pairs, CIEDE2000 (ΔE00) under normal vision and under simulated protanopia, deuteranopia and
tritanopia (Machado, Oliveira & Fernandes 2009, severity 1.0, linear RGB;
https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html). Base values were
tuned by constrained random search (hue within ±15° of the named hue, chroma 35–75) and a hand pass.

| | normal | protan | deutan | tritan |
|---|---|---|---|---|
| greybox palette (catalog.gd today): min ΔE00, pairs < 10 | 15.8, 0 | 4.4, 5 | **0.4 (teal/grey)**, 8 | 6.1, 3 |
| **v1 palette (this guide)** | **15.3, 0** | **12.3, 0** | **12.1, 0** | **10.1, 0** |

Tightest v1 pairs: teal/blue (tritan 10.1), yellow/pink (tritan 11.5), red/orange (tritan 11.8),
orange/yellow (deutan 12.1), pink/grey (protan 12.3). ≥10 is "different side by side", not "obvious at
a glance" (≥20), so the design must also not rely on colour alone:
- The scorer already takes the better of type-grouping and colour-grouping, so a colour-blind player
  can reach a full grouping score by type.
- Accessibility option (recommended, cheap): "colour tags" draws a small shape glyph per colour key on
  each item when held/hovered, and in the score reasons.
- Lightness is spread (L* 18–98) so even greyscale keeps most pairs apart.
- Against the mat (#2f5d50) every base is ≥19 ΔE00 (teal is the closest: keep its outline).

**Open:** catalog.gd `COLOURS` still holds the greybox values; switching it to the v1 bases is a
one-line-per-colour change for whoever owns game code.

## 3. Light, shadow, outline
- **No baked light direction.** Items rotate in 90° steps while the engine's shadow stays screen-fixed
  (down-right, `desk_item.gd`), so any top-left highlight would be wrong at 180°. Shade by *form only*,
  symmetric about the object's axis:
  - cylinders (pens, bottles, handles): lit band along the centre, shade at both sides
    (`cyl()` gradient: shade · base · highlight · base · shade);
  - boxes and flat things: flat base top face + a soft inner rim of the shade colour (`bevel()`);
  - round things (apple, ball): radial highlight in the centre (`dome()`).
- **No cast shadow in the sprite.** One soft drop shadow is drawn by the engine: resting offset (3, 4)
  px at 1x, alpha 0.35; lifted by drag → (12, 18) px, alpha 0.22, plus 8 % scale-up. Keep the sprite
  edge clean and opaque so that shadow reads. Small catch-lights (phone screen glint) are allowed only
  if they look fine at all four rotations.
- **Outline:** 1.5 px at 1x (6 px at 4x master), the outline colour of the material it encloses (not
  black), round joins. Interior lines 1 px at 1x (4 px master), shade or outline colour.
- Minimum feature: 2 px at 1x (8 px master). Anything smaller disappears on the Deck; drop it.
- No text, logos or brand shapes on items (also avoids trademark trouble); labels are blank paper with
  grey lines.

## 4. Scale and canvas
- Grid: 32 × 20 cells; `Desk.CELL` = 32 px; the mat is 1024 × 640 px inside the 1280 × 800 viewport.
- **1x (Deck) = 32 px/cell. Ship 2x = 64 px/cell. Author/master at 4x = 128 px/cell.**
  2x is native at 2560×1600 and for video capture; on the Deck it is downsampled 2:1 with mipmaps.
- Canvas = the item's footprint exactly (`w × h` from items.json, long axis horizontal, rotation 0),
  e.g. pencil 4×1 → 512 × 128 master / 256 × 64 shipped. Keep an 8 px (master) margin inside the canvas
  (matches `DeskItem.INSET` = 2 px at 1x) so outlines don't touch neighbours when packed tight.
- The object's long axis should reach within one margin of both ends of its footprint so that the
  footprint is legible; thin items may be narrower than a cell (pencil body is 64 of 128 px tall).
- One object per sprite, centred in its footprint; holes (scissors loops, key ring) stay transparent.

## 5. Files, naming, atlas
- Name = the items.json id: `<id>.svg` (vector master or hand-coded target), `<id>@4x.png` (master
  raster), `<id>@2x.png` (shipped). Colour variants are separate ids (`pencil_red`), made by recolouring
  the master with the palette ramp — never by generating a new AI image.
- Masters and work files: `projects/002-cozy-organizing-sim/assets/art/items/` (AI raw outputs in
  `assets/art/ai-raw/<id>/`, never shipped). Shipped textures: `game/assets/art/items/<id>.png` (2x).
- Binary files go in git LFS (`memories/tech/git-lfs-for-binary-assets`).
- Atlas plan: individual PNGs during production. Before the polish phase pack one atlas per tier with
  Godot's **Texture Atlas** importer (select PNGs → Import As: Texture Atlas, `atlas_file` =
  `game/assets/art/atlas/tier<N>.png`, crop to region on, max 2048 × 2048). ~80 items at 2x average
  ~3 × 1.6 cells ≈ 1.6 Mpx, so one 2048² atlas per tier is plenty. Loading by path still returns an
  AtlasTexture, so code doesn't change. Only do this if profiling shows draw calls matter (≤40 items on
  screen; probably not).
- Clips: run the game at 2560×1600 (canvas_items stretch picks up 2x detail), crop 900×1600, scale to
  1080×1920 (`memories/tech/godot-headless-capture-xvfb-write-movie`).

## 6. Godot import settings (Godot 4)
PNG (`Texture2D`): Compress Mode **Lossless** (VRAM compression smears flat colour edges); Mipmaps
Generate **on**; Fix Alpha Border **on**; Premult Alpha off; Detect 3D off; size limit 0.
Filter isn't an import option in Godot 4: set Project Settings → Rendering → Textures → Canvas
Textures → Default Texture Filter = **Linear Mipmap** (or `texture_filter` on the item node), otherwise
the mipmaps are ignored and 2x→1x downsampling shimmers while dragging.
SVG placeholders can be imported directly (ThorVG rasterises at import): set **SVG scale 0.5** on the
4x SVGs to get 64 px/cell, same settings as above. Fine for the greybox swap; ship PNGs for final art.
Drawing: `draw_texture_rect(tex, r, false)` with `r` = the footprint rect the greybox already uses;
the shadow pass can reuse the same texture modulated to `Color(0,0,0,a)` so the shadow takes the
item's silhouette instead of a rounded rect.

## 7. Keeping AI-assisted sprites consistent
1. **Reference sheet:** `_preview-2x.png` + the 12 SVG targets are the style reference for every
   generation (image prompt / style reference / custom style, depending on the tool). Add each accepted
   AI sprite to a growing reference board once cleaned.
2. **Fixed prompt template** (`art/sprite-prompts.md`): only the subject slot changes. Don't add style
   words per item; fix the template instead and regenerate the batch.
3. **Seed policy:** one fixed seed per batch (record it); 4 candidates per item; if none passes,
   change the subject wording first, the seed second, never the template mid-batch. Same tool, model
   version and settings for the whole catalogue; a model update means re-checking against the targets.
4. **Background:** native transparent output if the tool has it; otherwise a flat mat green (#2f5d50)
   background, so any halo left after keying blends into the desk.
5. **Cleanup pass checklist** (every sprite, by a human in Krita/Inkscape or by vectorising):
   - [ ] top-down orthographic, no perspective or 3/4 view; long axis horizontal; centred in footprint
   - [ ] background removed, no halo; alpha edge clean at 2x and 1x
   - [ ] baked cast shadow / directional highlight removed (§3)
   - [ ] colours snapped to the item's ramp (base/shade/highlight/outline) + neutral materials only;
         the colour key is the dominant chromatic colour
   - [ ] outline 6 px at master, outline colour; no black outline except via ramp
   - [ ] no text, logos, watermarks, brand shapes, extra objects, hands
   - [ ] smallest detail ≥ 8 px at master; silhouette readable in `_preview-1x` on the mat
   - [ ] canvas = footprint × 128 px, 8 px margin; exported `<id>@4x.png` and `<id>@2x.png`
   - [ ] logged in `art/ai-disclosure-notes.md` and `assets/LICENSES.md`
6. Prefer tools that output vector (SVG) or vectorise the cleaned raster: snapping to the palette is
   then a fill swap, and colour variants are a script.
