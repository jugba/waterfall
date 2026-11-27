class_name SongClock
extends Node
## Song position in AUDIO time, not frame time:
##   playback_position + time_since_last_mix - output_latency
## (https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html).
## The raw value only moves once per mix chunk, so we predict with frame delta and steer
## gently toward the raw value (snap if they disagree by > 50 ms). Never runs backwards.
## manual = true (tests, or no working audio output): time advances by the deltas you pass.

var player: AudioStreamPlayer
var manual := false
var _t := 0.0
var _last_raw := -1.0
var _stale := 0.0
var latency := 0.0


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = &"Music"
	add_child(player)


func set_stream(s: AudioStream) -> void:
	player.stream = s


func play_from(t: float) -> void:
	_t = t
	_last_raw = -1.0
	_stale = 0.0
	if player.stream and not manual:
		player.play(t)
	latency = AudioServer.get_output_latency()


func stop() -> void:
	player.stop()


func time() -> float:
	return _t


## Call once per physics step.
func advance(delta: float) -> float:
	if manual or not player.playing:
		_t += delta
		return _t
	var raw := player.get_playback_position() + AudioServer.get_time_since_last_mix() - latency
	_t += delta
	if is_equal_approx(raw, _last_raw):
		_stale += delta
		if _stale > 0.5:
			manual = true  # the audio clock is not moving (dummy driver): fall back to frame time
		return _t
	_stale = 0.0
	_last_raw = raw
	var diff := raw - _t
	if absf(diff) > 0.05:
		_t = maxf(raw, _t - 0.05) if diff < 0.0 else raw
	else:
		_t += diff * 0.15
	return _t
