extends GutTest
## Pacing promises, checked with the conservative scripted Bot over several seeds
## (memories/design/encode-pacing-promises-as-unit-tests). Retune data/balance.json, then run this.
##  - first evolution within 2-3 minutes
##  - an evolution every couple of minutes after that
##  - boss arrives in 7-10 minutes, is hookable by ~10-11 and eaten by ~12
##  - you can't out-grow the gate: the boss appears before you're big enough to hook it

const SEEDS := [0, 1, 2, 3]
const MAX_TIME := 900.0

static var _runs: Array = []


func _runs_cached() -> Array:
	if _runs.is_empty():
		for s in SEEDS:
			var sim := ArenaSim.new(Balance.copy(), 100 + s)
			var bot := Bot.new(200 + s)
			var sizes: Array = []
			var last := -1.0
			while sim.time < MAX_TIME and not sim.won:
				if not sim.pending_choice.is_empty():
					sim.choose_evolution(0)
				sim.step(bot.think(sim))
				if sim.time - last >= 10.0:
					last = sim.time
					sizes.append(sim.size)
			_runs.append({"evo": sim.evolution_times.duplicate(), "boss": sim.boss_spawned_at,
				"hookable": sim.boss_hookable_at, "won": sim.won_at, "sizes": sizes, "deaths": sim.deaths,
				"meals": sim.meals})
	return _runs


func test_first_evolution_in_two_to_three_minutes() -> void:
	for r in _runs_cached():
		assert_false(r["evo"].is_empty(), "evolved at all")
		if not r["evo"].is_empty():
			assert_between(float(r["evo"][0]), 120.0, 180.0, "first evolution at %.0f s" % r["evo"][0])


func test_evolutions_every_couple_of_minutes() -> void:
	for r in _runs_cached():
		var evo: Array = r["evo"]
		assert_eq(evo.size(), 3, "all three evolutions before the boss")
		for i in range(1, evo.size()):
			assert_between(evo[i] - evo[i - 1], 60.0, 180.0, "gap %d" % i)


func test_boss_reachable_by_about_ten_minutes() -> void:
	for r in _runs_cached():
		assert_between(float(r["boss"]), 420.0, 600.0, "boss arrives at %.0f s" % r["boss"])
		assert_between(float(r["hookable"]), 540.0, 720.0, "boss hookable at %.0f s" % r["hookable"])
		assert_gt(float(r["won"]), 0.0, "bot eats the boss")
		assert_lt(float(r["won"]), 780.0, "boss eaten at %.0f s" % r["won"])


func test_boss_gate_means_something() -> void:
	# you meet the boss too small and have to grow into it
	for r in _runs_cached():
		assert_gt(float(r["hookable"]) - float(r["boss"]), 20.0)


func test_size_only_goes_up_without_deaths() -> void:
	for r in _runs_cached():
		if r["deaths"] > 0:
			continue
		var s: Array = r["sizes"]
		for i in range(1, s.size()):
			assert_true(s[i] >= s[i - 1], "size never shrinks")


func test_meal_count_feels_like_a_feast() -> void:
	# continuous play: the bot eats something every second or so on average
	for r in _runs_cached():
		assert_gt(float(r["meals"]) / float(r["won"]), 0.8)
