class_name Sfx
extends RefCounted
## Named sound hooks. Code asks for a sound by id: Audio.play_sfx(Sfx.get_stream("click")).
## Drop-in files replace the synthesised placeholders with no code change:
##   res://assets/audio/sfx/<id>.ogg (or .wav), plus optional variants <id>_2.ogg ... <id>_8.ogg
##   that are picked at random each time (e.g. several recorded pencil clicks).
## Music works the same way per screen: res://assets/audio/music/<screen>.ogg, see MUSIC.
## The full list, priorities and sourcing plan: projects/002-cozy-organizing-sim/audio/audio-plan.md

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"
const EXTENSIONS := ["ogg", "wav"]
const MAX_VARIANTS := 8

## Every SFX id the game uses -> what it is (the audio plan lists priorities). Tests check that
## every Sfx.get_stream("...") call in the scripts uses an id from this table.
const IDS := {
	"click": "item snaps onto the grid (pitch follows item size)",
	"tick": "item lines up with a neighbour / UI tick / score count-up",
	"pick": "item picked up",
	"thunk": "container tipped over / lid shut",
	"tumble": "rattle of items pouring onto the mat",
	"shutter": "camera shutter at the photo",
	"stamp": "rating stamp slams down",
	"chime": "good score reveal",
	"pack_drop": "item placed inside the container",
	"zip": "container zips / closes",
	"unlock": "a new job unlocked",
	"ui_select": "menu button pressed",
}
## Music per screen. Missing files mean silence (no placeholder music).
const MUSIC := {
	"menu": "title and job select",
	"desk": "sorting and packing",
}

static var _cache: Dictionary = {}


## A stream for `id`: a random drop-in variant if files exist, else the synthesised placeholder.
static func get_stream(id: String) -> AudioStream:
	if not _cache.has(id):
		var found := files_for(id)
		var list: Array = []
		for f in found:
			var s = load(f)
			if s is AudioStream:
				list.append(s)
		if list.is_empty():
			list.append(_make(id))
		_cache[id] = list
	var arr: Array = _cache[id]
	return arr[randi() % arr.size()] if arr.size() > 1 else arr[0]


## Drop-in file paths that exist for an SFX id (base name, then _2 .. _8 variants).
static func files_for(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for n in range(1, MAX_VARIANTS + 1):
		var base := id if n == 1 else "%s_%d" % [id, n]
		for ext in EXTENSIONS:
			var path := "%s/%s.%s" % [SFX_DIR, base, ext]
			if ResourceLoader.exists(path):
				out.append(path)
				break
	return out


## Music for a screen id (see MUSIC), or null when no file has been dropped in yet.
static func music(screen: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path := "%s/%s.%s" % [MUSIC_DIR, screen, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


## Starts the screen's music if a file exists; otherwise leaves whatever is playing.
static func play_music(screen: String) -> void:
	var m := music(screen)
	if m:
		Audio.play_music(m)


## Forget loaded streams (tests, or after dropping files in while the editor runs).
static func clear_cache() -> void:
	_cache.clear()


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
		"pack_drop": dur = 0.09
		"zip": dur = 0.55
		"unlock": dur = 0.7
		"ui_select": dur = 0.05
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
			"pack_drop":  # soft, muffled settle into fabric
				lp = lerpf(lp, noise, 0.12)
				v = (lp * 1.6 + sin(TAU * 320.0 * t) * 0.4) * exp(-t * 45.0) * 0.7
			"zip":  # a fast run of teeth clicks that speeds up
				var phase := t * (80.0 + 260.0 * t)
				var tooth := fmod(phase, 1.0)
				v = noise * exp(-tooth * 40.0) * 0.5 * (1.0 - t / dur)
			"unlock":  # rising arpeggio
				var k := mini(int(t / 0.12), 3)
				var f: float = [784.0, 988.0, 1175.0, 1568.0][k]
				v = sin(TAU * f * t) * exp(-(t - k * 0.12) * 8.0) * 0.35
			"ui_select":
				v = sin(TAU * 1800.0 * t) * exp(-t * 120.0) * 0.4
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
