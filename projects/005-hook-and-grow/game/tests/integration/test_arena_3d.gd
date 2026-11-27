extends GutTest
## The "3D Arena (test)" mode: it loads, mouse aim maps through the camera onto the play plane,
## it plays exactly like the 2D mode for the same inputs (both run the shared ArenaSim through the
## shared ArenaDriver), and the bot can play waves 1-2 in it.

const SCENE_2D := "res://scenes/game.tscn"
const SCENE_3D := "res://scenes/game_3d.tscn"
const DT := 1.0 / 60.0

var _orig_save_dir: String


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	SaveGame.directory = "user://test_3d_saves"


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir


func _make(path: String, seed_value: int) -> Node:
	var g: Node = load(path).instantiate()
	g.seed_value = seed_value
	add_child_autofree(g)
	g.set_physics_process(false)  # the test calls tick() itself, frame by frame
	return g


# --- loads -------------------------------------------------------------------------------------

func test_title_offers_the_3d_mode() -> void:
	var title: Node = add_child_autofree(load("res://scenes/title.tscn").instantiate())
	var b: Button = title.get_node("%Play3D")
	assert_not_null(b)
	assert_string_contains(b.text, "3D")
	assert_true(ResourceLoader.exists(title.GAME_3D_SCENE))


func test_3d_scene_loads_with_camera_world_and_creatures() -> void:
	var g := _make(SCENE_3D, 7)
	var sim: ArenaSim = g.sim
	assert_not_null(sim)
	assert_not_null(g.driver)
	var cam: Camera3D = g.camera
	assert_true(cam.current, "camera is current")
	var pitch := rad_to_deg(-cam.global_transform.basis.get_euler().x)
	assert_almost_eq(pitch, 55.0, 2.0, "camera looks down at ~55 degrees")
	var env: Environment = g.world_env.environment
	assert_true(env.fog_enabled, "underwater fog")
	assert_not_null(g.get_node("Seabed3D/Seabed"), "seabed")
	assert_not_null(g.get_node("Seabed3D/Kelp"), "kelp")
	assert_not_null(g.get_node("Seabed3D/GodRay0"), "god rays")
	assert_not_null(g.morsel, "Morsel")
	for i in 5:
		g.tick(DT)
	assert_eq(g._creatures.size(), sim.enemies.size(), "one 3D creature per enemy")
	for e in sim.enemies:
		var c: Creature3D = g._creatures[e.id]
		assert_almost_eq(c.position.x, e.pos.x * ArenaSpace.S, 0.05)
		assert_almost_eq(c.position.z, e.pos.y * ArenaSpace.S, 0.05)


func test_camera_pulls_back_as_morsel_grows() -> void:
	var g := _make(SCENE_3D, 7)
	var sim: ArenaSim = g.sim
	sim.clear_for_test()
	var d0: float = g.camera.global_position.distance_to(g.morsel.global_position)
	sim.mass = Growth.mass_from_size(sim.B, 7.5)
	sim._recalc()
	for i in 240:
		g.tick(DT)
	var d1: float = g.camera.global_position.distance_to(g.morsel.global_position)
	assert_gt(d1, d0 * 1.4, "camera distance %.2f -> %.2f" % [d0, d1])
	assert_gt(g.morsel.rig.scale.y, 0.18 * 2.0, "body scaled up")
	assert_gt(g.morsel.shadow.scale.x, 0.18 * 2.0, "shadow blob scaled up")


# --- mouse aim -----------------------------------------------------------------------------------

func test_ray_to_plane_math() -> void:
	var hit = ArenaSpace.ray_to_plane(Vector3(1, 10, 2), Vector3(0, -1, 0), 0.5)
	assert_almost_eq((hit as Vector3).distance_to(Vector3(1, 0.5, 2)), 0.0, 0.0001)
	hit = ArenaSpace.ray_to_plane(Vector3(0, 10, 0), Vector3(1, -1, 0).normalized(), 0.0)
	assert_almost_eq((hit as Vector3).distance_to(Vector3(10, 0, 0)), 0.0, 0.0001)
	assert_null(ArenaSpace.ray_to_plane(Vector3(0, 10, 0), Vector3(1, 0, 0), 0.0), "parallel")
	assert_null(ArenaSpace.ray_to_plane(Vector3(0, 10, 0), Vector3(0, 1, 0), 0.0), "points away")
	var p := Vector2(123.0, -456.0)
	assert_almost_eq(ArenaSpace.to_sim(ArenaSpace.to_world(p, 3.0)).distance_to(p), 0.0, 0.001)


func test_mouse_on_screen_maps_to_the_same_point_on_the_play_plane() -> void:
	var g := _make(SCENE_3D, 7)
	var sim: ArenaSim = g.sim
	var cam: Camera3D = g.camera
	for a in 12:
		var target: Vector2 = sim.pos + Vector2.from_angle(TAU * a / 12.0) * 150.0
		var screen := cam.unproject_position(ArenaSpace.to_world(target, g.play_y))
		var back: Vector2 = g.mouse_sim(screen)
		assert_almost_eq(back.distance_to(target), 0.0, 0.5, "angle %d" % a)
		# and the InputFrame aims from Morsel straight at the cursor
		var f := ArenaDriver.make_frame(sim, Vector2.ZERO, Vector2.ZERO, false, back, false, false, false)
		assert_almost_eq(f.aim.angle_to((target - sim.pos).normalized()), 0.0, 0.01)


