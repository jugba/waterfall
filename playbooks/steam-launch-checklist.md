# Steam launch checklist (v1 — researched, not yet used on a launch)

- Researched: 2026-11-26 (all facts "checked 2026-11-26" unless marked otherwise)
- Learned from: desk research only; validate on project 002 and revise in its postmortem.
- Pairs with: `playbooks/monthly-cycle.md` (this playbook supersedes its review-time assumptions).

**How the evidence was gathered.** `partner.steamgames.com` and `store.steampowered.com`
could not be fetched from this session (host not in the network allowlist), so official
Steamworks pages were read through web-search extracts of those pages. Facts are tagged:

- **[official]** — stated on a Valve page (Steamworks docs, Steamworks news, Steam support), seen via search extract.
- **[press]** — reported by secondary press/third-party guide citing Valve; not seen on a Valve page.
- **[unverified]** — conflicting or single-source; confirm in the Steamworks partner site before relying on it.

Before each launch, re-open the linked Steamworks pages (logged in) and update anything that changed.

---

## Key constraints that shape a 1-game-per-month cadence

1. **Review lead time is now ~3 weeks, not 1.** Valve said on 2026-11-03 that pre-release
   build reviews take **up to 12 business days** (normal target 3–5) because of a submission
   surge and re-reviews of failed builds. [official] [Valve post][rev-2026] · [press][vgc-rev]
2. **Store page must be public as Coming Soon ≥ 2 weeks before release**, and the store page
   review should be submitted **≥ 7 business days** before you want it live. Store page review
   must be submitted (and passed) before the build can be submitted. [official] [coming_soon][cs] · [releasing][rel]
3. **Each game needs its own $100 Steam Direct fee**, and there is a **30-day wait between paying
   the fee and being able to release**. [official] [appfee][fee] · [Steam Direct][sd] Whether the
   30-day wait applies to every app or only a new partner's first ones is **[unverified]** (one guide says
   "first few releases": [Xsolla guide][xsolla]). → Pay the fee for game N+2 when game N launches.
4. **Release day kills discounting for 30 days** except the launch discount (≤ 40%, 7–14 days,
   set up before release). A game released < 30 days before a seasonal sale cannot be discounted
   in it. [official] [discounts][disc] · [press][gr-launch]
5. **Next Fest is one-shot per game and needs an unreleased game with a public demo.**
   Feb 2027 edition: **Feb 22 – Mar 1, 2027, registration deadline Jan 10, 2027 11:59pm PST**. [official] [nf-feb27][nf-feb27]

---

## Timeline

Times are relative to launch day **T**. "Business days" (bd) exclude weekends and US holidays.
Because of the 2026 review backlog, the store-page and build gates are planned at the slow end.

### Before T-8 weeks (do once per partner account / once per game slot)

- [ ] Steamworks partner account exists; onboarding paperwork (legal entity, bank, tax interview,
      identity) complete. Valve's onboarding page says paperwork takes **15–30 days**. [official, via search extract] [onboarding][onb]
      Tax interview itself takes 5–10 min (W-9 / W-8BEN), then third-party/IRS TIN validation;
      newly issued TINs can take **up to 30 days**. [official] [tax FAQ][taxfaq]
- [ ] Pay the $100 Steam Direct fee for the app (Admin users only). Clock starts on the 30-day
      release wait. [official] [appfee][fee] Recouped after the product earns **$1,000 Adjusted Gross
      Revenue** (store + in-app). [official] [fee sub][feesub]
- [ ] Keep a pipeline of pre-paid app slots: when game N launches, game N+1's page should already be
      live and game N+2's fee paid. (Derived from constraints 2–3.)

### T-8 weeks — store page draft

- [ ] Fill the **content survey** (mature content + AI disclosure). Must be complete before submitting
      store page and build. [official] [content survey][survey]
  - AI disclosure covers content *players consume* (game, store page, community/marketing assets);
    backend efficiency tools (code assistants etc.) are out of scope since the Jan 2026 revision.
    Two categories: **pre-generated** (reviewed like any content) and **live-generated** (describe
    guardrails; players can report via overlay; live-generated adult sexual content not allowed).
    [press] [PC Gamer][pcg-ai] · [GamingOnLinux][gol-ai]
  - Germany: games without a valid age rating are hidden from German customers (since 2024-11-15).
    Valve issues a German rating from the Steam questionnaire for free; do **not** enter a USK rating
    produced via IARC on another store. Indonesia also requires a rating. [official] [Germany][de] · [Indonesia][id]
  - IARC: Steam does not appear to use IARC directly; IARC certificates from other stores must not
    be reused as USK. Whether Steam accepts IARC for other regions is **[unverified]**.
