class_name PlayerController
extends RefCounted
## Pure 2D platformer controller: no nodes, fixed-step, deterministic, so tests and the music-level
## replay can simulate it exactly. Collision is axis-separated AABB against a World.
## Position is the FEET CENTRE (bottom middle of the hitbox). Y grows downwards.
##
## Usage: var c := PlayerController.new(Tuning.load_default(), world); c.step(1.0/60.0, input_frame)
## After each step, `events` lists what happened ({type: "jump"|"wall_jump"|"land"|"dash"|...}).

var T: Dictionary
var world: World

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := 1
var on_floor := false
var floor_solid = null  # Dictionary or null
var wall_dir := 0       # -1 touching a wall on the left, +1 on the right, 0 none
var gliding := false
var fast_falling := false
var wall_sliding := false
var events: Array = []
## Music mode: when set (float), the horizontal position is driven to this x every step.
var auto_run_x = null

# timers
var coyote := 0.0
var buffer := 0.0
var wall_coyote := 0.0
var last_wall_dir := 0
var control_lock := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var dashes_left := 1
var punch_t := 0.0
var punch_cd := 0.0
var punch_id := 0
var wallrun_t := 0.0
var wallrun_used := false
var jumping := false     # rising from a jump with variable height still in play
var jump_held := false
var air_time := 0.0

# derived constants
var gravity := 0.0
var jump_speed := 0.0
var half_w := 20.0
var height := 52.0


func _init(tuning: Dictionary, w: World = null) -> void:
	world = w if w else World.new()
	configure(tuning)


func configure(tuning: Dictionary) -> void:
	T = tuning
	var h: float = T["jump"]["height"]
	var ta: float = T["jump"]["time_to_apex"]
	gravity = 2.0 * h / (ta * ta)
	jump_speed = 2.0 * h / ta
	half_w = float(T["body"]["width"]) * 0.5
	height = float(T["body"]["height"])
	dashes_left = int(T["dash"]["air_dashes"])


func rect_at(p: Vector2) -> Rect2:
	return Rect2(p.x - half_w, p.y - height, half_w * 2.0, height)


func rect() -> Rect2:
	return rect_at(pos)


func punch_active() -> bool:
	return punch_t > 0.0


func punch_rect() -> Rect2:
	var r: float = T["punch"]["range"]
	var ph: float = T["punch"]["height"]
	var x0 := pos.x + half_w - 8.0 if facing > 0 else pos.x - half_w + 8.0 - r
	return Rect2(x0, pos.y - height * 0.5 - ph * 0.5, r, ph)


func is_dashing() -> bool:
	return dash_t > 0.0


func is_wall_running() -> bool:
	return wallrun_t > 0.0


## External launch (bounce pads).
func bounce(speed: float) -> void:
	vel.y = -speed
	on_floor = false
	floor_solid = null
	jumping = false
	gliding = false
	coyote = 0.0
	dashes_left = int(T["dash"]["air_dashes"])
	wallrun_used = false
	events.append({"type": "bounce"})