func test_screen_directions_match_the_2d_layout() -> void:
	# cursor above Morsel on screen aims "up" in the sim (-y), right aims +x, as in 2D
	var g := _make(SCENE_3D, 7)
	var sim: ArenaSim = g.sim
	var me: Vector2 = g.camera.unproject_position(ArenaSpace.to_world(sim.pos, g.play_y))
	var up: Vector2 = g.mouse_sim(me + Vector2(0, -120)) - sim.pos
	var right: Vector2 = g.mouse_sim(me + Vector2(120, 0)) - sim.pos
	assert_lt(up.normalized().y, -0.95, "screen up = sim up")
	assert_gt(right.normalized().x, 0.95, "screen right = sim right")


func test_controller_aim_ignores_the_mouse_and_keeps_assist() -> void:
	var sim := ArenaSim.new(Balance.copy(), 3)
	sim.clear_for_test()
	var stick := Vector2(0.0, 1.0)
	var f := ArenaDriver.make_frame(sim, Vector2.ZERO, stick, true, sim.pos + Vector2(500, 0), false, false, false)
	assert_almost_eq(f.aim.angle_to(Vector2.DOWN), 0.0, 0.0001, "stick wins over the mouse")
	var e = sim.spawn("nibbler", sim.pos + Vector2(20, 150), 1.5)
	f = ArenaDriver.make_frame(sim, Vector2.ZERO, stick, true, Vector2.ZERO, true, false, false)
	assert_almost_eq(f.aim.angle_to((e.pos - sim.pos).normalized()), 0.0, 0.0001, "assist snaps in the 12 deg cone")


# --- same gameplay in 2D and 3D ------------------------------------------------------------------

## A fixed input tape: wandering movement, a sweeping aim, hook presses (throws and yanks) and dodges.
func _tape(n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var out: Array = []
	var aim_a := 0.0
	for i in n:
		aim_a += rng.randf_range(-0.05, 0.12)
		var mv := Vector2(cos(i * 0.011), sin(i * 0.017)) * (0.9 if (i / 90) % 3 != 2 else 0.0)
		out.append(InputFrame.make(mv, Vector2.from_angle(aim_a), i % 9 == 0, i % 170 == 85))
	return out


func _run_tape(path: String, tape: Array, checkpoints: Array) -> Array:
	var snaps: Array = []
	if path == "":
		var sim := ArenaSim.new(Balance.copy(), 1234)
		var d := ArenaDriver.new(sim)
		d.script_input = func(dr: ArenaDriver) -> InputFrame: return tape[dr.ticks - 1]
		for i in tape.size():
			d.tick(DT, false, Callable())
			if checkpoints.has(i + 1):
				snaps.append(sim.snapshot())
		return snaps
	var g := _make(path, 1234)
	g.driver.script_input = func(dr: ArenaDriver) -> InputFrame: return tape[dr.ticks - 1]
	for i in tape.size():
		g.tick(DT)
		if checkpoints.has(i + 1):
			snaps.append(g.sim.snapshot())
	return snaps


func test_2d_and_3d_give_identical_gameplay_for_the_same_inputs() -> void:
	var n := 60 * 30
	var tape := _tape(n)
	var cps := [60, 300, 600, 900, 1200, 1500, n]
	var bare := _run_tape("", tape, cps)
	var s2 := _run_tape(SCENE_2D, tape, cps)
	var s3 := _run_tape(SCENE_3D, tape, cps)
	assert_eq(s2.size(), cps.size())
	assert_eq(s3.size(), cps.size())
	var last: Dictionary = bare[bare.size() - 1]
	assert_gt(int(last["meals"]), 0, "the tape actually eats something (meals %d)" % last["meals"])
	for i in cps.size():
		assert_eq(s2[i], bare[i], "2D == shared sim at frame %d" % cps[i])
		assert_eq(s3[i], bare[i], "3D == shared sim at frame %d" % cps[i])


func test_2d_and_3d_identical_with_the_bot_through_hitstops() -> void:
	var snaps: Array = []
	for path in [SCENE_2D, SCENE_3D]:
		var g := _make(path, 4321)
		g.bot = Bot.new(77)
		var stops := 0
		for i in 60 * 20:
			g.tick(DT)
			if g.driver.hitstop > 0.0:
				stops += 1
		assert_gt(stops, 0, "%s had hitstop frames" % path)
		snaps.append(g.sim.snapshot())
	assert_gt(int(snaps[0]["meals"]), 3)
	assert_eq(snaps[1], snaps[0], "bot run: 3D state == 2D state after 20 s")


# --- smoke: waves 1-2 in 3D ------------------------------------------------------------------------

func test_bot_plays_waves_1_and_2_in_3d() -> void:
	var g := _make(SCENE_3D, 11)
	var sim: ArenaSim = g.sim
	g.bot = Bot.new(12)
	var frames := 0
	var max_creatures := 0
	while sim.wave < 2 and frames < 60 * 240:
		g.tick(DT)
		frames += 1
		max_creatures = maxi(max_creatures, g._creatures.size())
	assert_gte(sim.wave, 2, "reached wave 3 after %.0f s of sim time" % sim.time)
	assert_gt(sim.meals, 20, "ate its way through")
	assert_gt(sim.size, 3.5, "grew")
	assert_gt(max_creatures, 3, "3D creatures were spawned")
	assert_eq(g._creatures.size(), sim.enemies.size(), "views track the sim")
	assert_almost_eq(g.morsel.position.x, sim.pos.x * ArenaSpace.S, 0.001)
	assert_true(g.morsel.rig.scale.x > 0.0)
