extends GutTest
## Whole-project smoke tests: every script compiles, every scene instantiates, the main scene
## is set, the pause menu pauses, scene transitions work.

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
	Input.action_release(&"pause")


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


func test_pause_menu_pauses_and_resumes() -> void:
	var level: Node = add_child_autofree(load("res://scenes/sandbox.tscn").instantiate())
	var menu = level.get_node("PauseMenu")
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
