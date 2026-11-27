class_name Bot
extends RefCounted
## A deliberately conservative scripted player for pacing tests and the --autoplay capture:
## reacts slowly (~0.5 s between throws), aims with a few degrees of error, leads targets,
## avoids hooking spiky puffers / armoured fronts, keeps its distance from threats and
## sometimes dodges shots. A real player should be faster than this; the pacing promises are
## "even this bot gets there in time".

var rng := RandomNumberGenerator.new()
var throw_every := 0.55
var aim_error_deg := 6.0
var yank_every := 0.3
var dodge_chance := 0.55
var _throw_t := 0.0
var _yank_t := 0.0
var _think_t := 0.0
var _move := Vector2.ZERO
var _dodge_cd := 0.0


func _init(seed_value := 7) -> void:
	rng.seed = seed_value


func think(sim: ArenaSim) -> InputFrame:
	var f := InputFrame.new()
	var dt := ArenaSim.DT
	_throw_t -= dt
	_yank_t -= dt
	_think_t -= dt
	_dodge_cd -= dt
	var target = _pick_target(sim)
	var aim := sim.aim
	if target != null:
		var lead_t: float = sim.pos.distance_to(target.pos) / maxf(1.0, sim.st["hook_speed"])
		var at: Vector2 = target.pos + target.vel * lead_t
		aim = (at - sim.pos).normalized().rotated(deg_to_rad(rng.randfn(0.0, aim_error_deg)))
	f.aim = aim
	if sim.any_attached():
		if _yank_t <= 0.0:
			f.hook_pressed = true
			_yank_t = yank_every
	elif target != null and sim.all_idle() and _throw_t <= 0.0:
		if sim.pos.distance_to(target.pos) - target.radius < sim.st["hook_range"] * 0.92:
			f.hook_pressed = true
			_throw_t = throw_every
	if _think_t <= 0.0:
		_think_t = 0.15
		_move = _steer(sim, target)
	f.move = _move
	if _dodge_cd <= 0.0 and _threatened(sim):
		_dodge_cd = 0.5
		if rng.randf() < dodge_chance:
			f.dodge_pressed = true
			f.move = _move.orthogonal() if _move.length() > 0.1 else Vector2.UP
	return f


func _pick_target(sim: ArenaSim):
	var best = null
	var best_score := INF
	for e in sim.enemies:
		if e.state == ArenaSim.EState.HOOKED or not sim.hookable(e):
			continue
		if e.kind == "puffer" and e.spiky and not sim.st["spike_proof"]:
			continue
		if e.kind == "shellback" and not sim.st["pierce"] \
				and sim._shell_blocks(e, e.pos + (sim.pos - e.pos).normalized() * e.radius):
			continue
		var score: float = sim.pos.distance_to(e.pos)
		if e.is_boss:
			score *= 0.3
		if score < best_score:
			best_score = score
			best = e
	return best


func _steer(sim: ArenaSim, target) -> Vector2:
	var v := Vector2.ZERO
	var r: float = sim.st["radius"]
	for e in sim.enemies:
		if e.state == ArenaSim.EState.HOOKED:
			continue
		var dv: Vector2 = sim.pos - e.pos
		var danger: float = r + e.radius + 140.0 * sim.st["scale"]
		if e.is_boss:
			danger += 200.0 * sim.st["scale"]
		var d := dv.length()
		if d < danger and d > 0.01:
			v += dv / d * (danger - d) / danger * 2.0
	if target != null:
		var to: Vector2 = target.pos - sim.pos
		var want: float = sim.st["hook_range"] * 0.6
		if to.length() > want:
			v += to.normalized()
	else:
		v += -sim.pos.normalized() * clampf(sim.pos.length() / 1500.0, 0.0, 1.0)  # drift to centre
	return v.limit_length(1.0)


func _threatened(sim: ArenaSim) -> bool:
	var r: float = sim.st["radius"]
	for s in sim.shots:
		var rel: Vector2 = sim.pos - s["pos"]
		var vel: Vector2 = s["vel"]
		if rel.length() < r + 160.0 * sim.st["scale"] and vel.dot(rel) > 0.0:
			return true
	for e in sim.enemies:
		if (e.dashing > 0.0 or e.tell > 0.0) and e.pos.distance_to(sim.pos) < r + e.radius + 120.0 * sim.st["scale"]:
			return true
	return false
