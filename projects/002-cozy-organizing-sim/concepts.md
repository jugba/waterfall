# 002 — Cozy organizing / job sim: three concepts

- Written: 2026-11-26 (iteration 001)
- Inputs: `projects/001-steam-market-research/reports/market-report.md` (direction 1),
  `research/processed/games_analyzed.csv` **[G]**, `candidates.csv` **[C]**, `tag_opportunity.csv` **[T]**,
  `raw/appdetails/` (store "about" text) **[AD]**, memories cited as **[M:path]**.
  All 001 paths are under `projects/001-steam-market-research/research/`.
- Constraints from the user: ~10-week pipeline (≈4 weeks core dev), Godot 4.7 GDScript, Claude writes
  code, art AI-assisted or sourced, 2D or simple 2.5D, single-player, $7.99–12.99, 3–6 h of content,
  >2 h of value, Steam Deck friendly, strong short-form-video hook.
- Revenue method: units = all-language reviews × 30 (range 20–60), net = units × price × 0.5
  [M:marketing/boxleiter-multiplier-about-30x-for-recent-games]. Estimates, ±50% per game.
- **Review text was not available.** `store.steampowered.com/appreviews` still 302-redirects to the store
  homepage and `steamcommunity.com` is unreachable from this container (checked 2026-11-26). The
  "praise / complaints" column below is **inferred** from score, playtime, price and store text,
  not read from reviews. Treat it as a hypothesis to check by reading reviews from a normal browser.

---

## 1. What the comparable hits have in common

### 1.1 The comparables (all launched new in the window, ≤$20)

Reviews are all-language totals from [G]. Playtime is the SteamSpy median (partial data). "Est. net" uses 30×.

| Game | Price | Reviews | % | Median play | Size | Core verb | Est. net (30×) |
|---|---|---|---|---|---|---|---|
| Librarian: Tidy Up the Arcane Library! | $5.99 | 29,685 | 93 | 7.6 h | 2 GB | return 3,072 books to shelves; unlock abilities that speed it up | $2.7M |
| Dressmaker (Free Lives) | $14.99 | 26,741 | 99 | 5.6 h | 2 GB | choose fabric, cut pattern, sew, decorate a dress for a customer | $6.0M |
| ReStory: Chill Electronics Repairs (tinyBuild) | $19.99 | 16,016 | 95 | 6.7 h | 1 GB | take apart, clean, replace parts, reassemble Y2K devices; branching customer stories | $4.8M |
| Creature Kitchen | $7.99 | 10,835 | 99 | 4.1 h | 1 GB | creepy-cozy cooking for wildlife | $1.3M |
| Cat Mail Co. | $14.99 | 9,158 | 94 | 5.6 h | 4 GB | sort, weigh, label, stamp parcels; night-time mystery; optional co-op | $2.1M |
| Potato Please | $9.99 | 4,251 | 90 | 4.6 h | 2 GB | peel potatoes with physics, buy better tools | $637k |
| Supermarket Chaos | $4.99 | 4,116 | 90 | 6.1 h | 2 GB | return 4,668 products to shelves | $308k |
| Lost and Found Co. | $17.99 | 3,503 | 98 | 9.6 h | 2 GB | 2D hidden-object adventure | $945k |
| The Artisan of Glimmith | $12.99 | 3,354 | 98 | 11.1 h | 2 GB | stained-glass colouring logic puzzles | $654k |
| Leafy Corner | $9.99 | 3,325 | 96 | 2.3 h | 1 GB | grow and sell houseplants, decorate shop | $498k |
| DinoBones: Tidy Up the Museum | $5.99 | 2,877 | 95 | 3.6 h | 4 GB | identify ~2,000 "Unknown" bones, assemble 9 skeletons | $258k |
| Sort Them Ducks | $5.99 | 2,648 | 92 | 7.2 h | 4 GB | sort 4,000 rubber ducks onto shelves | $238k |
| Playrooms | $6.99 | 2,465 | 97 | 5.3 h | 10 GB | put away thousands of balls (horror twist) | $258k |
| Dice Hoarder | $5.99 | 2,306 | 97 | 8.8 h | 4 GB | sort dice into 7-piece sets, mystery behind the job | $207k |
| Brick by Brick: Tidy Up the Small Town! | $7.99 | 1,646 | 89 | 4.8 h | 2 GB | sort 18,490 bricks to rebuild a town; co-op | $197k |
| Thrifty Business | $12.99 | 1,455 | 97 | 1.6 h | 1 GB | sort thrift boxes, arrange displays, befriend regulars | $284k |
| Cellar Keeper | $4.99 | 1,366 | 90 | 20.9 h | 1 GB | shelve 2,448 bottles | $102k |
| Cozy Cleaner | $6.99 | 1,254 | 89 | 1.1 h | 1 GB | tidy rooms messed up by cats | $131k |
| Moldwasher | $8.99 | 1,098 | 92 | 2.7 h | 0.6 GB | **2D** arcade fridge cleaning with spray nozzles | $148k |
| Hozy (tinyBuild) | $14.99 | 5,169 | **79** | 2.8 h | 5 GB | clean, paint, decorate houses | $1.2M |

