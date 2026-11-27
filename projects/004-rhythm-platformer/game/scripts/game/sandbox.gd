extends LevelBase
## Movement Sandbox: the test course that teaches every move (see SandboxCourse).
## Debug: F5 reloads data/movement.json live; T / Back jumps to the next section.

const LUM_CHAIN_GAP := 0.75

var course: SandboxCourse
var flag_index := 0
var hitstop := 0.0
var finished := false
var chain := 0
var _time := 0.0
var _last_lum := -10.0
## Optional scripted input for captures/tests: Callable(frame: int) -> InputFrame
var scripted_input: Callable
var _frame := 0


func _ready() -> void:
	T = Tuning.load_default()
	course = SandboxCourse.new()
	world = course.world
	ctl = PlayerController.new(T, world)
	ctl.pos = course.flags[0]["pos"]
	ctl.on_floor = true
	_build_stage()
	world_view.pads = course.pads
	world_view.flags = course.flags
	world_view.signs = course.signs
	world_view.goal = course.goal
	lum_view.lums = course.lums
	lums_total = course.lums.size()
	hint_label.text = controls_hint() + "   T/Back: next section"
	info_label.text = "Movement Sandbox"
	var shot := _arg_value("--shot=")
	if shot != "" and OS.is_debug_build():
		goto_section(shot)


