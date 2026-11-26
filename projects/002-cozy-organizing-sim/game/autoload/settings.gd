extends Node
## Player settings: bus volumes, display mode and input rebinding, saved to user://settings.cfg.
##
## Usage: Settings.set_volume("Music", 0.5); Settings.set_fullscreen(true); Settings.save_settings()
## Rebinding: Settings.rebind(&"move_left", event) replaces the binding of the same device kind
## (keyboard vs controller), so remapping the keyboard never breaks the controller.
## Bindings are stored as plain dictionaries, never as serialized Objects, so a tampered
## settings file cannot instantiate scripts.

signal changed

const DEFAULT_PATH := "user://settings.cfg"
const BUSES: Array[String] = ["Master", "Music", "SFX"]
## Actions shown in the controls menu. Add game-specific actions here and in project.godot.
const REBINDABLE_ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"action_primary", &"action_secondary", &"rotate_cw", &"rotate_ccw", &"finish_job", &"pause",
]
const DEFAULT_VOLUMES := {"Master": 0.8, "Music": 0.7, "SFX": 0.8}

var path := DEFAULT_PATH
var volumes: Dictionary = DEFAULT_VOLUMES.duplicate()
var fullscreen := false
var vsync := true

var _default_events: Dictionary = {}  # StringName -> Array[InputEvent]


func _ready() -> void:
	for action in REBINDABLE_ACTIONS:
		_default_events[action] = InputMap.action_get_events(action).duplicate()
	load_settings()


# --- audio -------------------------------------------------------------------

## linear: 0.0 (muted) .. 1.0 (full)
func set_volume(bus: String, linear: float) -> void:
	volumes[bus] = clampf(linear, 0.0, 1.0)
	_apply_volume(bus)
	changed.emit()


func get_volume(bus: String) -> float:
	return volumes.get(bus, 1.0)


func _apply_volume(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v: float = volumes.get(bus, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


# --- display -----------------------------------------------------------------

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_display()
	changed.emit()


func set_vsync(on: bool) -> void:
	vsync = on
	_apply_display()
	changed.emit()


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


# --- input -------------------------------------------------------------------

static func is_controller_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


## Replace the first binding of `action` with the same device kind as `event`.
func rebind(action: StringName, event: InputEvent) -> void:
	var events := InputMap.action_get_events(action)
	var want_pad := is_controller_event(event)
	var replaced := false
	InputMap.action_erase_events(action)
	for e in events:
		if not replaced and is_controller_event(e) == want_pad:
			InputMap.action_add_event(action, event)
			replaced = true
		else:
			InputMap.action_add_event(action, e)
	if not replaced:
		InputMap.action_add_event(action, event)
	changed.emit()


func reset_bindings() -> void:
	for action in _default_events:
		InputMap.action_erase_events(action)
		for e in _default_events[action]:
			InputMap.action_add_event(action, e)
	changed.emit()


## Human-readable label of the first binding of the given kind, for menus and prompts.
func binding_label(action: StringName, controller := false) -> String:
	for e in InputMap.action_get_events(action):
		if is_controller_event(e) == controller:
			return _event_label(e)
	return "-"


static func _event_label(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		return OS.get_keycode_string(DisplayServer.keyboard_get_label_from_physical(code)) \
			if DisplayServer.get_name() != "headless" else OS.get_keycode_string(code)
	if e is InputEventJoypadButton:
		return "Pad %d" % e.button_index
	if e is InputEventJoypadMotion:
		return "Axis %d%s" % [e.axis, "+" if e.axis_value > 0 else "-"]
	return e.as_text()


static func event_to_dict(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		return {"type": "key", "code": int(e.physical_keycode if e.physical_keycode else e.keycode)}
	if e is InputEventJoypadButton:
		return {"type": "pad_button", "button": int(e.button_index)}
	if e is InputEventJoypadMotion:
		return {"type": "pad_axis", "axis": int(e.axis), "value": signf(e.axis_value)}
	return {}


static func dict_to_event(d: Dictionary) -> InputEvent:
	match d.get("type", ""):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.get("code", 0)) as Key
			return k
		"pad_button":
			var b := InputEventJoypadButton.new()
			b.button_index = int(d.get("button", 0)) as JoyButton
			b.device = -1
			return b
		"pad_axis":
			var m := InputEventJoypadMotion.new()
			m.axis = int(d.get("axis", 0)) as JoyAxis
			m.axis_value = float(d.get("value", 1.0))
			m.device = -1
			return m
	return null


# --- persistence -------------------------------------------------------------

func save_settings() -> Error:
	var cfg := ConfigFile.new()
	for bus in BUSES:
		cfg.set_value("audio", bus, volumes.get(bus, 1.0))
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	for action in REBINDABLE_ACTIONS:
		var list: Array = []
		for e in InputMap.action_get_events(action):
			var d := event_to_dict(e)
			if not d.is_empty():
				list.append(d)
		cfg.set_value("input", String(action), list)
	return cfg.save(path)


## Loads saved settings (defaults if the file is missing or unreadable) and applies them.
func load_settings() -> void:
	volumes = DEFAULT_VOLUMES.duplicate()
	fullscreen = false
	vsync = true
	reset_bindings()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		for bus in BUSES:
			volumes[bus] = clampf(float(cfg.get_value("audio", bus, volumes.get(bus, 1.0))), 0.0, 1.0)
		fullscreen = bool(cfg.get_value("display", "fullscreen", false))
		vsync = bool(cfg.get_value("display", "vsync", true))
		for action in REBINDABLE_ACTIONS:
			var list = cfg.get_value("input", String(action), null)
			if list is Array and not list.is_empty():
				InputMap.action_erase_events(action)
				for d in list:
					var e: InputEvent = dict_to_event(d) if d is Dictionary else null
					if e:
						InputMap.action_add_event(action, e)
	for bus in BUSES:
		_apply_volume(bus)
	_apply_display()
	changed.emit()
