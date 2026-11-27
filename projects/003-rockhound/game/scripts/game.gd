extends Node2D
## Rockhound greybox: dig the rock face -> geodes drop to the tray -> crack one on the anvil ->
## reveal a crystal -> (polish) -> sell -> buy upgrades. Everything is drawn in code (no art).
## Rules and numbers: scripts/economy.gd + data/balance.json. Sounds: scripts/sfx.gd.

const Economy := preload("res://scripts/economy.gd")
const Fmt := preload("res://scripts/fmt.gd")
const Sfx := preload("res://scripts/sfx.gd")

enum Station { ROCK, ANVIL }
enum Anvil { EMPTY, GEODE, REVEALED, POLISHING, DONE }

const ROCK_RECT := Rect2(30, 130, 420, 470)
const ANVIL_POS := Vector2(705, 440)
const GEODE_R := 82.0
const TRAY_Y := 668.0
const TRAY_X0 := 70.0
const TRAY_DX := 84.0
const GRID_COLS := 3
const GRID_ROWS := 4
const DIG_INTERVAL := 0.12
const STRIKE_INTERVAL := 0.13
const HOLD_TO_POLISH := 0.18
const MIN_REVEAL_SHOW := 0.35
const AUTOSAVE_SECONDS := 10.0
const SAVE_SLOT := 0

var eco: Economy
var station := Station.ROCK

# rock face
var chunks: Array = []        # {poly, center, hp, max_hp, color, broken, cracks, flash}
var falling: Array = []       # {poly, pos, vel, rot, spin, life, color}
var flying: Array = []        # geodes in the air: {from, to, t, dur, hint, seed, landed}
var face_hue := 0.07
var _target_chunk := -1

# anvil
var anvil_state := Anvil.EMPTY
var anvil_geode: Dictionary = {}
var anvil_seed := 0
var strikes := 0
var crack_paths: Array = []   # Array[PackedVector2Array] relative to geode centre
var wobble := 0.0
var wobble_v := 0.0
var hammer_t := 1.0           # 0 = just struck, 1 = rest
var revealed: Dictionary = {}
var reveal_t := 0.0           # real seconds since reveal
var prisms: Array = []        # {angle, len, width, color, tip}
var crystal_scale := 0.0
var polish_fill := 0.0
var polish_mult := 1.0
var shell_halves_t := 0.0
var _press_time := -1.0
var _need_release := false

# input
var _mouse_hold := false
var _mouse_station := Station.ROCK
var _pad_hold := false
var _dig_cd := 0.0
var _strike_cd := 0.0
var _auto_acc := 0.0
var _using_pad := false

# feel
var trauma := 0.0
var shown_money := 0.0
var _autosave := 0.0
var _slowmo_active := false
var _autoplay := false
var _time := 0.0

# nodes
var camera: Camera2D
var glow: Node2D        # additive, in front of the world
var back_glow: Node2D   # additive, behind the crystal
var hud: CanvasLayer
var money_label: Label
var sub_label: Label
var goal_label: Label
var goal_bar: ProgressBar
var hint_label: Label
var banner: Label
var banner_sub: Label
var flash: ColorRect
var book_button: Button
var shop_buttons: Dictionary = {}
var book: Control
var _glow_tex: GradientTexture2D


func _ready() -> void:
	eco = Economy.new()
	var saved := SaveGame.load_slot(SAVE_SLOT)
	if saved.get("eco") is Dictionary:
		eco.from_dict(saved["eco"])
	shown_money = eco.money
	_build_nodes()
	_new_face(false)
	for i in mini(eco.chunks_broken, chunks.size()):
		chunks[i]["broken"] = true
	_try_load_anvil()
	_refresh_hud()
	_autoplay = OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay")
	if _autoplay:
		_run_autoplay()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	save_now()


func save_now() -> void:
	# The geode on the anvil goes back to the front of the tray so it is never lost.
	var d := eco.to_dict()
	if anvil_state == Anvil.GEODE and not anvil_geode.is_empty():
		d["tray"].push_front(anvil_geode.duplicate())
	SaveGame.save_slot(SAVE_SLOT, {"eco": d})


# --- node setup -----------------------------------------------------------------------

func _build_nodes() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(640, 400)
	add_child(camera)
	camera.make_current()

	_glow_tex = GradientTexture2D.new()
	_glow_tex.fill = GradientTexture2D.FILL_RADIAL
	_glow_tex.fill_from = Vector2(0.5, 0.5)
	_glow_tex.fill_to = Vector2(1.0, 0.5)
	_glow_tex.width = 128
	_glow_tex.height = 128
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	_glow_tex.gradient = g

	var bg_node := Node2D.new()
	bg_node.z_index = -10
	bg_node.draw.connect(func():
		bg_node.draw_polygon(PackedVector2Array([Vector2(-200, -200), Vector2(1480, -200), Vector2(1480, 1000), Vector2(-200, 1000)]),
			PackedColorArray([Color(0.09, 0.08, 0.1), Color(0.09, 0.08, 0.1), Color(0.16, 0.13, 0.12), Color(0.16, 0.13, 0.12)])))
	add_child(bg_node)
	glow = Node2D.new()
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add_mat
	glow.z_index = 5
	glow.draw.connect(_draw_glow)
	add_child(glow)
	back_glow = Node2D.new()
	back_glow.material = add_mat
	back_glow.z_index = -5
	back_glow.draw.connect(_draw_back_glow)
	add_child(back_glow)

	hud = CanvasLayer.new()
	hud.layer = 2
	add_child(hud)

	money_label = _label(Vector2(24, 6), 52, HORIZONTAL_ALIGNMENT_LEFT, Vector2(360, 66))
	money_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	money_label.add_theme_constant_override("outline_size", 6)
	money_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.0))
	sub_label = _label(Vector2(26, 70), 28, HORIZONTAL_ALIGNMENT_LEFT, Vector2(440, 40))
	sub_label.modulate = Color(0.8, 0.85, 0.9)

	goal_label = _label(Vector2(470, 8), 28, HORIZONTAL_ALIGNMENT_CENTER, Vector2(480, 40))
	goal_bar = ProgressBar.new()
	goal_bar.position = Vector2(500, 52)
	goal_bar.size = Vector2(420, 22)
	goal_bar.show_percentage = false
	goal_bar.max_value = 1.0
	goal_bar.step = 0.0
	goal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.15)
	bg.set_corner_radius_all(11)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(1.0, 0.78, 0.3)
	fg.set_corner_radius_all(11)
	goal_bar.add_theme_stylebox_override("background", bg)
	goal_bar.add_theme_stylebox_override("fill", fg)
	hud.add_child(goal_bar)

	book_button = Button.new()
	book_button.position = Vector2(978, 14)
	book_button.size = Vector2(290, 72)
	book_button.focus_mode = Control.FOCUS_NONE
	book_button.pressed.connect(toggle_book)
	hud.add_child(book_button)

	var y := 104.0
	for u in eco.upgrades:
		var b := Button.new()
		b.position = Vector2(978, y)
		b.size = Vector2(290, 128)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.pressed.connect(_on_shop_pressed.bind(u["id"], b))
		hud.add_child(b)
		shop_buttons[u["id"]] = b
		y += 136.0
	var ids: Array = shop_buttons.keys()
	for i in ids.size():
		var b: Button = shop_buttons[ids[i]]
		b.focus_neighbor_top = b.get_path_to(shop_buttons[ids[maxi(i - 1, 0)]])
		b.focus_neighbor_bottom = b.get_path_to(shop_buttons[ids[mini(i + 1, ids.size() - 1)]])
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)

	hint_label = _label(Vector2(20, 744), 28, HORIZONTAL_ALIGNMENT_CENTER, Vector2(940, 44))
	hint_label.modulate = Color(0.75, 0.78, 0.85)

	banner = _label(Vector2(465, 112), 44, HORIZONTAL_ALIGNMENT_CENTER, Vector2(490, 64))
	banner.add_theme_constant_override("outline_size", 10)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	banner.pivot_offset = Vector2(245, 32)
	banner.modulate.a = 0.0
	banner_sub = _label(Vector2(465, 172), 32, HORIZONTAL_ALIGNMENT_CENTER, Vector2(490, 90))
	banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_sub.add_theme_constant_override("outline_size", 8)
	banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	banner_sub.modulate.a = 0.0

	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)

	_build_book()


