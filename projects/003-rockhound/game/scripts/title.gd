extends Control
## Title screen: Play / Settings / Quit. The first button takes focus so controllers work at once.

const GAME_SCENE := "res://scenes/game.tscn"

@onready var _menu: Control = %Menu
@onready var _settings_menu: Control = %SettingsMenu


func _ready() -> void:
	%Play.pressed.connect(_on_play)
	%NewGame.pressed.connect(_on_new_game)
	%Play.text = "Continue" if SaveGame.has_slot(0) else "Play"
	%NewGame.visible = SaveGame.has_slot(0)
	%Settings.pressed.connect(_on_settings)
	%Quit.pressed.connect(get_tree().quit)
	%Quit.visible = OS.get_name() != "Web"
	%Version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0")
	_settings_menu.closed.connect(_on_settings_closed)
	%Play.grab_focus()


func _on_play() -> void:
	SceneChanger.change_to(GAME_SCENE)


func _on_new_game() -> void:
	SaveGame.delete_slot(0)
	SceneChanger.change_to(GAME_SCENE)


func _on_settings() -> void:
	_menu.hide()
	_settings_menu.open()


func _on_settings_closed() -> void:
	_menu.show()
	%Settings.grab_focus()
