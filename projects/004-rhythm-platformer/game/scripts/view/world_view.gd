class_name WorldView
extends Node2D
## Draws level geometry from a World with rounded, friendly shapes: grassy earth blocks,
## wooden one-way planks, crates, drum blocks, mushroom bounce pads, checkpoint flags and
## sign boards (text >= 28 px). Culls to the camera. `pulse` (0..1) makes things bob on the beat.

const EARTH := Color(0.42, 0.28, 0.45)
const EARTH_DARK := Color(0.3, 0.19, 0.34)
const GRASS := Color(0.45, 0.86, 0.42)
const GRASS_DARK := Color(0.26, 0.62, 0.3)
const PLANK := Color(0.78, 0.55, 0.32)
const CRATE := Color(0.93, 0.7, 0.38)
const CRATE_DARK := Color(0.62, 0.4, 0.2)
const DRUM := Color(0.92, 0.3, 0.4)
const DRUM_RIM := Color(1.0, 0.85, 0.35)
const PAD := Color(1.0, 0.45, 0.7)
const SIGN := Color(0.98, 0.94, 0.84)
const INK := Color(0.22, 0.14, 0.26)

var world: World
var camera: Camera2D
var pulse := 0.0
var bar_pulse := 0.0
var pads: Array = []      # [{x0, x1, y, squash}]
var flags: Array = []     # [{pos, active}]
var signs: Array = []     # [{pos, text}]
var goal = null           # Vector2 or null
var beat_marks: Array = []  # [{x, bar}] ground ticks for the music level
var font: Font
var _time := 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	for p in pads:
		p["squash"] = maxf(float(p.get("squash", 0.0)) - delta * 3.0, 0.0)
	queue_redraw()


func view_rect() -> Rect2:
	if camera == null:
		return Rect2(-1e6, -1e6, 2e6, 2e6)
	var size := get_viewport_rect().size
	return Rect2(camera.get_screen_center_position() - size * 0.5, size).grow(120)


func _draw() -> void:
	if world == null:
		return
	var view := view_rect()
	for s in world.solids:
		if not s["alive"]:
			continue
		var r: Rect2 = s["rect"]
		if not view.intersects(r):
			continue
		match s["kind"]:
			"oneway":
				_plank(r)
			"breakable":
				if s["data"].get("style", "crate") == "drum":
					_drum(r)
				else:
					_crate(r)
			_:
				_earth(r.intersection(view.grow(40)), r)
	for m in beat_marks:
		var x: float = m["x"]
		if x < view.position.x or x > view.end.x:
			continue
		var h := 10.0 if m["bar"] else 5.0
		draw_line(Vector2(x, 18), Vector2(x, 18 + h + pulse * 4.0), Color(1, 1, 1, 0.35 if m["bar"] else 0.2), 3.0)
	for p in pads:
		_pad(p)
	for f in flags:
		_flag(f)
	if goal != null:
		_goal(goal)
	for s in signs:
		_sign(s)


func _earth(vis: Rect2, full: Rect2) -> void:
	if vis.size.x <= 0.0 or vis.size.y <= 0.0:
		return
	var bob := -pulse * 3.0
	var body := Rect2(vis.position.x, maxf(vis.position.y, full.position.y + 10.0), vis.size.x, vis.end.y - maxf(vis.position.y, full.position.y + 10.0))
	draw_rect(body, EARTH)
	# side shading
	if vis.position.x <= full.position.x + 1.0:
		draw_rect(Rect2(full.position.x, body.position.y, 8, body.size.y), EARTH_DARK)
	if vis.end.x >= full.end.x - 1.0:
		draw_rect(Rect2(full.end.x - 8, body.position.y, 8, body.size.y), EARTH_DARK)
	# pebbles (deterministic by position)
	var step := 64.0
	var x := floorf(vis.position.x / step) * step
	while x < vis.end.x:
		var y := full.position.y + 40.0
		var row := 0
		while y < minf(vis.end.y, full.position.y + 600.0):
			var hx := fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
			var px := x + hx * step
			if px > full.position.x + 12.0 and px < full.end.x - 12.0 and y > vis.position.y:
				draw_circle(Vector2(px, y + hx * 20.0), 4.0 + hx * 4.0, EARTH_DARK)
			y += 70.0
			row += 1
		x += step
	# grass cap with scalloped edge and rounded ends
	if full.position.y >= vis.position.y - 20.0:
		var top := full.position.y + bob
		draw_rect(Rect2(vis.position.x, top, vis.size.x, 16), GRASS)
		var sx := maxf(full.position.x + 10.0, floorf(vis.position.x / 22.0) * 22.0)
		while sx < minf(full.end.x - 6.0, vis.end.x + 22.0):
			draw_circle(Vector2(sx, top + 16.0), 9.0, GRASS)
			sx += 22.0
		draw_line(Vector2(vis.position.x, top + 2), Vector2(vis.end.x, top + 2), Color(1, 1, 1, 0.35), 3.0)
		if vis.position.x <= full.position.x + 1.0:
			draw_circle(Vector2(full.position.x + 4.0, top + 8.0), 10.0, GRASS)
		if vis.end.x >= full.end.x - 1.0:
			draw_circle(Vector2(full.end.x - 4.0, top + 8.0), 10.0, GRASS)
		# tufts that bounce on the beat
		var tx := floorf(vis.position.x / 150.0) * 150.0 + 40.0
		while tx < vis.end.x:
			if tx > full.position.x + 20.0 and tx < full.end.x - 20.0:
				var hgt := 10.0 + pulse * 8.0
				for k in 3:
					draw_line(Vector2(tx + k * 6.0, top), Vector2(tx + k * 6.0 + (k - 1) * 4.0, top - hgt), GRASS_DARK, 3.0)
			tx += 150.0


