class_name Sfx
extends RefCounted
## Placeholder sounds synthesised in code (greybox: no audio files). Sfx.play("chomp", -2.0, 0.8)
## A file at res://assets/audio/sfx/<id>.wav or .ogg replaces the placeholder with no code change.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx"
const DUR := {"throw": 0.16, "catch": 0.18, "yank": 0.14, "chomp": 0.26, "gulp": 0.35, "clang": 0.3,
	"too_big": 0.3, "spiked": 0.25, "hurt": 0.2, "dodge": 0.18, "snap": 0.2, "spit": 0.15,
	"trait": 0.5, "evolve": 0.9, "wave": 0.5, "boss": 1.4, "win": 1.4, "death": 0.7, "puff": 0.2,
	"whirl": 0.5, "chain": 0.2}

static var _cache: Dictionary = {}


static func play(id: String, volume_db := 0.0, pitch := 1.0, jitter := 0.05) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Audio.play_sfx(get_stream(id), volume_db, jitter, pitch)


static func get_stream(id: String) -> AudioStream:
	if not _cache.has(id):
		var s: AudioStream = null
		for ext in ["ogg", "wav"]:
			var path := "%s/%s.%s" % [SFX_DIR, id, ext]
			if ResourceLoader.exists(path):
				s = load(path)
				break
		_cache[id] = s if s else make(id)
	return _cache[id]


static func make(id: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var dur: float = DUR.get(id, 0.15)
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
			"throw", "whirl", "dodge":
				var f := 0.05 + 0.3 * sin(PI * k)
				lp += (noise - lp) * f
				v = lp * 1.5 * sin(PI * k)
				if id == "whirl":
					v *= 0.6 + 0.4 * sin(t * TAU * 14.0)
			"catch", "chain":
				phase += TAU * lerpf(900.0, 300.0, k) / RATE
				v = signf(sin(phase)) * 0.35 * exp(-t / 0.05) + noise * 0.5 * exp(-t / 0.008)
			"yank":
				phase += TAU * lerpf(180.0, 520.0, k * k) / RATE
				v = sin(phase) * 0.7 * exp(-t / 0.08) + noise * 0.25 * exp(-t / 0.02)
			"chomp":
				# two crunchy bites + a low thump
				var bite := fmod(t, 0.09)
				lp += (noise - lp) * 0.6
				phase += TAU * lerpf(140.0, 60.0, k) / RATE
				v = lp * exp(-bite / 0.02) * 0.9 + sin(phase) * 0.7 * exp(-t / 0.1)
			"gulp":
				phase += TAU * lerpf(260.0, 90.0, sqrt(k)) / RATE
				v = sin(phase) * 0.8 * sin(PI * k)
			"clang":
				phase += TAU * 1250.0 / RATE
				v = (sin(phase) * 0.5 + sin(phase * 2.76) * 0.3) * exp(-t / 0.09) + noise * 0.3 * exp(-t / 0.004)
			"too_big":
				phase += TAU * (140.0 if k < 0.5 else 110.0) / RATE
				v = signf(sin(phase)) * 0.3 * exp(-fmod(t, dur * 0.5) / 0.1)
			"spiked", "hurt":
				phase += TAU * lerpf(500.0, 160.0, k) / RATE
				v = (signf(sin(phase)) * 0.3 + noise * 0.4) * exp(-t / 0.06)
			"snap":
				lp += (noise - lp) * 0.7
				v = lp * exp(-t / 0.03)
			"spit", "puff":
				phase += TAU * lerpf(300.0, 700.0, k) / RATE
				lp += (noise - lp) * 0.2
				v = (sin(phase) * 0.4 + lp * 0.6) * sin(PI * k)
			"trait", "wave", "evolve":
				var notes := [523.3, 659.3, 784.0, 1046.5] if id != "wave" else [392.0, 523.3]
				var idx := mini(int(k * notes.size()), notes.size() - 1)
				phase += TAU * notes[idx] / RATE
				v = (sin(phase) + 0.25 * sin(phase * 2.0)) * 0.35 * exp(-fmod(t, dur / notes.size()) / 0.15)
			"boss":
				phase += TAU * (55.0 + 8.0 * sin(t * 6.0)) / RATE
				v = (signf(sin(phase)) * 0.3 + sin(phase * 1.5) * 0.3) * minf(1.0, t * 4.0) * (1.0 - k)
			"win":
				var notes := [523.3, 659.3, 784.0, 1046.5, 1318.5]
				phase += TAU * notes[mini(int(k * 7.0), 4)] / RATE
				v = (sin(phase) + 0.3 * signf(sin(phase))) * 0.3 * (1.0 - k * 0.7)
			"death":
				phase += TAU * lerpf(500.0, 80.0, k) / RATE
				v = signf(sin(phase)) * 0.35 * (1.0 - k)
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
