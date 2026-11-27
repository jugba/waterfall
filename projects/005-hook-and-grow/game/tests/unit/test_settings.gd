extends GutTest
## Settings autoload: volumes reach the AudioServer, settings persist, rebinding keeps the
## other device kind, and bindings survive a save/load cycle.

var _orig_path: String


func before_each() -> void:
	_orig_path = Settings.path
	Settings.path = "user://test_settings_%d.cfg" % Time.get_ticks_usec()
	Settings.load_settings()  # defaults


func after_each() -> void:
	DirAccess.remove_absolute(Settings.path)
	Settings.path = _orig_path
	Settings.load_settings()


func test_buses_exist() -> void:
	for bus in Settings.BUSES:
		assert_gt(AudioServer.get_bus_index(bus), -1, "bus %s in default_bus_layout.tres" % bus)


func test_volume_applies_to_bus() -> void:
	Settings.set_volume("Music", 0.5)
	var idx := AudioServer.get_bus_index("Music")
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), linear_to_db(0.5), 0.01)
	Settings.set_volume("Music", 0.0)
	assert_true(AudioServer.is_bus_mute(idx), "zero volume mutes")


func test_settings_persist() -> void:
	Settings.set_volume("SFX", 0.25)
	Settings.set_fullscreen(true)
	assert_eq(Settings.save_settings(), OK)
	Settings.load_settings()
	assert_almost_eq(Settings.get_volume("SFX"), 0.25, 0.001)
	assert_true(Settings.fullscreen)


func test_rebind_keyboard_keeps_controller() -> void:
	var k := InputEventKey.new()
	k.physical_keycode = KEY_Q
	Settings.rebind(&"move_left", k)
	var keys := 0
	var pads := 0
	var has_q := false
	for e in InputMap.action_get_events(&"move_left"):
		if Settings.is_controller_event(e):
			pads += 1
		else:
			keys += 1
			has_q = has_q or e.physical_keycode == KEY_Q
	assert_true(has_q, "Q bound")
	assert_eq(keys, 2, "replaced one key, kept the arrow key")
	assert_eq(pads, 2, "controller bindings untouched")


func test_rebind_survives_save_load() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_Y
	Settings.rebind(&"hook", b)
	Settings.save_settings()
	Settings.reset_bindings()
	Settings.load_settings()
	var found := false
	for e in InputMap.action_get_events(&"hook"):
		found = found or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	assert_true(found)


func test_reset_bindings() -> void:
	var k := InputEventKey.new()
	k.physical_keycode = KEY_Z
	Settings.rebind(&"pause", k)
	Settings.reset_bindings()
	assert_eq(Settings.binding_label(&"pause"), "Escape")
