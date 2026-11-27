# Store page draft: Knolling Co. (working title)

- Written: 2026-11-27 (draft v1, before the art pass; the greybox is in `../assets/greybox/`)
- Inputs: `../BRIEF.md`, `../concepts.md`, `playbooks/marketing.md` §3 and §6, `playbooks/steam-launch-checklist.md`,
  `projects/001-steam-market-research/research/processed/tag_opportunity.csv` **[T]** and `candidates.csv` **[C]**, memories cited as **[M:path]**.
- Deadline: the store page must be **submitted for review by Fri 2026-12-18** (BRIEF schedule). It goes live as Coming Soon on Thu 2027-01-07.
- The name is not final: see `name-check.md`. Every `Knolling Co.` below is a placeholder until the user's trademark check is done.
- Numbers on the page (jobs, objects, hours) must match what ships. Must-have scope is 30 jobs and at least 200 items. 300 items is a should-have, so the copy says **200+** until it is in the build.

---

## 1. Short description (Steam limit 300 characters)

Rules this follows: say what the player *does*, count the mess [M:design/organizing-hits-count-the-mess-and-unlock-speed], and use the same words as the capsule and the first clip (playbook §3).

| # | Text | Chars | Angle |
|---|---|---|---|
| A | Clients tip their bags, drawers and toolboxes onto your desk. Sort every item into a perfect flat-lay, snap the photo, then pack it all back so the lid closes. A cozy organizing job sim with no single right answer: just you, a desk and 200+ very satisfying objects. | 265 | Full loop plus freeform. Says "job sim" and "organizing" for searchers. |
| B | One backpack. 60 loose items. Zero right angles, for now. As a professional organizer you knoll clients' tipped-out bags into immaculate flat-lays, earn a neatness score for every tidy row, and pack it all back in. 30 jobs, 200+ objects to identify. | 249 | Counts the mess, which is the pattern the hits use. Uses the word "knoll". |
| C | Every bag tells a story. A hiker's day pack, a kid's pencil case, a magician's trunk: tip it out, wipe it down, lay every item square on your desk for the perfect photo, then pack it all back so it fits. A relaxing top-down organizing game about right angles. | 259 | Clients and story first. Warmest tone, but the genre comes last. |

**Recommended: A.** Reasons:
- It names the whole loop: tip, sort, photo, pack.
- It contains the words players search for: "organizing", "job sim" and "cozy".
- It says "no single right answer", which answers the main review risk in this niche. Single-solution 2D organizers score 72–79% [M:design/freeform-scoring-beats-single-solution-in-cozy-puzzles].
- It doesn't depend on players knowing the word "knolling", which most don't.

Once the item count is locked, swap B's counted opener into the first line of the long description below. A/B test A against B as the first line of the Coming Soon announcement post.

---

## 2. "About this game" (Steam BBCode, ready to paste)

GIF markers `{GIF-n}` point to the trailer and GIF list in `screenshots-trailer.md` §3. Steam serves uploaded extras as
`[img]{STEAM_APP_IMAGE}/extras/<file>.gif[/img]`. Keep each GIF under about 5 MB, 616 px wide; check the current limit in Steamworks. Valve removed cross-promo links from descriptions in 2024 (playbook §4), so the description has no links to other games.

