class_name Hud
extends Control
## In-run HUD, built in code: size + HP, wave, trait badges, control hints, banners, floating
## text, boss bar, the evolution choice and the victory panel. All text >= 28 px at 1280x800.

signal evolution_chosen(index: int)
signal continue_pressed
signal title_pressed

const FORM_INFO := {
	"multi": ["Twin Lure", "Throw 3 hooks in a fan.", "Fan Lure", "Throw 5 hooks in a wide fan."],
	"chain": ["Chain Maw", "A catch leaps to 2 more prey nearby.", "Chain Maw II", "Catches leap to 3 more prey."],
	"whirl": ["Whirlpool", "Your dodge spins the hook in a full circle, snagging 2 prey.", "Whirlpool II", "Spin dodge snags 4 prey."],
	"long": ["Long Line", "+30% hook range.", "Longer Line", "Another +30% hook range."],
}

var sim: ArenaSim
var _size_label: Label
var _delta_label: Label
var _wave_label: Label
var _hint: Label
var _banner: Label
var _sub: Label
var _boss_label: Label
var _traits_box: HBoxContainer
var _trait_labels: Dictionary = {}
var _evolve: Control
var _evolve_buttons: Array[Button] = []
var _win: Control
var _win_text: Label
var _vignette: ColorRect
var _banner_tween: Tween
var _shown_hp := 1.0
var _delta_acc := 0.0
var _delta_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(1, 0.1, 0.2, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)
	_size_label = _label(40, Vector2(28, 14))
	_delta_label = _label(30, Vector2(250, 20))
	_delta_label.modulate = Color(0.75, 1, 0.8, 0)
	_wave_label = _label(30, Vector2.ZERO)
	_place(_wave_label, Control.PRESET_CENTER_TOP, -200, 16, 200, 56)
	_traits_box = HBoxContainer.new()
	_place(_traits_box, Control.PRESET_TOP_RIGHT, -620, 64, -24, 108)
	_traits_box.alignment = BoxContainer.ALIGNMENT_END
	_traits_box.add_theme_constant_override("separation", 18)
	for t in Growth.TRAITS:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", Look.TRAIT_COLORS[t])
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 6)
		l.visible = false
		_traits_box.add_child(l)
		_trait_labels[t] = l
	_hint = _label(28, Vector2.ZERO)
	_place(_hint, Control.PRESET_CENTER_BOTTOM, -630, -56, 630, -16)
	_banner = _label(60, Vector2.ZERO)
	_place(_banner, Control.PRESET_CENTER, -630, -250, 630, -170)
	_banner.modulate.a = 0.0
	_sub = _label(32, Vector2.ZERO)
	_place(_sub, Control.PRESET_CENTER, -630, -165, 630, -121)
	_sub.modulate.a = 0.0
	_boss_label = _label(30, Vector2.ZERO)
	_place(_boss_label, Control.PRESET_CENTER_BOTTOM, -630, -104, 630, -62)
	_boss_label.visible = false
	_build_evolve()
	_build_win()