func _label(pos: Vector2, font_size: int, align: HorizontalAlignment, sz: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(l)
	return l


# --- rock face ---------------------------------------------------------------------------

func _new_face(animate: bool) -> void:
	chunks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + eco.depth * 77
	face_hue = fposmod(0.07 + eco.depth * 0.13, 1.0)
	var cw := ROCK_RECT.size.x / GRID_COLS
	var ch := ROCK_RECT.size.y / GRID_ROWS
	var pts := []
	for r in GRID_ROWS + 1:
		var row := []
		for c in GRID_COLS + 1:
			var p := ROCK_RECT.position + Vector2(c * cw, r * ch)
			if c > 0 and c < GRID_COLS:
				p.x += rng.randf_range(-cw * 0.25, cw * 0.25)
			if r > 0 and r < GRID_ROWS:
				p.y += rng.randf_range(-ch * 0.25, ch * 0.25)
			row.append(p)
		pts.append(row)
	var hp := eco.chunk_hp()
	# Bottom rows first so the face is dug "into" from the floor up.
	for r in range(GRID_ROWS - 1, -1, -1):
		for c in GRID_COLS:
			var poly := PackedVector2Array([pts[r][c], pts[r][c + 1], pts[r + 1][c + 1], pts[r + 1][c]])
			# Bevel the corners a bit so chunks read as stones, not tiles.
			var centre := (poly[0] + poly[1] + poly[2] + poly[3]) / 4.0
			var bev := PackedVector2Array()
			for i in 4:
				var a: Vector2 = poly[i]
				var b: Vector2 = poly[(i + 1) % 4]
				bev.append(a.lerp(b, 0.12).lerp(centre, 0.05))
				bev.append(a.lerp(b, 0.88).lerp(centre, 0.05))
			var cracks := []
			for k in 5:
				var path := PackedVector2Array([centre])
				var dir := Vector2.RIGHT.rotated(rng.randf() * TAU)
				var p: Vector2 = centre
				for s in 4:
					dir = dir.rotated(rng.randf_range(-0.7, 0.7))
					p += dir * rng.randf_range(10, 22)
					path.append(p)
				cracks.append(path)
			var shade := rng.randf_range(-0.06, 0.06)
			chunks.append({
				"poly": bev, "center": centre, "hp": hp, "max_hp": hp, "broken": false,
				"color": Color.from_hsv(face_hue, 0.22, 0.46 + shade), "cracks": cracks, "flash": 0.0,
			})
	_target_chunk = 0
	if animate:
		for c in chunks:
			c["flash"] = 1.0


func _chunk_at(pos: Vector2) -> int:
	for i in chunks.size():
		if not chunks[i]["broken"] and Geometry2D.is_point_in_polygon(pos, chunks[i]["poly"]):
			return i
	return -1


func _default_chunk() -> int:
	if _target_chunk >= 0 and _target_chunk < chunks.size() and not chunks[_target_chunk]["broken"]:
		return _target_chunk
	for i in chunks.size():
		if not chunks[i]["broken"]:
			return i
	return -1


## One pick hit at `pos` (world). Auto-digger hits are quieter and don't shake.
func dig_hit(pos: Vector2 = Vector2.INF, auto := false) -> void:
	var idx := -1
	if pos != Vector2.INF:
		idx = _chunk_at(pos)
	if idx < 0:
		idx = _default_chunk()
	if idx < 0:
		return
	if not auto:
		_target_chunk = idx
	var c: Dictionary = chunks[idx]
	var hit_pos: Vector2 = pos if (pos != Vector2.INF and idx == _chunk_at(pos)) else c["center"] + Vector2(randf_range(-30, 30), randf_range(-25, 25))
	c["hp"] = int(c["hp"]) - eco.dig_power()
	c["flash"] = 0.6
	var dmg := 1.0 - clampf(float(c["hp"]) / float(c["max_hp"]), 0.0, 1.0)
	_burst(hit_pos, c["color"].lightened(0.15), 8 if auto else 14, 260.0, 7.0, 0.5, 900.0)
	Audio.play_sfx(Sfx.get_stream("chip"), -8.0 if auto else -2.0, 0.08, 0.85 + 0.5 * dmg)
	if not auto:
		add_trauma(0.18)
	if int(c["hp"]) <= 0:
		_break_chunk(idx)


func _break_chunk(idx: int) -> void:
	var c: Dictionary = chunks[idx]
	c["broken"] = true
	var centre: Vector2 = c["center"]
	var local := PackedVector2Array()
	for p in c["poly"]:
		local.append(p - centre)
	falling.append({"poly": local, "pos": centre, "vel": Vector2(randf_range(-120, 120), -220),
		"rot": 0.0, "spin": randf_range(-4, 4), "life": 1.2, "color": c["color"]})
	_burst(centre, c["color"], 30, 420.0, 10.0, 0.8, 1100.0)
	_burst(centre, Color(0.75, 0.7, 0.62, 0.6), 18, 120.0, 22.0, 0.9, -60.0)  # dust
	Audio.play_sfx(Sfx.get_stream("break"), 0.0, 0.1)
	add_trauma(0.4)
	var res := eco.break_chunk()
	var dropped: Array = res["geodes"]
	var tray_count_before: int = eco.tray.size() - dropped.size()
	for i in dropped.size():
		var g: Dictionary = dropped[i]
		var slot := clampi(tray_count_before + i, 0, eco.tray_size() - 1)
		flying.append({"from": centre, "to": _tray_pos(slot), "t": -0.08 * i, "dur": 0.55,
			"hint": int(g["hint"]), "seed": randi(), "landed": false})
	if res["bulk_sold"] > 0.0:
		_popup("+%s  tray full: sold a plain geode" % Fmt.money(res["bulk_sold"]), _tray_pos(0) + Vector2(160, -50), Color(0.9, 0.85, 0.7), 28)
	if res["new_depth"]:
		_on_new_depth()
	_try_load_anvil()
	_refresh_hud()


func _on_new_depth() -> void:
	add_trauma(0.9)
	Audio.play_sfx(Sfx.get_stream("rumble"), 0.0, 0.0)
	for c in chunks:
		c["broken"] = true
	_new_face(true)
	_show_banner("DEPTH %d" % eco.depth, "Crystals now worth x%s" % _mult_str(eco.depth_mult()), Color(1.0, 0.85, 0.5), 2.2)


func _tray_pos(slot: int) -> Vector2:
	return Vector2(TRAY_X0 + slot * TRAY_DX, TRAY_Y)


# --- anvil ------------------------------------------------------------------------------

func _try_load_anvil() -> void:
	if anvil_state != Anvil.EMPTY or eco.tray.is_empty():
		return
	anvil_geode = eco.take_from_tray()
	anvil_seed = randi()
	anvil_state = Anvil.GEODE
	strikes = 0
	wobble = 0.0
	wobble_v = 0.0
	crack_paths.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = anvil_seed
	var n := eco.strikes_needed(int(anvil_geode["tier"])) + 2
	for k in n:
		var a := rng.randf() * TAU
		var start := Vector2.RIGHT.rotated(a) * rng.randf_range(0.0, GEODE_R * 0.3)
		var path := PackedVector2Array([start])
		var dir := Vector2.RIGHT.rotated(a)
		var p := start
		for s in 6:
			dir = dir.rotated(rng.randf_range(-0.6, 0.6))
			p += dir * rng.randf_range(12, 22)
			if p.length() > GEODE_R * 1.02:
				break
			path.append(p)
		crack_paths.append(path)
	# Slide in from the tray.
	geode_slide = 0.0
	create_tween().tween_property(self, "geode_slide", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


var geode_slide := 1.0


func crack_progress() -> float:
	if anvil_state != Anvil.GEODE:
		return 0.0
	return float(strikes) / float(eco.strikes_needed(int(anvil_geode["tier"])))


## One hammer strike on the geode on the anvil.
func strike() -> void:
	if anvil_state != Anvil.GEODE:
		return
	strikes += 1
	var p := crack_progress()
	var tier := int(anvil_geode["tier"])
	hammer_t = 0.0
	wobble_v += (randf_range(0.5, 1.0) * (1 if randf() < 0.5 else -1)) * (6.0 + 10.0 * p)
	add_trauma(0.12 + 0.25 * p)
	Audio.play_sfx(Sfx.get_stream("strike"), -2.0, 0.03, 0.75 + 1.1 * p)
	if tier >= Economy.RARE and p >= 0.5:
		Audio.play_sfx(Sfx.get_stream("new"), -14.0 + 6.0 * p, 0.05, 0.8 + p)
	_burst(ANVIL_POS + Vector2(randf_range(-40, 40), -GEODE_R * 0.7), _shell_color(int(anvil_geode["hint"])).lightened(0.2), 10, 300.0, 6.0, 0.45, 900.0)
	if strikes >= eco.strikes_needed(tier):
		_reveal()


func _reveal() -> void:
	revealed = eco.crack(anvil_geode)
	var tier := int(revealed["tier"])
	anvil_state = Anvil.REVEALED
	reveal_t = 0.0
	shell_halves_t = 0.0
	polish_fill = 0.0
	polish_mult = 1.0
	_need_release = true
	_press_time = -1.0
	_make_prisms(tier)
	crystal_scale = 0.0
	var tw := create_tween()
	tw.set_ignore_time_scale(tier >= Economy.RARE)
	tw.tween_property(self, "crystal_scale", 1.0, 0.5 + 0.12 * tier).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tc := tier_color(tier)
	Audio.play_sfx(Sfx.get_stream("pop"), 0.0, 0.05)
	Audio.play_sfx(Sfx.get_stream("reveal_%d" % tier), -2.0 if tier >= 2 else -6.0, 0.0)
	add_trauma(0.35 + 0.15 * tier)
	_burst(ANVIL_POS, Color(revealed["color"]), 25 + 25 * tier, 380.0 + 80.0 * tier, 8.0, 0.9 + 0.2 * tier, 500.0, true)
	_burst(ANVIL_POS, _shell_color(int(anvil_geode["hint"])), 26, 420.0, 12.0, 0.8, 1300.0)
	_flash(tc.lightened(0.4), 0.15 + 0.12 * tier)
	var stars := "★".repeat(int(eco.tiers[tier]["stars"]))
	var title := "%s  %s" % [stars, String(eco.tiers[tier]["name"]).to_upper()]
	var sub := "%s  %s" % [revealed["name"], Fmt.money(revealed["value"])]
	if revealed["is_new"]:
		sub = "NEW!  " + sub
		Audio.play_sfx(Sfx.get_stream("new"), -6.0, 0.0)
	_show_banner(title, sub, tc.lightened(0.25), 1.6 + 0.5 * tier)
	for set_id in revealed["sets_completed"]:
		var s := _set_def(set_id)
		_popup("SET COMPLETE: %s  +%d%% value" % [s["name"], roundi(float(s["bonus"]) * 100)], Vector2(470, 300), Color(1, 0.9, 0.5), 32, 2.5)
	if tier >= Economy.RARE:
		_slowmo(0.12 if tier >= 4 else (0.2 if tier == 3 else 0.35), 0.35 + 0.3 * (tier - 2))
	_refresh_hud()


func _make_prisms(tier: int) -> void:
	prisms.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(revealed["id"]) + randi() % 1000
	var base := Color(revealed["color"])
	var n := 4 + tier * 2
	for i in n:
		var t := (float(i) / maxf(1.0, n - 1)) - 0.5
		var col := base
		if revealed["id"] == "star_opal":
			col = Color.from_hsv(fposmod(0.5 + t * 1.6, 1.0), 0.45, 1.0)
		prisms.append({
			"angle": t * 1.9 + rng.randf_range(-0.12, 0.12),
			"len": rng.randf_range(55, 95) * (1.0 + 0.13 * tier) * (1.0 - absf(t) * 0.6),
			"width": rng.randf_range(16, 26) * (1.0 + 0.05 * tier),
			"color": col.darkened(rng.randf_range(0.0, 0.25)),
		})
	prisms.sort_custom(func(a, b): return absf(a["angle"]) > absf(b["angle"]))  # centre drawn last


## Sell the revealed crystal (with its polish multiplier) and bring the next geode.
func collect() -> void:
	if anvil_state != Anvil.REVEALED and anvil_state != Anvil.DONE:
		return
	var v := eco.sell(revealed, polish_mult)
	Audio.play_sfx(Sfx.get_stream("coin"), -3.0, 0.05, 1.0 + 0.05 * int(revealed["tier"]))
	_popup("+" + Fmt.money(v), ANVIL_POS + Vector2(-80, -170), Color(1.0, 0.88, 0.4), 44)
	_burst(ANVIL_POS + Vector2(0, -40), Color(1.0, 0.85, 0.3), 16, 260.0, 7.0, 0.6, -300.0, true)
	anvil_state = Anvil.EMPTY
	revealed = {}
	_hide_banner()
	_try_load_anvil()
	_refresh_hud()
	if _slowmo_active:
		_end_slowmo()


func polishing_unlocked() -> bool:
	return eco.level("polish") > 0


func _start_polish() -> void:
	anvil_state = Anvil.POLISHING
	polish_fill = 0.0


func _finish_polish() -> void:
	polish_mult = eco.polish_mult(polish_fill)
	anvil_state = Anvil.DONE
	var txt: String
	if eco.is_perfect_polish(polish_fill):
		txt = "PERFECT POLISH  x%s" % _mult_str(polish_mult)
		Audio.play_sfx(Sfx.get_stream("perfect"), 0.0, 0.0)
		_burst(ANVIL_POS + Vector2(0, -60), Color(1, 1, 1), 40, 300.0, 6.0, 0.8, -100.0, true)
		_flash(Color(1, 1, 1), 0.25)
		add_trauma(0.3)
	elif polish_fill > 1.0:
		txt = "Scratched!  x%s" % _mult_str(polish_mult)
		Audio.play_sfx(Sfx.get_stream("deny"), 0.0, 0.0)
	else:
		txt = "Polished  x%s" % _mult_str(polish_mult)
		Audio.play_sfx(Sfx.get_stream("coin"), -8.0, 0.0, 0.8)
	_popup(txt, ANVIL_POS + Vector2(-170, 120), Color(0.85, 0.95, 1.0), 34)
	get_tree().create_timer(0.55).timeout.connect(func():
		if anvil_state == Anvil.DONE:
			collect())


# --- shop / book ----------------------------------------------------------------------------

func buy(id: String) -> bool:
	if not eco.buy(id):
		return false
	Audio.play_sfx(Sfx.get_stream("buy"), 0.0, 0.0)
	_flash(Color(1.0, 0.9, 0.5), 0.12)
	_popup("%s  Lv %d" % [eco.upgrade_def(id)["name"], eco.level(id)], Vector2(560, 560), Color(0.7, 1.0, 0.75), 34)
	if id == "polish" and eco.level(id) == 1:
		_show_banner("POLISHING UNLOCKED", "Hold on a crystal, release in the green zone", Color(0.7, 0.95, 1.0), 3.0)
	if id == "auto" and eco.level(id) == 1:
		_show_banner("AUTO-DIGGER", "It digs while you crack. Idle income!", Color(0.7, 1.0, 0.75), 3.0)
	save_now()
	_refresh_hud()
	return true


func _on_shop_pressed(id: String, b: Button) -> void:
	if not buy(id):
		Audio.play_sfx(Sfx.get_stream("deny"), -2.0, 0.0)
		var tw := create_tween()
		var x := b.position.x
		tw.tween_property(b, "position:x", x + 8, 0.04)
		tw.tween_property(b, "position:x", x - 8, 0.06)
		tw.tween_property(b, "position:x", x, 0.04)
	if not _using_pad:
		b.release_focus()


func _set_def(id: String) -> Dictionary:
	for s in eco.sets:
		if s["id"] == id:
			return s
	return {}


func _build_book() -> void:
	book = Control.new()
	book.set_anchors_preset(Control.PRESET_FULL_RECT)
	book.mouse_filter = Control.MOUSE_FILTER_STOP
	book.visible = false
	hud.add_child(book)
	var bgr := ColorRect.new()
	bgr.color = Color(0.04, 0.04, 0.06, 0.94)
	bgr.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.add_child(bgr)
	book.draw.connect(_draw_book)
	bgr.draw.connect(_draw_book_cells.bind(bgr))


func toggle_book() -> void:
	book.visible = not book.visible
	_mouse_hold = false
	_pad_hold = false
	if book.visible:
		for c in book.get_children():
			if c is Label:
				c.queue_free()
		_fill_book_labels()
		book.get_child(0).queue_redraw()
		Audio.play_sfx(Sfx.get_stream("drop"), -4.0, 0.0, 0.8)


const BOOK_CELL := Vector2(236, 160)
const BOOK_ORIGIN := Vector2(30, 76)


func _book_cell_rect(i: int) -> Rect2:
	var col := i % 5
	var row := i / 5
	return Rect2(BOOK_ORIGIN + Vector2(col * (BOOK_CELL.x + 8), row * (BOOK_CELL.y + 10)), BOOK_CELL)


func _fill_book_labels() -> void:
	var title := Label.new()
	title.text = "Collection  %d / %d" % [eco.collection.size(), eco.crystals.size()]
	title.position = Vector2(30, 14)
	title.add_theme_font_size_override("font_size", 40)
	book.add_child(title)
	var close := Label.new()
	close.text = "Close: Tab / B / (Y)"
	close.position = Vector2(860, 22)
	close.size = Vector2(390, 40)
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close.add_theme_font_size_override("font_size", 28)
	close.modulate = Color(0.7, 0.7, 0.75)
	book.add_child(close)
	for i in eco.crystals.size():
		var c: Dictionary = eco.crystals[i]
		var r := _book_cell_rect(i)
		var l := Label.new()
		var found := eco.collection.has(c["id"])
		l.text = ("%s  x%d" % [c["name"], eco.collection[c["id"]]]) if found else "? ? ?"
		l.position = r.position + Vector2(6, 100)
		l.size = Vector2(r.size.x - 12, 56)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 28)
		l.clip_text = true
		l.modulate = Color(1, 1, 1) if found else Color(0.5, 0.5, 0.55)
		book.add_child(l)
	var done := eco.completed_sets()
	for i in eco.sets.size():
		var s: Dictionary = eco.sets[i]
		var have := 0
		for m in s["members"]:
			if eco.collection.has(m):
				have += 1
		var l := Label.new()
		l.text = "%s %s %d/%d  +%d%%" % ["✔" if done.has(s["id"]) else "•", s["name"], have, s["members"].size(), roundi(float(s["bonus"]) * 100)]
		l.position = Vector2(30 + (i % 2) * 620, 584 + (i / 2) * 40)
		l.add_theme_font_size_override("font_size", 28)
		l.modulate = Color(1.0, 0.9, 0.5) if done.has(s["id"]) else Color(0.85, 0.85, 0.9)
		book.add_child(l)
	var odds := eco.tier_odds()
	var parts := []
	for t in eco.tiers.size():
		parts.append("%s %s%%" % [String(eco.tiers[t]["name"]).substr(0, 1), _pct(odds[t])])
	var ol := Label.new()
	ol.text = "Odds  " + "   ".join(parts) + "   ·   Rare+ guaranteed every %d" % int(eco.data["pity"]["rare_after"])
	ol.position = Vector2(30, 712)
	ol.size = Vector2(1220, 40)
	ol.add_theme_font_size_override("font_size", 28)
	ol.modulate = Color(0.7, 0.75, 0.8)
	book.add_child(ol)


func _pct(p: float) -> String:
	return "%.0f" % (p * 100) if p >= 0.1 else "%.1f" % (p * 100)


func _draw_book() -> void:
	pass


func _draw_book_cells(ci: CanvasItem) -> void:
	for i in eco.crystals.size():
		var c: Dictionary = eco.crystals[i]
		var r := _book_cell_rect(i)
		var tier := int(c["tier"])
		var tc := tier_color(tier)
		ci.draw_rect(r, Color(0.1, 0.1, 0.13))
		ci.draw_rect(r, tc.darkened(0.3), false, 3.0)
		var found := eco.collection.has(c["id"])
		var base := r.position + Vector2(r.size.x / 2, 92)
		if found:
			ci.draw_texture_rect(_glow_tex, Rect2(base - Vector2(70, 100), Vector2(140, 140)), false, Color(tc, 0.35))
			_draw_cluster(ci, base, Color(c["color"]), tier, 0.55, hash(c["id"]), c["id"] == "star_opal")
		else:
			_draw_cluster(ci, base, Color(0.2, 0.2, 0.24), tier, 0.55, hash(c["id"]), false)
		for s in tier + 1:
			ci.draw_circle(r.position + Vector2(14 + s * 16, 14), 5, tc)


# --- input --------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventKey or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		_using_pad = true  # controller or keyboard: show station highlights, keep shop focus
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		_using_pad = false
	if event.is_action_released(&"action_primary"):
		_on_release()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_release()
	if not get_tree().paused and (event.is_action_pressed(&"book") or (book.visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"action_secondary")))):
		toggle_book()
		get_viewport().set_input_as_handled()
		return
	# Leave the shop column with left on the d-pad / stick.
	var focus := get_viewport().gui_get_focus_owner()
	if focus and shop_buttons.values().has(focus) and event.is_action_pressed(&"ui_left"):
		focus.release_focus()
		station = Station.ANVIL
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if book.visible:
		return
	if event is InputEventMouseMotion:
		var s := _station_at(get_global_mouse_position())
		if s >= 0:
			station = s
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var s := _station_at(get_global_mouse_position())
		if s >= 0:
			station = s
			_mouse_station = s
			_mouse_hold = true
			_on_press(s, get_global_mouse_position())
	elif event.is_action_pressed(&"action_primary") and not event.is_echo():
		_pad_hold = true
		_on_press(station, Vector2.INF)
	elif event.is_action_pressed(&"ui_left"):
		station = Station.ROCK
	elif event.is_action_pressed(&"ui_right"):
		if station == Station.ROCK:
			station = Station.ANVIL
		else:
			var b: Button = shop_buttons[eco.upgrades[0]["id"]]
			for u in eco.upgrades:
				if eco.can_buy(u["id"]):
					b = shop_buttons[u["id"]]
					break
			b.grab_focus()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_down"):
		pass


