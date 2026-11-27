extends Node2D
## The arena: owns the ArenaSim, turns devices into InputFrames (mouse or right-stick aim,
## controller aim assist), steps the sim at 60 Hz with hitstop, and turns sim events into feel:
## squash/stretch, particles, screen shake, size-scaled camera zoom, sounds and HUD text.
##
## Debug/capture (debug builds only): `-- --autoplay [--skip=SECONDS] [--frames=N] [--seed=N]`
## lets the pacing Bot play; --skip fast-forwards the sim before the first frame.

const TITLE_SCENE := "res://scenes/title.tscn"

var sim: ArenaSim
var bot: Bot = null
var autoplay := false
var _quit_after := -1
var _frame := 0

var _floor: Node2D
var _glow_back: Node2D
var _bodies: Node2D
var _glow_front: Node2D
var _fx: Node2D
@onready var camera: Camera2D = $Camera
@onready var hud: Hud = %Hud
@onready var pause_menu = $PauseMenu

# feel state
var _t := 0.0
var _hitstop := 0.0
var _trauma := 0.0
var _hook_buffer := 0.0
var _dodge_buffer := 0.0
var _use_pad_aim := false
var _vis_r := 18.0
var _vis_rv := 0.0
var _squash := Vector2.ONE
var _squash_v := Vector2.ZERO
var _chomp := 0.0
var _hurt := 0.0
var _happy := 0.0
var _blink := 2.0
var _angle := 0.0
var _evis: Dictionary = {}      # enemy id -> {flash, pop}
var _ghosts: Array = []         # eaten enemies being swallowed
var _rings: Array = []          # expanding rings {pos, r, max, t, color}
var _line_flash := 0.0
var _decor: Array = []
var _yank_chain := 0
var _won_shown := false
var _start_ms := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	autoplay = OS.is_debug_build() and args.has("--autoplay")
	var seed_value := randi()
	var skip := 0.0
	for a in args:
		if a.begins_with("--seed="):
			seed_value = int(a.get_slice("=", 1))
		elif a.begins_with("--skip="):
			skip = float(a.get_slice("=", 1))
		elif a.begins_with("--frames="):
			_quit_after = int(a.get_slice("=", 1))
	sim = ArenaSim.new(Balance.copy(), seed_value)
	if autoplay:
		bot = Bot.new(seed_value + 1)
		while sim.time < skip:
			if not sim.pending_choice.is_empty():
				sim.choose_evolution(0)
			sim.step(bot.think(sim))
	_build_layers()
	hud.sim = sim
	hud.evolution_chosen.connect(_on_evolution_chosen)
	hud.continue_pressed.connect(func(): pass)
	hud.title_pressed.connect(func(): SceneChanger.change_to(TITLE_SCENE))
	hud.set_hint("Aim: mouse / right stick    Hook: left click / RT    Yank: hook again    Dodge: %s / A" % [
		Settings.binding_label(&"dodge")])
	_vis_r = sim.st["radius"]
	camera.zoom = Vector2.ONE * _target_zoom()
	camera.position = sim.pos
	_start_ms = Time.get_ticks_msec()
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	hud.banner("WAVE %d" % (sim.wave + 1) if sim.wave < sim.wave_count() else "BOSS",
		"Hook it. Reel it. Eat it. Grow.", 2.2)
	if sim.wave > 0:
		hud.set_hint("")
	_load_records()


func _build_layers() -> void:
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_floor = Node2D.new()
	_floor.z_index = -3
	add_child(_floor)
	_glow_back = Node2D.new()
	_glow_back.z_index = -1
	_glow_back.material = add_mat
	add_child(_glow_back)
	_bodies = Node2D.new()
	add_child(_bodies)
	_fx = Node2D.new()
	_fx.z_index = 1
	add_child(_fx)
	_glow_front = Node2D.new()
	_glow_front.z_index = 2
	_glow_front.material = add_mat
	add_child(_glow_front)
	_floor.draw.connect(_draw_floor)
	_glow_back.draw.connect(_draw_glow_back)
	_bodies.draw.connect(_draw_bodies)
	_glow_front.draw.connect(_draw_glow_front)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ar: float = sim.B["arena_radius"]
	for i in 420:
		var p := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * ar
		var kind := rng.randi_range(0, 9)
		_decor.append({"p": p, "k": kind, "s": rng.randf_range(6.0, 30.0) * (1.0 + p.length() / ar * 2.0), "ph": rng.randf() * TAU})


