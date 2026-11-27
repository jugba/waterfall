# Game 003 — direction, concepts and Next Fest schedule

- Written: 2026-11-27 (cross-project study; game 002 remains the active project, so no `projects/003-*` folder yet)
- Purpose: choose a direction and concept for game 003. It is the game reserved for **Steam Next Fest Feb 2027**
  (Feb 22 – Mar 1), with a public demo and a launch after the Spring Sale (Mar 18–25). This file also sets a dated
  schedule from today to launch and flags what cannot be done.
- Inputs:
  - `projects/001-steam-market-research/reports/market-report.md` **[R]**;
  - `projects/001-steam-market-research/research/processed/games_analyzed.csv` **[G]**, `tag_opportunity.csv` **[T]**, `candidates.csv` **[C]**;
  - `playbooks/monthly-cycle.md`, `playbooks/steam-launch-checklist.md` **[SLC]**, `playbooks/marketing.md` **[MKT]**;
  - `projects/002-cozy-organizing-sim/BRIEF.md` and `concepts.md`;
  - memories, cited as **[M:path]**.
- Constraints:
  - Godot 4.7 GDScript, with Claude writing the code.
  - AI-assisted item art; capsule and logo made by a human.
  - Single-player preferred; priced $5–15; Deck and Mac friendly.
  - A strong short-form hook; ≤4 weeks of core development.
- Revenue method (same as 002):
  - units = all-language reviews × 30 (range 20–60); net = units × price × 0.5 [M:marketing/boxleiter-multiplier-about-30x-for-recent-games].
  - *Typical* means 100–500 reviews; *hit* means 1,000–3,000 reviews [M:market/small-scope-steam-hit-base-rate-under-1-percent].
  - A second, wishlist-based method is in §4. Every figure is an estimate (±50%).
- `partner.steamgames.com` could not be fetched from this session (blocked host). Next Fest facts come from web-search extracts of the official page. They are marked [official-extract] or [third-party].

---

## 0. Summary

| | |
|---|---|
| **Recommendation** | **Concept A, "Rockhound" (working title).** A 2D geode-cracking incremental: dig rocks, crack them open for a randomised crystal reveal, polish and sell, and upgrade toward automation. Score **26/30**, against 22 for Claw Machine and 21 for Deep Line. |
| **Why** | It combines the strongest under-supplied signals: Mining 4.9×, Physics + Incremental 9.1× and Relaxing + Incremental 5.7× [T]. It keeps the gambling-style reveal of Scritchy Scratchy and Bills Must Be Paid without gambling tags or content-rating risk. The niche is empty: [C] has no geode or rockhound title with ≥200 reviews. The hook is a known viral format (one geode-cracking TikTok reached ~7M views). It makes a natural 30–45 min capped demo. Its tags barely overlap Knolling Co.'s, so the two games cross-promote rather than compete. |
| **Schedule verdict** | **Feasible only if three things happen.** (1) Steamworks onboarding completes and both app fees are paid **by Wed Dec 16** (hard latest Mon Dec 28). (2) 003's concept, capsule and 5 screenshots are produced in **December, before its nominal Dec 28 start**. (3) The demo build is submitted by **Fri Jan 22**, which leaves about 3.5 working weeks of development, including New Year. The binding rule: the base game must be **visible as Coming Soon at registration**, on or before **Sun Jan 10** [official-extract]. With a 7-business-day page review and the Christmas and New Year holidays, the page must be submitted by Mon Dec 28 at the latest. Onboarding started ~Nov 26–27 and takes 15–30 days, so it ends Dec 11–27: roughly a coin flip against a Dec 16 target. If onboarding is not done by Dec 28, **the Feb fest is impossible for 003**; see the fallbacks in §5.2. |
| **Launch** | **Thu Apr 8, 2027.** It falls after Easter, avoids April 1 and comes 38 days after the fest. The build goes to review Tue Mar 9. The release cooldown ends May 8, so the game is eligible for the Summer Sale (Jun 24; release by May 25). |

---

## 1. Re-examining the directions and the unused signals

### 1.1 The report's directions 2–5, seen through Next Fest and game 002