func _station_at(pos: Vector2) -> int:
	if ROCK_RECT.grow(10).has_point(pos):
		return Station.ROCK
	if pos.distance_to(ANVIL_POS) < 170.0:
		return Station.ANVIL
	return -1


func _on_press(s: int, pos: Vector2) -> void:
	if s == Station.ROCK:
		dig_hit(pos)
		_dig_cd = DIG_INTERVAL
	else:
		match anvil_state:
			Anvil.GEODE:
				strike()
				_strike_cd = STRIKE_INTERVAL
			Anvil.REVEALED:
				if _need_release:
					return
				if reveal_t < MIN_REVEAL_SHOW:
					return
				if polishing_unlocked():
					_press_time = _time
				else:
					collect()
			Anvil.DONE:
				collect()


func _on_release() -> void:
	var was_holding := _mouse_hold or _pad_hold
	_mouse_hold = false
	_pad_hold = false
	_need_release = false
	if not was_holding:
		return
	if anvil_state == Anvil.POLISHING:
		_finish_polish()
	elif anvil_state == Anvil.REVEALED and _press_time >= 0.0:
		_press_time = -1.0
		collect()


func _holding(s: int) -> bool:
	if book.visible or get_tree().paused:
		return false
	return (_mouse_hold and _mouse_station == s) or (_pad_hold and station == s)


