class_name ArenaSim
extends RefCounted
## The whole game rules as a node-free fixed-step simulation (60 Hz): player movement + dodge,
## hooks (throw, catch, struggle, yank, eat), enemy AI, shots, waves, boss gating, traits and
## evolutions. The scene (scripts/view/arena.gd) feeds it an InputFrame per step and only draws
## its state and reacts to `events`. Tests and the pacing bot run thousands of steps per call.
## See memories/tech/platformer-controller-as-pure-fixed-step-sim-for-tests.

const DT := 1.0 / 60.0
const FORMS: Array[String] = ["multi", "chain", "whirl", "long"]
const FORM_MAX := 2

enum HookState { IDLE, OUT, BACK, ATTACHED }
enum EState { FREE, HOOKED, STUNNED }


class Hook:
	extends RefCounted
	var state: int = HookState.IDLE
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var travelled := 0.0
	var enemy = null          # Enemy while ATTACHED
	var chain_from = null     # Enemy this link chained from (visual only), or null


class Enemy:
	extends RefCounted
	var id := 0
	var kind := ""
	var trait_name := ""
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var size := 1.0
	var mass := 1.0
	var radius := 6.0
	var state: int = EState.FREE
	var facing := 0.0         # radians (shellback shell faces this way)
	var line_dist := 0.0
	var pull_vel := 0.0
	var phase := 0.0          # struggle / animation phase
	var stun_t := 0.0
	var contact_cd := 0.0
	var ai_t := 0.0           # per-archetype timer
	var tell := 0.0           # >0 while telegraphing an attack
	var dashing := 0.0
	var dash_dir := Vector2.ZERO
	var spiky := false
	var is_boss := false
	var ring_t := 0.0
	var wander := Vector2.ZERO
	var bites_left := 1
	var snap_dist := 0.0


var B: Dictionary
var rng := RandomNumberGenerator.new()
var time := 0.0

# --- player ---
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var mass := 1.0
var size := 3.0
var hp := 1.0
var st: Dictionary = {}       # derived stats (Growth.stats)
var traits := {"armour": 0, "speed": 0, "damage": 0, "pierce": 0}
var forms := {"multi": 0, "chain": 0, "whirl": 0, "long": 0}
var aim := Vector2.RIGHT
var move_dir := Vector2.ZERO
var dodge_t := 0.0
var dodge_cd := 0.0
var invuln := 0.0
var since_hit := 99.0
var whirl_t := 0.0
var whirl_angle := 0.0
var throw_cd := 0.0
var yank_cd := 0.0
var hooks: Array = []         # Array[Hook]
var meals := 0
var deaths := 0

# --- world ---
var enemies: Array = []       # Array[Enemy]
var shots: Array = []         # Array[Dictionary] {pos, vel, r, dmg, life}
var events: Array = []        # this step's events: {"type": String, ...}
var wave := 0
var wave_queue: Array = []
var spawn_t := 0.0
var boss = null
var boss_spawned_at := -1.0
var boss_hookable_at := -1.0
var first_evolution_at := -1.0
var evolution_times: Array = []
var won := false
var won_at := -1.0
var pending_choice: Array = []   # form ids offered; the sim is paused while non-empty
var evolutions_taken := 0
var checkpoint: Dictionary = {}
var waves_enabled := true        # tests switch waves off to set up exact situations
var _next_id := 1


func _init(balance: Dictionary = {}, seed_value := 1) -> void:
	B = balance if not balance.is_empty() else Balance.copy()
	rng.seed = seed_value
	mass = float(B["player"]["start_mass"])
	_recalc()
	hp = st["hp_max"]
	hooks = [Hook.new()]
	_start_wave(0)


# =============================================================================
# public API
# =============================================================================

func step(inp: InputFrame) -> void:
	events.clear()
	if not pending_choice.is_empty():
		return
	time += DT
	_timers()
	_move_player(inp)
	_hook_input(inp)
	_update_hooks()
	_update_enemies()
	_update_shots()
	_contacts()
	if waves_enabled:
		_update_waves()
	_check_boss_gate()
	_check_evolution()


func choose_evolution(index: int) -> void:
	if pending_choice.is_empty():
		return
	events.clear()  # the offer was already handled; only report the choice
	var form: String = pending_choice[clampi(index, 0, pending_choice.size() - 1)]
	forms[form] = mini(FORM_MAX, int(forms[form]) + 1)
	evolutions_taken += 1
	pending_choice = []
	_recalc()
	_reset_hooks()
	events.append({"type": "evolve", "form": form, "level": forms[form]})


