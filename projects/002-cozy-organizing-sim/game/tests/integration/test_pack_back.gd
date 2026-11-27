extends GutTest
## Pack-back phase: every job's items fit its container; dragging items into the container grid
## packs them; the last one zips it shut and pays; "pack the rest" and the Skip-packing
## setting finish it automatically; a drop that doesn't fit stays on the desk.

const GAME := "res://scenes/game.tscn"
const Game := preload("res://scripts/game.gd")

var _orig_save_dir: String
var _orig_auto_pack: bool


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	_orig_auto_pack = Settings.auto_pack
	SaveGame.directory = "user://test_pack_saves"
	SaveGame.delete_slot(0)


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir
	Settings.auto_pack = _orig_auto_pack


## A game at the reveal of `job` (tidy desk, photo taken).
func _at_reveal(job: int) -> Node:
	var g: Node = load(GAME).instantiate()
	g.rng_seed = 99
	g.start_job_index = job
	add_child_autofree(g)
	g.settle_now()
	g.auto_arrange(true)
	g.take_photo()
	return g


func _drop_at(g: Node, it: DeskItem, cell: Vector2i, size: Vector2i) -> void:
	g.grab(it, it.position)
	if it.grid_size() != size:
		it.rotation += PI / 2.0
	it.position = Desk.centre_of(cell, size)
	g.drop_held(true)


func test_every_job_fits_its_container() -> void:
	for i in Catalog.job_count():
		var j := Catalog.job(i)
		var sizes: Array[Vector2i] = []
		for d in Catalog.job_items(j):
			sizes.append(Vector2i(int(d["w"]), int(d["h"])))
		var c: Dictionary = j["container"]
		var fit := Layouts.pack_into(sizes, int(c["w"]), int(c["h"]))
		assert_eq(fit.size(), sizes.size(), "%s: all items fit the %dx%d container" % [j["id"], c["w"], c["h"]])
		for a in fit.size():
			for b in range(a + 1, fit.size()):
				assert_false(fit[a].intersects(fit[b]), "%s: packed items don't overlap" % j["id"])


func test_manual_packing_completes_job() -> void:
	var g := _at_reveal(0)
	g.start_packing(false)
	assert_eq(g.phase, Game.Phase.PACKING)
	await wait_seconds(0.6)
	assert_eq(g.packed_count(), 0)
	var rect: Rect2i = g.pack_rect()
	assert_false(rect.intersects(Rect2i(0, 0, Desk.COLS, Desk.ROWS)), "container sits beside the mat")
	var fit := Layouts.pack_into(g._sizes_of(g.items), rect.size.x, rect.size.y)
	for k in g.items.size():
		_drop_at(g, g.items[k], rect.position + fit[k].position, fit[k].size)
		if k < g.items.size() - 1:
			assert_true(g.items[k].packed, "item %d is in the container" % k)
			assert_true(rect.encloses(Rect2i(g.items[k].cell, g.items[k].grid_size())))
	assert_eq(g.packed_count(), g.items.size())
	await wait_seconds(1.5)
	assert_eq(g.phase, Game.Phase.DONE, "last item in -> zips shut -> payday")
	assert_eq(g.container_box.zip, 1.0)
	assert_gte(g._pack_seconds, 0.0, "manual packing is timed")
	var save := SaveGame.load_slot(0)
	assert_true(save["completed"].has(g.job["id"]))
	assert_gt(int(save["money"]), 0)


func test_drop_outside_or_too_big_stays_on_desk() -> void:
	var g := _at_reveal(0)
	g.start_packing(false)
	await wait_seconds(0.6)
	var it: DeskItem = g.items[0]   # a 4x1 pencil
	g.grab(it, it.position)
	it.position = Desk.cell_to_px(Vector2(5, 5))
	g.drop_held(true)
	assert_true(it.placed and not it.packed, "dropped on the desk stays on the desk")
	assert_true(Desk.in_bounds(Rect2i(it.cell, it.grid_size())))
	# A container too small for it: the drop over the container bounces back onto the desk.
	g.container_box.cells = Vector2i(2, 2)
	g.grab(it, it.position)
	it.position = g.pack_rect_px().get_center()
	g.drop_held(true)
	assert_true(it.placed, "still snapped somewhere")
	assert_false(it.packed, "doesn't fit -> back on the desk")
	assert_true(Desk.in_bounds(Rect2i(it.cell, it.grid_size())), "landed inside the mat")
	# Overlap inside the container resolves to free cells.
	g.container_box.cells = Vector2i(9, 4)
	var b: DeskItem = g.items[1]
	_drop_at(g, it, g.pack_rect().position, it.grid_size())
	_drop_at(g, b, g.pack_rect().position, b.grid_size())
	assert_true(it.packed and b.packed)
	assert_false(Rect2i(it.cell, it.grid_size()).intersects(Rect2i(b.cell, b.grid_size())), "no overlap in the bag")


func test_pack_rest_finishes_from_partial() -> void:
	var g := _at_reveal(2)
	g.start_packing(false)
	await wait_seconds(0.6)
	var rect: Rect2i = g.pack_rect()
	# Player packs two items badly (middle of the container), then asks for help.
	_drop_at(g, g.items[0], rect.position + Vector2i(3, 5), g.items[0].grid_size())
	_drop_at(g, g.items[1], rect.position + Vector2i(1, 9), g.items[1].grid_size())
	assert_eq(g.packed_count(), 2)
	g.pack_rest()
	await wait_seconds(3.0)
	assert_eq(g.phase, Game.Phase.DONE)
	var cells := {}
	for it in g.items:
		assert_true(it.packed)
		var r := Rect2i(it.cell, it.grid_size())
		assert_true(rect.encloses(r), "%s inside the container" % it.name)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				assert_false(cells.has(Vector2i(x, y)), "no overlap at %s" % Vector2i(x, y))
				cells[Vector2i(x, y)] = true


func test_skip_packing_setting_auto_packs() -> void:
	Settings.auto_pack = true
	var g := _at_reveal(1)
	g.hud.pack_pressed.emit()
	assert_eq(g.phase, Game.Phase.PACKING)
	await wait_seconds(3.0)
	assert_eq(g.phase, Game.Phase.DONE)
	assert_lt(g._pack_seconds, 0.0, "auto-pack is not timed")


func test_controller_packs_with_y_and_a() -> void:
	var g := _at_reveal(0)
	g.start_packing(false)
	await wait_seconds(0.6)
	g._set_pad_mode(true)
	var it: DeskItem = g.items[0]
	g._cursor = it.position
	g._set_hover(it)
	var a := InputEventAction.new()
	a.action = &"action_primary"
	a.pressed = true
	g._unhandled_input(a)
	assert_eq(g._held, it, "A grabs in the pack phase")
	g._cursor = g.pack_rect_px().position + Vector2(it.grid_size()) * Desk.CELL * 0.5
	await wait_frames(30)
	g._unhandled_input(a)
	await wait_seconds(0.3)
	assert_true(it.packed, "A drops into the container")
	var y := InputEventAction.new()
	y.action = &"finish_job"
	y.pressed = true
	g._unhandled_input(y)
	await wait_seconds(2.5)
	assert_eq(g.phase, Game.Phase.DONE, "Y packs the rest")
