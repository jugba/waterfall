class_name ContainerBox
extends Node2D
## The client's bag or drawer, greybox: a body, a lid/flap that opens, and a name tag.

var kind := "bag"
var label := ""
var size_px := Vector2(256, 96)
var colour := Color.WEB_PURPLE
var lid := 0.0:   ## 0 = closed, 1 = open
	set(v):
		lid = v
		queue_redraw()

var _body := StyleBoxFlat.new()
var _lid := StyleBoxFlat.new()


func setup(c: Dictionary) -> void:
	kind = String(c.get("kind", "bag"))
	label = String(c.get("name", ""))
	size_px = Vector2(int(c.get("w", 8)), int(c.get("h", 3))) * Desk.CELL
	colour = Catalog.colour(String(c.get("colour", "purple")))
	_body.bg_color = colour
	_body.border_color = colour.darkened(0.4)
	_body.set_border_width_all(3)
	_body.set_corner_radius_all(18 if kind == "bag" else 6)
	_body.shadow_color = Color(0, 0, 0, 0.35)
	_body.shadow_size = 10
	_body.shadow_offset = Vector2(4, 8)
	_lid.bg_color = colour.darkened(0.18)
	_lid.border_color = colour.darkened(0.45)
	_lid.set_border_width_all(3)
	_lid.set_corner_radius_all(16 if kind == "bag" else 4)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size_px * 0.5, size_px)
	draw_style_box(_body, r)
	var font := ThemeDB.fallback_font
	if kind == "drawer":
		# Drawer front with a handle; "open" slides a dark interior into view.
		var inner := r.grow(-12)
		inner.size.y *= lid
		draw_rect(inner, Color(0, 0, 0, 0.45))
		var handle := Rect2(Vector2(-40, r.end.y - 30), Vector2(80, 12))
		draw_rect(handle, colour.darkened(0.55))
	else:
		# Bag: the flap lifts up and fades as it opens, showing the dark mouth.
		var mouth := Rect2(r.position + Vector2(16, 12), Vector2(r.size.x - 32, r.size.y * 0.42))
		draw_rect(mouth, Color(0, 0, 0, 0.5 * lid))
		var flap := Rect2(r.position + Vector2(0, -lid * r.size.y * 0.35), Vector2(r.size.x, r.size.y * 0.5))
		_lid.bg_color.a = 1.0 - lid * 0.55
		draw_style_box(_lid, flap)
		draw_rect(Rect2(Vector2(-10, flap.end.y - 14), Vector2(20, 14)), Color(0.9, 0.85, 0.6, 1.0 - lid * 0.5))
	draw_string(font, Vector2(r.position.x, r.end.y + 30), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color(1, 1, 1, 0.75))