func hookable(e) -> bool:
	return Growth.can_hook(B, size, e.size)


func alive_count(include_boss := false) -> int:
	var n := 0
	for e in enemies:
		if include_boss or not e.is_boss:
			n += 1
	return n


func any_attached() -> bool:
	for h in hooks:
		if h.state == HookState.ATTACHED:
			return true
	return false


func all_idle() -> bool:
	for h in hooks:
		if h.state != HookState.IDLE:
			return false
	return true


## A quiet arena for tests: no waves, no enemies.
func clear_for_test() -> void:
	waves_enabled = false
	enemies.clear()
	wave_queue.clear()
	shots.clear()


func boss_size_needed() -> float:
	return Growth.size_needed(B, float(B["enemies"]["boss"]["size"]))


func wave_count() -> int:
	return (B["waves"]["list"] as Array).size()


## Directly spawns an enemy (tests and the wave system use this).
func spawn(kind: String, at: Vector2, enemy_size: float):
	var d: Dictionary = B["enemies"][kind]
	var e := Enemy.new()
	e.id = _next_id
	_next_id += 1
	e.kind = kind
	e.trait_name = String(d.get("trait", ""))
	e.pos = at
	e.size = enemy_size
	e.mass = Growth.mass_from_size(B, enemy_size)
	e.radius = Growth.radius(B, enemy_size) * float(d.get("radius_mult", 1.0))
	e.facing = (pos - at).angle()
	e.phase = rng.randf() * TAU
	e.ai_t = rng.randf_range(0.5, 1.5)
	e.is_boss = kind == "boss"
	e.wander = Vector2.from_angle(rng.randf() * TAU)
	if kind == "puffer":
		e.ai_t = rng.randf_range(0.2, float(d["calm_time"]))
	if e.is_boss:
		e.bites_left = int(d.get("bites", 1))
		e.ai_t = float(d["charge_every"])
		e.ring_t = float(d["ring_every"]) * 0.6
	enemies.append(e)
	return e


# =============================================================================
# player
# =============================================================================

func _recalc() -> void:
	size = Growth.size_from_mass(B, mass)
	var old_max: float = st.get("hp_max", 0.0)
	st = Growth.stats(B, size, traits, forms)
	if old_max > 0.0:
		hp += maxf(0.0, st["hp_max"] - old_max)  # growing heals the extra max HP


func _timers() -> void:
	dodge_cd = maxf(0.0, dodge_cd - DT)
	invuln = maxf(0.0, invuln - DT)
	throw_cd = maxf(0.0, throw_cd - DT)
	yank_cd = maxf(0.0, yank_cd - DT)
	since_hit += DT
	if since_hit > float(B["player"]["regen_delay"]):
		hp = minf(st["hp_max"], hp + st["hp_max"] * float(B["player"]["regen_frac_per_s"]) * DT)


func _move_player(inp: InputFrame) -> void:
	var p: Dictionary = B["player"]
	move_dir = inp.move.limit_length(1.0)
	if inp.aim.length() > 0.01:
		aim = inp.aim.normalized()
	var speed: float = st["speed"] * (0.72 if any_attached() else 1.0)
	if inp.dodge_pressed and dodge_cd <= 0.0 and dodge_t <= 0.0:
		var dir := move_dir.normalized() if move_dir.length() > 0.1 else aim
		vel = dir * st["speed"] * float(p["dodge_speed_mult"])
		dodge_t = float(p["dodge_time"])
		invuln = maxf(invuln, float(p["dodge_invuln"]))
		dodge_cd = st["dodge_cooldown"]
		events.append({"type": "dodge", "pos": pos, "dir": dir})
		if int(forms["whirl"]) > 0 and all_idle():
			whirl_t = float(B["evolution"]["whirl_time"])
			whirl_angle = aim.angle()
			events.append({"type": "whirl", "pos": pos})
	if dodge_t > 0.0:
		dodge_t -= DT
	else:
		var target := move_dir * speed
		vel = vel.lerp(target, 1.0 - exp(-float(p["accel"]) * DT))
	pos += vel * DT
	var limit: float = float(B["arena_radius"]) - st["radius"]
	if pos.length() > limit:
		pos = pos.normalized() * limit
		var n := pos.normalized()
		vel -= n * maxf(0.0, vel.dot(n))


