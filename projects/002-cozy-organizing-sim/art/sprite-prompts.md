# Knolling Co. — item sprite prompts (v1, 2026-11-27)

Rules: `art/style-guide.md`. Log every generation in `art/ai-disclosure-notes.md`.
Only the **{subject}**, **{colour}** and **{w}:{h}** slots change; the rest of the template is fixed for
the whole catalogue. Colour variants (e.g. `pencil_red` from `pencil_yellow`) are **not** prompted:
generate one master per item type and recolour it with the palette ramp in cleanup.

## Fixed template

```
Game item sprite, a single {subject}, main colour {colour}.
Seen from directly above (orthographic top-down flat-lay, knolling photo style), object centred,
long axis horizontal, filling a {w}:{h} frame with a small even margin.
Clean flat vector illustration, rounded friendly shapes, soft symmetric form shading with no light
direction, no cast shadow, thin darker same-hue outline, limited palette, cozy and tidy.
Plain flat background in solid #2F5D50 (or transparent).
```
Negative / "avoid" (where the tool has a field; otherwise append "Avoid: ..."):
```
perspective, 3/4 view, isometric, side view, cast shadow, drop shadow, reflection on table, photo,
realistic texture, noise, grain, text, letters, numbers, logo, brand, watermark, hands, multiple
objects, cropped object, table, scene, gradient background, neon, glow
```
Style reference: attach `assets/art/items/_preview-2x.png` (or the tool's equivalent: Midjourney
`--sref`, Firefly "style reference", Recraft custom style from images, an IP-Adapter for SD/FLUX).
Colour slot = key name + base hex, e.g. "warm yellow (#F6DA4C)".

