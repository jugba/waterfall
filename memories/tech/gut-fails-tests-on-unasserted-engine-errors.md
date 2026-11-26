# GUT 9.7 fails a test on any engine error or push_error it didn't expect, so write error-free code paths and assert intended errors

- Area: tech
- Date / source: 2026-11-26, building projects/_template (GUT 9.7.1 on Godot 4.7.1; first run had 2 failures from this)
- Confidence: high
- Apply when: writing Godot code or GUT tests for any project.

- `push_error()` or an engine error during a test fails that test. When a test means to cause
  the error, add `assert_push_error("text")` / `assert_engine_error("text")` to it (also `*_count`).
- Avoid APIs that log engine errors on normal bad input. Example: `JSON.parse_string()` logs
  "Parse JSON failed", so use `JSON.new().parse(text) == OK` for user files. Also check
  `DirAccess.dir_exists_absolute()` before `get_files_at()`.
- Get GUT with `git clone --depth 1 --branch v<ver> https://github.com/bitwes/Gut` (github.com git
  works here; api.github.com does not). Run it with `godot --headless --path game -s res://addons/gut/gut_cmdln.gd -gexit`.
  Autoloads load under `-s`, and the exit code is non-zero on failure. GUT 9.7.x is the line for
  Godot 4.7 (it changed double return types for 4.7's stricter typing).