func damage_player(amount: float, source := "") -> void:
	if invuln > 0.0 or amount <= 0.0:
		return
	var dealt := amount * float(st["damage_taken"])
	hp -= dealt
	invuln = float(B["player"]["invuln_after_hit"])
	since_hit = 0.0
	events.append({"type": "hurt", "amount": dealt, "source": source, "pos": pos})
	if hp <= 0.0:
		_die()


func _die() -> void:
	deaths += 1
	events.append({"type": "death", "pos": pos, "wave": wave})
	mass = checkpoint["mass"]
	traits = checkpoint["traits"].duplicate()
	forms = checkpoint["forms"].duplicate()
	evolutions_taken = checkpoint["evolutions_taken"]
	st = {}
	_recalc()
	hp = st["hp_max"]
	invuln = 1.5
	var keep: Array = []
	for e in enemies:
		if e.is_boss:
			e.state = EState.FREE
			e.pos = pos + (e.pos - pos).normalized() * 900.0 * st["scale"]
			keep.append(e)
	enemies = keep
	shots.clear()
	_reset_hooks()
	_build_queue(wave)


# =============================================================================
# hooks
# =============================================================================

func _reset_hooks() -> void:
	for h in hooks:
		if h.state == HookState.ATTACHED and h.enemy != null and is_instance_valid(h.enemy):
			h.enemy.state = EState.STUNNED
			h.enemy.stun_t = 0.5
	var n := 1 + 2 * int(forms["multi"])
	hooks = []
	for i in n:
		hooks.append(Hook.new())
	whirl_t = 0.0


func _hook_input(inp: InputFrame) -> void:
	if not inp.hook_pressed:
		return
	if any_attached():
		if yank_cd <= 0.0:
			_yank()
	elif all_idle() and throw_cd <= 0.0 and whirl_t <= 0.0:
		throw_hooks(aim)


func throw_hooks(dir: Vector2) -> void:
	dir = dir.normalized()
	var n := hooks.size()
	var spread := deg_to_rad(float(B["evolution"]["multi_spread_deg"]))
	for i in n:
		var h: Hook = hooks[i]
		var a := dir.angle() + (i - (n - 1) * 0.5) * spread
		var d := Vector2.from_angle(a)
		h.state = HookState.OUT
		h.pos = pos + d * st["radius"]
		h.vel = d * st["hook_speed"]
		h.travelled = 0.0
		h.enemy = null
		h.chain_from = null
	throw_cd = float(B["hook"]["throw_cooldown"])
	events.append({"type": "throw", "pos": pos, "dir": dir, "count": n})


func _yank() -> void:
	yank_cd = float(B["hook"]["yank_cooldown"])
	for h in hooks:
		if h.state == HookState.ATTACHED and h.enemy != null:
			var ratio: float = h.enemy.mass / mass
			h.enemy.pull_vel += st["yank"] / (0.4 + minf(ratio, 3.0))
	events.append({"type": "yank", "pos": pos})


