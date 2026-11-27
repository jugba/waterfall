extends RefCounted
## Placeholder sounds synthesised in code (no audio assets yet). Usage:
##   Audio.play_sfx(Sfx.get_stream("chip"), 0.0, 0.08, 1.2)
## A file at res://assets/audio/sfx/<id>.ogg or .wav replaces the placeholder with no code change.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx"

const IDS := {
	"chip": "pick hits rock (crunchy)",
	"break": "rock chunk breaks off",
	"drop": "geode lands in the tray",
	"strike": "hammer tick on a geode (pitch rises with progress)",
	"pop": "geode bursts open",
	"reveal_0": "common reveal", "reveal_1": "uncommon reveal", "reveal_2": "rare reveal",
	"reveal_3": "epic reveal", "reveal_4": "legendary reveal",
	"coin": "crystal sold",
	"polish": "polish rub tick",
	"perfect": "perfect polish",
	"buy": "upgrade bought",
	"rumble": "rock face collapses / new depth",
	"new": "new crystal for the book",
	"deny": "cannot afford",
}

static var _cache: Dictionary = {}


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
	var dur := 0.12
	match id:
		"chip": dur = 0.09
		"break": dur = 0.35
		"drop": dur = 0.12
		"strike": dur = 0.07
		"pop": dur = 0.45
		"reveal_0": dur = 0.35
		"reveal_1": dur = 0.6
		"reveal_2": dur = 1.1
		"reveal_3": dur = 1.6
		"reveal_4": dur = 2.6
		"coin": dur = 0.25
		"polish": dur = 0.08
		"perfect": dur = 0.6
		"buy": dur = 0.35
		"rumble": dur = 0.9
		"new": dur = 0.5
		"deny": dur = 0.15
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var notes := {
		"reveal_0": [660.0],
		"reveal_1": [660.0, 880.0],
		"reveal_2": [523.3, 659.3, 784.0, 1046.5],
		"reveal_3": [523.3, 659.3, 784.0, 1046.5, 1318.5],
		"reveal_4": [392.0, 523.3, 659.3, 784.0, 1046.5, 1318.5, 1568.0, 2093.0],
	}
	for i in n:
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var v := 0.0
		match id:
			"chip":  # crunchy: band-limited noise burst + a short knock
				lp = lerpf(lp, noise, 0.5)
				v = (lp - lp2) * 1.8 * exp(-t * 55.0) + sin(TAU * (260.0 - 900.0 * t) * t) * exp(-t * 70.0) * 0.6
				lp2 = lerpf(lp2, lp, 0.08)
			"break":
				lp = lerpf(lp, noise, 0.18)
				v = lp * 1.6 * exp(-t * 10.0) + sin(TAU * (90.0 - 80.0 * t) * t) * exp(-t * 9.0) * 0.8
			"drop":  # stony clack
				v = (sin(TAU * 1250.0 * t) * 0.5 + sin(TAU * 410.0 * t) * 0.5 + noise * 0.3) * exp(-t * 60.0)
			"strike":  # bright tick
				v = (sin(TAU * 1800.0 * t) * 0.6 + noise * 0.4) * exp(-t * 90.0)
			"pop":  # burst: noise crack + low boom
				lp = lerpf(lp, noise, 0.6)
				v = lp * exp(-t * 18.0) * 1.1 + sin(TAU * (140.0 - 120.0 * t) * t) * exp(-t * 7.0) * 0.9
			"reveal_0", "reveal_1", "reveal_2", "reveal_3", "reveal_4":
				var ns: Array = notes[id]
				var step := 0.09 if ns.size() > 4 else 0.11
				for k in ns.size():
					var dt := t - k * step
					if dt >= 0.0:
						var f: float = ns[k]
						v += (sin(TAU * f * dt) + 0.35 * sin(TAU * f * 2.0 * dt) + 0.15 * sin(TAU * f * 3.01 * dt)) * exp(-dt * (2.2 if id == "reveal_4" else 4.0)) * 0.22
				if id == "reveal_4":  # shimmer tail
					v += sin(TAU * 3136.0 * t) * sin(TAU * 7.0 * t) * exp(-t * 1.5) * 0.06
			"coin":
				var f2 := 1568.0 if t < 0.07 else 2093.0
				v = sin(TAU * f2 * t) * exp(-fmod(t, 0.07) * 18.0) * 0.4
			"polish":
				lp = lerpf(lp, noise, 0.25)
				v = lp * sin(PI * t / dur) * 0.5
			"perfect":
				v = (sin(TAU * 1318.5 * t) + sin(TAU * 1975.5 * t) * 0.6) * exp(-t * 5.0) * 0.3
			"buy":
				var f3: float = [784.0, 1175.0, 1568.0][mini(int(t / 0.07), 2)]
				v = sin(TAU * f3 * t) * exp(-fmod(t, 0.07) * 10.0) * 0.35
			"rumble":
				lp = lerpf(lp, noise, 0.04)
				v = lp * 3.0 * sin(PI * t / dur) + sin(TAU * 48.0 * t) * exp(-t * 3.0) * 0.5
			"new":
				var f4 := 2093.0 + 1500.0 * t
				v = sin(TAU * f4 * t) * exp(-t * 6.0) * 0.25 * (0.6 + 0.4 * sin(TAU * 30.0 * t))
			"deny":
				v = sin(TAU * 180.0 * t) * exp(-t * 20.0) * 0.5
		out[i] = v
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(out[i], -1.0, 1.0) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
