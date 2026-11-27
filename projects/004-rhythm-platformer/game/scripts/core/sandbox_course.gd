class_name SandboxCourse
extends RefCounted
## The movement sandbox test course: one left-to-right route that teaches each move in turn
## and gates it with geometry that needs that move. Ground top is y = 0, up is negative.
##   run -> jump (tap vs hold) -> coyote gap -> wall-jump chimney -> wall-run cliff -> dash gap
##   -> punch crates (hitstop) -> glide canyon -> bounce pad + fast-fall -> goal

const BOUNCE_SPEED := 1300.0
const KILL_Y := 420.0

var world := World.new()
var crates: Array = []   # breakable solids
var pads: Array = []     # [{x0, x1, y}]
var flags: Array = []    # [{pos, active}]
var signs: Array = []    # [{pos, text}]
var lums: Array = []     # [{pos, alive}]
var goal := Vector2(7700, 0)
var sections: Array = []  # [{name, x}] (for tests and the debug teleport)


func _init() -> void:
	var D := 900.0
	_solid(-800, 0, 2700, D)            # start ground, x -800..1900
	_solid(1000, -60, 200, 60)          # ledge 1 (tap jump)
	_solid(1200, -150, 220, 150)        # ledge 2 (needs a held jump)
	_solid(2100, 0, 560, D)             # after the coyote gap (1900..2100)
	_solid(2440, -780, 60, 670)         # chimney left column (walk under it), taller than R
	_solid(2660, -720, 700, D + 720)    # mesa R (chimney right wall), top -720
	_solid(3360, -960, 400, D + 960)    # mesa W, reached by wall-run, top -960
	_solid(4180, -900, 700, D + 900)    # mesa P (after the dash gap), top -900
	_solid(5700, -500, 900, D + 500)    # mesa Q (after the glide canyon), top -500
	world.add(Rect2(6080, -830, 220, 18), "oneway")  # high plank reached by the bounce pad
	_solid(6600, 0, 1500, D)            # final ground
	_solid(8100, -1400, 120, 1400 + D)  # end wall
	_solid(-900, -1400, 100, 1400 + D)  # start wall
	# crates on mesa P: two singles, then a 3-high wall you must punch through
	for c in [Vector2(4330, -956), Vector2(4430, -956), Vector2(4640, -956), Vector2(4640, -1012), Vector2(4640, -1068)]:
		crates.append(world.add(Rect2(c, Vector2(56, 56)), "breakable", {"style": "crate"}))
	pads.append({"x0": 5880.0, "x1": 5944.0, "y": -500.0})

	_flag(0, 0); _flag(2200, 0); _flag(2780, -720); _flag(3480, -960); _flag(4240, -900)
	_flag(5780, -500); _flag(6720, 0)

	_sign(120, 0, "Run: A/D, arrows or left stick\nYou speed up, then cruise")
	_sign(820, 0, "Jump: Space / K or (A)\nTap = hop, hold = high jump")
	_sign(1700, 0, "Coyote time: jump just after\nthe edge still works")
	_sign(2290, 0, "Wall slide: hold toward a wall\nWall jump: jump off it")
	_sign(3050, -720, "Wall run: sprint (+jump) into\nthe cliff and hold toward it")
	_sign(3600, -960, "Dash: Shift / L or (B) / RT\nWorks once in the air too")
	_sign(4300, -900, "Punch: J / X or (X)\nSmash the crates")
	_sign(4800, -900, "Glide: hold Jump while falling")
	_sign(6000, -500, "Bounce! Then fast-fall:\nhold Down in the air")
	_sign(7200, 0, "Course complete!\nNow try the Music Level")

	sections = [
		{"name": "run", "x": 0.0}, {"name": "jump", "x": 900.0}, {"name": "coyote", "x": 1800.0},
		{"name": "wall_jump", "x": 2200.0}, {"name": "wall_run", "x": 2780.0},
		{"name": "dash", "x": 3480.0}, {"name": "punch", "x": 4240.0}, {"name": "glide", "x": 4800.0},
		{"name": "bounce_fast_fall", "x": 5780.0}, {"name": "goal", "x": 7700.0},
	]

	# lums: a ground row (chain sound), arcs over ledges and the gap, up the chimney,
	# along the dash line, down the glide canyon, up the bounce column
	_row(300, 760, -30, 52)
	_arc(Vector2(1100, -60), 90, 80, 5)
	_arc(Vector2(1310, -150), 100, 90, 5)
	_arc(Vector2(2000, 0), 120, 150, 7)
	for i in 8:
		_lum(Vector2(2525 + (i % 2) * 110, -80 - i * 72))
	_row(3200, 3330, -760, 40)
	_row(3800, 4140, -985, 48)
	for i in 10:
		_lum(Vector2(4960 + i * 70, -900 + i * 32))
	for i in 7:
		_lum(Vector2(5912, -600 - i * 50))
	_row(6100, 6300, -880, 50)
	for i in 6:
		_lum(Vector2(6420, -760 + i * 120))
	_row(6900, 7500, -30, 60)


func _solid(x: float, y: float, w: float, h: float) -> void:
	world.add(Rect2(x, y, w, h))


func _flag(x: float, y: float) -> void:
	flags.append({"pos": Vector2(x, y), "active": flags.is_empty()})


func _sign(x: float, y: float, text: String) -> void:
	signs.append({"pos": Vector2(x, y), "text": text})


func _lum(p: Vector2) -> void:
	for l in lums:
		if l["pos"].distance_to(p) < 20.0:
			return
	lums.append({"pos": p, "alive": true})


func _row(x0: float, x1: float, y: float, step: float) -> void:
	var x := x0
	while x <= x1:
		_lum(Vector2(x, y))
		x += step


func _arc(base: Vector2, half_w: float, height: float, n: int) -> void:
	for i in n:
		var k := float(i) / float(n - 1)
		var x := base.x - half_w + k * half_w * 2.0
		_lum(Vector2(x, base.y - 40.0 - height * (1.0 - pow(2.0 * k - 1.0, 2.0))))
