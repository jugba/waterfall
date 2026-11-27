class_name MusicCourse
extends RefCounted
## Builds the music level's geometry from the beat map: the runner's x is locked to audio time
## (x = run_speed * t), so an event at time t sits at x(t) and is reached exactly on its beat.
## jump/long_jump -> a pit just after x(t); punch -> a tall drum block; bounce -> a pad at x(t)
## with a pit after it; bounce_glide -> a pad and a canyon you only clear by gliding.
## Lums are placed on their beat ON the ideal trajectory (simulated with ideal_inputs()).

const GROUND_Y := 0.0
const PIT_DEPTH := 900.0
const DT := 1.0 / 60.0
const BOUNCE_SPEED := 1050.0
const BLOCK_W := 56.0
const BLOCK_H := 170.0
const LUM_RADIUS := 40.0

var map: Beatmap
var T: Dictionary
var run_speed := 400.0
var world := World.new()
var holes: Array = []        # [Vector2(x0, x1)]
var grounds: Array = []      # [Vector2(x0, x1)] solid ground spans (for drawing)
var blocks: Array = []       # world solids of kind "breakable", data {time}
var pads: Array = []         # [{x0, x1, time, glide}]
var checkpoints: Array = []  # [{time, x}]
var end_time := 0.0
var end_x := 0.0
var lums: Array = []         # [{time, pos}]
var length_x := 0.0
# measured at build time with the real controller
var tap_air := 0.0
var bounce_air := 0.0
var glide_air := 0.0


func _init(beatmap: Beatmap, tuning: Dictionary) -> void:
	map = beatmap
	T = tuning
	run_speed = float(T["music"]["run_speed"])
	_measure()
	_build()


func x_of(time: float) -> float:
	return run_speed * time


func _measure() -> void:
	tap_air = _air_time(func(_i): return {"press": _i == 0, "hold": _i < 1}, false)
	bounce_air = _air_time(func(_i): return {"press": false, "hold": false}, true)
	glide_air = _air_time(func(_i): return {"press": _i == 20, "hold": _i >= 20}, true)


func _air_time(inp: Callable, bounce: bool) -> float:
	var w := World.new()
	w.add(Rect2(-100000, GROUND_Y, 200000, 100))
	var c := PlayerController.new(T, w)
	c.step(DT, InputFrame.new())
	if bounce:
		c.bounce(BOUNCE_SPEED)
	var n := 0
	while n < 1200:
		var d: Dictionary = inp.call(n)
		var f := InputFrame.new()
		f.jump_pressed = d["press"]
		f.jump_held = d["hold"]
		c.step(DT, f)
		n += 1
		if c.on_floor:
			break
	return n * DT


func _build() -> void:
	var raw_holes: Array = []
	for e in map.events:
		var t: float = e["time"]
		var x := x_of(t)
		match e["type"]:
			"jump":
				raw_holes.append(Vector2(x + 20.0, x + 150.0))
			"long_jump":
				raw_holes.append(Vector2(x + 20.0, x + 235.0))
			"punch":
				var b := world.add(Rect2(x + 70.0, GROUND_Y - BLOCK_H, BLOCK_W, BLOCK_H), "breakable", {"time": t})
				blocks.append(b)
			"bounce", "bounce_glide":
				var glide: bool = e["type"] == "bounce_glide"
				pads.append({"x0": x, "x1": x + 64.0, "time": t, "glide": glide})
				var air := glide_air if glide else bounce_air
				var land := x + run_speed * air
				var noglide_land := x + run_speed * bounce_air
				var x1 := land - 90.0
				if glide:
					x1 = maxf(noglide_land + 120.0, land - 160.0)
				raw_holes.append(Vector2(x + 110.0, x1))
			"checkpoint":
				checkpoints.append({"time": t, "x": x})
			"end":
				end_time = t
				end_x = x
	holes = raw_holes
	length_x = x_of(map.duration) + 1200.0
	# ground = everything between holes
	var cursor := -800.0
	for h in holes:
		grounds.append(Vector2(cursor, h.x))
		cursor = h.y
	grounds.append(Vector2(cursor, length_x))
	for g in grounds:
		world.add(Rect2(g.x, GROUND_Y, g.y - g.x, PIT_DEPTH))
	_place_lums()


## Frame-indexed ideal input script: press on the exact beat of every event.
func ideal_inputs() -> Dictionary:
	var presses := {}  # frame -> {jump_press, jump_hold_frames, punch}
	var holds := {}    # frame -> true (jump held)
	for e in map.events:
		var f := int(ceilf(e["time"] / DT - 0.0001))
		match e["type"]:
			"jump":
				_mark(presses, f, "jump")
				for k in range(f, f + 3):
					holds[k] = true
			"long_jump":
				_mark(presses, f, "jump")
				for k in range(f, f + 18):
					holds[k] = true
			"punch":
				_mark(presses, f, "punch")
			"bounce_glide":
				var g0 := f + 24
				_mark(presses, g0, "jump")
				for k in range(g0, f + int(glide_air / DT) + 30):
					holds[k] = true
	return {"presses": presses, "holds": holds}


static func _mark(d: Dictionary, f: int, what: String) -> void:
	if not d.has(f):
		d[f] = {}
	d[f][what] = true


static func input_for_frame(script: Dictionary, frame: int) -> InputFrame:
	var i := InputFrame.new()
	var p: Dictionary = script["presses"].get(frame, {})
	i.jump_pressed = p.has("jump")
	i.punch_pressed = p.has("punch")
	i.jump_held = script["holds"].has(frame) or i.jump_pressed
	return i


func _place_lums() -> void:
	# simulate the ideal run (blocks broken by punches as they would be) to get the path
	var run := MusicRun.new(self, true)
	var script := ideal_inputs()
	var path: Array = []  # [time, centre]
	var frame := 0
	var stop := map.duration
	while frame * DT < stop and run.state != MusicRun.State.DONE and run.state != MusicRun.State.DEAD:
		run.step(frame * DT, DT, input_for_frame(script, frame))
		path.append([frame * DT, run.ctl.pos + Vector2(0, -run.ctl.height * 0.5)])
		frame += 1
	for b in blocks:
		b["alive"] = true
	for e in map.events:
		if e["type"] != "lum":
			continue
		var t: float = e["time"]
		var idx := clampi(int(t / DT), 0, path.size() - 1)
		if path.is_empty():
			break
		var p: Vector2 = path[idx][1]
		if idx + 1 < path.size():
			var k: float = (t - path[idx][0]) / DT
			p = p.lerp(path[idx + 1][1], clampf(k, 0.0, 1.0))
		lums.append({"time": t, "pos": p + Vector2(0, -6)})


func reset_blocks_after(time: float) -> void:
	for b in blocks:
		if b["data"]["time"] >= time:
			b["alive"] = true
