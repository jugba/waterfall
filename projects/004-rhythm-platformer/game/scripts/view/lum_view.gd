class_name LumView
extends Node2D
## Collectible "notes": small glowing orbs with an eighth-note flag. Additive glow behind
## (memories/tech/godot-2d-glow-additive-layers-behind-and-in-front).
## lums: [{pos: Vector2, alive: bool}]

const CORE := Color(1.0, 0.86, 0.25)
const CORE_HI := Color(1.0, 1.0, 0.85)
const GLOW := Color(1.0, 0.75, 0.25, 0.55)

var lums: Array = []
var pulse := 0.0
var camera: Camera2D
var _glow: Node2D
var _tex: GradientTexture2D
var _time := 0.0


func _ready() -> void:
	z_index = 2
	_glow = Node2D.new()
	_glow.z_index = -1
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = m
	add_child(_glow)
	_glow.draw.connect(_draw_glow)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.35))
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.fill = GradientTexture2D.FILL_RADIAL
	_tex.fill_from = Vector2(0.5, 0.5)
	_tex.fill_to = Vector2(1.0, 0.5)
	_tex.width = 64
	_tex.height = 64


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_glow.queue_redraw()


func _visible_rect() -> Rect2:
	if camera == null:
		return Rect2(-1e6, -1e6, 2e6, 2e6)
	var size := get_viewport_rect().size
	return Rect2(camera.get_screen_center_position() - size * 0.5, size).grow(80)


func _lum_pos(i: int, l: Dictionary) -> Vector2:
	return l["pos"] + Vector2(0, sin(_time * 3.0 + i * 0.7) * 3.0)


func _draw_glow() -> void:
	var view := _visible_rect()
	var s := 1.0 + pulse * 0.35
	for i in lums.size():
		var l: Dictionary = lums[i]
		if not l["alive"] or not view.has_point(l["pos"]):
			continue
		var r := 34.0 * s
		var p := _lum_pos(i, l)
		_glow.draw_texture_rect(_tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, GLOW)


func _draw() -> void:
	var view := _visible_rect()
	var s := 1.0 + pulse * 0.25
	for i in lums.size():
		var l: Dictionary = lums[i]
		if not l["alive"] or not view.has_point(l["pos"]):
			continue
		var p := _lum_pos(i, l)
		# note stem and flag
		draw_line(p + Vector2(7 * s, 0), p + Vector2(7 * s, -20 * s), CORE.darkened(0.2), 3.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(7, -20) * s, p + Vector2(17, -12) * s,
			p + Vector2(14, -9) * s, p + Vector2(7, -14) * s]), CORE.darkened(0.1))
		draw_circle(p, 9.0 * s, CORE)
		draw_circle(p + Vector2(-2.5, -2.5) * s, 4.0 * s, CORE_HI)
