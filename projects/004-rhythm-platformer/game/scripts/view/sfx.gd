class_name Sfx
extends RefCounted
## Placeholder sounds synthesised in code (greybox: no audio assets). Usage:
##   Sfx.play("jump")  /  Sfx.play("lum", -4.0, 1.5)  (volume dB, explicit pitch)
## A file at res://assets/audio/sfx/<id>.wav or .ogg replaces the placeholder with no code change.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx"
## Pitch ladder for chained collectibles: a major pentatonic run (semitones), so a chain of
## pickups always plays a melody in key with the music.
const CHAIN_SEMITONES := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28, 31]

static var _cache: Dictionary = {}


static func play(id: String, volume_db := 0.0, pitch := 1.0, jitter := 0.04) -> void:
	Audio.play_sfx(get_stream(id), volume_db, jitter, pitch)


static func chain_pitch(chain: int) -> float:
	var semi: int = CHAIN_SEMITONES[clampi(chain, 0, CHAIN_SEMITONES.size() - 1)]
	return pow(2.0, semi / 12.0)


static func get_stream(id: String) -> AudioStream:
	if not _cache.has(id):
		var s: AudioStream = null
		for ext in ["ogg", "wav"]:
			var path := "%s/%s.%s" % [SFX_DIR, id, ext]
			if ResourceLoader.exists(path):
				s = load(path)
				break
		_cache[id] = s if s else _make(id)
	return _cache[id]


static func _make(id: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var dur := {"jump": 0.14, "wall_jump": 0.16, "land": 0.1, "land_hard": 0.22, "dash": 0.22,
		"punch": 0.09, "hit": 0.16, "break": 0.3, "lum": 0.32, "bounce": 0.36, "death": 0.6,
		"checkpoint": 0.5, "perfect": 0.32, "win": 1.2, "glide": 0.25, "wall_run": 0.18,
		"tick": 0.05, "go": 0.3}.get(id, 0.15)
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var noise := rng.randf_range(-1.0, 1.0)
		var v := 0.0
		match id:
			"jump":
				phase += TAU * lerpf(320.0, 760.0, sqrt(k)) / RATE
				v = (sin(phase) * 0.7 + signf(sin(phase)) * 0.12) * exp(-t / 0.07)
			"wall_jump":
				phase += TAU * lerpf(420.0, 980.0, sqrt(k)) / RATE
				v = sin(phase) * 0.6 * exp(-t / 0.07) + noise * 0.3 * exp(-t / 0.01)
			"land", "land_hard":
				var big := id == "land_hard"
				lp += (noise - lp) * 0.12
				phase += TAU * (110.0 if not big else 70.0) * (1.0 - k * 0.5) / RATE
				v = (lp * 1.4 + sin(phase) * 0.8) * exp(-t / (0.03 if not big else 0.07))
			"dash", "wall_run", "glide":
				var f := 0.05 + 0.25 * sin(PI * k)
				lp += (noise - lp) * f
				v = lp * 1.3 * sin(PI * k) * (0.6 if id == "glide" else 1.0)
			"punch":
				lp += (noise - lp) * (0.4 - k * 0.3)
				v = lp * sin(PI * k)
			"hit":
				phase += TAU * lerpf(220.0, 90.0, k) / RATE
				v = (noise * exp(-t / 0.02) * 0.9 + sin(phase) * exp(-t / 0.06)) * 0.9
			"break":
				var crackle := noise if rng.randf() < 0.3 + 0.6 * (1.0 - k) else 0.0
				lp += (crackle - lp) * 0.5
				v = lp * exp(-t / 0.12) * 1.2
			"lum":
				phase += TAU * 1046.5 / RATE
				v = (sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.08) \
					* exp(-t / 0.12) * minf(t / 0.002, 1.0)
			"bounce":
				phase += TAU * (200.0 + 500.0 * (1.0 - exp(-t / 0.08))) / RATE
				v = sin(phase) * exp(-t / 0.14) * 0.8
			"death":
				phase += TAU * lerpf(600.0, 120.0, k) / RATE
				v = signf(sin(phase)) * 0.35 * (1.0 - k) + noise * 0.2 * exp(-t / 0.05)
			"checkpoint", "go":
				var f := 784.0 if k < 0.4 else 1174.7
				phase += TAU * f / RATE
				v = sin(phase) * 0.5 * exp(-fmod(t, dur * 0.4) / 0.12)
			"perfect":
				var notes := [1568.0, 2093.0, 2637.0]
				phase += TAU * notes[mini(int(k * 3.0), 2)] / RATE
				v = sin(phase) * 0.35 * exp(-fmod(t, dur / 3.0) / 0.05)
			"win":
				var notes := [523.3, 659.3, 784.0, 1046.5]
				var idx := mini(int(k * 6.0), 3)
				phase += TAU * notes[idx] / RATE
				v = (sin(phase) + 0.3 * signf(sin(phase))) * 0.3 * (1.0 - k * 0.7)
			"tick":
				v = noise * exp(-t / 0.006)
			_:
				v = noise * exp(-t / 0.03)
		out[i] = clampf(v, -1.0, 1.0)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(out[i] * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
