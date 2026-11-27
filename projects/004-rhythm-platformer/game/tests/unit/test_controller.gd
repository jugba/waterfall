extends GutTest
## Controller physics promises, checked against data/movement.json with the real controller.

const DT := 1.0 / 60.0

var T: Dictionary


func before_all() -> void:
	T = Tuning.load_default()


func _flat() -> World:
	var w := World.new()
	w.add(Rect2(-5000, 0, 10000, 200))
	return w


func _ctl(w: World, at := Vector2.ZERO) -> PlayerController:
	var c := PlayerController.new(T, w)
	c.pos = at
	c.step(DT, InputFrame.new())  # settle onto the floor
	return c


func _inp(move := 0.0, press := false, hold := false) -> InputFrame:
	var i := InputFrame.new()
	i.move_x = move
	i.jump_pressed = press
	i.jump_held = hold or press
	return i


func _has(c: PlayerController, type: String) -> bool:
	return c.events.any(func(e): return e["type"] == type)


## Jump holding the button for `hold` frames; returns the peak height in px.
func _jump_height(hold: int) -> float:
	var c := _ctl(_flat())
	var top := 0.0
	for n in 240:
		c.step(DT, _inp(0.0, n == 0, n < hold))
		top = minf(top, c.pos.y)
		if n > 2 and c.on_floor:
			break
	return -top


func test_tap_and_full_jump_heights_in_range() -> void:
	var tap := _jump_height(1)
	var full := _jump_height(60)
	assert_between(tap, 45.0, 90.0, "tap jump is a hop (about one tile)")
	assert_between(full, 130.0, 175.0, "full jump is about three tiles")
	assert_gt(full, tap * 2.0, "holding matters: full jump > 2x tap")


func test_jump_height_grows_with_hold_time() -> void:
	var last := 0.0
	for hold in [1, 4, 8, 14]:
		var h := _jump_height(hold)
		assert_gt(h, last, "hold %d frames -> higher (%.0f px)" % [hold, h])
		last = h


func test_apex_hang_lowers_gravity_near_the_top() -> void:
	var c := _ctl(_flat())
	c.step(DT, _inp(0.0, true, true))
	var rise_dv := 0.0
	var apex_dv := 0.0
	for n in 60:
		var before := c.vel.y
		c.step(DT, _inp(0.0, false, true))
		var dv := c.vel.y - before
		if before < -400.0:
			rise_dv = dv
		elif absf(before) < 60.0 and c.vel.y < 100.0:
			apex_dv = dv
	assert_gt(rise_dv, 0.0)
	assert_lt(apex_dv, rise_dv * 0.7, "gravity is lower near the apex (apex hang)")


func _ledge_run(press_after_frames: int) -> PlayerController:
	# ledge ends at x = 0; drop of 400 px below
	var w := World.new()
	w.add(Rect2(-3000, 0, 3000, 200))
	w.add(Rect2(-3000, 400, 9000, 200))
	var c := _ctl(w, Vector2(-200, 0))
	c.vel.x = float(T["run"]["max_speed"])
	var off := -1
	for n in 120:
		var press := off >= 0 and n - off == press_after_frames
		c.step(DT, _inp(1.0, press, press))
		if press:
			return c
		if off < 0 and not c.on_floor:
			off = n
	return c


func test_coyote_time_allows_late_jump() -> void:
	var coyote: float = T["jump"]["coyote_time"]
	var late := int(coyote / DT) - 2
	var c := _ledge_run(late)
	assert_true(_has(c, "jump"), "jump %d frames after leaving the ledge still works" % late)
	assert_lt(c.vel.y, 0.0)


func test_no_jump_after_coyote_window() -> void:
	var coyote: float = T["jump"]["coyote_time"]
	var c := _ledge_run(int(coyote / DT) + 4)
	assert_false(_has(c, "jump"), "too late: no air jump")


func _drop_and_press(frames_before_landing: int) -> bool:
	# reference drop to find the landing frame
	var ref := _ctl(_flat(), Vector2(0, -160))
	var land := 0
	for n in 200:
		ref.step(DT, _inp())
		if ref.on_floor:
			land = n
			break
	var c := _ctl(_flat(), Vector2(0, -160))
	for n in land + 8:
		var press := n == land - frames_before_landing
		c.step(DT, _inp(0.0, press, press))
		if n > land and _has(c, "jump"):
			return true
		if n >= land and _has(c, "jump"):
			return true
	return false


func test_jump_buffer_jumps_on_landing() -> void:
	var buf: float = T["jump"]["buffer_time"]
	assert_true(_drop_and_press(int(buf / DT) - 2), "pressed just before landing -> jumps on touchdown")


func test_jump_buffer_expires() -> void:
	var buf: float = T["jump"]["buffer_time"]
	assert_false(_drop_and_press(int(buf / DT) + 6), "pressed too early -> no jump")


func _wall_world(wall_on_right: bool) -> World:
	var w := _flat()
	if wall_on_right:
		w.add(Rect2(100, -800, 60, 800))
	else:
		w.add(Rect2(-160, -800, 60, 800))
	return w


