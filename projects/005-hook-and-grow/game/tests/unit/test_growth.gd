extends GutTest
## Growth curve: size and stats per meal (monotonic), diminishing returns, size gating.

var B: Dictionary


func before_each() -> void:
	B = Balance.copy()


func test_size_mass_round_trip() -> void:
	for s in [3.0, 7.5, 20.0, 46.0]:
		assert_almost_eq(Growth.size_from_mass(B, Growth.mass_from_size(B, s)), s, 0.001)


func test_every_meal_grows_you_and_stats_never_drop() -> void:
	var sim := ArenaSim.new(B, 3)
	sim.clear_for_test()
	var kinds := ["nibbler", "darter", "shellback", "spitter", "puffer"]
	var prev: Dictionary = sim.st.duplicate()
	for i in 200:
		var kind: String = kinds[i % kinds.size()]
		var e = sim.spawn(kind, sim.pos + Vector2(500, 0), sim.size * 0.5)
		sim._eat(e)
		assert_gt(sim.st["size"], prev["size"], "meal %d grows size" % i)
		for key in ["radius", "hp_max", "hook_range", "speed", "yank", "hook_speed"]:
			assert_true(sim.st[key] >= prev[key] - 0.0001, "%s never drops (meal %d)" % [key, i])
		assert_true(sim.st["damage_taken"] <= prev["damage_taken"] + 0.0001)
		prev = sim.st.duplicate()
	assert_gt(sim.size, 9.0, "200 half-size meals make you much bigger")


func test_bigger_prey_is_a_bigger_meal() -> void:
	var small := Growth.meal_mass(B, "nibbler", 1.5, 3.0)
	var big := Growth.meal_mass(B, "nibbler", 3.0, 3.0)
	assert_gt(big, small * 4.0)


func test_efficiency_falls_off_as_you_grow() -> void:
	# the same relative meal is worth less (relative to your mass) when you're huge
	var rel_small := Growth.meal_mass(B, "nibbler", 1.5, 3.0) / Growth.mass_from_size(B, 3.0)
	var rel_big := Growth.meal_mass(B, "nibbler", 15.0, 30.0) / Growth.mass_from_size(B, 30.0)
	assert_lt(rel_big, rel_small * 0.5)


func test_visible_growth_on_a_snack_early() -> void:
	# early meals must be visible: a half-size snack grows radius by at least 1%
	var sim := ArenaSim.new(B, 3)
	sim.clear_for_test()
	var r0: float = sim.st["radius"]
	sim._eat(sim.spawn("nibbler", Vector2(400, 0), sim.size * 0.5))
	assert_gt(sim.st["radius"] / r0, 1.01)


func test_can_hook_gate() -> void:
	var ratio := float(B["hook"]["catch_ratio"])
	assert_true(Growth.can_hook(B, 10.0, 10.0 * ratio))
	assert_false(Growth.can_hook(B, 10.0, 10.0 * ratio + 0.01))
	assert_almost_eq(Growth.size_needed(B, 46.0), 46.0 / ratio, 0.001)


func test_world_scale_keeps_screen_speed_sane() -> void:
	# camera zoom = 1/scale, so on-screen move speed should stay within +-40% at any size
	var s3: Dictionary = Growth.stats(B, 3.0, {})
	var s40: Dictionary = Growth.stats(B, 40.0, {})
	var screen3: float = s3["speed"] / s3["scale"]
	var screen40: float = s40["speed"] / s40["scale"]
	assert_almost_eq(screen40 / screen3, 1.0, 0.4)
