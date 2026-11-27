extends GutTest
## Hook physics: throw range, catch, struggle + yank + reel, eat, and the ways a hook bounces off
## (too big, armoured front, spiky puffer). Everything runs on the node-free ArenaSim.

var sim: ArenaSim


func before_each() -> void:
	sim = ArenaSim.new(Balance.copy(), 11)
	sim.clear_for_test()


func _run(seconds: float, f: InputFrame = null) -> void:
	if f == null:
		f = InputFrame.new()
	var n := int(seconds / ArenaSim.DT)
	for i in n:
		sim.step(f)


func _press() -> InputFrame:
	return InputFrame.make(Vector2.ZERO, Vector2.RIGHT, true)


func test_throw_reaches_range_then_returns() -> void:
	sim.step(_press())
	var h = sim.hooks[0]
	assert_eq(h.state, ArenaSim.HookState.OUT)
	var max_d := 0.0
	for i in 120:
		sim.step(InputFrame.new())
		max_d = maxf(max_d, h.pos.distance_to(sim.pos))
		if h.state == ArenaSim.HookState.IDLE:
			break
	var expected: float = sim.st["hook_range"] + sim.st["radius"]
	assert_almost_eq(max_d, expected, sim.st["hook_speed"] * ArenaSim.DT + 1.0, "flies out to its range")
	assert_eq(h.state, ArenaSim.HookState.IDLE, "comes back on its own")


func test_flight_time_is_snappy() -> void:
	# the throw should feel instant: out to full range in about a quarter second
	var t: float = sim.st["hook_range"] / sim.st["hook_speed"]
	assert_between(t, 0.12, 0.3)


func test_range_grows_with_size() -> void:
	var small: float = sim.st["hook_range"]
	sim.mass = Growth.mass_from_size(sim.B, 20.0)
	sim._recalc()
	assert_gt(sim.st["hook_range"], small * 1.8)


func test_catch_reel_and_eat() -> void:
	var e = sim.spawn("nibbler", sim.pos + Vector2(150, 0), 1.5)
	sim.step(_press())
	var caught := false
	for i in 30:
		sim.step(InputFrame.new())
		if e.state == ArenaSim.EState.HOOKED:
			caught = true
			break
	assert_true(caught, "hook latches onto prey in its path")
	assert_eq(sim.hooks[0].enemy, e)
	var size_before := sim.size
	var eaten_at := -1.0
	var t0 := sim.time
	for i in 600:
		sim.step(_press() if i % 15 == 0 else InputFrame.new())
		if not sim.enemies.has(e):
			eaten_at = sim.time - t0
			break
	assert_gt(eaten_at, 0.0, "reeled in and eaten")
	assert_lt(eaten_at, 2.5, "a snack is eaten within a couple of seconds of yanking")
	assert_gt(sim.size, size_before, "eating grows you")
	assert_eq(sim.meals, 1)


func test_yank_reels_faster_than_waiting() -> void:
	var times := []
	for yank in [false, true]:
		before_each()
		var e = sim.spawn("nibbler", sim.pos + Vector2(200, 0), 2.4)
		sim.step(_press())
		var t := 0.0
		for i in 1200:
			sim.step(_press() if yank and i % 14 == 0 else InputFrame.new())
			if not sim.enemies.has(e):
				t = sim.time
				break
		times.append(t if t > 0.0 else 999.0)
	assert_lt(times[1], times[0] * 0.7, "yanking beats the auto-reel by a lot (%s)" % str(times))


func test_struggle_scales_with_prey_size() -> void:
	# a hooked prey your own size fights back: with no yanks it snaps the line, a snack doesn't
	var big = sim.spawn("nibbler", sim.pos + Vector2(250, 0), sim.size * 1.05)
	sim.step(_press())
	var snapped := false
	for i in 600:
		sim.step(InputFrame.new())
		for ev in sim.events:
			snapped = snapped or ev["type"] == "snap"
		if snapped or not sim.enemies.has(big):
			break
	assert_true(snapped, "a big catch escapes if you don't yank")


func test_too_big_bounces_off() -> void:
	var e = sim.spawn("nibbler", sim.pos + Vector2(120, 0), sim.size * 1.5)
	sim.step(_press())
	var too_big := false
	for i in 30:
		sim.step(InputFrame.new())
		for ev in sim.events:
			too_big = too_big or ev["type"] == "too_big"
	assert_true(too_big)
	assert_ne(e.state, ArenaSim.EState.HOOKED)


