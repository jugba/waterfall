extends Node3D
## "3D Arena (test)": the same game as scripts/game.gd, drawn in 3D. The rules are the shared
## ArenaSim on the XZ plane, driven by the shared ArenaDriver (same input mapping, buffers,
## hitstop and stepping as 2D), so both modes play identically for the same inputs. This view adds
## an angled perspective camera that pulls back as Morsel grows, low-poly primitive creatures,
## a sagging 3D hook line, and an underwater set (fog, god rays, glow, seabed, kelp, bubbles).
##
## Debug/capture (debug builds only): `-- --autoplay [--skip=SECONDS] [--frames=N] [--seed=N]`.

const TITLE_SCENE := "res://scenes/title.tscn"
const S := ArenaSpace.S
const PITCH_DEG := 55.0
const BASE_DIST := 3.8        # camera distance at the start size (world units)
const LINE_W := 0.022         # hook line half-width at the start size

var sim: ArenaSim
var driver: ArenaDriver
var bot: Bot = null
var seed_value := -1
var autoplay := false
var _quit_after := -1
var _frame := 0

@onready var camera: Camera3D = $Camera
@onready var hud: Hud = %Hud
@onready var pause_menu = $PauseMenu
@onready var world_env: WorldEnvironment = $WorldEnvironment

var seabed: Seabed3D
var morsel: Creature3D
var _creatures: Dictionary = {}   # enemy id -> Creature3D
var _ghosts: Array = []           # [{node, from, t}]
var _rings: Array = []            # [{node, mat, max, t}]
var _shots: Array = []            # pool of Node3D
var _heads: Array = []            # pool of hook heads
var _dots: Array = []             # aim preview
var _line_mesh: ImmediateMesh
var _line_shadow_mesh: ImmediateMesh
var _line_mat: StandardMaterial3D
var _fx: Node3D
var _lure_light: OmniLight3D
var _boss_light: OmniLight3D
var _sag: Array = []              # per hook: [sag, sag_vel]

# feel state
var _t := 0.0
var _trauma := 0.0
var _vis_r := 18.0
var _vis_rv := 0.0
var _squash := Vector2.ONE
var _squash_v := Vector2.ZERO
var _chomp := 0.0
var _hurt := 0.0
var _happy := 0.0
var _blink := 2.0
var _angle := 0.0
var _evis: Dictionary = {}        # enemy id -> {flash, pop, yaw}
var _line_flash := 0.0
var _yank_chain := 0
var _cam_k := 1.0
var _cam_target := Vector3.ZERO
var _died_this_step := false
var play_y := 0.2                 # height of the play plane (Morsel's centre); mouse rays hit this


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	autoplay = OS.is_debug_build() and args.has("--autoplay")
	if seed_value < 0:
		seed_value = randi()
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
	driver = ArenaDriver.new(sim)
	driver.stepped.connect(_handle_events)
	driver.auto_chose.connect(func(): hud.hide_evolution(); _handle_events())
	world_env.environment = Seabed3D.make_environment()
	_build_world()
	hud.sim = sim
	hud.world_to_screen = func(p: Vector2) -> Vector2: return _screen(p)
	hud.evolution_chosen.connect(_on_evolution_chosen)
	hud.continue_pressed.connect(func(): pass)
	hud.title_pressed.connect(func(): SceneChanger.change_to(TITLE_SCENE))
	hud.set_hint("Aim: mouse / right stick    Hook: left click / RT    Yank: hook again    Dodge: %s / A" % [
		Settings.binding_label(&"dodge")])
	_vis_r = sim.st["radius"]
	_cam_k = Growth.scale(sim.B, sim.size)
	_cam_target = ArenaSpace.to_world(sim.pos)
	_update_camera(0.0, true)
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	hud.banner("WAVE %d" % (sim.wave + 1) if sim.wave < sim.wave_count() else "BOSS",
		"Hook it. Reel it. Eat it. Grow.  (3D arena test)", 2.2)
	if sim.wave > 0:
		hud.set_hint("")
	_load_records()
	_sync_views(0.0)


