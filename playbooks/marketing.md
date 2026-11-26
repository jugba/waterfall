# Marketing playbook: one small Steam game per month (draft v0, research-based)

Status: written from desk research on 2026-11-26. It has not yet been tested on one of our
projects. Revise after the first postmortem (see `playbooks/README.md`: a playbook
names the projects it was learned from; none yet).

**How the sources were checked.** Every figure cites a URL and the source's date. The research
session could only use web search. Direct page fetches were blocked by the sandbox's network
policy for howtomarketagame.com, gamedeveloper.com, newsletter.gamediscover.co and
steampageanalyzer.com. Figures were therefore read from search-result summaries and
secondary coverage, not from the primary page. Labels used below:
- **unverified**: the number appears only in a vendor/SEO blog or a single anecdote, or we could not trace it to a primary dataset.
- **(acc. 2026-11-26)**: the date we read a living document, such as Steamworks docs.

Before any decision costs real money, re-check the key benchmarks against the primary page.

---

## 0. The five facts that shape everything

1. **Wishlists are still the best predictor of sales, but each one is worth less than it used to be.**
   - Median first-week sales are about **0.15x** of launch wishlists for games with more than 25k wishlists, and about **0.10x** for games priced above $10 ([GameDiscoverCo, 2025-10-17](https://newsletter.gamediscover.co/p/the-state-of-steam-wishlist-conversions); [summary](https://gamedevreports.substack.com/p/gamediscoverco-the-state-of-steam)).
   - First-month sales per wishlist roughly halved, from 0.45 for 2020–22 releases to 0.22 for 2023–25 releases. The correlation stayed at about 0.72–0.77 ([Zukowski via Inven Global / Automaton, ~2026-10](https://www.invenglobal.com/articles/27273/steam-wishlist-inflation-value-of-1-wishlist-cut-in-half-but-predictive-power-remains-unchanged); [Automaton JP 2026-10-17](https://automaton-media.com/articles/newsjp/20261017-474077/)).
2. **The front-page "Popular Upcoming" list is out of reach for us.**
   - Since Valve's store refresh on **2026-06-04**, the de-facto threshold reportedly rose from about 7k wishlists to **about 80k**, with some reports saying about 100k ([GamesRadar, 2026](https://www.gamesradar.com/games/valve-made-it-roughly-15-times-harder-for-indie-games-to-reach-a-coveted-steam-ranking-but-one-expert-says-an-understated-new-steam-feature-is-doing-gods-work/); [PC Guide, 2026](https://www.pcguide.com/news/steams-new-100000-wishlist-rule-means-many-indie-devs-will-have-to-rely-on-a-different-feature-to-be-discovered/); [Creative Bloq, 2026-06](https://www.creativebloq.com/3d/video-game-design/is-steams-more-modern-redesign-good-or-bad-for-indie-game-developers)). All of these are developer-inferred, not published by Valve.
   - The new **Personal Calendar** is personalised by tags and reportedly favours smaller games. One developer claims it brings 300–3,000 wishlists/day, which is **unverified** ([games.gg, 2026](https://games.gg/news/steam-popular-upcoming-indie-personal-calendar/)).
   - The consequence: **tags and capsule clarity now matter more than raw wishlist count** for pre-launch visibility.
3. **New & Trending depends on revenue, not wishlists.** Valve says placement depends on passing a secret threshold of dollars earned, and the threshold varies by country and language ([Steamworks Visibility docs, acc. 2026-11-26](https://partner.steamgames.com/doc/marketing/visibility); [Zukowski 2024-01-29](https://howtomarketagame.com/2024/01/29/do-wishlists-matter-any-more/)). Publishers aim for 30k+ wishlists to clear it reliably. That figure is an industry heuristic, not a Valve number.
4. **The market is brutal at the median.**
   - About 20.3k games released on Steam in 2025 ([Zukowski 2026-01-08](https://howtomarketagame.com/2026/01/08/how-many-games-were-released-in-2025/); [GamesRadar](https://www.gamesradar.com/games/a-terrifying-20-282-games-were-released-on-steam-in-2025-and-just-608-managed-to-get-1-000-reviews-expert-finds-we-might-be-in-a-bit-of-an-indie-golden-age)).
   - Only 608 of them reached 1,000 reviews.
   - Gamalytic estimates median 2025 revenue at **$249**, and 65.9% of releases earned under $1k ([80.lv, early 2026](https://80.lv/articles/analysts-report-drop-in-game-revenue-on-steam-despite-growing-number-of-releases)).
5. **Small, fast games can break out, and short-form video is what moves them.**
   - *A Game About Digging A Hole* took about 2–3 weeks to make and was priced at €4.99.
   - It had more than 100k wishlists before its 2025-02-07 launch, sold 250k copies in week 1 and passed 1M by 2025-08-01.
   - It was driven by TikTok (5M views), Shorts (2.2M) and Reels (14.5M) ([PC Gamer, 2025-02](https://www.pcgamer.com/games/survival-crafting/designed-in-just-a-few-weeks-this-usd5-indie-game-about-digging-a-hole-has-journeyed-to-the-centre-of-steams-top-sellers-chart); [WN Hub, 2025-02](https://wnhub.io/news/finance/item-47099); [Automaton, 2025-08-04](https://automaton-media.com/articles/newsjp/a-game-about-digging-a-hole-20250804-352074/)).
   - This is an outlier, not a plan. It does show the shape of the opportunity: an instantly legible hook, a low price and viral clips.

**Strategic consequence for the factory.** We will not reach big-wishlist thresholds in 4–6 weeks of Coming Soon time. Our edge has to come from:
- (a) a hook that reads in one second, both in the capsule and in a 10-second clip;
- (b) many cheap shots at virality through short-form video;
- (c) a **compounding owned audience** (developer homepage followers, cross-promotion, bundles) that every release grows and every later release draws on.

---

## 1. Per-game timeline (about 8 weeks per game from concept lock to launch, overlapping so one game ships every 4–6 weeks; L = launch day)

Hard Steam constraints:
- The Coming Soon page must be public for **≥2 weeks** before release ([Steamworks: Coming Soon, acc. 2026-11-26](https://partner.steamgames.com/doc/store/coming_soon)).
- Submit the store page for review **≥7 business days** before it should go live ([Steamworks: Releasing, acc. 2026-11-26](https://partner.steamgames.com/doc/store/releasing)).
- A launch discount must be set up before release and runs 7–14 days. After it, there is a **30-day discount cooldown**. Seasonal sales are exempt from that cooldown, but not from the 30-day release cooldown ([Steamworks: Discounts, acc. 2026-11-26](https://partner.steamgames.com/doc/marketing/discounts)).
- The $100 app fee is recouped after $1,000 adjusted gross revenue ([Steamworks: App fee, acc. 2026-11-26](https://partner.steamgames.com/doc/gettingstarted/appfee); [PC Gamer, 2017](https://www.pcgamer.com/steam-direct-is-now-live-developers-can-pay-a-100-fee-to-submit-games)).
- Pre-release **build** review currently takes up to 12 business days, so submit the build at least 4 weeks before launch (see `memories/process/steam-review-lead-time-three-weeks`).
- Pay the app fee at least 30 days ahead (see `memories/process/steam-direct-fee-pay-two-games-ahead`).
- Players can refund any game with under 2 h played within 14 days of purchase (see `memories/marketing/steam-refund-two-hours-short-games`).
- Related memories: `marketing/coming-soon-page-live-five-weeks-before-launch` and `marketing/steam-release-blocks-discounts-30-days`.

So for our cadence, **game N's store page goes live while game N is still in development**, and game N's launch marketing overlaps with game N+1's hook test and prototype. With one launch per month, at any moment about two games are in the pipeline: one in Coming Soon and one in hook test or prototype.

| When | Game N task | Owner notes |
|---|---|---|
| **L−8w** (concept locked) | **Hook test.** Make 3 one-line pitches and 3 rough capsule thumbnails. Pick tags from 5–10 comparable successful games. Post one 10–15 s gameplay clip per pitch variant to TikTok, Shorts and Reels, and pick the hook whose clip gets the best views and retention. Draft the short description. | Cheapest validation we have. Kill or reshape the concept if every variant flops. |
| **L−8w** | Create the store page (the app fee should already have been paid at least 30 days earlier). **Link the app to our Creator Homepage before the page goes live** ([Steamworks: Creator Homepage](https://partner.steamgames.com/doc/store/creator_homepage)). | Followers of the homepage get an email when the game releases (same source). |
| **L−8w → L−7w** | Commission or finish the **final capsule**. It is the top-priority asset (see §3). Prepare 5+ gameplay screenshots, with the genre shown in the first 3. **Submit the store page for review by L−7w** (allow 7 business days). | Budget goes to the capsule before the trailer ([Zukowski, howtomarketagame 2022-03-08](https://howtomarketagame.com/2022/03/08/what-should-you-spend-money-on-if-you-have-a-small-marketing-budget/)). |
| **L−5w** | **Store page live (Coming Soon).** Announce it to our existing audience: a homepage post, Steam events on earlier games' pages, the mailing list and Discord. Add the new game to the "More from this developer" placement and to franchise/bundle plans. | Must happen by L−2w at the latest (hard rule). Aim for L−5w so the page builds wishlist velocity. |
| **L−5w → L** | **Short-form cadence: 3–5 clips per week** on TikTok, Shorts and Reels, re-cut from development footage. Make **1–2 Reddit posts** in genre-specific subreddits, following the 1-in-10 self-promo norms. Collect creator contacts (see §4). | Shorts keep resurfacing for longer than TikToks ([bugnet.io, n.d.](https://bugnet.io/blog/youtube-shorts-for-indie-game-marketing); **unverified**). |
| **L−4w** | **Submit the launch build for Steam review** (up to 12 business days). | Build must have recent playtime launched through Steam. |
| **L−3w** | Trailer v1: 30–60 s, gameplay from second one (see §3). Optional free demo if the game benefits from being tried (see §4, Demos). Register for any **themed Steam fest** that falls in the launch window. | |
| **L−2w** | **Creator outreach wave 1.** Send keys to 30–100 matched small and mid-sized creators. Use Keymailer, Woovit or Lurkit to filter, plus direct emails to creators who have played comparable games. Set embargo = launch day. Set the launch discount (10–15%). Upload the press kit. | Verify every key request against the creator's real channel contact ([gamedeveloper.com, n.d.](https://www.gamedeveloper.com/game-platforms/avoiding-ineffective-or-scam-discovery-interactions-with-influencers)). |
| **L−1w** | Build approved; day-one patch ready. Schedule launch posts. Prepare the Steam "Release" event. Plan a cross-promotion: launch-week discount on the previous titles plus a refreshed franchise bundle. | |
| **L (launch)** | Release in the morning, US time (convention, **unverified**). Post a Steam event, a homepage post and socials. Reply to every review in week 1. Hotfix within 48 h if needed. | Week-1 review score strongly predicts over- or under-performance. Over-performers averaged 91% positive, under-performers 67% ([GameDiscoverCo via Automaton, 2025-10-18](https://automaton-media.com/en/news/steam-wishlist-to-sales-study-shows-how-genre-release-timing-and-reviews-affect-success-nsfw-games-show-unusually-high-conversion-rate/)). |
| **L+1w** | Creator outreach wave 2: launch-day coverage gets clipped and shared. Patch 1. Record week-1 metrics (§7). | |
| **L+2–4w** | Quality-of-life patch with an update event. Join the first eligible seasonal sale after the 30-day release cooldown. Add the game to the franchise bundle. Write the postmortem metrics into `projects/<id>/POSTMORTEM.md`. | By now game N+1 should be on its own L−4w step. |
| **Ongoing** | Every new release creates a "sale moment" for the back catalogue: discount older titles in launch week when cooldowns allow, and refresh the bundle. | See §5. |

**Next Fest does not fit a monthly cadence by default.**
- Next Fest runs three times a year (Feb, Jun, Oct).
- Each game can appear **only once**, must be unreleased, and must have a public store page and a playable demo by the start of the fest ([Steamworks: Next Fest, acc. 2026-11-26](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest)).
- The demo should be submitted about 3 weeks before the fest ([Next Fest tips](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/tips)).

Policy: for the game whose launch lands **1–4 weeks after a Next Fest**, plan the schedule so its demo is in the fest. That is up to three games per year. Pick the titles with the strongest hook-test results, because pre-fest wishlists are the best predictor of fest results (see §2.3). Fest dates for 2027 are in `memories/marketing/next-fest-once-per-game-plan-which-game`.

---

## 2. Benchmarks reference

### 2.1 Wishlists to sales

| Metric | Value | Source (date) |
|---|---|---|
| Median first-week sales ÷ launch wishlists, games with >25k wishlists, Sep 2024–Sep 2025 | **0.15x** (0.14x excluding adult games) | [GameDiscoverCo 2025-10-17](https://newsletter.gamediscover.co/p/the-state-of-steam-wishlist-conversions) |
| Same, games priced above $10 | **0.10x** | same |
| Spread between titles | about 10x (order of magnitude) | same |
| Earlier GDCo median, first week | 0.2x | [Game World Observer 2024-12-06](https://gameworldobserver.com/2024/12/06/wishlist-to-sales-ratio-steam-gamediscoverco-benchmark) |
| First-month sales per wishlist (developer-reported data) | 0.45 (2020–22 releases) → **0.22** (2023–25 releases) | Zukowski, via [Inven Global ~2026-10](https://www.invenglobal.com/articles/27273/steam-wishlist-inflation-value-of-1-wishlist-cut-in-half-but-predictive-power-remains-unchanged) |
| Six-month / one-year sales per wishlist, 2023–25 releases | 0.43 / **0.70** | same |
| Correlation of launch wishlists to month-1 sales | 0.72 (2023–25) | same |
| Howtomarketagame study, Feb 2025, sales ÷ wishlists by wishlist bucket | 15% (<5k), 20% (5k–40k), 23% (40k–100k), 25% (100k+). **Measurement window unclear, unverified** | [howtomarketagame benchmarks](https://howtomarketagame.com/2026/06/25/archive-how-many-wishlists-should-i-have-when-i-launch-my-game/) (via search summary) |

Note that GDCo's ratio counts *all* first-week sales (organic sales plus sales from wishlists) divided by wishlists. It is not "the % of wishlisters who bought".

**Planning rule for us:** expected week-1 units ≈ 0.10–0.15 × launch wishlists, and expected year-1 units ≈ 0.7 × launch wishlists. Use the low end when the price is above $10.

### 2.2 Visibility thresholds

| Surface | What gets you in | Source (date) |
|---|---|---|
| Popular Upcoming (front page) | Before 2026-06: about 5–10k wishlists. After the 2026-06-04 refresh: about **80k** (some say 100k). Ranking blends wishlist total, velocity and release proximity; each game is effectively eligible once. All **unverified**: inferred by developers, not published by Valve. | [GamesRadar 2026](https://www.gamesradar.com/games/valve-made-it-roughly-15-times-harder-for-indie-games-to-reach-a-coveted-steam-ranking-but-one-expert-says-an-understated-new-steam-feature-is-doing-gods-work/); [PC Guide 2026](https://www.pcguide.com/news/steams-new-100000-wishlist-rule-means-many-indie-devs-will-have-to-rely-on-a-different-feature-to-be-discovered/); [Zukowski 2024-06-04, velocity](https://howtomarketagame.com/2024/06/04/what-is-wishlist-velocity-and-is-it-a-better-indicator-of-success/) |
| Personal Calendar (new in 2026-06) | Personalised by tags. Reportedly weighted towards smaller games. Claim of 300–3,000 wishlists/day is **unverified** | [games.gg 2026](https://games.gg/news/steam-popular-upcoming-indie-personal-calendar/) |
| New & Trending | Secret **revenue** threshold, varies by country and language. A 30k+ wishlist heuristic is used by publishers | [Steamworks Visibility, acc. 2026-11-26](https://partner.steamgames.com/doc/marketing/visibility); [Zukowski 2024-01-29](https://howtomarketagame.com/2024/01/29/do-wishlists-matter-any-more/) |
| Wishlists in the algorithm | Valve has confirmed wishlists are **not** a factor in most algorithmic visibility, except Popular Upcoming | [Creative Bloq 2026-06](https://www.creativebloq.com/3d/video-game-design/is-steams-more-modern-redesign-good-or-bad-for-indie-game-developers) (secondary) |
| Wishlist velocity | Usually defined as wishlists gained in the 30 days before launch. Zukowski argues it is a better success indicator than the raw total | [Zukowski 2024-06-04](https://howtomarketagame.com/2024/06/04/what-is-wishlist-velocity-and-is-it-a-better-indicator-of-success/) |

### 2.3 Next Fest

| Metric | Value | Source (date) |
|---|---|---|
| Median wishlists gained during the fest (survey) | **806** (Feb 2026). Percentiles: p30 = 382, p70 = 1,839, p95 = 13,461 | [Zukowski, "Making sense of Feb 2026 Next Fest" 2026-04-13](https://howtomarketagame.com/2026/04/13/making-sense-of-the-february-2026-steam-next-fest/) |
| Tier definitions (wishlists gained) | Bronze 0–999, Silver 1k–6,999, Gold 7k–9,999, Diamond 10k+ | same / [benchmarks page](https://howtomarketagame.com/2025/03/26/benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/) |
| Best predictor of fest results | Pre-fest wishlists (Spearman 0.825) | same |
| Median wishlists gained, Oct 2024 | about 930–967 (demo on a separate page vs on the main page; no real difference) | [Zukowski 2024-11-04](https://howtomarketagame.com/2024/11/04/how-was-the-october-2024-steam-next-fest/) |
| Demo players per wishlist | about 5.3 players per 1 wishlist (median, Oct 2024) | same |
| Valve's own figure (2020) | Median game's daily wishlist adds +421% during the fest vs the prior 2 weeks | [Game Developer, 2020](https://www.gamedeveloper.com/business/steam-next-fest-continues-to-boost-wishlisting-and-sales-says-valve) |
| Caveat | Fest-sourced wishlists convert worse than others; Zukowski cites this as a cause of "wishlist inflation" | Zukowski, via [Inven Global ~2026-10](https://www.invenglobal.com/articles/27273/steam-wishlist-inflation-value-of-1-wishlist-cut-in-half-but-predictive-power-remains-unchanged) |

### 2.4 Reviews to sales ("Boxleiter number")

| Estimate | Multiplier (units per review) | Source (date) |
|---|---|---|
| Classic Boxleiter / Birkett working number | about 80x (dataset average 82, median 77) | [Game Developer, n.d. (post-SteamSpy-privacy, ~2018)](https://www.gamedeveloper.com/business/using-steam-reviews-to-estimate-sales) |
| Gamalytic, 2023 | The ratio halved after Steam began prompting reviews in 2019 and still edges down every year. **>90% positive: about 30x; about 70% positive: about 60x.** Higher price gives a lower multiplier | [Gamalytic 2023](https://gamalytic.com/blog/a-deep-dive-into-the-steam-review-ratio) |
| GameDiscoverCo | Small sellers (<1k units) have a median of about **20x** | [GDCo "What review count tells us"](https://newsletter.gamediscover.co/p/what-steam-review-count-tells-us), via [otakukart 2025](https://otakukart.com/steams-review-multiplier-still-shapes-game-revenue-metrics-in-2025/) |
| Current working range (vendor blog) | **about 30x, range 20–40x**, roughly flat since 2022. **Unverified** | [Steam Page Analyzer, 2026](https://www.steampageanalyzer.com/blog/steam-review-to-sales-multiplier) |
| Genre | VG Insights found genre effects *not* statistically significant. Only release year, price and % positive were significant. Gamedeveloper.com suggests roguelikes and sim/strategy run higher, story, casual and puzzle lower (**unverified**) | [VG Insights, 2021](https://wp.vginsights.com/further-analysis-into-steam-reviews-to-sales-ratio-how-to-estimate-video-game-sales/2) |

**Our rule for competitor estimates:** units ≈ reviews × 30. Use 20x for games under $10 that are very positive or very small, and 40–60x for games that are Mixed or priced above $20. Treat any single estimate as ±50%.

### 2.5 Paid acquisition

| Metric | Value | Source (date) |
|---|---|---|
| Cost per wishlist, well-targeted ads | about $1, with $1–2 "acceptable". Reddit and Meta are best; Google Search is not worth it; Facebook boosted posts do not work. **Unverified**: secondary summaries of Zukowski | [Steam Page Analyzer, n.d.](https://www.steampageanalyzer.com/blog/indie-game-marketing-budget); [howtomarketagame 2022-03-08](https://howtomarketagame.com/2022/03/08/what-should-you-spend-money-on-if-you-have-a-small-marketing-budget/) |
| Real campaign example | Danchi Days: 3,600 wishlists from Reddit ads; the developer struggled to go below $1.50/wishlist | [Melodic Ambient newsletter, n.d.](https://buttondown.com/melodicambient/archive/danchi-days-3600-wishlists-through-reddit-ads-was) |
| Paid TikTok ads | "Rarely pay off for indie games" (funnel too long). **Unverified** | [presskit.gg, n.d.](https://presskit.gg/field-guides/tiktok-indie-game-marketing) |

**Why ads lose money for $5–$10 games.** At 0.22 month-1 sales per wishlist, $1 of ads buys about 0.22 sales in the first month. For a $9.99 game, our net per sale after Steam's 30%, VAT, refunds and regional pricing is roughly $5–6 (a rule of thumb, **unverified**). That returns about $1.2–1.3 per $1 in the first month. It improves to about 0.7 sales per wishlist within a year, but most of those sales happen at a discount. This is break-even at best, before the cost of making creatives.

**Policy:** no paid ads for games priced at $10 or less. The exception is a capped test of **$10–20/day for 1–2 weeks** to measure cost per wishlist for a genre we plan to reuse.

---

## 3. Store page best practice

- **Capsule art is the #1 spend.**
  - Zukowski: "If you have a limited budget, I would spend money on a capsule before a trailer, ads, in-person conventions, or a PR company." You can get by with a montage trailer, but you cannot fake a capsule ([howtomarketagame 2022-03-08](https://howtomarketagame.com/2022/03/08/what-should-you-spend-money-on-if-you-have-a-small-marketing-budget/)).
  - In a case study, one new image increased sales **20x** ([howtomarketagame 2020-04-13](https://howtomarketagame.com/2020/04/13/how-one-new-image-increased-sales-by-20x/)).
  - Rules:
    - Show the genre at thumbnail size.
    - Keep the logo legible at small size.
    - Use one clear focal subject.
    - Keep it consistent with the screenshots.
  - The 2026 redesign uses wider, higher-resolution images, and developers report rethinking capsules for the Personal Calendar ([games.gg 2026](https://games.gg/news/steam-popular-upcoming-indie-personal-calendar/)). Check current asset specs in Steamworks before each commission.
- **Screenshots.**
  - Gameplay with UI visible; no concept art or title cards.
  - The **first 3** carry the most weight, so lead with action that reveals the genre ([Steam page checklist, Zukowski 2020](https://howtomarketagame.com/wp-content/uploads/2020/03/SteamPageChecklistv1.pdf); [gtstu.com, n.d.](https://gtstu.com/steam-store-page-wishlist-conversion/), **unverified**).
- **Trailer.**
  - Gameplay from the first second, with no slow establishing shots and no studio logo up front.
  - Make it work muted, because autoplay is silent.
  - Keep it **30–90 s**, with about 60 s as the common target.
  - Use at most 2 trailers on the page so videos do not push screenshots off.
  - Sources: [Zukowski checklist 2020](https://howtomarketagame.com/wp-content/uploads/2020/03/SteamPageChecklistv1.pdf); [Game World Observer citing Derek Lieu, 2022-09-22](https://gameworldobserver.com/2022/09/22/common-game-trailer-mistkaes-indie-developers-steam); [Steam Page Analyzer](https://www.steampageanalyzer.com/blog/steam-trailer-best-practices) (**unverified** on retention data).
  - For a monthly game, trailer v1 can be a well-cut montage. Do not over-invest.
- **Short description.** Genre plus hook plus the player fantasy in one or two sentences. It should name what the player *does*, so the capsule, short description and first clip all say the same thing ([Game Developer beginner's guide, n.d.](https://www.gamedeveloper.com/business/a-beginner-s-guide-to-designing-indie-game-store-pages)).
- **Tags** ([Steamworks: Tags, acc. 2026-11-26](https://partner.steamgames.com/doc/store/tags); [Zukowski 2020-11-12](https://howtomarketagame.com/2020/11/12/steam-101-how-to-tag-your-game/)):
  - Only the top **20** tags are shown and used for visibility.
  - Tags are weighted, and higher-weighted tags drive visibility more.
  - The **top 5** are used to describe the game.
  - Some filters use the **first 15**, so sort them by relevance.
  - For recommendations, overlap between several tags matters more than their order.
  - Use the Tag Wizard's "Suggest Prioritization".
  - Copy the tag pattern of 5–10 comparable successful games. Avoid aspirational tags that attract the wrong audience, because they hurt conversion and reviews.
  - After the 2026 redesign, tag accuracy also feeds the Personal Calendar.
- **Localisation.**
  - Simplified Chinese became the most-used language in the Steam hardware survey (over 50% in Feb 2025; full-year 2024: 33.7% vs 33.5% for English) ([PC Gamer / Alinea, 2025](https://alineaanalytics.substack.com/p/chinese-audiences-have-been-a-huge)).
  - Case studies:
    - Political Animals: **3.2x** units in the 5 weeks after adding Simplified Chinese.
    - Hidden Folks: 41% of units went to Chinese players, 30% of revenue ([Game Developer, ~2017–19](https://gamedeveloper.com/business/china-is-kind-of-a-big-deal-for-indie-games)).
  - Revenue per Chinese player is about 47% of a US player's because of regional pricing.
  - Valve's New & Trending threshold is per country and language, so localisation also changes visibility ([Steamworks Visibility](https://partner.steamgames.com/doc/marketing/visibility)).
  - **Policy:** for games with little text, localise the store page and the game into Simplified Chinese at launch, plus 3–5 of Japanese, German, French, Spanish, Brazilian Portuguese, Russian and Korean, when the text volume makes it cheap. Track the share of revenue by language. The evidence is anecdotal and confounded, so treat it as a hypothesis to test across our titles.

---

## 4. Channels

**What works for small games, in priority order for us:**

1. **Short-form video (TikTok, YouTube Shorts, Instagram Reels).**
   - Cases:
     - *Digging a Hole*: see §0.
     - *The Matriarch*: one TikTok took it from about 400 to over 20k wishlists ([Game Developer, n.d.](https://www.gamedeveloper.com/game-platforms/from-400-to-20-000-wishlists-with-1-video-how-tiktok-can-make-your-game-go-viral)).
     - *Mortal Rite*: 120M views and about 60k wishlists ([Game Developer, n.d.](https://www.gamedeveloper.com/game-platforms/this-game-used-tiktok-to-get-120m-views-60k-steam-wishlists-)).
     - Another developer: one 4.5M-view TikTok brought about 10k wishlists.
   - Zukowski's TikTok tips date from 2022-02-07 ([howtomarketagame](https://howtomarketagame.com/2022/02/07/seven-great-tips-for-marketing-your-indie-game-on-tiktok/)).
   - Most of this evidence is from 2022–23 and is survivorship-biased.
   - Why it is our best channel: it is cheap, gives instant feedback and doubles as hook testing. Post every clip to all three platforms.
2. **Reddit.**
   - Laysara's r/gaming post (3.2M views) brought about **11k wishlists** on day one, an outlier ([howtomarketagame 2022-01-10](https://howtomarketagame.com/2022/01/10/how-a-two-person-team-earned-11000-wishlists-with-one-reddit-post/)).
   - A typical successful post brings about **100–150 wishlists**. Most posts get 10–50 upvotes and only a trickle ([Steam Page Analyzer](https://www.steampageanalyzer.com/blog/reddit-indie-game-marketing), **unverified**).
   - Use GIF or short clips under 60 s in genre-specific subreddits.
   - Respect the norm of 1 self-promo post per 10 posts. Never cross-post the same clip to many subreddits within an hour ([impress.games 2024-08-28](https://impress.games/blog/how-to-promote-your-indie-game-on-reddit)).
3. **Creators and streamers.**
   - Find creators who have *recently played comparable games*. Search YouTube and Twitch for the comparable titles, and note channels of 1k–100k subscribers. Smaller creators answer more often (practitioner consensus, **unverified**).
   - Pitch: a short email with the hook in the subject line, one GIF, a Steam link, a key and the embargo date.
   - Key-distribution platforms such as Keymailer, Woovit and Lurkit authenticate creators and let us filter by size and region ([games.gg](https://games.gg/news/steam-key-distribution-pricing/)). Woovit is YouTube/Twitch only, and its pricing is not public.
   - One 2026 review claims Keymailer caps indie titles at 10 keys/month. That is a single user's claim, **unverified** ([Trustpilot](https://fi.trustpilot.com/review/keymailer.co)).
   - Beware of scam key requests: only send keys to the address listed on the channel itself ([Game Developer](https://www.gamedeveloper.com/game-platforms/avoiding-ineffective-or-scam-discovery-interactions-with-influencers)).
   - Some developers argue against key platforms in favour of direct outreach ([Benjamin Glover](https://benjaminglover.substack.com/p/heres-a-long-article-explaining-why)).
   - We will A/B test both across titles.
4. **Demos.**
   - A demo is required for Next Fest.
   - Zukowski's 2026 view is "nobody plays demos and that is OK": a demo's value is wishlists, visibility and the fest, not play counts ([howtomarketagame 2026-06-30](https://howtomarketagame.com/2026/06/30/nobody-plays-demos-and-that-is-ok/)).
   - Wishlisters and followers are **not** notified when a demo launches ([Steamworks: Followers](https://partner.steamgames.com/doc/marketing/followers), via search summary).
   - For non-fest titles, build a demo only if it costs at most 2 days to make.
5. **Steam festivals.**
   - Next Fest: see §1 and §2.3.
   - Themed fests run by Valve or third parties are free extra visibility. Apply to every relevant one for both upcoming and back-catalogue titles. For which fests exist and their deadlines, check the Steamworks "Upcoming Events" pages per cycle.
6. **Bundles and our own catalogue.** See §5.

**What tends not to work for us:**
- Paid ads for games priced at $10 or less (§2.5).
- Google Search ads.
- Facebook boosted posts.
- Paid PR firms and in-person conventions on our budget ([howtomarketagame 2022-03-08](https://howtomarketagame.com/2022/03/08/what-should-you-spend-money-on-if-you-have-a-small-marketing-budget/)).
- Mass-mailing press. **Unverified** for our genre.
- Valve removed cross-promo links and images from store descriptions in Aug 2024 ([Steam Page Analyzer](https://www.steampageanalyzer.com/blog/steam-bundle-strategy), **unverified**; the change is described in Steamworks bundle docs). Use bundles, franchise pages and the developer homepage instead.

---

## 5. Exploiting the monthly cadence (our structural advantage)

1. **One Creator/Developer Homepage, with every game linked before its page goes live.**
   - Homepage followers get an **email when a new game releases**, and announcements appear in their activity feed ([Steamworks: Creator Homepage, acc. 2026-11-26](https://partner.steamgames.com/doc/store/creator_homepage); [Valve announcement, 2018](https://store.steampowered.com/oldnews/20845)).
   - Steam now offers "follow developer/publisher" at purchase ([WN Hub](https://wnhub.io/news/stores-and-publishing/item-47906)).
   - Homepage followers are our only compounding Steam-native audience. Track them as a top-level KPI. They differ from per-game followers, who get no launch email ([Zukowski 2023-05-01](https://howtomarketagame.com/2023/05/01/what-is-the-difference-between-a-steam-wishlist-and-a-follower/); [presskit.gg](https://presskit.gg/field-guides/steam-followers-vs-wishlists)).
   - Put a "Follow us on Steam" call to action:
     - in the game's main menu and end screen;
     - in every Steam event post;
     - in every short-form video bio.
2. **Cross-promotion inside our catalogue.**
   - On each launch day, post an event on every previous game's page announcing the new one (events reach those games' owners, followers and wishlisters).
   - Discount the back catalogue in launch week where cooldowns allow.
   - Reuse the "More from this developer" placement.
3. **Franchise / Developer bundle.**
   - Steam supports "Franchise Pack" and "Developer Pack" bundles with **complete-the-set** pricing, so owners of one game pay only for the rest ([Steamworks: Bundles, acc. 2026-11-26](https://partner.steamgames.com/doc/store/application/bundles)).
   - Bundle sales are counted inside each product's figures.
   - Pin the bundle on every store page and add each new game to it at launch.
   - Collaborative bundles with other developers are also possible ([Steamworks collaborative bundles](https://partner.steamgames.com/doc/store/application/bundles/collaborative)).
   - Zukowski on bundles: ["Bundling is giving", 2022-12-14](https://howtomarketagame.com/2022/12/14/bundling-is-giving/).
4. **Recurring audience off Steam.**
   - One Discord, one mailing list and one short-form account for the studio brand, *not* one per game, so every game's viral moment grows the same audience.
   - A consistent visual and brand signature across titles helps creators remember and recommend us. This is a hypothesis to test.
5. **Reuse winners.**
   - When a game over-performs on wishlist velocity, sales or follower growth, consider a sequel, an expansion or a "same hook, new theme" game next month. Its owners are the warmest possible audience.
   - Record each result in `memories/market/` so the concept picker can use it.
6. **Learning loop.**
   - Every launch is an experiment slot. Change one marketing variable per game (capsule style, price, demo or no demo, key platform, localisation set) and log the result in the iteration file.

---

## 6. Pricing and launch discounts ($5–$20 games)

- **Market norms.**
  - The median launch price of the top 50 new Steam releases fell from $19.50 (Feb 2023) to **$15.64 (Oct 2025)** ([GameDiscoverCo via TechSpot/GamesRadar, 2025-10](https://www.gamesradar.com/games/the-median-price-of-best-selling-new-games-on-steam-has-dropped-in-the-past-2-years-research-finds-charging-usd25-is-getting-trickier-as-players-compare-value-to-the-usd10-usd15-indie-titles)).
  - Among the top 1,000 indie games, the most common prices are $19.99, then $14.99, then $9.99 ([Gamigion](https://www.gamigion.com/?p=27722); date not shown).
- **Price vs conversion.** Games priced above $10 convert wishlists worse: 0.10x vs 0.15x overall ([GameDiscoverCo 2025-10-17](https://newsletter.gamediscover.co/p/the-state-of-steam-wishlist-conversions)). The claim that $9.99 sells 2.5x the units of $14.99 is **unverified** ([earnifyhub](https://earnifyhub.com/gaming/indie-game-pricing-strategy-2026)).
- **Refunds.** Steam refunds anything under 2 h of playtime within 14 days. A game that can be finished in under 2 hours needs replay value or a low price.
- **Our default price ladder**, to be calibrated after 3 launches:
  - About 1–2 hours of content, with a viral or toy-like hook: **$4.99–$5.99**.
  - About 3–6 hours of polished content, or a replayable roguelite or sim: **$7.99–$9.99**.
  - 8+ hours, or a deep systems game: **$12.99–$14.99**.
  - Above $15 only with strong comparable-game evidence.
- **Launch discount.**
  - Valve generally suggests **10–15%**.
  - It must be set before launch and runs 7–14 days.
  - It triggers a 30-day cooldown before the next discount. Seasonal sales are exempt from that cooldown, but not from the 30-day release cooldown ([Steamworks: Discounts](https://partner.steamgames.com/doc/marketing/discounts); [Steamworks: Seasonal sales](https://partner.steamgames.com/doc/marketing/discounts/seasonalsales)).
  - Maximum launch discount: 40% ([GamesRadar on Steamworks rules](https://www.gamesradar.com/valve-lets-steam-launch-discounts-double-in-length-so-the-savings-now-last-between-7-and-14-days); cross-checked by a parallel research session, `memories/marketing/steam-release-blocks-discounts-30-days`).
  - **Default: 10% for 7 days for games under $10, 15% for games of $10 or more.** Steam emails wishlisters at release and when a wishlisted game is discounted ([Steamworks: Wishlists](https://partner.steamgames.com/doc/marketing/wishlist); exact email triggers **unverified**). A small launch discount is cheap insurance, so we always run one.
- **Later discounts.**
  - Regional pricing: use Valve's recommended regional prices ([Steamworks: Pricing](https://partner.steamgames.com/doc/store/pricing)).
  - Seasonal sales: in year 1, step discounts up gradually (20%, then 30%, then 40%, then 50%+) to avoid training buyers to wait.
  - A SteamSpy-era analysis found 50–79% off the most profitable for mature titles ([Game Developer, n.d.](https://gamedeveloper.com/business/the-most-profitable-way-to-discount-your-game-on-steam)).

---

## 7. Metrics: what we track for every game

Record these in `projects/<id>/marketing-metrics.md`, or in the iteration file, at each checkpoint: **page live, L−1d, L+7d, L+30d, L+90d, L+365d**. The sources are Steamworks (Wishlist report, UTM Traffic report, Sales, Store traffic stats), the platform analytics pages, and the creator-platform dashboards.

**Funnel, pre-launch**

| Metric | Why it matters | First target (to recalibrate) |
|---|---|---|
| Store page impressions → visits (CTR) | Tests the capsule and tags | Compare across our titles; no reliable public benchmark found |
| Visits → wishlists (page conversion) | Tests the trailer, screenshots and description | Same |
| Wishlists at page-live +7d, and at L−1d | Raw demand | Track; use median Next Fest gain (806) as a sense check |
| **Wishlist velocity**: net wishlists over the last 30 days before launch | Better success indicator than total ([Zukowski](https://howtomarketagame.com/2024/06/04/what-is-wishlist-velocity-and-is-it-a-better-indicator-of-success/)) | Increase every launch |
| Wishlists by source (UTM links per post, per platform) | Which channel works | n/a |
| Short-form views per clip, and wishlists/day correlated with them | Channel ROI and hook testing | n/a |
| Creator keys sent / redeemed / videos made / views | Creator ROI per platform | n/a |
| Developer Homepage followers (total and delta) | **Our compounding asset** | Increase every month |

**Launch and after**

| Metric | Why it matters |
|---|---|
| Week-1 units and gross revenue | Core result |
| **Week-1 units ÷ launch wishlists** | Our own conversion ratio vs the 0.10–0.15x benchmark |
| Month-1 and year-1 units ÷ launch wishlists | Long-tail behaviour vs Zukowski's 0.22 / 0.70 |
| Review count, % positive at L+7d and L+30d | Week-1 score predicts over-performance (91% vs 67%) |
| Units ÷ reviews (our own Boxleiter number) | Calibrates the competitor estimates in `research/` |
| Whether it reached New & Trending (and in which regions) | Visibility check |
| Revenue share by country and language | Tests localisation |
| Refund rate | Expectation mismatch from the store page |
| Median playtime | Content vs price check |
| Cross-sell: back-catalogue units in launch week vs the previous 4-week average | Tests catalogue compounding |
| Bundle units | Same |
| Net revenue vs (dev cost + marketing cost); $100 app fee recouped (≥$1k AGR) | Profitability |

**Monthly factory dashboard (cross-title):**
- homepage followers;
- total catalogue revenue/month;
- median conversion ratio across titles;
- median week-1 review score;
- best-performing channel;
- the marketing variable we changed and what happened.

---

## Open questions to verify before relying on them

- The exact Popular Upcoming threshold after 2026-06, and how Personal Calendar ranks games.
- Whether the howtomarketagame Feb 2025 bucket conversions (15–25%) measure week 1 or a longer window.
- Current Keymailer, Woovit and Lurkit pricing and caps for indies.
- Any 2025–26 primary dataset on reviews per sale by price.