# --- frame ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var real_dt := delta / maxf(Engine.time_scale, 0.01)
	_time += real_dt
	eco.play_seconds += real_dt
	if _holding(Station.ROCK):
		_dig_cd -= delta
		if _dig_cd <= 0.0:
			_dig_cd += DIG_INTERVAL
			dig_hit(get_global_mouse_position() if _mouse_hold else Vector2.INF)
	if _holding(Station.ANVIL):
		match anvil_state:
			Anvil.GEODE:
				_strike_cd -= delta
				if _strike_cd <= 0.0:
					_strike_cd += STRIKE_INTERVAL
					strike()
			Anvil.REVEALED:
				if _press_time >= 0.0 and _time - _press_time >= HOLD_TO_POLISH:
					_start_polish()
			Anvil.POLISHING:
				polish_fill += real_dt / float(eco.data["polish"]["fill_seconds"])
				if fmod(polish_fill, 0.08) < real_dt / float(eco.data["polish"]["fill_seconds"]):
					Audio.play_sfx(Sfx.get_stream("polish"), -6.0, 0.1, 0.8 + polish_fill)
					_burst(ANVIL_POS + Vector2(randf_range(-50, 50), randf_range(-110, -20)), Color(1, 1, 1, 0.9), 2, 80.0, 5.0, 0.4, -50.0, true)
				if polish_fill > 1.15:
					_finish_polish()
	# Auto-digger
	var aps := eco.auto_digs_per_second()
	if aps > 0.0:
		_auto_acc += aps * delta
		while _auto_acc >= 1.0:
			_auto_acc -= 1.0
			var idx := _default_chunk()
			if idx >= 0:
				dig_hit(chunks[idx]["center"] + Vector2(randf_range(-30, 30), randf_range(-20, 20)), true)
	# Animation state
	if anvil_state == Anvil.REVEALED or anvil_state == Anvil.POLISHING or anvil_state == Anvil.DONE:
		reveal_t += real_dt
		shell_halves_t += real_dt
	if anvil_state == Anvil.EMPTY:
		_try_load_anvil()
	wobble_v += (-wobble * 160.0 - wobble_v * 9.0) * delta
	wobble += wobble_v * delta
	hammer_t = minf(1.0, hammer_t + delta * 7.0)
	for c in chunks:
		c["flash"] = maxf(0.0, float(c["flash"]) - delta * 4.0)
	for f in falling:
		f["vel"].y += 1500.0 * delta
		f["pos"] += f["vel"] * delta
		f["rot"] += f["spin"] * delta
		f["life"] -= delta
	falling = falling.filter(func(f): return f["life"] > 0.0)
	for g in flying:
		g["t"] += delta
		if not g["landed"] and g["t"] >= g["dur"]:
			g["landed"] = true
			Audio.play_sfx(Sfx.get_stream("drop"), -4.0, 0.1, 1.0 + 0.1 * g["hint"])
	flying = flying.filter(func(g): return g["t"] < g["dur"])
	trauma = maxf(0.0, trauma - delta * 2.2)
	var sh := trauma * trauma * 16.0
	camera.offset = Vector2(randf_range(-sh, sh), randf_range(-sh, sh))
	shown_money = lerpf(shown_money, eco.money, minf(1.0, real_dt * 10.0))
	if absf(shown_money - eco.money) < 0.5:
		shown_money = eco.money
	_autosave += real_dt
	if _autosave >= AUTOSAVE_SECONDS:
		_autosave = 0.0
		save_now()
	_refresh_hud()
	queue_redraw()
	glow.queue_redraw()
	back_glow.queue_redraw()