func _build_world() -> void:
	seabed = Seabed3D.new()
	seabed.name = "Seabed3D"
	add_child(seabed)
	seabed.build(float(sim.B["arena_radius"]) * S)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-62, 25, 0)
	sun.light_color = Color(0.65, 0.85, 1.0)
	sun.light_energy = 0.9
	sun.shadow_enabled = false
	add_child(sun)
	_lure_light = OmniLight3D.new()
	_lure_light.name = "LureLight"
	_lure_light.light_color = Color(1.0, 0.93, 0.55)
	_lure_light.light_energy = 1.6
	_lure_light.omni_attenuation = 1.4
	add_child(_lure_light)
	_boss_light = OmniLight3D.new()
	_boss_light.name = "BossLight"
	_boss_light.light_color = Color(1.0, 0.9, 0.5)
	_boss_light.light_energy = 2.0
	_boss_light.visible = false
	add_child(_boss_light)
	_fx = Node3D.new()
	_fx.name = "FX"
	add_child(_fx)
	morsel = Creature3D.make("morsel")
	morsel.name = "Morsel"
	add_child(morsel)
	# hook line: a camera-facing ribbon, plus its faint shadow on the seabed
	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.vertex_color_use_as_albedo = true
	_line_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_mesh = ImmediateMesh.new()
	var li := MeshInstance3D.new()
	li.name = "HookLine"
	li.mesh = _line_mesh
	li.material_override = _line_mat
	li.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(li)
	_line_shadow_mesh = ImmediateMesh.new()
	var ls := MeshInstance3D.new()
	ls.name = "HookLineShadow"
	ls.mesh = _line_shadow_mesh
	ls.material_override = _line_mat
	add_child(ls)
	for i in 14:
		var d := MeshInstance3D.new()
		d.mesh = Kit3D.sphere(6, 3)
		d.material_override = Kit3D.flat(Color(1, 1, 1, 0.3))
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(d)
		_dots.append(d)


# =============================================================================
# input + stepping (shared driver)
# =============================================================================

func _input(event: InputEvent) -> void:
	driver.on_input_event(event)


func _read_input(d: ArenaDriver) -> InputFrame:
	return d.read_devices(mouse_sim(get_viewport().get_mouse_position()))


## Cursor -> sim position on the play plane (camera ray hit). Falls back to the player position
## (which keeps the current aim) if the ray misses the plane.
func mouse_sim(screen: Vector2) -> Vector2:
	var hit = ArenaSpace.screen_to_sim(camera, screen, play_y)
	return hit if hit != null else sim.pos


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	driver.bot = bot
	driver.poll_buttons()
	_died_this_step = false
	driver.tick(delta, hud.evolution_visible() or hud.win_visible(), _read_input)
	_update_feel(delta)
	_sync_views(delta)
	_frame += 1
	if _quit_after > 0 and _frame >= _quit_after:
		get_tree().quit()


func _on_evolution_chosen(i: int) -> void:
	hud.hide_evolution()
	sim.choose_evolution(i)
	_handle_events()


# =============================================================================
# events -> feel (same reactions as 2D; HUD + sound identical)
# =============================================================================

func _world(p: Vector2, y := -1.0) -> Vector3:
	return ArenaSpace.to_world(p, play_y if y < 0.0 else y)


