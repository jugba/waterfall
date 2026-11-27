# Game project template (Godot 4.7 + GDScript)

Copy this folder to start a new game. It contains a small playable game (title screen, a
player you can move, pause, settings) that already builds, tests and exports headless, so
each project starts on a pipeline that works and spends its month on the game.

Why this stack: `memories/tech/godot-gdscript-is-default-engine`, `projects/_research/engine-evaluation.md`.
Process: `playbooks/monthly-cycle.md` (schedule), `playbooks/steam-launch-checklist.md` (Steam),
`playbooks/marketing.md`.

## Layout

```
projects/NNN-name/
├── BRIEF.md  POSTMORTEM.md  iterations/  research/   # factory docs (see CLAUDE.md)
├── assets/              # source and marketing files: .psd/.aseprite masters, capsule art, trailer
├── build.env            # pinned GODOT_VERSION, GUT_VERSION, GAME_NAME
├── ci/github-workflow.yml   # copy to .github/workflows/ (see "CI and Steam upload")
├── .gitignore  .gitattributes   # Godot ignores; Git LFS for binary assets
├── build/               # (gitignored) exports, test-results.xml, logs
└── game/                # the Godot project (open game/project.godot in the editor)
    ├── project.godot    # 1280x800 base, canvas_items stretch, Compatibility renderer, InputMap
    ├── export_presets.cfg   # "Linux" (also used by Steam Deck), "Windows", "macOS" (universal, ad-hoc signed)
    ├── autoload/        # globals, registered in project.godot
    │   ├── settings.gd      # Settings: volumes, fullscreen, vsync, rebinding -> user://settings.cfg
    │   ├── save_game.gd     # SaveGame: JSON slots, atomic writes, format_version + _migrate()
    │   ├── audio.gd         # Audio: music cross-fade (Music bus), pooled SFX (SFX bus)
    │   ├── scene_changer.gd # SceneChanger.change_to(path): fade transition
    │   └── steam_service.gd # SteamService: GodotSteam if present, safe no-op otherwise
    ├── scenes/          # title.tscn (main scene), game.tscn, player.tscn
    ├── scripts/         # scripts for scenes/
    ├── ui/              # settings_menu, pause_menu, theme.tres (default font size 28)
    ├── assets/{art,audio,fonts}/   # in-game assets Godot imports (LFS for binaries)
    ├── tests/{unit,integration}/   # GUT tests, test_*.gd
    ├── default_bus_layout.tres     # Master, Music, SFX
    └── addons/          # gut/ is fetched by the build (gitignored); godotsteam/ goes here
```

Code rule: game code calls `SteamService`, `Settings`, `SaveGame`, `Audio` and `SceneChanger`,
never the `Steam` singleton or `get_tree().change_scene_*` directly.

## Start a new game

```bash
cp -r projects/_template projects/002-my-game
echo 002-my-game > projects/ACTIVE
```

Then:
1. Fill in `BRIEF.md` and create `iterations/001.md` (CLAUDE.md rules 4 and 8).
2. In `game/project.godot`, set `config/name` and `config/version`. In `game/export_presets.cfg`,
   set `application/product_name`. Set the title text in `scenes/title.tscn`.
3. In `build.env`, set `GAME_NAME` (the executable file name, no spaces). Change the Godot version
   only on purpose.
