extends GutTest
## A job loads, tips, can be sorted (drag + drop snaps to the grid), scored, packed and paid.

const GAME := "res://scenes/game.tscn"
const Game := preload("res://scripts/game.gd")
const EXPECTED_COUNTS := [8, 14, 22]

var _orig_save_dir: String


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	SaveGame.directory = "user://test_job_saves"


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir
	get_tree().paused = false


func _game(job: int, autofree := true) -> Node:
	var g: Node = load(GAME).instantiate()
	g.rng_seed = 1234
	g.start_job_index = job
	if autofree:
		add_child_autofree(g)
	else:
		add_child(g)
	return g


func test_data_is_valid() -> void:
	assert_eq(Catalog.job_count(), 3)
	for i in Catalog.job_count():
		var j := Catalog.job(i)
		assert_eq(j["items"].size(), EXPECTED_COUNTS[i], "job %d size" % i)
		assert_eq(Catalog.job_items(j).size(), j["items"].size(), "every item id of job %d exists" % i)
	for id in Catalog.items():
		var it: Dictionary = Catalog.item(id)
		assert_true(Catalog.COLOURS.has(it["colour"]), "%s colour" % id)
		assert_gte(int(it["w"]), int(it["h"]), "%s: long axis horizontal" % id)
		assert_gt(int(it["h"]), 0)


func test_job_loads_and_completes() -> void:
	for job in Catalog.job_count():
		var g := _game(job, false)
		assert_eq(g.phase, Game.Phase.INTRO)
		assert_eq(g.items.size(), EXPECTED_COUNTS[job])
		g.begin_tip()
		assert_eq(g.phase, Game.Phase.TIPPING)
		g.settle_now()
		assert_eq(g.phase, Game.Phase.SORTING)
		var mat := Desk.rect_px().grow(1.0)
		var scatter := Neatness.evaluate(g._entries())
		for it in g.items:
			assert_true(it.visible and mat.has_point(it.position), "%s landed on the mat" % it.name)
		assert_lt(int(scatter["total"]), 50, "job %d: the tipped mess is messy" % job)
		g.auto_arrange(true)
		assert_eq(g.loose_count(), 0)
		for it in g.items:
			assert_true(Desk.in_bounds(Rect2i(it.cell, it.grid_size())), "%s arranged inside the desk" % it.name)
		var result: Dictionary = g.take_photo()
		assert_eq(g.phase, Game.Phase.REVEAL)
		gut.p("job %d: scatter %d -> arranged %d %s" % [job, scatter["total"], result["total"], result["parts"]])
		assert_gte(int(result["total"]), 85, "job %d tidy arrangement scores high" % job)
		assert_gt(g.last_pay, 0)
		g.pack_back(true)
		assert_eq(g.phase, Game.Phase.DONE)
		var save := SaveGame.load_slot(0)
		assert_eq(int(save.get("next_job", -1)), mini(job + 1, 2))
		assert_true(save["completed"].has(g.job["id"]), "job %d marked completed" % job)
		assert_eq(int(save["best"][g.job["id"]]), int(result["total"]))
		g.free()


func test_drop_snaps_to_grid_without_overlap() -> void:
	var g := _game(1)
	g.settle_now()
	var a: DeskItem = g.items[0]
	var b: DeskItem = g.items[1]
	g.grab(a, a.position)
	a.position = Desk.cell_to_px(Vector2(10.3, 8.6))
	g.drop_held(true)
	assert_true(a.placed)
	assert_almost_eq(a.rotation, a.snapped_angle(), 0.0001, "square after drop")
	var size := a.grid_size()
	assert_eq(a.position, Desk.centre_of(a.cell, size), "centred on its cells")
	# Drop b on top of a: it must land on the nearest free cells instead.
	g.grab(b, b.position)
	b.position = a.position
	g.drop_held(true)
	assert_true(b.placed)
	assert_false(Rect2i(a.cell, a.grid_size()).intersects(Rect2i(b.cell, b.grid_size())), "no overlap")


func test_rotate_turns_item_a_quarter() -> void:
	var g := _game(0)
	g.settle_now()
	var it: DeskItem = g.items[0]
	g.grab(it, it.position)
	g.drop_held(true)
	var before := it.quarter()
	var size_before := it.grid_size()
	g.rotate_item(it, 1)
	await wait_seconds(0.3)
	assert_eq(it.quarter(), (before + 1) % 4)
	assert_eq(it.grid_size(), Vector2i(size_before.y, size_before.x))
	assert_true(it.placed)


func test_controller_flow_grab_nudge_drop() -> void:
	var g := _game(0)
	g.settle_now()
	var it: DeskItem = g.items[3]
	g._set_pad_mode(true)
	g._cursor = it.position
	g._set_hover(it)
	var press := InputEventAction.new()
	press.action = &"action_primary"
	press.pressed = true
	g._unhandled_input(press)
	assert_eq(g._held, it, "A grabs the hovered item")
	var start: Vector2 = g._cursor
	var right := InputEventAction.new()
	right.action = &"move_right"
	right.pressed = true
	g._unhandled_input(right)
	assert_almost_eq(g._cursor.x - start.x, Desk.CELL, 0.01, "d-pad nudges one cell")
	await wait_frames(20)
	g._unhandled_input(press)
	assert_null(g._held, "A drops")
	assert_true(it.placed)


func test_photo_reveal_runs_to_pack_button() -> void:
	var g := _game(0)
	g.settle_now()
	g.auto_arrange(true)
	g.take_photo()
	await wait_seconds(4.0)
	var buttons: Array = g.hud.buttons_box.get_children()
	assert_eq(buttons.size(), 1, "Pack button shown after the reveal")
	assert_eq(g.hud.reasons_box.get_child_count(), 4, "one line per reason")
	assert_ne(g.hud.stamp_label.text, "")