func step(dt: float, inp: InputFrame) -> void:
	events.clear()
	var run: Dictionary = T["run"]
	var wall: Dictionary = T["wall"]
	var max_speed: float = run["max_speed"]
	var mx := inp.move_x
	if absf(mx) < float(run["input_deadzone"]):
		mx = 0.0
	jump_held = inp.jump_held

	# timers
	buffer = maxf(buffer - dt, 0.0)
	dash_cd = maxf(dash_cd - dt, 0.0)
	punch_cd = maxf(punch_cd - dt, 0.0)
	punch_t = maxf(punch_t - dt, 0.0)
	control_lock = maxf(control_lock - dt, 0.0)
	if inp.jump_pressed:
		buffer = float(T["jump"]["buffer_time"])
	if mx != 0.0 and dash_t <= 0.0 and control_lock <= 0.0:
		facing = 1 if mx > 0.0 else -1

	# --- dash ---
	if inp.dash_pressed and dash_cd <= 0.0 and auto_run_x == null and (on_floor or dashes_left > 0):
		var d := facing if mx == 0.0 else (1 if mx > 0.0 else -1)
		facing = d
		dash_t = float(T["dash"]["time"])
		dash_cd = float(T["dash"]["cooldown"])
		if not on_floor:
			dashes_left -= 1
		vel = Vector2(d * float(T["dash"]["speed"]), 0.0)
		gliding = false
		wallrun_t = 0.0
		jumping = false
		events.append({"type": "dash", "dir": d})

	# --- punch ---
	if inp.punch_pressed and punch_cd <= 0.0:
		punch_t = float(T["punch"]["active_time"])
		punch_cd = float(T["punch"]["cooldown"])
		punch_id += 1
		if not on_floor and vel.y > 0.0:
			vel.y *= float(T["punch"]["air_hang"])
		if auto_run_x == null and dash_t <= 0.0:
			vel.x += facing * float(T["punch"]["lunge_speed"])
		events.append({"type": "punch"})

	# --- jump / wall jump (buffered) ---
	if buffer > 0.0 and dash_t <= 0.0:
		if on_floor or coyote > 0.0:
			_jump()
		elif auto_run_x == null and (wall_dir != 0 or wall_coyote > 0.0):
			_wall_jump(wall_dir if wall_dir != 0 else last_wall_dir)
	if inp.jump_pressed and not on_floor and vel.y > 0.0 and not jumping:
		gliding = true  # a fresh press while falling opens the glide

	# variable jump height: releasing early cuts the rise
	if jumping:
		if vel.y >= 0.0:
			jumping = false
		elif not jump_held:
			vel.y = maxf(vel.y, -jump_speed * float(T["jump"]["release_cut"]))
			jumping = false

	# --- horizontal ---
	if dash_t > 0.0:
		dash_t -= dt
		vel.y = 0.0
		if dash_t <= 0.0:
			vel.x *= float(T["dash"]["end_speed_mult"])
	elif auto_run_x != null:
		vel.x = clampf((float(auto_run_x) - pos.x) / dt, -max_speed * 4.0, max_speed * 4.0)
	else:
		var target := mx * max_speed * (float(T["glide"]["air_speed_mult"]) if gliding else 1.0)
		var frac := clampf(absf(vel.x) / max_speed, 0.0, 1.0)
		var a := 0.0
		if mx != 0.0 and vel.x != 0.0 and signf(mx) != signf(vel.x):
			a = float(run["turn_accel"]) if on_floor else float(run["accel_air"]) * 1.6
		elif mx != 0.0 and absf(vel.x) <= absf(target):
			a = (float(run["accel_ground"]) if on_floor else float(run["accel_air"])) \
				* Tuning.sample_curve(run["accel_curve"], frac)
		else:
			a = (float(run["decel_ground"]) if on_floor else float(run["decel_air"])) \
				* Tuning.sample_curve(run["decel_curve"], frac)
		if not on_floor and absf(vel.y) < float(T["apex"]["speed_threshold"]):
			a *= float(T["apex"]["air_accel_mult"])
		if control_lock > 0.0:
			a *= float(wall["control_lock_mult"])
		vel.x = move_toward(vel.x, target, a * dt)

	# --- vertical ---
	fast_falling = false
	wall_sliding = false
	if dash_t > 0.0:
		pass
	elif wallrun_t > 0.0:
		wallrun_t -= dt
		vel.y = -float(wall["run_speed"])
		if wall_dir == 0 or mx * wall_dir <= 0.0:
			wallrun_t = 0.0
	elif not on_floor:
		var g := gravity
		var max_fall: float = T["fall"]["max_speed"]
		var apex_thr: float = T["apex"]["speed_threshold"]
		if vel.y > 0.0:
			g *= float(T["fall"]["gravity_mult"])
		if absf(vel.y) < apex_thr and (jump_held or vel.y > 0.0):
			g *= float(T["apex"]["gravity_mult"])  # apex hang
		if inp.down and vel.y > -apex_thr:
			fast_falling = true
			gliding = false
			g = gravity * float(T["fall"]["fast_fall_gravity_mult"])
			max_fall = T["fall"]["fast_fall_max_speed"]
		if not jump_held:
			gliding = false
		elif not fast_falling and vel.y > float(T["glide"]["auto_start_fall_speed"]) and wall_dir == 0:
			gliding = true
		if gliding and vel.y > 0.0:
			g = gravity * float(T["glide"]["gravity_mult"])
			max_fall = T["glide"]["max_fall_speed"]
		if wall_dir != 0 and mx * wall_dir > 0.0 and vel.y > 0.0 and auto_run_x == null:
			wall_sliding = true
			gliding = false
			g *= float(wall["slide_gravity_mult"])
			max_fall = wall["slide_max_speed"]
		vel.y += g * dt
		if vel.y > max_fall:
			vel.y = move_toward(vel.y, max_fall, 3000.0 * dt)  # ease into glide / slide speed

	# --- move and collide ---
	var was_on_floor := on_floor
	var impact := vel.y
	var pre_vx := vel.x
	var hit_x := _move_x(vel.x * dt)
	if hit_x != 0:
		if dash_t > 0.0:
			dash_t = 0.0
		var need: float = float(wall["run_min_speed_frac"]) * max_speed
		if not wallrun_used and auto_run_x == null and absf(pre_vx) >= need \
				and mx * hit_x > 0.0 and (on_floor or vel.y < 0.0):
			wallrun_t = float(wall["run_time"])
			wallrun_used = true
			on_floor = false
			jumping = false
			events.append({"type": "wall_run", "dir": hit_x})
	_move_y(vel.y * dt)
	_probe_floor_and_walls()

	if on_floor:
		coyote = float(T["jump"]["coyote_time"])
		if not was_on_floor:
			events.append({"type": "land", "speed": impact})
			gliding = false
			dashes_left = int(T["dash"]["air_dashes"])
			wallrun_used = false
			wallrun_t = 0.0
		air_time = 0.0
	else:
		coyote = maxf(coyote - dt, 0.0)
		air_time += dt
		if was_on_floor and vel.y >= 0.0:
			events.append({"type": "leave_ground"})
	if wall_dir != 0 and not on_floor:
		wall_coyote = float(wall["coyote_time"])
		last_wall_dir = wall_dir
		dashes_left = int(T["dash"]["air_dashes"])
	else:
		wall_coyote = maxf(wall_coyote - dt, 0.0)