func _screen(p: Vector2, y := -1.0) -> Vector2:
	return camera.unproject_position(_world(p, y))


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
				for s in _sag:
					s[0] = 0.28
					s[1] = 0.0
			"catch":
				_shake(0.22 if not ev["boss"] else 0.5)
				Sfx.play("catch", -2.0)
				_flash_enemy(ev["id"])
				_ring(p, 40.0 * k, Look.LINE)
				for s in _sag:
					s[1] -= 2.5  # the line snaps tight with a twang
				_burst(p, Color(1, 1, 1, 0.7), 8, ev.get("boss", false), true)
			"chain":
				Sfx.play("chain", -5.0, 1.3)
				_ring(ev["to"], 30.0 * k, Color("ffd166"))
			"yank":
				_yank_chain += 1
				Sfx.play("yank", -3.0, 1.0 + 0.06 * mini(_yank_chain, 8))
				_line_flash = 1.0
				_squash = Vector2(0.85, 1.12)
				_shake(0.08)
				for s in _sag:
					s[1] -= 1.2
			"eat":
				_on_eat(ev)
			"bite":
				_shake(0.7)
				_chomp = 1.0
				_happy = 0.6
				Sfx.play("chomp", 0.0, 0.6)
				Sfx.play("gulp", -2.0, 0.7)
				_burst(p, Look.KIND_COLORS["boss"].lightened(0.4), 40, true)
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
				_burst(p, Color("dfe7f5"), 10, false)
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
				_died_this_step = true
				hud.banner("GULP...", "You got eaten! Back to the start of wave %d." % (ev["wave"] + 1), 2.2, Color("ff8a95"))
				Sfx.play("death")
				_shake(0.8)
				_vis_r = sim.st["radius"]
			"dodge":
				Sfx.play("dodge", -6.0)
				_squash = Vector2(1.3, 0.8)
				_burst(p, Color(0.8, 0.95, 1.0, 0.6), 6, false, true)
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
	_shake(0.16 + 0.35 * ratio)
	_chomp = 1.0
	_happy = 0.45
	_squash = Vector2(1.35, 0.72)
	_vis_rv += sim.st["radius"] * 2.5 * (0.5 + ratio)
	Sfx.play("chomp", -1.0, clampf(1.3 - ratio * 0.6, 0.6, 1.4))
	if ratio > 0.6:
		Sfx.play("gulp", -3.0, 1.0)
	var col: Color = Look.KIND_COLORS[ev["kind"]]
	var mouth: Vector2 = sim.pos + (p - sim.pos).normalized() * sim.st["radius"]
	_burst(mouth, col, int(10 + 20 * ratio), ev["boss"])
	_burst(sim.pos, Color(0.85, 0.97, 1.0, 0.8), int(10 + 14 * ratio), ev["boss"], true)
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
	if _evis.has(id):
		_evis[id]["flash"] = 1.0


## Expanding flat ring on the play plane.
func _ring(p: Vector2, max_r: float, col: Color) -> void:
	var m := Kit3D.flat(col, true).duplicate() as StandardMaterial3D
	var mi := Kit3D.part(_fx, Kit3D.ring(0.07), m, _world(p, 0.06), Vector3.ONE * 0.01)
	_rings.append({"node": mi, "mat": m, "max": max_r * S, "t": 0.0, "c": col})


## One-shot particle burst. bubbles = rising white bubbles; otherwise coloured chunks.
func _burst(p: Vector2, col: Color, amount: int, big: bool, bubbles := false) -> void:
	var r: float = sim.st["radius"] * S
	var cp := CPUParticles3D.new()
	cp.position = _world(p, play_y)
	cp.one_shot = true
	cp.explosiveness = 0.9
	cp.amount = maxi(amount, 2)
	cp.lifetime = 1.1 if bubbles else 0.6
	cp.local_coords = false
	cp.direction = Vector3.UP
	cp.spread = 180.0 if not bubbles else 60.0
	var spd := r * (3.0 if big else 5.0)
	cp.initial_velocity_min = spd * 0.4
	cp.initial_velocity_max = spd
	cp.gravity = Vector3(0, r * 6.0, 0) if bubbles else Vector3(0, -r * 2.0, 0)
	cp.damping_min = r * 2.0
	cp.damping_max = r * 4.0
	cp.scale_amount_min = r * (0.04 if bubbles else 0.07)
	cp.scale_amount_max = r * (0.12 if bubbles else 0.18)
	cp.mesh = Kit3D.sphere(8, 4)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.8 if bubbles else 1.5
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if bubbles:
		m.rim_enabled = true
		m.rim = 1.0
	cp.material_override = m
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	cp.color_ramp = g
	_fx.add_child(cp)
	cp.emitting = true
	cp.finished.connect(cp.queue_free)


