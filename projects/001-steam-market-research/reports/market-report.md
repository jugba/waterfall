# Steam market report — releases 2025-11-26 → 2026-11-26

- Project: 001-steam-market-research · Iteration 002 · Written 2026-11-26
- Data: every game in Steam search released in the window (30,708), enriched for the 745 with ≥1,000 reviews.
- How to read the citations:
  - **[A §X]** = section X of `research/processed/analysis.md`, produced by `research/scripts/analyze.py`.
  - **[G]** = `research/processed/games_analyzed.csv`, one row per game.
  - **[T]** = `research/processed/tag_opportunity.csv`.
  - **[M:path]** = a memory file.
- Revenue figures are **estimates**, not reported sales. The formula is units = total reviews × 30 (range 20–60), then net revenue = units × list price × 0.5. The 0.5 covers Steam's 30% cut, VAT, regional pricing, discounts and refunds. Source: [M:marketing/boxleiter-multiplier-about-30x-for-recent-games]. Any single game's figure can be off by ±50% or more.

## Executive summary

1. **The success bar is a top-2% outcome.**
   - Of 30,708 releases, 744 reached 1,000 reviews (2.4%) and 530 also scored ≥80% (1.7%).
   - Our **core target** (small scope, paid, genuinely new launch) has **250 hits, or 0.81% of releases**.
   - The median release got fewer than 10 reviews, and the 90th percentile got 119. [A §Funnel, §Review-count percentiles]
2. **A typical small-scope hit earns roughly $340k net (estimate).**
   - The middle half of the 250 core hits runs from $176k to $708k, and the top 10% exceed $1.9M.
   - At the median price of $9.99, it takes about 2,000 total reviews. [A §Estimated net revenue — core target, §Segment profile]
3. **The data is cleaner after three corrections.**
   - 22% of the "new releases" with ≥1k reviews had Steam reviews more than 45 days before their listed date. These are Early Access graduates and re-releases such as Valheim, Palworld and Timberborn, and they are excluded from the core target.
   - The search-row review count is language-filtered, roughly English only. The all-language total is a median 1.39× larger.
   - SteamSpy has real data for only 176 of 744 games. [A §Data checks]
4. **Small-scope hits are cheap and small.**
   - Median price is $9.99. 58% are priced under $10 and none above $20.
   - Median install size is 2 GB, with 151 of 250 at 2 GB or less.
   - Median SteamSpy playtime is about 4.8 h. [A §Segment profile, §Price bands, §Scope signal — Install size]
5. **What over-indexes for the core target**, measured as hit rate per tag vs. the base of 8.1 hits per 1,000 releases [A §Tag opportunity — highest core-target lift]:
   - Organizing (5.4×), Mining (4.9×), Investigation (4.5×), Job Simulator (4.0×), Co-op (3.4×).
   - Incremental (2.5×), Online Co-Op (2.5×), Relaxing (2.6×), Management (2.4×).
6. **What is saturated**, meaning many releases and a low hit rate [A §Saturated tags]:
   - 2D Platformer (0.19×), Turn-Based Tactics (0.23×), Arcade (0.39×), Top-Down (0.45×), Bullet Hell (0.49×) and Minimalist (0.17×).
   - Generic "2D" (0.59×) and "Casual" (0.83×) are below average too.
7. **Online co-op has the biggest upside, not the best average.**
   - The median core co-op hit is estimated at $771k (p75 $2.1M), and the cluster includes MECCHA CHAMELEON, How to Fish and Gamble With Your Friends.
   - But only 55–57% of ≥1k-review co-op or multiplayer games score ≥80%, vs. 82% for single-player-only games. [A §Candidate directions, §Player mode]
8. **The cheapest tier is a trap.**
   - $0.01–4.99 is 42% of all releases but produces only 2.7 successes per 1,000.
   - The rate is 15.3 per 1,000 at $5–9.99, 29.3 at $10–14.99 and 71.7 at $15–19.99. That gradient mostly reflects investment and quality, not elasticity. [A §Price bands]
