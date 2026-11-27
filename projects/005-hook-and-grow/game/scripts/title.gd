extends Control
## Title screen: Play (2D) / Play 3D Arena (test) / Settings / Quit. The first button takes focus so controllers work at once.

const GAME_SCENE := "res://scenes/game.tscn"
const GAME_3D_SCENE := "res://scenes/game_3d.tscn"   # "3D Arena (test)": same rules, 3D view

@onready var _menu: Control = %Menu
@onready var _settings_menu: Control = %SettingsMenu


func _ready() -> void:
	%Play.pressed.connect(_on_play)
	%Play3D.pressed.connect(func(): SceneChanger.change_to(GAME_3D_SCENE))
	%Settings.pressed.connect(_on_settings)
	%Quit.pressed.connect(get_tree().quit)
	%Quit.visible = OS.get_name() != "Web"
	%Version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0")
	_settings_menu.closed.connect(_on_settings_closed)
	%Play.grab_focus()
	_add_mascot()


## Charm on the title: Morsel bobbing next to the menu, eyeing a snack, plus a tagline and records.
func _add_mascot() -> void:
	var tag := Label.new()
	tag.text = "a tiny hungry thing in a very deep sea"
	tag.add_theme_font_size_override("font_size", 30)
	tag.add_theme_color_override("font_color", Color("9ad1ff"))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vb: VBoxContainer = %Play.get_parent()
	vb.add_child(tag)
	vb.move_child(tag, 1)
	var rec := Records.from_save(SaveGame.load_slot(0))
	if rec["runs"] > 0:
		var r := Label.new()
		r.text = "Best: Leviathan eaten in %s  -  biggest size %.1f" % [
			Records.format_time(rec["best_win_time"]), rec["best_size"]]
		r.add_theme_font_size_override("font_size", 28)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(r)
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	art.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		var p := Vector2(165, 400 + sin(t * 2.0) * 12.0)
		var snack := Vector2(120 + sin(t * 1.3) * 20.0, 590 + cos(t * 1.7) * 14.0)
		Look.glow(art, p, 220.0, Color(0.3, 0.9, 0.85, 0.12))
		Look.draw_morsel(art, p, 78.0, (snack - p).angle(), Vector2(1.0 + sin(t * 4.0) * 0.03, 1.0 - sin(t * 4.0) * 0.03),
			{"t": t, "mouth": 0.3 + 0.3 * sin(t * 3.0), "look": Vector2(0.2, 0.9), "traits": {"speed": 1, "damage": 2}})
		art.draw_circle(snack, 22.0, Look.KIND_COLORS["nibbler"])
		Look.eye(art, snack + Vector2(6, -4), 9.0, (p - snack).normalized(), "wide")
		var boss := Vector2(1150, 660 + sin(t) * 10.0)
		art.draw_circle(boss, 150.0, Color(Look.KIND_COLORS["boss"], 0.6))
		Look.glow(art, boss + Vector2(-120, -140), 70.0 + sin(t * 3.0) * 6.0, Color(1.0, 0.95, 0.5, 0.5))
		art.draw_circle(boss + Vector2(-120, -140), 14.0, Look.LURE)
		Look.eye(art, boss + Vector2(-60, -50), 18.0, Vector2(-1, 0), "angry"))
	var tw := create_tween().set_loops()
	tw.tween_callback(art.queue_redraw).set_delay(1.0 / 30.0)


func _on_play() -> void:
	SceneChanger.change_to(GAME_SCENE)


func _on_settings() -> void:
	_menu.hide()
	_settings_menu.open()


func _on_settings_closed() -> void:
	_menu.show()
	%Settings.grab_focus()
