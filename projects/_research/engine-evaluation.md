# Engine and tech-stack evaluation

- Date: 2026-11-26
- Question: which engine and pipeline should the game factory standardise on, given that
  Claude Code builds the games from a text/CLI session in a Linux cloud container (no GUI
  editor), with a human directing, and we ship one polished Steam game per month?
- Method: web search (sources linked inline and listed at the end), plus a hands-on test of
  Godot headless in this container (section 3). Claims marked *(unverified)* come from model
  knowledge or a single weak source and should be checked before we rely on them.

## 1. Recommendation

**Standard stack: Godot 4.7.x with GDScript, 2D-first, GodotSteam GDExtension for Steamworks,
GUT for tests, Git LFS for binary assets, and Steam uploads from GitHub Actions with
`game-ci/steam-deploy`.**

Why:
1. **It is the only mainstream engine we proved works end to end in this container with no
   editor.** We downloaded the official Linux binary from GitHub, imported a hand-written project,
   ran a GDScript test, and exported working Linux and Windows builds headless, all in about
   15 seconds after the download (section 3).
2. **Everything is text.** `project.godot`, `.tscn` scenes, `.tres` resources, `export_presets.cfg`
   and `.gd` scripts are plain text that Claude can write and diff. A scene we wrote by hand
   loaded and passed a test. The engine is MIT-licensed with no fees
   ([godotengine.org/license](https://godotengine.org/license)).
3. **It is proven in the market where we will compete.** Godot releases on Steam went from 375
   (2023) to 819 (2024) to 1,229 (2025)
   ([GamesRadar](https://www.gamesradar.com/games/roguelike/steam-stats-for-slay-the-spire-2s-engine-godot-show-strong-signs-of-exponential-growth/)).
   Slay the Spire 2 launched in early access on 5 March 2026 on Godot and peaked at 430,456
   concurrent players
   ([PC Gamer](https://pcgamer.com/games/card-games/slay-the-spire-2-ditched-unity-for-open-source-engine-godot-after-2-years-of-development)).
   Brotato, Halls of Torment, Dome Keeper and Buckshot Roulette are other Godot hits in the
   2D or small-3D scope we would work in
   ([Godot showcase](https://godotengine.org/showcase/)).

**Runner-up: LÖVE 2D (Lua)** for purely 2D, code-only games. There is no editor at all, the
game is a zip of Lua files, the licence is zlib, and Balatro shows the ceiling
([Wikipedia: Balatro](https://en.wikipedia.com/wiki/Balatro_(video_game))). It loses to Godot
because Steamworks support comes from a small community binding (luasteam), it has no built-in
UI, scene, animation or tooling, and it has no 3D path. Choose it only if Godot's import step
becomes a problem.

**Language: use GDScript, not C#.** C# needs the .NET SDK, and the host it is downloaded from
(`builds.dotnet.microsoft.com`) is blocked in this container. Godot 4 C# projects also still
cannot export to the web
([Godot docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)),
which rules out browser demos on itch.io or Poki. Slay the Spire 2 suggests C# can work at
scale, but GDScript removes a toolchain and keeps builds to a single binary.

## 2. Comparison table

Scores: ++ strong, + fine, ~ workable with effort, − weak, −− blocker for us.

| | Godot 4.7 GDScript | Godot 4.7 C# | Unity 6 | Unreal 5 | Defold | Bevy | LÖVE | MonoGame / FNA | Phaser/PixiJS + Electron |
|---|---|---|---|---|---|---|---|---|---|
| Licence and fees (2026) | MIT, free [1] | MIT, free [1] | Personal free under $200K revenue or funding; Pro above that, +5% price from 12 Jan 2026; runtime fee cancelled [2][3] | Free up to $1M lifetime gross per product, then 5% royalty [4] | Free, Apache-derived licence, attribution required [5] | MIT/Apache-2.0 *(unverified)* | zlib *(unverified)* | MS-PL / MS-PL *(unverified)* | MIT (Phaser, PixiJS, Electron) *(unverified)* |
| 2D | ++ | ++ | + | − | ++ | + | ++ | ++ | ++ |
| 3D | + (stylised, small scope) | + | ++ | ++ | − | + (young) | −− | ~ (do it yourself) | ~ (three.js) |
| Steamworks (achievements, cloud, overlay) | ++ GodotSteam GDExtension covers the whole SDK [6]; overlay does not show when run from the editor with Forward+, but works in exported builds [6] | + Steamworks.NET (NuGet, lists Godot as its top engine) [7]; NativeAOT problems reported [7] | ++ Steamworks.NET / Facepunch [7] | ++ built-in OnlineSubsystemSteam *(unverified)* | + official extension-steam [8] | ~ bevy_steamworks, lags Bevy releases [9] | ~ luasteam *(unverified)* | + Steamworks.NET [7] | ~ steamworks.js; overlay is unreliable, and Tauri gets no overlay [10] |
| Linux / Steam Deck export | ++ native Linux export tested here (section 3) | + | + | + | + | + | + (Linux needs a bundled runtime or Proton) | + (FNA/SDL) | + Electron for Linux; Tauri on WebKitGTK |
| Headless CLI build in Linux container | ++ tested: `--headless --import / --script / --export-release` | ~ needs the .NET SDK (blocked here) | −− Personal licences cannot be activated manually or offline; headless Docker builds expect a floating licence server [11] | −− CI needs a source-built engine (tens of GB), and Linux packaging goes through RunUAT [12] | + bob.jar CLI (Java is installed) [5] | ++ `cargo build` (crates index reachable) | ++ zip the folder | ++ `dotnet build` (needs .NET) | ++ npm + electron-builder |
| Text formats Claude can edit | ++ .tscn/.tres/.godot are all text | ++ | ~ YAML scenes with GUIDs and fileIDs; fragile to hand-edit | −− .uasset/.umap are binary and Blueprints are visual; Expedition 33 used Blueprints for all gameplay [13] | + text .collection/.go files | ++ code only | ++ code only | ++ code only | ++ code only |
| Automated testing | + GUT/GdUnit4 headless with JUnit output [14]; our plain SceneTree test worked | + | + Test Framework in batchmode | ~ Automation framework | ~ | ++ cargo test | ~ busted | ++ xUnit | ++ vitest/playwright |
| Community, docs, AI model knowledge | ++ large and growing; 4.x API churn means older 3.x answers mislead | + | ++ largest | ++ | − small | ~ breaking changes every release (0.18 in Jan 2026, 0.19 since) [9] | + | + | ++ |
| 2025–26 Steam evidence | Slay the Spire 2 (2026), Backpack Battles, Halls of Torment, Brotato [15][16] | Slay the Spire 2 *(language unconfirmed)* | R.E.P.O., Megabonk (2025) [17] | Clair Obscur: Expedition 33 (2025, ~30 people) [13] | none found in our searches | Tiny Glade (Bevy ECS only, secondhand) [18] | Balatro (2024) [19] | Stardew Valley, Celeste *(older, unverified)* | Vampire Survivors started on Phaser and moved to Unity in Aug 2023 [20] |
| **Fit for the factory** | **Pick** | Fallback for a game that truly needs C# | No, because of licensing in CI | No | Niche | No (churn) | **Runner-up** | ~ | ~ (good for web-first demos) |

Notes on the rejected options:
- **Unity 6** is the strongest engine in the market (most 2025 indie hits were made with it), but
  the Personal licence cannot be activated with a manual file, and Unity's headless Docker path
  assumes a floating licence server, which is an Enterprise feature [11]. GameCI users still
  report "License is not active (com.unity.editor.headless)" [11]. Scene YAML is also hard to
  edit without the editor. Reconsider only if a human with Pro seats joins.
- **Unreal 5** has the wrong scale for 2D or one-month games: binary assets, Blueprints, and a
  huge install. Epic's own Linux quickstart assumes a source or installed engine build [12].
- **Web tech** is attractive for code-only work, but steamworks.js overlay problems [10] and
  shipping Chromium in every game are real costs. Vampire Survivors left Phaser for performance
  reasons [20]. Godot can export to the web anyway (with GDScript), so we keep the browser-demo
  option without this stack.

## 3. Hands-on test in this container (2026-11-26)

| Step | Result |
|---|---|
| `api.github.com` (latest-release API) | Blocked: "GitHub access to this repository is not enabled for this session" |
| `github.com/godotengine/godot/releases/download/...` | **Allowed.** Latest stable releases are 4.7.1 and 4.7.2. 4.7.1 was used (76 MB zip) |
| `downloads.godotengine.org`, `godotengine.org/download` | Blocked by the proxy ("no rule or network setting allows this host") |
| `Godot_v4.7.1-stable_linux.x86_64 --headless --version` | `4.7.1.stable.official.a13da4feb` |
| Hand-written `project.godot` + `main.tscn` + `main.gd`; `--headless --import` | OK |
| `--headless --script res://test.gd` (instantiate scene, assert label text) | `TEST PASS`, exit 0 |
| Export templates `.tpz` | 1.28 GB download, about 9 s. Only the Linux and Windows x86_64 templates were extracted to `~/.local/share/godot/export_templates/4.7.1.stable/` |
| `--headless --export-release "Linux"` | 2.9 s; produced `game.x86_64` + `game.pck`; the exported game ran headless and printed `main ready` |
| `--headless --export-release "Windows"` (cross-export from Linux) | 109 MB PE32+ exe with the pck embedded |
| `export_presets.cfg` written by hand | Works, but Godot logs errors unless each preset has `include_filter=""` and `exclude_filter=""` |
| .NET SDK (`builds.dotnet.microsoft.com`) | Blocked by the proxy; no dotnet in apt. Godot C# cannot be built here |
| SteamCMD (`steamcdn-a.akamaihd.net`, `media.steampowered.com`), `partner.steamgames.com` | Blocked by the proxy |
| `steamdb.info`, `gamefromscratch.com`, `godotsteam.com` | Blocked for WebFetch |
| npm registry, `index.crates.io`, `api.nuget.org` | Reachable (package registries) |
| Installed: git-lfs, java, cargo, node 22 | Present |

Resources: 4 vCPU, 15 GB RAM, 60 GB free disk, which is enough for Godot builds.

## 4. Art and audio pipeline for an AI-heavy team

**Steam rules (current as of January 2026).** Valve rewrote the AI disclosure in January 2026.
Developers disclose AI-generated content that players see, hear or interact with. AI tools used
only for development efficiency, such as code assistants, are exempt
([PC Gamer](https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/),
[VGC](https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use)).
There are two categories:
- **Pre-generated** content (made with AI before shipping) follows the same content rules as
  any other content.
- **Live-generated** content (made while the game runs) requires describing the guardrails.
  Players can report it through the overlay, and a game can be removed if those controls fail.

Claude-written code therefore needs no disclosure. Generated art, audio, voice or text that ships
in the game does.

**Copyright.** The US Copyright Office says prompts alone do not make the user the author of the
output. Protection depends on human control over the expressive elements, decided case by case
([copyright.gov, Jan 2025](https://copyright.gov/newsnet/2025/1060.html)). Purely generated key
art and characters may therefore be unprotectable, so clones could copy them.

**Practical split** (our policy proposal, not a cited rule):

| Asset | Approach |
|---|---|
| Code, shaders, UI layout, data tables, localisation drafts | Claude generates them (no disclosure needed) |
| Procedural or vector art (SVG, shapes, particles, tilemaps from code) | Claude generates in code. This is the most reliable route with no image model in the loop |
| Pixel art, sprites, backgrounds | Licensed packs (e.g. CC0 or commercial itch.io / Kenney packs *(unverified)*) or a contracted artist. AI image generation only with disclosure plus human paint-over |
| Capsule art, key art, trailer | Human artist or heavy human paint-over. These are the most visible assets and the ones most exposed to copyright and review backlash |
| SFX | sfxr-style procedural tools or licensed libraries |
| Music | Licensed or commissioned. Disclose if AI-generated |
| Fonts | OFL fonts (Google Fonts) |

Keep `assets/LICENSES.md` per project: each asset, its source URL, licence, and whether it is
AI-generated. That file feeds the Steam disclosure form directly.

## 5. Version control for binary assets

- Use Git LFS for `*.png *.wav *.ogg *.psd *.aseprite *.ttf *.glb`. Keep `.tscn`, `.tres` and `.gd` in
  normal git. Do not commit `.godot/` (the import cache, which is regenerated by `--import`).
  `git-lfs` is already installed in the container.
- GitHub LFS billing is now metered. Free and Pro accounts get 10 GiB storage and 10 GiB
  bandwidth, then $0.07/GiB-month storage and $0.0875/GiB bandwidth. Team accounts get 250 GiB
  ([GitHub docs](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)).
  CI clones count as bandwidth, so cache LFS objects in Actions.
- Never commit build outputs or export templates. Store them as CI artifacts.

## 6. CI: build and upload to Steam

Steam's CDN hosts and partner site are blocked from this container. Upload therefore runs in
**GitHub Actions** (or wherever a human allows those hosts), not in the Claude session:

1. Job `build`: download the pinned Godot binary and the needed templates from GitHub releases,
   cache them, then `godot --headless --import`, run the GUT tests
   (`godot --headless -d -s addons/gut/gut_cmdln.gd -gexit`, which exits non-zero on failure)
   [14], then `--export-release` for "Linux" and "Windows".
2. Job `deploy` (manual approval, `main` only): `game-ci/steam-deploy@v3` with the app ID and
   depot folders. Authentication is either a base64 `config.vdf` from a one-time local SteamCMD
   login, or TOTP generated from a Steam Guard shared secret. Setting TOTP makes the action
   ignore configVdf
   ([game-ci/steam-deploy](https://github.com/game-ci/steam-deploy),
   [action.yml](https://www.github.com/game-ci/steam-deploy/blob/main/action.yml)).
   Use a dedicated Steam build account that has only the "edit app metadata / publish" rights it
   needs *(Steamworks permission names unverified, because partner.steamgames.com was blocked)*.
   Upload to a beta branch, and have a human set the default branch live.
3. Native Linux depot plus Windows depot. Valve tests the native Linux build on Steam Deck first
   and falls back to Proton only if it fails
   ([GamingOnLinux](https://www.gamingonlinux.com/2022/02/valve-clarifies-how-they-test-native-linux-or-proton-for-steam-deck)).
   Test both builds on a Deck before launch.

## 7. Risks and mitigations

| Risk | Mitigation |
|---|---|
| GodotSteam's binary GDExtension lags Godot minor releases. Its changelog notes that a Godot 4.7 API change broke backwards compatibility [6] | Pin Godot per project (e.g. 4.7.x) and the GodotSteam version that matches it. Don't upgrade Godot mid-month |
| `github.com` release downloads are allowed today but `godotengine.org` is not. The policy could change | Cache the binary and templates. Ask to allowlist `downloads.godotengine.org` as a backup |
| Godot 4 API churn: model knowledge mixes 3.x and 4.x APIs | Run `--headless --check-only` / `--import` after every edit, and keep a memory of mistakes as we hit them |
| Visual polish can't be judged from a headless container | Script screenshot capture (e.g. `--write-movie` or viewport `get_image()`) and have a human review it. Treat that review as a hard gate in each iteration |
| 3D games are a weaker fit for Godot | Stay 2D or stylised low-poly 3D within the monthly scope |
| AI-asset backlash or copyright exposure | Use the asset split in section 4, track licences in `assets/LICENSES.md`, disclose honestly |
| Steam upload credentials | Store them as GitHub secrets only. Never put them in the container or the repo |
| Some evidence is weak (marked *unverified*); steamdb.info was blocked, so engine counts for other engines are missing | Allow steamdb.info and re-run the engine-share numbers before the first launch |

## 8. Sources

1. Godot licence: https://godotengine.org/license ; MIT note via PC Gamer (above). Releases: https://godotengine.org/releases/4.6/ , https://godotengine.org/releases/4.5/
2. Unity cancels the Runtime Fee (Sep 2024): https://unity.com/blog/unity-is-canceling-the-runtime-fee
3. Unity pricing updates 2026: https://unity.com/products/pricing-updates
4. Unreal licence: https://www.unrealengine.com/en-US/license ; https://www.unrealengine.com/blog/we-are-updating-unreal-engine-twinmotion-and-realitycapture-pricing-in-late-april
5. Defold licence: https://defold.com/license , https://defold.com/open
6. GodotSteam: https://github.com/GodotSteam/GodotSteam , https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/
7. Steamworks.NET NuGet: https://packages.nuget.org/packages/Steamworks.NET.AnyCPU/ ; forum on C#/NativeAOT issues: https://forum.godotengine.org/t/c-unable-to-find-an-entry-named-steamapi-init-in-dll-steam-api64-despite-having-both/83143/2 ; https://wiki.facepunch.com/steamworks/
8. Defold Steam extension: https://defold.com/extension-steam
9. Bevy 0.18: https://bevy.org/news/bevy-0-18/ ; news: https://bevy.org/news/ ; bevy-steamworks: https://docs.rs/crate/bevy-steamworks/latest/source/examples/basic.rs
10. steamworks.js: https://www.npmjs.com/package/steamworks.js ; Tauri/WebView2 overlay: https://github.com/MicrosoftEdge/WebView2Feedback/discussions/4019 ; https://dev.to/arty_prof/steamworks-ffi-node-a-steamworks-sdk-library-for-javascript-game-frameworks-15h1
11. Unity licensing: https://docs.unity3d.com/Manual/ManualActivationCmdWin.html , https://discussions.unity.com/t/unity-no-longer-supports-manual-activation-of-personal-licenses/926760 , https://docs.unity.com/en-us/engine/6000.7/manual/building-and-publishing/docker , https://github.com/game-ci/unity-orb/issues/74
12. Unreal on Linux: https://dev.epicgames.com/documentation/en-us/unreal-engine/linux-development-quickstart-for-unreal-engine ; https://gameye.com/blog/unreal-engine-5-dedicated-server-docker-container/
13. Expedition 33: https://www.unrealengine.com/en-US/developer-interviews/inside-the-development-journey-of-clair-obscur-expedition-33 ; https://80.lv/articles/sandfall-interactive-used-ue5-blueprints-for-all-gameplay-systems-in-clair-obscur
14. GUT CLI: https://gut.readthedocs.io/en/latest/Command-Line.html ; GdUnit4: https://github.com/MikeSchulze/gdUnit4 , https://github.com/MikeSchulze/gdUnit4-action
15. Godot growth and Slay the Spire 2: https://www.gamesradar.com/games/roguelike/steam-stats-for-slay-the-spire-2s-engine-godot-show-strong-signs-of-exponential-growth/ ; https://pcgamer.com/games/card-games/slay-the-spire-2-ditched-unity-for-open-source-engine-godot-after-2-years-of-development
16. Godot showcase / 2025 showreel: https://godotengine.org/showcase/ ; https://www.gamingonlinux.com/2025/11/the-2025-godot-engine-showreel-is-out
17. R.E.P.O. (Unity): https://semiworks.itch.io/repo , https://handwiki.org/wiki/Software:R.E.P.O. ; Megabonk (Unity): https://cavac.at/cavacopedia/Megabonk (wiki mirror, weak)
18. Tiny Glade / Bevy ECS (secondhand): https://mountainlabz.itch.io/nostle/devlog/809019/bevy-and-path-traced-lighting-soon-enough
19. Balatro on LÖVE: https://en.wikipedia.com/wiki/Balatro_(video_game)
20. Vampire Survivors Phaser to Unity: https://www.gamingonlinux.com/2023/07/vampire-survivors-switching-to-new-game-engine-on-august-17 , https://www.gamesradar.com/vampire-survivors-dev-asked-if-hell-ever-use-unity-again-lol-no-thank-you
21. Steam AI disclosure (Jan 2026): https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/ , https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use
22. US Copyright Office AI report Part 2: https://copyright.gov/newsnet/2025/1060.html
23. GitHub LFS billing: https://docs.github.com/en/billing/concepts/product-billing/git-lfs
24. Godot C# web export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html ; https://github.com/godotengine/godot-proposals/discussions/13076
25. Steam Deck native vs Proton: https://www.gamingonlinux.com/2022/02/valve-clarifies-how-they-test-native-linux-or-proton-for-steam-deck
