# Market check: tight 2D rhythm platformer ($9.99, 2–3 h)

- Project: 004-rhythm-platformer · Written 2026-11-27 (subagent desk study)
- Question: in our 12-month Steam data, how do platformers do, and rhythm/music platformers specifically? What would a Rayman-Legends-style, music-synced, single-player 2D platformer face?
- Citations:
  - **[C]** = `projects/001-steam-market-research/research/processed/candidates.csv`, the 30,708 releases from 2025-11-26 to 2026-11-26 with their top ~7 search tags.
  - **[G]** = `projects/001-steam-market-research/research/processed/games_analyzed.csv`, the 744 games with ≥1k reviews plus the success/core/revenue columns.
  - **[R]** = `research/processed/tag_combo_rates.csv` (this project), produced by `research/scripts/platformer_check.py` from [C] and [G].
  - **[GG]** = `research/processed/genre_games.csv`, every ≥1k-review game with a platformer, rhythm, music or runner tag (same script).
  - **[GM]** = `research/processed/genre_mid.csv`, platformer + rhythm releases with ≥50 reviews, and rhythm releases with ≥100 reviews (same script).
  - **[D]** = `research/processed/demo_presence.csv`, built by `research/scripts/demo_check.py` from Steam appdetails saved to `research/raw/appdetails_genre/`.
  - **[S]** = Steam store endpoints for older games, fetched 2026-11-27 and saved to `research/raw/comparables/`:
    - appdetails: `https://store.steampowered.com/api/appdetails?appids=<id>`, which gives `recommendations.total`, the all-language review count;
    - review histogram: `https://store.steampowered.com/appreviewhistogram/<id>`, whose lifetime rollups give the % positive.
- Definitions follow project 001 ([M:market/small-scope-steam-hit-base-rate-under-1-percent]):
  - **Success** = ≥1k search reviews and ≥80% positive.
  - **Core** = a success that is also: not from a major publisher, paid, ≤$20, ≤10 GB, and with its first review no more than 45 days before release.
  - **Lift** = the tag's rate divided by the rate across all releases.
- Revenue figures are **estimates**: all-language reviews × 20–60 × list price × 0.5, per [M:marketing/boxleiter-multiplier-about-30x-for-recent-games]. Any single figure is ±50% or worse.

## TL;DR

- **Platformers are the most crowded genre we can pick.**
  - 3,755 releases (12% of all) carry a platformer tag. Only 5.2% of them reach 100 reviews, against 11.1% for all releases.
  - The core-hit lift is **0.39×** for any platformer tag and **0.19×** for 2D Platformer.
  - Not one core hit in the window is a pure, linear 2D platformer. Each platformer hit adds a second genre (metroidvania, incremental, puzzle, collectathon) or rides a brand or licence.
- **Rhythm is healthier than average.**
  - Rhythm has 361 releases, a success lift of 1.6× and a core lift of 1.36×. Music has 151 releases, a success lift of 3.8× and a core lift of 2.4×.
  - Rhythm + Cute/Colorful has 73 releases and a 3.4× core lift, but on only 2 hits.
  - Rhythm hits pair the beat with another genre: brawler, visual novel, minigames, roguelike.
