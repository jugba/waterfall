extends GutTest
## Music level: a scripted input replay completes it; timing windows are fair; death
## respawns at the checkpoint with the music re-synced; the scene loads and runs.

const DT := MusicCourse.DT

var course: MusicCourse


func before_all() -> void:
	course = MusicCourse.new(Beatmap.load_default(), Tuning.load_default())


func _play(run: MusicRun, script: Dictionary, shift := 0, max_t := 0.0) -> void:
	var f := 0
	var stop := max_t if max_t > 0.0 else course.map.duration
	while f * DT < stop and run.state != MusicRun.State.DONE and run.state != MusicRun.State.DEAD:
		run.step(f * DT, DT, MusicCourse.input_for_frame(script, f - shift))
		f += 1


func test_ideal_replay_completes_the_level() -> void:
	var run := MusicRun.new(course)
	_play(run, course.ideal_inputs())
	assert_eq(run.state, MusicRun.State.DONE, "reached the goal")
	assert_eq(run.deaths, 0)
	assert_gte(run.lums_got.size(), int(course.lums.size() * 0.95), "collects the on-beat notes on the way")
	assert_gt(run.perfects, 30, "on-beat inputs are rated perfect")
	course.reset_blocks_after(0.0)


func test_replay_completes_with_inputs_50ms_early_or_late() -> void:
	for shift in [-3, 3]:
		var run := MusicRun.new(course)
		_play(run, course.ideal_inputs(), shift)
		assert_eq(run.state, MusicRun.State.DONE, "completes with inputs shifted %d ms" % (shift * 1000 / 60))
		course.reset_blocks_after(0.0)


func test_no_input_dies_at_the_first_obstacle() -> void:
	var run := MusicRun.new(course)
	_play(run, {"presses": {}, "holds": {}})
	assert_eq(run.state, MusicRun.State.DEAD)
	var first: float = course.map.of_type(["jump"])[0]["time"]
	assert_almost_eq(run.song_time, first, 0.5, "dies right at the first jump")
	course.reset_blocks_after(0.0)


func test_death_respawns_at_checkpoint_and_resyncs_music() -> void:
	var run := MusicRun.new(course)
	var cp: Dictionary = course.checkpoints[2]
	var script := course.ideal_inputs()
	_play(run, script, 0, float(cp["time"]) + 2.0)
	assert_eq(run.cp_index, 2, "passed checkpoint 2")
	# stop pressing: die at the next obstacle
	var f := int(run.song_time / DT)
	while run.state == MusicRun.State.RUN and f < 10000:
		run.step(f * DT, DT, InputFrame.new())
		f += 1
	assert_eq(run.state, MusicRun.State.DEAD)
	var seek := run.respawn()
	var lead := float(course.T["music"]["respawn_lead_beats"]) * course.map.beat_length()
	assert_almost_eq(seek, float(cp["time"]) - lead, 0.001, "music restarts a count-in before the checkpoint")
	assert_eq(run.state, MusicRun.State.COUNT_IN)
	assert_almost_eq(run.ctl.pos.x, float(cp["x"]), 0.5, "back at the checkpoint")
	# play on from the seek point with the ideal script: x stays locked to audio time
	f = int(ceil(seek / DT))
	var checked := false
	while run.state != MusicRun.State.DONE and run.state != MusicRun.State.DEAD and f < 10000:
		run.step(f * DT, DT, MusicCourse.input_for_frame(script, f))
		if not checked and f * DT > float(cp["time"]) + 1.0:
			assert_almost_eq(run.ctl.pos.x, course.x_of(f * DT), 1.0, "x matches audio time after respawn")
			checked = true
		f += 1
	assert_eq(run.state, MusicRun.State.DONE, "finishes after the respawn")
	assert_eq(run.deaths, 1)
	course.reset_blocks_after(0.0)


func test_music_level_scene_loads_and_runs() -> void:
	var level: Node = add_child_autofree(load("res://scenes/music_level.tscn").instantiate())
	level.clock.manual = true
	await wait_physics_frames(20)
	assert_not_null(level.run)
	assert_true(level.run.state == MusicRun.State.RUN or level.run.state == MusicRun.State.COUNT_IN)
	assert_gt(level.clock.time(), 0.1, "song clock advancing")
	assert_gt(level.lums_total, 100)
