extends GutTest
## Whole-project smoke tests: every script compiles, every scene instantiates, the main scene
## is set, the player moves on input, the pause menu pauses, scene transitions work.

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
	for a in [&"move_right", &"pause"]:
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
	assert_gt(scenes.size(), 3)
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


func test_player_moves_right_on_input() -> void:
	var player: CharacterBody2D = add_child_autofree(load("res://scenes/player.tscn").instantiate())
	player.position = Vector2(200, 200)
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	Input.action_release(&"move_right")
	assert_gt(player.position.x, 200.0, "moved right")
	assert_almost_eq(player.position.y, 200.0, 0.5, "did not drift vertically")


func test_pause_menu_pauses_and_resumes() -> void:
	var game: Node = add_child_autofree(load("res://scenes/game.tscn").instantiate())
	var menu = game.get_node("PauseMenu")
	menu.pause()
	assert_true(get_tree().paused)
	assert_true(menu.get_node("%Root").visible)
	menu.resume()
	assert_false(get_tree().paused)


func test_game_scene_saves_player_position() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.get_node("Player").position = Vector2(300, 333)
	game.free()  # _exit_tree saves
	var data := SaveGame.load_slot(0)
	assert_almost_eq(float(data.get("player_y", 0)), 333.0, 0.01)


func test_scene_changer_rejects_missing_scene() -> void:
	var err = await SceneChanger.change_to("res://does_not_exist.tscn")
	assert_eq(err, ERR_FILE_NOT_FOUND)
	assert_push_error("no scene at")  # expected error; GUT fails tests on unasserted errors
	assert_false(SceneChanger.busy)
