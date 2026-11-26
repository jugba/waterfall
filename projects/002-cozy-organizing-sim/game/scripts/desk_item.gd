class_name DeskItem
extends Node2D
## One item on the desk, drawn as greybox art: a coloured rounded rectangle with its name.
## `rotation` is the item's real orientation (used for scoring); `tilt`, `lift` and `squash`
## are visual-only juice applied in _draw (drag wobble, raised shadow, landing squash).

const CORNER := 7
const INSET := 2.0

var data: Dictionary = {}
var base_size := Vector2i(1, 1)   ## cells at rotation 0 (w >= h)
var held := false
var placed := false               ## snapped onto the grid (an obstacle for other drops)
var cell := Vector2i.ZERO         ## top-left grid cell while placed
var velocity := Vector2.ZERO      ## loose-item physics (tip scatter, being bumped)
var spin := 0.0

var lift := 0.0:
	set(v):
		lift = v
		queue_redraw()
var tilt := 0.0:
	set(v):
		tilt = v
		queue_redraw()
var squash := 1.0:
	set(v):
		squash = v
		queue_redraw()
var hover := false:
	set(v):
		if hover != v:
			hover = v
			queue_redraw()

var _motion: Tween
var _colour := Color.WHITE
var _font_size := 14
var _body := StyleBoxFlat.new()
var _shadow := StyleBoxFlat.new()
var _outline := StyleBoxFlat.new()


func setup(item_data: Dictionary) -> void:
	data = item_data
	name = "Item_%s" % String(data.get("id", "x"))
	base_size = Vector2i(maxi(1, int(data.get("w", 1))), maxi(1, int(data.get("h", 1))))
	_colour = Catalog.colour(String(data.get("colour", "")))
	_body.bg_color = _colour
	_body.border_color = _colour.darkened(0.35)
	_body.set_border_width_all(2)
	_body.set_corner_radius_all(CORNER)
	_shadow.bg_color = Color(0, 0, 0, 0.35)
	_shadow.set_corner_radius_all(CORNER + 2)
	_outline.draw_center = false
	_outline.border_color = Color(1, 1, 1, 0.9)
	_outline.set_border_width_all(3)
	_outline.set_corner_radius_all(CORNER + 2)
	_fit_font()
	queue_redraw()


## The item's one movement tween. Starting a new move kills the previous one, so a grab,
## drop or rotate never fights an older tween over position/rotation.
func motion() -> Tween:
	stop_motion()
	_motion = create_tween()
	return _motion


func stop_motion() -> void:
	if _motion and _motion.is_valid():
		_motion.kill()
	_motion = null


func category() -> String:
	return String(data.get("category", ""))


func colour_name() -> String:
	return String(data.get("colour", ""))


## Nearest quarter turn of the current rotation (0..3).
func quarter() -> int:
	return posmod(roundi(rotation / (PI / 2.0)), 4)


func snapped_angle() -> float:
	return roundf(rotation / (PI / 2.0)) * (PI / 2.0)


## Footprint in cells at a quarter turn (defaults to the current one).
func grid_size(q := -1) -> Vector2i:
	if q < 0:
		q = quarter()
	return base_size if q % 2 == 0 else Vector2i(base_size.y, base_size.x)


func size_px() -> Vector2:
	return Vector2(base_size) * Desk.CELL


## Half of the axis-aligned bounding box at the current rotation, in pixels.
func half_extents() -> Vector2:
	var h := size_px() * 0.5
	var c := absf(cos(rotation))
	var s := absf(sin(rotation))
	return Vector2(h.x * c + h.y * s, h.x * s + h.y * c)


func contains_point(world: Vector2, margin := 4.0) -> bool:
	var local := to_local(world)
	var h := size_px() * 0.5 + Vector2(margin, margin)
	return absf(local.x) <= h.x and absf(local.y) <= h.y


## The item as the scorer sees it: footprint in cells at its nearest quarter turn, real angle.
func score_entry() -> Dictionary:
	var size := Vector2(grid_size())
	var centre := Desk.px_to_cell(position)
	return Neatness.entry(Rect2(centre - size * 0.5, size), rad_to_deg(rotation), category(), colour_name())


func _fit_font() -> void:
	var font := ThemeDB.fallback_font
	var text := String(data.get("name", ""))
	var avail := size_px().x - 10.0
	_font_size = 16
	while _font_size > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x > avail:
		_font_size -= 1


func _draw() -> void:
	var s := size_px()
	var r := Rect2(-s * 0.5 + Vector2(INSET, INSET), s - Vector2(INSET, INSET) * 2.0)
	var vis := Vector2.ONE * (1.0 + 0.08 * lift) * squash
	# The shadow falls down-right on screen whatever the item's rotation.
	var off := Vector2(3, 4).lerp(Vector2(12, 18), lift).rotated(-rotation - tilt)
	_shadow.bg_color.a = lerpf(0.35, 0.22, lift)
	draw_set_transform(off, tilt, vis)
	draw_style_box(_shadow, r)
	draw_set_transform(Vector2.ZERO, tilt, vis)
	draw_style_box(_body, r)
	# A highlight strip on the top edge sells "object" over "rectangle".
	draw_rect(Rect2(r.position + Vector2(CORNER, 3), Vector2(r.size.x - CORNER * 2, 2)), Color(1, 1, 1, 0.25))
	var font := ThemeDB.fallback_font
	var text := String(data.get("name", ""))
	var ink := Color("1d1f26") if _colour.get_luminance() > 0.45 else Color("f4f1ea")
	var baseline := (font.get_ascent(_font_size) - font.get_descent(_font_size)) * 0.5
	draw_string(font, Vector2(r.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, _font_size, ink)
	if hover or held:
		draw_style_box(_outline, r.grow(3))