| Direction [R] | What changed since the report | Next Fest demo fit | Overlap with 002 | Verdict |
|---|---|---|---|---|
| **2. Juicy incremental with a gambling or roguelite hook** | Incremental's share of releases grew 5.1% (Q1 2026) → 6.4% → 7.6% → 9.3% (Q4, 8 weeks) [C]. But 16% of Q3 incrementals reached 100 reviews, against 12.3% of all Q3 releases, so the tag still beats the average. The pure **Gambling** tag is cooling: the share reaching 100 reviews fell 28% (Q1) → 20% (Q2) → **8.5% (Q3)**, below the 12.3% base [C]. Gambling still has 3.2× core lift over the full window [T]. | **Best.** A sub-minute loop reaches "one more" fast. It caps naturally (first biome or first debt paid). It suits Steam's "try it now" fest browsing. | Low. It shares only "Relaxing" with 002, and the audience overlap (people who like "satisfying" videos) helps cross-promotion. | **Take it**, but make the reveal or "chance" hook the fantasy (loot, rarity), not casino gambling. |
| 3. Online co-op comedy | Unchanged: highest upside (median core hit about $771k) but 55–57% ≥80% scores [R]. Netcode is new for us, and fest demos need lobbies that work on day 1. | Good for streamers, bad for solo fest browsers. Matchmaking with no players is a known demo killer. | None | **No.** The brief prefers single-player, and multiplayer review risk on a demo is too high for this first fest. |
| 4. Detective / investigation | Investigation is still 4.5×. But Q4 2026 supply is 103 releases and the share reaching 100 reviews dropped to 8.7% (young games) [C]. Writing load is high and the text-heavy format is costly to localise [R]. | Good if it is one complete short case. A demo gives away a big share of non-replayable content. | Medium (desk object inspection) | **No for 003.** 3.5 weeks to a demo cannot carry case writing plus puzzle QA. Keep it for a later 10-week slot. |
| 5. Nostalgia shopkeeper | Most hits are first-person 3D with many props [R]. Pawn-shop entries score poorly: Pawnbroker Simulator 69%, Pawn Planet 70% [C]. | Medium (one shop day) | **High.** It would compete with Knolling Co. for the cozy job-sim audience the month after 002 launches. | **No.** |

### 1.2 Signals in [T] not yet considered (≥80 releases, core lift ≥2.5×)

| Tag | Releases | Core hits | Lift | Read |
|---|---|---|---|---|
| Surreal | 263 | 8 | 3.7× | A *tonal twist*, not a genre: Berry Bury Berry, Playrooms, Endacopia, Lucid Blocks [G]. Usable as flavour (a faint weird mystery inside the rocks), not as the core. |
| Artificial Intelligence | 198 | 6 | 3.7× | Player-applied tag on Moon Sweepers, Librarian and others, of unclear meaning [002 concepts §1.2.8]. Not a design signal. |
| Level Editor | 150 | 4 | 3.3× | Happy Wheels and Glimmith. Too few hits; not worth the scope. |
| **Gambling** | 228 | 6 | 3.2× | Scritchy Scratchy, Bills Must Be Paid, Booster Pack Heroes, This Ain't Even Poker [G]. **Cooling** (see 1.1). Payment-platform and age-rating care is needed [R]. Take the *reveal* mechanic, not the casino skin. |
| Crafting | 593 | 14 | 2.9× | Polishing and cutting a gem is a light craft step; usable as a second verb [M:design/second-verb-needed-as-organizing-supply-explodes]. |
| **Fishing** | 171 | 4 | 2.9× | How to Fish (co-op) dominates. The single-player 2D case is **Scale the Depths** ($9.99, 2,472 reviews, 93%, 3.2 h, about $370k est.) [G]. Supply is growing: 25 → 29 → 45 → 67 per quarter [C]. → Concept C. |
| Driving | 352 | 8 | 2.8× | Mostly 3D vehicle sims. Off our pipeline. |
| **Mining** | 250 | 10 | 4.9× | Already in the report, but under-used: incremental-mining hits cluster at $4.99–9.99 and ≤1 GB. Examples: Sludgineers (2,234 reviews, 90%), You Know The Drill (1,173, 92%), Big Dig (1,009, 96%), Dwarf Eats Mountain (1,376, 82%), Space Rock Breaker (5,073, 96%) [G]. Q3 2026 Mining releases reached 100 reviews at 21% vs 12% overall [C]. → Concept A. |