const BASE_ZOOM := 2.0


func _target_zoom() -> float:
	return BASE_ZOOM / Growth.scale(sim.B, sim.size)


# =============================================================================
# input + stepping
# =============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_pad_aim = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		_use_pad_aim = true


func _read_input() -> InputFrame:
	var f := InputFrame.new()
	f.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() > 0.35:
		_use_pad_aim = true
	if _use_pad_aim:
		if stick.length() > 0.35:
			f.aim = stick.normalized()
		elif f.move.length() > 0.3:
			f.aim = f.move.normalized()
		else:
			f.aim = sim.aim
		if Settings.aim_assist:
			f.aim = _assist(f.aim)
	else:
		var m := get_global_mouse_position() - sim.pos
		f.aim = m.normalized() if m.length() > 4.0 else sim.aim
	f.hook_pressed = _hook_buffer > 0.0
	f.dodge_pressed = _dodge_buffer > 0.0
	return f


## Controller aim assist: nudge onto the closest hookable prey inside a 12 degree cone.
func _assist(aim: Vector2) -> Vector2:
	var best := aim
	var best_a := deg_to_rad(12.0)
	for e in sim.enemies:
		if not sim.hookable(e) or e.state == ArenaSim.EState.HOOKED:
			continue
		var to: Vector2 = e.pos - sim.pos
		if to.length() > sim.st["hook_range"] + e.radius:
			continue
		var a := absf(aim.angle_to(to))
		if a < best_a:
			best_a = a
			best = to.normalized()
	return best


func _physics_process(delta: float) -> void:
	_t += delta
	if Input.is_action_just_pressed(&"hook"):
		_hook_buffer = 0.15
	if Input.is_action_just_pressed(&"dodge"):
		_dodge_buffer = 0.12
	_hook_buffer -= delta
	_dodge_buffer -= delta
	if hud.evolution_visible() or hud.win_visible():
		_hook_buffer = 0.0
		_dodge_buffer = 0.0
	elif _hitstop > 0.0:
		_hitstop -= delta
	else:
		var f: InputFrame
		if bot != null:
			if not sim.pending_choice.is_empty():
				_on_evolution_chosen(0)
			f = bot.think(sim)
		else:
			f = _read_input()
		if f.hook_pressed:
			_hook_buffer = 0.0
		if f.dodge_pressed:
			_dodge_buffer = 0.0
		sim.step(f)
		_handle_events()
	_update_feel(delta)
	_floor.queue_redraw()
	_glow_back.queue_redraw()
	_bodies.queue_redraw()
	_glow_front.queue_redraw()
	_frame += 1
	if _quit_after > 0 and _frame >= _quit_after:
		get_tree().quit()


func _on_evolution_chosen(i: int) -> void:
	hud.hide_evolution()
	sim.choose_evolution(i)
	_handle_events()


# =============================================================================
# events -> feel
# =============================================================================

func _screen(world: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world


func _shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount * Settings.screen_shake)


