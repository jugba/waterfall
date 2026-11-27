# Steam screenshots must be 16:9 (≥1920×1080); a 16:10 Deck-native game must plan a 16:9 capture mode from day 1

- Area: marketing
- Date / source: 2026-11-27, projects/002-cozy-organizing-sim/store/screenshots-trailer.md §0; asset sizes from playbooks/steam-launch-checklist.md Reference A (Steamworks assets page, checked 2026-11-26)
- Confidence: medium (the size rule is official; the Godot method is untested on final art)
- Apply when: setting a new game's base resolution, UI anchors, or capture scripts.

We design for Steam Deck at 1280×800 (16:10), but store screenshots and trailers are 16:9 at 1920×1080 or larger. Letterbox bars or stretched UI look amateur on the most-seen part of the page.

In Godot:
- Use `stretch/mode=canvas_items` with `aspect=expand`.
- Anchor UI to the edges.
- Capture with `--resolution 1920x1080` via the Xvfb `--write-movie` recipe (tech/godot-headless-capture-xvfb-write-movie).
- Check the 16:9 framing in the vertical-slice week, before the store-page screenshots are due.

Short-form clips need a third framing, 9:16, so a tighter or portrait-shaped play area for capture saves re-shoots.
