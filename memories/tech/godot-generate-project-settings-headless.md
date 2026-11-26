# Let Godot write InputMap and bus layouts (headless script + ProjectSettings.save()), and set joypad events to device -1

- Area: tech
- Date / source: 2026-11-26, building projects/_template/game/project.godot
- Confidence: high
- Apply when: adding input actions, audio buses or other Object-valued settings without the editor.

InputMap entries in `project.godot` are long `Object(InputEventKey, ...)` strings, which are
easy to get wrong by hand. Instead, write a one-off `extends SceneTree` script that calls
`ProjectSettings.set_setting("input/<action>", {"deadzone": 0.2, "events": [...]})` and then
`ProjectSettings.save()`. Run it with `godot --headless --path game -s gen.gd`. For buses, use
`ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres")`.
Pitfall: an `InputEventJoypadButton/Motion.new()` defaults to `device = 0`, which means the
first controller only, and keys default to 16. Set `device = -1` (all devices), as the editor
does. The template's `tests/unit/test_input_map.gd` checks this. `ProjectSettings.save()` rewrites
the file header and reorders keys, which is harmless.