func _update_hooks() -> void:
	# whirl: one hook orbits at full length during the dodge-whirl and snags whatever it touches
	if whirl_t > 0.0:
		whirl_t -= DT
		whirl_angle += TAU * float(B["evolution"]["whirl_turns_per_s"]) * DT
		var reach: float = st["hook_range"] * float(B["evolution"]["whirl_range_mult"])
		var max_catch := 2 * int(forms["whirl"])
		var tip := pos + Vector2.from_angle(whirl_angle) * reach
		var caught := _attached_count()
		for e in enemies:
			if caught >= max_catch:
				break
			if e.state == EState.HOOKED or not hookable(e) or (e.kind == "puffer" and e.spiky and not st["spike_proof"]):
				continue
			# the whole line sweeps: anything within the swept segment is snagged
			var closest := Geometry2D.get_closest_point_to_segment(e.pos, pos, tip)
			if closest.distance_to(e.pos) <= e.radius + st["hook_radius"]:
				var h: Hook = _free_hook()
				if h == null:
					h = Hook.new()
					hooks.append(h)
				h.pos = e.pos
				if _try_attach(h, e, false, false):
					caught += 1
		if whirl_t <= 0.0:
			events.append({"type": "whirl_end"})
	for h in hooks:
		match h.state:
			HookState.OUT:
				h.pos += h.vel * DT
				h.travelled += h.vel.length() * DT
				for e in enemies:
					if e.state == EState.HOOKED:
						continue
					if e.kind == "darter" and e.state == EState.FREE and e.dashing <= 0.0 and e.tell <= 0.0 \
							and e.contact_cd <= 0.0 and h.pos.distance_to(e.pos) < e.radius + 110.0 * st["scale"]:
						e.contact_cd = 0.9  # reuse as an evade cooldown
						if rng.randf() < float(B["enemies"]["darter"].get("evade_chance", 0.0)):
							var side: Vector2 = h.vel.normalized().orthogonal() * (1.0 if rng.randf() < 0.5 else -1.0)
							e.vel = side * float(B["enemies"]["darter"]["dash_speed"]) * st["scale"]
							e.dashing = 0.0
							events.append({"type": "evade", "pos": e.pos, "id": e.id})
					if h.pos.distance_to(e.pos) <= e.radius + st["hook_radius"]:
						_try_attach(h, e, true)
						break
				if h.state == HookState.OUT and h.travelled >= st["hook_range"]:
					h.state = HookState.BACK
			HookState.BACK:
				var to: Vector2 = pos - h.pos
				var stepd: float = st["return_speed"] * DT
				if to.length() <= maxf(stepd, st["radius"]):
					h.state = HookState.IDLE
					h.pos = pos
				else:
					h.pos += to.normalized() * stepd
			HookState.ATTACHED:
				if h.enemy == null or not enemies.has(h.enemy):
					h.state = HookState.IDLE
					h.enemy = null
				else:
					h.pos = h.enemy.pos
			HookState.IDLE:
				h.pos = pos
	# extra hooks made by chain/whirl go away once idle (keep the base count)
	var base_n := 1 + 2 * int(forms["multi"])
	if hooks.size() > base_n and whirl_t <= 0.0:
		var keep: Array = []
		for h in hooks:
			if h.state != HookState.IDLE or keep.size() < base_n:
				keep.append(h)
		hooks = keep


func _attached_count() -> int:
	var n := 0
	for h in hooks:
		if h.state == HookState.ATTACHED:
			n += 1
	return n


func _free_hook():
	for h in hooks:
		if h.state == HookState.IDLE:
			return h
	return null


## Returns true if the hook latched on. Otherwise emits why (too_big / clang / spiked) and bounces.
func _try_attach(h: Hook, e, allow_chain: bool, check_shell := true) -> bool:
	if not hookable(e):
		events.append({"type": "too_big", "pos": e.pos, "need": Growth.size_needed(B, e.size),
			"boss": e.is_boss})
		h.state = HookState.BACK
		return false
	if check_shell and e.kind == "shellback" and not st["pierce"] and _shell_blocks(e, h.pos):
		events.append({"type": "clang", "pos": h.pos})
		h.state = HookState.BACK
		e.stun_t = 0.0
		return false
	if e.kind == "puffer" and e.spiky and not st["spike_proof"]:
		events.append({"type": "spiked", "pos": h.pos})
		h.state = HookState.BACK
		invuln = 0.0
		damage_player(float(B["hook"]["spike_damage"]) * st["scale"], "spikes")
		return false
	h.state = HookState.ATTACHED
	h.enemy = e
	e.state = EState.HOOKED
	e.line_dist = pos.distance_to(e.pos)
	e.snap_dist = maxf(st["hook_range"] * float(B["hook"]["snap_factor"]), e.line_dist * 1.2)
	e.pull_vel = 0.0
	e.tell = 0.0
	e.dashing = 0.0
	events.append({"type": "catch", "pos": e.pos, "kind": e.kind, "boss": e.is_boss, "id": e.id})
	if allow_chain and int(forms["chain"]) > 0:
		var last = e
		for i in int(forms["chain"]) + 1:
			var nxt = _chain_target(last)
			if nxt == null:
				break
			var link := Hook.new()
			link.pos = nxt.pos
			link.chain_from = last
			hooks.append(link)
			if not _try_attach(link, nxt, false, false):
				break
			events.append({"type": "chain", "from": last.pos, "to": nxt.pos})
			last = nxt
	return true


