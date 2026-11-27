class_name MusicRun
extends RefCounted
## Gameplay state of one music-level attempt, with no nodes: the scene feeds it the AUDIO time
## each physics step; tests feed it a manual clock. Emits `events` for the view (juice, sounds).
##
## The runner's x is locked to audio time, so being on the beat is the same as being in the
## right place. Death -> respawn at the last checkpoint; the scene seeks the music to
## respawn_seek_time() so the song re-syncs with a count-in.

enum State { COUNT_IN, RUN, DEAD, DONE }

const DEATH_FALL_Y := 260.0
const BLOCKED_LAG := 10.0
const LUM_CHAIN_GAP := 0.75  # seconds between pickups that still continue a chain

var course: MusicCourse
var ctl: PlayerController
var state := State.COUNT_IN
var song_time := 0.0
var cp_index := 0
var deaths := 0
var lums_got := {}   # lum index -> true
var chain := 0
var last_lum_time := -10.0
var perfects := 0
var goods := 0
var events: Array = []
var _pad_used := {}
var _silent := false
var _lum_cursor := 0


func _init(c: MusicCourse, silent := false) -> void:
	course = c
	_silent = silent
	ctl = PlayerController.new(c.T, c.world)
	_place_at_checkpoint()


func checkpoint() -> Dictionary:
	return course.checkpoints[cp_index] if not course.checkpoints.is_empty() else {"time": 0.0, "x": 0.0}


func _place_at_checkpoint() -> void:
	var cp := checkpoint()
	ctl.pos = Vector2(cp["x"], MusicCourse.GROUND_Y)
	ctl.vel = Vector2.ZERO
	ctl.on_floor = true
	ctl.facing = 1
	ctl.auto_run_x = cp["x"]
	_pad_used.clear()
	state = State.COUNT_IN
	_lum_cursor = 0


## Audio time the music should restart from after a death (count-in before the checkpoint).
func respawn_seek_time() -> float:
	var lead := float(course.T["music"]["respawn_lead_beats"]) * course.map.beat_length()
	return maxf(float(checkpoint()["time"]) - lead, 0.0)


func respawn() -> float:
	course.reset_blocks_after(float(checkpoint()["time"]))
	_place_at_checkpoint()
	return respawn_seek_time()


func beat_now() -> float:
	return course.map.beat_at(song_time)


func step(t: float, dt: float, inp: InputFrame) -> void:
	events.clear()
	song_time = t
	if state == State.DEAD or state == State.DONE:
		return
	var cp := checkpoint()
	if state == State.COUNT_IN:
		ctl.auto_run_x = cp["x"]
		if t >= float(cp["time"]):
			state = State.RUN
			events.append({"type": "go"})
	if state == State.RUN:
		ctl.auto_run_x = course.x_of(maxf(t, float(cp["time"])))
	ctl.step(dt, inp)
	for e in ctl.events:
		match e["type"]:
			"jump":
				_judge(["jump", "long_jump"], "jump")
		events.append(e)
	if state != State.RUN:
		return
	_check_punch()
	_check_pads()
	_check_lums()
	_check_checkpoints()
	if ctl.pos.y > DEATH_FALL_Y or ctl.pos.x < float(ctl.auto_run_x) - BLOCKED_LAG:
		state = State.DEAD
		deaths += 1
		chain = 0
		events.append({"type": "death", "pos": ctl.pos})
		return
	if ctl.pos.x >= course.end_x and course.end_x > 0.0:
		state = State.DONE
		events.append({"type": "finish"})


## Rate an action against the nearest event of the given types (audio time).
func _judge(types: Array, action: String) -> String:
	var best := 999.0
	for e in course.map.events:
		if types.has(e["type"]):
			var d: float = e["time"] - song_time
			if absf(d) < absf(best):
				best = d
	var w: Dictionary = course.T["music"]
	var rating := ""
	if absf(best) <= float(w["perfect_window"]):
		rating = "perfect"
		perfects += 1
	elif absf(best) <= float(w["good_window"]):
		rating = "good"
		goods += 1
	if rating != "":
		events.append({"type": "on_beat", "rating": rating, "action": action, "offset": best, "pos": ctl.pos})
	return rating


func _check_punch() -> void:
	if not ctl.punch_active():
		return
	var pr := ctl.punch_rect()
	for b in course.blocks:
		if b["alive"] and pr.intersects(b["rect"]):
			b["alive"] = false
			var off: float = song_time - float(b["data"]["time"])
			var w: Dictionary = course.T["music"]
			var rating := "perfect" if absf(off) <= float(w["perfect_window"]) else \
				("good" if absf(off) <= float(w["good_window"]) else "")
			if rating == "perfect":
				perfects += 1
			elif rating == "good":
				goods += 1
			events.append({"type": "punch_hit", "rect": b["rect"], "rating": rating, "offset": off})


func _check_pads() -> void:
	if not ctl.on_floor:
		return
	for i in course.pads.size():
		var p: Dictionary = course.pads[i]
		if not _pad_used.has(i) and ctl.pos.x >= p["x0"] and ctl.pos.x <= p["x1"]:
			_pad_used[i] = true
			ctl.bounce(MusicCourse.BOUNCE_SPEED)
			perfects += 1
			events.append({"type": "pad", "pos": Vector2(p["x0"] + 32.0, MusicCourse.GROUND_Y), "glide": p["glide"]})


func _check_lums() -> void:
	var centre := ctl.pos + Vector2(0, -ctl.height * 0.5)
	var lums: Array = course.lums
	# lums are sorted by time; skip the ones far behind
	while _lum_cursor < lums.size() and lums[_lum_cursor]["pos"].x < centre.x - 200.0:
		_lum_cursor += 1
	var i := _lum_cursor
	while i < lums.size() and lums[i]["pos"].x < centre.x + 200.0:
		if not lums_got.has(i) and centre.distance_to(lums[i]["pos"]) <= MusicCourse.LUM_RADIUS:
			lums_got[i] = true
			if song_time - last_lum_time <= LUM_CHAIN_GAP:
				chain += 1
			else:
				chain = 0
			last_lum_time = song_time
			events.append({"type": "lum", "index": i, "pos": lums[i]["pos"], "chain": chain})
		i += 1


func _check_checkpoints() -> void:
	var n := course.checkpoints.size()
	while cp_index + 1 < n and ctl.pos.x >= float(course.checkpoints[cp_index + 1]["x"]):
		cp_index += 1
		events.append({"type": "checkpoint", "index": cp_index, "pos": Vector2(course.checkpoints[cp_index]["x"], 0)})