func _handle_events() -> void:
	var k: float = sim.st["scale"]
	for ev in sim.events:
		var p: Vector2 = ev.get("pos", sim.pos)
		match ev["type"]:
			"throw":
				Sfx.play("throw", -4.0, 1.0 + 0.1 * (ev["count"] - 1))
				_squash = Vector2(1.15, 0.9)
				_yank_chain = 0
			"catch":
				_hitstop = float(sim.B["hook"]["hitstop_boss" if ev["boss"] else "hitstop_catch"])
				_shake(0.22 if not ev["boss"] else 0.5)
				Sfx.play("catch", -2.0)
				_flash_enemy(ev["id"])
				_ring(p, 40.0 * k, Look.LINE)
			"chain":
				Sfx.play("chain", -5.0, 1.3)
				_ring(ev["to"], 30.0 * k, Color("ffd166"))
			"yank":
				_yank_chain += 1
				Sfx.play("yank", -3.0, 1.0 + 0.06 * mini(_yank_chain, 8))
				_line_flash = 1.0
				_squash = Vector2(0.85, 1.12)
				_shake(0.08)
			"eat":
				_on_eat(ev)
			"bite":
				_hitstop = 0.12
				_shake(0.7)
				_chomp = 1.0
				_happy = 0.6
				Sfx.play("chomp", 0.0, 0.6)
				Sfx.play("gulp", -2.0, 0.7)
				_burst(p, Look.KIND_COLORS["boss"].lightened(0.4), 40, ev["enemy_radius"] * 0.8)
				hud.floater("CHOMP!  %d to go" % ev["bites_left"], _screen(p), Look.LURE, 44)
				hud.on_meal(ev["size_before"], ev["size_after"])
			"trait":
				var t: String = ev["trait"]
				var lvl := Growth.stack(sim.traits, t, int(sim.B["traits"]["cap"]))
				var before := Growth.stack({t: int(ev["stacks"]) - 1}, t, int(sim.B["traits"]["cap"]))
				if lvl > before:
					hud.floater("%s %s!" % [Look.TRAIT_NAMES[t], Look.ROMAN[lvl]], _screen(sim.pos) + Vector2(0, -60), Look.TRAIT_COLORS[t], 40)
					Sfx.play("trait", -3.0)
					_ring(sim.pos, sim.st["radius"] * 2.2, Look.TRAIT_COLORS[t])
			"too_big":
				hud.floater("TOO BIG! need size %.1f" % ev["need"], _screen(p), Color("ff8a95"), 30)
				Sfx.play("too_big", -4.0)
			"clang":
				hud.floater("CLANG! hit its back", _screen(p), Color("c9d6ea"), 28)
				Sfx.play("clang", -3.0)
				_burst(p, Color("dfe7f5"), 10, 8.0 * k)
				_shake(0.12)
			"spiked":
				hud.floater("OUCH! wait till it deflates", _screen(p), Color("ffb36b"), 28)
				Sfx.play("spiked", -2.0)
				_shake(0.3)
			"hurt":
				_hurt = 1.0
				hud.hurt_flash(0.18 + 0.3 * clampf(ev["amount"] / sim.st["hp_max"] * 4.0, 0.0, 1.0))
				_shake(0.25)
				Sfx.play("hurt", -3.0)
			"death":
				hud.banner("GULP...", "You got eaten! Back to the start of wave %d." % (ev["wave"] + 1), 2.2, Color("ff8a95"))
				Sfx.play("death")
				_shake(0.8)
				_vis_r = sim.st["radius"]
			"dodge":
				Sfx.play("dodge", -6.0)
				_squash = Vector2(1.3, 0.8)
			"whirl":
				Sfx.play("whirl", -3.0)
			"snap":
				hud.floater("it got away!", _screen(p), Color("c9d6ea"), 28)
				Sfx.play("snap", -3.0)
			"spit":
				Sfx.play("spit", -12.0)
			"puff":
				Sfx.play("puff", -12.0, 0.8)
			"shockwave":
				_ring(sim.pos, ev["radius"], Look.TRAIT_COLORS["damage"])
			"wave":
				if ev["wave"] > 1:
					hud.banner("WAVE %d" % ev["wave"], "", 1.2)
					Sfx.play("wave", -4.0)
				if ev["wave"] == 2:
					hud.set_hint("")
			"boss":
				hud.banner("THE LANTERN LEVIATHAN RISES", "Grow to size %.1f to hook it. Its snacks keep coming." % ev["need"], 2.6, Color("9ad1ff"))
				Sfx.play("boss")
				_shake(0.6)
			"boss_hookable":
				hud.banner("BIG ENOUGH!", "Hook the Leviathan and mash yank!", 2.0, Color("b8ffb0"))
				Sfx.play("evolve", -2.0, 0.8)
			"evolve_offer":
				Sfx.play("evolve", -2.0)
				_ring(sim.pos, sim.st["radius"] * 3.0, Look.LURE)
				if bot == null:
					hud.show_evolution(sim.pending_choice, sim.forms)
			"evolve":
				var info: Array = Hud.FORM_INFO[ev["form"]]
				hud.banner(info[0] if ev["level"] == 1 else info[2], info[1] if ev["level"] == 1 else info[3], 1.6, Look.LURE)
			"win":
				_on_win()


