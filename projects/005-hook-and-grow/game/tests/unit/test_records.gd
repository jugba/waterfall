extends GutTest
## Records saved to SaveGame slot 0, and the gameplay settings added for this game.

var _orig_dir: String
var _orig_path: String


func before_each() -> void:
	_orig_dir = SaveGame.directory
	SaveGame.directory = "user://test_records_%d" % Time.get_ticks_usec()
	_orig_path = Settings.path
	Settings.path = "user://test_settings_rec_%d.cfg" % Time.get_ticks_usec()
	Settings.load_settings()


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_dir
	DirAccess.remove_absolute(Settings.path)
	Settings.path = _orig_path
	Settings.load_settings()


func test_records_accumulate_and_keep_bests() -> void:
	var r := Records.from_save({})
	assert_eq(r["runs"], 0)
	r = Records.add_run(r, 700.0, 30.0, false)
	r = Records.add_run(r, 650.0, 44.0, true)
	r = Records.add_run(r, 690.0, 43.0, true)
	assert_eq(r["runs"], 3)
	assert_eq(r["wins"], 2)
	assert_almost_eq(r["best_win_time"], 650.0, 0.001)
	assert_almost_eq(r["best_size"], 44.0, 0.001)
	assert_eq(Records.format_time(650.0), "10:50")
	assert_eq(Records.format_time(-1.0), "--:--")


func test_records_survive_save_load() -> void:
	var r := Records.add_run({}, 612.0, 43.5, true)
	assert_eq(SaveGame.save_slot(0, r), OK)
	var back := Records.from_save(SaveGame.load_slot(0))
	assert_eq(back["wins"], 1)
	assert_almost_eq(back["best_win_time"], 612.0, 0.001)


func test_corrupt_records_fall_back_to_defaults() -> void:
	var back := Records.from_save({"runs": "lots", "best_size": null})
	assert_eq(back["runs"], 0)
	assert_eq(back["best_size"], 0.0)


func test_gameplay_settings_persist() -> void:
	Settings.set_screen_shake(0.3)
	Settings.set_aim_assist(false)
	assert_eq(Settings.save_settings(), OK)
	Settings.screen_shake = 1.0
	Settings.aim_assist = true
	Settings.load_settings()
	assert_almost_eq(Settings.screen_shake, 0.3, 0.001)
	assert_false(Settings.aim_assist)


func test_mouse_binding_survives_save_load() -> void:
	assert_eq(Settings.binding_label(&"hook"), "J")
	assert_eq(Settings.save_settings(), OK)
	Settings.load_settings()
	var has_mouse := false
	for e in InputMap.action_get_events(&"hook"):
		has_mouse = has_mouse or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)
	assert_true(has_mouse, "left click still throws after a settings round trip")


func test_controller_aim_actions_exist() -> void:
	for a in [&"aim_left", &"aim_right", &"aim_up", &"aim_down"]:
		assert_true(InputMap.has_action(a))
		var pad := false
		for e in InputMap.action_get_events(a):
			pad = pad or (e is InputEventJoypadMotion and e.device == -1)
		assert_true(pad, "%s on the right stick, any pad" % a)