func add_trauma(a: float) -> void:
	trauma = minf(1.0, trauma + a)


func _slowmo(scale: float, hold: float) -> void:
	_slowmo_active = true
	Engine.time_scale = scale
	var zoom_tw := create_tween().set_ignore_time_scale(true).set_parallel()
	zoom_tw.tween_property(camera, "zoom", Vector2(1.14, 1.14), 0.25).set_trans(Tween.TRANS_SINE)
	zoom_tw.tween_property(camera, "position", camera.position.lerp(ANVIL_POS, 0.45), 0.25).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(hold, true, false, true).timeout.connect(_end_slowmo)


func _end_slowmo() -> void:
	if not _slowmo_active or not is_inside_tree():
		return
	_slowmo_active = false
	var tw := create_tween().set_ignore_time_scale(true).set_parallel()
	tw.tween_property(Engine, "time_scale", 1.0, 0.4)
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(camera, "position", Vector2(640, 400), 0.5).set_trans(Tween.TRANS_SINE)


func _flash(c: Color, a: float) -> void:
	flash.color = Color(c, a)
	create_tween().set_ignore_time_scale(true).tween_property(flash, "color:a", 0.0, 0.35)


func _show_banner(title: String, sub: String, c: Color, hold: float) -> void:
	banner.text = title
	banner.modulate = Color(c, 1.0)
	banner.scale = Vector2(1.6, 1.6)
	banner_sub.text = sub
	banner_sub.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(banner_sub, "modulate:a", 1.0, 0.3).set_delay(0.12)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(banner_sub, "modulate:a", 0.0, 0.5)
	banner.set_meta("tw", tw)


