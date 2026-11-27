extends Node
## Music with cross-fade on the "Music" bus, and fire-and-forget SFX on the "SFX" bus.
## Buses are defined in res://default_bus_layout.tres; volumes are owned by Settings.
##
## Usage: Audio.play_music(preload("res://assets/audio/theme.ogg")); Audio.play_sfx(stream)

const SFX_VOICES := 12

var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # music keeps playing while paused
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		add_child(p)
		_music.append(p)
	for i in SFX_VOICES:
		var s := AudioStreamPlayer.new()
		s.bus = &"SFX"
		add_child(s)
		_sfx.append(s)


func play_music(stream: AudioStream, fade := 1.0) -> void:
	var current := _music[_active]
	if current.stream == stream and current.playing:
		return
	_active = 1 - _active
	var next := _music[_active]
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	var t := create_tween().set_parallel()
	t.tween_property(next, "volume_db", 0.0, fade)
	t.tween_property(current, "volume_db", -40.0, fade)
	t.chain().tween_callback(current.stop)


func stop_music(fade := 0.5) -> void:
	var current := _music[_active]
	create_tween().tween_property(current, "volume_db", -40.0, fade).finished.connect(current.stop)


## pitch_jitter adds small random variation so repeated sounds don't feel robotic.
func play_sfx(stream: AudioStream, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	if stream == null:
		return
	var p := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
