# Put the run loop (input mapping, buffers, hitstop, stepping) in a node-free driver shared by every view, then test view parity with state snapshots

- Area: tech
- Date / source: 2026-11-27, projects/005-hook-and-grow/iterations/002.md (`game/scripts/core/arena_driver.gd`, `tests/integration/test_arena_3d.gd`)
- Confidence: high (identical snapshots 2D vs 3D vs bare driver over a 30 s input tape and a 20 s bot run with 210 hitstop frames)
- Apply when: a game may get a second presentation (2D vs 3D test, a side-on variant, a replay viewer, a headless server) or you need deterministic replays through a scene.

- A node-free rules sim (`tech/platformer-controller-as-pure-fixed-step-sim-for-tests`) is not enough:
  the scene still decided *when* the sim steps (hitstop) and *what* it was fed (aim from the mouse,
  press buffers, controller assist). Move all of that into a RefCounted driver:
  `tick(delta, blocked, read_input)` + signals `stepped`; a pure `make_frame(sim, move, stick,
  pad_aim, mouse_world, assist, hook, dodge)`; a `script_input` Callable that tests use to feed a tape.
- Each view only supplies the cursor's position on the play plane (2D: canvas mouse; 3D: camera ray
  hit) and reacts to `stepped` events. Hitstop must be in the driver: it changes which frames step.
- Then add `sim.snapshot()` (rounded state dict) and assert the 2D scene, the 3D scene and a bare
  driver give equal snapshots at checkpoints for the same tape; disable `_physics_process` in the
  test and call the scene's `tick()` yourself (30 s of 3D runs in well under a second headless).
- Also: release exports refuse a scene path on the command line, so a test mode needs a menu entry.
