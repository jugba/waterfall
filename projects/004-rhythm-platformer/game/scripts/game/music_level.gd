extends LevelBase
## The music level: an auto-run locked to the song. Jumps sit on kicks, punch drums on
## snares, bounce pads and checkpoints on downbeats; the world pulses with the beat.
## Gameplay lives in MusicRun (node-free, tested); this script adds audio, visuals and HUD.
## Debug args: --autoplay (plays the ideal input script), --start-cp=N (start at checkpoint N).

const DEATH_PAUSE := 1.0

var map: Beatmap
var course: MusicCourse
var run: MusicRun
var clock: SongClock
var _dead_t := 0.0
var _count_shown := -1
var _results: Control
var _ideal: Dictionary
var _zoom_kick := 0.0
var _lum_nodes: Array = []


func _ready() -> void:
	T = Tuning.load_default()
	map = Beatmap.load_default()
	course = MusicCourse.new(map, T)
	run = MusicRun.new(course)
	world = course.world
	ctl = run.ctl
	for b in course.blocks:
		b["data"]["style"] = "drum"
	_build_stage()
	cam.music_mode = true
	backdrop.set_palette(Color(0.29, 0.2, 0.62), Color(1.0, 0.55, 0.62), Color(0.55, 0.36, 0.75),
		Color(0.25, 0.5, 0.62), Color(1.0, 0.9, 0.6))
	world_view.pads = course.pads.map(func(p): return {"x0": p["x0"], "x1": p["x1"], "y": 0.0, "glide": p["glide"]})
	world_view.flags = course.checkpoints.map(func(c): return {"pos": Vector2(c["x"], 0), "active": false})
	world_view.flags[0]["active"] = true
	world_view.goal = Vector2(course.end_x, 0)
	for b in map.length_beats:
		world_view.beat_marks.append({"x": course.x_of(map.time_of_beat(b)), "bar": b % map.beats_per_bar == 0})
	for l in course.lums:
		_lum_nodes.append({"pos": l["pos"], "alive": true})
	lum_view.lums = _lum_nodes
	lums_total = _lum_nodes.size()
	hint_label.text = "Jump %s/A on the kick   Punch %s/X on the clap   Hold Jump to glide" % [
		Settings.binding_label(&"jump"), Settings.binding_label(&"punch")]
	Audio.stop_music(0.2)
	clock = SongClock.new()
	add_child(clock)
	clock.set_stream(load(map.music_path))
	_ideal = course.ideal_inputs()
	var start_cp := int(_arg_value("--start-cp=", "0")) if OS.is_debug_build() else 0
	if start_cp > 0:
		run.cp_index = clampi(start_cp, 0, course.checkpoints.size() - 1)
		world_view.flags[0]["active"] = false
		world_view.flags[run.cp_index]["active"] = true
		clock.play_from(run.respawn())
		hero.teleport()
		cam.snap()
	else:
		clock.play_from(0.0)
	_update_info()