func _place(c: Control, preset: int, l: float, t: float, r: float, b: float) -> void:
	if c.get_parent() == null:
		add_child(c)
	c.set_anchors_preset(preset)
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b
	if c is Label:
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(font_size: int, at: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.position = at
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func set_hint(text: String) -> void:
	_hint.text = text


func _process(delta: float) -> void:
	if sim == null:
		return
	_size_label.text = "Size %.1f" % sim.size
	_shown_hp = lerpf(_shown_hp, sim.hp / sim.st["hp_max"], 1.0 - exp(-10.0 * delta))
	if sim.wave < sim.wave_count():
		_wave_label.text = "Wave %d / %d" % [sim.wave + 1, sim.wave_count()]
	else:
		_wave_label.text = "BOSS" if not sim.won else "ENDLESS"
	var cap := int(sim.B["traits"]["cap"])
	for t in Growth.TRAITS:
		var lvl := Growth.stack(sim.traits, t, cap)
		var l: Label = _trait_labels[t]
		l.visible = lvl > 0
		l.text = "%s %s" % [Look.TRAIT_NAMES[t], Look.ROMAN[lvl]]
	if sim.boss != null:
		_boss_label.visible = true
		var dots := "%d bite%s left" % [sim.boss.bites_left, "" if sim.boss.bites_left == 1 else "s"]
		if sim.hookable(sim.boss):
			_boss_label.text = "LANTERN LEVIATHAN  -  %s  -  HOOK IT AND REEL!" % dots
			_boss_label.add_theme_color_override("font_color", Color("b8ffb0"))
		else:
			_boss_label.text = "LANTERN LEVIATHAN  -  %s  -  grow to size %.1f to hook it (you: %.1f)" % [dots, Growth.size_needed(sim.B, sim.boss.size), sim.size]
			_boss_label.add_theme_color_override("font_color", Color("ffb0b8"))
	else:
		_boss_label.visible = false
	_delta_t -= delta
	if _delta_t <= 0.0:
		_delta_acc = 0.0
	_delta_label.modulate.a = clampf(_delta_t, 0.0, 1.0)
	_vignette.color.a = maxf(0.0, _vignette.color.a - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	# off-screen boss: an arrow on the screen edge pointing at it
	if sim.boss != null:
		var sp: Vector2 = get_viewport().get_canvas_transform() * sim.boss.pos
		var vr := get_viewport_rect()
		var rect := Rect2(70.0, 130.0, vr.size.x - 140.0, vr.size.y - 270.0)  # clear of the HUD rows
		if not rect.has_point(sp):
			var c := rect.get_center()
			var d := (sp - c)
			var t := minf(absf(rect.size.x * 0.5 / maxf(absf(d.x), 0.001)), absf(rect.size.y * 0.5 / maxf(absf(d.y), 0.001)))
			var at := c + d * minf(t, 1.0)
			var dir := d.normalized()
			var col := Color("b8ffb0") if sim.hookable(sim.boss) else Color("ff8a95")
			draw_colored_polygon(PackedVector2Array([at + dir * 34.0, at + dir.orthogonal() * 20.0 - dir * 6.0,
				at - dir.orthogonal() * 20.0 - dir * 6.0]), col)
			draw_string(get_theme_default_font(), at - dir * 44.0 - Vector2(36, -10), "BOSS",
				HORIZONTAL_ALIGNMENT_CENTER, 72, 28, col)
	# HP bar under the size
	var r := Rect2(30, 66, 300, 18)
	draw_rect(r.grow(3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(_shown_hp, 0, 1), r.size.y)), Color("ff5d73").lerp(Color("7dffb0"), clampf(_shown_hp, 0, 1)))


func on_meal(size_before: float, size_after: float) -> void:
	_delta_acc += size_after - size_before
	_delta_t = 1.4
	_delta_label.text = "+%.2f" % _delta_acc
	_delta_label.position.x = 30 + _size_label.get_minimum_size().x + 10
	_size_label.pivot_offset = _size_label.size * Vector2(0, 0.5)
	var tw := create_tween()
	_size_label.scale = Vector2.ONE * 1.18
	tw.tween_property(_size_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hurt_flash(strength := 0.3) -> void:
	_vignette.color.a = maxf(_vignette.color.a, strength)


func banner(text: String, sub := "", hold := 1.6, color := Color.WHITE) -> void:
	_banner.text = text
	_sub.text = sub
	_banner.add_theme_color_override("font_color", color)
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_sub.modulate.a = 1.0 if sub != "" else 0.0
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2.ONE * 1.3
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.parallel().tween_property(_sub, "modulate:a", 0.0, 0.4)


## Floating text at a screen position; rises and fades.
func floater(text: String, screen_pos: Vector2, color := Color.WHITE, font_size := 30) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.position = screen_pos - Vector2(l.get_minimum_size().x * 0.5, 40)
	l.pivot_offset = l.get_minimum_size() * 0.5
	l.scale = Vector2.ONE * 0.6
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 70, 1.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)


# --- evolution ----------------------------------------------------------------

func _panel(title: String) -> Array:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vb)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 60)
	t.add_theme_color_override("font_color", Look.LURE)
	vb.add_child(t)
	return [root, vb]


func _build_evolve() -> void:
	var p := _panel("EVOLVE!")
	_evolve = p[0]
	var vb: VBoxContainer = p[1]
	var sub := Label.new()
	sub.text = "Choose how your hook works from now on"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 30)
	vb.add_child(sub)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(360, 230)
		b.add_theme_font_size_override("font_size", 28)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): evolution_chosen.emit(i))
		hb.add_child(b)
		_evolve_buttons.append(b)


func show_evolution(options: Array, forms: Dictionary) -> void:
	for i in _evolve_buttons.size():
		var b := _evolve_buttons[i]
		b.visible = i < options.size()
		if not b.visible:
			continue
		var f: String = options[i]
		var info: Array = FORM_INFO[f]
		var lvl := int(forms.get(f, 0))
		b.text = "%s\n\n%s" % [info[0 if lvl == 0 else 2], info[1 if lvl == 0 else 3]]
	_evolve.visible = true
	_evolve_buttons[0].grab_focus()


func hide_evolution() -> void:
	_evolve.visible = false


func evolution_visible() -> bool:
	return _evolve.visible


# --- victory -------------------------------------------------------------------

func _build_win() -> void:
	var p := _panel("YOU ATE THE LEVIATHAN!")
	_win = p[0]
	var vb: VBoxContainer = p[1]
	_win_text = Label.new()
	_win_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_text.add_theme_font_size_override("font_size", 32)
	vb.add_child(_win_text)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	vb.add_child(hb)
	var cont := Button.new()
	cont.text = "Keep eating (endless)"
	cont.custom_minimum_size = Vector2(380, 70)
	cont.pressed.connect(func(): _win.visible = false; continue_pressed.emit())
	hb.add_child(cont)
	var title := Button.new()
	title.text = "Back to title"
	title.custom_minimum_size = Vector2(300, 70)
	title.pressed.connect(func(): title_pressed.emit())
	hb.add_child(title)


func show_win(text: String) -> void:
	_win_text.text = text
	_win.visible = true
	(_win.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func win_visible() -> bool:
	return _win.visible