- **Platformer + Rhythm is empty, not proven.**
  - 52 releases in 12 months, 40 of them with zero reviews.
  - The best is Ultimate Drummer, a 3D game with 184 reviews. The best 2D one is B.I.R.D. with 11.
  - Older games show a ceiling of about 2–8k reviews for linear rhythm runners and platformers (BIT.TRIP RUNNER, Melody's Escape, Thumper, Sayonara Wild Hearts). Games break out only with a level editor or UGC (Geometry Dash, A Dance of Fire and Ice) or with movement plus charm and no strict rhythm (Pizza Tower).
- **Verdict: medium-high market risk.** The best angle is "one-button-plus, music-is-the-level", aimed at the rhythm audience rather than the platformer audience. Price $9.99, 2.5–3.5 h of content plus replay (ranks), and lead with the tags Rhythm, Music, Platformer, Colorful, Cute, Fast-Paced. Details are in §4.

## 1. What the 12-month data says

### 1.1 Rates by tag and combination [R]

Base: 30,708 releases, of which 11.1% reached 100 reviews, 530 were successes (17.3 per 1,000) and 250 were core hits (8.1 per 1,000).

| Tag set | Releases | ≥100 rev (share) | ≥1k | Successes | Core | Core /1000 | Core lift | Success lift |
|---|---|---|---|---|---|---|---|---|
| **All releases** | 30,708 | 3,405 (11.1%) | 745 | 530 | 250 | 8.1 | 1.00 | 1.00 |
| 2D Platformer | 1,893 | 82 (4.3%) | 10 | 7 | 3 | 1.6 | **0.19** | 0.21 |
| Platformer | 1,522 | 99 (6.5%) | 11 | 10 | 7 | 4.6 | 0.56 | 0.38 |
| Precision Platformer | 577 | 30 (5.2%) | 2 | 2 | 1 | 1.7 | 0.21 | 0.20 |
| Puzzle Platformer | 670 | 27 (4.0%) | 2 | 2 | 1 | 1.5 | 0.18 | 0.17 |
| 3D Platformer | 1,050 | 53 (5.0%) | 7 | 6 | 6 | 5.7 | 0.70 | 0.33 |
| Any platformer tag (5 above) | 3,755 | 196 (5.2%) | 24 | 19 | 12 | 3.2 | **0.39** | 0.29 |
| Runner | 340 | 9 (2.6%) | 2 | 1 | 1 | 2.9 | 0.36 | 0.17 |
| **Rhythm** | 361 | 43 (11.9%) | 12 | 10 | 4 | 11.1 | **1.36** | 1.60 |
| **Music** | 151 | 32 (21.2%) | 10 | 10 | 3 | 19.9 | **2.44** | 3.84 |
| Rhythm or Music | 415 | 48 (11.6%) | 13 | 11 | 4 | 9.6 | 1.18 | 1.54 |
| Music-Based Procedural Generation | 49 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| **Platformer (any) + Rhythm/Music** | **52** | **2 (3.8%)** | 0 | 0 | 0 | 0 | **0** | 0 |
| Platformer (any) + Rhythm | 48 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| Platformer (any) + Cute or Colorful | 438 | 28 (6.4%) | 3 | 3 | 2 | 4.6 | 0.56 | 0.40 |
| Platformer (any) + Cartoony or Hand-drawn | 161 | 7 (4.3%) | 0 | 0 | 0 | 0 | 0 | 0 |
| Platformer (any) + Short | 7 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| Platformer (any) + Fast-Paced | 47 | 6 (12.8%) | 2 | 2 | 2 | 42.6 | 5.2 (n=2) | 2.47 |
| Rhythm/Music + Cute or Colorful | 73 | 15 (20.5%) | 5 | 3 | 2 | 27.4 | 3.4 (n=2) | 2.38 |
| Rhythm/Music + Action | 140 | 12 (8.6%) | 3 | 1 | 1 | 7.1 | 0.88 | 0.41 |
| Runner + Rhythm/Music | 20 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| Cute | 2,175 | 226 (10.4%) | 40 | 31 | 17 | 7.8 | 0.96 | 0.83 |
| Colorful | 1,349 | 66 (4.9%) | 11 | 9 | 5 | 3.7 | 0.46 | 0.39 |
| Short | 127 | 17 (13.4%) | 1 | 1 | 1 | 7.9 | 0.97 | 0.46 |
| Fast-Paced | 186 | 24 (12.9%) | 7 | 6 | 4 | 21.5 | 2.64 | 1.87 |

Caveats:
- Tags are the top ~7 per game only.
- Hit counts per tag are small (1–12), so every lift above has wide error bars.
- "Music" also catches non-rhythm music games, for example Mixtape, a narrative walking sim.
- Q4 2026 releases are right-censored.

How crowded the platformer genre is ([C], list prices as shown in search):
- The median platformer-tagged release costs **$4.99**.
- 51% are priced at $0.01–4.99, and 13% are free.
- The mid-tier is also thin. Among 2D-style platformers with 300–999 reviews, the good-scoring ones are mostly metroidvanias, puzzle or cozy hybrids and brand revivals. One example: *Rayman: 30th Anniversary Edition* had 494 reviews at 65%.

### 1.2 Every platformer hit in the window (≥1k reviews, ≥80%) [GG]

Columns:
- Reviews = search reviews (≈English) / all-language total.
- Revenue = estimated net, all-language × 20–60 × price × 0.5.
- Core = ✓ if it passes the core-target filter.

| Game | Released | Price | Reviews | % | Core | Est. net revenue | Top tags | What it really is |
|---|---|---|---|---|---|---|---|---|
| Castlevania: Belmont's Curse | 2026-10-14 | $29.99 | 6,075 / 10,118 | 86 | – (Konami) | $3.0–9.1M | Action, Platformer, Metroidvania, 2D Platformer | Big IP |
| Mina the Hollower | 2026-05-28 | $19.99 | 6,461 / 8,902 | 89 | ✓ | $1.8–5.3M | Platformer, Pixel Graphics, Action-Adventure, Top-Down | Studio brand (Yacht Club); top-down Zelda-like |
| MIO: Memories in Orbit | 2026-01-20 | $19.99 | 2,285 / 5,241 | 87 | – (Focus) | $1.0–3.1M | Platformer, Metroidvania, Atmospheric | Metroidvania |
| VHOLUME | 2026-08-21 | $8.00 | 3,340 / 5,135 | 97 | ✓ | $0.41–1.2M | Platformer, First-Person, Parkour, 3D Platformer, Runner | 3D first-person parkour runner |
| Idols of Ash | 2026-04-09 | $2.99 | 2,710 / 3,828 | 97 | ✓ | $0.11–0.34M | Horror, First-Person, Parkour, 3D Platformer | Horror parkour |
| Denshattack! | 2026-07-15 | $19.99 | 2,507 / 3,736 | 98 | ✓ | $0.75–2.2M | Trains, Fast-Paced, Arcade, Anime, Colorful, 3D Platformer | Novel vehicle + movement |
| MONOMOON | 2026-11-11 | $11.99 | 1,324 / 2,564 | 98 | ✓ | $0.31–0.92M | Metroidvania, Puzzle, Puzzle Platformer, Pixel Graphics | Puzzle metroidvania |
| Funi Raccoon Game | 2026-03-13 | $11.99 | 1,955 | 99 | ✓ | $0.23–0.70M | Platformer, 2.5D, 3D Platformer, Collectathon | Charm-led collectathon |
| CICADAMATA" | 2026-08-21 | $9.99 | 1,875 | 96 | ✓ | $0.19–0.56M | Fast-Paced, Shooter, First-Person, 3D Platformer | Movement shooter |
| Terrible Lizards | 2026-10-29 | $24.99 | 1,569 | 82 | – (>$20) | $0.39–1.2M | Platformer, Horror, Dinosaurs | Horror adventure |
| Terminator 2D: NO FATE | 2025-12-12 | $29.99 | 1,539 | 84 | – (>$20) | $0.46–1.4M | Action, Arcade, Side Scroller, 2D Platformer, 1990's | Licence, retro |
| IGTAP: an Incremental Game That's Also a Platformer | 2026-09-21 | $9.99 | 1,417 | 80 | ✓ | $0.14–0.42M | Precision Platformer, 2D Platformer, Incremental, Automation | Genre mash-up hook in the title |
| Twin Shot Deluxe | 2026-04-30 | $9.99 | 1,388 | 96 | ✓ | $0.14–0.42M | Action, Platformer, Arcade, Cute, 2D Platformer | Nitrome remake, single-screen arcade |
| JUMP KING QUEST | 2026-05-25 | $14.99 | 1,338 | 88 | – (prior reviews) | $0.20–0.60M | Precision Platformer, Difficult, PvP, 2D Platformer | Sequel to a streamer hit |
| Cirno! Lifts a Boulder | 2026-03-11 | $5.99 | 1,227 | 98 | ✓ | $0.07–0.22M | Platformer, 3D Platformer, Collectathon | Touhou fan IP, joke premise |
| Kugayama Shiori's Death Diary | 2026-04-29 | $24.99 | 1,140 | 94 | – (>$20) | $0.28–0.85M | Visual Novel, 2D Platformer | Visual novel, mis-tag |
| Planet of Lana II | 2026-03-05 | $19.99 | 1,052 | 92 | – (44 GB) | $0.21–0.63M | Cinematic, Cute, Puzzle Platformer, Cozy | Sequel, cinematic |
| TOEM 2 | 2026-09-29 | $19.99 | 1,024 | 93 | ✓ | $0.20–0.61M | Platformer, Puzzle, Cozy, Wholesome | Sequel; photo adventure |
| Shattered Divinities | 2026-05-14 | $9.99 | 1,002 | 93 | ✓ | $0.10–0.30M | Action, RPG, Platformer, Metroidvania | Metroidvania |

Misses with ≥1k reviews but under 80%: s&box (48%), Goblin Vyke (70%), Zad Archery (75%), Agreeee (75%), plus the free MMOs Soul's Remnant and Granblue Fantasy.

**Read:**
- Of 3,182 releases with a 2D-style platformer tag, only 9 became core hits.
- None of the 9 is a linear, level-based 2D action platformer sold on movement feel.
- The closest is **Twin Shot Deluxe**, a remake of a known Nitrome game.

### 1.3 Every rhythm / music hit in the window [GG]

| Game | Released | Price | Reviews | % | Core | Est. net revenue | Top tags | Hook |
|---|---|---|---|---|---|---|---|---|
| Rhythm Doctor | 2025-12-06 | $19.99 | 8,374 / 25,704 | 98 | – (EA grad) | $5.1–15.4M | Music, Story Rich, Rhythm, Pixel Graphics, Level Editor | One-button "7th beat", editor |
| Dead as Disco | 2026-05-05 | $24.99 | 9,890 / 15,505 | 97 | – (>$20, EA) | $3.9–11.6M | Music, Hack and Slash, Rhythm, Beat 'em up | Rhythm brawler, licensed songs |
| Mixtape | 2026-05-07 | $19.99 | 3,961 / 8,090 | 85 | – (Annapurna, 12 GB) | $1.6–4.9M | Adventure, Music, Walking Simulator, Narrative | Not rhythm; soundtrack narrative |
| UNBEATABLE | 2025-12-09 | $27.99 | 6,457 / 7,499 | 93 | – (>$20) | $2.1–6.3M | Music, Story Rich, Rhythm, Arcade, Anime | Anime rhythm adventure, a long-hyped demo |
| Yunyun Syndrome!? Rhythm Psychosis | 2026-04-23 | $16.99 | 1,767 / 4,811 | 91 | ✓ | $0.82–2.5M | Music, Psychological Horror, Rhythm, Visual Novel, Cute | Rhythm + visual novel (Needy Streamer spin-off) |
| Rhythia | 2026-02-20 | $3.99 | 1,713 / 2,991 | 84 | ✓ | $0.12–0.36M | Casual, Point & Click, Rhythm, Multiplayer | osu!-like with community maps |
| Ratatan | 2026-10-14 | $34.99 | 1,054 / 2,744 | 85 | – (EA grad) | $0.96–2.9M | Music, Roguelike, Rhythm, Cute | Patapon successor |
| Afterbeat (Project Arrhythmia) | 2026-10-08 | $14.99 | 1,809 / 2,585 | 96 | – (EA grad) | $0.39–1.2M | Music, Rhythm, Local Co-Op, Bullet Hell, Level Editor | Just Shapes & Beats-like, editor |
| Bits & Bops | 2025-12-09 | $15.99 | 1,987 | 92 | ✓ | $0.32–0.95M | Action, Music, Rhythm, Cartoon, Minigames, Wholesome | Rhythm Heaven-style cartoon minigames |
| Dancing Line | 2026-05-31 | $9.99 | 1,904 | 92 | ✓ | $0.19–0.57M | Casual, Music, Rhythm, 3D, Colorful, Abstract | Mobile hit port, one-button line runner |
| In Falsus | 2026-09-09 | $39.99 | 1,566 | 91 | – (>$20) | $0.63–1.9M | Music, Story Rich, Rhythm, Visual Novel, Anime | Arcaea developer (lowiro) brand |

Misses with ≥1k reviews: PLATiNA :: LAB (53%) and the free hololive Dreams (63%).

Below 1k reviews, from [GM]:
- **Melody's Escape 2** (2026-06-12, rhythm runner, 317 reviews, 94%) is the only rhythm *runner* in the window with more than 300 reviews.
- **Nocturne** (818, 98%), **BAZOOKA: Rhythm Game** (727, 98%) and **Rock Band Simulator** (776, 98%) are well-reviewed mid-tier games.

**Platformer + rhythm in the window, all 52 releases [GM]:** the top games by review count are
- Ultimate Drummer (3D, 184 reviews, $5.99);
- CYBERMATRIX (first-person rhythm roguelike, 135);
- Beat, Heart, Beat (EA 2D rhythm platformer with editor, 92, $8.99);
- Beat of Rebellion (33).

Every 2D rhythm platformer we found is at **≤12 reviews**: B.I.R.D. (11), SURI: The Seventh Note (10, $19.99), Miser King (12) and Sidechain (0). This sub-genre has no breakout and also no visible incumbent.

### 1.4 Demos and trailers [D]

Paid releases with ≥100 reviews; demo = a demo still listed on the store on 2026-11-27.

| Group | Band | Games | Demo still live | Avg. trailers |
|---|---|---|---|---|
| 2D platformer tags | hit (≥1k, ≥80%) | 14 | 29% | 2.7 |
| 2D platformer tags | 300–999 | 41 | 41% | 2.2 |
| 2D platformer tags | 100–299 | 66 | 27% | 1.9 |
| Rhythm tag | hit | 10 | 30% | 2.8 |
| Rhythm tag | 100–299 | 13 | 54% | 1.8 |

**Read:**
- A post-launch demo flag does not separate hits from misses, because most games pull their demo at launch, so this says nothing about Next Fest.
- Hits do carry more trailers (2.7–2.8 vs 1.8–1.9).
- Known pre-launch demo stories, from general knowledge and **unverified**: UNBEATABLE's [white label] demo built a following for years before launch; Dead as Disco and Bits & Bops ran public demos in Next Fest. Next Fest participation is not in our dataset.

## 2. Older comparables (outside the window)

Data:
- Reviews are the all-language `recommendations.total` and % positive is from the lifetime histogram rollups, both from [S] on 2026-11-27.
- "Price now" is the current US list price.
- Launch prices are from memory unless marked; **(unv.)** = unverified.
- Revenue is a rough ceiling: reviews × 20–60 × current list price × 0.5. Older games sold mostly at a discount and used higher review multipliers, so treat it as order of magnitude only.

| Game (Steam appid) | Steam release | Launch price | Price now | Reviews | % | Rough net | Why it worked / didn't |
|---|---|---|---|---|---|---|---|
| BIT.TRIP RUNNER (63710) | 2011-02-28 | $9.99 (unv.) | $9.99 | 1,828 | 87 | $0.2–0.6M | Auto-runner, each action on the beat; Wii-first |
| Runner2: Future Legend of Rhythm Alien (218060) | 2013-02-26 | $14.99 (unv.) | $14.99 | 1,636 | 94 | $0.25–0.7M | Charm + music-synced obstacles; on every console |
| Runner3 (516130) | 2018-05-22 | $19.99 (unv.) | $19.99 | **263** | **75** | <$0.2M | Sequel bloat, harder, so **the series declined** |
| Melody's Escape (270210) | 2016-05-20 (from EA) | $9.99 (unv.) | $9.99 | 4,337 | 92 | $0.4–1.3M | "Your own music" auto-runner; procedural |
| Melody's Escape 2 (in window) | 2026-06-12 | ~$14.99 (unv.) | – | 317 (search) | 94 | ~$0.1M | Sequel to the same idea, much smaller |
| Geometry Dash (322170) | 2014-12-22 | $4.99 (unv.) | $4.99 | **618,534** | 92 | outlier | Mobile-first, one-button, **level editor/UGC**, YouTube "impossible level" culture |
| A Dance of Fire and Ice (977950) | 2019-01-24 | $4.99 (unv.) | $5.99 | 80,243 | 93 | $4.8–14M | One-button rhythm path, Workshop levels, huge in Asia |
| Thumper (356400) | 2016-10-10 | $19.99 | $19.99 | 4,078 | 92 | $0.8–2.5M | "Rhythm violence", VR halo, art-forward |
| Sayonara Wild Hearts (1122720) | 2019-12-12 (PC) | $12.99 | $12.99 | 8,058 | 97 | $1.0–3.1M | Pop-album-as-game, 1–2 h, Annapurna + Apple Arcade |
| Just Shapes & Beats (531510) | 2018-05-31 | $19.99 | $19.99 | 24,331 | 97 | $4.9–15M | Rhythm bullet-hell, **co-op**, licensed chiptune |
| Crypt of the NecroDancer (247080) | 2015-04-23 (from EA) | $14.99 | $14.99 | 23,676 | 95 | $3.6–11M | Rhythm + roguelike, Danny Baranowsky soundtrack |
| Rift of the NecroDancer (2073250) | 2025-02-05 | $19.99 | $19.99 | 6,262 | 94 | $1.3–3.8M | Rhythm + brand spin-off |
| Melatonin (1585220) | 2022-12-15 | $14.99 (unv.) | $14.99 | 7,620 | 94 | $1.1–3.4M | Rhythm Heaven-like, cozy art, short |
| Muse Dash (774171) | 2019-06-19 | $2.99 | $2.99 | 117,749 | 89 | $3.5–11M + DLC | Anime runner-rhythm, cheap base + DLC packs; mostly Asian buyers |
| Spinch (794240) | 2020-09-03 | $14.99 | $14.99 | **140** | 70 | ~$0 | Gorgeous, psychedelic, hard 2D platformer, so art alone **failed** |
| Rayman Origins (207490) | 2012-03-29 | $19.99 (unv.) | $9.99 | 5,883 | 94 | – | Ubisoft brand |
| Rayman Legends (242550) | 2013-09-03 | $39.99 (unv.) | $19.99 | 11,577 | 89 | – | Ubisoft brand; music levels are its most-clipped content |
| Pizza Tower (2231450) | 2023-01-26 | $19.99 | $19.99 | 67,026 | 98 | $13–40M | Movement speed + cartoon charm + escape-timer chases; years of dev-log hype |
| Celeste (504230) | 2018-01-25 | $19.99 | $19.99 | 134,890 | 97 | outlier | Precision + story + assist mode |
| Super Meat Boy (40800) | 2010-11-30 | $14.99 | $14.99 | 30,448 | 93 | – | Precision; 2010 market |
| Hi-Fi RUSH (1817230) | 2023-01-25 | $29.99 (unv.) | $39.99 | 27,655 | 97 | – | Major (Bethesda); shadow-drop |

**Read:**
- Linear rhythm runners and platformers with no level editor and no co-op cluster at **2–8k lifetime reviews**: BIT.TRIP, Melody's Escape, Thumper, Sayonara, Melatonin. That is a decent indie result, roughly $0.3–3M over many years.
- Sequels of the pure "runner" format shrank (Runner3, Melody's Escape 2).
- The big numbers come from three sources:
  - (a) UGC and level editors: Geometry Dash, ADOFAI, Rhythm Doctor;
  - (b) co-op: Just Shapes & Beats;
  - (c) movement + charm with no strict rhythm: Pizza Tower, Celeste.
- Art alone fails (Spinch).

## 3. What the hits have that the misses lack

| Factor | Hits | Misses / 2D rhythm platformers in the window | Source |
|---|---|---|---|
| **Hook clarity** | The pitch fits in one line and often in the title: "IGTAP: an Incremental Game That's Also a Platformer", "Rhythm Psychosis", "Bits & Bops". Rhythm hits name **what the beat controls** (punches, notes, a line, a heart monitor). | 2D rhythm platformers market "music platformer" with no clear verb: is the jump on the beat, the level on the beat, or both? | [GG], [GM] |
| **Second genre or system** | Every platformer core hit is a hybrid: metroidvania, incremental, puzzle, collectathon, first-person parkour. Rhythm hits add a brawler, visual novel, roguelike or minigames. | Plain "2D Platformer" is 0.19× and "Precision Platformer" 0.21×. | [R] |
| **Length** | Median playtime of genre hits is ~3–5 h (SteamSpy where present). Short rhythm hits like Bits & Bops (4 h) and Dancing Line justify themselves with ranks and replay. Sayonara (~1.5 h) is the exception and had Annapurna behind it. | Platformer + Short: 7 releases, no hits. A 2–3 h game risks refunds ([M:marketing/steam-refund-two-hours-short-games]). | [GG], [R] |
| **Price** | Core genre hits cost $8–19.99; median ~$11.99. $9.99 hits exist (Twin Shot Deluxe, IGTAP, Dancing Line, CICADAMATA). | The median platformer release is $4.99 and 51% are under $5, the tier with 1/6 the hit rate ([M:market/small-scope-price-7-to-15-dollars-never-under-5]). | [C], [G] |
| **Art style** | Hits read at thumbnail size with a strong identity: Cute/Colorful in rhythm (3.4× lift), cartoon (Bits & Bops), crisp pixel art (Mina, MONOMOON). | Colorful alone is 0.46× and Cartoony 0.22×. Style is necessary but not a hook (Spinch). | [R] |
| **Brand / IP** | 8 of the 19 platformer hits had a brand, IP, known studio or were sequels (Konami, Yacht Club, Nitrome, Touhou, Terminator, Jump King, Planet of Lana, TOEM). | A new studio has no brand; the hook must carry it. | [GG] |
| **Demo / Next Fest** | Our data can't tell. A post-launch demo is live for ~30% of hits and misses alike. UNBEATABLE, Dead as Disco and Bits & Bops had high-profile pre-launch demos (unverified). | – | [D] |
| **Video-friendliness** | Hits have more trailers (2.7–2.8 vs 1.8–1.9). Rhythm is inherently clip-able: audio + visual sync reads in 5 seconds, and Rayman Legends' music levels and Geometry Dash circulate as clips. | Platformers without a visible gimmick are indistinguishable in a feed. | [D]; [M:marketing/short-form-video-is-primary-free-channel] |

## 4. Verdict

**Market risk: medium-high.**
- *Platformer* is a saturated genre: 0.19–0.39× core lift, 3,755 releases a year, median price $4.99.
- *Rhythm* is a healthy niche: 1.36× core lift, rising to 3.4× with Cute/Colorful (small n).
- The *intersection* is an unvalidated gap: 52 releases, none above 184 reviews. Older proof sits at 2–8k reviews for linear games.
- A competent but generic "pretty 2D platformer with music" would land in the 10–300-review bucket.

**Best angle.** Position it as a **rhythm game you play with platformer movement**, not a platformer with a good soundtrack. That sells into the healthier audience, Rhythm/Music buyers, and away from the saturated one.
- The level *is* the song: every hazard, platform and enemy moves on the beat, as in the Rayman Legends music levels and Runner2.
- Movement stays free (not an auto-runner), but on-beat actions are rewarded with speed, combos and juice.
- One short clip has to show it, with no explanation needed.

**Suggested price:** **$9.99** with a 10–15% launch discount.
- It sits in the healthy band, below the $15–20 rhythm hits, and above the $4.99 platformer mass.
- $12.99 only if content reaches about 4 h.

**Length:** 2.5–3.5 h for a first clear (about 20–25 levels or "tracks"), plus rank/score replay and a harder remix of each track.
- This keeps value above the 2-hour refund line.
- It matches the 3–5 h median of the genre's hits.

**Tags, in priority order:** Rhythm, Music, Platformer, 2D Platformer, Colorful, Cute, Fast-Paced, Singleplayer, Great Soundtrack, Hand-drawn or Cartoony.
- Steam orders tags by votes, so seed the first four on the store page.
- Avoid leading with Precision Platformer and Difficult (0.21×); they are also the wrong audience for "charm".

**Three differentiation ideas:**
1. **A song-shaped level structure the trailer can show.**
   - Each level is one track: verse is the run, chorus is a set-piece chase (Pizza Tower-style escape), and the drop is a boss beat-off.
   - The visible "the whole world dances" moment is the hook clip and the capsule.
   - Name the verb in the title or tagline, for example "*every jump is a note*".
2. **The player's on-beat movement adds instruments.**
   - Landing on the beat adds a layer (drums → bass → melody), so good play literally sounds better.
   - This gives free-movement platforming a rhythm-game skill ceiling without an auto-runner.
   - It is also a strong 10-second before/after clip.
3. **Replay and community without a full editor.**
   - S/A/B ranks per track, a "remix" (mirrored, double-time) version of each level, and online leaderboards.
   - A level editor is the proven breakout lever (Geometry Dash, ADOFAI, Rhythm Doctor), but it is a cut-list item for a one-month scope.
   - Design the level data so an editor can ship as a free update if the game lands.

Supporting choices from memory:
- Single-player, ≤1 GB build, Tuesday–Thursday launch ([M:market/small-scope-hits-are-small-builds-single-player-3-to-9-hours], [M:market/release-tuesday-to-thursday-not-weekends]).
- Test the hook with short-form clips before production ([M:marketing/short-form-video-is-primary-free-channel]).

## Sources

- Project 001 data:
  - `projects/001-steam-market-research/research/processed/candidates.csv`
  - `projects/001-steam-market-research/research/processed/games_analyzed.csv`
  - `projects/001-steam-market-research/research/processed/tag_opportunity.csv`
  - `projects/001-steam-market-research/research/raw/tags/populartags_english.json`
- This study's derived data, made by `research/scripts/platformer_check.py` and `research/scripts/demo_check.py`:
  - `research/processed/tag_combo_rates.csv`
  - `research/processed/genre_games.csv`
  - `research/processed/genre_mid.csv`
  - `research/processed/demo_presence.csv`
- Steam endpoints, fetched 2026-11-27; raw copies are in `research/raw/comparables/` and `research/raw/appdetails_genre/`:
  - `https://store.steampowered.com/api/appdetails?appids=<id>`
  - `https://store.steampowered.com/appreviewhistogram/<id>`
  - `https://store.steampowered.com/api/storesearch/?term=<name>`
- Store pages: https://store.steampowered.com/app/63710, /218060, /516130, /270210, /322170, /977950, /356400, /1122720, /531510, /247080, /2073250, /1585220, /774171, /794240, /207490, /242550, /2231450, /504230, /40800, /1817230
- Revenue method: memories/marketing/boxleiter-multiplier-about-30x-for-recent-games.md
- Unverified, from general knowledge: launch prices marked (unv.), and the pre-launch demo histories of UNBEATABLE, Dead as Disco and Bits & Bops.