func _hide_banner() -> void:
	if banner.has_meta("tw"):
		var tw: Tween = banner.get_meta("tw")
		if tw and tw.is_valid():
			tw.kill()
	var t := create_tween().set_ignore_time_scale(true).set_parallel()
	t.tween_property(banner, "modulate:a", 0.0, 0.2)
	t.tween_property(banner_sub, "modulate:a", 0.0, 0.2)


func _popup(text: String, pos: Vector2, c: Color, font_size := 32, life := 1.1) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(l)
	var tw := create_tween().set_ignore_time_scale(true).set_parallel()
	tw.tween_property(l, "position:y", pos.y - 60, life).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.4).set_delay(life * 0.6)
	tw.chain().tween_callback(l.queue_free)


func _burst(pos: Vector2, c: Color, amount: int, speed: float, size_px: float, life: float, gravity: float, additive := false) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size_px * 0.5
	p.scale_amount_max = size_px
	p.damping_min = 40.0
	p.damping_max = 120.0
	var ramp := Gradient.new()
	ramp.set_color(0, c)
	ramp.set_color(1, Color(c, 0.0))
	p.color_ramp = ramp
	p.z_index = 6
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


# --- HUD ------------------------------------------------------------------------------------

func _refresh_hud() -> void:
	if money_label == null:
		return
	money_label.text = Fmt.money(shown_money)
	var inc := eco.idle_income_per_second()
	sub_label.text = ("Depth %d  ·  x%s value" % [eco.depth, _mult_str(eco.depth_mult() * eco.set_mult())]) + (("  ·  +%s/s idle" % Fmt.money(inc)) if inc > 0.0 else "")
	var goal := eco.next_goal()
	if goal != "":
		var cost := eco.upgrade_cost(goal)
		goal_label.text = "Next: %s  %s" % [eco.upgrade_def(goal)["name"], Fmt.money(cost)]
		goal_bar.value = clampf(eco.money / maxf(cost, 1.0), 0.0, 1.0)
	book_button.text = "Book %d/%d  [Tab]" % [eco.collection.size(), eco.crystals.size()]
	for u in eco.upgrades:
		var id: String = u["id"]
		var b: Button = shop_buttons[id]
		var desc: String = u["desc"]
		if id == "polish":
			var pz: Dictionary = eco.data["polish"]
			var next_mult := float(pz["base_mult"]) + float(pz["mult_per_level"]) * eco.level(id)
			desc = ("perfect x%s" % _mult_str(next_mult)) if eco.level(id) > 0 else "unlock polishing"
		var cost_txt := "MAX" if eco.is_maxed(id) else Fmt.money(eco.upgrade_cost(id))
		b.text = "%s\n%s\nLv %d   %s" % [u["name"], desc, eco.level(id), cost_txt]
		var afford := eco.can_buy(id)
		b.modulate = Color(1, 1, 1) if afford else Color(0.55, 0.55, 0.6)
		if afford:
			b.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.95, 0.7), 0.5 + 0.5 * sin(_time * 5.0))
	var hint := ""
	if station == Station.ROCK:
		hint = "Hold to dig the rock  (click / Space / A)"
	else:
		match anvil_state:
			Anvil.EMPTY: hint = "Dig rock to find geodes"
			Anvil.GEODE: hint = "Hold to crack the geode  (click / Space / A)"
			Anvil.REVEALED: hint = "Tap: sell   ·   Hold: polish" if polishing_unlocked() else "Tap to sell"
			Anvil.POLISHING: hint = "Release in the green zone!"
			Anvil.DONE: hint = ""
	if _using_pad:
		hint += "    ←→ switch"
	hint_label.text = hint


func _mult_str(m: float) -> String:
	return ("%.2f" % m).rstrip("0").rstrip(".") if m < 10.0 else Fmt.number(m)


# --- drawing --------------------------------------------------------------------------------

static func tier_color(tier: int) -> Color:
	return [Color("#b8b4ad"), Color("#5fd17a"), Color("#4aa8ff"), Color("#b465ff"), Color("#ffc23d")][clampi(tier, 0, 4)]


func _shell_color(hint: int) -> Color:
	return [Color(0.48, 0.43, 0.38), Color(0.42, 0.42, 0.36), Color(0.33, 0.36, 0.42), Color(0.32, 0.27, 0.38), Color(0.2, 0.18, 0.2)][clampi(hint, 0, 4)]


func _draw() -> void:
	# Rock face backing (deeper, darker rock)
	var back := ROCK_RECT.grow(6)
	draw_rect(back, Color.from_hsv(face_hue, 0.25, 0.16))
	for i in 7:
		var y := back.position.y + 40 + i * 64
		draw_line(Vector2(back.position.x, y), Vector2(back.end.x, y + 22 * sin(i * 1.7)), Color.from_hsv(face_hue, 0.3, 0.22), 3.0)
	if station == Station.ROCK and _using_pad:
		draw_rect(back.grow(6), Color(1, 0.9, 0.5, 0.6 + 0.3 * sin(_time * 6)), false, 4.0)
	var hover := _chunk_at(get_global_mouse_position())
	for i in chunks.size():
		var c: Dictionary = chunks[i]
		if c["broken"]:
			continue
		var col: Color = c["color"]
		var poly: PackedVector2Array = c["poly"]
		var cols := PackedColorArray()
		for p in poly:
			var k: float = ((p - c["center"]).dot(Vector2(-0.6, -0.8))) / 80.0
			cols.append(col.lightened(clampf(k * 0.25, 0.0, 0.3)).darkened(clampf(-k * 0.25, 0.0, 0.3)).lerp(Color.WHITE, c["flash"] * 0.35))
		draw_polygon(poly, cols)
		var outline := poly.duplicate()
		outline.append(poly[0])
		draw_polyline(outline, col.darkened(0.55), 3.0)
		if i == hover or (i == _default_chunk() and _using_pad and station == Station.ROCK):
			draw_polyline(outline, Color(1, 0.95, 0.75, 0.7), 3.0)
		var dmg := 1.0 - float(c["hp"]) / float(c["max_hp"])
		var n := int(ceil(dmg * c["cracks"].size()))
		for k in n:
			draw_polyline(c["cracks"][k], col.darkened(0.7), 3.0)
	for f in falling:
		var xf := Transform2D(f["rot"], f["pos"])
		var poly := xf * PackedVector2Array(f["poly"])
		draw_colored_polygon(poly, Color(f["color"], clampf(f["life"] * 1.5, 0.0, 1.0)))
	# Auto-digger: a little drill rig at the face's right edge
	if eco.level("auto") > 0:
		var dp := Vector2(ROCK_RECT.end.x + 2, ROCK_RECT.end.y - 40 + sin(_time * 30.0) * 2.0)
		draw_rect(Rect2(dp + Vector2(0, -16), Vector2(36, 32)), Color(0.85, 0.6, 0.15))
		draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -10), dp + Vector2(0, 10), dp + Vector2(-26, 0)]), Color(0.7, 0.72, 0.75))
		draw_string(ThemeDB.fallback_font, dp + Vector2(-4, 46), "x%d" % eco.level("auto"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.95, 0.8, 0.4))
	# Workbench + tray
	draw_rect(Rect2(20, 622, 940, 110), Color(0.22, 0.16, 0.12))
	draw_rect(Rect2(20, 622, 940, 10), Color(0.32, 0.24, 0.18))
	for s in eco.tray_size():
		draw_circle(_tray_pos(s), 34, Color(0.15, 0.11, 0.09))
	for i in eco.tray.size():
		var g: Dictionary = eco.tray[i]
		_draw_geode(self, _tray_pos(i), 30.0, int(g["hint"]), i * 31 + int(g["hint"]), 0.0)
	draw_string(ThemeDB.fallback_font, Vector2(TRAY_X0 + eco.tray_size() * TRAY_DX - 30, TRAY_Y + 10), "tray %d/%d" % [eco.tray.size(), eco.tray_size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.7, 0.62, 0.55))
	for g in flying:
		var t := clampf(g["t"] / g["dur"], 0.0, 1.0)
		if g["t"] < 0.0:
			continue
		var p: Vector2 = g["from"].lerp(g["to"], t) + Vector2(0, -180.0 * sin(PI * t))
		_draw_geode(self, p, 30.0, g["hint"], g["seed"], t * 8.0)
	# Anvil
	var ap := ANVIL_POS + Vector2(0, GEODE_R)
	draw_colored_polygon(PackedVector2Array([ap + Vector2(-150, 0), ap + Vector2(150, 0), ap + Vector2(110, 50), ap + Vector2(-110, 50)]), Color(0.36, 0.38, 0.42))
	draw_rect(Rect2(ap + Vector2(-70, 50), Vector2(140, 90)), Color(0.27, 0.28, 0.32))
	draw_line(ap + Vector2(-150, 0), ap + Vector2(150, 0), Color(0.6, 0.62, 0.66), 4.0)
	if station == Station.ANVIL and _using_pad:
		draw_arc(ANVIL_POS, 150, 0, TAU, 48, Color(1, 0.9, 0.5, 0.6 + 0.3 * sin(_time * 6)), 4.0)
	match anvil_state:
		Anvil.GEODE:
			var from := _tray_pos(0)
			var gp := from.lerp(ANVIL_POS, geode_slide) + Vector2(0, -120.0 * sin(PI * geode_slide))
			var r := lerpf(30.0, GEODE_R * (1.0 + 0.05 * int(anvil_geode["hint"])), geode_slide)
			_draw_geode(self, gp, r, int(anvil_geode["hint"]), anvil_seed, wobble * 0.02)
			var prog := crack_progress()
			if prog > 0.0:
				var n := int(ceil(prog * crack_paths.size()))
				for k in mini(n, crack_paths.size()):
					var path: PackedVector2Array = Transform2D(wobble * 0.02, gp) * crack_paths[k]
					draw_polyline(path, Color(0.05, 0.04, 0.04), 4.0)
			_draw_hammer()
		Anvil.REVEALED, Anvil.POLISHING, Anvil.DONE:
			_draw_reveal()


