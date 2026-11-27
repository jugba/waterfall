class_name Hud
extends CanvasLayer
## Job HUD, built in code: top bar, live neatness meter, client intro card, photo flash and the
## score reveal (count-up, stamp, confetti, one line per scoring reason), the pack-back bar and
## payday buttons, plus the item-name tooltip shown on hover / hold.
## Readability rule (BRIEF): every text is >= MIN_FONT (28 px at 1280x800); tests scan for it.

signal start_pressed
signal photo_pressed
signal pack_pressed
signal next_pressed
signal retry_pressed
signal title_pressed
signal pack_rest_pressed

const PANEL_X := 824.0
const INK := Color("f4f1ea")
const DIM := Color(0.96, 0.94, 0.9, 0.7)
const ACCENT := Color("f2cf4a")
const MIN_FONT := 28

var root: Control
var title_label: Label
var hint_label: Label
var side: Control
var meter_label: Label
var meter_fill: ColorRect
var loose_label: Label
var photo_button: Button
var intro: PanelContainer
var intro_button: Button
var flash_rect: ColorRect
var panel: PanelContainer
var stamp_label: Label
var percent_label: Label
var reasons_box: VBoxContainer
var pay_label: Label
var buttons_box: VBoxContainer
var confetti: CPUParticles2D
var tip_panel: PanelContainer
var tip_label: Label
var pack_bar: PanelContainer
var pack_status: Label
var pack_rest_button: Button

var _meter_value := 0.0
var _intro_client: Label
var _intro_note: Label
var _intro_contents: Label


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	title_label = _label(28, INK)
	title_label.position = Vector2(32, 18)
	title_label.size = Vector2(1000, 40)
	root.add_child(title_label)
	hint_label = _label(MIN_FONT, DIM)
	hint_label.position = Vector2(32, 66)
	hint_label.size = Vector2(1220, 32)
	root.add_child(hint_label)
	_build_side()
	_build_intro()
	_build_panel()
	_build_pack_bar()
	_build_tip()
	confetti = _make_confetti()
	root.add_child(confetti)
	flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(flash_rect)


func _label(size: int, colour: Color, text := "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, signal_to: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.pressed.connect(func(): signal_to.emit())
	return b


func _panel_style(alpha := 0.92) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.13, 0.16, alpha)
	s.border_color = Color(1, 1, 1, 0.12)
	s.set_border_width_all(2)
	s.set_corner_radius_all(14)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 16
	return s


func _build_side() -> void:
	side = Control.new()
	side.position = Vector2(1072, 116)
	side.size = Vector2(192, 420)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(side)
	var cap := _label(MIN_FONT, DIM, "NEATNESS")
	side.add_child(cap)
	meter_label = _label(56, INK, "0%")
	meter_label.position = Vector2(0, 30)
	side.add_child(meter_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.position = Vector2(0, 110)
	bar_bg.size = Vector2(192, 14)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(bar_bg)
	meter_fill = ColorRect.new()
	meter_fill.color = ACCENT
	meter_fill.position = bar_bg.position
	meter_fill.size = Vector2(0, 14)
	meter_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(meter_fill)
	loose_label = _label(MIN_FONT, DIM, "")
	loose_label.position = Vector2(0, 132)
	loose_label.size = Vector2(192, 80)
	loose_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(loose_label)
	photo_button = _button("Snap photo", photo_pressed)
	photo_button.focus_mode = Control.FOCUS_NONE  # controller uses the finish_job action (Y)
	photo_button.position = Vector2(0, 220)
	photo_button.size = Vector2(192, 64)
	side.add_child(photo_button)
	side.hide()


func _build_intro() -> void:
	intro = PanelContainer.new()
	intro.add_theme_stylebox_override("panel", _panel_style(0.95))
	intro.position = Vector2(290, 200)
	intro.custom_minimum_size = Vector2(700, 0)
	root.add_child(intro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	intro.add_child(v)
	_intro_client = _label(28, ACCENT)
	v.add_child(_intro_client)
	_intro_note = _label(28, INK)
	_intro_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_note.custom_minimum_size = Vector2(640, 0)
	v.add_child(_intro_note)
	_intro_contents = _label(MIN_FONT, DIM)
	_intro_contents.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_contents.custom_minimum_size = Vector2(640, 0)
	v.add_child(_intro_contents)
	intro_button = _button("Tip it out!", start_pressed)
	v.add_child(intro_button)
	intro.hide()


func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(PANEL_X, 112)
	panel.custom_minimum_size = Vector2(440, 650)
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	stamp_label = _label(44, ACCENT)
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_label.custom_minimum_size = Vector2(384, 56)
	v.add_child(stamp_label)
	percent_label = _label(96, INK, "0%")
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(percent_label)
	reasons_box = VBoxContainer.new()
	reasons_box.add_theme_constant_override("separation", 6)
	v.add_child(reasons_box)
	pay_label = _label(28, ACCENT)
	pay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pay_label)
	buttons_box = VBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 10)
	v.add_child(buttons_box)
	panel.hide()


