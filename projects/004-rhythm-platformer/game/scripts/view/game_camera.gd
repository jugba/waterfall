class_name GameCamera
extends Camera2D
## Follows a node with look-ahead in the facing/run direction, gentle exponential smoothing,
## a fall look-down and trauma-style shake. Values from movement.json "camera".

var target: Node2D
var ctl: PlayerController
var music_mode := false  # auto-runner: look further ahead, follow height loosely
var _look := 0.0
var _shake := 0.0
var _y := 0.0


func snap() -> void:
	if target:
		_y = target.position.y
		position = _goal()
		reset_smoothing()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _goal() -> Vector2:
	var c: Dictionary = ctl.T["camera"]
	var p := target.position
	var gy := _y + float(c["vertical_offset"])
	if ctl.vel.y > 600.0:
		gy += float(c["fall_lookdown"])
	return Vector2(p.x + _look, gy)


func _process(delta: float) -> void:
	if target == null or ctl == null:
		return
	var c: Dictionary = ctl.T["camera"]
	var max_speed: float = ctl.T["run"]["max_speed"]
	var want := 0.0
	if music_mode:
		want = float(c["lookahead_x"]) * 1.6
	else:
		var speed_k := clampf(absf(ctl.vel.x) / max_speed, 0.35, 1.0)
		want = ctl.facing * float(c["lookahead_x"]) * speed_k
	_look = lerpf(_look, want, 1.0 - exp(-float(c["lookahead_rate"]) * delta))
	# vertical: follow quickly when grounded (new floor height), loosely in the air
	var vy_rate: float = c["vertical_smoothing"] * (2.0 if ctl.on_floor else 1.0)
	var ty := target.position.y
	if music_mode:
		ty = minf(ty, 0.0) * 0.55
	_y = lerpf(_y, ty, 1.0 - exp(-vy_rate * delta))
	var g := _goal()
	var k := 1.0 - exp(-float(c["smoothing"]) * delta)
	position.x = lerpf(position.x, g.x, k * (2.5 if music_mode else 1.0))
	position.y = lerpf(position.y, g.y, k)
	_shake = maxf(_shake - delta * 30.0, 0.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
