extends GutTest
## Upgrade cost curve, income, values, sets, polish and number formatting.

const Economy := preload("res://scripts/economy.gd")
const Fmt := preload("res://scripts/fmt.gd")


func test_cost_curve_is_exponential_and_increasing() -> void:
	var eco = Economy.new(1)
	for u in eco.upgrades:
		var id: String = u["id"]
		var prev := 0.0
		for lv in 8:
			eco.levels[id] = lv
			var c: float = eco.upgrade_cost(id)
			assert_eq(c, floor(float(u["base_cost"]) * pow(float(u["growth"]), lv)))
			assert_gt(c, prev, "%s cost rises at Lv %d" % [id, lv])
			prev = c


func test_buy_spends_money_and_levels_up() -> void:
	var eco = Economy.new(1)
	assert_false(eco.buy("pick"), "can't buy broke")
	eco.money = 100
	var cost: float = eco.upgrade_cost("pick")
	assert_true(eco.buy("pick"))
	assert_eq(eco.level("pick"), 1)
	assert_eq(eco.money, 100 - cost)
	assert_eq(eco.dig_power(), 2)


func test_max_level_blocks_buy() -> void:
	var eco = Economy.new(1)
	eco.levels["polish"] = int(eco.upgrade_def("polish")["max"])
	eco.money = 1e30
	assert_true(eco.is_maxed("polish"))
	assert_false(eco.buy("polish"))


## Pacing promise: the first upgrade is affordable within ~30 s of normal play. Simulates manual
## play from a fresh save at a conservative pace (0.15 s per pick hit, 0.15 s per hammer strike,
## 0.6 s to look at each common reveal and tap to sell, more for rarer ones).
func test_first_upgrade_within_30_seconds() -> void:
	for seed_value in 20:
		var eco = Economy.new(seed_value)
		var t := 0.0
		var cheapest: float = eco.upgrade_cost(eco.next_goal())
		while eco.money < cheapest and t < 120.0:
			var hits := int(ceil(float(eco.chunk_hp()) / eco.dig_power()))
			t += hits * 0.15
			eco.break_chunk()
			while not eco.tray.is_empty():
				var g: Dictionary = eco.take_from_tray()
				t += eco.strikes_needed(g["tier"]) * 0.15 + 0.6 + 0.5 * int(g["tier"])
				eco.sell(eco.crack(g))
		assert_lte(t, 30.0, "seed %d: first upgrade after %.1f s" % [seed_value, t])


func test_values_grow_with_depth_and_sets() -> void:
	var eco = Economy.new(1)
	var q: Dictionary = eco.crystals[0]
	var v0: float = eco.crystal_value(q)
	eco.depth = 3
	assert_almost_eq(eco.crystal_value(q), v0 * pow(1.3, 3), 0.001)
	for m in eco.sets[0]["members"]:
		eco.collection[m] = 1
	assert_almost_eq(eco.set_mult(), 1.0 + float(eco.sets[0]["bonus"]), 0.0001)
	assert_eq(eco.completed_sets(), [eco.sets[0]["id"]])


func test_depth_advances_after_a_full_face() -> void:
	var eco = Economy.new(1)
	var hp0: int = eco.chunk_hp()
	for i in eco.chunks_per_face():
		eco.break_chunk()
		eco.tray.clear()
	assert_eq(eco.depth, 1)
	assert_eq(eco.chunks_broken, 0)
	assert_gte(eco.chunk_hp(), hp0)


func test_full_tray_bulk_sells_plainest_geode() -> void:
	var eco = Economy.new(1)
	eco.tray = []
	for i in eco.tray_size():
		eco.tray.append({"tier": 4, "hint": 4})
	var res: Dictionary = eco.break_chunk()
	assert_eq(eco.tray.size(), eco.tray_size())
	assert_gt(res["bulk_sold"], 0.0)
	assert_gt(eco.money, 0.0)


func test_idle_income_needs_auto_digger_and_scales() -> void:
	var eco = Economy.new(1)
	assert_eq(eco.idle_income_per_second(), 0.0)
	eco.levels["auto"] = 1
	var one: float = eco.idle_income_per_second()
	assert_gt(one, 0.0)
	eco.levels["auto"] = 3
	assert_almost_eq(eco.idle_income_per_second(), one * 3.0, 0.0001)
	eco.levels["pick"] = 3
	assert_gt(eco.idle_income_per_second(), one * 3.0)


func test_polish_rewards_the_green_zone() -> void:
	var eco = Economy.new(1)
	assert_eq(eco.polish_mult(0.86), 1.0, "locked until bought")
	eco.levels["polish"] = 1
	var perfect: float = eco.polish_mult(0.86)
	assert_eq(perfect, 1.5)
	assert_lt(eco.polish_mult(0.5), perfect)
	assert_lt(eco.polish_mult(1.1), eco.polish_mult(0.5), "overshoot scratches")
	assert_gt(eco.polish_mult(1.1), 1.0)


func test_crack_records_collection_and_new_flag() -> void:
	var eco = Economy.new(1)
	var c: Dictionary = eco.crack({"tier": 0, "hint": 0})
	assert_true(c["is_new"])
	assert_true(eco.collection.has(c["id"]))
	assert_gt(c["value"], 0.0)


func test_number_format() -> void:
	assert_eq(Fmt.money(0), "$0")
	assert_eq(Fmt.money(7), "$7")
	assert_eq(Fmt.money(2.5), "$2.5")
	assert_eq(Fmt.money(1240), "$1,240")
	assert_eq(Fmt.money(9999), "$9,999")
	assert_eq(Fmt.money(12400), "$12.4K")
	assert_eq(Fmt.money(3050000), "$3.05M")
	assert_eq(Fmt.money(999999), "$999K")
	assert_eq(Fmt.money(2.5e12), "$2.50T")
