# A headless Godot `-s` script whose dependencies fail to compile never quits, so wrap every headless run in `timeout` and log to a file

- Area: tech
- Date / source: 2026-11-27, projects/005-hook-and-grow/iterations/001.md (Godot 4.7.1; two runs hung for minutes at ~0% CPU)
- Confidence: high
- Apply when: running any Godot tool script, test runner or game scene headless (in this container or CI).

- `godot --headless -s res://tool.gd` with a `SceneTree` script: if a script it uses has a parse error,
  `_init` fails, `quit()` is never called and the process idles forever. Piping into `grep`/`tail`
  also hides the error until it exits. Run `timeout 60 godot ... > log 2>&1`, then grep the log for
  `SCRIPT ERROR` (tools/godot/build.sh already greps for these).
- The most common parse error in 4.7: `var x := <expr>` where the expression's type is unknown,
  e.g. a property of an element from an untyped `Array` or `for e in list`, or an inner-class object
  stored in an untyped var (`var to := pos - h.pos`). Write `var x: Vector2 = ...` (explicit type) instead.
- Inner classes (`class Enemy: extends RefCounted`) inside a `class_name` script are fine for a node-free
  sim; reference them as `ArenaSim.Enemy`.
