extends Control
## Job select / progression: one row per job in jobs.json with its best score and stars.
## Locked jobs (previous job not yet packed and returned) are greyed out and can't be chosen.
## Mouse, keyboard and controller (focus starts on the suggested job). Back / B returns to title.

const GAME_SCENE := "res://scenes/game.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const INK := Color("f4f1ea")
const DIM := Color(0.96, 0.94, 0.9, 0.6)
const ACCENT := Color("f2cf4a")

var progress: Dictionary = {}
var rows: Array[Button] = []
var back_button: Button
var money_label: Label

var _list: VBoxContainer


func _ready() -> void:
	progress = Progress.load_progress()
	_build()
	Sfx.play_music("menu")
	var pick := Progress.suggested_job(progress)
	if pick < rows.size():
		rows[pick].grab_focus()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 120)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	margin.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("Today's jobs", 48, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	money_label = _label("Earned: $%d" % int(progress.get("money", 0)), 32, ACCENT)
	head.add_child(money_label)
	v.add_child(_label("%d of %d jobs unlocked" % [Progress.unlocked_count(progress), Catalog.job_count()], 28, DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_list)
	for i in Catalog.job_count():
		var row := _make_row(i)
		_list.add_child(row)
		rows.append(row)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(240, 60)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(_on_back)
	v.add_child(back_button)
	# Vertical focus wraps between the last job and Back.
	if not rows.is_empty():
		var last_open := rows[Progress.unlocked_count(progress) - 1]
		last_open.focus_neighbor_bottom = last_open.get_path_to(back_button)
		back_button.focus_neighbor_top = back_button.get_path_to(last_open)


func _make_row(i: int) -> Button:
	var job := Catalog.job(i)
	var unlocked := Progress.is_unlocked(progress, i)
	var b := Button.new()
	b.name = "Job%d" % (i + 1)
	b.custom_minimum_size = Vector2(0, 92)
	b.disabled = not unlocked
	b.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
	b.pressed.connect(choose.bind(i))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 24
	h.offset_right = -24
	h.add_theme_constant_override("separation", 24)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var num := _label("%d" % (i + 1), 40, ACCENT if unlocked else DIM)
	num.custom_minimum_size = Vector2(48, 0)
	h.add_child(num)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(names)
	names.add_child(_label(String(job.get("title", "")), 32, INK if unlocked else DIM))
	var sub := "%s  -  %d items  -  pays $%d" % [job.get("client", ""), job.get("items", []).size(), int(job.get("pay", 0))]
	if not unlocked:
		sub = "Locked: finish \"%s\" first" % Catalog.job(i - 1).get("title", "")
	names.add_child(_label(sub, 28, DIM))
	var played: bool = progress.get("best", {}).has(Progress.job_id(i))
	var best := _label("Best %d%%" % Progress.best(progress, i) if played else ("New" if unlocked else ""), 28, INK if played else ACCENT)
	best.custom_minimum_size = Vector2(150, 0)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(best)
	var stars := StarRow.new()
	stars.name = "Stars"
	stars.count = Progress.stars(progress, i)
	stars.custom_minimum_size = Vector2(132, 40)
	stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(stars)
	if Progress.is_completed(progress, i):
		b.tooltip_text = "Completed"
	return b


func _label(text: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Start a job (ignored if it is locked).
func choose(index: int) -> bool:
	if not Progress.is_unlocked(progress, index):
		return false
	Audio.play_sfx(Sfx.get_stream("ui_select"), -6.0, 0.02)
	Progress.pending_job = index
	SceneChanger.change_to(GAME_SCENE)
	return true


func _on_back() -> void:
	SceneChanger.change_to(TITLE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


## Three stars drawn as polygons (the default font has no star glyph).
class StarRow extends Control:
	var count := 0:
		set(v):
			count = v
			queue_redraw()

	func _draw() -> void:
		var r := minf(size.y * 0.5, size.x / 6.0) - 1.0
		for k in 3:
			var c := Vector2(r + k * (r * 2.0 + 4.0) + 1.0, size.y * 0.5)
			var pts := PackedVector2Array()
			for p in 10:
				var rad := r if p % 2 == 0 else r * 0.45
				pts.append(c + Vector2.from_angle(-PI / 2.0 + p * PI / 5.0) * rad)
			if k < count:
				draw_colored_polygon(pts, Color("f2cf4a"))
			else:
				pts.append(pts[0])
				draw_polyline(pts, Color(1, 1, 1, 0.35), 2.0, true)
