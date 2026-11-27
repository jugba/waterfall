# Fake 2D glow in Godot's Compatibility renderer with additive draw layers: one behind the subject, one in front

- Area: tech
- Date / source: 2026-11-27, projects/003-rockhound/iterations/001.md (greybox crack reveal; frames in projects/003-rockhound/assets/greybox/)
- Confidence: high (seen in Xvfb captures)
- Apply when: a greybox or 2D game needs glow, light leaks, rays or bloom without art or a post-process.

- No WorldEnvironment needed: a `Node2D` with `CanvasItemMaterial.blend_mode = BLEND_MODE_ADD`,
  drawing a radial `GradientTexture2D` (white → transparent) with `draw_texture_rect(tex, rect, false, tint)`,
  plus `draw_polyline` / `draw_colored_polygon` for light leaks and rays. Works on Compatibility (Mac/Deck safe).
- **Put the big glow behind the subject** (`z_index` below the node that draws it) and only a small,
  low-alpha bloom in front. Our first pass drew everything in front and the white-hot additive core
  washed the crystal out completely, so the payoff object was invisible. The background must then be its
  own node at a lower `z_index`, or it covers the back glow.
- Connect a child's `draw` signal to a method on the parent (`glow.draw.connect(_draw_glow)` and call
  `glow.draw_*` inside it) to get extra draw layers without one script per layer.
- Also: `CPUParticles2D` one-shot bursts (with an ADD material for sparkles) and `Engine.time_scale` slow-mo
  with `create_timer(t, true, false, true)` and `tween.set_ignore_time_scale(true)`, so UI tweens and the
  slow-mo exit run in real time.