func _plank(r: Rect2) -> void:
	draw_rect(r, PLANK)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), PLANK.lightened(0.25))
	draw_circle(r.position + Vector2(10, r.size.y * 0.5), 3.0, CRATE_DARK)
	draw_circle(Vector2(r.end.x - 10, r.position.y + r.size.y * 0.5), 3.0, CRATE_DARK)


func _crate(r: Rect2) -> void:
	var g := r.grow(-2)
	draw_rect(g, CRATE)
	draw_rect(g, CRATE_DARK, false, 4.0)
	draw_line(g.position + Vector2(6, 6), g.end - Vector2(6, 6), CRATE_DARK, 4.0)
	draw_line(Vector2(g.end.x - 6, g.position.y + 6), Vector2(g.position.x + 6, g.end.y - 6), CRATE_DARK, 4.0)


func _drum(r: Rect2) -> void:
	var s := 1.0 + pulse * 0.06
	var c := Vector2(r.get_center().x, r.end.y)
	var w := r.size.x * s
	var h := r.size.y * s
	var body := Rect2(c.x - w * 0.5, c.y - h + 10, w, h - 10)
	draw_rect(body, DRUM)
	for i in 5:  # zig-zag lacing
		var y0 := body.position.y + 14.0
		var y1 := body.end.y - 14.0
		var x0 := body.position.x + i * w / 5.0
		draw_line(Vector2(x0, y0), Vector2(x0 + w / 10.0, y1), Color(1, 1, 1, 0.8), 2.0)
		draw_line(Vector2(x0 + w / 10.0, y1), Vector2(x0 + w / 5.0, y0), Color(1, 1, 1, 0.8), 2.0)
	draw_rect(Rect2(body.position.x - 3, body.position.y, w + 6, 10), DRUM_RIM)
	draw_rect(Rect2(body.position.x - 3, body.end.y - 10, w + 6, 10), DRUM_RIM)
	draw_colored_polygon(PlayerView.ellipse(Vector2(c.x, body.position.y), Vector2(w * 0.55, 9), 20), Color(1, 0.96, 0.9))
	# a face on the drum: it's a character too
	var fy := body.position.y + h * 0.42
	draw_circle(Vector2(c.x - 10, fy), 4.0, INK)
	draw_circle(Vector2(c.x + 10, fy), 4.0, INK)
	draw_arc(Vector2(c.x, fy + 8), 6.0, 0.2, PI - 0.2, 8, INK, 2.5)


func _pad(p: Dictionary) -> void:
	var x0: float = p["x0"]
	var x1: float = p["x1"]
	var y: float = p.get("y", 0.0)
	var sq: float = p.get("squash", 0.0)
	var cx := (x0 + x1) * 0.5
	var w := (x1 - x0) * (1.0 + sq * 0.3 + pulse * 0.08)
	var h := 26.0 * (1.0 - sq * 0.5 + pulse * 0.15)
	draw_rect(Rect2(cx - 8, y - h * 0.5, 16, h * 0.5 + 2), Color(0.98, 0.92, 0.8))
	var cap := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		cap.append(Vector2(cx + cos(a) * w * 0.5, y - h * 0.4 + sin(a) * h))
	draw_colored_polygon(cap, PAD if not p.get("glide", false) else Color(0.55, 0.8, 1.0))
	for k in 3:
		draw_circle(Vector2(cx - w * 0.25 + k * w * 0.25, y - h * 0.4 - h * 0.6 + (4.0 if k == 1 else 8.0)), 4.0, Color.WHITE)


func _flag(f: Dictionary) -> void:
	var p: Vector2 = f["pos"]
	draw_line(p, p + Vector2(0, -110), Color(0.95, 0.95, 0.95), 5.0)
	draw_circle(p + Vector2(0, -112), 6.0, DRUM_RIM)
	var c := Color(0.35, 0.9, 0.55) if f.get("active", false) else Color(0.75, 0.75, 0.8)
	var wave := sin(_time * 6.0) * 5.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(3, -106), p + Vector2(58, -92 + wave),
		p + Vector2(3, -74)]), c)


func _goal(p: Vector2) -> void:
	for i in 2:
		var x := p.x + (i * 2 - 1) * 90.0
		draw_rect(Rect2(x - 10, p.y - 230, 20, 230), Color(1, 1, 1, 0.9))
	draw_arc(Vector2(p.x, p.y - 230), 90.0, PI, TAU, 24, DRUM_RIM, 18.0)
	_text_centered(Vector2(p.x, p.y - 260), "GOAL", 44, Color.WHITE)


func _sign(s: Dictionary) -> void:
	var p: Vector2 = s["pos"]
	var lines: PackedStringArray = String(s["text"]).split("\n")
	var fs := 28
	var w := 0.0
	for l in lines:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var h := lines.size() * 36.0 + 20.0
	var box := Rect2(p.x - w * 0.5 - 20, p.y - h - 170, w + 40, h)
	draw_rect(Rect2(p.x - 5, box.end.y, 10, 170), PLANK)
	draw_rect(box.grow(4), INK)
	draw_rect(box, SIGN)
	for i in lines.size():
		_text_centered(Vector2(p.x, box.position.y + 40 + i * 36.0), lines[i], fs, INK, false)


func _text_centered(at: Vector2, text: String, size: int, c: Color, outline := true) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if outline:
		draw_string_outline(font, at - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 8, INK)
	draw_string(font, at - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