- [ ] Produce the store assets (sizes in Reference A). Trailer is **required for release**;
      **≥ 5 screenshots**, ≥ 5 tagged as gameplay (all-ages if game has mature content). [official] [trailer][trailer] · [review process][review]
- [ ] Write description, tags, system requirements, price, supported languages.
- [ ] Decide Early Access vs full release (Reference D). Decide demo/playtest (Reference E).

### T-6 weeks — submit store page

- [ ] Complete the **Store Presence checklist** and submit the store page for review **≥ 7 business
      days before you want it public** (typical review 3–5 bd, now possibly longer). [official] [releasing][rel] · [coming_soon][cs]
- [ ] If entering Next Fest: register from the **base game** (not the demo) before the edition's deadline;
      page must be public/Coming Soon, demo must be a separate Demo-type app. [official] [Next Fest][nf]

### T-5 weeks — store page live (Coming Soon) — hard minimum T-2 weeks

- [ ] Make the page public as **Coming Soon**. Absolute minimum is 2 weeks before release (and 2 weeks
      before EA becomes playable). [official] [coming_soon][cs] Aim for 4–5 weeks to collect wishlists
      *and* absorb review slippage.
- [ ] Set a release date (or month). Changing it later may require contacting Valve **[unverified — 2019 report]** [GOL][gol-date].
- [ ] Start wishlist push: announce event, creator outreach, social posts linking the page.
- [ ] Every wishlister at release time gets an **email and/or mobile push** when the game releases
      (EA or full); another when EA → full release. [official] [wishlist][wish] This is the main
      reason the page must be live early.

### T-4 weeks — build ready for review

- [ ] Upload the release build to the default branch via SteamPipe; set launch options, depots,
      redistributables.
