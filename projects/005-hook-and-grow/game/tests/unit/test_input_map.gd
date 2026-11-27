extends GutTest
## Every gameplay action has a keyboard AND a controller binding (Steam Deck / controller support).


func test_actions_have_keyboard_and_controller() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		var has_key := false
		var has_pad := false
		for e in InputMap.action_get_events(action):
			has_key = has_key or e is InputEventKey
			has_pad = has_pad or Settings.is_controller_event(e)
			if Settings.is_controller_event(e):
				assert_eq(e.device, -1, "%s controller binding works on any pad" % action)
		assert_true(has_key, "%s has a key" % action)
		assert_true(has_pad, "%s has a controller binding" % action)


func test_event_serialisation_round_trip() -> void:
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_Y
	m.axis_value = -1.0
	var back := Settings.dict_to_event(Settings.event_to_dict(m))
	assert_true(back is InputEventJoypadMotion)
	assert_eq(back.axis, JOY_AXIS_LEFT_Y)
	assert_eq(back.axis_value, -1.0)
	assert_null(Settings.dict_to_event({"type": "bogus"}))


func test_steam_deck_resolution() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 800)
