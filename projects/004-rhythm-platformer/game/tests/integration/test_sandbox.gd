extends GutTest
## Movement sandbox loads, has every teaching section, and its gates need the move they teach.

const DT := 1.0 / 60.0

var level: Node


func before_each() -> void:
	level = add_child_autofree(load("res://scenes/sandbox.tscn").instantiate())


func _inp(move := 0.0, press := false, hold := false) -> InputFrame:
	var i := InputFrame.new()
	i.move_x = move
	i.jump_pressed = press
	i.jump_held = hold or press
	return i


func test_sandbox_loads_with_all_sections() -> void:
	await wait_physics_frames(5)
	assert_not_null(level.ctl)
	assert_not_null(level.hero)
	assert_gt(level.lums_total, 40, "plenty of collectibles")
	assert_eq(level.course.crates.size(), 5)
	assert_gte(level.course.signs.size(), 9)
	var names: Array = level.course.sections.map(func(s): return s["name"])
	for n in ["run", "jump", "coyote", "wall_jump", "wall_run", "dash", "punch", "glide", "bounce_fast_fall", "goal"]:
		assert_has(names, n)


func test_glide_canyon_needs_the_glide() -> void:
	for glide in [false, true]:
		level.goto_section("glide")
		level.ctl.pos.x = 4760.0  # past the crate wall
		var reached := false
		for f in 600:
			var steer := 1.0 if level.ctl.pos.x < 5850.0 else 0.0  # steer onto the landing mesa
			level.sim_step(DT, _inp(steer, f == 10, glide and f >= 10))
			if level.ctl.on_floor and level.ctl.pos.y <= -499.0 and level.ctl.pos.x > 5700.0:
				reached = true
				break
		assert_eq(reached, glide, "glide %s -> crosses: %s" % [glide, reached])


func test_crate_wall_needs_punches() -> void:
	level.goto_section("punch")
	for f in 400:
		var i := _inp(1.0)
		i.punch_pressed = f % 20 == 0
		level.sim_step(DT, i)
		if level.ctl.pos.x > 4720.0:
			break
	assert_gt(level.ctl.pos.x, 4720.0, "punched through the crate wall")
	assert_eq(level.course.crates.filter(func(c): return c["alive"]).size(), 0)


func test_wall_run_reaches_the_high_cliff() -> void:
	level.goto_section("wall_run")
	var top := false
	for f in 300:
		# sprint, jump near the cliff, keep holding toward it, jump off the top
		var near: bool = level.ctl.pos.x > 3260.0
		level.sim_step(DT, _inp(1.0, near and level.ctl.on_floor, near))
		if level.ctl.on_floor and level.ctl.pos.y <= -959.0:
			top = true
			break
	assert_true(top, "reached the top of the wall-run cliff")


func test_chimney_is_climbable_with_wall_jumps() -> void:
	level.goto_section("wall_jump")
	var ctl: PlayerController = level.ctl
	var dir := 1.0
	var hold := 0
	var top := false
	for f in 600:
		var i := _inp(dir)
		if ctl.on_floor and ctl.pos.x > 2560.0:
			i.jump_pressed = true
			hold = 14
		elif not ctl.on_floor and ctl.wall_dir != 0 and ctl.vel.y > -150.0:
			i.jump_pressed = true  # wall jump, then steer toward the other wall
			hold = 14
			dir = -ctl.wall_dir
		if ctl.pos.y < -690.0:
			dir = 1.0
		i.jump_held = hold > 0
		hold -= 1
		level.sim_step(DT, i)
		if ctl.on_floor and ctl.pos.y <= -719.0:
			top = true
			break
	assert_true(top, "wall-jumped up the chimney onto the cliff")


func test_dash_crosses_the_dash_gap() -> void:
	for use_dash in [false, true]:
		level.goto_section("dash")
		var ctl: PlayerController = level.ctl
		var crossed := false
		var dashed := false
		var jumped_at := -100
		for f in 300:
			var i := _inp(1.0)
			if ctl.on_floor and ctl.pos.x > 3700.0 and jumped_at < 0:
				i.jump_pressed = true
				jumped_at = f
			i.jump_held = f - jumped_at < 14  # full jump, released before it turns into a glide
			if use_dash and not dashed and not ctl.on_floor and ctl.pos.x > 3790.0:
				i.dash_pressed = true
				dashed = true
			level.sim_step(DT, i)
			if ctl.on_floor and ctl.pos.x > 4180.0 and ctl.pos.y <= -899.0:
				crossed = true
				break
		assert_eq(crossed, use_dash, "dash %s -> crosses with a full jump: %s" % [use_dash, crossed])
