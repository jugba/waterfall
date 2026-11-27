extends GutTest
## Waves and boss gating: waves advance, the boss arrives after the last wave, it can only be
## hooked at size >= size_needed, it takes several reels, and dying restores the wave checkpoint.

var sim: ArenaSim


func before_each() -> void:
	sim = ArenaSim.new(Balance.copy(), 9)


func _clear_wave() -> void:
	sim.wave_queue.clear()
	sim.enemies.clear()
	sim.step(InputFrame.new())


func test_waves_advance_when_cleared() -> void:
	assert_eq(sim.wave, 0)
	assert_gt(sim.enemies.size(), 0, "opens with snacks already in view")
	_clear_wave()
	assert_eq(sim.wave, 1)


func test_wave_list_grows() -> void:
	var prev := 0
	for w in sim.B["waves"]["list"]:
		var n := 0
		for k in w:
			n += int(w[k])
		assert_true(n >= prev, "later waves are not smaller")
		prev = n


func test_boss_after_last_wave() -> void:
	for i in sim.wave_count() - 1:
		_clear_wave()
	assert_eq(sim.wave, sim.wave_count() - 1)
	assert_null(sim.boss)
	_clear_wave()
	assert_not_null(sim.boss, "boss arrives after the last wave")
	assert_gt(sim.boss_spawned_at, 0.0)


func test_boss_hookable_only_when_big_enough() -> void:
	sim.clear_for_test()
	sim.evolutions_taken = 3  # skip the evolution choices (they pause the sim)
	var need := sim.boss_size_needed()
	assert_almost_eq(need, float(sim.B["enemies"]["boss"]["size"]) / float(sim.B["hook"]["catch_ratio"]), 0.01)
	assert_gt(need, 35.0, "the boss is a late-game goal")
	sim.mass = Growth.mass_from_size(sim.B, need - 0.5)
	sim._recalc()
	var boss = sim.spawn("boss", Vector2.ZERO, float(sim.B["enemies"]["boss"]["size"]))
	sim.boss = boss
	assert_false(sim.hookable(boss), "size %.1f can't hook it" % sim.size)
	sim.pos = boss.pos + Vector2(-boss.radius - sim.st["radius"] - 60.0, 0)
	sim.step(InputFrame.make(Vector2.ZERO, Vector2.RIGHT, true))
	var bounced := false
	for i in 30:
		for ev in sim.events:
			bounced = bounced or (ev["type"] == "too_big" and ev["boss"])
		sim.step(InputFrame.new())
	assert_true(bounced, "hook bounces off with a 'too big' event")
	sim.mass = Growth.mass_from_size(sim.B, need + 0.01)
	sim._recalc()
	sim.step(InputFrame.new())
	assert_true(sim.hookable(boss))
	assert_gt(sim.boss_hookable_at, 0.0)


func test_boss_takes_several_reels() -> void:
	sim.clear_for_test()
	sim.evolutions_taken = 3
	sim.mass = Growth.mass_from_size(sim.B, 44.0)
	# by the boss every archetype has been eaten dozens of times (see the pacing test)
	sim.traits = {"armour": 60, "speed": 100, "damage": 80, "pierce": 80}
	sim._recalc()
	sim.invuln = 999.0
	var boss = sim.spawn("boss", sim.pos + Vector2(500, 0), float(sim.B["enemies"]["boss"]["size"]))
	sim.boss = boss
	var bites := 0
	for i in 60 * 120:
		var to: Vector2 = boss.pos - sim.pos
		sim.step(InputFrame.make(Vector2.ZERO, to.normalized(), i % 12 == 0))
		for ev in sim.events:
			if ev["type"] == "bite":
				bites += 1
		if sim.won:
			break
	assert_true(sim.won, "boss eventually eaten")
	assert_eq(bites, int(sim.B["enemies"]["boss"]["bites"]) - 1, "every reel but the last is a bite")


func test_death_restores_wave_checkpoint() -> void:
	_clear_wave()
	var cp_mass: float = sim.mass
	sim.mass *= 3.0
	sim._recalc()
	sim.invuln = 0.0
	sim.damage_player(99999.0)
	assert_eq(sim.deaths, 1)
	assert_almost_eq(sim.mass, cp_mass, 0.0001)
	assert_almost_eq(sim.hp, sim.st["hp_max"], 0.001)
	assert_eq(sim.wave, 1, "same wave again")