func _build_pack_bar() -> void:
	pack_bar = PanelContainer.new()
	pack_bar.add_theme_stylebox_override("panel", _panel_style(0.9))
	pack_bar.position = Vector2(32, 700)
	pack_bar.custom_minimum_size = Vector2(1216, 0)
	root.add_child(pack_bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	pack_bar.add_child(h)
	pack_status = _label(MIN_FONT, INK)
	pack_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pack_status)
	pack_rest_button = _button("Pack the rest for me", pack_rest_pressed)
	pack_rest_button.focus_mode = Control.FOCUS_NONE  # controller: the finish_job action (Y)
	pack_rest_button.custom_minimum_size = Vector2(380, 56)
	h.add_child(pack_rest_button)
	# Compact: shrink the panel margins so the bar stays inside the bottom 100 px.
	var st: StyleBoxFlat = pack_bar.get_theme_stylebox("panel")
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	pack_bar.hide()


func _build_tip() -> void:
	tip_panel = PanelContainer.new()
	var st := _panel_style(0.94)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 4
	st.content_margin_bottom = 6
	st.shadow_size = 6
	tip_panel.add_theme_stylebox_override("panel", st)
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_label = _label(MIN_FONT, INK)
	tip_panel.add_child(tip_label)
	root.add_child(tip_panel)
	tip_panel.hide()


## Item name above an item (screen position of the item's top centre). Empty text hides it.
func show_item_tip(text: String, screen_top: Vector2) -> void:
	if text.is_empty():
		tip_panel.hide()
		return
	if tip_label.text != text:
		tip_label.text = text
		tip_panel.reset_size()
	var sz := tip_panel.get_combined_minimum_size()
	var p := screen_top - Vector2(sz.x * 0.5, sz.y + 8)
	var vp := root.get_viewport_rect().size if root.is_inside_tree() else Vector2(1280, 800)
	p.x = clampf(p.x, 8, vp.x - sz.x - 8)
	p.y = clampf(p.y, 104, vp.y - sz.y - 8)
	tip_panel.position = p
	tip_panel.show()


func hide_item_tip() -> void:
	tip_panel.hide()


func _make_confetti() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(420, 330)
	p.emitting = false
	p.one_shot = true
	p.amount = 160
	p.lifetime = 2.4
	p.explosiveness = 0.92
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.initial_velocity_min = 380.0
	p.initial_velocity_max = 820.0
	p.gravity = Vector2(0, 900)
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 10.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	g.colors = PackedColorArray([Catalog.colour("red"), Catalog.colour("orange"), Catalog.colour("yellow"),
		Catalog.colour("green"), Catalog.colour("blue"), Catalog.colour("pink")])
	p.color_initial_ramp = g
	return p


# --- phases -------------------------------------------------------------------