func _update_feel(delta: float) -> void:
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
		_evis[id]["pop"] = minf(1.0, _evis[id]["pop"] + delta * 5.0)
	_trauma = maxf(0.0, _trauma - delta * 1.8)
	_update_camera(delta, false)


## Angled ~55 degree perspective camera: follows with a little aim look-ahead, pulls back as
## Morsel grows (same curve as the 2D zoom), shakes with trauma.
## Camera distance for a world-scale factor k (1 at the start size). Slightly more than linear so
## the 3D view pulls back a bit further than the 2D zoom as Morsel grows (perspective crowds big bodies).
static func cam_distance(k: float) -> float:
	return BASE_DIST * pow(k, 1.15)


func _update_camera(delta: float, snap: bool) -> void:
	var look: Vector2 = sim.aim * sim.st["hook_range"] * 0.18
	var want := ArenaSpace.to_world(sim.pos + look)
	var kz := Growth.scale(sim.B, sim.size)
	if snap:
		_cam_target = want
		_cam_k = kz
	else:
		_cam_target = _cam_target.lerp(want, 1.0 - exp(-8.0 * delta))
		_cam_k = lerpf(_cam_k, kz, 1.0 - exp(-2.5 * delta))
	var dist := cam_distance(_cam_k)
	var pitch := deg_to_rad(PITCH_DEG)
	var aim_at := _cam_target + Vector3(0, play_y, 0)   # look at the play plane, so Morsel stays centred
	camera.position = aim_at + Vector3(0, sin(pitch) * dist, cos(pitch) * dist)
	camera.look_at(aim_at, Vector3.UP)
	var sh := _trauma * _trauma * 0.045 * dist
	camera.h_offset = sin(_t * 71.0) * sh
	camera.v_offset = cos(_t * 63.0) * sh
	var env := world_env.environment
	if env != null:
		env.fog_density = 0.32 / dist
	if seabed != null:
		seabed.follow(_cam_target, dist, _t)


# =============================================================================
# sync 3D nodes to the sim
# =============================================================================

func _trait_levels() -> Dictionary:
	var out := {}
	var cap := int(sim.B["traits"]["cap"])
	for t in Growth.TRAITS:
		out[t] = Growth.stack(sim.traits, t, cap)
	return out


func _sync_views(delta: float) -> void:
	var r := maxf(_vis_r, 1.0) * S
	play_y = r * 1.15
	_sync_morsel(r)
	_sync_enemies(delta)
	_sync_ghosts(delta)
	_sync_hooks()
	_sync_shots()
	_sync_rings(delta)
	_sync_aim_dots()


func _sync_morsel(r: float) -> void:
	var vel_stretch := clampf(sim.vel.length() / maxf(1.0, sim.st["speed"]) * 0.08, 0.0, 0.25)
	var sq := _squash * Vector2(1.0 + vel_stretch, 1.0 - vel_stretch * 0.6)
	var bob := sin(_t * 2.2) * r * 0.06
	morsel.place(ArenaSpace.to_world(sim.pos), r, play_y + bob, _angle, Vector3(sq.x, sq.y, lerpf(1.0, sq.y, 0.5)))
	morsel.set_traits(_trait_levels())
	var eyes := "normal"
	if _hurt > 0.4:
		eyes = "hurt"
	elif _happy > 0.0:
		eyes = "happy"
	elif _blink < 0.0:
		eyes = "closed"
	morsel.set_eyes(eyes, Vector3(1, 0.15, 0))
	morsel.set_flash(0.0, _hurt * 0.6)
	var mouth_open := maxf(0.55 if sim.any_attached() else 0.0, sin(_chomp * PI) * 0.9)
	(morsel.p["mouth"] as Node3D).scale = Vector3(0.2 + 0.12 * mouth_open, 0.06 + 0.4 * mouth_open, 0.4)
	var lure_on := sim.all_idle() and sim.whirl_t <= 0.0
	(morsel.p["lure"] as Node3D).visible = lure_on
	# the lure light rides the hook when it is thrown
	var lp := morsel.lure_world()
	if not lure_on and not sim.hooks.is_empty():
		lp = _hook_world(sim.hooks[0])
	_lure_light.position = lp
	_lure_light.omni_range = maxf(0.8, r * 7.0)


