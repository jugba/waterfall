extends CanvasLayer
## Pause overlay. Add an instance to any gameplay scene. Opens on the "pause" action
## (Esc / P / controller Start), when the window loses focus, and when the Steam overlay opens.

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var _root: Control = %Root
@onready var _settings_menu: Control = %SettingsMenu


func _ready() -> void:
	%Resume.pressed.connect(resume)
	%Settings.pressed.connect(_open_settings)
	%Quit.pressed.connect(_quit_to_title)
	_settings_menu.closed.connect(_on_settings_closed)
	SteamService.overlay_toggled.connect(func(active: bool) -> void:
		if active:
			pause())


func is_paused() -> bool:
	return get_tree().paused


func pause() -> void:
	if get_tree().paused or SceneChanger.busy:
		return
	get_tree().paused = true
	_root.show()
	%Resume.grab_focus()


func resume() -> void:
	_settings_menu.hide()
	_root.hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if not get_tree().paused:
			pause()
		elif not _settings_menu.visible:
			resume()
	elif event.is_action_pressed(&"ui_cancel") and get_tree().paused and not _settings_menu.visible:
		get_viewport().set_input_as_handled()
		resume()


func _notification(what: int) -> void:
	# Auto-pause when the player alt-tabs or the Deck is suspended.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		pause()


func _open_settings() -> void:
	_root.hide()
	_settings_menu.open()


func _on_settings_closed() -> void:
	_root.show()
	%Settings.grab_focus()


func _quit_to_title() -> void:
	SceneChanger.change_to(TITLE_SCENE)
