# Capture real gameplay frames in the container with Xvfb + Godot --write-movie driven by an --autoplay arg

- Area: tech
- Date / source: 2026-11-26, projects/002-cozy-organizing-sim/iterations/002.md (greybox capture)
- Confidence: high
- Apply when: you need screenshots, a PNG sequence or a clip of a Godot game without a desktop.

`--headless` uses a dummy renderer (no pixels), but Xvfb + Mesa (llvmpipe) render the
Compatibility renderer fine:
`xvfb-run -a -s "-screen 0 1280x800x24" godot --path game --rendering-driver opengl3 --resolution 1280x800 --write-movie out/f.png --fixed-fps 30 res://scenes/game.tscn -- --autoplay`
Movie Maker writes `f00000000.png...` plus `f.wav` at a fixed frame rate (deterministic, not
real time; 14 s of game took ~1 min). Make the scene play itself when
`OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay")` (release exports ignore
it) and `get_tree().quit()` at the end. ffmpeg + ImageMagick `montage` are installed for an
mp4 or a contact sheet to review many frames in one image read.