func _on_eat(ev: Dictionary) -> void:
	var p: Vector2 = ev["pos"]
	var ratio: float = ev["enemy_radius"] / maxf(1.0, sim.st["radius"])
	_ghosts.append({"kind": ev["kind"], "from": p, "r": ev["enemy_radius"], "t": 0.0})
	_hitstop = maxf(_hitstop, float(sim.B["hook"]["hitstop_eat"]) * (1.0 + ratio))
	_shake(0.16 + 0.35 * ratio)
	_chomp = 1.0
	_happy = 0.45
	_squash = Vector2(1.35, 0.72)
	_vis_rv += sim.st["radius"] * 2.5 * (0.5 + ratio)  # pop: the spring overshoots the new size
	Sfx.play("chomp", -1.0, clampf(1.3 - ratio * 0.6, 0.6, 1.4))
	if ratio > 0.6:
		Sfx.play("gulp", -3.0, 1.0)
	var col: Color = Look.KIND_COLORS[ev["kind"]]
	_burst(sim.pos + (p - sim.pos).normalized() * sim.st["radius"], col, int(10 + 20 * ratio), ev["enemy_radius"] * 0.45)
	_burst(sim.pos, Color("fff4e0"), 6, ev["enemy_radius"] * 0.3)
	hud.on_meal(ev["size_before"], ev["size_after"])


func _on_win() -> void:
	Sfx.play("win")
	_shake(1.0)
	_ring(sim.pos, sim.st["radius"] * 6.0, Look.LURE)
	var secs := int(sim.time)
	_save_records(true)
	if bot != null:
		hud.banner("YOU ATE THE LEVIATHAN!", "%d:%02d" % [secs / 60, secs % 60], 3.0, Look.LURE)
		return
	hud.show_win("Time %d:%02d   -   size %.1f   -   %d meals   -   %d deaths\n%s" % [
		secs / 60, secs % 60, sim.size, sim.meals, sim.deaths, _records_line()])


func _flash_enemy(id: int) -> void:
	if not _evis.has(id):
		_evis[id] = {"flash": 0.0, "pop": 1.0}
	_evis[id]["flash"] = 1.0


func _ring(p: Vector2, max_r: float, col: Color) -> void:
	_rings.append({"pos": p, "max": max_r, "t": 0.0, "c": col})


func _burst(p: Vector2, col: Color, amount: int, speed_scale: float) -> void:
	var cp := CPUParticles2D.new()
	cp.position = p
	cp.one_shot = true
	cp.explosiveness = 0.95
	cp.amount = maxi(amount, 2)
	cp.lifetime = 0.55
	cp.spread = 180.0
	cp.direction = Vector2.UP
	cp.gravity = Vector2.ZERO
	cp.initial_velocity_min = speed_scale * 4.0
	cp.initial_velocity_max = speed_scale * 10.0
	cp.damping_min = speed_scale * 8.0
	cp.damping_max = speed_scale * 12.0
	cp.scale_amount_min = maxf(0.06, speed_scale * 0.03)
	cp.scale_amount_max = maxf(0.12, speed_scale * 0.07)
	cp.texture = Look.glow_texture()
	var g := Gradient.new()
	g.set_color(0, col.lightened(0.2))
	g.set_color(1, Color(col, 0.0))
	cp.color_ramp = g
	_fx.add_child(cp)
	cp.emitting = true
	cp.finished.connect(cp.queue_free)


