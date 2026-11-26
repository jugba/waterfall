extends GutTest
## Neatness scorer: tidy layouts score high whatever their shape, messes score low.

const COLS := 32
const ROWS := 20


func _job_items(i: int) -> Array:
	return Catalog.job_items(Catalog.job(i))


func _entries_from_rects(items: Array, rects: Array[Rect2i], angle := 0.0) -> Array:
	var out := []
	for k in items.size():
		var r := rects[k]
		out.append(Neatness.entry(Rect2(r), angle, items[k]["category"], items[k]["colour"]))
	return out


func _sizes(items: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for it in items:
		out.append(Vector2i(int(it["w"]), int(it["h"])))
	return out


## Layout A: one row per type (1-cell gaps, 2 between rows), every long item horizontal.
func _rows_by_type(job: int) -> Array:
	var items := Layouts.sort_by_type(_job_items(job))
	var groups := items.map(func(it): return it["category"])
	var rects := Layouts.grouped_rows(_sizes(items), groups, COLS - 2, 1, 2)
	return _entries_from_rects(items, Layouts.centred(rects, COLS, ROWS))


## Layout B: one column per colour, every long item vertical, different gaps.
func _columns_by_colour(job: int) -> Array:
	var items := Layouts.sort_by_colour(_job_items(job))
	var groups := items.map(func(it): return it["colour"])
	var rects := Layouts.transposed(Layouts.grouped_rows(_sizes(items), groups, ROWS - 2, 1, 2))
	return _entries_from_rects(items, Layouts.centred(rects, COLS, ROWS), 90.0)


## What the tip produces: random positions and angles.
func _scatter(job: int, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	for it in _job_items(job):
		var s := Vector2(int(it["w"]), int(it["h"]))
		var angle := rng.randf_range(0.0, 360.0)
		if posmod(roundi(angle / 90.0), 2) == 1:
			s = Vector2(s.y, s.x)
		var c := Vector2(rng.randf_range(3.0, COLS - 3.0), rng.randf_range(3.0, ROWS - 3.0))
		out.append(Neatness.entry(Rect2(c - s / 2.0, s), angle, it["category"], it["colour"]))
	return out


## Snapped to the grid and square, but placed at random: better than a mess, worse than tidy.
func _snapped_random(job: int, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	for it in _job_items(job):
		var s := Vector2i(int(it["w"]), int(it["h"]))
		var p := Vector2i(rng.randi_range(0, COLS - s.x), rng.randi_range(0, ROWS - s.y))
		out.append(Neatness.entry(Rect2(Rect2i(p, s)), 0.0, it["category"], it["colour"]))
	return out


func test_perfect_grid_scores_high() -> void:
	for job in Catalog.job_count():
		var r := Neatness.evaluate(_rows_by_type(job))
		gut.p("job %d rows-by-type: %d %s" % [job, r.total, r.parts])
		assert_gte(r.total, 85, "job %d tidy rows score high" % job)
		assert_eq(int(r.info.overlaps), 0)


func test_random_scatter_scores_low() -> void:
	for job in Catalog.job_count():
		var worst := 0
		for s in 20:
			worst = maxi(worst, Neatness.evaluate(_scatter(job, 1000 + s)).total)
		gut.p("job %d worst scatter: %d" % [job, worst])
		assert_lte(worst, 35, "job %d scatter scores low" % job)


func test_two_different_tidy_layouts_both_score_high() -> void:
	for job in Catalog.job_count():
		var a := Neatness.evaluate(_rows_by_type(job))
		var b := Neatness.evaluate(_columns_by_colour(job))
		gut.p("job %d columns-by-colour: %d %s" % [job, b.total, b.parts])
		assert_gte(a.total, 85)
		assert_gte(b.total, 80, "job %d: vertical colour columns are also tidy" % job)
		assert_lte(absi(a.total - b.total), 15, "no single right answer")


func test_snapped_but_unsorted_is_in_between() -> void:
	var tidy: int = Neatness.evaluate(_rows_by_type(1)).total
	var mess: int = Neatness.evaluate(_scatter(1, 7)).total
	for s in 5:
		var mid: int = Neatness.evaluate(_snapped_random(1, 50 + s)).total
		assert_lt(mid, tidy - 10, "random-but-snapped is clearly worse than tidy")
		assert_gt(mid, mess, "snapping alone still helps")


func test_overlaps_cost_points() -> void:
	var entries := _rows_by_type(0)
	var clean: int = Neatness.evaluate(entries).total
	var piled := entries.duplicate(true)
	for e in piled:
		e["rect"] = Rect2(Vector2(10, 10), (e["rect"] as Rect2).size)
	var r := Neatness.evaluate(piled)
	assert_gt(int(r.info.overlaps), 0)
	assert_lt(r.total, clean - 30)


func test_tilt_costs_points() -> void:
	var entries := _rows_by_type(0)
	var tilted := entries.duplicate(true)
	for e in tilted:
		e["angle"] = 25.0
	assert_lt(Neatness.evaluate(tilted).total, Neatness.evaluate(entries).total - 30)


func test_reasons_explain_every_point() -> void:
	var r := Neatness.evaluate(_rows_by_type(2))
	assert_eq(r.reasons.size(), 4)
	var sum := 0
	var max_sum := 0
	for reason in r.reasons:
		assert_false(String(reason.text).is_empty())
		sum += int(reason.points)
		max_sum += int(reason.max)
	assert_eq(max_sum, 100)
	assert_almost_eq(sum, r.total, 2, "reasons add up to the total (rounding)")


func test_squareness() -> void:
	assert_eq(Neatness.squareness(0.0), 1.0)
	assert_eq(Neatness.squareness(270.0), 1.0)
	assert_eq(Neatness.squareness(-90.0), 1.0)
	assert_eq(Neatness.squareness(45.0), 0.0)
	assert_almost_eq(Neatness.squareness(95.0), 0.5, 0.001)


func test_empty_and_single() -> void:
	assert_eq(Neatness.evaluate([]).total, 0)
	var one := [Neatness.entry(Rect2(2, 2, 3, 1), 0.0, "writing", "red")]
	assert_eq(Neatness.evaluate(one).total, 100)
