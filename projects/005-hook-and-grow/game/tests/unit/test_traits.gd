extends GutTest
## Trait application: eating an archetype adds its trait; levels step at 1/3/12/27 meals; each
## trait changes the stats it promises.

var sim: ArenaSim


func before_each() -> void:
	sim = ArenaSim.new(Balance.copy(), 5)
	sim.clear_for_test()


func _feed(kind: String, n: int) -> void:
	for i in n:
		sim._eat(sim.spawn(kind, sim.pos + Vector2(400, 0), sim.size * 0.4))


func test_archetype_gives_its_trait() -> void:
	var expect := {"shellback": "armour", "darter": "speed", "spitter": "damage", "puffer": "pierce"}
	for kind in expect:
		var before := int(sim.traits[expect[kind]])
		_feed(kind, 1)
		assert_eq(int(sim.traits[expect[kind]]), before + 1, "%s gives %s" % [kind, expect[kind]])
	_feed("nibbler", 3)
	var total := 0
	for t in sim.traits:
		total += int(sim.traits[t])
	assert_eq(total, 4, "nibblers are plain food")


func test_trait_levels_step_up_slower_each_time() -> void:
	var cap := int(sim.B["traits"]["cap"])
	var want := {0: 0, 1: 1, 2: 1, 3: 2, 11: 2, 12: 3, 27: 4, 48: 5, 75: 6, 200: 6}
	for n in want:
		assert_eq(Growth.trait_level(n, cap), want[n], "%d eaten" % n)


func test_eat_event_reports_trait() -> void:
	sim._eat(sim.spawn("darter", sim.pos + Vector2(300, 0), 1.0))
	var got := false
	for e in sim.events:
		got = got or (e["type"] == "trait" and e["trait"] == "speed")
	assert_true(got)


func test_armour_cuts_damage_and_spikes() -> void:
	var base: float = sim.st["damage_taken"]
	assert_false(sim.st["spike_proof"])
	_feed("shellback", 4)
	assert_lt(sim.st["damage_taken"], base)
	assert_true(sim.st["spike_proof"], "armour lets you hook spiky puffers")


func test_speed_trait_is_faster() -> void:
	var plain := Growth.stats(sim.B, 10.0, {})
	var fast := Growth.stats(sim.B, 10.0, {"speed": 12})
	assert_gt(fast["speed"], plain["speed"] * 1.15)
	assert_lt(fast["dodge_cooldown"], plain["dodge_cooldown"])


func test_damage_trait_yanks_harder_and_shockwaves() -> void:
	var plain := Growth.stats(sim.B, 10.0, {})
	var strong := Growth.stats(sim.B, 10.0, {"damage": 12})
	assert_gt(strong["yank"], plain["yank"] * 1.2)
	assert_eq(plain["shockwave"], 0.0)
	assert_gt(strong["shockwave"], strong["radius"])


func test_pierce_ignores_shell() -> void:
	_feed("puffer", 1)
	assert_true(sim.st["pierce"])
	var e = sim.spawn("shellback", sim.pos + Vector2(140, 0), 1.0)
	e.facing = PI
	e.ai_t = 99.0
	sim.step(InputFrame.make(Vector2.ZERO, Vector2.RIGHT, true))
	for i in 15:
		sim.step(InputFrame.new())
	assert_eq(e.state, ArenaSim.EState.HOOKED, "pierce goes through the front shell")


func test_evolution_changes_hook() -> void:
	sim.mass = Growth.mass_from_size(sim.B, float(sim.B["evolution"]["at_sizes"][0]) + 0.01)
	sim._recalc()
	sim.step(InputFrame.new())
	assert_eq(sim.pending_choice.size(), 3, "three forms offered")
	for f in sim.pending_choice:
		assert_true(f in ["multi", "chain", "whirl"], "first offer is all hook-changing forms")
	var t := sim.time
	sim.step(InputFrame.new())
	assert_eq(sim.time, t, "the run waits while you choose")
	var idx: int = sim.pending_choice.find("multi")
	sim.choose_evolution(idx)
	assert_eq(int(sim.forms["multi"]), 1)
	assert_eq(sim.hooks.size(), 3)
