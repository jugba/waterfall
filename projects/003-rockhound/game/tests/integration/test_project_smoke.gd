extends GutTest
## Whole-project smoke tests: every script compiles, every scene instantiates, the main scene
## is set, the core loop runs, the pause menu pauses, scene transitions work.

const SCAN_DIRS := ["res://autoload", "res://scenes", "res://scripts", "res://ui"]

var _orig_save_dir: String


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	SaveGame.directory = "user://test_smoke_saves"


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir
	get_tree().paused = false
	Engine.time_scale = 1.0
	for a in [&"action_primary", &"pause"]:
		Input.action_release(a)


func _files(ext: String) -> Array[String]:
	var out: Array[String] = []
	var stack: Array = SCAN_DIRS.duplicate()
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for d in DirAccess.get_directories_at(dir):
			stack.append(dir.path_join(d))
		for f in DirAccess.get_files_at(dir):
			if f.get_extension() == ext:
				out.append(dir.path_join(f))
	return out


func test_all_scripts_compile() -> void:
	var scripts := _files("gd")
	assert_gt(scripts.size(), 5)
	for p in scripts:
		var s: GDScript = load(p)
		assert_not_null(s, p)
		if s:
			assert_true(s.can_instantiate(), "%s compiles" % p)


func test_all_scenes_instantiate() -> void:
	var scenes := _files("tscn")
	assert_gt(scenes.size(), 2)
	for p in scenes:
		var packed: PackedScene = load(p)
		assert_not_null(packed, p)
		if packed:
			var node := packed.instantiate()
			assert_not_null(node, "%s instantiates" % p)
			node.free()


func test_main_scene_set() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene", "")
	assert_true(ResourceLoader.exists(main), "main scene %s exists" % main)


func test_core_loop_dig_crack_sell_buy() -> void:
	var game: Node = add_child_autofree(load("res://scenes/game.tscn").instantiate())
	var eco = game.eco
	assert_eq(eco.money, 0.0, "fresh save")
	# Dig until a geode reaches the anvil.
	var hits := 0
	while game.anvil_state != game.Anvil.GEODE and hits < 100:
		game.dig_hit()
		hits += 1
	assert_eq(game.anvil_state, game.Anvil.GEODE, "a geode is on the anvil after %d hits" % hits)
	assert_lte(hits, 10, "first geode comes fast")
	# Crack it.
	var strikes := 0
	while game.anvil_state == game.Anvil.GEODE and strikes < 50:
		game.strike()
		strikes += 1
	assert_eq(game.anvil_state, game.Anvil.REVEALED)
	assert_false(game.revealed.is_empty())
	assert_eq(eco.collection.size(), 1, "book has the crystal")
	# Sell, then keep looping until the first upgrade is affordable and buy it.
	game.collect()
	assert_gt(eco.money, 0.0, "sold for money")
	var loops := 0
	while not eco.can_buy("pick") and loops < 200:
		if game.anvil_state == game.Anvil.GEODE:
			game.strike()
		elif game.anvil_state == game.Anvil.REVEALED:
			game.collect()
		else:
			game.dig_hit()
		loops += 1
	assert_true(game.buy("pick"), "bought Sharper Pick")
	assert_eq(eco.level("pick"), 1)
	Engine.time_scale = 1.0


func test_book_toggles() -> void:
	var game: Node = add_child_autofree(load("res://scenes/game.tscn").instantiate())
	game.toggle_book()
	assert_true(game.book.visible)
	game.toggle_book()
	assert_false(game.book.visible)


func test_pause_menu_pauses_and_resumes() -> void:
	var game: Node = add_child_autofree(load("res://scenes/game.tscn").instantiate())
	var menu = game.get_node("PauseMenu")
	menu.pause()
	assert_true(get_tree().paused)
	assert_true(menu.get_node("%Root").visible)
	menu.resume()
	assert_false(get_tree().paused)


func test_scene_changer_rejects_missing_scene() -> void:
	var err = await SceneChanger.change_to("res://does_not_exist.tscn")
	assert_eq(err, ERR_FILE_NOT_FOUND)
	assert_push_error("no scene at")  # expected error; GUT fails tests on unasserted errors
	assert_false(SceneChanger.busy)