9. **Release Tuesday to Thursday, never on a weekend.**
   - Thursday has 26.5 successes per 1,000 releases and Tuesday 20.3.
   - Saturday has 3.7 and Sunday 5.7.
   - This is correlational, because hobby releases cluster at weekends. [A §Release weekday]
10. **Recommended first directions for a ~10-week Godot project:**
    - (a) a cozy organizing / job-sim game;
    - (b) a "juicy" incremental with a gambling or roguelite hook.
    - A small online co-op comedy is the high-variance option. Details are in the directions section below.

## Funnel

| Stage | Games | Share of releases | Source |
|---|---|---|---|
| Released in window (Steam search, type game) | 30,708 | 100% | [A §Funnel] |
| ≥10 reviews (has a score) | 11,436 | 37.2% | [A §Funnel] |
| ≥100 reviews | 3,405 | 11.1% | [A §Funnel] |
| ≥1,000 reviews | 744 | 2.4% | [A §Funnel] (745 minus one free prologue) |
| **Success** (≥1k reviews and ≥80%) | **530** | 1.7% | [A §Funnel] |
| **Small-scope success** (not major publisher, ≤$20, ≤10 GB) | **332** | 1.08% | [A §Funnel] |
| **Core target** (small scope, paid, first review no more than 45 days before release) | **250** | 0.81% | [A §Funnel] |

The step from 332 small-scope successes to 250 core hits removes two groups:
- 29 free-to-play games;
- about 53 small-scope games whose reviews predate the window, such as TCG Card Shop Simulator, Fields of Mistria, Mon Bazou and Rhythm Doctor. These left Early Access in the window, so their counts reflect years of sales. [A §Small-scope successes with prior reviews]

Downside reference: a paid release that reaches the 90th percentile (119 reviews) at $9.99 is estimated at about $18k net. The 75th percentile (21 reviews) is about $3k. Both use the formula above.

## What wins overall (all 530 successes)

- **Scale wins at the top.** The highest estimated net revenue in the window came from:
  - big-budget releases: Crimson Desert, Resident Evil Requiem, Forza Horizon 6;
  - EA graduates: Valheim, Palworld, Enshrouded;
  - Slay the Spire 2, a sequel with about 236k all-language reviews. [A §Top 30 successes overall]
- **Price and scope correlate with reaching 1k reviews.** The success rate per 1,000 releases rises from 2.7 at under $5 to 136–164 at $20 and above. Median reviews per release (among those with ≥10) rise from 22 to about 500. [A §Price bands]
- **Install size and score move in opposite directions.**
  - Among ≥1k-review games, 88% of those ≤1 GB score ≥80%, but only 52–54% of those above 10 GB do.
  - Big games attract more reviews, and also more negative ones. [A §Scope signal — Install size]
- **Multiplayer and free-to-play draw reach but worse scores.**
  - 63% of ≥1k-review games that missed 80% have multiplayer, vs. 31% of successes.
  - 20% of the ones that missed are free-to-play, vs. 6% of successes. [A §Segment profile]
- **Early Access converts better.** Games with the Early Access tag have a success rate of 30.3 per 1,000, vs. 16.6 per 1,000 for the rest. EA games are fewer and more invested, and EA also lets reviews accumulate before 1.0. [A §Early Access vs full release]

## What wins for small scope (the factory's target: 250 core hits)

Profile, from [A §Segment profile] and [G]:
- **Price:** median $9.99, and 58% are under $10.
  - Band counts: 32 hits at $0.01–4.99, 110 at $5–9.99, 56 at $10–14.99 and 47 at $15–19.99. [A §Price bands]