func _draw_hammer() -> void:
	var pivot := ANVIL_POS + Vector2(210, -40)
	var swing := lerpf(-0.15, -0.95, ease(hammer_t, 0.4)) if hammer_t < 1.0 else -0.95
	if _holding(Station.ANVIL):
		swing = -0.95 + 0.8 * (1.0 - hammer_t)
	var xf := Transform2D(swing, pivot)
	draw_set_transform_matrix(xf)
	draw_rect(Rect2(Vector2(-150, -6), Vector2(150, 12)), Color(0.55, 0.38, 0.22))
	draw_rect(Rect2(Vector2(-190, -30), Vector2(48, 60)), Color(0.62, 0.64, 0.7))
	draw_rect(Rect2(Vector2(-190, -30), Vector2(48, 8)), Color(0.8, 0.82, 0.86))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_reveal() -> void:
	var tier := int(revealed["tier"])
	var base := ANVIL_POS + Vector2(0, GEODE_R * 0.75)
	# Shell halves flying apart
	if shell_halves_t < 0.9:
		var t := shell_halves_t / 0.9
		var sc := _shell_color(int(anvil_geode.get("hint", 0)))
		for side in [-1, 1]:
			var c := ANVIL_POS + Vector2(side * (20 + 260 * t), -80 * sin(PI * t * 0.8) + 300 * t * t)
			var pts := PackedVector2Array()
			for k in 13:
				var a: float = -PI / 2 + side * PI * k / 12.0
				pts.append(Vector2(cos(a), sin(a)) * GEODE_R)
			var xf := Transform2D(side * t * 3.0, c)
			draw_colored_polygon(xf * pts, Color(sc, 1.0 - t))
			# inner geode lining
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(p * 0.8)
			draw_colored_polygon(xf * inner, Color(Color(revealed["color"]).darkened(0.4), (1.0 - t) * 0.8))
	# Cut geode bowl behind the crystal
	draw_circle(base + Vector2(0, -20), 92 * crystal_scale, Color(_shell_color(int(anvil_geode.get("hint", 0))), 1.0))
	draw_circle(base + Vector2(0, -24), 78 * crystal_scale, Color(revealed["color"]).darkened(0.55))
	var shine := polish_fill if anvil_state == Anvil.POLISHING else (0.6 if anvil_state == Anvil.DONE else 0.0)
	for pr in prisms:
		_draw_prism(self, base, pr, crystal_scale * 1.45, shine)
	# sparkle stars
	for k in 3 + tier * 2:
		var a := _time * (0.6 + 0.1 * k) + k * 2.1
		var rr := 70.0 + 30.0 * sin(_time * 1.3 + k)
		var sp := base + Vector2(cos(a), sin(a) * 0.7) * rr + Vector2(0, -60)
		var s := (2.0 + tier) * (0.5 + 0.5 * sin(_time * 6.0 + k * 1.7)) * crystal_scale
		draw_line(sp - Vector2(s * 2, 0), sp + Vector2(s * 2, 0), Color(1, 1, 1, 0.9), 2.0)
		draw_line(sp - Vector2(0, s * 2), sp + Vector2(0, s * 2), Color(1, 1, 1, 0.9), 2.0)
	# polish meter
	if polishing_unlocked() and anvil_state != Anvil.DONE:
		var bar := Rect2(ANVIL_POS + Vector2(-140, -GEODE_R - 120), Vector2(280, 24))
		var pz: Dictionary = eco.data["polish"]
		draw_rect(bar, Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * float(pz["zone_start"]), 0), Vector2(bar.size.x * (float(pz["zone_end"]) - float(pz["zone_start"])), bar.size.y)), Color(0.3, 0.85, 0.4))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(polish_fill, 0.0, 1.0), bar.size.y)), Color(1, 1, 1, 0.55))
		draw_rect(bar, Color(0.8, 0.8, 0.85), false, 2.0)


func _draw_prism(ci: CanvasItem, base: Vector2, pr: Dictionary, sc: float, shine: float) -> void:
	var dir := Vector2.UP.rotated(pr["angle"])
	var side := dir.orthogonal()
	var L: float = pr["len"] * sc
	var w: float = pr["width"] * 0.5 * sc
	var c: Color = pr["color"]
	var b0: Vector2 = base - side * w
	var b1: Vector2 = base + side * w
	var s0: Vector2 = b0 + dir * L * 0.78
	var s1: Vector2 = b1 + dir * L * 0.78
	var tip: Vector2 = base + dir * L
	var mid_b: Vector2 = base
	var mid_s: Vector2 = base + dir * L * 0.8
	var light := c.lightened(0.35 + 0.3 * shine)
	ci.draw_polygon(PackedVector2Array([b0, mid_b, mid_s, tip, s0]), PackedColorArray([c.darkened(0.35), c, light, light.lightened(0.3), c]))
	ci.draw_polygon(PackedVector2Array([mid_b, b1, s1, tip, mid_s]), PackedColorArray([c.darkened(0.15), c.darkened(0.45), c.darkened(0.2), light, c.lightened(0.1)]))
	ci.draw_polyline(PackedVector2Array([b0, s0, tip, s1, b1]), c.darkened(0.6), 2.0)
	ci.draw_line(mid_b, tip, Color(1, 1, 1, 0.25 + 0.5 * shine), 2.0)


