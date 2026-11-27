class_name PlayerView
extends Node2D
## Draws "Pip", the hero: a round, bouncy blob with headphones, big eyes, stubby feet, a boxing
## glove for punches and a leaf for gliding. All simple shapes. Reads a PlayerController and
## turns its events into squash/stretch, dust, afterimages, speed lines and sounds.
## Call sync() after every controller step (physics); drawing interpolates between steps.

signal shake(amount: float)

const BODY := Color(1.0, 0.62, 0.26)
const BODY_DARK := Color(0.62, 0.3, 0.12)
const BELLY := Color(1.0, 0.86, 0.6)
const PHONES := Color(0.16, 0.78, 0.78)
const PHONES_DARK := Color(0.07, 0.42, 0.48)
const CHEEK := Color(1.0, 0.45, 0.5, 0.55)
const GLOVE := Color(0.95, 0.24, 0.3)
const LEAF := Color(0.42, 0.85, 0.36)

var ctl: PlayerController
var fx: Fx
var frozen := false  # hitstop
var muted := false   # no sounds (title screen)
var interpolate := true

var _prev := Vector2.ZERO
var _cur := Vector2.ZERO
var _scale := Vector2.ONE
var _scale_vel := Vector2.ZERO
var _blink := 0.0
var _blink_wait := 2.0
var _run_phase := 0.0
var _punch := 0.0
var _leaf := 0.0
var _lean := 0.0
var _look := Vector2.RIGHT
var _trail_t := 0.0
var _grin := 0.0
var _beat_pulse := 0.0


func setup(controller: PlayerController, effects: Fx) -> void:
	ctl = controller
	fx = effects
	teleport()


func teleport() -> void:
	_prev = ctl.pos
	_cur = ctl.pos
	position = ctl.pos


func pulse(amount: float) -> void:
	_beat_pulse = maxf(_beat_pulse, amount)


func grin() -> void:
	_grin = 1.0


func sync() -> void:
	_prev = _cur
	_cur = ctl.pos
	react(ctl.events)


func react(events: Array) -> void:
	var feel: Dictionary = ctl.T["feel"]
	for e in events:
		match e["type"]:
			"jump":
				_kick(Vector2(-0.3, 0.32) * float(feel["stretch_jump"]) / 0.28)
				_dust(5, 0.0)
				_sfx("jump", -6.0)
			"wall_jump":
				_kick(Vector2(-0.25, 0.3))
				if fx:
					fx.dust(ctl.pos + Vector2(-e["dir"] * ctl.half_w, -20), 6, Vector2(-e["dir"], -0.3))
				_sfx("wall_jump", -5.0)
			"land":
				var spd: float = e["speed"]
				var k := clampf(spd / float(ctl.T["fall"]["max_speed"]), 0.0, 1.0) * float(feel["squash_land_max"])
				_kick(Vector2(k * 1.2, -k))
				if spd >= float(feel["dust_land_speed"]):
					_dust(4 + int(k * 20.0), 0.0)
				if spd > 800.0:
					shake.emit(float(feel["shake_land_hard"]))
					_sfx("land_hard", -4.0)
				elif spd > 200.0:
					_sfx("land", -8.0)
			"dash":
				_kick(Vector2(0.4, -0.25))
				if fx:
					fx.ring(ctl.pos + Vector2(0, -26), 40.0, Color(1, 1, 1, 0.6), 0.18)
				_sfx("dash", -4.0)
			"wall_run":
				_kick(Vector2(-0.15, 0.2))
				_sfx("wall_run", -6.0)
			"punch":
				_punch = 1.0
				_kick(Vector2(0.18, -0.1))
				_sfx("punch", -6.0)
			"bounce":
				_kick(Vector2(-0.38, 0.45))
				_dust(8, 0.0)
				_sfx("bounce", -3.0)
			"bonk":
				_kick(Vector2(0.2, -0.2))