func _wall_jump(wall_on_right: bool) -> PlayerController:
	var side := 1.0 if wall_on_right else -1.0
	var c := PlayerController.new(T, _wall_world(wall_on_right))
	c.pos = Vector2(side * (100.0 - c.half_w), -300)
	c.vel = Vector2(0, 200)
	for n in 10:  # slide against the wall
		c.step(DT, _inp(side))
	assert_eq(c.wall_dir, int(side), "touching the wall")
	c.step(DT, _inp(side, true, true))
	return c


func test_wall_jump_pushes_away_from_right_wall() -> void:
	var c := _wall_jump(true)
	assert_true(_has(c, "wall_jump"))
	assert_lt(c.vel.x, -200.0, "away from the wall (left)")
	assert_lt(c.vel.y, -500.0, "and up")
	assert_eq(c.facing, -1, "faces away")


func test_wall_jump_pushes_away_from_left_wall() -> void:
	var c := _wall_jump(false)
	assert_true(_has(c, "wall_jump"))
	assert_gt(c.vel.x, 200.0, "away from the wall (right)")
	assert_lt(c.vel.y, -500.0)


func test_wall_slide_caps_fall_speed() -> void:
	var c := PlayerController.new(T, _wall_world(true))
	c.pos = Vector2(100.0 - c.half_w, -700)
	c.vel = Vector2(0, 0)
	for n in 60:
		c.step(DT, _inp(1.0))
	assert_true(c.wall_sliding)
	assert_lte(c.vel.y, float(T["wall"]["slide_max_speed"]) + 1.0)


func test_wall_run_climbs_when_sprinting_into_a_wall() -> void:
	var c := _ctl(_wall_world(true), Vector2(-300, 0))
	c.vel.x = float(T["run"]["max_speed"])
	var top := 0.0
	var ran := false
	for n in 90:
		c.step(DT, _inp(1.0))
		ran = ran or _has(c, "wall_run")
		top = minf(top, c.pos.y)
	assert_true(ran, "wall run started")
	assert_gt(-top, 90.0, "ran up the wall without jumping")


func test_glide_slows_the_fall_and_fast_fall_speeds_it_up() -> void:
	var speeds := {}
	for mode in ["none", "glide", "fast"]:
		var c := PlayerController.new(T, _flat())
		c.pos = Vector2(0, -9000)
		var i := InputFrame.new()
		i.jump_held = mode == "glide"
		i.down = mode == "fast"
		for n in 70:
			i.jump_pressed = mode == "glide" and n == 10
			c.step(DT, i)
		speeds[mode] = c.vel.y
	assert_lte(speeds["glide"], float(T["glide"]["max_fall_speed"]) + 1.0, "glide caps fall speed")
	assert_gt(speeds["none"], speeds["glide"] * 4.0)
	assert_gt(speeds["fast"], speeds["none"], "fast-fall is faster than a normal fall")


func test_run_accelerates_and_stops_quickly() -> void:
	var c := _ctl(_flat())
	var max_speed: float = T["run"]["max_speed"]
	var n := 0
	while c.vel.x < max_speed * 0.98 and n < 120:
		c.step(DT, _inp(1.0))
		n += 1
	assert_lt(n * DT, 0.4, "reaches top speed in < 0.4 s (%.2f s)" % (n * DT))
	var quarter := 0
	c = _ctl(_flat())
	for k in 6:
		c.step(DT, _inp(1.0))
	quarter = int(c.vel.x)
	assert_gt(quarter, max_speed * 0.3, "snappy start: > 30%% of top speed after 0.1 s")
	c.vel.x = max_speed
	n = 0
	while c.vel.x > 0.0 and n < 120:
		c.step(DT, _inp(0.0))
		n += 1
	assert_lt(n * DT, 0.3, "stops in < 0.3 s")


func test_dash_covers_distance_and_has_cooldown() -> void:
	var c := _ctl(_flat())
	var i := InputFrame.new()
	i.dash_pressed = true
	c.step(DT, i)
	assert_true(_has(c, "dash"))
	var x0 := c.pos.x
	i.dash_pressed = false
	for n in int(float(T["dash"]["time"]) / DT):
		c.step(DT, i)
	assert_gt(c.pos.x - x0, float(T["dash"]["speed"]) * float(T["dash"]["time"]) * 0.75)
	i.dash_pressed = true
	c.step(DT, i)
	assert_false(_has(c, "dash"), "cooldown blocks an instant second dash")


func test_punch_has_a_hitbox_in_front() -> void:
	var c := _ctl(_flat())
	var i := InputFrame.new()
	i.punch_pressed = true
	c.step(DT, i)
	assert_true(c.punch_active())
	assert_gt(c.punch_rect().position.x, c.pos.x, "facing right -> hitbox on the right")


func test_all_tuning_lives_in_one_file() -> void:
	for section in ["body", "run", "jump", "apex", "fall", "glide", "wall", "dash", "punch", "feel", "camera", "music"]:
		assert_true(T.has(section), "movement.json has [%s]" % section)