func _arg_value(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


func goto_section(name: String) -> void:
	for s in course.sections:
		if s["name"] == name:
			_teleport_x(float(s["x"]))


func _teleport_x(x: float) -> void:
	# stand on the highest surface near x
	var best_y := 10000.0
	for s in world.solids:
		var r: Rect2 = s["rect"]
		if s["kind"] != "oneway" and x >= r.position.x and x <= r.end.x and r.position.y < best_y:
			best_y = r.position.y
	ctl.pos = Vector2(x, best_y)
	ctl.vel = Vector2.ZERO
	ctl.on_floor = true
	hero.teleport()
	cam.snap()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F5:
			T = Tuning.load_default(true)
			ctl.configure(T)
			show_center("Tuning reloaded", 0.8)
		elif event.physical_keycode == KEY_T:
			_next_section()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
		_next_section()


func _next_section() -> void:
	for s in course.sections:
		if float(s["x"]) > ctl.pos.x + 50.0:
			_teleport_x(float(s["x"]))
			return
	_teleport_x(float(course.sections[0]["x"]))


func _physics_process(delta: float) -> void:
	_time += delta
	if hitstop > 0.0:
		hitstop -= delta
		hero.frozen = true
		return
	hero.frozen = false
	var inp: InputFrame
	if scripted_input.is_valid():
		inp = scripted_input.call(_frame)
	elif is_autoplay():
		inp = _bot()
	else:
		inp = InputFrame.from_input()
	_frame += 1
	sim_step(delta, inp)


## One fixed step of gameplay (also called directly by tests).
func sim_step(delta: float, inp: InputFrame) -> void:
	ctl.step(delta, inp)
	_check_punch()
	_check_pads()
	_check_lums()
	_check_flags()
	if ctl.pos.y > SandboxCourse.KILL_Y:
		_respawn()
	if not finished and ctl.pos.x >= course.goal.x - 20.0:
		finished = true
		Sfx.play("win", -3.0)
		show_center("Course complete!", 2.0)
		fx.sparks(ctl.pos + Vector2(0, -60), 30, Color(1, 0.9, 0.4), 500.0)
	hero.sync()


func _check_punch() -> void:
	if not ctl.punch_active():
		return
	var pr := ctl.punch_rect()
	for c in course.crates:
		if c["alive"] and pr.intersects(c["rect"]):
			c["alive"] = false
			var r: Rect2 = c["rect"]
			hitstop = float(T["punch"]["hitstop"])
			cam.add_shake(float(T["feel"]["shake_punch"]))
			fx.sparks(r.get_center(), 14, Color(0.93, 0.7, 0.38), 420.0)
			fx.ring(r.get_center(), 60.0, Color(1, 1, 1, 0.9), 0.2)
			fx.popup(r.get_center() + Vector2(0, -40), "POW!", Color(1.0, 0.55, 0.3), 40)
			Sfx.play("hit", -2.0)
			Sfx.play("break", -6.0)
			hero.grin()
			# crates stacked on top drop down one slot
			for above in course.crates:
				var ar: Rect2 = above["rect"]
				if above["alive"] and is_equal_approx(ar.position.x, r.position.x) and ar.position.y < r.position.y:
					above["rect"] = Rect2(ar.position + Vector2(0, r.size.y), ar.size)
			return


func _check_pads() -> void:
	if not ctl.on_floor:
		return
	for p in course.pads:
		if ctl.pos.x >= p["x0"] - 8.0 and ctl.pos.x <= p["x1"] + 8.0 and absf(ctl.pos.y - p["y"]) < 2.0:
			ctl.bounce(SandboxCourse.BOUNCE_SPEED)
			p["squash"] = 1.0
			fx.ring(Vector2((p["x0"] + p["x1"]) * 0.5, p["y"]), 70.0, Color(1, 0.6, 0.85), 0.3)


func _check_lums() -> void:
	var centre := ctl.pos + Vector2(0, -ctl.height * 0.5)
	for l in course.lums:
		if l["alive"] and centre.distance_to(l["pos"]) <= 40.0:
			l["alive"] = false
			chain = chain + 1 if _time - _last_lum <= LUM_CHAIN_GAP else 0
			_last_lum = _time
			collect_lum(l["pos"], chain)


func _check_flags() -> void:
	for i in course.flags.size():
		var f: Dictionary = course.flags[i]
		if i > flag_index and ctl.pos.x >= f["pos"].x and absf(ctl.pos.y - f["pos"].y) < 150.0:
			course.flags[flag_index]["active"] = false
			flag_index = i
			f["active"] = true
			Sfx.play("checkpoint", -6.0)
			fx.sparks(f["pos"] + Vector2(20, -100), 12, Color(0.4, 1.0, 0.6), 300.0)


func _respawn() -> void:
	Sfx.play("death", -8.0)
	ctl.pos = course.flags[flag_index]["pos"]
	ctl.vel = Vector2.ZERO
	ctl.on_floor = true
	hero.teleport()
	fx.dust(ctl.pos, 10, Vector2.ZERO)
	cam.add_shake(6.0)


## Tiny demo bot for --autoplay captures: run right, jump at edges/walls, punch crates,
## glide over gaps, dash across them.
var _bot_hold := 0
var _bot_dashed := false


func _bot() -> InputFrame:
	var i := InputFrame.new()
	i.move_x = 1.0
	var front := Rect2(ctl.pos.x + ctl.half_w, ctl.pos.y - 48.0, 70.0, 44.0)
	var blocked := false
	for s in world.query(front):
		if s["kind"] == "breakable":
			i.punch_pressed = _frame % 12 == 0
		elif s["kind"] != "oneway":
			blocked = true
	var floor_ahead := not world.query(Rect2(ctl.pos.x + 40.0, ctl.pos.y, 10.0, 8.0)).is_empty()
	if ctl.on_floor:
		_bot_dashed = false
		if blocked or not floor_ahead:
			i.jump_pressed = true
			_bot_hold = 16
	elif not _bot_dashed and ctl.vel.y > -100.0 and world.query(Rect2(ctl.pos.x, ctl.pos.y, 40.0, 400.0)).is_empty():
		i.dash_pressed = true
		_bot_dashed = true
	if _bot_hold > 0:
		_bot_hold -= 1
		i.jump_held = true
	elif not ctl.on_floor and ctl.vel.y > 0.0:
		i.jump_held = true  # glide
	return i