func _enemy_height(e) -> float:
	var r: float = e.radius * S
	match e.kind:
		"spitter":
			return r * 1.6 + sin(_t * 1.6 + e.id) * r * 0.15
		"boss":
			return r * 0.95 + sin(_t * 1.1) * r * 0.05
	return r * 1.05 + sin(_t * 2.6 + e.id) * r * 0.08


func _sync_enemies(delta: float) -> void:
	var alive := {}
	for e in sim.enemies:
		alive[e.id] = true
		var c: Creature3D = _creatures.get(e.id)
		if c == null:
			c = Creature3D.make(e.kind)
			add_child(c)
			_creatures[e.id] = c
			_evis[e.id] = {"flash": 0.0, "pop": 0.0 if sim.time > 0.1 else 1.0, "yaw": (sim.pos - e.pos).angle()}
		_pose_enemy(c, e, _evis[e.id], delta)
	_boss_light.visible = false
	for id in _creatures.keys():
		if alive.has(id):
			continue
		var c: Creature3D = _creatures[id]
		_creatures.erase(id)
		_evis.erase(id)
		if _died_this_step:
			c.queue_free()
		else:  # eaten: slide into the mouth and shrink
			c.marker.visible = false
			c.stars.visible = false
			_ghosts.append({"node": c, "from": c.position + Vector3(0, c.height, 0), "r": c.radius, "t": 0.0})
	if sim.boss != null and _creatures.has(sim.boss.id):
		var bc: Creature3D = _creatures[sim.boss.id]
		_boss_light.visible = true
		_boss_light.position = bc.rig.global_transform * (bc.p["bulb_pos"] as Vector3)
		_boss_light.omni_range = bc.radius * 4.0
		_boss_light.light_color = Color(1.0, 0.35, 0.4) if sim.boss.tell > 0.0 else Color(1.0, 0.9, 0.5)