func _draw_cluster(ci: CanvasItem, base: Vector2, col: Color, tier: int, sc: float, seed_value: int, rainbow: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var n := 4 + tier * 2
	var list := []
	for i in n:
		var t := (float(i) / maxf(1.0, n - 1)) - 0.5
		var cc := Color.from_hsv(fposmod(0.5 + t * 1.6, 1.0), 0.45, 1.0) if rainbow else col
		list.append({"angle": t * 1.9 + rng.randf_range(-0.12, 0.12),
			"len": rng.randf_range(55, 95) * (1.0 + 0.13 * tier) * (1.0 - absf(t) * 0.6),
			"width": rng.randf_range(16, 26), "color": cc.darkened(rng.randf_range(0.0, 0.25))})
	list.sort_custom(func(a, b): return absf(a["angle"]) > absf(b["angle"]))
	for pr in list:
		_draw_prism(ci, base, pr, sc, 0.0)


func _draw_geode(ci: CanvasItem, pos: Vector2, r: float, hint: int, seed_value: int, rot: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var col := _shell_color(hint)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var n := 20
	for k in n:
		var a := TAU * k / n + rot
		var rr := r * (1.0 + rng.randf_range(-0.08, 0.08))
		var p := Vector2(cos(a), sin(a) * 0.92) * rr
		pts.append(pos + p)
		var light := p.normalized().dot(Vector2(-0.6, -0.8))
		cols.append(col.lightened(maxf(0.0, light) * 0.3).darkened(maxf(0.0, -light) * 0.35))
	ci.draw_polygon(pts, cols)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, col.darkened(0.6), 2.0 + r * 0.03)
	# bumps
	for k in 6:
		var p := pos + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)).rotated(rot) * r
		ci.draw_circle(p, r * rng.randf_range(0.08, 0.16), col.darkened(0.15))
	# rarity flecks: more and brighter for better shells
	if hint > 0:
		var fc := tier_color(hint)
		for k in hint * 4:
			var p := pos + Vector2(rng.randf_range(-0.75, 0.75), rng.randf_range(-0.7, 0.7)).rotated(rot) * r
			var tw := 0.6 + 0.4 * sin(_time * 4.0 + k * 1.3)
			ci.draw_circle(p, r * 0.045 * (1.0 + 0.3 * hint) * tw, Color(fc.lightened(0.3), 0.9))


func _draw_glow() -> void:
	# Additive layer: glows, light leaks and rays.
	for i in eco.tray.size():
		var h := int(eco.tray[i]["hint"])
		if h >= 3:
			var gr := 60.0 + 10 * h
			glow.draw_texture_rect(_glow_tex, Rect2(_tray_pos(i) - Vector2(gr, gr), Vector2(gr, gr) * 2), false, Color(tier_color(h), 0.25 + 0.1 * sin(_time * 3 + i)))
	match anvil_state:
		Anvil.GEODE:
			var h := int(anvil_geode["hint"])
			var tier := int(anvil_geode["tier"])
			var gp := _tray_pos(0).lerp(ANVIL_POS, geode_slide)
			if h >= 3:
				glow.draw_texture_rect(_glow_tex, Rect2(gp - Vector2(170, 170), Vector2(340, 340)), false, Color(tier_color(h), 0.25 + 0.1 * sin(_time * 3)))
			var prog := crack_progress()
			# Light leaks out of the cracks: brighter and coloured for better crystals.
			if prog > 0.0:
				var lc := Color(revealed_color_hint(tier), clampf(prog * (0.4 + 0.15 * tier), 0.0, 1.0))
				var n := int(ceil(prog * crack_paths.size()))
				for k in mini(n, crack_paths.size()):
					var path: PackedVector2Array = Transform2D(wobble * 0.02, gp) * crack_paths[k]
					glow.draw_polyline(path, lc, 6.0 + 4.0 * prog * tier)
				if tier >= Economy.RARE:
					glow.draw_texture_rect(_glow_tex, Rect2(gp - Vector2(140, 140) * prog, Vector2(280, 280) * prog), false, Color(tier_color(tier), 0.5 * prog))
		Anvil.REVEALED, Anvil.POLISHING, Anvil.DONE:
			var tier := int(revealed["tier"])
			var tc := tier_color(tier)
			var c := ANVIL_POS + Vector2(0, -10)
			# flash ring right after the burst
			if reveal_t < 0.5:
				var rr := 40.0 + 700.0 * reveal_t
				glow.draw_arc(c, rr, 0, TAU, 64, Color(tc, 1.0 - reveal_t * 2.0), 10.0)
			# soft bloom on the crystal tips
			var gr := 60.0 * crystal_scale
			glow.draw_texture_rect(_glow_tex, Rect2(c + Vector2(0, -20) - Vector2(gr, gr), Vector2(gr, gr) * 2), false, Color(Color(revealed["color"]), 0.18 + 0.25 * polish_fill))


func _draw_back_glow() -> void:
	if not (anvil_state == Anvil.REVEALED or anvil_state == Anvil.POLISHING or anvil_state == Anvil.DONE):
		return
	var tier := int(revealed["tier"])
	var tc := tier_color(tier)
	var c := ANVIL_POS + Vector2(0, -20)
	var gr := (120.0 + 40.0 * tier) * crystal_scale * (1.0 + 0.05 * sin(_time * 4))
	back_glow.draw_texture_rect(_glow_tex, Rect2(c - Vector2(gr, gr), Vector2(gr, gr) * 2), false, Color(tc, 0.35 + 0.08 * tier))
	if tier >= Economy.RARE:
		var rays := 6 + 3 * tier
		for k in rays:
			var a := TAU * k / rays + _time * 0.4
			var len := (200.0 + 50.0 * tier) * crystal_scale
			var w := 0.06
			back_glow.draw_colored_polygon(PackedVector2Array([c, c + Vector2.RIGHT.rotated(a - w) * len, c + Vector2.RIGHT.rotated(a + w) * len]), Color(tc, 0.07 + 0.025 * tier))


func revealed_color_hint(tier: int) -> Color:
	return Color(1.0, 0.85, 0.6) if tier < Economy.RARE else tier_color(tier).lightened(0.3)


# --- autoplay (debug builds only: greybox capture) -------------------------------------------

## `godot --path game res://scenes/game.tscn -- --autoplay [--tier=4]`: digs, then cracks a
## geode of the given tier and quits after the reveal. For screenshots only.
func _run_autoplay() -> void:
	var tier := 4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tier="):
			tier = int(a.substr(7))
	eco.money = 0
	await get_tree().create_timer(0.3).timeout
	for i in 14:
		dig_hit(chunks[_default_chunk()]["center"] + Vector2(randf_range(-30, 30), randf_range(-20, 20)))
		await get_tree().create_timer(0.11).timeout
	anvil_state = Anvil.EMPTY
	eco.tray.push_front({"tier": tier, "hint": tier})
	_try_load_anvil()
	station = Station.ANVIL
	await get_tree().create_timer(0.5).timeout
	while anvil_state == Anvil.GEODE:
		strike()
		await get_tree().create_timer(0.16).timeout
	await get_tree().create_timer(3.0, true, false, true).timeout
	get_tree().quit()