func set_job_title(text: String) -> void:
	title_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func show_intro(job: Dictionary, item_count: int) -> void:
	panel.hide()
	side.hide()
	_intro_client.text = "%s  -  %s" % [job.get("client", ""), job.get("title", "")]
	_intro_note.text = "\"%s\"" % job.get("note", "")
	_intro_contents.text = "%s - %d items inside - pays $%d" % [job.get("container", {}).get("name", ""), item_count, int(job.get("pay", 0))]
	intro.show()
	intro.modulate.a = 0.0
	intro.position.y = 230
	var t := create_tween().set_parallel()
	t.tween_property(intro, "modulate:a", 1.0, 0.25)
	t.tween_property(intro, "position:y", 200.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_button.grab_focus()


func hide_intro() -> void:
	intro.hide()


func show_sorting() -> void:
	intro.hide()
	panel.hide()
	side.show()
	side.modulate.a = 0.0
	create_tween().tween_property(side, "modulate:a", 1.0, 0.3)


func hide_side() -> void:
	side.hide()


func set_live_score(total: int, loose: int) -> void:
	loose_label.text = ("%d still loose" % loose) if loose > 0 else "All on the grid"
	var t := create_tween().set_parallel()
	t.tween_method(_set_meter, _meter_value, float(total), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# A little pop when the score goes up.
	if total > roundi(_meter_value):
		meter_label.pivot_offset = Vector2(0, 32)
		meter_label.scale = Vector2(1.18, 1.18)
		t.tween_property(meter_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_meter(v: float) -> void:
	_meter_value = v
	meter_label.text = "%d%%" % roundi(v)
	meter_fill.size.x = 192.0 * clampf(v / 100.0, 0.0, 1.0)


func flash() -> void:
	flash_rect.color.a = 0.9
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)


static func rating(total: int) -> String:
	if total >= 90:
		return "IMMACULATE"
	if total >= 75:
		return "NEAT!"
	if total >= 55:
		return "TIDY-ISH"
	if total >= 35:
		return "STILL MESSY"
	return "CHAOS"


## The score reveal. Awaitable; the Pack button appears (and takes focus) at the end.
func reveal(result: Dictionary, pay: int) -> void:
	side.hide()
	for c in reasons_box.get_children():
		c.queue_free()
	for c in buttons_box.get_children():
		c.queue_free()
	var total: int = result.get("total", 0)
	stamp_label.text = ""
	percent_label.text = "0%"
	pay_label.text = ""
	panel.show()
	panel.position.x = 1300.0
	var slide := create_tween()
	slide.tween_property(panel, "position:x", PANEL_X, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await slide.finished
	# Count up, ticking as it goes.
	var count := create_tween()
	count.tween_method(_set_percent, 0.0, float(total), 0.4 + total / 100.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await count.finished
	# Stamp slams down.
	stamp_label.text = rating(total)
	stamp_label.pivot_offset = stamp_label.size * 0.5
	stamp_label.scale = Vector2(2.6, 2.6)
	stamp_label.rotation = -0.25
	stamp_label.modulate.a = 0.0
	var stamp := create_tween().set_parallel()
	stamp.tween_property(stamp_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stamp.tween_property(stamp_label, "rotation", -0.06, 0.22)
	stamp.tween_property(stamp_label, "modulate:a", 1.0, 0.1)
	Audio.play_sfx(Sfx.get_stream("stamp"), 0.0, 0.02)
	if total >= 60:
		confetti.amount = 60 + total
		confetti.restart()
		Audio.play_sfx(Sfx.get_stream("chime"), -4.0, 0.0)
	await stamp.finished
	# One line per reason, so every point is explained.
	var i := 0
	for r in result.get("reasons", []):
		var row := HBoxContainer.new()
		var text := _label(MIN_FONT, INK, String(r["text"]))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		var pts := _label(MIN_FONT, ACCENT if int(r["points"]) >= int(r["max"]) * 0.75 else DIM, "+%d" % int(r["points"]))
		row.add_child(pts)
		reasons_box.add_child(row)
		row.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(row, "modulate:a", 1.0, 0.15)
		Audio.play_sfx(Sfx.get_stream("tick"), -6.0, 0.0, 1.0 + i * 0.12)
		i += 1
		await t.finished
	pay_label.text = "Pay: $%d" % pay
	var pack := _button("Pack it back", pack_pressed)
	buttons_box.add_child(pack)
	pack.grab_focus()


func _set_percent(v: float) -> void:
	var before := percent_label.text
	percent_label.text = "%d%%" % roundi(v)
	if before != percent_label.text and roundi(v) % 4 == 0:
		Audio.play_sfx(Sfx.get_stream("tick"), -10.0, 0.02, 0.8 + v / 100.0)


func show_packing(container_name: String) -> void:
	panel.hide()
	side.hide()
	pack_bar.show()
	pack_bar.modulate.a = 0.0
	create_tween().tween_property(pack_bar, "modulate:a", 1.0, 0.25)
	set_job_title("Pack everything back into the %s" % container_name.to_lower())


func set_pack_status(packed: int, total: int, seconds: float) -> void:
	pack_status.text = "%d of %d packed     %s" % [packed, total, clock(seconds)]


static func clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


## Payday card. `pack_seconds` < 0 = packed automatically. `unlocked` = title of a job this
## unlocked (empty for none).
func show_payday(pay: int, earned_total: int, has_next: bool, pack_seconds := -1.0, unlocked := "") -> void:
	pack_bar.hide()
	hide_item_tip()
	panel.show()
	panel.position.x = PANEL_X
	for c in buttons_box.get_children():
		c.queue_free()
	for c in reasons_box.get_children():  # already read at the reveal; make room for payday
		c.queue_free()
	var lines := "Packed and returned!" if pack_seconds < 0.0 else "Packed in %s!" % clock(pack_seconds)
	lines += "\n+$%d   (total $%d)" % [pay, earned_total]
	if not unlocked.is_empty():
		lines += "\nNew job unlocked: %s" % unlocked
	pay_label.text = lines
	pay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pay_label.custom_minimum_size = Vector2(384, 0)
	var first: Button
	if has_next:
		first = _button("Next job", next_pressed)
		buttons_box.add_child(first)
	var again := _button("Try this job again", retry_pressed)
	buttons_box.add_child(again)
	buttons_box.add_child(_button("Job list", title_pressed))
	(first if first else again).grab_focus()
