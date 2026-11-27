extends GutTest
## SteamService must be a safe no-op without GodotSteam (CI, editor, tests).


func test_noop_without_godotsteam() -> void:
	if Engine.has_singleton("Steam"):
		pass_test("GodotSteam is installed; no-op path not testable here")
		return
	assert_false(SteamService.available)
	assert_false(SteamService.unlock_achievement("ACH_TEST"))
	assert_false(SteamService.set_stat_int("STAT_TEST", 1))
	assert_false(SteamService.set_rich_presence("status", "Testing"))
	assert_eq(SteamService.persona_name(), "")


func test_app_id_configured() -> void:
	assert_gt(int(ProjectSettings.get_setting(SteamService.APP_ID_SETTING, 0)), 0)