Smaller 2D organizing games ([C], English search-row review counts): Deleted Wiki: Clean Up the Lost Files
(pixel, $3.99, 837, 98%), Folded Fables: Tidy Up The Dragon Hoard (hand-drawn, ~$4.79, 525, 96%),
Neat! ($9.99, 685, **74%**), A Storied Life: Tabitha ($14.99, 73, 79%), Suitcase Stories ($6.99, 84, **72%**).

### 1.2 Patterns

1. **Two price tiers, two designs.**
   - *Tidy-up template* ($4.99–7.99): one verb (pick up, put back) at huge counted scale, first-person 3D,
     abilities that speed you up, a collectathon log, a one-line mystery or a cat. 1–4k reviews each,
     ≈$100–310k est. net; Librarian ($2.7M) is the outlier that started it. [G]
   - *Craft / job sim* ($12.99–19.99): a real-world craft simulated with fidelity (fabric grain, device
     disassembly, postage and stamps), plus customers with small stories. Fewer games, much higher
     revenue per game (Dressmaker $6.0M, ReStory $4.8M, Cat Mail $2.1M). [G], [AD]
2. **The hook is "chaos → order", and the store pitch counts the chaos.** "3,072 books", "4,668 products",
   "18,490 bricks", "~2,000 bones", "17,437 supplies". A number that makes the mess feel enormous is in
   almost every short description. [AD], [G short_description]