- [ ] **New (Nov 2026): the release checklist requires recent Steam playtime** — launch via Steam's
      Play button (any account's playtime counts) within the last 7 days, or since the last build
      upload. Press reports a **5-minute minimum**. [official] [Valve post][rev-2026] · [press, 5 min][gsm]
- [ ] Reviewers must be able to reach all content (incl. multiplayer). Provide test instructions/keys. [press] [summary][rev-sum]
- [ ] Achievements / Steam Cloud / redistributables / screenshot labelling are reported as checklist
      items in the Nov 2026 change. Whether achievements and Cloud are *mandatory* is **[unverified]**;
      treat both as expected-by-players and cheap to add (plan them into every game).
- [ ] **Submit build for review at ≥ T-4 weeks** (12 bd ≈ 2.5 calendar weeks + one re-review buffer).
      A failed build re-enters the queue — re-reviews are the main cause of the backlog. [official] [Valve post][rev-2026]

### T-3 weeks — discounts and events

- [ ] Configure the **launch discount** now (must be set up before release): max **40%**, runs
      **7–14 days** from release, ends 10am Pacific; Valve suggests 10–15%. [official+press] [discounts][disc] · [GamesRadar][gr-launch]
- [ ] Request **Steam Deck compatibility review** (Technical Tools on app landing page). Results
      by email; you choose whether to publish. 2021 target turnaround was "within a week" — current
      time **[unverified]**. Verified on Deck also counts as Verified on Steam Machine. [official] [Deck compat][deck] · [PC Gamer 2021][pcg-deck]
- [ ] Prepare launch-day event/announcement (Steamworks events) and press/creator keys.

### T-1 week — final checks

- [ ] Build review passed? If not, move the date now (cut scope, never polish — CLAUDE.md rule 8).
- [ ] Store page: capsules final, trailer first frame/gameplay-first, price confirmed in all currencies.
- [ ] Release is **manual**: approval does not auto-release. Confirm who presses the button. [press] [SPA guide][spa-pub]

### Launch day (T)

- [ ] Press **Release** in Steamworks (all checklist items green). Wishlist emails go out automatically.
- [ ] Post launch announcement event; reply in community hub; watch crash reports and refunds.
- [ ] Hotfix pipeline ready (patch builds still go through SteamPipe; minor updates don't need re-review
      **[unverified]**).

### T+1 to T+14 days

- [ ] Launch discount runs (7–14 days). Monitor reviews, refunds (Reference G), wishlist conversion.
- [ ] Ship a quick-fix patch; announce it (events bring players back).
- [ ] Demo: the July 2026 one-time demo notice to wishlisters is sent when the **demo** goes public
      (up to 2 weeks after), i.e. pre-launch — schedule it in the Coming Soon window, not after launch. [press] [PCGamesN][pcgn-wish]

### T+30 days

- [ ] **Release cooldown ends** — first normal discount or seasonal sale possible. 30 days must also pass
      between any two discounts (seasonal sales exempt from the prior-discount rule, not from the release
      or price-increase cooldowns). [official] [discounts][disc]
- [ ] Register for the next seasonal sale / relevant themed fest (Reference C).
- [ ] Write `POSTMORTEM.md` numbers: wishlists at launch, conversion, refunds %, revenue vs $1,000 recoup.

---

## Reference

### A. Required graphical assets (checked 2026-11-26)

Larger sizes accepted since Aug 2024; old dimensions no longer accepted for most capsules.
[official] [assets][assets] · [library assets][lib] · cross-checked [impress.games browser][impress]

| Asset | Size (px) | Required | Notes |
|---|---|---|---|
| Header capsule | 920 × 430 | Yes | Top of store page, recommendations |
| Small capsule | 462 × 174 | Yes | Lists/search; 120×45 and 184×69 auto-generated |
| Main capsule | 1232 × 706 | Yes | Front-page carousel |
| Vertical capsule | 748 × 896 | Yes | Seasonal sale pages (size [press] via impress.games) |
| Screenshots | ≥ 1920 × 1080, 16:9 | ≥ 5 | ≥ 5 tagged gameplay |
| Page background | 1438 × 810 | Optional | Size [press] only |
| Library capsule | 600 × 900 | Yes | Library grid |
| Library header | 920 × 430 | Yes | (Dutch docs show 460×215 — likely stale) |
| Library hero | 3840 × 1240 | Yes | PNG, no logo/text |
| Library logo | 1280 wide and/or 720 tall | Yes | Transparent PNG, sits on hero |
| Trailer | — | Yes (for release) | Gameplay-first recommended [trailer][trailer] |
| Event/announcement assets | see [event assets][eventassets] | Per event | |

### B. Next Fest

- **Feb 2027:** Feb 22 – Mar 1, 2027; registration deadline **Jan 10, 2027, 11:59pm PST**. [official] [feb_2027][nf-feb27]
- **Jun 2027:** Jun 14 10:00 PDT – Jun 21 10:00 PDT, 2027. Registration deadline **[unverified]** (expect ~5–6 weeks before). [official] [june_2027][nf-jun27]
- **Oct 2027:** planned, dates not yet published. [official] [june_2027][nf-jun27]
- Rules: developer account in good standing; base game page public (Coming Soon); public playable demo
  by start; registration from base game; **a game may only appear once in Next Fest**. [official] [Next Fest][nf] ·
  [june_2027][nf-jun27]. Base game must be unreleased: third-party guides say yes, official wording focuses on
  "upcoming" games — **[unverified]**, assume yes.
- Cadence implication: a monthly game can only use Next Fest if its launch falls *after* the fest
  (e.g. a March 2027 game with a demo in the Feb fest). Plan which game gets each fest.

### C. Seasonal sales and themed fests, 2026-12 → 2027

| Event | Dates | Source |
|---|---|---|
| Winter Sale 2026 (+ Steam Awards voting) | Dec 17, 2026 – Jan 4, 2027, 10am PT | [official] [winter_sale][winter] |
| Desktop Companion Fest | Jan 14 – 18, 2027 | [press] [Insider Gaming][ig27] |
| Shop Keeper Fest | Jan 25 – Feb 1, 2027 | [press] [Insider Gaming][ig27] |
| Sheep Fest | Feb 4 – 8, 2027 | [press] [Insider Gaming][ig27] |
| Couch Co-Op Fest | Feb 8 – 15, 2027 | [press] [Insider Gaming][ig27] |
| **Next Fest** | Feb 22 – Mar 1, 2027 | [official] [feb_2027][nf-feb27] |
| Rhythm Fest | Mar 8 – 15, 2027 | [press] [TheBigBois][bigbois] |
| **Spring Sale** | Mar 18 – 25, 2027 | [official] [upcoming events][events] |
| Dinos vs. Robots Fest | Mar 29 – Apr 5, 2027 | [press] [TheBigBois][bigbois] |
| Racing Fest | Apr 12 – 19, 2027 | **[unverified]** single source [TheBigBois][bigbois] |
| Fighting Fest | Apr 26 – May 3, 2027 | **[unverified]** single source [TheBigBois][bigbois] |
| Real-Time Strategy Fest | May 10 – 17, 2027 | [press] [TheBigBois][bigbois] |
| Mountaineering Fest | May 31 – Jun 3, 2027 | [press] [TheBigBois][bigbois] |
| **Next Fest** | Jun 14 – 21, 2027 | [official] [june_2027][nf-jun27] |
| **Summer Sale** | Jun 24 – Jul 8, 2027 | [official] [upcoming events][events] |
| H2 2027 (Autumn, Winter, Oct Next Fest) | not announced | [press] [Notebookcheck][nbc27] |

Fest names in January differ between outlets (ixbt.games calls them "Tabletop Companions" / "Store
Management") — check the official [upcoming events][events] page. No Lunar New Year 2027 or Black Friday 2026
Steam event found. Themed fests require opting in; eligibility is per fest page.

**Seasonal-sale cutoff dates for a discount** (release ≥ 30 days before start, derived from the release cooldown):
Winter 2026 → released by Nov 17, 2026 · Spring 2027 → by Feb 16, 2027 · Summer 2027 → by May 25, 2027.
A newer game may still join late once its cooldown ends ([press] [SPA winter sale][spa-winter], **[unverified]**).

### D. Discount rules [official] [discounts][disc] · [seasonal][seasonal]

- Any discount: 10% minimum, 95% maximum (90% in 2022 coverage). [press] [GamesRadar][gr-launch]
- Launch discount: ≤ 40%, 7–14 days, configured before release.
- No discount for 30 days after release (EA release **and** full release each count), 30 days after any
  price increase, or within 30 days of another discount.
- Seasonal sales are exempt from the prior-discount cooldown, **not** from release/price-increase cooldowns.

### E. Early Access [official] [earlyaccess][ea]

- Enable EA in store page config; complete the **Early Access Q&A**; Valve reviews page + Q&A before EA release.
  Weak answers (esp. "current state") get rejected. [press] [lilting guide][lilting]
- Coming Soon ≥ 2 weeks still applies before EA is playable. [official] [coming_soon][cs]
- EA release and full release **each** trigger a 30-day discount cooldown and a wishlist notification.
- EA playtime counts toward the 2-hour refund limit (since Apr 2024). [press] [GameSpot][gs-refund]
- Pricing rule for EA vs. full release: **[unverified]** (not found).
- Cadence note: EA → full release gives two wishlist pings but doubles the cooldown cost; it suits
  games we intend to keep updating, not one-month titles we move on from.

### F. Demos and Playtest [official] [demos][demos] · [playtest][playtest]

- **Demo:** separate app of type Demo linked to base game; optional own store page (then it gets reviews
  and a hub); otherwise appears as a button on the base page. Needed for Next Fest.
- **Playtest:** child app for closed/open tests; sign-up button on the main page (users still wishlist/follow
  the main game); playtest players cannot review the full game; data tracked separately.
- Demo notification to wishlisters (July 2026): one-time notice, send up to 2 weeks after demo goes public. [press] [PCGamesN][pcgn-wish]

### G. Revenue share and refunds

- Revenue share: Valve 30% up to $10M, 25% on $10M–$50M, 20% beyond $50M (per app, since Oct 2018). [press quoting Valve] [Game Informer][gi-rev] — no change found since.
- Refunds: any reason within **14 days of purchase** and **< 2 hours** playtime; Valve may remove refund
  access for abusers. [official] [refunds][refunds] · [support FAQ][refund-faq]
- **Implication for short games:** a game finishable in < 2 h can be bought, completed, and refunded.
  Design for ≥ 2–3 h of first-session value (replayability, unlocks, endless mode) or price low enough
  that refunding isn't worth the effort. Track refund % per game in the postmortem.

### H. Steam Deck

- Request review via "Steam Deck Compatibility Review" in Technical Tools; ratings Verified / Playable /
  Unsupported; can re-request after fixes. [official] [compat][deck]
- Cheap wins for Verified: controller support with correct glyphs, readable text at 1280×800, no launcher,
  default config works offline — our summary, **[unverified]**; use the criteria list in [compat][deck].

---

## Open questions to verify inside Steamworks (logged in)

1. Does the 30-day Steam Direct wait apply to every app or only early ones for an established partner?
2. Exact Next Fest June 2027 registration deadline.
3. Are achievements and Steam Cloud now hard requirements on the release checklist (Nov 2026)?
4. Current Deck review turnaround.
5. Can a released game join a themed fest within its release cooldown (no discount)?

[rev-2026]: https://store.steampowered.com/news/group/4145017/view/696528162820984745
[vgc-rev]: https://www.videogameschronicle.com/news/steam-says-its-running-behind-when-reviewing-pre-release-games-because-of-how-many-re-reviews-it-has-to-do/
[rev-sum]: https://tech-insider.org/steam-review-delay-valve-running-behind-12-business-days-2026/
[gsm]: https://www.gsmgotech.com/2026/11/steams-new-rule-developers-must.html
[cs]: https://partner.steamgames.com/doc/store/coming_soon
[rel]: https://partner.steamgames.com/doc/store/releasing
[review]: https://partner.steamgames.com/doc/store/review_process
[fee]: https://partner.steamgames.com/doc/gettingstarted/appfee
[sd]: https://partner.steamgames.com/steamdirect
[feesub]: https://store.steampowered.com/sub/163632
[xsolla]: https://xsolla.com/blog/self-publish-on-steam-the-ultimate-guide
[onb]: https://partner.steamgames.com/doc/gettingstarted/onboarding
[taxfaq]: https://partner.steamgames.com/doc/finance/taxfaq
[disc]: https://partner.steamgames.com/doc/marketing/discounts
[seasonal]: https://partner.steamgames.com/doc/marketing/discounts/seasonalsales
[gr-launch]: https://www.gamesradar.com/valve-lets-steam-launch-discounts-double-in-length-so-the-savings-now-last-between-7-and-14-days
[nf]: https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest
[nf-feb27]: https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027
[nf-jun27]: https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/june_2027
[events]: https://partner.steamgames.com/doc/marketing/upcoming_events
[winter]: https://partner.steamgames.com/doc/marketing/upcoming_events/2026_winter_sale
[ig27]: https://insider-gaming.com/2027-steam-sales-revealed-for-first-half-of-the-year/
[bigbois]: https://thebigbois.com/news/steam-sales-events-schedule-2027/
[nbc27]: https://www.notebookcheck.net/Valve-announces-Steam-Sales-and-Festivals-for-first-half-of-2027.1344181.0.html
[spa-winter]: https://www.steampageanalyzer.com/blog/steam-winter-sale-2026
[spa-pub]: https://www.steampageanalyzer.com/blog/how-to-publish-game-on-steam
[survey]: https://partner.steamgames.com/doc/gettingstarted/contentsurvey
[de]: https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany
[id]: https://partner.steamgames.com/doc/gettingstarted/contentsurvey/indonesia
[pcg-ai]: https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/
[gol-ai]: https://gamingonlinux.com/2026/01/valve-tweak-steam-ai-disclosure-form-for-developers-to-clarify-its-for-content-consumed-by-players
[trailer]: https://partner.steamgames.com/doc/store/trailer
[assets]: https://partner.steamgames.com/doc/store/assets/standard
[lib]: https://partner.steamgames.com/doc/store/assets/libraryassets
[eventassets]: https://partner.steamgames.com/doc/store/assets/eventassets
[impress]: https://impress.games/steam-capsule-asset-browser
[wish]: https://partner.steamgames.com/doc/marketing/wishlist
[pcgn-wish]: https://www.pcgamesn.com/steam/wishlist-categories-gifting-changes-july-2026
[gol-date]: https://www.gamingonlinux.com/2019/08/valve-confirmed-developers-now-need-to-contact-them-to-change-their-release-date/page=1/
[deck]: https://partner.steamgames.com/doc/steamdeck/compat
[pcg-deck]: https://www.pcgamer.com/uk/valve-is-reviewing-steams-whole-library-for-steam-deck-compatibility/
[ea]: https://partner.steamgames.com/doc/store/earlyaccess
[lilting]: https://lilting.ch/en/articles/steam-early-access-release-guide
[gs-refund]: https://gamespot.com/articles/steam-refund-policy-changes-have-closed-an-early-access-loophole/1100-6522898/
[demos]: https://partner.steamgames.com/doc/store/application/demos
[playtest]: https://partner.steamgames.com/doc/features/playtest
[gi-rev]: https://www.gameinformer.com/2018/11/30/valve-adjusting-revenue-share-for-steams-most-popular-games
[refunds]: https://store.steampowered.com/steam_refunds
[refund-faq]: https://help.steampowered.com/faqs/view/5FDE-BA65-ACCE-A411
