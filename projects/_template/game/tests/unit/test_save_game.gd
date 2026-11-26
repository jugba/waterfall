extends GutTest
## SaveGame autoload: round trip, missing and corrupt slots, atomic write leaves no tmp file.

var _orig_dir: String


func before_each() -> void:
	_orig_dir = SaveGame.directory
	SaveGame.directory = "user://test_saves_%d" % Time.get_ticks_usec()


func after_each() -> void:
	if not DirAccess.dir_exists_absolute(SaveGame.directory):
		SaveGame.directory = _orig_dir
		return
	for f in DirAccess.get_files_at(SaveGame.directory):
		DirAccess.remove_absolute(SaveGame.directory.path_join(f))
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_dir


func test_round_trip() -> void:
	var data := {"level": 3, "name": "Ada", "inventory": ["key", "map"]}
	assert_eq(SaveGame.save_slot(1, data), OK)
	assert_true(SaveGame.has_slot(1))
	var loaded := SaveGame.load_slot(1)
	assert_eq(int(loaded["level"]), 3)
	assert_eq(loaded["name"], "Ada")
	assert_eq(loaded["inventory"], ["key", "map"])
	assert_false(FileAccess.file_exists(SaveGame.slot_path(1) + ".tmp"), "tmp file renamed away")


func test_missing_slot_returns_empty() -> void:
	assert_false(SaveGame.has_slot(7))
	assert_eq(SaveGame.load_slot(7), {})


func test_corrupt_slot_returns_empty() -> void:
	DirAccess.make_dir_recursive_absolute(SaveGame.directory)
	var f := FileAccess.open(SaveGame.slot_path(2), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert_eq(SaveGame.load_slot(2), {})


func test_delete_slot() -> void:
	SaveGame.save_slot(3, {"a": 1})
	assert_eq(SaveGame.delete_slot(3), OK)
	assert_false(SaveGame.has_slot(3))
