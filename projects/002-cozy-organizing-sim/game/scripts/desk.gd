class_name Desk
extends Node2D
## The work surface: a cutting mat with a soft grid. Owns the grid maths (cells <-> pixels)
## and draws the drop preview ("ghost") and alignment guides while an item is held.

const CELL := 32.0
const COLS := 32
const ROWS := 20
const ORIGIN := Vector2(32, 120)       ## top-left of the mat in world pixels
const SIZE := Vector2(COLS, ROWS) * CELL

const ROOM_COLOUR := Color("1d1f26")
const MAT_COLOUR := Color("2f5d50")
const MAT_EDGE := Color("244a40")
const GRID_COLOUR := Color(1, 1, 1, 0.06)
const GRID_MAJOR := Color(1, 1, 1, 0.12)
const GHOST_COLOUR := Color(1, 1, 1, 0.16)
const GHOST_EDGE := Color(1, 1, 1, 0.55)
const GUIDE_COLOUR := Color(1.0, 0.93, 0.6, 0.55)

var ghost := Rect2i()       ## cells; size 0 = hidden
var guides_x: Array[float] = []  ## cell x of vertical guide lines
var guides_y: Array[float] = []
var flash := 0.0:            ## brief brightening of the mat (photo flash / snap feedback)
	set(v):
		flash = v
		queue_redraw()


static func rect_px() -> Rect2:
	return Rect2(ORIGIN, SIZE)


static func cell_to_px(cell: Vector2) -> Vector2:
	return ORIGIN + cell * CELL


static func px_to_cell(px: Vector2) -> Vector2:
	return (px - ORIGIN) / CELL


## World-pixel centre of an item whose top-left cell is `cell` and footprint is `size` cells.
static func centre_of(cell: Vector2i, size: Vector2i) -> Vector2:
	return cell_to_px(Vector2(cell) + Vector2(size) * 0.5)


static func in_bounds(r: Rect2i) -> bool:
	return r.position.x >= 0 and r.position.y >= 0 and r.end.x <= COLS and r.end.y <= ROWS


func show_ghost(r: Rect2i, gx: Array[float], gy: Array[float]) -> void:
	if r == ghost and gx == guides_x and gy == guides_y:
		return
	ghost = r
	guides_x = gx
	guides_y = gy
	queue_redraw()


func hide_ghost() -> void:
	if ghost.size == Vector2i.ZERO and guides_x.is_empty() and guides_y.is_empty():
		return
	ghost = Rect2i()
	guides_x = []
	guides_y = []
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2000, -2000, 5280, 4800), ROOM_COLOUR)
	var mat := rect_px()
	var outer := StyleBoxFlat.new()
	outer.bg_color = MAT_EDGE
	outer.set_corner_radius_all(14)
	draw_style_box(outer, mat.grow(10))
	var inner := StyleBoxFlat.new()
	inner.bg_color = MAT_COLOUR.lerp(Color.WHITE, flash * 0.35)
	inner.set_corner_radius_all(6)
	draw_style_box(inner, mat)
	for x in range(1, COLS):
		var px := ORIGIN.x + x * CELL
		draw_line(Vector2(px, mat.position.y), Vector2(px, mat.end.y), GRID_MAJOR if x % 4 == 0 else GRID_COLOUR, 1.0)
	for y in range(1, ROWS):
		var py := ORIGIN.y + y * CELL
		draw_line(Vector2(mat.position.x, py), Vector2(mat.end.x, py), GRID_MAJOR if y % 4 == 0 else GRID_COLOUR, 1.0)
	if ghost.size != Vector2i.ZERO:
		for gx in guides_x:
			var px := ORIGIN.x + gx * CELL
			draw_dashed_line(Vector2(px, mat.position.y), Vector2(px, mat.end.y), GUIDE_COLOUR, 2.0, 8.0)
		for gy in guides_y:
			var py := ORIGIN.y + gy * CELL
			draw_dashed_line(Vector2(mat.position.x, py), Vector2(mat.end.x, py), GUIDE_COLOUR, 2.0, 8.0)
		var g := Rect2(cell_to_px(Vector2(ghost.position)), Vector2(ghost.size) * CELL).grow(-2)
		var box := StyleBoxFlat.new()
		box.bg_color = GHOST_COLOUR
		box.border_color = GHOST_EDGE
		box.set_border_width_all(2)
		box.set_corner_radius_all(7)
		draw_style_box(box, g)
