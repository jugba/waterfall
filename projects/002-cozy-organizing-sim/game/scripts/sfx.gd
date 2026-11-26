class_name Sfx
extends RefCounted
## Placeholder sound effects synthesised in code (no audio files yet), played through the
## Audio autoload: Audio.play_sfx(Sfx.get_stream("click")). Replace with recorded per-material
## clicks later (BRIEF: "the satisfying layer").

const RATE := 22050

static var _cache: Dictionary = {}


static func get_stream(id: String) -> AudioStreamWAV:
	if not _cache.has(id):
		_cache[id] = _make(id)
	return _cache[id]


static func _make(id: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var dur := 0.1
	match id:
		"click": dur = 0.06
		"tick": dur = 0.03
		"pick": dur = 0.05
		"thunk": dur = 0.25
		"tumble": dur = 0.7
		"chime": dur = 1.0
		"shutter": dur = 0.18
		"stamp": dur = 0.22
	var n := int(dur * RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var lp := 0.0
	var bursts: Array = []
	if id == "tumble":
		for k in 18:
			bursts.append([rng.randf_range(0.0, dur - 0.05), rng.randf_range(1400.0, 3200.0), rng.randf_range(0.3, 1.0)])
	for i in n:
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var v := 0.0
		match id:
			"click":  # crisp snap: bright tone + noise, very short
				v = (sin(TAU * 2300.0 * t) * 0.55 + noise * 0.45) * exp(-t * 95.0)
			"tick":
				v = sin(TAU * 3400.0 * t) * exp(-t * 180.0) * 0.6
			"pick":  # soft lift: rising tone
				v = sin(TAU * (600.0 + 4000.0 * t) * t) * exp(-t * 60.0) * 0.45
			"thunk":  # the tip: low falling thump
				v = sin(TAU * (120.0 - 160.0 * t) * t) * exp(-t * 13.0) * 0.9 + noise * exp(-t * 45.0) * 0.25
			"tumble":  # rattle of items landing
				for b in bursts:
					var dt: float = t - b[0]
					if dt >= 0.0 and dt < 0.05:
						v += (sin(TAU * b[1] * dt) * 0.5 + noise * 0.5) * exp(-dt * 120.0) * b[2]
				v *= 0.55
			"chime":  # score reveal: major triad, slow decay
				v = (sin(TAU * 1046.5 * t) + 0.6 * sin(TAU * 1318.5 * t) + 0.45 * sin(TAU * 1568.0 * t)) * exp(-t * 3.5) * 0.3
			"shutter":  # camera: two filtered noise clacks
				lp = lerpf(lp, noise, 0.35)
				v = lp * (exp(-t * 70.0) + (exp(-(t - 0.09) * 70.0) if t > 0.09 else 0.0)) * 0.9
			"stamp":
				v = sin(TAU * (90.0 - 60.0 * t) * t) * exp(-t * 18.0) * 0.8 + noise * exp(-t * 60.0) * 0.4
		samples[i] = v
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