3. **Speed-up unlocks make it incremental.** Librarian, Cellar Keeper, Brick by Brick and Cat Mail all
   unlock abilities as shelves fill; Rip It!, Potato Please and Sort Them Ducks carry the Incremental tag.
   Relaxing + Incremental lifts 5.7× [T]. DinoBones is the exception ("no skill trees… just you getting
   better") and still scores 95%.
4. **Freedom scores higher than "one correct answer"** (inference). The 2D organizing puzzles that
   appear to have a single correct placement score 72–79% (Neat!, Suitcase Stories, A Storied Life),
   while freeform or creative games score 94–99% (Dressmaker "complete creative freedom", Cat Mail
   "no such thing as a correct way", Scriptorium 97%). Hozy (79%, 2.8 h at $14.99) suggests a value
   complaint at the higher price. *Inferred from scores and store text, not review text.*
5. **Length.** Hits sit at 3.6–11 h median play; the cheapest tier often runs longest (Cellar Keeper
   20.9 h at $4.99). Short ones that still score well are cheap or very polished (Cozy Cleaner 1.1 h at
   $6.99, 89%; Thrifty Business 1.6 h at $12.99, 97%). Refund rule says design for >2 h
   [M:marketing/steam-refund-two-hours-short-games].
6. **Small builds, single-player, controller.** 1–4 GB, single-player-first (co-op added later by Supermarket
   Chaos, Brick by Brick, Cat Mail), and most list full controller support (Librarian, Cat Mail, Leafy
   Corner, Moldwasher). [G categories]
7. **Localisation is cheap and normal:** 9–31 languages for most; Dressmaker (3) and Librarian (4) are
   the exceptions. [G langs]
8. **AI content did not sink the top hit.** Librarian and Cellar Keeper carry the player-applied
   "Artificial Intelligence" tag and still score 90–93% (why the tag was applied is unverified). Keep
   key art human-made anyway [M:tech/steam-ai-disclosure-player-facing-only].
9. **The supply is exploding — the lift will fade.** Releases tagged Organizing per quarter: 7 (Q1 2026)
   → 15 (Q2) → 60 (Q3) → 192 (Q4, only ~8 weeks). Job Simulator: 23 → 30 → 40 → 274. Cleaning:
   2 → 13 → 33 → 79. Share reaching 100 reviews fell from 48% (Q3) to 12% (Q4; partly because Q4 games
   are young). The "Tidy Up the X" title is now a template: 143 window releases have "Tidy" in the name, 19 of
   them with ≥200 reviews. [C]
   Caveat: [C] holds only each game's top ~6 tags. **A pure "put it back on the shelf" clone launching in
   Feb 2027 enters a crowded shelf; we need a second verb or a different view.**
10. **2D is under-proven in this cluster, not disproven.** Among Organizing/Job Sim/Cleaning releases:
    2D-tagged 38 → 2 reached 100 reviews, 1 reached 1k (Moldwasher); First-Person 94 → 6 → 2. The big
    tidy-up hits are first-person 3D, the big craft hits (Dressmaker, ReStory) are bench/table views.
    A 2D concept must look native to its view, not like a flattened tidy-up. [C]

---

## 2. Three concepts

All three are 2D (top-down or ¾ "workbench" view), single-player, mouse + full controller, 1280×800
native, built on the `_template` foundations (save, settings, pause, Steam service).

Revenue lines use the method above at the concept's price:
- *Typical* = 100–500 reviews (the 90th percentile of all releases is 119 [M:market/small-scope-steam-hit-base-rate-under-1-percent]).
- *Hit* = 1,000–3,000 reviews (the core-hit bar; the cluster's core hits are $197k–$637k p25–p75, market report direction 1).

### Concept A — "Lost Property Office"

- **Pitch:** Run a railway station's lost-property office: shelve the daily sack of forgotten things,
  then work out which item belongs to each traveller from their muddled description.
- **5-second hook:** a mail sack is upended and 150 objects avalanche across the counter; a traveller's
  speech bubble shows icons "red · umbrella · duck handle"; the player pulls it from a shelf, stamps
  RETURNED, the traveller beams.
- **Core loop (a 10-minute "day"):** morning sack → tag and shelve by category (snap slots) → counter
  queue: travellers describe items by icon attributes (colour, type, feature, where lost) → search
  shelves, hand over, collect claim fee → evening: unclaimed items go to auction for coins.
- **Progression / meta:** coins buy shelves, a label maker, a magnifier that highlights attribute matches,
  a trolley; 4 stations (village halt → city terminus → airport → night train), 12 recurring travellers
  with tiny story threads, a "parcel nobody claims" mystery, item catalogue to 100%.
- **Content for 3–6 h:** 25 days × ~10 min ≈ 4 h; endless "rush hour" mode and catalogue completion add 1–2 h.
- **Art (our pipeline):** ¾ counter + shelf wall per station (4 backgrounds); ~200 base items as icon-style
  sprites with colour variants generated by palette shader (AI-assisted then hand-cleaned, or licensed
  packs); 12 traveller busts (human-drawn or heavily edited). Medium load.
- **Scope vs 4 weeks:** W1 sort/shelve + item database + attribute generator; W2 traveller descriptions,
  matching, day loop, economy; W3 upgrades, 4 stations, story threads; W4 juice, audio, controller,
  achievements. Two separate systems (sorting and deduction) each need tuning → **tight**.
- **Cut list:** 4th station → story threads (generic travellers) → auction → endless mode → items 200→120.
- **Top 3 risks:** (1) the deduction step needs reading, so the muted clip is weaker and localisation costs
  more; (2) two systems halve the polish time for each; (3) the name space is taken: Lost and Found Co.
  (98%, 3.5k reviews), LOST & FOUND (free), Lost & Found: A This Bed We Made Story. [C]
- **Comparables + revenue:** Cat Mail Co. ($2.1M est.), Lost and Found Co. ($945k), Librarian ($2.7M),
  Dice Hoarder ($207k). At **$9.99**: typical $15k–75k; hit $150k–450k.
- **Steam tags (top 5):** Organizing, Job Simulator, Investigation, Relaxing, Cozy.
- **Why different:** organizing + light deduction (Puzzle + Investigation lifts 8.9× [T]); returning an
  item to a person gives an emotional payoff that shelf-fillers lack.

### Concept B — "Knolling Co." (working title) — **recommended**

- **Pitch:** You're a professional organizer. Each client's handbag, drawer or toolbox is tipped onto your
  desk: clean it, sort it into a perfect *knolling* flat-lay, snap the photo, then pack it all back so it fits.
- **5-second hook:** top-down shot; a backpack is tipped out and 60 items scatter; a 3-second timelapse
  snaps them into a perfect right-angled grid, each with a click; "NEAT 100%" stamp and camera flash.
  This is the exact frame of the #knolling / "oddly satisfying" format, readable muted, and needs no
  text.
- **Core loop (one job, 6–12 min):**
  1. **Dump:** the container empties onto the desk (physics scatter, so every mess differs).
  2. **Sort:** drag (mouse) or grab-and-nudge (d-pad); items snap to a soft grid with magnetic alignment
     to neighbours.
  3. **Fix:** one-gesture micro-actions on some items (wipe a smudge, untangle earbuds, sharpen a pencil,
     close a pen cap).
  4. **Photo:** a **neatness score** computed from alignment, even spacing, grouping (type / colour /
     size) and symmetry. Any tidy layout scores well; there is no single solution (pattern 4).
  5. **Pack:** fit everything back into the container (rotate, tetris-style); a lid that closes is the
     second satisfying beat; "perfect pack" is optional bonus.
  6. **Payday:** client note + pay. The contents tell you who they are (a kid's pencil case, a hiker's
     pack, a widower's sewing box); recurring clients' bags change between visits.
- **Progression / meta:** pay buys tools that speed you up (sorting trays, a ruler that auto-aligns a row,
  a colour-sort brush, a sweep, a bigger desk), as in Librarian's abilities; 5 tiers of clients from
  pencil case to magician's trunk; a **catalogue of ~300 items** that start "Unknown" and are identified as
  you handle them (DinoBones / collectathon); a photo album of your best flat-lays (screenshots players share).
- **Content for 3–6 h:** 30 jobs × ~8 min ≈ 4 h to credits; chasing 100% neatness and perfect packs, the
  catalogue, and a "free desk" mode with procedurally mixed messes add 1–2 h. More than 2 h pass before credits.
- **Art (our pipeline):** strictly top-down flat 2D. One sprite per item; dirt, shadows and highlights
  come from shaders, not extra art; 5 desk surfaces; 15–20 container sprites (open/closed); clients
  appear only as Polaroids and notes (no animation). Top-down object sprites are the easiest thing to
  produce in one consistent style (AI-assisted then hand-cleaned, or licensed icon packs). Capsule
  and logo are human-made. **Lowest art risk of the three.**
- **Scope vs 4 weeks:** W1 drag/snap/grid + neatness scorer + 3 greybox containers (go/no-go + first clips);
  W2 packing, micro-actions, job flow, save; W3 30 jobs as data (JSON), tool upgrades, catalogue;
  W4 juice (sound, particles, photo), controller/Deck pass, achievements, string table. Everything is
  data-driven; the long pole is ~300 item sprites on a parallel art track from week 1. **Fits.**
- **Cut list:** free-desk mode → photo album export → 5th tier → recurring-client story → micro-actions
  down to 2 types → items 300→200. Packing stays (it is the differentiator).
- **Top 3 risks:** (1) 2D flat-lay organizing is under-proven here: the 2D organizing games in [C] are small
  (Deleted Wiki 837, Folded Fables 525 reviews) and the single-solution ones score 72–79%; (2) players
  will compare it to *Unpacking* (2021, outside our dataset), so the knolling grid, neatness score and
  packing must be the identity; (3) a scorer that feels arbitrary would sink reviews. Mitigate with
  visible score reasons ("+ aligned row", "+ colour gradient") and a week-1 playtest.
- **Comparables + revenue:** tidy-up template Sort Them Ducks ($238k est.), DinoBones ($258k), Supermarket
  Chaos ($308k), Librarian ($2.7M outlier); 2D: Moldwasher ($148k), Deleted Wiki, Folded Fables.
  At **$7.99** (3–5 h rule [M:market/small-scope-price-7-to-15-dollars-never-under-5]): typical $12k–60k;
  hit $120k–360k.
- **Steam tags (top 5):** Organizing, Relaxing, Job Simulator, Cozy, Collectathon.
- **Why different:** the 2026 hits are first-person "walk and put back"; ours is the top-down view that
  satisfying-content already uses, with a scored, freeform layout and a packing puzzle as bookends.
  The view is the reason to be 2D, not a compromise.

### Concept C — "Toy Hospital"

- **Pitch:** Mend the town's beloved broken toys: unpick, wash, stitch, re-stuff and repaint them on your
  workbench, then hand them back to their kids.
- **5-second hook:** split screen. A shredded teddy with one eye becomes stitched, fluffed and button-eyed,
  and a child hugs it. Strong and emotional, readable muted.
- **Core loop:** intake ticket with a kid's note ("Mr Buttons lost his ear in the dog incident") → diagnose
  (tap damaged parts) → tool minigames: unpick/unscrew, scrub basin, sew (trace the stitch path), stuff
  (hold to fill), paint, swap parts from drawers → quality score → hand-back reaction + coins.
- **Progression / meta:** buy tools, fabrics, patches and decorations; customise repairs creatively
  (Dressmaker's freedom); 4 toy families (plush, wooden, tin wind-up, robots); workshop upgrades; light
  town story.
- **Content for 3–6 h:** 28 repairs × 8–10 min ≈ 4–5 h.
- **Art (our pipeline):** layered "paper-doll" 2D toys, each 5–10 parts × damaged/clean states; fabric
  textures (AI-assisted fine); workbench, tools; ~10 child portraits. Every toy is unique art, and the
  child portraits must be human-quality. **Highest art load.**
- **Scope vs 4 weeks:** 5–6 tool minigames each need feel-tuning, plus per-toy authoring of damage. Over
  budget at full scope; feasible only cut to 3 tools.
- **Cut list:** paint tool → tin wind-up family → customisation → story → toys 28→18 → 3 tools only.
- **Top 3 risks:** (1) minigame count × polish exceeds 4 weeks; (2) art: unique toys + damage states +
  children faces; (3) value perception: the repair sims that win (ReStory $19.99, 6.7 h) are deep 3D
  systems, so a thinner $9.99 2D version may read as shallow (compare Hozy, 79% at 2.8 h).
- **Comparables + revenue:** ReStory ($4.8M est.), Dressmaker ($6.0M), Thrifty Business ($284k), Moldwasher
  ($148k), Hozy ($1.2M, 79%). At **$9.99–12.99**: typical $15k–97k; hit $150k–585k.
- **Steam tags (top 5):** Job Simulator, Relaxing, Cozy, Crafting, Management.
- **Why different:** no toy-repair game appears among 30,708 window releases (title search in [C]); it
  targets the highest-earning sub-pattern (craft fidelity + customer stories) [T: Relaxing + Job Simulator 17.9×].

---

## 3. Scores and recommendation

Scale 1–5, 5 = best. For scope risk and art risk, 5 means *lowest* risk. Unweighted total.

| Concept | Market evidence | Hook strength | Scope risk | Art risk | Differentiation | **Total** |
|---|---|---|---|---|---|---|
| A — Lost Property Office | 4 (Organizing 5.4× + Investigation 4.5×) | 3 (needs reading) | 3 (two systems) | 3 | 4 | **17** |
| B — Knolling Co. | 3 (Organizing 5.4×, but 2D flat-lay small) | 5 (native "satisfying" format) | 4 (one system, data-driven) | 5 (flat sprites, no characters) | 4 | **21** |
| C — Toy Hospital | 4 (craft job sims earn most) | 4 | 2 (5–6 minigames) | 2 (unique toys, faces) | 5 | **17** |

**Recommendation: B, "Knolling Co."**
- It is the only concept whose whole loop fits the 4-week budget with polish to spare, and whose art is
  achievable at quality with AI-assisted or sourced sprites (the weakest part of our pipeline).
- Its hook is the strongest for our main free channel [M:marketing/short-form-video-is-primary-free-channel]:
  the dump-to-grid timelapse *is* the clip, with no text.
- It sits in the top tag (Organizing 5.4×) and the best pair (Relaxing + Job Simulator 17.9×) while
  avoiding the "Tidy Up the X" first-person clone wave (pattern 9) and the single-solution trap (pattern 4).
- Its weakest score, market evidence for 2D, is testable cheaply: greybox clips in week 1. **Kill or
  reshape criterion:** if 3–5 prototype clips all stay under ~2k views and the 5-minute playtest is not
  fun, fall back to A, which reuses the sort/snap code and the item sprites.
- Ideas to borrow: A's "the items tell you who owns them" (already in B's client notes); C's repair
  micro-actions (kept as one-gesture fixes).