func _chain_target(from):
	var best = null
	var best_d: float = st["hook_range"] * float(B["evolution"]["chain_range_mult"])
	for e in enemies:
		if e == from or e.state == EState.HOOKED or e.is_boss or not hookable(e):
			continue
		if e.kind == "puffer" and e.spiky and not st["spike_proof"]:
			continue
		var d: float = e.pos.distance_to(from.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func shell_open(e) -> bool:
	return e.kind == "shellback" and (e.tell > 0.0 or e.dashing > 0.0)


## Shellbacks block hooks that arrive inside their front shell cone.
func _shell_blocks(e, hit_pos: Vector2) -> bool:
	if shell_open(e):
		return false
	var cone := deg_to_rad(float(B["enemies"]["shellback"]["shell_cone_deg"]))
	var from_dir: float = (hit_pos - e.pos).angle()
	return absf(angle_difference(e.facing, from_dir)) < cone * 0.5


func _eat(e) -> void:
	var before := size
	mass += Growth.meal_mass(B, e.kind, e.size, size)
	meals += 1
	var gained_trait := ""
	if e.trait_name != "":
		traits[e.trait_name] = int(traits[e.trait_name]) + 1
		gained_trait = e.trait_name
	_recalc()
	hp = minf(st["hp_max"], hp + st["hp_max"] * float(B["player"]["heal_on_eat"]))
	enemies.erase(e)
	for h in hooks:
		if h.enemy == e:
			h.state = HookState.IDLE
			h.enemy = null
			h.pos = pos
	events.append({"type": "eat", "pos": e.pos, "kind": e.kind, "boss": e.is_boss,
		"size_before": before, "size_after": size, "trait": gained_trait,
		"enemy_size": e.size, "enemy_radius": e.radius})
	if gained_trait != "":
		events.append({"type": "trait", "trait": gained_trait, "stacks": traits[gained_trait]})
	if st["shockwave"] > 0.0:
		for o in enemies:
			if o.state != EState.HOOKED and not o.is_boss and o.pos.distance_to(pos) < st["shockwave"] + o.radius:
				o.state = EState.STUNNED
				o.stun_t = 0.6
				o.vel = (o.pos - pos).normalized() * 500.0 * st["scale"]
		events.append({"type": "shockwave", "pos": pos, "radius": st["shockwave"]})
	if e.is_boss:
		won = true
		won_at = time
		boss = null
		events.append({"type": "win", "time": time})


# =============================================================================
# enemies
# =============================================================================

func _update_enemies() -> void:
	var k: float = st["scale"]
	var hk: Dictionary = B["hook"]
	for e in enemies.duplicate():
		e.contact_cd = maxf(0.0, e.contact_cd - DT)
		e.phase += DT
		var d: Dictionary = B["enemies"][e.kind]
		if e.kind == "puffer":
			e.ai_t -= DT
			if e.ai_t <= 0.0:
				e.spiky = not e.spiky
				e.ai_t = float(d["spiky_time"] if e.spiky else d["calm_time"])
				events.append({"type": "puff" if e.spiky else "unpuff", "pos": e.pos, "id": e.id})
		match e.state:
			EState.HOOKED:
				_hooked_step(e, hk)
				continue
			EState.STUNNED:
				e.stun_t -= DT
				e.vel = e.vel.lerp(Vector2.ZERO, 1.0 - exp(-5.0 * DT))
				if e.stun_t <= 0.0:
					e.state = EState.FREE
			EState.FREE:
				var ek := k if not e.is_boss else Growth.scale(B, e.size) * 0.55
				var want := _ai(e, d, ek)
				var rate := 4.0 if e.dashing <= 0.0 else 12.0
				e.vel = e.vel.lerp(want, 1.0 - exp(-rate * DT))
		e.pos += e.vel * DT
		var lim: float = float(B["arena_radius"]) - e.radius
		if e.pos.length() > lim:
			e.pos = e.pos.normalized() * lim
	# soft separation so packs don't stack into one blob
	var n := enemies.size()
	for i in n:
		var a = enemies[i]
		for j in range(i + 1, n):
			var c = enemies[j]
			var dv: Vector2 = c.pos - a.pos
			var min_d: float = a.radius + c.radius
			var dd := dv.length_squared()
			if dd < min_d * min_d and dd > 0.0001:
				var dl := sqrt(dd)
				var push := dv / dl * (min_d - dl) * 0.5
				if a.state != EState.HOOKED:
					a.pos -= push
				if c.state != EState.HOOKED:
					c.pos += push


func _hooked_step(e, hk: Dictionary) -> void:
	var ratio: float = minf(e.mass / mass, 3.0)
	var struggle: float = (float(hk["struggle_base"]) + float(hk["struggle_per_mass_ratio"]) * ratio) \
		* st["hook_scale"] * float(B["enemies"][e.kind].get("struggle_mult", 1.0))
	# tugs in pulses so the line visibly fights; yanks between tugs feel like winning the fight
	var pulse := 0.55 + 0.9 * maxf(0.0, sin(e.phase * TAU * 1.3))
	e.pull_vel -= e.pull_vel * float(hk["pull_drag"]) * DT
	e.line_dist -= (st["auto_reel"] + e.pull_vel - struggle * pulse) * DT
	var dir: Vector2 = (e.pos - pos)
	dir = dir.normalized() if dir.length() > 0.01 else aim
	dir = dir.rotated(sin(e.phase * 5.0) * 0.9 * DT)
	if e.line_dist > e.snap_dist:
		for h in hooks:
			if h.enemy == e:
				h.state = HookState.BACK
				h.enemy = null
		e.state = EState.STUNNED
		e.stun_t = 0.4
		events.append({"type": "snap", "pos": e.pos})
		return
	var new_pos: Vector2 = pos + dir * e.line_dist
	e.vel = (new_pos - e.pos) / DT
	e.pos = new_pos
	if e.line_dist <= st["radius"] + e.radius * 0.35:
		if e.is_boss and e.bites_left > 1:
			_boss_bite(e)
		else:
			_eat(e)


## The boss takes several reels: each one tears off a chunk (you grow a little), and it breaks
## free, shrinks a bit and gets angrier. The last reel eats it.
func _boss_bite(e) -> void:
	e.bites_left -= 1
	var chunk := Growth.meal_mass(B, e.kind, e.size, size) * 0.5
	var before := size
	mass += chunk
	_recalc()
	for h in hooks:
		if h.enemy == e:
			h.state = HookState.IDLE
			h.enemy = null
			h.pos = pos
	e.state = EState.STUNNED
	e.stun_t = 1.2
	var away: Vector2 = (e.pos - pos).normalized()
	e.vel = away * 900.0 * st["scale"]
	e.size *= 0.93
	e.mass = Growth.mass_from_size(B, e.size)
	e.radius = Growth.radius(B, e.size) * float(B["enemies"]["boss"].get("radius_mult", 1.0))
	e.ring_t = minf(e.ring_t, 1.0)
	events.append({"type": "bite", "pos": e.pos, "bites_left": e.bites_left,
		"size_before": before, "size_after": size, "enemy_radius": e.radius})


func _ai(e, d: Dictionary, k: float) -> Vector2:
	var to: Vector2 = pos - e.pos
	var dist: float = to.length()
	var dir: Vector2 = to / maxf(dist, 0.001)
	var speed: float = float(d["speed"]) * k
	match e.kind:
		"nibbler":
			if rng.randf() < DT * 0.5:
				e.wander = Vector2.from_angle(rng.randf() * TAU)
			return (dir * 0.8 + e.wander * 0.7).normalized() * speed
		"darter":
			if e.dashing > 0.0:
				e.dashing -= DT
				return e.dash_dir * float(d["dash_speed"]) * k
			if e.tell > 0.0:
				e.tell -= DT
				if e.tell <= 0.0:
					e.dashing = 0.45
					e.dash_dir = dir
					events.append({"type": "dash", "pos": e.pos, "id": e.id})
				return Vector2.ZERO
			e.ai_t -= DT
			if e.ai_t <= 0.0 and dist < 520.0 * k:
				e.tell = 0.35
				e.ai_t = float(d["dash_every"]) * rng.randf_range(0.8, 1.3)
			var orbit := 230.0 * k
			var tangent: Vector2 = dir.orthogonal() * (1.0 if e.id % 2 == 0 else -1.0)
			return (tangent + dir * clampf((dist - orbit) / orbit, -1.0, 1.0)).normalized() * speed
		"shellback":
			# slow turner with a front shell; it opens up to bite (tell + lunge): hook it then, or flank it
			if e.dashing > 0.0:
				e.dashing -= DT
				return Vector2.from_angle(e.facing) * float(d["lunge_speed"]) * k
			if e.tell > 0.0:
				e.tell -= DT
				if e.tell <= 0.0:
					e.dashing = 0.4
					events.append({"type": "lunge", "pos": e.pos, "id": e.id})
				return Vector2.ZERO
			var turn := deg_to_rad(float(d["turn_deg_s"])) * DT
			e.facing = rotate_toward(e.facing, to.angle(), turn)
			e.ai_t -= DT
			if e.ai_t <= 0.0 and dist < e.radius + st["radius"] + 220.0 * k:
				e.tell = 0.65
				e.ai_t = float(d["lunge_every"]) * rng.randf_range(0.8, 1.3)
				events.append({"type": "shell_open", "pos": e.pos, "id": e.id})
			return Vector2.from_angle(e.facing) * speed * clampf(dist / (200.0 * k), 0.2, 1.0)
		"spitter":
			var keep := float(d["keep_range"]) * k
			var v: Vector2 = dir.orthogonal() * (0.7 if e.id % 2 == 0 else -0.7)
			if dist < keep * 0.8:
				v -= dir
			elif dist > keep * 1.2:
				v += dir
			if e.tell > 0.0:
				e.tell -= DT
				if e.tell <= 0.0:
					_fire(e.pos, dir, float(d["shot_speed"]) * k, float(d["dmg"]), 9.0 * k)
				return Vector2.ZERO
			e.ai_t -= DT
			if e.ai_t <= 0.0 and dist < keep * 1.6:
				e.tell = 0.45
				e.ai_t = float(d["fire_every"]) * rng.randf_range(0.85, 1.2)
			return v.normalized() * speed
		"puffer":
			return (dir + e.wander * 0.3).normalized() * speed * (0.5 if e.spiky else 1.0)
		"boss":
			return _boss_ai(e, d, dir, dist, k)
	return Vector2.ZERO


func _boss_ai(e, d: Dictionary, dir: Vector2, dist: float, k: float) -> Vector2:
	e.ring_t -= DT
	if e.ring_t <= 0.0:
		e.ring_t = float(d["ring_every"])
		var n := int(d["ring_shots"])
		for i in n:
			_fire(e.pos, Vector2.from_angle(TAU * i / n + e.phase), float(d["shot_speed"]) * k,
				float(d["dmg"]) * 0.6, 14.0 * k)
		events.append({"type": "boss_ring", "pos": e.pos})
	if e.dashing > 0.0:
		e.dashing -= DT
		return e.dash_dir * float(d["charge_speed"]) * k
	if e.tell > 0.0:
		e.tell -= DT
		if e.tell <= 0.0:
			e.dashing = 1.1
			e.dash_dir = dir
			events.append({"type": "boss_charge", "pos": e.pos})
		return Vector2.ZERO
	e.ai_t -= DT
	if e.ai_t <= 0.0:
		e.tell = 0.8
		e.ai_t = float(d["charge_every"])
	var orbit: float = e.radius + st["radius"] + 160.0 * k
	var tangent := dir.orthogonal()
	return (tangent + dir * clampf((dist - orbit) / orbit, -1.0, 1.0)).normalized() * float(d["speed"]) * k


func _fire(from: Vector2, dir: Vector2, speed: float, dmg: float, r: float) -> void:
	shots.append({"pos": from, "vel": dir * speed, "r": r, "dmg": dmg, "life": 4.5})
	events.append({"type": "spit", "pos": from})


func _update_shots() -> void:
	var keep: Array = []
	for s in shots:
		s["pos"] += s["vel"] * DT
		s["life"] -= DT
		if (s["pos"] as Vector2).distance_to(pos) < st["radius"] + float(s["r"]):
			if invuln <= 0.0:
				damage_player(float(s["dmg"]), "shot")
				continue
		if s["life"] > 0.0:
			keep.append(s)
	shots = keep


func _contacts() -> void:
	for e in enemies:
		if e.state == EState.HOOKED or e.contact_cd > 0.0:
			continue
		var dv: Vector2 = pos - e.pos
		var min_d: float = st["radius"] + e.radius
		if dv.length() < min_d:
			var n := dv.normalized() if dv.length() > 0.01 else Vector2.RIGHT
			# bodies push apart; the smaller one gets shoved more
			var share: float = e.mass / (e.mass + mass)
			pos += n * (min_d - dv.length()) * share
			e.pos -= n * (min_d - dv.length()) * (1.0 - share)
			if e.state == EState.STUNNED:
				continue
			var dmg: float = float(B["enemies"][e.kind]["dmg"]) * pow(e.size / 3.0, 0.7)
			if e.kind == "puffer" and e.spiky:
				dmg *= 1.5
			if e.dashing > 0.0:
				dmg *= 1.4
			e.contact_cd = 0.8
			if invuln <= 0.0:
				vel += n * 260.0 * st["scale"]
				damage_player(dmg, e.kind)


# =============================================================================
# waves, boss gate, evolutions
# =============================================================================

func _save_checkpoint() -> void:
	checkpoint = {"mass": mass, "traits": traits.duplicate(), "forms": forms.duplicate(),
		"evolutions_taken": evolutions_taken}


func _start_wave(i: int) -> void:
	wave = i
	_save_checkpoint()
	_build_queue(i)
	events.append({"type": "wave", "wave": i + 1})


func _build_queue(i: int) -> void:
	var defs: Dictionary
	if i < wave_count():
		defs = B["waves"]["list"][i]
	else:
		defs = B["waves"]["boss_minions"]
	wave_queue = []
	for kind in defs:
		for n in int(defs[kind]):
			wave_queue.append(kind)
	# deterministic shuffle
	for j in range(wave_queue.size() - 1, 0, -1):
		var r := rng.randi_range(0, j)
		var t = wave_queue[j]
		wave_queue[j] = wave_queue[r]
		wave_queue[r] = t
	spawn_t = 0.6
	if i == 0 and enemies.is_empty():
		# open with a few snacks already in view, so the first throw happens in the first seconds
		for n in mini(int(B["waves"].get("opening_burst", 0)), wave_queue.size()):
			var kind: String = wave_queue.pop_back()
			var d: Dictionary = B["enemies"][kind]
			var at := pos + Vector2.from_angle(TAU * n / 4.0 + 0.5) * rng.randf_range(170.0, 240.0)
			spawn(kind, at, size * rng.randf_range(float(d["rel"][0]), float(d["rel"][1])))


func _update_waves() -> void:
	var w: Dictionary = B["waves"]
	spawn_t -= DT
	if not wave_queue.is_empty():
		if spawn_t <= 0.0 and alive_count() < int(w["max_alive"]):
			var kind: String = wave_queue.pop_back()
			_spawn_near_player(kind)
			spawn_t = float(w["spawn_gap"])
		return
	var hookable_left := 0
	for e in enemies:
		if not e.is_boss and hookable(e):
			hookable_left += 1
	if hookable_left > int(w["advance_when_left"]):
		return
	if wave + 1 < wave_count():
		_start_wave(wave + 1)
		spawn_t = float(w.get("wave_break", 0.6))
	elif boss_spawned_at < 0.0:
		boss_spawned_at = time
		var a := rng.randf() * TAU
		var at: Vector2 = pos + Vector2.from_angle(a) * (900.0 * st["scale"] + 300.0)
		at = at.limit_length(float(B["arena_radius"]) - 300.0)
		boss = spawn("boss", at, float(B["enemies"]["boss"]["size"]))
		wave = wave_count()
		_save_checkpoint()
		events.append({"type": "boss", "pos": at, "need": boss_size_needed()})
		_build_queue(wave)
	elif not won:
		_build_queue(wave)  # the boss keeps summoning snacks so you can grow into it


func _spawn_near_player(kind: String) -> void:
	var d: Dictionary = B["enemies"][kind]
	var rel: Array = d["rel"]
	var s := size * rng.randf_range(float(rel[0]), float(rel[1]))
	var sd: Array = B["waves"].get("spawn_dist", [700.0, 900.0])
	var dist: float = rng.randf_range(float(sd[0]), float(sd[1])) * st["scale"]
	var at: Vector2 = pos + Vector2.from_angle(rng.randf() * TAU) * dist
	var lim := float(B["arena_radius"]) - Growth.radius(B, s) - 10.0
	if at.length() > lim:
		at = pos - (at - pos)  # mirror to the inside of the arena
		at = at.limit_length(lim)
	spawn(kind, at, s)
	events.append({"type": "spawn", "kind": kind, "pos": at})


func _check_boss_gate() -> void:
	if boss != null and boss_hookable_at < 0.0 and hookable(boss):
		boss_hookable_at = time
		events.append({"type": "boss_hookable"})


func _check_evolution() -> void:
	var at: Array = B["evolution"]["at_sizes"]
	if evolutions_taken >= at.size() or not pending_choice.is_empty():
		return
	if size < float(at[evolutions_taken]):
		return
	if first_evolution_at < 0.0:
		first_evolution_at = time
	evolution_times.append(time)
	pending_choice = roll_options()
	events.append({"type": "evolve_offer", "options": pending_choice})


## Up to 3 forms that can still level up. Hook-changing forms (multi/chain/whirl) come first.
func roll_options() -> Array:
	var main: Array = []
	var extra: Array = []
	for f in FORMS:
		if int(forms[f]) >= FORM_MAX:
			continue
		if f == "long":
			extra.append(f)
		else:
			main.append(f)
	for j in range(main.size() - 1, 0, -1):
		var r := rng.randi_range(0, j)
		var t = main[j]
		main[j] = main[r]
		main[r] = t
	var out: Array = main + extra
	return out.slice(0, 3)