- **Score:** median 94% positive. The bar is ≥80%, but hits typically sit in "Very/Overwhelmingly Positive".
- **Size:** median 2 GB. 151 of 250 are 2 GB or less, and only 32 are 5–10 GB.
- **Players:** 97% have single-player, while 27% have multiplayer and 25% co-op.
- **Publishing:** 46% are strictly self-published and 59% have the developer among the publishers. Indie labels publish the rest, e.g. Funday Games, tinyBuild, Playstack, Kwalee, Black Lantern Collective.
- **Early Access:** 16% are still in Early Access.
- **Platforms:** 35% have a Mac build and 16% a Linux build. Godot exports these cheaply.
- **Language support:** the median core hit supports 11 languages, and 61% support 10 or more.
  - 41 core hits shipped in one language only, mostly narrative or very cheap games. [A §Scope signal — Languages]
- **Release month:** hits are spread across all months, with no strong seasonality. The 36 April hits are the peak, and October–November are right-censored. [A §Release month]

## Genre/tag opportunity — demand vs saturation

How the table is built:
- Hit rates are computed against the **whole release base** (candidates.csv tag ids, named via Steam's tag list).
- "Releases" is the number of releases in the window carrying the tag, which measures saturation.
- "Core /1000" is core-target hits per 1,000 of those releases.
- Lift is that rate divided by the base rate of 8.1.

Full table: [T]; top rows: [A §Tag opportunity].

| Tag | Releases | ≥100 reviews | Core hits | Core /1000 | Lift | Read |
|---|---|---|---|---|---|---|
| Organizing | 274 | 60 | 12 | 43.8 | 5.4× | Under-supplied and hot (Librarian, Cat Mail Co.) |
| Mining | 250 | 50 | 10 | 40.0 | 4.9× | Under-supplied; pairs with incremental (Space Rock Breaker, MineMogul) |
| Investigation | 300 | 49 | 11 | 36.7 | 4.5× | Under-supplied (Galley House, Message from Deep Space) |
| Job Simulator | 372 | 53 | 12 | 32.3 | 4.0× | Dressmaker, ReStory |
| Co-op | 788 | 193 | 22 | 27.9 | 3.4× | High reach, lower scores |
| Crafting | 593 | 117 | 14 | 23.6 | 2.9× | |
| Detective | 393 | 72 | 9 | 22.9 | 2.8× | |
| Relaxing | 2,103 | 270 | 45 | 21.4 | 2.6× | Big *and* still above average |
| Incremental | 2,227 | 304 | 46 | 20.7 | 2.5× | Big *and* still above average |
| Online Co-Op | 1,063 | 258 | 22 | 20.7 | 2.5× | |
| Management | 1,344 | 248 | 26 | 19.3 | 2.4× | |
| Cooking | 307 | 55 | 6 | 19.5 | 2.4× | |
| Physics | 1,158 | 143 | 18 | 15.5 | 1.9× | |
| Deckbuilding | 778 | 110 | 12 | 15.4 | 1.9× | Average-plus; dominated by Slay the Spire 2 overall |
| Shop Keeper | 541 | 80 | 8 | 14.8 | 1.8× | |
| Cozy | 1,108 | — | 15 | 13.5 | 1.7× | |
| Pixel Graphics | 2,490 | 260 | 24 | 9.6 | 1.2× | Neutral |
| Roguelite | 2,595 | 269 | 22 | 8.5 | 1.0× | Neutral, crowded |
| Puzzle | 4,386 | 288 | 30 | 6.8 | 0.8× | Crowded, below average unless paired with a hook (Investigation, Collectathon) |
| 2D | 6,233 | 340 | 30 | 4.8 | 0.6× | Art style is not a hook |
| Bullet Hell | 1,261 | 96 | 5 | 4.0 | 0.5× | Saturated by survivors-likes |
| Top-Down | 1,103 | 51 | 4 | 3.6 | 0.45× | Saturated |
| Arcade | 3,498 | 171 | 11 | 3.1 | 0.39× | Saturated |
| Turn-Based Tactics | 1,083 | 97 | 2 | 1.8 | 0.23× | Saturated for small scope |
| 2D Platformer | 1,893 | 82 | 3 | 1.6 | 0.19× | Most saturated large tag |
| Minimalist | 733 | — | 1 | 1.4 | 0.17× | Avoid |

Strongest tag pairs among core hits [A §Tag pairs]:

| Pair | Releases | Core hits | Lift |
|---|---|---|---|
| Relaxing + Job Simulator | 55 | 8 | 17.9× |
| Relaxing + Management | 103 | 10 | 11.9× |
| Relaxing + Resource Management | 74 | 7 | 11.6× |
| Physics + Incremental | 81 | 6 | 9.1× |
| Puzzle + Investigation | 124 | 9 | 8.9× |
| Co-op + Funny | 123 | 7 | 7.0× |
| Relaxing + Incremental | 406 | 19 | 5.7× |

These rates come from small numbers (4–12 hits per tag). Treat them as direction, not precision.

## Price bands

All release counts in the table are from [A §Price bands]. List price is the search-row price with the discount removed. 57 joke listings priced above $100 are excluded.

| Band | Releases | Share | Successes /1000 | Core hits | Median reviews (≥10) | Median est. net revenue of successes |
|---|---|---|---|---|---|---|
| Free | 3,689 | 12% | 8.9 | 0 | 30 | — |
| $0.01–4.99 | 12,802 | 42% | 2.7 | 32 | 22 | $111k |
| $5–9.99 | 8,833 | 29% | 15.3 | 110 | 35 | $233k |
| $10–14.99 | 2,939 | 10% | 29.3 | 56 | 68 | $471k |
| $15–19.99 | 1,353 | 4% | 71.7 | 47 | 105 | $730k |
| $20–29.99 | 624 | 2% | 136.2 | 1 | 300 | $1.3M |
| $30–49.99 | 283 | 1% | 137.8 | 4 | 488 | $3.0M |

Reading:
- **$0.01–4.99 is a flood of low-effort releases.** Success odds there are 1/6 of the $5–9.99 band.
- **The $10–19.99 bands have far better odds per release.** That reflects selection (more invested games), so raising the price of a weak game will not buy success.
- **Price against playtime** [A §Playtime vs price]:
  - median playtime is 4.4 h at $5–9.99, 7.0 h at $10–14.99 and 5.8 h at $15–19.99;
  - value per dollar falls from about 0.56 h/$ to about 0.30 h/$.
- **What that implies for our price:** $7.99–9.99 for a 3–5 h game, and $12.99–14.99 only if it holds 6 h or more.
- **The refund rule supports the floor.** Steam refunds anything under 2 h played [M:marketing/steam-refund-two-hours-short-games]. 32 of 229 core hits with playtime data have a median under 2 h. Their median price is $7.49, and 20 of the 32 cost $7.99 or less.

## Scope signals (playtime, size, languages)

| Signal | Evidence | Implication |
|---|---|---|
| Install size | Success rate among ≥1k-review games is 88% at ≤1 GB, 81% at 1–2 GB, 75% at 2–5 GB, 72% at 5–10 GB and 52–54% above 10 GB. Core median is 2 GB. [A §Scope signal — Install size] | Small builds are normal for hits. There is no need to bulk up. |
| Playtime | Core median is about 4.8 h (SteamSpy median playtime; p25 3.0 h, p75 8.7 h). Success rate is 78% for games with a 2–5 h median, 62% for 1–2 h and 59% above 20 h. [A §Scope signal — Median playtime], [G] | Design for 3–6 h of first-play value plus a reason to replay. |
| Languages | The median core hit supports 11 languages, and 61% support 10 or more. One-language games also do fine (77% success rate, 41 core hits). [A §Scope signal — Languages] | UI-light designs make 10+ languages cheap. Text-heavy games can launch in English and add languages later. |
| Player mode | Single-player-only: 82% success rate. Co-op: 57%. Multiplayer: 55%. Co-op tags still have 3.4× core lift. [A §Player mode], [T] | Co-op raises reach and variance. The netcode and review risk are real. |
| Media | Core median: 10 screenshots, 2 trailers. [A §Segment profile] | Budget for 2 trailers. |
| Early Access | 16% of core hits are still in EA. [A §Segment profile] | EA is optional; it is not required for small games. |

## Notable small-scope examples (core target)

All rows are from [A §Core-target successes] and [G]. "Est. net" is the 20–60× range. Descriptions paraphrase the Steam short description (appdetails, in `raw/`).

| # | Game | Price | Reviews (all languages) | % | Est. net | Why it is notable |
|---|---|---|---|---|---|---|
| 1 | MECCHA CHAMELEON | $5.99 | 97,711 | 91 | $5.9M–17.6M | Paint-yourself hide-and-seek with friends. One readable hook, self-published under a personal handle. |
| 2 | How to Fish | $7.99 | 94,553 | 96 | $7.6M–22.7M | 1–4 player physics fishing comedy at 1 GB. The co-op "friendslop" template. |
| 3 | Dressmaker | $14.99 | 26,741 | 99 | $4.0M–12.0M | Cozy sewing job-sim (published by Free Lives). Shows a real-world craft as a hook; 3 languages only. |
| 4 | Librarian: Tidy Up the Arcane Library! | $5.99 | 29,685 | 93 | $1.8M–5.3M | Put books back on shelves. The purest "Organizing" hit, at 2 GB. |
| 5 | Gamble With Your Friends | $7.99 | 27,358 | 89 | $2.2M–6.6M | Co-op casino crawler with a shared debt. Combines gambling and co-op comedy. |
| 6 | Scritchy Scratchy | $6.99 | 20,930 | 94 | $1.5M–4.4M | Scratch-card incremental. Shows a tiny loop with heavy "juice". |
| 7 | Retro Rewind – Video Store Simulator | $19.90 | 12,401 | 95 | $2.5M–7.4M | Nostalgia shopkeeper at the top of the price band, self-published. |
| 8 | ReStory: Chill Electronics Repairs | $19.99 | 16,016 | 95 | $3.2M–9.6M | Repair-shop job-sim at 1 GB (tinyBuild). |
| 9 | Creature Kitchen | $7.99 | 10,835 | 99 | $0.9M–2.6M | "Creepy-cozy" cooking. Shows a tonal twist on cozy. |
| 10 | Cat Mail Co. | $14.99 | 9,158 | 94 | $1.4M–4.1M | Cozy parcel-sorting with an optional online co-op mode. Organizing + Management. |
| 11 | Bills Must Be Paid | $6.99 | 15,125 | 96 | $1.1M–3.2M | "Short active incremental", self-published. |
| 12 | Berry Bury Berry | $7.99 | 9,541 | 97 | $0.8M–2.3M | First-person incremental at 0.6 GB. Combines Incremental + Physics + Horror. |
| 13 | Space Rock Breaker | $2.99 | 5,073 | 96 | $152k–455k | Short asteroid-mining incremental. Mining + Incremental at a low price. |
| 14 | A Game About Feeding A Black Hole | $6.99 | 3,796 | 87 | $265k–796k | Short incremental at 0.5 GB, two-person team. |
| 15 | RACCOIN: Coin Pusher Roguelike | $11.99 | 5,043 | 86 | $605k–1.8M | Coin-pusher deckbuilder (Playstack). Puts a gambling-machine fantasy on a roguelike. |
| 16 | The Incident at Galley House | $19.99 | 5,220 | 97 | $1.0M–3.1M | Deduction mystery. Investigation lifts even at $19.99. |
| 17 | The Mermaid Mask | $19.99 | 3,374 | 99 | $674k–2.0M | Locked-room murder puzzle by SFB Games, at 1 GB. |
| 18 | Endacopia | $16.50 | 9,433 | 99 | $1.6M–4.7M | Point-and-click horror styled like old edutainment, in one language. Shows that an aesthetic twist can be the hook. |
| 19 | Idols of Ash | $2.99 | 3,828 | 97 | $114k–343k | First-person horror climbing. A tiny scope at an impulse price. |
| 20 | Birdwatching Notebook | $9.99 | 2,143 | 98 | $214k–642k | Desktop-companion idle game at 0.5 GB. A niche format with a loyal audience. |
| 21 | Fortune Mill | $7.99 | 4,490 | 83 | $359k–1.1M | Pachinko/darts/scratch-off incremental, solo-named developer. |
| 22 | Antivirus Survivors 2003 Professional | $5.99 | 1,957 | 98 | $117k–352k | Survivors-like rescued by a Y2K theme in a saturated tag. 23 languages, 0.25 GB. |

## Candidate game directions (~10 weeks, small team, Godot 2D / light 3D)

Notes that apply to all five directions:
- **Cluster numbers** come from [A §Candidate directions]. A game counts if it carries any of the listed tags.
- **Revenue** is the p25–p75 estimated net revenue of that cluster's core hits at 30×. *Conditional on being a hit*, it is not an expected value.
- **Odds:** about 1–2% of releases in any cluster become core hits, and 12–24% reach 100 reviews.

### 1. Cozy organizing / job sim — recommended first

- **Concept:** sort, tidy, repair or craft a real-world thing, in 2D or light 3D. A tonal twist is optional.
- **Evidence:**
  - Cluster: 1,611 releases, 33 core hits (20.5 per 1,000), 2.5× lift.
  - Organizing (5.4×) and Job Simulator (4.0×) are the top two tags.
  - Relaxing + Job Simulator is the best pair, at 17.9×. [T], [A §Tag pairs]
- **Comparables:** Librarian, Dressmaker, ReStory, Cat Mail Co., Creature Kitchen.
- **Estimated net revenue if it hits:** $197k–$637k, median $284k at a median price of $7.99. A $12.99–14.99 price fits if content reaches 5 h or more.
- **Why it fits:** content-light systems, low art-asset count, no netcode, small builds, and it reads instantly in a muted 10-second clip [M:marketing/short-form-video-is-primary-free-channel].
- **Risks:**
  - The tags are small (274–372 releases), so the lift could fade as copycats arrive.
  - Playtime could fall under 2 h, which invites refunds. Mitigate with unlockable areas and a sandbox mode.
  - It needs a distinctive "object fantasy" (books, dresses, electronics, parcels).

### 2. "Juicy" incremental with a gambling or roguelite hook — recommended first (alt)

- **Concept:** a short (3–5 h), very tactile incremental. Smash, scratch, dig or mine, with automation unlocks and physics.
- **Evidence:**
  - Cluster: 3,331 releases, 50 core hits (15.0 per 1,000), 1.8× lift.
  - Incremental alone has 46 core hits at 2.5× lift. Physics + Incremental is 9.1× and Relaxing + Incremental 5.7×.
  - Mining has 4.9× lift. [T], [A §Tag pairs]
- **Comparables:** Scritchy Scratchy, Bills Must Be Paid, Berry Bury Berry, Space Rock Breaker, A Game About Feeding A Black Hole, Fortune Mill, Can 'Em All.
- **Estimated net revenue if it hits:** $143k–$440k, median $234k at a median price of $6.99.
- **Why it fits:** the smallest content scope of any direction. A Godot 2D or simple 3D-physics game can be done in weeks, and players accept a short length at $4.99–7.99.
- **Risks:**
  - Incremental/Idler is large (about 2.2k releases each) and full of low-effort clones. The pure "Idler" tag lifts only 1.3×.
  - Gambling themes need care with age ratings and payment platforms. Use no real-money mechanics.
  - Low price limits revenue.

### 3. Online co-op comedy ("friendslop") — high variance

- **Concept:** 2–6 player online physics comedy in light 3D with one readable hook (hide, fish, golf, gamble).
- **Evidence:**
  - Online Co-Op: 1,063 releases, 22 core hits (20.7 per 1,000), 2.5× lift.
  - It has the highest conditional revenue: median $771k, p75 $2.1M.
  - Co-op + Funny lifts 7.0×. [A §Candidate directions], [A §Tag pairs]
- **Comparables:** MECCHA CHAMELEON, How to Fish, Gamble With Your Friends, Super Battle Golf, YAPYAP, BOMBANANA!, Machine Party, Worst Class Ever.
- **Estimated net revenue if it hits:** $267k–$2.1M, median price $7.99.
- **Risks:**
  - Co-op and multiplayer games score ≥80% far less often (55–57% vs 82%). [A §Player mode]
  - Netcode, lobbies and Steam networking in Godot are new tech for us; check memories/tech before committing.
  - Testing needs several machines.
  - The game is dead without a group-video moment, so it depends on creators and short-form virality.
  - Treat it as a second or third project once the pipeline is proven.

### 4. Detective / investigation puzzle

- **Concept:** a self-contained deduction mystery (one location, one case). It can be 2D illustrated.
- **Evidence:**
  - Cluster: 1,110 releases, 15 core hits (13.5 per 1,000), 1.7× lift.
  - Investigation has 4.5× lift and Puzzle + Investigation 8.9×. [T], [A §Tag pairs]
- **Comparables:** The Incident at Galley House, The Mermaid Mask, The Death Game Report, The Message from Deep Space, lily's world XD.
- **Estimated net revenue if it hits:** $154k–$433k, median price $10.99. The genre supports $19.99 for strong writing.
- **Risks:**
  - The writing and puzzle-design load is high and the content is not reusable.
  - The text-heavy format makes localisation costly.
  - Replay value is low, and a 2–4 h game is close to the refund line.

### 5. Shopkeeper / management sim with a nostalgia theme

- **Concept:** run a themed shop (video store, repair shop, gas station) with a customer loop and decoration.
- **Evidence:**
  - Cluster: 1,792 releases, 28 core hits (15.6 per 1,000), 1.9× lift.
  - Relaxing + Management lifts 11.9×. [A §Candidate directions], [A §Tag pairs]
- **Comparables:** Retro Rewind, Probably Stolen, ReStory, The Last Gas Station, Roadside Research.
- **Estimated net revenue if it hits:** $234k–$606k, median price $12.49.
- **Risks:**
  - Most hits are first-person 3D with many props, which strains a 10-week art budget.
  - The large TCG Card Shop Simulator copycat wave already exists.
  - A top-down 2D take is unproven in this data.

### Directions to avoid for game #1

- **2D platformer:** 0.36× cluster lift, 8 core hits in 2,714 releases.
- **Bullet heaven / survivors-like:** 0.56×.
- **Turn-based tactics:** 0.23×.

Each needs either an exceptional hook or a big IP. [A §Candidate directions], [A §Saturated tags]

## Data caveats

1. **Review counts:**
   - The success bar uses the search-row count, which is language-filtered. Totals from the review histogram and appdetails are a median 1.39× higher.
   - Games with ≥1k reviews overall but <1k English reviews were never enriched, so Asian-market hits are under-represented. [A §Data checks]
2. **Launch type:** "Prior reviews" means the first Steam review came more than 45 days before the listed release date. It catches Early Access graduates and re-releases, but can also catch games with public betas on the main app. [A §Data checks]
3. **SteamSpy:**
   - Owners and tags are empty for 568 of 744 games, so owners are not used anywhere.
   - Playtime is used but may be sampled or partial.
   - Tags come from the search row (top ~6 per game) instead.
4. **Release counts:** releases per month grow from about 1.6k (Dec 2025) to 5.2k (Nov 2026). This is either real growth or search under-listing older low-visibility titles. Per-month hit rates for Oct–Nov 2026 are also right-censored (less time to reach 1k reviews).
5. **Revenue:**
   - The 20–60× multiplier is ±50% per game [M:marketing/boxleiter-multiplier-about-30x-for-recent-games].
   - Net revenue uses list price, not average selling price, and ignores bundles and keys. Treat the figures as order-of-magnitude.
6. **Major-publisher flag:** keyword-based. Seven missed majors were re-flagged (Bungie, HoYoverse, NCSOFT…), but some publisher subsidiaries may still slip through.
7. **Hit rates are correlational:** price, weekday and tag effects mix quality and investment with the variable itself.
8. **Not measured:** wishlists, revenue, marketing spend and team size. "Solo developer" cannot be identified reliably; only self-publishing (46–59%) is measured.
