extends GutTest
## Deck readability rule (BRIEF.md): every on-screen text >= 28 px at 1280x800, and controller
## focus is visible. Static scan of scenes/scripts plus a runtime walk of every screen and phase.

const MIN := 28
const Game := preload("res://scripts/game.gd")
const DIRS := ["res://scenes", "res://ui", "res://scripts", "res://autoload"]

var _orig_save_dir: String


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	SaveGame.directory = "user://test_read_saves"


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir
	get_tree().paused = false


func _files(ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	for d in DIRS:
		if not DirAccess.dir_exists_absolute(d):
			continue
		for f in DirAccess.get_files_at(d):
			if f.ends_with(ext):
				out.append("%s/%s" % [d, f])
	return out


func test_theme_default_font_and_focus() -> void:
	var theme: Theme = load(ProjectSettings.get_setting("gui/theme/custom"))
	assert_gte(theme.default_font_size, MIN, "theme default font size")
	for type in ["Button", "CheckButton", "HSlider"]:
		var sb := theme.get_stylebox("focus", type) as StyleBoxFlat
		assert_not_null(sb, "%s has a focus style" % type)
		if sb:
			assert_gte(sb.border_width_left, 3, "%s focus border is visible" % type)
			assert_gt(sb.border_color.a, 0.8)


func test_no_small_font_sizes_in_files() -> void:
	var rx := RegEx.create_from_string("font_size\\s*=\\s*(\\d+)")
	for f in _files(".tscn"):
		for m in rx.search_all(FileAccess.get_file_as_string(f)):
			assert_gte(int(m.get_string(1)), MIN, "%s: font_size %s" % [f, m.get_string(1)])
	# Literal sizes in code: _label(N, ...), _label("text", N, ...), font_size", N), draw_string(..., N, colour)
	var code_rx := [
		RegEx.create_from_string("_label\\((\\d+)\\s*,"),
		RegEx.create_from_string("_label\\(\"[^\"]*\"\\s*,\\s*(\\d+)"),
		RegEx.create_from_string("\"font_size\"\\s*,\\s*(\\d+)\\)"),
		RegEx.create_from_string("draw_string\\(.*,\\s*(\\d+)\\s*,\\s*[A-Za-z(]"),
	]
	for f in _files(".gd"):
		var text := FileAccess.get_file_as_string(f)
		for r in code_rx:
			for m in r.search_all(text):
				assert_gte(int(m.get_string(1)), MIN, "%s: literal font size %s" % [f, m.get_string(1)])


func test_world_items_draw_no_text() -> void:
	# Text drawn in world space shrinks with the camera zoom; names go through the HUD tooltip.
	for f in ["res://scripts/desk_item.gd", "res://scripts/container_box.gd", "res://scripts/desk.gd"]:
		assert_false(FileAccess.get_file_as_string(f).contains("draw_string"), "%s draws no text" % f)


func test_hints_fit_the_screen() -> void:
	var font := ThemeDB.fallback_font
	for h in Game.HINTS:
		assert_lte(font.get_string_size(h, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN).x, 1216.0, "hint fits: %s" % h)


func _check_tree(root: Node, where: String) -> int:
	var n := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Control and node.is_visible_in_tree() and (node is Label or node is Button):
			var text: String = node.text
			if text.strip_edges().is_empty():
				continue
			var fs: int = node.get_theme_font_size(&"font_size")
			assert_gte(fs, MIN, "%s: '%s' is %d px" % [where, text.left(30), fs])
			n += 1
	return n


func test_every_screen_text_is_large_enough() -> void:
	var title: Control = load("res://scenes/title.tscn").instantiate()
	add_child_autofree(title)
	assert_gt(_check_tree(title, "title"), 3)
	title.get_node("%SettingsMenu").open()
	assert_gt(_check_tree(title, "settings"), 10)
	var jobs: Control = load("res://scenes/job_select.tscn").instantiate()
	add_child_autofree(jobs)
	assert_gt(_check_tree(jobs, "job select"), 5)
	var g: Node = load("res://scenes/game.tscn").instantiate()
	g.rng_seed = 3
	g.start_job_index = 0
	add_child_autofree(g)
	await wait_seconds(0.4)
	assert_gt(_check_tree(g, "intro"), 3)
	g.settle_now()
	g._set_pad_mode(true)   # headless has no real mouse to hover with
	g._cursor = g.items[0].position
	g._set_hover(g.items[0])
	await wait_frames(3)
	assert_true(g.hud.tip_panel.visible, "item name shown on hover")
	assert_eq(g.hud.tip_label.text, g.items[0].display_name())
	assert_gt(_check_tree(g, "sorting"), 3)
	g.auto_arrange(true)
	g.take_photo()
	await wait_seconds(4.0)
	assert_gt(_check_tree(g, "reveal"), 5)
	g.start_packing(false)
	await wait_seconds(0.6)
	assert_gt(_check_tree(g, "packing"), 1)
	g.pack_rest()
	await wait_seconds(2.5)
	assert_eq(g.phase, Game.Phase.DONE)
	assert_gt(_check_tree(g, "payday"), 3)
	g.get_node("PauseMenu").pause()
	assert_gt(_check_tree(g, "pause"), 2)
	g.get_node("PauseMenu").resume()