```bbcode
[img]{STEAM_APP_IMAGE}/extras/gif1_tip_to_grid.gif[/img]
{GIF-1: tip -> scatter -> 3-second snap timelapse into a perfect grid -> "IMMACULATE" stamp + flash}

[h2]Tip it out. Square it up. Pack it back.[/h2]
You are the city's most meticulous professional organizer. Clients drop off their handbags, school bags, junk drawers and toolboxes, and you tip every last thing out onto your desk.

Sort the chaos into a perfect [b]knolling[/b] flat-lay: every object parallel, every gap even, every colour where it belongs. Snap the photo, then fit it all back in so the lid actually closes.

[img]{STEAM_APP_IMAGE}/extras/gif2_score_reasons.gif[/img]
{GIF-2: finished layout -> score panel counts up: "Square to the desk +20 / Lined up in rows +28 / Even spacing +24 / Grouped by type +25"}

[h2]There is no single right answer[/h2]
Group by type, by colour or by size. Make a rainbow, a spiral or strict rows. The neatness score rewards [i]tidy[/i], not [i]correct[/i], and it always shows you why: every point comes with a reason.

[img]{STEAM_APP_IMAGE}/extras/gif3_pack_lid.gif[/img]
{GIF-3: last items rotate and drop into the backpack -> lid closes with a click -> "PERFECT PACK"}

[h2]Then make it all fit again[/h2]
Packing is the second half of every job. Rotate, nest and slide every item back into its bag, drawer or case. A perfect pack earns a bonus, and a lid that closes is its own reward.

[h2]Every bag tells a story[/h2]
A hiker's day pack. A kid's pencil case full of chewed erasers. A widower's sewing box. A magician's trunk that really shouldn't contain a rabbit. Read your clients through their things, and watch regulars' bags change between visits.

[img]{STEAM_APP_IMAGE}/extras/gif4_tools.gif[/img]
{GIF-4: the auto-align ruler snaps a whole row straight in one sweep; colour-sort brush}

[h2]Work faster, tidy bigger[/h2]
Spend your pay on better tools: sorting trays, an auto-align ruler, a colour-sort brush, a sweep and a bigger desk. Then take on bigger messes, from pencil cases to steamer trunks.

[h2]Features[/h2]
[list]
[*][b]30 organizing jobs[/b] across four client tiers, from pocket-sized to trunk-sized
[*][b]200+ hand-finished objects[/b] to sort, wipe, untangle and identify in your catalogue
[*][b]A freeform neatness score[/b] with visible reasons: alignment, spacing, grouping and symmetry
[*][b]A packing puzzle[/b] at the end of every job: rotate, fit, close the lid
[*][b]One-gesture fixes[/b]: wipe the smudge, untangle the earbuds, cap the pen
[*][b]Tools that speed you up[/b] as you earn
[*][b]No timers, no fail states[/b]: take as long as you like
[*][b]Tactile sound[/b]: every material clicks, taps and snaps differently
[*][b]Full controller support[/b] and built for Steam Deck
[/list]

[h2]Follow us[/h2]
We make a new small, polished game every month. Follow our developer page on Steam to get an email when the next one comes out.
```

Copy notes:
- Bullets that depend on the cut list need checking before submission: "four client tiers", "200+", "regulars' bags change" (cut-list item 4), and the steamer/magician trunk (5th tier, cut-list item 3). If the 5th tier is cut, change "steamer trunks" to "toolboxes" and drop the magician line.
- Add "Free-desk mode: endless procedurally mixed messes" only if it ships (cut-list item 1).
- Do not claim playtime in hours on the page until playtests measure it. The brief targets about 4 h to credits.
- The last section is the Developer Homepage call to action [M:marketing/developer-homepage-followers-compound-across-releases]. The homepage must exist and be linked to the app before the page goes live.

---

## 3. Feature bullets (for the trailer end card, press kit and announcement posts)

1. Tip it out, square it up, pack it back: a complete organizing job in 6–12 minutes.
2. No single right answer: a neatness score that rewards tidy, and always says why.
3. A packing puzzle bookends every job; the lid has to close.
4. 30 clients whose things tell their stories.
5. 200+ objects, each with its own satisfying click.
6. Tools that turn you from tidy to terrifyingly efficient.
7. No timers, full controller support, made for Steam Deck.

---

## 4. Tags: the 20, ranked