func _pose_enemy(c: Creature3D, e, v: Dictionary, delta: float) -> void:
	var r: float = e.radius * S * (0.25 + 0.75 * float(v["pop"]))
	var hooked: bool = e.state == ArenaSim.EState.HOOKED
	var stunned: bool = e.state == ArenaSim.EState.STUNNED
	var pos: Vector2 = e.pos
	if hooked:
		pos += Vector2(sin(_t * 61.0), cos(_t * 53.0)) * e.radius * 0.07
	if e.tell > 0.0:
		pos += Vector2(sin(_t * 80.0), 0).rotated(e.facing) * e.radius * 0.06
	var to_player: Vector2 = sim.pos - e.pos
	var heading: float = e.vel.angle() if e.vel.length() > 5.0 else to_player.angle()
	match e.kind:
		"shellback":
			heading = e.facing
		"darter":
			if e.dashing > 0.0:
				heading = e.dash_dir.angle()
		"boss", "spitter", "puffer":
			heading = to_player.angle()
	v["yaw"] = lerp_angle(float(v["yaw"]), heading, 1.0 - exp(-10.0 * delta)) if delta > 0.0 else heading
	var sq := Vector3.ONE
	match e.kind:
		"nibbler":
			var w := sin(_t * 9.0 + e.id) * 0.06
			sq = Vector3(1.0 + w, 1.0 - w, 1.0)
			(c.p["tail"] as Node3D).rotation.y = sin(_t * 12.0 + e.id) * 0.5
		"darter":
			sq = Vector3(1.25, 0.85, 0.9) if e.dashing > 0.0 else Vector3.ONE
		"spitter":
			var sw := 1.0 + (0.18 if e.tell > 0.0 else 0.04 * sin(_t * 4.0 + e.id))
			sq = Vector3(sw, sw * (0.9 + 0.1 * sin(_t * 3.0 + e.id)), sw)
			var tent: Node3D = c.p["tentacles"]
			for i in tent.get_child_count():
				(tent.get_child(i) as Node3D).rotation = Vector3(sin(_t * 3.0 + i) * 0.35, 0, cos(_t * 2.6 + i * 1.7) * 0.35)
			((c.p["pool"] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color(0.78, 0.5, 1.0, 0.8 if e.tell > 0.0 else 0.4)
		"shellback":
			var open := sim.shell_open(e)
			var shell: Node3D = c.p["shell"]
			shell.position = Vector3(-0.1, 0.45, 0) if open else Vector3.ZERO
			shell.rotation = Vector3(0, 0, 0.9) if open else Vector3.ZERO
			(c.p["mouth"] as Node3D).visible = open
		"puffer":
			var sp: bool = e.spiky
			var s := 1.15 if sp else 0.9
			sq = Vector3.ONE * s
			var spikes: Node3D = c.p["spikes"]
			spikes.scale = Vector3.ONE * (1.25 if sp else 0.8)
			spikes.rotation.y = _t * (0.8 if sp else 0.2)
			var sm: Material = c.p["spike_hot"] if sp else c.p["spike_calm"]
			for n in c.p["spike_list"]:
				(n as MeshInstance3D).material_override = sm
		"boss":
			var mo := 0.55 + 0.25 * sin(_t * 2.0) + (0.3 if e.tell > 0.0 else 0.0)
			(c.p["mouth"] as Node3D).scale = Vector3(1.0, mo, 1.0)
			var bm: StandardMaterial3D = c.p["bulb_mat"]
			var lc := Color("ff5d73") if e.tell > 0.0 else Look.LURE
			bm.albedo_color = lc
			bm.emission = lc
			Kit3D.set_halo(c.p["halo"], Color(lc, 0.7 + 0.15 * sin(_t * 4.0)))
	c.place(ArenaSpace.to_world(pos), r, _enemy_height(e), float(v["yaw"]), sq)
	# expressions (same rules as 2D)
	var eyes := "wide" if hooked else ("angry" if e.tell > 0.0 or (e.kind == "puffer" and e.spiky) or e.is_boss else "normal")
	if stunned:
		eyes = "closed"
	var look_world := Vector3(to_player.x, 0.0, to_player.y).normalized()
	var local_look: Vector3 = (c.rig.global_transform.basis.inverse() * look_world).normalized()
	c.set_eyes(eyes, local_look + Vector3(0, 0.2, 0))
	c.set_flash(float(v["flash"]))
	c.set_stunned(stunned, _t + e.id)
	# readability: red ring = too big to hook, faint white ring = hookable and in range
	var hookable := sim.hookable(e)
	var near: bool = e.pos.distance_to(sim.pos) < sim.st["hook_range"] + e.radius
	c.marker.visible = not hooked and (not hookable or near)
	if c.marker.visible:
		c.marker.material_override = Kit3D.flat(Color(1, 0.3, 0.35, 0.75)) if not hookable else Kit3D.flat(Color(1, 1, 1, 0.3))


func _sync_ghosts(delta: float) -> void:
	var mouth := morsel.mouth_world()
	var keep: Array = []
	for g in _ghosts:
		g["t"] += delta / 0.18
		var gt: float = g["t"]
		var node: Creature3D = g["node"]
		if gt >= 1.0:
			node.queue_free()
			continue
		var at: Vector3 = (g["from"] as Vector3).lerp(mouth, gt * gt)
		node.position = Vector3(at.x, 0.0, at.z)
		node.rig.position.y = at.y
		var s: float = float(g["r"]) * (1.0 - gt) * (1.0 + 0.3 * sin(gt * PI))
		node.rig.scale = Vector3.ONE * maxf(s, 0.001)
		node.shadow.scale = Vector3.ONE * maxf(s, 0.001)
		keep.append(g)
	_ghosts = keep


func _hook_world(h) -> Vector3:
	if h.state == ArenaSim.HookState.ATTACHED and h.enemy != null and _creatures.has(h.enemy.id):
		var c: Creature3D = _creatures[h.enemy.id]
		return Vector3(c.position.x, c.height, c.position.z)
	return _world(h.pos, play_y)


func _sync_hooks() -> void:
	_line_mesh.clear_surfaces()
	_line_shadow_mesh.clear_surfaces()
	var k: float = sim.st["scale"]
	var tip := morsel.lure_world()
	var segs: Array = []   # [from, to, attached, colour]
	for h in sim.hooks:
		if h.state == ArenaSim.HookState.IDLE:
			continue
		var from := tip
		var gold := false
		if h.chain_from != null and sim.enemies.has(h.chain_from) and _creatures.has(h.chain_from.id):
			var cc: Creature3D = _creatures[h.chain_from.id]
			from = Vector3(cc.position.x, cc.height, cc.position.z)
			gold = true
		segs.append([from, _hook_world(h), h.state == ArenaSim.HookState.ATTACHED, gold, h])
	if sim.whirl_t > 0.0:
		var reach: float = sim.st["hook_range"] * float(sim.B["evolution"]["whirl_range_mult"])
		var wtip: Vector2 = sim.pos + Vector2.from_angle(sim.whirl_angle) * reach
		segs.append([tip, _world(wtip, play_y), true, false, null])
	while _sag.size() < segs.size():
		_sag.append([0.25, 0.0])
	var line_col := Look.LINE.lerp(Color.WHITE, _line_flash)
	var w := LINE_W * k * (1.0 + _line_flash * 0.8)
	var cam_pos := camera.global_position
	var head_i := 0
	for i in segs.size():
		var sgm: Array = segs[i]
		var a: Vector3 = sgm[0]
		var b: Vector3 = sgm[1]
		var taut: bool = sgm[2]
		# sag spring: slack while flying, tight while something is on the line
		var s: Array = _sag[i]
		var target := 0.02 if taut else 0.22
		s[1] += ((target - s[0]) * 90.0 - s[1] * 9.0) * (1.0 / 60.0)
		s[0] = clampf(s[0] + s[1] * (1.0 / 60.0), -0.08, 0.4)
		var pts := _rope(a, b, s[0], taut)
		var col := Color("ffd166") if sgm[3] else line_col
		_ribbon(_line_mesh, pts, w, col, cam_pos)
		var shadow_pts: Array = []
		for pnt in pts:
			shadow_pts.append(Vector3(pnt.x, 0.03, pnt.z))
		_ribbon(_line_shadow_mesh, shadow_pts, w * 1.3, Color(0, 0, 0, 0.35), cam_pos + Vector3(0, 50, 0))
		if not taut or sgm[4] == null:
			_place_head(head_i, b, b - a, k)
			head_i += 1
	for j in range(head_i, _heads.size()):
		(_heads[j] as Node3D).visible = false


## Rope points from a to b: a parabolic sag downward plus a small wobble (fast and tight when taut).
func _rope(a: Vector3, b: Vector3, sag: float, taut: bool) -> Array:
	var pts: Array = []
	var n := 16
	var d := b - a
	var dl := d.length()
	var side := d.cross(Vector3.UP).normalized() if dl > 0.001 else Vector3.RIGHT
	var amp: float = (dl * 0.03) if not taut else (0.004 + 0.002 * sin(_t * 40.0)) * sim.st["scale"]
	for i in n + 1:
		var u := float(i) / n
		var bell := 4.0 * u * (1.0 - u)
		var wob: float = sin(u * PI) * amp * sin(_t * (40.0 if taut else 12.0) + u * 6.0)
		var pt: Vector3 = a + d * u + Vector3.DOWN * sag * dl * bell * 0.5 + side * wob
		pt.y = maxf(pt.y, 0.03)
		pts.append(pt)
	return pts


func _ribbon(mesh: ImmediateMesh, pts: Array, w: float, col: Color, cam_pos: Vector3) -> void:
	if pts.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in pts.size():
		var pt: Vector3 = pts[i]
		var tg: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var to_cam := (cam_pos - pt).normalized()
		var off := tg.cross(to_cam).normalized() * w
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(pt - off)
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(pt + off)
	mesh.surface_end()


func _place_head(i: int, at: Vector3, dir: Vector3, k: float) -> void:
	while _heads.size() <= i:
		var hn := Node3D.new()
		add_child(hn)
		Kit3D.part(hn, Kit3D.sphere(8, 4), Kit3D.mat(Look.LURE, 4.0, 0.2), Vector3(0.6, 0, 0), Vector3.ONE * 0.5)
		Kit3D.spike(hn, Kit3D.mat(Look.LINE, 0.5, 0.2), Vector3(-0.2, 0, 0), Vector3(-1, -0.6, 0), 0.9, 0.22)
		Kit3D.part(hn, Kit3D.ring(0.25), Kit3D.mat(Look.LINE, 0.5, 0.2), Vector3(-0.3, 0, 0), Vector3(0.6, 1.0, 0.6),
			Basis(Vector3.RIGHT, PI * 0.5))
		Kit3D.halo(hn, Color(1.0, 0.95, 0.5, 0.55), 2.2, Vector3(0.6, 0, 0))
		_heads.append(hn)
	var hn: Node3D = _heads[i]
	hn.visible = true
	hn.position = at
	hn.rotation = Vector3(0, ArenaSpace.yaw(Vector2(dir.x, dir.z).angle()), 0)
	hn.scale = Vector3.ONE * 0.09 * k


func _sync_shots() -> void:
	while _shots.size() < sim.shots.size():
		var sn := Node3D.new()
		add_child(sn)
		Kit3D.part(sn, Kit3D.sphere(8, 4), Kit3D.mat(Color("b8ff6a"), 2.5, 0.2), Vector3.ZERO, Vector3.ONE)
		Kit3D.halo(sn, Color(0.7, 1.0, 0.4, 0.5), 3.5)
		_shots.append(sn)
	for i in _shots.size():
		var sn: Node3D = _shots[i]
		sn.visible = i < sim.shots.size()
		if sn.visible:
			var s: Dictionary = sim.shots[i]
			sn.position = _world(s["pos"], play_y)
			sn.scale = Vector3.ONE * float(s["r"]) * S


func _sync_rings(delta: float) -> void:
	var keep: Array = []
	for rg in _rings:
		rg["t"] += delta / 0.45
		var rt: float = rg["t"]
		var mi: MeshInstance3D = rg["node"]
		if rt >= 1.0:
			mi.queue_free()
			continue
		var rr: float = float(rg["max"]) * (0.3 + 0.7 * sqrt(rt))
		mi.scale = Vector3(rr, 1.0, rr)
		(rg["mat"] as StandardMaterial3D).albedo_color = Color(rg["c"], 1.0 - rt)
		keep.append(rg)
	_rings = keep


func aim_target():
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


func _sync_aim_dots() -> void:
	var dots_on := sim.all_idle() and not hud.evolution_visible()
	var mat := Kit3D.flat(Color(1, 1, 1, 0.3))
	if dots_on:
		var target = aim_target()
		if target != null:
			mat = Kit3D.flat(Color(0.6, 1.0, 0.65, 0.6)) if sim.hookable(target) else Kit3D.flat(Color(1.0, 0.4, 0.45, 0.6))
	var rng_len: float = sim.st["hook_range"]
	var k: float = sim.st["scale"]
	var n := _dots.size()
	for i in n:
		var d: MeshInstance3D = _dots[i]
		d.visible = dots_on and i >= 1
		if d.visible:
			d.position = _world(sim.pos + sim.aim * rng_len * float(i + 1) / n, play_y)
			d.scale = Vector3.ONE * 3.0 * k * S
			d.material_override = mat


# =============================================================================
# records (SaveGame slot 0, shared with 2D)
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
	if sim != null and not sim.won and not autoplay and not driver.script_input.is_valid():
		_records = Records.add_run(_records, sim.time, sim.size, false)
		SaveGame.save_slot(0, _records)