Example, fully rendered (`pencil_yellow`, 4:1): "Game item sprite, a single wooden hexagonal pencil,
sharpened, pink eraser in a silver ferrule, main colour warm yellow (#F6DA4C). Seen from directly
above ... filling a 4:1 frame ..."

## Prompts: the 38 items in `game/data/items.json`
`id` · footprint · colour key — **{subject}**

### writing
- `pencil_yellow` 4:1 yellow — wooden hexagonal pencil, sharpened wood cone and graphite tip, pink eraser in a silver ferrule *(style target exists: `pencil_yellow.svg`)*
- `pencil_red` 4:1 red — recolour of `pencil_yellow`
- `pen_blue` 4:1 blue — ballpoint pen with matching cap and a silver pocket clip *(target: `pen_blue.svg`)*
- `pen_black` 4:1 black — recolour of `pen_blue`

### marking
- `marker_green` 3:1 green — chunky permanent marker with a ridged cap and blank white label
- `highlighter_yellow` 3:1 yellow — recolour of `highlighter_pink`
- `highlighter_pink` 3:1 pink — flat oval highlighter with chunky cap and blank label *(target: `highlighter_pink.svg`)*

### tools (desk)
- `eraser` 2:1 pink — rectangular rubber eraser half covered by a white paper sleeve *(target)*
- `sharpener` 2:1 blue — small plastic pencil sharpener block with a silver blade plate and one round hole
- `ruler` 6:1 grey — clear grey plastic 30 cm ruler with tick marks (no numbers)
- `stapler` 3:2 black — desk stapler, rounded body, silver metal head and base plate *(target)*
- `tape` 2:2 grey — roll of clear sticky tape in a small grey dispenser
- `clips` 2:2 grey — small tidy pile of silver paper clips
- `scissors` 4:2 red — closed office scissors, red plastic finger loops, silver blades *(target)*
- `glue` 3:1 purple — glue stick with twist base and cap

### paper
- `sticky_notes` 2:2 yellow — square pad of sticky notes, top sheet with a curled corner *(target)*
- `notebook` 4:3 blue — closed hardcover notebook, cloth spine, black elastic band, blank label *(target)*
- `map` 4:3 green — folded paper trail map showing green contour shapes (no text)

### tech
- `phone` 4:2 black — smartphone lying face up, dark screen, thin rim *(target)*
- `earbuds` 2:2 white — open wireless earbuds charging case with two earbuds
- `cable` 3:3 white — neatly coiled white USB cable with plugs at both ends
- `power_bank` 3:2 grey — rectangular power bank with two ports and four tiny indicator dots
- `usb_stick` 2:1 blue — USB flash drive with a swivel cover
- `charger` 2:2 white — compact wall charger plug, prongs folded

### personal
- `wallet` 4:3 brown — closed bifold leather wallet with stitched edges
- `keys` 2:2 grey — two keys on a split key ring *(target)*
- `lip_balm` 2:1 pink — lip balm stick with cap
- `sunglasses` 4:2 black — folded sunglasses, arms closed
- `mints` 2:1 teal — small flat tin of mints

### outdoor
- `compass` 2:2 red — round hiking compass, white dial, red/silver needle, lanyard lug *(target)*
- `torch` 4:1 black — slim aluminium flashlight with a ridged grip and lens end
- `multitool` 3:1 red — closed pocket multitool / army knife with silver tool edges
- `bottle` 6:2 teal — reusable insulated water bottle lying flat, screw cap with loop
- `carabiner` 2:1 orange — anodised aluminium carabiner with silver gate
- `first_aid` 3:3 red — small zipped first-aid pouch with a white cross

### food
- `snack_bar` 3:1 orange — wrapped granola bar with crimped ends, blank wrapper
- `apple` 2:2 green — green apple seen from above with stem and one leaf *(target)*
- `trail_mix` 3:2 brown — resealable bag of trail mix, nuts visible through a window

## Prompts: 42 new items for the 30-job plan
Proposed additions to items.json (ids, footprints and keys are suggestions for whoever owns the data).
New categories: `hardware`, `craft`, `magic`.

### writing / marking (art-box jobs)
- `fountain_pen` 4:1 black — fountain pen with silver nib and cap clip
- `crayon_blue` 2:1 blue — wax crayon with paper wrapper (variants: red, yellow, green)
- `chalk` 2:1 white — stick of chalk, slightly worn end
- `paint_brush` 4:1 brown — artist paint brush, wooden handle, silver ferrule, clean bristles
- `paint_tube` 3:1 red — squeezed paint tube with cap (variants: blue, yellow)
- `watercolour_tin` 4:2 black — small open watercolour tin with 8 pans of paint

### tools (desk) / paper
- `hole_punch` 3:2 grey — two-hole paper punch
- `binder_clip` 1:1 black — single binder clip with silver arms
- `rubber_bands` 2:2 orange — small loose bundle of rubber bands
- `push_pins` 2:2 blue — small clear box of push pins
- `envelope` 4:2 white — sealed paper envelope (no writing)
- `index_cards` 3:2 white — small stack of ruled index cards
- `postcard` 3:2 blue — postcard showing a simple sea and sky picture

### tech
- `game_controller` 4:2 grey — game controller with two sticks and four face buttons (no logos)
- `mouse` 2:2 white — computer mouse with scroll wheel, wireless
- `sd_card` 1:1 blue — SD memory card
- `batteries` 2:1 orange — two AA batteries side by side
- `headphones` 4:3 black — folded over-ear headphones

### personal (handbag / makeup-bag jobs)
- `comb` 4:1 purple — plastic hair comb
- `hair_clip` 2:1 pink — claw hair clip
- `watch` 3:2 brown — wristwatch with leather strap, plain dial
- `coin_purse` 3:2 purple — small zipped coin purse
- `hand_cream` 3:1 teal — small tube of hand cream
- `glasses_case` 4:2 teal — closed hard glasses case
- `tissues` 3:2 white — pocket pack of tissues
- `id_card` 2:1 blue — blank ID card on a lanyard clip (no face, no text)

### hardware (toolbox jobs)
- `screwdriver` 4:1 yellow — screwdriver with chunky plastic handle and steel shaft
- `hammer` 6:2 red — claw hammer with rubber grip
- `tape_measure` 2:2 yellow — retractable tape measure
- `wrench` 4:1 grey — open-end spanner / wrench
- `pliers` 4:2 blue — closed pliers with blue rubber handles
- `spirit_level` 6:1 green — spirit level with one bubble vial
- `utility_knife` 3:1 orange — retractable box cutter, blade retracted

### craft (sewing-box jobs)
- `thread_spool` 2:1 purple — wooden spool of thread seen lying down (variants: red, blue, white)
- `pin_cushion` 2:2 red — tomato pin cushion with a few pins
- `button_tin` 2:2 teal — small round tin with mixed buttons
- `yarn_ball` 2:2 pink — ball of yarn with a loose end
- `knitting_needles` 6:1 grey — pair of knitting needles side by side

### magic (magician's trunk tier)
- `playing_cards` 2:2 red — deck of playing cards in its box, plain pattern back
- `magic_wand` 4:1 black — black magic wand with white tips
- `silk_scarves` 3:3 purple — neatly folded silk scarves (variants: yellow, green)
- `juggling_ball` 2:2 orange — soft juggling ball with panel seams

38 + 42 = **80 item types**; with the listed colour variants and per-job recolours (~2.5 variants per
type) this reaches the BRIEF's ~200 catalogue entries without generating more AI images.

## 30-job content plan (draft, for the designer to confirm)
| Tier | Jobs | Containers | Item pools |
|---|---|---|---|
| 1 School & office | 1–7 | pencil case ×2, desk drawer, art box, teacher's tote, office tray, kid's backpack | writing, marking, tools, paper |
| 2 Everyday bags | 8–15 | handbag, day pack, gym bag, gamer desk, commuter bag, travel pouch, grandma's handbag, lunch bag | tech, personal, food, outdoor |
| 3 Hobby boxes | 16–23 | toolbox ×2, sewing box, makeup bag, camping kit, art studio drawer, tackle-style craft case, garage drawer | hardware, craft, personal, outdoor |
| 4 Special clients | 24–30 | magician's trunk ×2, detective's desk, explorer's satchel, artist's trolley, junk drawer final, own-desk finale | everything + magic |

## AI image tools: licence / commercial use (checked 2026-11-27)
Terms change often; re-check the linked page the day a batch is generated and save a PDF of it next to
the log. Purely AI output is probably not copyrightable in the US
(`memories/tech/steam-ai-disclosure-player-facing-only`), whatever the tool's terms grant.

| Tool | Commercial use of outputs | Notes for us | Source |
|---|---|---|---|
| Recraft (V3) | Paid plans only: full ownership + commercial rights, kept after cancelling. Free plan: images owned by Recraft, public, **no commercial use** | Outputs **SVG/vector** and has custom styles from reference images → best fit for this pipeline. Outputs can't be used to train AI | https://www.recraft.ai/docs/plans-and-billing/commercial-rights-and-ownership |
| Adobe Firefly | Allowed for non-beta features; trained on licensed/public-domain content; IP indemnity for **enterprise** plans only | Style reference + transparent bg in Photoshop; "commercially safe" is Adobe's term, not a legal guarantee | https://helpx.adobe.com/firefly/faq.html ; https://www.adobe.com/cc-shared/assets/pdf/enterprise/firefly-legal-faqs-enterprise-customers-2024-06-11.pdf |
| Midjourney | Paid plans: you own assets; companies > $1M gross/yr need Pro or Mega | `--sref` style reference and `--seed`; no transparent output; images public unless stealth (Pro+) | https://docs.midjourney.com/hc/en-us/articles/27870375276557-Using-Images-Commercially ; https://docs.midjourney.com/docs/terms-of-service |
| OpenAI image models (ChatGPT / API) | Terms: you own the Output (as far as law allows); similar output may go to others | Transparent background supported *(unverified for the current model)*; check API business terms | https://openai.com/policies/terms-of-use/ |
| Stable Diffusion 3.5 (self-hosted) | Stability Community License: free commercial use for orgs < $1M annual revenue, above that an Enterprise licence | Local, seed-exact, LoRA on our 12 targets possible; needs a GPU box (not this container) | https://stability.ai/license ; https://stability.ai/news/license-update |
| FLUX.1 [dev] (self-hosted) | Weights **non-commercial**; licence says outputs may be used commercially, but running it for a revenue-generating product is arguably commercial use of the model → **avoid** or buy a BFL commercial licence / use paid API | | https://bfl.ai/legal/non-commercial-license-terms |
| Scenario, Leonardo, Google Imagen/Gemini | Not checked | *unverified*; read terms before use | — |

Recommendation (for the user to decide): Recraft paid plan as primary (vector output, style from our
targets, clear ownership), Firefly as the fallback; keep one tool for the whole catalogue.
