class_name Fx
extends Node2D
## World-space juice: dust puffs, sparks, rings, afterimages, speed lines and text popups.
## Everything is drawn here with simple shapes; one node, no per-particle nodes.

const DUST := Color(1.0, 0.97, 0.9, 0.85)
const GHOST := Color(0.55, 0.9, 1.0, 0.6)

var _puffs: Array = []   # {p, v, r, life, max, c, grow}
var _rings: Array = []   # {p, r, life, max, c}
var _ghosts: Array = []  # {p, s, f, life, max}
var _lines: Array = []   # {p, dir, life, max}
var _texts: Array = []   # {p, s, c, size, life, max}
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	z_index = 5


func dust(at: Vector2, count: int, dir: Vector2) -> void:
	for i in count:
		var v := Vector2(randf_range(-160, 160), randf_range(-90, -10))
		if dir != Vector2.ZERO:
			v = dir.normalized() * randf_range(60, 180) + Vector2(randf_range(-40, 40), randf_range(-40, 20))
		_puffs.append({"p": at + Vector2(randf_range(-14, 14), -4), "v": v, "r": randf_range(5, 10),
			"life": 0.0, "max": randf_range(0.25, 0.45), "c": DUST, "grow": 14.0})


func sparks(at: Vector2, count: int, color: Color, speed := 380.0) -> void:
	for i in count:
		var a := randf() * TAU
		_puffs.append({"p": at, "v": Vector2(cos(a), sin(a)) * randf_range(speed * 0.4, speed),
			"r": randf_range(3, 6), "life": 0.0, "max": randf_range(0.2, 0.4), "c": color, "grow": -8.0})


func ring(at: Vector2, radius: float, color: Color, life := 0.3) -> void:
	_rings.append({"p": at, "r": radius, "life": 0.0, "max": life, "c": color})


func afterimage(at: Vector2, s: Vector2, facing: int, life: float) -> void:
	_ghosts.append({"p": at, "s": s, "f": facing, "life": 0.0, "max": life})


func speed_line(at: Vector2, dir: int) -> void:
	_lines.append({"p": at, "dir": dir, "life": 0.0, "max": 0.16, "len": randf_range(40, 90)})


func popup(at: Vector2, text: String, color: Color, size := 40) -> void:
	_texts.append({"p": at, "s": text, "c": color, "size": size, "life": 0.0, "max": 0.75})


func _process(delta: float) -> void:
	for list in [_puffs, _rings, _ghosts, _lines, _texts]:
		var i: int = list.size() - 1
		while i >= 0:
			var e: Dictionary = list[i]
			e["life"] += delta
			if e["life"] >= e["max"]:
				list.remove_at(i)
			i -= 1
	for e in _puffs:
		e["p"] += e["v"] * delta
		e["v"] *= exp(-5.0 * delta)
		e["r"] = maxf(e["r"] + e["grow"] * delta, 0.5)
	for e in _texts:
		e["p"].y -= 70.0 * delta
	queue_redraw()


func _draw() -> void:
	for g in _ghosts:
		var k: float = 1.0 - g["life"] / g["max"]
		var c := GHOST
		c.a *= k
		draw_set_transform(g["p"], 0.0, Vector2(g["s"].x * g["f"], g["s"].y))
		var body := PlayerView.ellipse(Vector2(0, -27), Vector2(23, 24.5), 20)
		draw_colored_polygon(body, c)
		draw_arc(Vector2(0, -30), 27.0, PI * 1.08, PI * 1.92, 12, Color(1, 1, 1, c.a), 4.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for l in _lines:
		var k: float = 1.0 - l["life"] / l["max"]
		var p: Vector2 = l["p"]
		draw_line(p, p + Vector2(l["dir"] * l["len"] * (0.4 + k), 0), Color(1, 1, 1, 0.7 * k), 3.0)
	for e in _puffs:
		var k: float = 1.0 - e["life"] / e["max"]
		var c: Color = e["c"]
		c.a *= k
		draw_circle(e["p"], e["r"], c)
	for r in _rings:
		var k: float = r["life"] / r["max"]
		var c: Color = r["c"]
		c.a *= 1.0 - k
		draw_arc(r["p"], r["r"] * (0.3 + k), 0, TAU, 32, c, 5.0 * (1.0 - k) + 1.0, true)
	for t in _texts:
		var k: float = t["life"] / t["max"]
		var c: Color = t["c"]
		c.a = 1.0 - k * k
		var size: int = t["size"]
		var pop := 1.0 + 0.4 * maxf(0.0, 1.0 - k * 6.0)
		var fs := int(size * pop)
		var w := font.get_string_size(t["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p: Vector2 = t["p"] - Vector2(w * 0.5, 0)
		draw_string_outline(font, p, t["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0.15, 0.05, 0.2, c.a))
		draw_string(font, p, t["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
