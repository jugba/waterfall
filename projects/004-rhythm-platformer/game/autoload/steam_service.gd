extends Node
## Steam integration that works with or without GodotSteam.
##
## If the GodotSteam GDExtension is installed (res://addons/godotsteam/, see the template
## README) and the Steam client is running, this initialises Steam and forwards calls.
## Otherwise every method is a safe no-op that returns false/"" and `available` is false,
## so the game runs the same in the editor, in CI, in tests, and in DRM-free builds.
##
## Game code calls SteamService only, never the `Steam` singleton directly, so the game
## never breaks when GodotSteam is missing.
##
## GodotSteam API names used here are from its 4.x docs and could not be verified from the
## Claude container (godotsteam.com and codeberg.org are blocked): check them against the
## GodotSteam version you install (docs: https://godotsteam.com/classes/main/).

signal overlay_toggled(active: bool)

## App ID comes from Project Settings > game/steam/app_id. 480 is Valve's "Spacewar" test app.
const APP_ID_SETTING := "game/steam/app_id"

var available := false
var status_message := "not initialised"
var _steam: Object = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize()


func initialize() -> bool:
	available = false
	if not Engine.has_singleton("Steam"):
		status_message = "GodotSteam not installed; Steam features disabled"
		return false
	_steam = Engine.get_singleton("Steam")
	var app_id := int(ProjectSettings.get_setting(APP_ID_SETTING, 0))
	# GodotSteam 4.x: steamInitEx(app_id, embed_callbacks) -> {"status": int, "verbal": String};
	# status 0 means OK. embed_callbacks=true means we don't need to call run_callbacks().
	var result = _steam.call("steamInitEx", app_id, true)
	if result is Dictionary:
		available = int(result.get("status", -1)) == 0
		status_message = str(result.get("verbal", result))
	else:
		available = bool(result)
		status_message = "steamInitEx returned %s" % [result]
	if available and _steam.has_signal("overlay_toggled"):
		_steam.connect("overlay_toggled", _on_overlay_toggled)
	print("SteamService: ", status_message)
	return available


func _on_overlay_toggled(active: bool, _user_initiated := false, _app_id := 0) -> void:
	overlay_toggled.emit(active)


## True on a Steam Deck (Steam sets SteamDeck=1 in the environment), even without GodotSteam.
func is_steam_deck() -> bool:
	return OS.get_environment("SteamDeck") == "1"


func persona_name() -> String:
	return str(_call("getPersonaName", [], ""))


## Achievement ids are the API names set in Steamworks > Stats & Achievements.
func unlock_achievement(api_name: String) -> bool:
	if not available:
		return false
	var ok := bool(_call("setAchievement", [api_name], false))
	_call("storeStats", [], false)
	return ok


func set_stat_int(api_name: String, value: int) -> bool:
	if not available:
		return false
	var ok := bool(_call("setStatInt", [api_name, value], false))
	_call("storeStats", [], false)
	return ok


func set_rich_presence(key: String, value: String) -> bool:
	return bool(_call("setRichPresence", [key, value], false))


## Opens the Steam overlay to this game's store page (e.g. a "Wishlist the full game" button in a demo).
func open_store_page() -> void:
	var app_id := int(ProjectSettings.get_setting(APP_ID_SETTING, 0))
	if available:
		_call("activateGameOverlayToStore", [app_id], null)
	else:
		OS.shell_open("https://store.steampowered.com/app/%d" % app_id)


func _call(method: String, args: Array, fallback: Variant) -> Variant:
	if not available or _steam == null or not _steam.has_method(method):
		return fallback
	return _steam.callv(method, args)