func _update_feel(delta: float) -> void:
	# size spring: under-damped so each meal visibly "pops" bigger, then settles
	var target_r: float = sim.st["radius"]
	var acc := (target_r - _vis_r) * 180.0 - _vis_rv * 14.0
	_vis_rv += acc * delta
	_vis_r += _vis_rv * delta
	_squash_v += ((Vector2.ONE - _squash) * 260.0 - _squash_v * 16.0) * delta
	_squash += _squash_v * delta
	_chomp = maxf(0.0, _chomp - delta * 4.0)
	_hurt = maxf(0.0, _hurt - delta * 3.0)
	_happy = maxf(0.0, _happy - delta)
	_line_flash = maxf(0.0, _line_flash - delta * 6.0)
	_blink -= delta
	if _blink < -0.12:
		_blink = randf_range(1.8, 4.5)
	_angle = lerp_angle(_angle, sim.aim.angle(), 1.0 - exp(-18.0 * delta))
	for id in _evis.keys():
		_evis[id]["flash"] = maxf(0.0, _evis[id]["flash"] - delta * 6.0)
	for g in _ghosts:
		g["t"] += delta / 0.16
	_ghosts = _ghosts.filter(func(g): return g["t"] < 1.0)
	for r in _rings:
		r["t"] += delta / 0.45
	_rings = _rings.filter(func(r): return r["t"] < 1.0)
	# camera: follow with a little aim look-ahead; zoom out smoothly as you grow
	var look: Vector2 = sim.aim * sim.st["hook_range"] * 0.18
	camera.position = camera.position.lerp(sim.pos + look, 1.0 - exp(-8.0 * delta))
	var z := lerpf(camera.zoom.x, _target_zoom(), 1.0 - exp(-2.5 * delta))
	camera.zoom = Vector2.ONE * z
	_trauma = maxf(0.0, _trauma - delta * 1.8)
	var sh := _trauma * _trauma * 22.0 / z
	camera.offset = Vector2(sin(_t * 71.0), cos(_t * 63.0)) * sh


# =============================================================================
# drawing
# =============================================================================

func _draw_floor() -> void:
	var ar: float = sim.B["arena_radius"]
	_floor.draw_rect(Rect2(-Vector2.ONE * ar * 3.0, Vector2.ONE * ar * 6.0), Color("050a16"))
	_floor.draw_circle(Vector2.ZERO, ar + 40.0, Color("0c1a33"))
	for i in 6:
		_floor.draw_circle(Vector2.ZERO, ar * (1.0 - i * 0.16), Color("0e2140").lerp(Color("123058"), i / 6.0))
	for d in _decor:
		var p: Vector2 = d["p"]
		var s: float = d["s"]
		match d["k"]:
			0, 1, 2, 3:
				_floor.draw_circle(p, s, Color(0.2, 0.32, 0.5, 0.18))
			4, 5:
				var pts := PackedVector2Array()
				for j in 7:
					pts.append(p + Vector2(sin(_t * 1.5 + d["ph"] + j * 0.6) * s * 0.4, -j * s * 0.7))
				_floor.draw_polyline(pts, Color(0.2, 0.55, 0.45, 0.5), maxf(2.0, s * 0.18), true)
			_:
				_floor.draw_circle(p, s * 0.25, Color(0.4, 0.8, 1.0, 0.25 + 0.15 * sin(_t * 2.0 + d["ph"])))
	_floor.draw_arc(Vector2.ZERO, ar, 0.0, TAU, 128, Color(0.4, 0.8, 1.0, 0.5), 10.0, true)
	# aim preview: dotted line to the end of the hook range
	if sim.all_idle() and not hud.evolution_visible():
		var rng_len: float = sim.st["hook_range"]
		var k: float = sim.st["scale"]
		var col := Color(1, 1, 1, 0.22)
		var target = _aim_target()
		if target != null:
			col = Color(0.6, 1.0, 0.65, 0.5) if sim.hookable(target) else Color(1.0, 0.4, 0.45, 0.5)
		var n := 14
		for i in range(2, n + 1):
			var p := sim.pos + sim.aim * rng_len * i / n
			_floor.draw_circle(p, 3.0 * k, col)


