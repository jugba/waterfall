# Write the platformer controller as a node-free fixed-step AABB sim, so feel promises are unit tests and whole-level replays run in milliseconds

- Area: tech
- Date / source: 2026-11-27, projects/004-rhythm-platformer/iterations/001.md (`game/scripts/core/player_controller.gd`, tests in `game/tests/unit/test_controller.gd`, `tests/integration/test_sandbox.gd`, `test_music_level.gd`)
- Confidence: high for testability (51 tests, a 70 s level replay in ~50 ms); feel itself awaits the fun gate
- Apply when: building any 2D platformer / action controller in Godot (or any engine).

- Controller = `RefCounted` with `step(dt, InputFrame)` against a `World` of `Rect2` solids
  (solid / one-way / breakable), axis-separated move-and-resolve, feet-centre position, events list
  per step (`jump`, `land`, `wall_jump`, ...). No CharacterBody2D, no physics frames.
- Why: Godot physics only advances in real-time physics frames, so a 70 s replay would take 70 s per
  test and isn't bit-deterministic. The pure sim runs thousands of steps inside one test call.
- Tests then read like the design: tap vs full jump height range, coyote and buffer windows work and
  expire, wall jump pushes *away* from either wall, "this gap needs the dash", "this canyon needs
  the glide", replays shifted ±50 ms still finish the level. They caught a glide tuned so floaty it
  overshot the landing mesa.
- The view (`PlayerView`) only reads state + events (squash/stretch, dust, sounds) and interpolates
  between steps with `Engine.get_physics_interpolation_fraction()`.
- All tuning in one JSON (`data/movement.json`) with piecewise accel/decel curves; F5 reloads it live.
- Trade-off: no slopes or rotating bodies; fine for tile-like greybox geometry.