func test_shellback_blocks_front_but_not_back() -> void:
	var e = sim.spawn("shellback", sim.pos + Vector2(140, 0), 2.0)
	e.facing = PI  # facing the player: shell in front
	e.ai_t = 99.0
	sim.step(_press())
	var clang := false
	for i in 20:
		sim.step(InputFrame.new())
		for ev in sim.events:
			clang = clang or ev["type"] == "clang"
	assert_true(clang, "armoured front clangs")
	assert_ne(e.state, ArenaSim.EState.HOOKED)
	_run(1.0)
	e.facing = 0.0  # turned away: soft back exposed
	sim.step(_press())
	for i in 20:
		sim.step(InputFrame.new())
	assert_eq(e.state, ArenaSim.EState.HOOKED, "hooked from behind")


func test_shellback_open_mouth_is_hookable() -> void:
	var e = sim.spawn("shellback", sim.pos + Vector2(140, 0), 2.0)
	e.facing = PI
	e.tell = 0.6  # opening up to bite
	assert_true(sim.shell_open(e))
	sim.step(_press())
	for i in 12:
		sim.step(InputFrame.new())
	assert_eq(e.state, ArenaSim.EState.HOOKED)


func test_spiky_puffer_hurts_unless_calm() -> void:
	var e = sim.spawn("puffer", sim.pos + Vector2(140, 0), 2.0)
	e.spiky = true
	e.ai_t = 99.0
	var hp := sim.hp
	sim.step(_press())
	for i in 20:
		sim.step(InputFrame.new())
	assert_lt(sim.hp, hp, "hooking spikes hurts")
	assert_ne(e.state, ArenaSim.EState.HOOKED)
	_run(1.0)
	e.spiky = false
	sim.step(_press())
	for i in 20:
		sim.step(InputFrame.new())
	assert_eq(e.state, ArenaSim.EState.HOOKED, "calm puffer is fair game")


func test_dodge_gives_invulnerability_and_distance() -> void:
	var start := sim.pos
	sim.step(InputFrame.make(Vector2.RIGHT, Vector2.RIGHT, false, true))
	assert_gt(sim.invuln, 0.0)
	_run(0.2, InputFrame.make(Vector2.RIGHT))
	var dodge_d := sim.pos.distance_to(start)
	before_each()
	_run(0.2 + ArenaSim.DT, InputFrame.make(Vector2.RIGHT))
	assert_gt(dodge_d, sim.pos.distance_to(Vector2.ZERO) * 1.8, "dodge covers much more ground")


func test_multi_hook_throws_a_fan() -> void:
	sim.forms["multi"] = 1
	sim._reset_hooks()
	sim.step(_press())
	assert_eq(sim.hooks.size(), 3)
	var dirs := []
	for h in sim.hooks:
		assert_eq(h.state, ArenaSim.HookState.OUT)
		dirs.append(h.vel.angle())
	assert_gt(absf(dirs[0] - dirs[2]), deg_to_rad(20.0), "spread out")


func test_chain_leaps_to_nearby_prey() -> void:
	sim.forms["chain"] = 1
	var a = sim.spawn("nibbler", sim.pos + Vector2(140, 0), 1.5)
	var b = sim.spawn("nibbler", sim.pos + Vector2(160, 60), 1.5)
	var c = sim.spawn("nibbler", sim.pos + Vector2(170, -60), 1.5)
	sim.step(_press())
	for i in 12:
		sim.step(InputFrame.new())
	var hooked := 0
	for e in [a, b, c]:
		if e.state == ArenaSim.EState.HOOKED:
			hooked += 1
	assert_eq(hooked, 3, "one throw, three catches")


func test_whirl_dodge_snags_prey_around_you() -> void:
	sim.forms["whirl"] = 1
	# the dodge dashes right (aim) ~170 px, then the hook sweeps a full circle around you
	var a = sim.spawn("nibbler", sim.pos + Vector2(150, 110), 1.5)
	var b = sim.spawn("nibbler", sim.pos + Vector2(200, -100), 1.5)
	a.ai_t = 99.0
	b.ai_t = 99.0
	sim.step(InputFrame.make(Vector2.ZERO, Vector2.RIGHT, false, true))
	assert_gt(sim.whirl_t, 0.0)
	for i in 40:
		sim.step(InputFrame.new())
	assert_true(a.state == ArenaSim.EState.HOOKED or not sim.enemies.has(a))
	assert_true(b.state == ArenaSim.EState.HOOKED or not sim.enemies.has(b))
