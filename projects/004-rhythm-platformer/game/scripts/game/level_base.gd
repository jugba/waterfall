class_name LevelBase
extends Node2D
## Shared stage for the sandbox and the music level: sky + parallax, world, collectibles, hero,
## effects, camera and HUD. Subclasses build `ctl` and `world` first, then call _build_stage().

const HUD_INK := Color(0.16, 0.08, 0.22)

var T: Dictionary
var ctl: PlayerController
var world: World
var backdrop: Backdrop
var world_view: WorldView
var lum_view: LumView
var fx: Fx
var hero: PlayerView
var cam: GameCamera
var hud: CanvasLayer
var lum_label: Label
var info_label: Label
var hint_label: Label
var center_label: Label
var lums_total := 0
var lums_got := 0
var _center_t := 0.0
var autoplay := false


func _build_stage() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	backdrop = Backdrop.new()
	bg_layer.add_child(backdrop)
	world_view = WorldView.new()
	world_view.world = world
	add_child(world_view)
	lum_view = LumView.new()
	add_child(lum_view)
	fx = Fx.new()
	add_child(fx)
	hero = PlayerView.new()
	hero.z_index = 4
	add_child(hero)
	hero.setup(ctl, fx)
	cam = GameCamera.new()
	cam.target = hero
	cam.ctl = ctl
	add_child(cam)
	cam.make_current()
	hero.shake.connect(cam.add_shake)
	backdrop.camera = cam
	world_view.camera = cam
	lum_view.camera = cam
	_build_hud()
	cam.snap()


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	lum_label = _label(Vector2(28, 18), 36, HORIZONTAL_ALIGNMENT_LEFT)
	info_label = _label(Vector2(0, 18), 32, HORIZONTAL_ALIGNMENT_RIGHT)
	info_label.anchor_left = 1.0
	info_label.anchor_right = 1.0
	info_label.offset_left = -640
	info_label.offset_right = -28
	var band := ColorRect.new()
	band.color = Color(0.12, 0.06, 0.18, 0.55)
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.anchor_right = 1.0
	band.offset_top = -92
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(band)
	hint_label = _label(Vector2(0, 0), 28, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.anchor_right = 1.0
	hint_label.offset_top = -90
	hint_label.offset_bottom = -14
	center_label = _label(Vector2.ZERO, 96, HORIZONTAL_ALIGNMENT_CENTER)
	center_label.anchor_right = 1.0
	center_label.anchor_top = 0.3
	center_label.anchor_bottom = 0.3
	center_label.offset_bottom = 120
	center_label.text = ""


func _label(pos: Vector2, size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.position = pos
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", HUD_INK)
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(l)
	return l


func show_center(text: String, time := 0.8) -> void:
	center_label.text = text
	center_label.scale = Vector2.ONE * 1.3
	center_label.pivot_offset = Vector2(get_viewport_rect().size.x * 0.5, 60)
	_center_t = time


func _process(delta: float) -> void:
	if _center_t > 0.0:
		_center_t -= delta
		center_label.scale = center_label.scale.lerp(Vector2.ONE, 1.0 - exp(-14.0 * delta))
		if _center_t <= 0.0:
			center_label.text = ""
	lum_label.text = "Notes  %d / %d" % [lums_got, lums_total]


## Collect a lum: chain pitch rises on quick successive pickups.
func collect_lum(at: Vector2, chain: int) -> void:
	lums_got += 1
	Sfx.play("lum", -5.0, Sfx.chain_pitch(chain), 0.0)
	fx.sparks(at, 6, Color(1.0, 0.9, 0.4), 260.0)
	fx.ring(at, 34.0, Color(1.0, 0.95, 0.6, 0.9), 0.25)
	if chain > 0 and chain % 5 == 4:
		fx.popup(at + Vector2(0, -30), "x%d!" % (chain + 1), Color(1.0, 0.9, 0.4), 32)


func controls_hint() -> String:
	return "Move %s/%s or stick   Jump %s/A (hold: higher, glide)   Down: fast-fall\nPunch %s/X   Dash %s/B/RT   Pause %s/Start" % [
		Settings.binding_label(&"move_left"), Settings.binding_label(&"move_right"),
		Settings.binding_label(&"jump"), Settings.binding_label(&"punch"),
		Settings.binding_label(&"dash"), Settings.binding_label(&"pause")]


func is_autoplay() -> bool:
	return autoplay or (OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay"))