func _kick(v: Vector2) -> void:
	_scale = Vector2.ONE + v
	_scale_vel = Vector2.ZERO


func _dust(count: int, _dir: float) -> void:
	if fx:
		fx.dust(ctl.pos, count, Vector2.ZERO)


func _sfx(id: String, db: float) -> void:
	if not muted:
		Sfx.play(id, db)


func _process(delta: float) -> void:
	if ctl == null:
		return
	if not frozen:
		var f := Engine.get_physics_interpolation_fraction() if interpolate else 1.0
		position = _prev.lerp(_cur, f)
	var feel: Dictionary = ctl.T["feel"]
	# squash/stretch spring back to 1
	var k: float = feel["squash_spring"]
	var d: float = feel["squash_damping"]
	if not frozen:
		_scale_vel += (Vector2.ONE - _scale) * k * delta - _scale_vel * d * delta
		_scale += _scale_vel * delta
	# expressive bits
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink = 0.12
		_blink_wait = randf_range(1.6, 3.8)
	_blink = maxf(_blink - delta, 0.0)
	_punch = maxf(_punch - delta / 0.16, 0.0)
	_grin = maxf(_grin - delta * 1.5, 0.0)
	_beat_pulse = maxf(_beat_pulse - delta * 5.0, 0.0)
	_leaf = move_toward(_leaf, 1.0 if ctl.gliding else 0.0, delta * 7.0)
	var target_lean := clampf(ctl.vel.x / 2400.0, -0.18, 0.18)
	if ctl.wall_sliding:
		target_lean = -ctl.wall_dir * 0.12
	_lean = lerpf(_lean, target_lean, 1.0 - exp(-12.0 * delta))
	var want := ctl.vel.normalized() if ctl.vel.length() > 60.0 else Vector2(ctl.facing, 0.15)
	_look = _look.lerp(want, 1.0 - exp(-10.0 * delta))
	if ctl.on_floor and absf(ctl.vel.x) > 30.0:
		_run_phase += delta * (6.0 + absf(ctl.vel.x) / 30.0)
	else:
		_run_phase = lerpf(_run_phase, round(_run_phase / PI) * PI, 1.0 - exp(-10.0 * delta))
	# trail: afterimages while dashing / very fast, speed lines
	_trail_t -= delta
	var fast := ctl.is_dashing() or absf(ctl.vel.x) > float(feel["trail_speed"]) or ctl.is_wall_running()
	if fx and fast and _trail_t <= 0.0 and not frozen:
		_trail_t = float(feel["afterimage_interval"])
		fx.afterimage(position, _scale, ctl.facing, float(feel["afterimage_life"]))
		fx.speed_line(position + Vector2(-ctl.facing * 26.0, randf_range(-46.0, -6.0)), -ctl.facing)
	if fx and ctl.wall_sliding and randf() < 0.4:
		fx.dust(position + Vector2(ctl.wall_dir * ctl.half_w, -10.0), 1, Vector2(-ctl.wall_dir * 0.3, -0.2))
	queue_redraw()


