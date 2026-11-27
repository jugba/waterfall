extends Control
## Title: choose Movement Sandbox or Music Level. Pip hops on the beat of the theme.

const SANDBOX_SCENE := "res://scenes/sandbox.tscn"
const MUSIC_SCENE := "res://scenes/music_level.tscn"
const BPM := 125.0

@onready var _menu: Control = %Menu
@onready var _settings_menu: Control = %SettingsMenu

var _ctl: PlayerController
var _hero: PlayerView
var _stage: Node2D
var _time := 0.0
var _next_hop := 1


func _ready() -> void:
	%Sandbox.pressed.connect(func(): _go(SANDBOX_SCENE))
	%Music.pressed.connect(func(): _go(MUSIC_SCENE))
	%Settings.pressed.connect(_on_settings)
	%Quit.pressed.connect(get_tree().quit)
	%Quit.visible = OS.get_name() != "Web"
	%Version.text = "v%s greybox" % ProjectSettings.get_setting("application/config/version", "0")
	_settings_menu.closed.connect(_on_settings_closed)
	%Sandbox.grab_focus()
	var map := Beatmap.load_default()
	if ResourceLoader.exists(map.music_path):
		Audio.play_music(load(map.music_path), 0.5)
	_build_hero()


func _build_hero() -> void:
	var bg := Backdrop.new()
	$BackLayer.add_child(bg)
	_stage = Node2D.new()
	_stage.position = Vector2(250, 640)
	_stage.scale = Vector2(2.2, 2.2)
	$BackLayer.add_child(_stage)
	var w := World.new()
	w.add(Rect2(-2000, 0, 4000, 200))
	_ctl = PlayerController.new(Tuning.load_default(), w)
	var ground := WorldView.new()
	ground.world = w
	_stage.add_child(ground)
	var fx := Fx.new()
	_hero = PlayerView.new()
	_hero.muted = true
	_hero.interpolate = false
	_stage.add_child(fx)
	_stage.add_child(_hero)
	_hero.setup(_ctl, fx)


func _physics_process(delta: float) -> void:
	if _ctl == null:
		return
	_time += delta
	var beat := _time * BPM / 60.0
	var inp := InputFrame.new()
	if beat >= _next_hop * 2.0:
		_next_hop += 1
		inp.jump_pressed = true
	inp.jump_held = fmod(beat, 2.0) < 0.3
	_ctl.step(delta, inp)
	_ctl.pos.x = 0.0
	_hero.sync()
	var t := %GameTitle as Label
	t.position.y = -6.0 * exp(-fmod(beat, 1.0) * 5.0)


func _on_settings() -> void:
	_menu.hide()
	_settings_menu.open()


func _on_settings_closed() -> void:
	_menu.show()
	%Settings.grab_focus()


func _go(path: String) -> void:
	Audio.stop_music(0.3)
	SceneChanger.change_to(path)