func _arg_value(prefix: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return fallback


func _input_now(t: float) -> InputFrame:
	if is_autoplay():
		return MusicCourse.input_for_frame(_ideal, int(ceilf(t / MusicCourse.DT - 0.0001)))
	return InputFrame.from_input()


func _physics_process(delta: float) -> void:
	match run.state:
		MusicRun.State.DEAD:
			_dead_t += delta
			if _dead_t >= DEATH_PAUSE:
				_dead_t = 0.0
				var seek := run.respawn()
				clock.play_from(seek)
				_count_shown = -1
				hero.teleport()
				cam.snap()
			return
		MusicRun.State.DONE:
			clock.advance(delta)
			_pulse(clock.time())
			return
	var t := clock.advance(delta)
	run.step(t, delta, _input_now(t))
	_handle(run.events)
	hero.sync()
	_pulse(t)
	if run.state == MusicRun.State.COUNT_IN:
		var left := int(ceilf((float(run.checkpoint()["time"]) - t) / map.beat_length()))
		if left != _count_shown and left >= 1 and left <= 3:
			_count_shown = left
			show_center(str(left), 0.4)
			Sfx.play("tick", -2.0)


func _pulse(t: float) -> void:
	var beat := map.beat_at(t)
	if beat < 0.0:
		return
	var frac := beat - floorf(beat)
	var p := exp(-frac * 6.0)
	var bar := p if int(floorf(beat)) % map.beats_per_bar == 0 else 0.0
	backdrop.pulse = p
	backdrop.bar_pulse = maxf(bar, backdrop.bar_pulse * 0.9)
	world_view.pulse = p
	lum_view.pulse = p
	if run.state == MusicRun.State.RUN and frac < 0.1:
		hero.pulse(0.6)


func _handle(events: Array) -> void:
	for e in events:
		match e["type"]:
			"go":
				show_center("GO!", 0.5)
				Sfx.play("go", -4.0)
			"on_beat":
				_rate(e["rating"], e["pos"] + Vector2(0, -80))
			"punch_hit":
				var r: Rect2 = e["rect"]
				fx.sparks(r.get_center(), 18, Color(1.0, 0.4, 0.5), 520.0)
				fx.sparks(r.get_center(), 10, Color(1.0, 0.85, 0.35), 380.0)
				fx.ring(r.get_center(), 90.0, Color(1, 1, 1, 0.9), 0.22)
				cam.add_shake(float(T["feel"]["shake_punch"]))
				_zoom_kick = 1.0
				Sfx.play("hit", -1.0)
				if e["rating"] != "":
					_rate(e["rating"], r.get_center() + Vector2(0, -120))
			"pad":
				world_view.pads[e["index"]]["squash"] = 1.0
				fx.ring(e["pos"], 90.0, Color(1, 0.6, 0.85), 0.3)
				_rate("perfect", e["pos"] + Vector2(0, -90), "BOING!")
			"lum":
				_lum_nodes[e["index"]]["alive"] = false
				collect_lum(e["pos"], e["chain"])
			"checkpoint":
				for f in world_view.flags:
					f["active"] = false
				world_view.flags[e["index"]]["active"] = true
				fx.popup(e["pos"] + Vector2(0, -150), "Checkpoint!", Color(0.5, 1.0, 0.6), 36)
				Sfx.play("checkpoint", -5.0)
			"death":
				fx.dust(e["pos"], 16, Vector2.ZERO)
				fx.sparks(e["pos"] + Vector2(0, -26), 16, Color(1.0, 0.62, 0.26), 400.0)
				cam.add_shake(10.0)
				Sfx.play("death", -4.0)
				clock.stop()
				show_center("Oops!", 0.9)
			"finish":
				Sfx.play("win", -2.0)
				fx.sparks(ctl.pos + Vector2(0, -60), 40, Color(1, 0.9, 0.4), 600.0)
				_show_results()
	_update_info()


func _rate(rating: String, at: Vector2, text := "") -> void:
	if rating == "perfect":
		fx.popup(at, text if text != "" else "PERFECT!", Color(1.0, 0.92, 0.35), 40)
		fx.ring(at + Vector2(0, 30), 70.0, Color(1.0, 0.95, 0.5, 0.9), 0.3)
		backdrop.bar_pulse = 1.0
		hero.grin()
		Sfx.play("perfect", -9.0, 1.0, 0.0)
	elif rating == "good":
		fx.popup(at, text if text != "" else "Good", Color(0.6, 0.95, 1.0), 32)


func _process(delta: float) -> void:
	super._process(delta)
	_zoom_kick = maxf(_zoom_kick - delta * 6.0, 0.0)
	cam.zoom = Vector2.ONE * cam.base_zoom() * (1.0 + 0.035 * _zoom_kick)


func _update_info() -> void:
	info_label.text = "On beat %d   Deaths %d" % [run.perfects + run.goods, run.deaths]


func _show_results() -> void:
	if _results:
		return
	_results = PanelContainer.new()
	_results.anchor_left = 0.5
	_results.anchor_right = 0.5
	_results.anchor_top = 0.5
	_results.anchor_bottom = 0.5
	_results.offset_left = -300
	_results.offset_right = 300
	_results.offset_top = -220
	_results.offset_bottom = 220
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_results.add_child(v)
	for line in [["Level complete!", 56], ["Notes  %d / %d" % [lums_got, lums_total], 36],
			["On the beat  %d" % (run.perfects + run.goods), 36], ["Deaths  %d" % run.deaths, 36]]:
		var l := Label.new()
		l.text = line[0]
		l.add_theme_font_size_override("font_size", line[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var again := Button.new()
	again.text = "Play again"
	again.custom_minimum_size = Vector2(320, 64)
	again.pressed.connect(func(): SceneChanger.change_to("res://scenes/music_level.tscn"))
	v.add_child(again)
	var title := Button.new()
	title.text = "Title"
	title.custom_minimum_size = Vector2(320, 64)
	title.pressed.connect(func(): SceneChanger.change_to("res://scenes/title.tscn"))
	v.add_child(title)
	hud.add_child(_results)
	again.grab_focus()