func _jump() -> void:
	vel.y = -jump_speed
	on_floor = false
	floor_solid = null
	coyote = 0.0
	buffer = 0.0
	jumping = true
	gliding = false
	events.append({"type": "jump"})


func _wall_jump(dir: int) -> void:
	var wall: Dictionary = T["wall"]
	vel.x = -dir * float(wall["jump_speed_x"])
	vel.y = -float(wall["jump_speed_y"])
	facing = -dir
	control_lock = float(wall["control_lock_time"])
	buffer = 0.0
	wall_coyote = 0.0
	wallrun_t = 0.0
	jumping = true
	gliding = false
	events.append({"type": "wall_jump", "dir": -dir})


func _blocks(s: Dictionary) -> bool:
	return s["kind"] != "oneway"


func _move_x(dx: float) -> int:
	if dx == 0.0:
		return 0
	pos.x += dx
	var hit := 0
	for s in world.query(rect()):
		if not _blocks(s):
			continue
		var r: Rect2 = s["rect"]
		if dx > 0.0:
			pos.x = minf(pos.x, r.position.x - half_w)
			hit = 1
		else:
			pos.x = maxf(pos.x, r.end.x + half_w)
			hit = -1
	if hit != 0:
		vel.x = 0.0
	return hit


func _move_y(dy: float) -> void:
	if dy == 0.0:
		return
	var prev_bottom := pos.y
	pos.y += dy
	for s in world.query(rect()):
		var r: Rect2 = s["rect"]
		if dy > 0.0:
			if s["kind"] == "oneway" and prev_bottom > r.position.y + 0.5:
				continue
			if pos.y > r.position.y:
				pos.y = r.position.y
				vel.y = 0.0
				on_floor = true
				floor_solid = s
		elif _blocks(s):
			# corner correction: slide round a ceiling corner we only clip by a few pixels
			var me := rect()
			var left_overlap := me.end.x - r.position.x
			var right_overlap := r.end.x - me.position.x
			if left_overlap > 0.0 and left_overlap <= 12.0 and auto_run_x == null:
				pos.x -= left_overlap
				continue
			if right_overlap > 0.0 and right_overlap <= 12.0 and auto_run_x == null:
				pos.x += right_overlap
				continue
			pos.y = r.end.y + height
			vel.y = 0.0
			jumping = false
			events.append({"type": "bonk"})


func _probe_floor_and_walls() -> void:
	if vel.y >= 0.0:
		var below := Rect2(pos.x - half_w, pos.y, half_w * 2.0, 1.0)
		var found = null
		for s in world.query(below):
			var r: Rect2 = s["rect"]
			if absf(r.position.y - pos.y) <= 0.75:
				found = s
				break
		on_floor = found != null
		floor_solid = found
	else:
		on_floor = false
		floor_solid = null
	wall_dir = 0
	var r := rect().grow_individual(0.0, -4.0, 0.0, -4.0)
	for s in world.query(Rect2(r.end.x, r.position.y, 1.0, r.size.y)):
		if _blocks(s):
			wall_dir = 1
			break
	if wall_dir == 0:
		for s in world.query(Rect2(r.position.x - 1.0, r.position.y, 1.0, r.size.y)):
			if _blocks(s):
				wall_dir = -1
				break