4. When the Steam app exists, set `game/steam/app_id` in `project.godot` (480 is Valve's test app).
5. Copy the CI workflow (see below).
6. Run the build once (see next section). It must pass before you change anything else.

Replace `scenes/game.tscn` and `scripts/player.gd` with the real game. Keep the autoloads and
menus, and restyle them.

## Build, test, export

```bash
tools/godot/build.sh projects/002-my-game                 # import + tests + Linux + Windows + macOS
tools/godot/build.sh projects/002-my-game --no-export     # import + tests only (fast loop)
tools/godot/build.sh projects/002-my-game --platform linux   # or windows | macos
GODOT=/path/to/godot tools/godot/build.sh projects/002-my-game   # use an existing binary
```

- The Godot binary and export templates are installed on first use by `tools/godot/install-godot.sh`
  from GitHub releases (binary to `~/.cache/godot/<v>/`, templates to
  `~/.local/share/godot/export_templates/<v>.stable/`). The templates download is ~1.3 GB, and only
  the Linux, Windows and macOS files are kept.
- GUT is cloned at the pinned tag by `tools/godot/fetch-gut.sh` into `game/addons/gut/`.
- The build fails if import, any test, or any export fails, or if the logs contain a script or
  parse error. Outputs go to `build/linux/<GAME_NAME>.x86_64`, `build/windows/<GAME_NAME>.exe`
  (PCK embedded, one file each), `build/macos/<GAME_NAME>.zip` (universal `<GAME_NAME>.app`), `build/test-results.xml` (JUnit) and `build/logs/`.
- Run the game: `build/linux/<GAME_NAME>.x86_64`, or open `game/project.godot` in the Godot 4.7 editor.
- Tests: `godot --headless --path game -s res://addons/gut/gut_cmdln.gd -gexit` (config in
  `game/.gutconfig.json`; add `-gselect=test_settings` to run one script). GUT fails a test on any
  unexpected engine error or `push_error`. If a test triggers an error on purpose, assert it with
  `assert_push_error("text")` or `assert_engine_error("text")`.
- `tests/` and `addons/gut/` are excluded from exports (`exclude_filter` in `export_presets.cfg`).
- Commit the `*.uid` and `*.import` files Godot generates; never commit `game/.godot/` or `build/`.
- macOS: the preset exports a universal (arm64 + x86_64) `.app` in a `.zip`, ad-hoc signed by Godot's
  built-in signer and **not notarized** (no Apple Developer ID). Players must allow it once (right-click
  > Open, or System Settings > Privacy & Security > Open Anyway). Universal/arm64 needs
  `rendering/textures/vram_compression/import_etc2_astc=true` (set in `project.godot`). Set
  `application/bundle_identifier` per game. Details: `memories/tech/godot-macos-export-unsigned-from-linux`.
- Windows `.exe` icon and version metadata are off (`application/modify_resources=false`),
  because that needs rcedit + Wine, and neither is installed. Steam shows its own icons, so this
  only matters for DRM-free builds.

## Polish foundations included

| Need | Where | Notes |
|---|---|---|
| Steam Deck UI | `project.godot` | Base 1280x800 (Deck native), `canvas_items` + `expand` stretch, font size 28 or larger. Keep text readable at 1280x800. |
| Controller | InputMap | Every action has keyboard and controller bindings, on any pad (`device=-1`). Menus take focus on open, so they work without a mouse. `tests/unit/test_input_map.gd` enforces this. |
| Rebinding | `Settings.rebind()`, settings menu | Rebinding keyboard keeps controller bindings and the reverse. Stored as plain data, not Objects. |
| Volume / display | Settings menu | Master, Music and SFX sliders. Fullscreen. V-Sync. Saved on close. |
| Pause | `ui/pause_menu.tscn` | Esc, P or Start. It also auto-pauses on focus loss and when the Steam overlay opens. |
| Save / load | `SaveGame` | Atomic writes. Versioned for migrations. Corrupt or missing saves return `{}`. |
| Transitions | `SceneChanger.change_to()` | Fade. Blocks input while it runs and unpauses the tree. |
| Audio | `Audio` | Music cross-fade. 12-voice SFX pool with pitch jitter. |

New gameplay actions: add them in Project Settings > Input Map (with a key AND a controller
binding), then add them to `Settings.REBINDABLE_ACTIONS` so they appear in the controls menu.

## Steam

### Adding GodotSteam (not included; it could not be downloaded in the Claude container)

`SteamService` works without it: `SteamService.available` is `false` and every call is a no-op.
To enable Steam features, do this once per project on a machine with normal internet:

1. Download the **GDExtension** build of GodotSteam for Godot 4.7. The project moved from GitHub
   to Codeberg: https://codeberg.org/godotsteam/godotsteam (docs: https://godotsteam.com). Both
   hosts are blocked in the Claude container, so a human (or CI) has to fetch it.
2. Copy its `addons/godotsteam/` folder into `game/addons/godotsteam/`. The folder holds the
   `.gdextension` file plus `.so`/`.dll` and the Steam API libraries. `.so`/`.dll` are LFS-tracked
   by `.gitattributes`, so run `git lfs install` first.
3. Run `tools/godot/build.sh` and check that the exports contain `libsteam_api.so` /
   `steam_api64.dll` next to the executable. Godot copies GDExtension dependencies on export.
4. Check the method names in `autoload/steam_service.gd` (`steamInitEx`, `setAchievement`,
   `storeStats`, `setRichPresence`, `activateGameOverlayToStore`) against that GodotSteam
   version's docs. They come from the 4.x docs and are **unverified** here.
5. To test locally outside Steam, put the App ID in `game/steam_appid.txt` (gitignored). Steam must
   be running.

`tests/unit/test_steam_service.gd` covers the no-op path. It skips itself if GodotSteam is installed.

### Steamworks setup (human, on partner.steamgames.com; blocked from the container)

- Create two depots: Linux (OS = Linux, used by Steam Deck) and Windows (OS = Windows).
- Launch options: Linux `<GAME_NAME>.x86_64`, Windows `<GAME_NAME>.exe`.
- Steam Cloud: use Auto-Cloud with root `LinuxHome` / `WinAppDataRoaming` and the path
  `godot/app_userdata/<config/name>/saves` (`SaveGame` writes `user://saves`). If the project
  later sets `application/config/use_custom_user_dir`, update this path. *(Path is unverified:
  check it on a real install.)*
- Achievements: create them under Stats & Achievements, then call
  `SteamService.unlock_achievement("API_NAME")`.
- Valve tests the native Linux build on Deck first, so test both builds on a Deck
  (`memories/tech/steam-upload-ci-steam-deploy-action`). `SteamService.is_steam_deck()` detects a Deck.
- The full launch timeline is in `playbooks/steam-launch-checklist.md`. Submit the build at
  least 4 weeks before launch (`memories/process/steam-review-lead-time-three-weeks`).

### CI and Steam upload

Steam's hosts are blocked from the Claude container (`memories/tech/container-network-blocks-steam-hosts`),
so uploads run in GitHub Actions with `game-ci/steam-deploy@v3`:

```bash
mkdir -p .github/workflows
sed -e 's#projects/NNN-name#projects/002-my-game#g' -e 's#NNN-name#002-my-game#g' -e 's#NNN-v#002-v#g' \
  projects/_template/ci/github-workflow.yml > .github/workflows/002-my-game.yml
```

- On every push or PR that touches the project, CI imports, tests and exports, then uploads the
  builds and the JUnit results as artifacts.
- On a tag `002-v<version>`, the `deploy` job waits for approval in the `steam` environment,
  then uploads the Linux and Windows depots to the Steam **beta** branch. A human sets the build live.
- Secrets and variables to configure (names only; values never go in the repo):
  `secrets.STEAM_USERNAME`, `secrets.STEAM_CONFIG_VDF` (base64 `config.vdf` from one local
  `steamcmd +login`), `vars.STEAM_APP_ID`, `vars.STEAM_DEPOT_LINUX`, `vars.STEAM_DEPOT_WINDOWS`.
  Also create an Environment `steam` with a required reviewer.
- The workflow is a template and has not been run on GitHub yet. Its first real run is part of
  the first game project.
