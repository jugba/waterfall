extends GutTest
## The beat map is data; its events must sit on the beat in AUDIO time (+-10 ms), and the
## generated music must actually have a transient at each gameplay event.

const TOL := 0.010
const GAMEPLAY := ["jump", "long_jump", "punch", "bounce", "bounce_glide", "checkpoint", "end"]

var map: Beatmap


func before_all() -> void:
	map = Beatmap.load_default()


func test_tempo_and_length_match_the_brief() -> void:
	assert_between(map.bpm, 120.0, 130.0, "120-130 BPM")
	assert_between(map.duration, 60.0, 90.0, "60-90 s")
	assert_true(ResourceLoader.exists(map.music_path), "music file exists")


func test_every_event_is_on_the_beat_grid() -> void:
	assert_gt(map.events.size(), 50)
	var worst := 0.0
	for e in map.events:
		var grid := map.time_of_beat(e["beat"])
		worst = maxf(worst, absf(e["time"] - grid))
		assert_true(absf(e["time"] - grid) <= TOL, "%s @ beat %.1f within 10 ms" % [e["type"], e["beat"]])
		if GAMEPLAY.has(e["type"]):
			assert_eq(e["beat"], floor(e["beat"]), "gameplay events sit on whole beats")
		else:
			assert_eq(e["beat"] * 2.0, floor(e["beat"] * 2.0), "collectibles sit on half beats")
	gut.p("worst grid error %.2f ms" % (worst * 1000.0))


func test_events_sorted_and_known() -> void:
	var last := -1.0
	for e in map.events:
		assert_gte(e["time"], last)
		last = e["time"]
		assert_true(GAMEPLAY.has(e["type"]) or e["type"] == "lum", "known type %s" % e["type"])
	assert_eq(map.of_type(["end"]).size(), 1, "exactly one end")
	assert_gt(map.of_type(["checkpoint"]).size(), 2)


## Reads the generated WAV (PCM16 mono) straight from the project.
func _pcm() -> Dictionary:
	var f := FileAccess.open(map.music_path, FileAccess.READ)
	var bytes := f.get_buffer(f.get_length())
	var rate := 44100
	var i := 12
	while i + 8 <= bytes.size():
		var id := bytes.slice(i, i + 4).get_string_from_ascii()
		var size := bytes.decode_u32(i + 4)
		if id == "fmt ":
			rate = bytes.decode_u32(i + 12)
			assert_eq(bytes.decode_u16(i + 10), 1, "mono")
			assert_eq(bytes.decode_u16(i + 22), 16, "16-bit")
		elif id == "data":
			return {"rate": rate, "data": bytes.slice(i + 8, i + 8 + size)}
		i += 8 + size + (size % 2)
	return {}


func test_music_has_an_onset_on_each_gameplay_event() -> void:
	var pcm := _pcm()
	assert_false(pcm.is_empty(), "WAV parsed")
	var rate: int = pcm["rate"]
	var data: PackedByteArray = pcm["data"]
	var n := data.size() / 2
	assert_almost_eq(float(n) / rate, map.duration, 0.05, "WAV length matches the map")
	var win := int(rate * 0.002)  # 2 ms energy frames
	var worst := 0.0
	for e in map.of_type(GAMEPLAY):
		var t: float = e["time"]
		if t <= 0.0:
			continue
		# energy per 2 ms frame from t-30 ms to t+30 ms; onset = biggest rise
		var start := int((t - 0.03) * rate)
		var prev := -1.0
		var best_rise := -1.0
		var best_t := -1.0
		for k in 30:
			var s0 := start + k * win
			var acc := 0.0
			for j in range(s0, mini(s0 + win, n)):
				acc += absf(data.decode_s16(j * 2))
			acc /= win
			if prev >= 0.0 and acc - prev > best_rise:
				best_rise = acc - prev
				best_t = float(s0) / rate
			prev = acc
		var err := absf(best_t - t)
		worst = maxf(worst, err)
		assert_true(err <= TOL, "%s @ %.3f s: onset at %.3f s (%.1f ms)" % [e["type"], t, best_t, err * 1000.0])
	gut.p("worst onset error %.1f ms" % (worst * 1000.0))