static func ellipse(c: Vector2, r: Vector2, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


func _draw() -> void:
	if ctl == null:
		return
	var face := float(ctl.facing)
	var s := _scale * (1.0 + _beat_pulse * 0.06)
	draw_set_transform(Vector2.ZERO, _lean, Vector2(s.x * face, s.y))
	# feet
	var step := sin(_run_phase)
	var air := not ctl.on_floor
	for side in [-1.0, 1.0]:
		var lift := maxf(0.0, step * side) * 7.0 if not air else 3.0
		var fwd := step * side * 5.0 if not air else 2.0
		var foot := Vector2(side * 10.0 + fwd + 3.0, -5.0 - lift)
		draw_colored_polygon(ellipse(foot, Vector2(9, 5.5), 16), BODY_DARK)
	# leaf glider (behind the body)
	if _leaf > 0.01:
		var top := Vector2(-2, -58 - 20 * _leaf)
		draw_line(Vector2(0, -44), top, Color(0.3, 0.55, 0.2), 3.0)
		var leaf := ellipse(top + Vector2(0, -4), Vector2(38 * _leaf, 12 * _leaf), 24)
		draw_colored_polygon(leaf, LEAF)
		draw_polyline(leaf + PackedVector2Array([leaf[0]]), Color(0.2, 0.5, 0.2), 2.0)
		draw_line(top + Vector2(-34 * _leaf, -4), top + Vector2(34 * _leaf, -4), Color(0.25, 0.6, 0.25), 2.0)
	# headphone band (behind the head)
	draw_arc(Vector2(0, -30), 27.0, PI * 1.08, PI * 1.92, 20, PHONES_DARK, 6.0, true)
	# body
	var body := ellipse(Vector2(0, -27), Vector2(23, 24.5), 32)
	draw_colored_polygon(body, BODY)
	draw_colored_polygon(ellipse(Vector2(4, -18), Vector2(14, 11), 20), BELLY)
	draw_polyline(body + PackedVector2Array([body[0]]), BODY_DARK, 3.0, true)
	# ear cups
	for side in [-1.0, 1.0]:
		var cup := Vector2(side * 22.0, -31.0)
		draw_colored_polygon(ellipse(cup, Vector2(6, 9), 16), PHONES)
		draw_colored_polygon(ellipse(cup + Vector2(side * 1.5, 0), Vector2(3, 5), 12), PHONES_DARK)
	# eyes
	var look := Vector2(maxf(_look.x * face, -0.3), _look.y) * 3.5
	for ex in [-1.0, 9.0]:
		var c := Vector2(ex + 4.0, -33.0)
		if _blink > 0.0:
			draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), Color(0.15, 0.1, 0.1), 3.0)
			continue
		var tall := 8.5 + (1.5 if ctl.vel.y > 400.0 else 0.0)
		draw_colored_polygon(ellipse(c, Vector2(6.5, tall), 18), Color.WHITE)
		draw_colored_polygon(ellipse(c + look, Vector2(3.6, 4.6), 14), Color(0.12, 0.08, 0.14))
		draw_circle(c + look + Vector2(1.2, -1.8), 1.3, Color.WHITE)
	# brows when determined (dash / punch)
	if ctl.is_dashing() or _punch > 0.0:
		draw_line(Vector2(-4, -44), Vector2(6, -42), BODY_DARK, 2.5)
		draw_line(Vector2(9, -42), Vector2(18, -44), BODY_DARK, 2.5)
	# cheeks
	draw_circle(Vector2(-6, -23), 4.0, CHEEK)
	draw_circle(Vector2(19, -23), 4.0, CHEEK)
	# mouth
	var m := Vector2(7, -21)
	if _grin > 0.1:
		draw_colored_polygon(ellipse(m + Vector2(0, 1), Vector2(6, 4), 14), Color(0.45, 0.1, 0.15))
	elif air and ctl.vel.y > 350.0:
		draw_colored_polygon(ellipse(m, Vector2(3, 3.5), 12), Color(0.45, 0.1, 0.15))
	else:
		draw_arc(m + Vector2(0, -3), 4.5, PI * 0.15, PI * 0.85, 10, Color(0.35, 0.12, 0.12), 2.2)
	# glove
	if _punch > 0.0:
		var ext := sin((1.0 - _punch) * PI)
		var reach: float = float(ctl.T["punch"]["range"]) * 0.8
		var g := Vector2(22.0 + ext * reach, -26.0)
		draw_line(Vector2(16, -24), g, BODY_DARK, 4.0)
		draw_colored_polygon(ellipse(g, Vector2(12, 11), 18), GLOVE)
		draw_colored_polygon(ellipse(g + Vector2(-9, 0), Vector2(4, 8), 12), Color.WHITE)
		draw_circle(g + Vector2(3, -4), 3.0, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
