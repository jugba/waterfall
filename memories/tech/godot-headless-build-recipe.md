# Godot builds fully headless here: binary + templates from GitHub releases, then --import/--export-release

- Area: tech
- Date / source: 2026-11-26, hands-on test logged in projects/_research/engine-evaluation.md §3
- Confidence: high
- Apply when: setting up a Godot project, CI, or a fresh container.

- Download: `https://github.com/godotengine/godot/releases/download/<v>-stable/Godot_v<v>-stable_linux.x86_64.zip`
  (allowed). `downloads.godotengine.org` and `api.github.com` are blocked.
- Templates `.tpz` is 1.28 GB; extract only what you need, e.g.
  `unzip -j t.tpz 'templates/linux_release.x86_64' 'templates/windows_release_x86_64.exe' 'templates/version.txt' -d ~/.local/share/godot/export_templates/<v>.stable/`.
- `godot --headless --import` then `godot --headless --script res://test.gd` (SceneTree script, `quit(code)`)
  then `godot --headless --export-release "Linux" build/linux/game.x86_64`. Windows cross-export
  from Linux works. Whole cycle took ~15 s on 4 vCPU.
- Hand-written `export_presets.cfg` needs `include_filter=""` and `exclude_filter=""` per preset or
  Godot logs errors. Hand-written `.tscn` (format=3) loads fine.
- Pin the exact Godot version per project (4.7.1 tested; 4.7.2 exists).