func _aim_target():
	var best = null
	var best_d := INF
	var rng_len: float = sim.st["hook_range"]
	for e in sim.enemies:
		var c := Geometry2D.get_closest_point_to_segment(e.pos, sim.pos, sim.pos + sim.aim * rng_len)
		if c.distance_to(e.pos) < e.radius + sim.st["hook_radius"]:
			var d: float = sim.pos.distance_to(e.pos)
			if d < best_d:
				best_d = d
				best = e
	return best


func _draw_glow_back() -> void:
	var r := _vis_r
	Look.glow(_glow_back, sim.pos, r * 2.6, Color(0.3, 0.9, 0.85, 0.22))
	for e in sim.enemies:
		Look.glow_for_enemy(_glow_back, e, _t, sim.pos)
	for s in sim.shots:
		Look.glow(_glow_back, s["pos"], s["r"] * 4.0, Color(0.7, 1.0, 0.4, 0.5))
	for h in sim.hooks:
		if h.state != ArenaSim.HookState.IDLE:
			Look.glow(_glow_back, h.pos, 26.0 * sim.st["scale"], Color(1.0, 0.95, 0.5, 0.45))
	if sim.whirl_t > 0.0:
		Look.glow(_glow_back, sim.pos, sim.st["hook_range"] * 0.8, Color(0.4, 0.9, 1.0, 0.12))


func _draw_bodies() -> void:
	var k: float = sim.st["scale"]
	# shots
	for s in sim.shots:
		_bodies.draw_circle(s["pos"], s["r"], Color("b8ff6a"))
		_bodies.draw_circle(s["pos"], s["r"] * 0.5, Color("f4ffd8"))
	# enemies
	for e in sim.enemies:
		var v: Dictionary = _evis.get(e.id, {"flash": 0.0, "pop": 1.0})
		Look.draw_enemy(_bodies, e, {"t": _t + e.id, "flash": v["flash"], "hookable": sim.hookable(e),
			"open": sim.shell_open(e), "player": sim.pos,
			"near": e.pos.distance_to(sim.pos) < sim.st["hook_range"] + e.radius})
	# ghosts being swallowed: shrink and slide into the mouth
	var mouth := sim.pos + Vector2.from_angle(_angle) * _vis_r * 0.6
	for g in _ghosts:
		var gt: float = g["t"]
		var gp: Vector2 = (g["from"] as Vector2).lerp(mouth, gt * gt)
		var gr: float = g["r"] * (1.0 - gt) * (1.0 + 0.3 * sin(gt * PI))
		_bodies.draw_circle(gp, maxf(gr, 0.5), Look.KIND_COLORS[g["kind"]])
	# lines and hooks
	var tip := Look.lure_tip(sim.pos, _vis_r, _angle)
	var line_col := Look.LINE.lerp(Color.WHITE, _line_flash)
	var w := maxf(2.0, 3.0 * k) * (1.0 + _line_flash * 0.8)
	for h in sim.hooks:
		if h.state == ArenaSim.HookState.IDLE:
			continue
		var from := tip
		if h.chain_from != null and sim.enemies.has(h.chain_from):
			from = h.chain_from.pos
		var taut: bool = h.state == ArenaSim.HookState.ATTACHED
		_draw_line(from, h.pos, taut, line_col if h.chain_from == null else Color("ffd166"), w)
		if not taut:
			Look.draw_hook_head(_bodies, h.pos, h.pos - from, k)
	if sim.whirl_t > 0.0:
		var reach: float = sim.st["hook_range"] * float(sim.B["evolution"]["whirl_range_mult"])
		var wtip := sim.pos + Vector2.from_angle(sim.whirl_angle) * reach
		_bodies.draw_arc(sim.pos, reach, sim.whirl_angle - 1.6, sim.whirl_angle, 24, Color(0.6, 0.95, 1.0, 0.35), 10.0 * k, true)
		_draw_line(tip, wtip, true, line_col, w)
		Look.draw_hook_head(_bodies, wtip, wtip - sim.pos, k)
	# the player
	var eyes := "normal"
	if _hurt > 0.4:
		eyes = "hurt"
	elif _happy > 0.0:
		eyes = "happy"
	elif _blink < 0.0:
		eyes = "closed"
	var mouth_open := maxf(0.55 if sim.any_attached() else 0.0, sin(_chomp * PI) * 0.9)
	var vel_stretch := clampf(sim.vel.length() / maxf(1.0, sim.st["speed"]) * 0.08, 0.0, 0.25)
	var sq := _squash * Vector2(1.0 + vel_stretch, 1.0 - vel_stretch * 0.6)
	if sim.invuln > 0.0 and sim.dodge_t <= 0.0 and int(_t * 20.0) % 2 == 0 and _hurt > 0.0:
		sq *= 0.97
	Look.draw_morsel(_bodies, sim.pos, _vis_r, _angle, sq, {"t": _t, "mouth": mouth_open, "eyes": eyes,
		"look": Vector2.RIGHT, "traits": _trait_levels(), "lure": sim.all_idle() and sim.whirl_t <= 0.0,
		"hurt": _hurt * 0.6})
	# rings
	for r in _rings:
		var rt: float = r["t"]
		_bodies.draw_arc(r["pos"], r["max"] * (0.3 + 0.7 * sqrt(rt)), 0, TAU, 48, Color(r["c"], 1.0 - rt), maxf(2.0, 6.0 * k * (1.0 - rt)), true)