Theme check in [C] (title search over 30,708 releases):
- "geode" matches 1 game (GEODE, free, 34 reviews).
- "crystal" matches 33; the best rock-breaking one is Crystal Breaker Inc ($3.49, 109 reviews, 79%).
- "claw" matches 25; Dungeon Clawler, a claw-machine roguelike deckbuilder, has $14.99, 3,956 reviews, 92% [G].
- "coin" matches 57: RACCOIN (5,043, 86%) and The Coin Game ($19.99, 5,719, 92%).
- So the geode or rockhound space is empty, while claw machines and coin pushers are taken by proven games.

### 1.3 What makes a strong Next Fest demo (from our playbooks and memories, plus 2026 sources)

1. **Wishlists before the fest decide the fest.** Pre-fest wishlists predict fest wishlists (Spearman 0.825). The median fest gain is 806 (p30 382, p70 1,839) [MKT §2.3]. So the **Coming Soon page must be live as early as possible** and fed by short-form clips. Our own Next Fest planning target is 2,000+ pre-fest wishlists (third-party advice, [search summary](https://howtomarketagame.com/2025/03/26/archive-january-2026-benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/)).
2. **Most wishlisters never play the demo.** Zukowski 2026: "nobody plays demos and that is OK" [MKT §4.4]. The capsule, tags and the first 10 seconds of the trailer do most of the work [M:marketing/capsule-art-first-in-marketing-budget]. The demo must exist, look polished and not bounce people.
3. **Session length of 20–60 min, with a clear end and a wishlist call to action.** Bounces under 10 min reportedly hurt ranking from day 3 ([presskit.gg](https://presskit.gg/field-guides/steam-next-fest-guide), [Steamworks tips](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/tips); secondary, unverified). A short incremental must **cap** the demo, or the demo becomes the game and invites refunds of the full game later [M:marketing/steam-refund-two-hours-short-games].
4. **Release the demo before the fest.** It catches bugs, and the one-time wishlister "demo available" notice (July 2026) can be sent within 2 weeks of the demo going public [SLC §F]. Valve itself advises having the demo approved about 6 weeks before the fest. That is impossible for us (§5).
5. **Fest-sourced wishlists convert worse** [M:marketing/wishlist-conversion-0-1-to-0-15x-first-week]. Budget at 0.10× week-1 conversion.
6. **Once per game** [M:marketing/next-fest-once-per-game-plan-which-game]. If the build is shaky, withdraw before the Press Preview (about Feb 11, [third-party]) and take the June fest instead (§5.2).

### 1.4 Differentiation from Knolling Co. (002) and cross-promotion

- **Avoid:** Organizing, Job Simulator or Cozy as top tags, and any "tidy or sort objects on a desk" verb. Those would compete with 002 for the same Personal Calendar tag audience in the same 6 weeks [M:marketing/popular-upcoming-unreachable-after-june-2026].
- **Use:** the shared "oddly satisfying" short-form audience, which is a different genre with the same feed. Both games link to one Developer Homepage before going live [M:marketing/developer-homepage-followers-compound-across-releases].
- **Concrete cross-promotion:**
  - 002's launch event (Feb 11) and credits screen show "Our next game: wishlist Rockhound".
  - 003's demo end screen shows "Wishlist + follow the studio + Knolling Co. out now".
  - A homepage post when the demo goes live.
  - A two-game franchise bundle when 003 launches.
  - 002 is ~11 days old during the fest, so 003's fest traffic lands while 002 is still in its launch-discount window.

---

## 2. Three concepts

All three are 2D, single-player, mouse plus full controller, native 1280×800 (Deck), ≤1 GB, with Windows, Linux and Mac exports from Godot. All are built on `_template` (save, settings, pause, Steam service).

### Concept A — "Rockhound" (working title) — **recommended**

- **Pitch:** a short, tactile incremental about cracking open rocks. Dig stones out of a quarry wall, split them with a hammer and see what is inside: dull agate, or a fist-sized amethyst cathedral. Polish the best pieces, sell the rest and upgrade until the quarry runs itself.
- **5-second hook:** a plain grey rock sits on the bench; a hammer strike; the rock splits along a physics crack with a crisp "pop"; violet crystals glow; a rarity banner flashes "★★★★ RARE — $1,240". No text is needed and it reads muted. This mirrors the real geode-cracking clip format: one creator's most popular video has ~7M views ([Bladi 2022](https://en.bladi.net/viral-tiktok-star-cracks-open-ancient-moroccan-geodes-revealing-hidden-crystal,95425.html)), and the "pop" is valued as ASMR ([Rock & Gem](https://www.magzter.com/stories/hobbies-craft/RockGem-Magazine/CLEANING-CRACKING-GODES-GREAT-AND-SMALL)).
- **Core loop (20–60 s per rock, about 10 min per "haul"):**
  1. **Dig:** the side-view quarry wall breaks into rigid-body chunks with pickaxe clicks. Mining-tag fantasy.
  2. **Crack:** aim and strike. Strike placement and force matter a little (skill), and what is inside is rolled from a rarity table (the reveal). This is the Scritchy Scratchy dopamine without a gambling tag.
  3. **Polish or cut:** a one-gesture rub or a one-line saw cut raises value. This is the second verb (craft).
  4. **Sell or display:** sell for cash, or put the piece in the collection cabinet (a "Unknown" → identified catalogue of ~60 minerals with a few variants each).
  5. **Upgrade:** cash buys better picks, auto-hammers, a rock tumbler (idle polishing), a conveyor, a sorting sieve, lucky lamps and new quarries.
  6. **Pressure (optional roguelite layer):** each quarry lease has a rent quota per week, as in Bills Must Be Paid's "bills". Missing it ends the lease and keeps meta-upgrades. Included only if playtests show the pure incremental sags.
- **Progression:** 4 quarries (riverbank → desert → volcanic → a strange "hollow" mine with a faint surreal mystery). Automation unlocks make the screen fill with cracking rocks, so the clip gets better as the player progresses. Physics + Incremental lifts 9.1× [T].
- **Content:** about 3–4 h to credits plus completing the catalogue. An endless "deep vein" mode is the replay option. Price **$7.99** [M:market/small-scope-price-7-to-15-dollars-never-under-5].
- **Demo scope (30–45 min):**
  - Quarry 1 complete with 15 minerals and the first automation (auto-hammer).
  - The demo ends when the first lease is paid off. A teaser then cracks a locked "hollow" geode and cuts to the wishlist screen.
  - Upgrades are capped; no save carry-over (decide later whether to carry it).
  - Built from the vertical slice, so the demo is not extra scope.
- **Full-game scope (4 weeks core plus fest-feedback polish):**
  - W1 (Dec 28 – Jan 8): rock physics, crack shader and fracture, rarity table, sell, 5 upgrades. This is the clip machine.
  - W2 (Jan 11 – 22): quarry 1 content, polish verb, catalogue, demo flow, controller, Steam achievements stub. **Demo submitted Jan 22.**
  - W3–W4 (Jan 25 – Feb 19, shared with 002 launch week): quarries 2–3, automation chain, tumbler idle, string table.
  - W5–W6 (Mar 1 – 9): quarry 4, endless mode, fest feedback. **Build submitted Mar 9.**
- **Cut list (in order):** roguelite rent layer → quarry 4 and the mystery → endless mode → saw cut (keep polish) → minerals 60→40 → conveyor visual (keep the auto-hammer). **Never cut:** the crack-and-reveal feel, sound and the first automation.
- **Art:** procedurally shaded rocks (one base mesh or sprite family plus noise and fracture shaders); crystals as layered sprites with emission and palette swaps (AI-assisted, then hand-cleaned); 4 quarry backgrounds; no characters. **Low-to-medium load**, and the shader work suits Claude-written code.
- **Risks:**
  1. The "reveal" can feel like a slot machine. Mitigate with skill in the strike, a pity timer, and visible odds in the catalogue.
  2. Incremental supply is rising (9.3% of Q4 releases), so the polish of the crack moment has to carry the game.
  3. Crystal Breaker Inc. scored 79% with 109 reviews (cheap, thin), which shows the theme alone does not sell.
  4. Godot 2D fracture (convex decomposition at runtime) is new to us. Spike it on day 1, with a pre-fractured fallback.
  5. Title clash: check "Rockhound" on Steam and for trademarks before the store page.
- **Comparables [G]:**
  - Scritchy Scratchy ($6.99, 20,930 reviews, 94%, about $2.2M est.);
  - Bills Must Be Paid ($6.99, 15,125, 96%, $1.6M);
  - Space Rock Breaker ($2.99, 5,073, 96%, $228k);
  - Sludgineers ($6.99, 2,234, 90%, $234k);
  - Big Dig ($7.99, 1,009, 96%, $121k);
  - You Know The Drill ($4.99, 1,173, 92%, $88k).
  - Revenue at **$7.99**: typical **$12k–60k**, hit **$120k–360k**. Cluster p25–p75 of core hits is $143k–440k [R direction 2].
- **Top 5 tags:** Incremental, Mining, Relaxing, Physics, Collectathon (then Casual, Idler, Crafting, 2D, Singleplayer).

### Concept B — "Claw Machine" / "Prize Pit" (working title)

- **Pitch:** you own one battered claw machine in a seaside arcade. Play it yourself to win prizes, sell or display them, and upgrade your way to magnet claws, triple claws and a wall of machines that play themselves.
- **5-second hook:** the claw drops into a pile of 200 physics plushies and lifts *eleven* at once, which rain into the chute with a jackpot siren. A familiar frustration is inverted.
- **Loop:** drop and grab (a light physics skill) → prizes into the chute → sell or put on the prize shelf → upgrades (grip, size, multi-claw, prize tiers, auto-play) → weekly rent quota (roguelite). About 2 min per credit and 10–15 min per week.
- **Demo:** one machine, 3 prize tiers, and the first auto-claw; it ends at week 3's rent (30–40 min).
- **Full game:** 5 machine types (classic, pusher hybrid, key-master, capsule, giant), about 80 prizes, endless arcade.
- **Cut list:** machine types 5→3 → prize shelf decorating → endless mode → prizes 80→50.
- **Art:** lots of plush and toy prize sprites (AI-friendly), machine cabinets, arcade backgrounds. Medium load.
- **Risks:**
  1. Physics grab feel needs long tuning (soft piles, jitter, Deck performance with 200 rigid bodies).
  2. It reads as Gambling. That tag is cooling (8.5% of Q3 releases reached 100 reviews), and prize-machine age-rating questions apply.
  3. Dungeon Clawler ($14.99, 3,956 reviews, 92%) owns "claw machine" on Steam searches, and The Coin Game owns arcade physics.
- **Comparables [G]:**
  - Dungeon Clawler ($593k–1.8M est., 20–60×);
  - RACCOIN ($11.99, 5,043, 86%, $907k at 30×);
  - Fortune Mill ($7.99, 4,490, 83%, $538k);
  - Scritchy Scratchy ($2.2M).
  - At **$7.99**: typical $12k–60k, hit $120k–360k.
- **Top 5 tags:** Incremental, Physics, Arcade, Gambling, Roguelite. Arcade is a saturated tag at 0.39× [T], which hurts.

### Concept C — "Deep Line" (working title)

- **Pitch:** a 2D side-view fishing incremental. Drop a line as deep as it will go, hook everything on the way back up, sell the catch, and upgrade line, lures and sonar to reach the trench and the thing that lives there.
- **5-second hook:** the hook plunges through 5 depth bands with the camera following, then rockets back up dragging a chain of 30 fish that pop into coins at the surface.
- **Loop:** cast (depth limited by line) → descend while dodging (light skill) → reel up, hooking fish in the path → sell and fill the bestiary → upgrade. About 1–2 min per cast.
- **Demo:** depths 1–2 and 20 fish; it ends at the first "trench gate" (30 min).
- **Full game:** 5 zones, about 70 fish, a boss catch, endless mode.
- **Cut list:** boss → zone 5 → fish 70→45 → bestiary flavour text.
- **Art:** about 70 fish sprites with swim animation (the heaviest of the three), parallax water and lighting.
- **Risks:**
  1. The format is proven: it is close to the 2011 mobile hit *Ridiculous Fishing*, and Steam already has Cat Goes Fishing and Scale the Depths, so differentiation is thin.
  2. Fishing supply is rising (67 releases in Q4, with only 7.5% reaching 100 reviews so far).
  3. Animated fish are the most art per item.
- **Comparables [G]:**
  - Scale the Depths ($9.99, 2,472 reviews, 93%, $370k);
  - Space Rock Breaker ($228k);
  - Big Dig ($121k);
  - How to Fish is the co-op outlier and is not comparable.
  - At **$9.99**: typical $15k–75k, hit $150k–450k.
- **Top 5 tags:** Incremental, Fishing, Relaxing, Casual, Pixel Graphics (or 2D).

---

## 3. Scores

Each criterion is scored 1–5, with 5 the best. For scope risk and art risk, 5 means the *lowest* risk. Unweighted total out of 30. The new criterion versus 002 is **Next Fest demo fit**: fun in under 1 minute, a natural 30–45 min cap, and polish reachable by Jan 22.

| Concept | Market evidence | Hook (muted clip) | Next Fest demo fit | Scope risk | Art risk | Differentiation (market + vs 002) | **Total** |
|---|---|---|---|---|---|---|---|
| **A — Rockhound** | 4 (Mining 4.9×, Physics + Incremental 9.1×; geode theme itself untested) | 5 (real viral format, single "pop" moment) | 5 (instant loop, cap at first lease) | 4 (one physics system; fracture spike) | 4 (shader-driven rocks and crystals) | 4 (empty niche; low overlap with 002) | **26** |
| B — Claw Machine | 4 (Gambling 3.2× but cooling; Dungeon Clawler proves the fantasy) | 5 | 4 (instant, but physics frustration risk in a demo) | 3 (pile physics tuning, Deck performance) | 4 | 2 (claw is taken; Arcade tag 0.39×) | **22** |
| C — Deep Line | 3 (Fishing 2.9×, only 4 core hits; single-player 2D proof is one game) | 4 | 4 | 4 | 3 (≈70 animated fish) | 3 (familiar format; no 002 overlap) | **21** |

**Recommendation: A, "Rockhound".**
- It has the strongest combined tag evidence that is not Organizing.
- It has the clearest 5-second clip, and it avoids both the cooling Gambling tag and Knolling Co.'s audience.
- Its demo is simply the first quarry.
- **Kill or reshape test:** by Fri Jan 8, post 3–5 crack clips. If all stay under ~2k views and the 5-minute playtest does not produce "one more rock", reshape toward B. B reuses the physics, rarity and upgrade code.

---

## 4. Revenue cross-check from wishlists (A at $7.99)

| Step | Low | High | Source |
|---|---|---|---|
| Pre-fest wishlists (page live ~Jan 8, 6 weeks, clips plus 002 cross-promotion) | 500 | 2,500 | assumption; target 2,000+ ([third-party](https://howtomarketagame.com/2025/03/26/archive-january-2026-benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/)) |
| Gained in the fest | 382 (p30) | 1,839 (p70) | [MKT §2.3] |
| Gained fest-end → launch (5.5 weeks) | 300 | 1,500 | assumption |
| **Launch wishlists** | **≈1.2k** | **≈5.8k** | |
| Week-1 units (0.10–0.15×) | 120 | 870 | [M:marketing/wishlist-conversion-0-1-to-0-15x-first-week] |
| Year-1 units (≈0.7×, plus organic, not modelled) | 840 | 4,060 | same |
| Year-1 net at $7.99 × 0.5 | ≈$3.4k | ≈$16k | |

The wishlist floor sits **below** the review-based "typical" band ($12k–60k). Organic discovery (Personal Calendar, the tags, New & Trending) has to do the rest, as for any small game. A hit (≥1k reviews) needs a clip that breaks out, not the fest alone.

---

## 5. Dated schedule (today Fri 2026-11-27 → launch Thu 2027-04-08)

Business days (bd) exclude weekends and US holidays: **Fri Dec 25, Fri Jan 1, Mon Jan 18 (MLK), Mon Feb 15 (Presidents' Day)**. Assume Valve runs at reduced capacity Dec 24 – Jan 1 (assumption).

Official or extracted rules used:
- The base game must be **visible as Coming Soon at the time of registration**. Registration closes **Sun Jan 10, 11:59pm PST** [official-extract, [Steamworks Feb 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027)].
- All required items must be **submitted for review by Mon Feb 8** [official-extract].
- The Press Preview reportedly starts **Thu Feb 11** [third-party].
- A demo needs its own store-presence review even without a separate page [official-extract].
- Store page review takes ≥7 bd; build review up to 12 bd [M:process/steam-review-lead-time-three-weeks].
- 30-day wait from fee payment to release [M:process/steam-direct-fee-pay-two-games-ahead].
- 30-day discount block after release [M:marketing/steam-release-blocks-discounts-30-days].

| Date | Game 003 development | Steam / marketing gate | Slack / note |
|---|---|---|---|
| **Fri Nov 27 – Tue Dec 1** | User picks concept A, B or C | **Concept and working title locked; commission the human capsule and logo now** (2–3 weeks of artist time); title and trademark check | Capsule is needed by about Dec 18 |
| Nov 27 → **Dec 11–27** | — | **Steamworks onboarding** (started ~Nov 26–27; 15–30 days, plus TIN validation up to 30 days) [SLC] | **Single point of failure for both 002 and 003** |
| Mon Dec 7 – Wed Dec 16 | **Pre-production spike, ~4 days of Claude time inside 002's production weeks:** crack shader, 1 quarry mock, 10 crystal sprites → **5 store-quality screenshots** and 2–3 clips | Store page draft: description, tags, content survey (AI disclosure [M:tech/steam-ai-disclosure-player-facing-only]); **Developer Homepage created and linked** | This work is *before* the nominal Dec 28 start. Unavoidable, because a Coming Soon page needs screenshots |
| **Target Wed Dec 16** (hard latest **Mon Dec 28**) | — | Onboarding done → **pay both $100 fees (002 and 003) the same day** → create the app → **submit 003's store page for review** | 7 bd from Dec 16 = Mon Dec 28; from Dec 28 = Thu Jan 7 |
| Fri Dec 18 | — | 002's store page submitted (002 BRIEF) | Same onboarding gate |
| **Mon Dec 28** | **003 development starts** (W1: physics, fracture, rarity, upgrades) | Last safe day to submit 003's store page | After this date the Feb fest is **impossible** (§5.2) |
| **Mon Dec 28 – Fri Jan 8** | W1 | **003 Coming Soon page public** as soon as approved (target ~Dec 29–Jan 7); clips 3–5 per week begin | 002 Coming Soon also goes live Thu Jan 7 |
| **By Fri Jan 8 (deadline Sun Jan 10, 11:59pm PST)** | Hook test: crack clips posted | **Register for Next Fest from the base game** (green check on the App Landing Page) | Register on Friday; Valve support is closed at the weekend |
| Mon Jan 11 – Fri Jan 22 | W2: demo flow, quarry 1, controller and Deck pass, wishlist end screen | **Fri Jan 15: create the Demo app and submit its store presence** (7 bd → Wed Jan 27) | |
| **Fri Jan 22** | **Demo build submitted for review** (launched via Steam ≥5 min first) | 12 bd worst case → **Tue Feb 9** approval; typical 3–5 bd → ~Jan 27–29 | 1 bd before the Feb 8 deadline at worst case; Valve's "approved 6 weeks prior" advice is impossible |
| Mon Jan 25 – Fri Feb 19 | W3–W4: quarries 2–3, automation, tumbler, strings | Demo public as soon as approved (target ~Feb 1); **send the one-time demo notice to wishlisters**; homepage post | A failed first review that re-enters on ~Feb 1 still makes the Feb 8 submission deadline. A second fail risks the Press Preview |
| **Mon Feb 8** | — | Valve deadline: all fest items submitted (demo, assets, any trailer) | |
| Thu Feb 11 | (002 launches) | 002 launch event advertises 003 Coming Soon; **Press Preview reportedly starts** [third-party] | Withdraw before this if the demo is not ready |
| **Mon Feb 22 – Mon Mar 1** | Hotfix the demo daily; collect feedback | **Next Fest**: livestream slot, homepage post, clips daily | 002 is in week 2 of its launch |
| Tue Mar 2 – Mon Mar 8 | W5–W6: quarry 4, endless mode, fest feedback fixes | Trailer v1 (required for release); launch discount configured (10–15%, 7 days; ≤40%, 7–14 days allowed) | |
| **Tue Mar 9** | **Release build submitted for review** | 12 bd → **Thu Mar 25** worst case | 2 weeks of buffer for one re-review before Apr 8 |
| Thu Mar 18 – Thu Mar 25 | Polish, Deck review request | Spring Sale: 003 is unreleased, so it cannot be discounted (rule); **002 is eligible** (released 35 days earlier); put 003's "wishlist" link on 002's sale event | Do **not** launch inside the sale |
| **Thu Apr 8** | **Launch** (Thursday [M:market/release-tuesday-to-thursday-not-weekends]) | Wishlist and homepage-follower emails; franchise bundle (002 + 003) | Fee paid ~Dec 16, >30 days ago ✔ |
| Thu Apr 8 – Sat May 8 | Patches | 30-day discount block → ends **May 8** | |
| By Tue May 25 | — | Summer Sale (Jun 24 – Jul 8) eligibility cutoff: 003 is eligible ✔ | |

Launch-date alternatives:
- **Tue Apr 6** (also fine).
- **Thu Apr 1** works on the calendar, but April Fools' Day buries announcements.
- **Tue Mar 30** falls in Easter week, only 5 days after the sale; review buffer would be 3 bd.
- Anything later than **Tue May 25** misses the Summer Sale.

### 5.1 Impossibilities and hard risks (plain)

1. **If onboarding is not done by Mon Dec 28, Feb Next Fest is impossible for 003.**
   - Registration needs a public Coming Soon page.
   - The page needs a paid app plus a 7-bd review, and the holidays remove Dec 25 and Jan 1.
   - Even a Dec 28 submission only works if Valve hits 7 bd (→ Jan 7) despite holiday staffing.
   - **Realistic target: onboarding and both fees by Wed Dec 16.**
2. **003 cannot "start" on Dec 28 and still have a store page.** About 4 days of art and prototype work (screenshots, capsule brief, clips) must happen Dec 7–16, overlapping 002's content production. This is a capacity decision for the user.
3. **The demo has about 3.5 working weeks** (Dec 28 – Jan 22, including New Year) to be fest-quality.
   - At worst-case 12-bd review it lands Feb 9, the day after the Feb 8 deadline. A slip of one day breaks the target.
   - Valve's ideal of the demo approved 6 weeks before the fest (mid-January) cannot be met.
   - Mitigation: submit the Demo store presence Jan 15, and the demo build on Jan 22 even if rough. Later demo builds can be updated; whether updates need re-review is **unverified**.
4. **Pre-fest wishlists will be thin.** The page is live only ~6 weeks, which pushes the fest result toward its median (~800) or below.
5. **The cadence gap.** 002 ships Feb 11 and 003 Apr 8, so **no game ships in March**. Game 004 (start ~Jan 25) would ship ~early May and cannot use a fest.
6. **Unverified items to check once logged in to Steamworks:**
   - whether the Coming Soon page needs a trailer (assumed no; trailer required for release only);
   - the exact Press Preview date and any demo build deadline (third parties say Jan 18 or Jan 25);
   - whether demo updates need re-review;
   - whether the 30-day fee wait applies to a new partner's second app.

### 5.2 Fallbacks if onboarding slips past Dec 28

| Option | What it means | Cost |
|---|---|---|
| **F1 — June Next Fest** (Jun 14–21; registration deadline not yet published, expect ~early May) | Keep concept A; launch ~**Thu Jul 15** (after the Summer Sale Jun 24 – Jul 8). Page goes live in January anyway, giving 5 months of wishlists | Long gap; game 004 or 005 would have to ship Apr–Jun without a fest |
| F2 — Launch without a fest ~Thu Apr 8 | Demo optional (≤2 days rule [MKT §4.4]) | Loses fest visibility (~800 median wishlists) |
| F3 — Swap: give the Feb fest to nobody | 003 becomes a normal monthly game (~Mar 11) | Pays nothing for the reservation |

Recommendation if it slips: **F1.** Steam holds the fest slot per game, and Rockhound's page benefits from a longer wishlist window.

---

## 6. Decisions needed from the user

1. Concept: **A Rockhound** (recommended), B Claw Machine, or C Deep Line.
2. Approve ~4 days of 003 pre-production on Dec 7–16, inside 002's production weeks. Without it there are no screenshots and no Coming Soon page by Jan 10.
3. Onboarding status: confirm the start date. Commit to paying **both** app fees the day onboarding completes (target Dec 16).
4. Capsule artist: commission by ~Dec 1, for delivery by ~Dec 18.
5. Fallback if onboarding is not done by Dec 28: **F1 June fest** (recommended), F2 or F3.
6. Accept that no game ships in March (002 Feb 11 → 003 Apr 8), or plan a non-fest game for March.
