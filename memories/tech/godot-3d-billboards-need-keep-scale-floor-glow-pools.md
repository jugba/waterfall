# Godot 3D billboards ignore node and particle scale unless `billboard_keep_scale` is on; put ground glows on the floor as additive pools

- Area: tech
- Date / source: 2026-11-27, projects/005-hook-and-grow/iterations/002.md (Hookmaw 3D arena, Godot 4.7.1 Compatibility, Xvfb captures)
- Confidence: high (seen and fixed in captures)
- Apply when: adding halos, glow sprites, particles or any billboarded quad to a Godot 3D scene.

- A `StandardMaterial3D` with `billboard_mode = BILLBOARD_ENABLED` or `BILLBOARD_PARTICLES` draws the
  mesh at its own size and throws away the node's / particle's scale unless
  `billboard_keep_scale = true`. Our 2x2 halo quads and marine-snow particles all rendered as 2-unit
  white squares; with `scale_amount` 0.02 they still filled the screen.
- A camera-facing halo near the seabed is cut by the floor along a straight line (depth test). Glow
  around a creature that stands on the ground reads better as a horizontal additive quad on the floor
  (a light pool, radial gradient, `depth_draw_mode = DISABLED`), plus a small billboard only on
  things well above the floor (a lure bulb, shots).
- Each halo/pool whose colour animates needs its own material copy (QuadMesh has no vertex colours).
- Works on the Compatibility renderer (Mac-safe), together with custom spatial shaders, depth fog,
  glow, MultiMesh, CPUParticles3D and ImmediateMesh; all render under Xvfb + llvmpipe for screenshots
  (`tech/godot-headless-capture-xvfb-write-movie`).
