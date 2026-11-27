class_name ContainerBox
extends Node2D
## The client's bag or drawer, greybox. Two looks:
## - closed/tipping: a body, a lid/flap that opens (`lid`), used for the intro and the tip;
## - `interior`: seen from above wide open, showing its packing grid (w x h cells, the same
##   32 px lattice as the desk) for the pack-back phase. `zip` 0..1 closes it from left to right.

const RIM := 18.0

var kind := "bag"
var label := ""
var cells := Vector2i(8, 3)
var size_px := Vector2(256, 96)
var colour := Color.WEB_PURPLE
var lid := 0.0:   ## 0 = closed, 1 = open
	set(v):
		lid = v
		queue_redraw()
var interior := false:
	set(v):
		interior = v
		queue_redraw()
var zip := 0.0:   ## interior view only: 0 = open, 1 = fully closed
	set(v):
		zip = v
		queue_redraw()

var _body := StyleBoxFlat.new()
var _lid := StyleBoxFlat.new()


func setup(c: Dictionary) -> void:
	kind = String(c.get("kind", "bag"))
	label = String(c.get("name", ""))
	cells = Vector2i(int(c.get("w", 8)), int(c.get("h", 3)))
	size_px = Vector2(cells) * Desk.CELL
	colour = Catalog.colour(String(c.get("colour", "purple")))
	interior = false
	zip = 0.0
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


## World x where the closing edge is (items left of it are under the lid).
func zip_edge_x() -> float:
	return global_position.x - size_px.x * 0.5 + size_px.x * zip


func _draw() -> void:
	if interior:
		_draw_interior()
		return
	var r := Rect2(-size_px * 0.5, size_px)
	draw_style_box(_body, r)
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


func _draw_interior() -> void:
	var grid := Rect2(-size_px * 0.5, size_px)
	draw_style_box(_body, grid.grow(RIM))
	draw_rect(grid, colour.darkened(0.62))
	var line := Color(1, 1, 1, 0.07)
	for x in range(1, cells.x):
		draw_line(Vector2(grid.position.x + x * Desk.CELL, grid.position.y), Vector2(grid.position.x + x * Desk.CELL, grid.end.y), line, 1.0)
	for y in range(1, cells.y):
		draw_line(Vector2(grid.position.x, grid.position.y + y * Desk.CELL), Vector2(grid.end.x, grid.position.y + y * Desk.CELL), line, 1.0)
	if kind == "bag":
		# Zip teeth along both long edges of the opening.
		var teeth := Color(0.85, 0.82, 0.7, 0.8)
		var x := grid.position.x
		while x < grid.end.x:
			draw_rect(Rect2(Vector2(x, grid.position.y - 10), Vector2(5, 6)), teeth)
			draw_rect(Rect2(Vector2(x + 3, grid.end.y + 4), Vector2(5, 6)), teeth)
			x += 9.0
	if zip > 0.0:
		# The lid / flap slides over the interior from the left; the zip pull leads it.
		var cover := Rect2(grid.position - Vector2(RIM, RIM), Vector2(size_px.x * zip + RIM, size_px.y + RIM * 2))
		_lid.bg_color.a = 1.0
		draw_style_box(_lid, cover)
		var edge := grid.position.x + size_px.x * zip
		var pull := Rect2(Vector2(edge - 8, grid.position.y - RIM - 6), Vector2(16, 34))
		draw_rect(pull, Color(0.9, 0.85, 0.6))
		draw_rect(pull.grow(-4), colour.darkened(0.5))