func _draw_line(a: Vector2, b: Vector2, taut: bool, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var n := 14
	var d := b - a
	var perp := d.orthogonal().normalized()
	var amp: float = (0.0 if taut else d.length() * 0.05) + (3.0 * sim.st["scale"] if taut else 0.0)
	for i in n + 1:
		var u := float(i) / n
		var wob: float = sin(u * PI) * amp * sin(_t * (40.0 if taut else 14.0) + u * 6.0)
		pts.append(a + d * u + perp * wob)
	_bodies.draw_polyline(pts, Color(0, 0, 0, 0.35), w + 2.0, true)
	_bodies.draw_polyline(pts, col, w, true)


func _trait_levels() -> Dictionary:
	var out := {}
	var cap := int(sim.B["traits"]["cap"])
	for t in Growth.TRAITS:
		out[t] = Growth.stack(sim.traits, t, cap)
	return out


func _draw_glow_front() -> void:
	for s in sim.shots:
		Look.glow(_glow_front, s["pos"], s["r"] * 1.6, Color(0.8, 1.0, 0.6, 0.35))
	if sim.all_idle() and sim.whirl_t <= 0.0:
		Look.glow(_glow_front, Look.lure_tip(sim.pos, _vis_r, _angle), _vis_r * 0.45, Color(1.0, 0.95, 0.55, 0.35))
	for h in sim.hooks:
		if h.state != ArenaSim.HookState.IDLE:
			Look.glow(_glow_front, h.pos, 10.0 * sim.st["scale"], Color(1.0, 0.95, 0.6, 0.5))


# =============================================================================
# records (SaveGame slot 0)
# =============================================================================

var _records: Dictionary = {}


func _load_records() -> void:
	_records = Records.from_save(SaveGame.load_slot(0))


func _save_records(won: bool) -> void:
	_records = Records.add_run(_records, sim.time, sim.size, won)
	SaveGame.save_slot(0, _records)


func _records_line() -> String:
	return "Best time to eat the Leviathan: %s   -   biggest ever: size %.1f" % [
		Records.format_time(_records.get("best_win_time", -1.0)), float(_records.get("best_size", 0.0))]


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if sim != null and not sim.won and not autoplay:
		_records = Records.add_run(_records, sim.time, sim.size, false)
		SaveGame.save_slot(0, _records)