How Steam uses them (playbook §3; [Steamworks: Tags](https://partner.steamgames.com/doc/store/tags)):
- Only 20 are applied.
- The **top 5** describe the game.
- Some filters use the **first 15**.
- Tags also drive the Personal Calendar, which matters more than Popular Upcoming for us [M:marketing/popular-upcoming-unreachable-after-june-2026].
- Run the Tag Wizard's "Suggest Prioritization", then reorder to match this list.

Columns:
- **Lift** is core-hit lift from **[T]** (`lift_core`: core hits per 1,000 releases with the tag ÷ the 8.1 base rate).
- **Releases** is the number of window releases with the tag.
- **Comps** counts how many of 20 comparable organizing and cozy-job games carry the tag in their top ~7 tags in **[C]**. The 20 are Librarian, DinoBones, Sort Them Ducks, Supermarket Chaos, Moldwasher, Cat Mail Co., Dice Hoarder, Cellar Keeper, Brick by Brick: Tidy Up the Small Town!, Thrifty Business, Cozy Cleaner, Deleted Wiki, Folded Fables, Neat!, Suitcase Stories, Potato Please, Dressmaker, ReStory, Leafy Corner and A Storied Life. The counts were computed in this session from `candidates.csv` tag ids.
- Copying the comparables' tag pattern is the playbook rule, and overlap matters more than order for recommendations.

| Rank | Tag | Lift | Releases | Comps (of 20) | Why it is here |
|---|---|---|---|---|---|
| 1 | Organizing | 5.38× | 274 | 13 | Our genre; the top-lift tag for small-scope hits [M:market/small-scope-winning-tags-organizing-jobsim-incremental-coop] |
| 2 | Relaxing | 2.63× | 2,103 | 19 | The most common tag among comparables; big *and* above average; no timers or fail states |
| 3 | Job Simulator | 3.96× | 372 | 6 | Clients, jobs, pay. Relaxing + Job Simulator is the best pair (17.9×), which separates us from pure tidy-up clones |
| 4 | Cozy | 1.66× | 1,108 | 11 | Audience and Personal Calendar match |
| 5 | Simulation | 1.32× | 6,051 | 13 | Parent genre that 13 of 20 comparables carry; puts us in the sim browse shelves |
| 6 | Casual | 0.83× | 10,937 | 14 | Below-average lift but carried by 14 of 20 comparables, so it helps recommendation overlap. Not in the top 5 |
| 7 | Puzzle | 0.84× | 4,386 | 8 | The packing step is a real spatial puzzle. Puzzle lifts when paired with a hook (market report) |
| 8 | Collectathon | 1.57× | 863 | 8 | The item catalogue goes from "Unknown" to identified |
| 9 | Physics | 1.91× | 1,158 | 1 | The tip-out is a physics scatter; Physics is above average |
| 10 | Inventory Management | 1.34× | 184 | 0 | Packing is literally inventory Tetris; a small, above-average tag |
| 11 | Wholesome | 2.12× | 232 | 0 | Client stories (kid's pencil case, widower's sewing box); small and above average |
| 12 | Incremental | 2.54× | 2,227 | 5 | Pay buys speed-up tools. **Keep it only if tools noticeably change speed**, because Incremental players expect numbers going up |
| 13 | Cleaning | n/a | n/a | 2 | Wipe and fix micro-actions; Moldwasher and Cozy Cleaner carry it. Too small to be in [T] |
| 14 | 2D | 0.59× | 6,233 | 2 | Accurate, so it helps filters. Low lift, so it stays out of the top 5 ("art style is not a hook") |
| 15 | Top-Down | 0.45× | 1,103 | 0 | Accurate and used by filters (first 15); low lift |
| 16 | Singleplayer | 0.94× | 4,297 | 3 | Accurate |
| 17 | Cute | 0.96× | 2,175 | 2 | Matches the art direction if the art pass lands cute |
| 18 | Colorful | 0.46× | 1,349 | 2 | Colour grouping is a core scoring axis |
| 19 | Family Friendly | 0.0× core | 585 | 0 | Accurate: no mature content. Tells parents and streamers it is safe |
| 20 | Sandbox | 1.73× | 1,419 | 0 | **Only if Free-desk mode ships** (cut-list item 1). Otherwise use Point & Click (1.0×, 4 comps: mouse-only drag) |

Do not use:
- **Minimalist** (0.17×) or **Hidden Object** (0.49×; it attracts players expecting a find-the-item game).
- **Management**: the economy is too thin. Hozy's 79% score is a warning about overpromising (concepts.md §1.2).
- **Artificial Intelligence**: players apply it themselves to games with AI art. Librarian and Cellar Keeper carry it and still scored 90–93%, so don't fight it, but don't add it.

---

## 5. Price and launch discount

- **Price: US$7.99.** Rule of thumb: $7.99 for a 3–5 h game; hits have a median price of $9.99; the $5–9.99 band has 15.3 hits per 1,000 releases versus 2.7 under $5 [M:market/small-scope-price-7-to-15-dollars-never-under-5].
- Comparable prices: DinoBones, Sort Them Ducks and Librarian at $5.99; Brick by Brick at $7.99; Moldwasher (2D) at $8.99; Unbox the Room at $7.99 (Steam appdetails, checked 2026-11-27).
- Under $10 also gets the better wishlist conversion (0.15x vs 0.10x above $10) [M:marketing/wishlist-conversion-0-1-to-0-15x-first-week].
- **Revisit at T-3 weeks:**
  - If playtests show at least 6 h with Free-desk mode and 300 items, consider $9.99.
  - If credits arrive in under 2.5 h, stay at $7.99 and add replay hooks. Refunds are allowed under 2 h of play [M:marketing/steam-refund-two-hours-short-games].
- **Launch discount: 10% for 7 days** (US$7.19). This is the playbook default for games under $10. Valve suggests 10–15%, and the maximum is 40%.
  - It must be configured before release.
  - Then no discount is possible for 30 days. Launching Thu 2027-02-11 keeps us eligible for the Spring Sale on Mar 18 [M:marketing/steam-release-blocks-discounts-30-days].
  - Plan 20% for the Spring Sale, stepping up slowly in year 1 (playbook §6).
- **Regional pricing:** accept Valve's recommended regional prices. China's recommended price is lower, so revenue per Chinese player is about 47% of a US player's (playbook §3).
- **Do not run paid ads** at this price [M:marketing/no-paid-ads-for-games-under-10-dollars].

---

## 6. Supported languages plan and budget

Policy (playbook §3): Simplified Chinese at launch for low-text games. It was over 50% of the Steam hardware survey in Feb 2025, and New & Trending thresholds are set per country and language.

**Text volume estimate.** Target under 5,000 source words; the estimate assumes catalogue blurbs of at most 8 words.

| Content | Estimate |
|---|---|
| UI, menus and settings | ~600 words |
| Score reasons and tool names | ~250 |
| 30 client notes × ~45 words | ~1,350 |
| 300 item names + optional 8-word catalogue blurbs | ~600 names + ~2,400 blurbs |
| 15 achievements | ~200 |
| Store page (short and long description, captions) | ~700 |
| **Total** | **~4,000 without blurbs, ~6,100 with blurbs** |

Cost per language:

| Option | Rate | Cost per language |
|---|---|---|
| Agency, EN → ZH-Hans | €0.09–0.12/word ([Allcorrect pricing](https://allcorrectgames.com/localization-pricing/), vendor page, 2026) | ≈ $400–750 + LQA |
| General range | $0.10–0.20/word ([Alconost 2026 guide](https://alconost.com/en/blog/steam-language-mix-indies); vendor) | ≈ $400–1,200 |
| Store page only | $100–300 per language (same guide) | cheap first step |

Vendor numbers are unverified and may run high. Get two quotes, including one freelancer with games credits.

**Plan:**

| Language | Store page | Game | Budget | When |
|---|---|---|---|---|
| English | ✓ | ✓ | n/a | launch |
| **Simplified Chinese** | ✓ (live with Coming Soon on Jan 7) | ✓ full + LQA (2 h pass on a build) | **$900 cap** (≈ $150 store + $600 game + $150 LQA) | must-have for launch |
| Japanese | ✓ | ✓ | ~$800 | launch if budget allows (cut-list item 6 keeps ZH-Hans + JA + DE) |
| German | ✓ | ✓ | ~$700 | launch if budget allows |
| FR, ES, PT-BR, RU, KO | store page only at launch ($100–300 each) | patch 1 if ZH/JA/DE revenue share justifies | ~$600–900 each | after launch |

Engineering prerequisites (add to the dev plan):
- A string table from day 1, and no text baked into sprites or the logo.
- A CJK font. Noto Sans SC is OFL-licensed, adds about 10–20 MB, and needs logging in `assets/LICENSES.md`.
- UI that survives about 30% longer German strings.
- A localized logo for ZH-Hans and JA, since Steam supports localized capsules (see `capsule-brief.md`).
- Translators need a context sheet with a screenshot per string.

Track revenue share by language from day 1 (playbook §7). This is the experiment for this title.

---

## 7. System requirements

Basis:
- Godot 4.7.1 with the `gl_compatibility` renderer (OpenGL 3.3 / GLES3), from `../game/project.godot`.
- 2D only, 1280×800 base viewport.
- Export presets exist for Windows, Linux and macOS (`../game/export_presets.cfg`).
- The BRIEF ships **Windows + Linux/Deck**. **macOS is a user decision** (see below).

Fill these from a measured build before submission. Build size target is under 300 MB; hits are 2 GB or less, and 88% of 1 GB-or-smaller builds score 80% or more [M:market/small-scope-hits-are-small-builds-single-player-3-to-9-hours].

| | Minimum | Recommended |
|---|---|---|
| **Windows** OS | Windows 10 64-bit | Windows 10/11 64-bit |
| Processor | Dual-core 2.0 GHz (x86-64) | Quad-core 2.5 GHz |
| Memory | 4 GB RAM | 8 GB RAM |
| Graphics | OpenGL 3.3 compatible, e.g. Intel HD Graphics 4000 / GeForce GT 630 / Radeon HD 7000 series | Any GPU from 2015 or later |
| Storage | 500 MB available space | 500 MB available space |
| **Linux / SteamOS** OS | 64-bit, Ubuntu 22.04 or equivalent, SteamOS 3 | same |
| Graphics | OpenGL 3.3 (Mesa 21+ or proprietary driver) | same |
| Other | same CPU, RAM and storage as Windows | |
| **macOS** (if shipped) | macOS 11 Big Sur or later, Apple Silicon or Intel (universal build), 4 GB RAM, 500 MB | macOS 13+, 8 GB |
| **Steam Deck** | Target **Verified**: native 1280×800, full controller with Deck glyphs, text ≥ 28 px (BRIEF), no launcher, works offline. Request review at T-3 weeks (checklist §H) | |

Notes:
- The GPU examples are our reading of what OpenGL 3.3 means. **Measure them** on the oldest hardware available, or remove the model names.
- The macOS minimum version follows Godot's export requirement for 4.7. Verify it in the Godot docs before submission.
- Shipping macOS costs time we have not budgeted:
  - Apple Developer account ($99/yr) for signing and notarization. Whether Steam strictly needs notarization is unverified.
  - One more test platform.
  - Our CI does not build or test it yet.
- **Recommendation: no macOS at launch.** Revisit after launch if the wishlist comments ask for it. The Mac share of Steam users is small, roughly 2% in the hardware survey (unverified; check the current survey).

---

## 8. Steam AI disclosure (content survey) draft

Basis:
- Pre-generated AI content that players see must be disclosed. AI-written code is exempt since the Jan 2026 revision [M:tech/steam-ai-disclosure-player-facing-only]; checklist T-8 weeks.
- The disclosure must match `assets/LICENSES.md`. Every sprite row records its source and whether AI was used. That file doesn't exist yet: create it with the first sprite.

**Survey answers:**
- *Pre-generated AI content:* **Yes.**
- *Live-generated AI content:* **No.** Nothing is generated while the game runs, so no guardrails section is needed.

**Public text** (shown on the store page; keep it plain and specific):

> Some of the in-game object illustrations (the everyday items you sort, such as pens, keys and snacks) were created with the help of AI image tools and then redrawn, corrected and cleaned up by hand. Our store capsule art, logo and key art were made entirely by human artists. All in-game text and music were written or licensed from human creators. Nothing in the game is generated by AI while you play.

Conditions for that text to stay true. Edit it if any of these change:
- **Item sprites:** every AI-assisted sprite gets a manual pass. If some are licensed packs instead, the text still holds because it says "some".
- **Capsule, logo, library hero and key art:** human-made, with no AI underpainting. Write this into the artist contract (`capsule-brief.md`).
- **Text:** client notes, item names and blurbs are human-written or human-edited. If Claude drafts them, they count as AI-generated player-facing text. Then either disclose "in-game text was drafted with AI assistance and edited by our team", or rewrite them by hand. **User decision**, flagged below.
- **Music:** confirm each licensed track's source is not AI-generated, and record it in LICENSES.md.
- **Screenshots and trailer:** they show the AI-assisted sprites, which the disclosure already covers. Do not use AI video or upscaling on store media.

---

## 9. Content survey answers (mature content and ratings)

| Survey question | Answer | Note |
|---|---|---|
| Some nudity or sexual content | No | |
| Frequent violence or gore | No | |
| Adult-only sexual content | No | |
| Gratuitous sexual content | No | |
| Any mature content (general) | No | Keep item list free of cigarettes, alcohol, drugs, real weapons and gambling items. A multitool or scissors is fine. "Pills" should read as a generic first-aid box |
| AI-generated content | Yes, pre-generated (§8) | |
| Real brands or logos | None (not a survey item) | No real logos on items: trademark and review risk. Use invented brands |
| Germany (USK via Steam questionnaire) | Answer Valve's questionnaire; expect USK 0 | Since 2024-11-15, unrated games are hidden in Germany. Do **not** reuse an IARC-issued USK rating ([Steamworks: Germany](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany)) |
| Indonesia rating | Answer the questionnaire | [Steamworks: Indonesia](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/indonesia) |
| In-game purchases or ads | None | |
| User-generated content / online interaction | None (photo album export is local only) | |

The content survey must be complete before the store page and build can be submitted (checklist T-8 weeks). Fill it in the week of Dec 14.

---

## 10. Open items for the user

1. **Name**: run a real trademark search, then lock the name by **Fri Dec 4**. The logo needs it (`name-check.md`).
2. **Short description**: A (recommended) or B.
3. **macOS at launch**: yes or no. The recommendation is no.
4. **Languages at launch**: ZH-Hans only (≈$900), or ZH-Hans + JA + DE (≈$2.4k).
5. **AI-drafted in-game text**: disclose it, or rewrite it by hand.
6. Create the Developer Homepage before the Coming Soon page goes live.
