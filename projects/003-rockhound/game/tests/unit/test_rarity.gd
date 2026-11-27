extends GutTest
## Rarity roll distribution, luck, shell hints and the pity timer (data/balance.json).

const Economy := preload("res://scripts/economy.gd")


func _no_pity(eco) -> void:
	eco.data["pity"]["rare_after"] = 1000000
	eco.data["pity"]["epic_after"] = 1000000


func test_tiers_ordered_and_crystals_cover_every_tier() -> void:
	var eco = Economy.new(1)
	assert_eq(eco.tiers.size(), 5)
	for t in eco.tiers.size():
		assert_gt(eco.crystals_of_tier(t).size(), 0, "tier %d has crystals" % t)
		if t > 0:
			assert_lt(float(eco.tiers[t]["weight"]), float(eco.tiers[t - 1]["weight"]), "rarer tiers are rarer")
			assert_gt(float(eco.tiers[t]["value"]), float(eco.tiers[t - 1]["value"]), "rarer tiers are worth more")


func test_distribution_matches_weights() -> void:
	var eco = Economy.new(12345)
	_no_pity(eco)
	var n := 40000
	var counts := [0, 0, 0, 0, 0]
	for i in n:
		counts[eco.roll_tier()] += 1
	var odds: Array[float] = eco.tier_odds()
	for t in 5:
		var expected := odds[t] * n
		var tol := 4.0 * sqrt(expected * (1.0 - odds[t])) + 2.0  # ~4 sigma
		assert_almost_eq(float(counts[t]), expected, tol, "tier %d: %d vs %.0f" % [t, counts[t], expected])


func test_luck_shifts_odds_to_rarer_tiers() -> void:
	var eco = Economy.new(1)
	var base: Array[float] = eco.tier_odds()
	eco.levels["luck"] = 5
	var lucky: Array[float] = eco.tier_odds()
	assert_lt(lucky[0], base[0])
	assert_gt(lucky[4], base[4] * 3.0)


func test_rare_pity_never_exceeded() -> void:
	for seed_value in [1, 2, 3, 99, 2024]:
		var eco = Economy.new(seed_value)
		var limit := int(eco.data["pity"]["rare_after"])
		var gap := 0
		var worst := 0
		for i in 3000:
			gap += 1
			if eco.roll_tier() >= Economy.RARE:
				worst = maxi(worst, gap)
				gap = 0
		assert_lte(worst, limit, "seed %d: max gap %d without a rare" % [seed_value, worst])


func test_pity_forces_rare_and_epic() -> void:
	var eco = Economy.new(7)
	eco.since_rare = int(eco.data["pity"]["rare_after"]) - 1
	assert_gte(eco.roll_tier(), Economy.RARE)
	assert_eq(eco.since_rare, 0)
	eco.since_epic = int(eco.data["pity"]["epic_after"]) - 1
	assert_gte(eco.roll_tier(), Economy.EPIC)
	assert_eq(eco.since_epic, 0)


## Pacing promise: a fresh save sees a rare+ within the first `rare_after` geodes, i.e. within
## the first 2-3 minutes at ~3-6 s per geode.
func test_fresh_save_gets_rare_early() -> void:
	for seed_value in 50:
		var eco = Economy.new(seed_value)
		var got := false
		for i in int(eco.data["pity"]["rare_after"]):
			if eco.new_geode()["tier"] >= Economy.RARE:
				got = true
				break
		assert_true(got, "seed %d" % seed_value)
	var e = Economy.new(1)
	assert_lte(int(e.data["pity"]["rare_after"]) * 6, 150, "pity fits in 2.5 min at 6 s/geode")


func test_shell_hint_never_overstates() -> void:
	var eco = Economy.new(3)
	var exact := 0
	for i in 2000:
		var t := 1 + i % 4
		var h: int = eco.shell_hint(t)
		assert_true(h == t or h == t - 1)
		if h == t:
			exact += 1
	assert_almost_eq(exact / 2000.0, float(eco.data["shell_hint_accuracy"]), 0.05)
