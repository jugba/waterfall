class_name Backdrop
extends Node2D
## Screen-space sky: vertical gradient, sun, drifting clouds and two parallax hill layers.
## Put it in a CanvasLayer with a negative layer. `pulse` (0..1) flashes it on the beat.

var camera: Camera2D
var pulse := 0.0
var bar_pulse := 0.0
var sky_top := Color(0.36, 0.55, 0.98)
var sky_bottom := Color(1.0, 0.78, 0.62)
var hills_far := Color(0.55, 0.5, 0.85)
var hills_near := Color(0.36, 0.7, 0.55)
var sun := Color(1.0, 0.95, 0.7)
var _time := 0.0


func set_palette(top: Color, bottom: Color, far: Color, near: Color, sun_c: Color) -> void:
	sky_top = top
	sky_bottom = bottom
	hills_far = far
	hills_near = near
	sun = sun_c


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _cam() -> Vector2:
	return camera.get_screen_center_position() if camera and camera.is_inside_tree() else Vector2.ZERO


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := _cam()
	var flash := pulse * 0.10 + bar_pulse * 0.10
	var top := sky_top.lerp(Color.WHITE, flash)
	var bottom := sky_bottom.lerp(Color.WHITE, flash * 1.2)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	# sun with soft rings
	var sp := Vector2(size.x * 0.78 - cam.x * 0.01, size.y * 0.24 - cam.y * 0.01)
	for i in 4:
		var c := sun
		c.a = 0.12 - i * 0.025
		draw_circle(sp, 90.0 + i * 34.0 + pulse * 10.0, c)
	draw_circle(sp, 70.0 + pulse * 6.0, sun)
	# clouds
	for i in 7:
		var cx := fposmod(i * 330.0 - cam.x * 0.06 - _time * 12.0, size.x + 400.0) - 200.0
		var cy := 90.0 + (i * 53) % 160 - cam.y * 0.03
		var cc := Color(1, 1, 1, 0.75)
		for j in 4:
			draw_circle(Vector2(cx + j * 34.0 - 50.0, cy + (8.0 if j % 2 else 0.0)), 30.0 + (j % 2) * 10.0, cc)
	_hills(size, cam, 0.12, size.y * 0.62, 70.0, 0.004, hills_far.lerp(Color.WHITE, flash * 0.5), 0.0)
	_hills(size, cam, 0.3, size.y * 0.78, 60.0, 0.007, hills_near.lerp(Color.WHITE, flash * 0.5), pulse * 8.0)


func _hills(size: Vector2, cam: Vector2, factor: float, base: float, amp: float, freq: float, c: Color, bob: float) -> void:
	var pts := PackedVector2Array()
	var y0 := base - cam.y * factor * 0.25 - bob
	pts.append(Vector2(0, size.y))
	var x := 0.0
	while x <= size.x + 16.0:
		var wx := x + cam.x * factor
		var y := y0 + amp * sin(wx * freq) * 0.6 + amp * 0.4 * sin(wx * freq * 2.3 + 1.7)
		pts.append(Vector2(x, y))
		x += 16.0
	pts.append(Vector2(size.x, size.y))
	draw_colored_polygon(pts, c)
	# little round trees on the near layer
	if factor > 0.2:
		var step := 260.0
		var start := floorf((cam.x * factor) / step) * step
		var wx2 := start
		while wx2 < cam.x * factor + size.x + step:
			var sx := wx2 - cam.x * factor + 60.0
			var sy := y0 + amp * sin((sx + cam.x * factor) * freq) * 0.6 + amp * 0.4 * sin((sx + cam.x * factor) * freq * 2.3 + 1.7)
			var tc := c.darkened(0.15)
			draw_rect(Rect2(sx - 4, sy - 30, 8, 34), tc.darkened(0.3))
			draw_circle(Vector2(sx, sy - 40 - bob * 0.5), 24.0, tc)
			wx2 += step
