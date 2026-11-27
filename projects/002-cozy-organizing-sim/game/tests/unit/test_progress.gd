extends GutTest
## Job unlocks, stars and best scores, saved through SaveGame; the job select screen reflects them.

const JOBS := "res://scenes/job_select.tscn"

var _orig_save_dir: String


func before_each() -> void:
	_orig_save_dir = SaveGame.directory
	SaveGame.directory = "user://test_progress_saves"
	SaveGame.delete_slot(0)
	Progress.pending_job = -1


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_save_dir
	Progress.pending_job = -1


func test_new_save_unlocks_only_first_job() -> void:
	var p := Progress.load_progress()
	assert_true(Progress.is_unlocked(p, 0))
	assert_false(Progress.is_unlocked(p, 1))
	assert_eq(Progress.unlocked_count(p), 1)
	assert_eq(Progress.suggested_job(p), 0)
	assert_eq(Progress.stars(p, 0), 0, "unplayed: no stars")


func test_completion_unlocks_next_and_survives_save() -> void:
	var p := Progress.load_progress()
	assert_true(Progress.record_best(p, 0, 80))
	assert_false(Progress.record_best(p, 0, 60), "lower score is not a best")
	assert_eq(Progress.best(p, 0), 80)
	assert_eq(Progress.mark_completed(p, 0), 1, "finishing job 1 unlocks job 2")
	assert_eq(Progress.mark_completed(p, 0), -1, "replaying unlocks nothing new")
	assert_eq(Progress.save(p), OK)
	var q := Progress.load_progress()
	assert_true(Progress.is_unlocked(q, 1))
	assert_false(Progress.is_unlocked(q, 2))
	assert_eq(Progress.best(q, 0), 80)
	assert_eq(Progress.suggested_job(q), 1)
	assert_eq(Progress.mark_completed(q, Catalog.job_count() - 1), -1, "last job unlocks nothing")


func test_stars_follow_job_thresholds() -> void:
	var j := {"stars": [50, 70, 88]}
	assert_eq(Progress.stars_for(j, 49), 0)
	assert_eq(Progress.stars_for(j, 50), 1)
	assert_eq(Progress.stars_for(j, 87), 2)
	assert_eq(Progress.stars_for(j, 88), 3)
	assert_eq(Progress.stars_for({}, 90), 3, "default thresholds")
	assert_eq(Progress.stars_for({"stars": "bad"}, 60), 1, "bad data falls back to defaults")


func test_v010_save_migrates() -> void:
	# v0.1.0 saved only next_job / best / money.
	SaveGame.save_slot(0, {"next_job": 2, "money": 70, "best": {"mia_pencil_case": 91}})
	var p := Progress.load_progress()
	assert_true(Progress.is_unlocked(p, 2), "jobs before next_job count as completed")
	assert_eq(Progress.stars(p, 0), 3)
	assert_eq(int(p["money"]), 70)


func test_job_select_lists_jobs_and_locks() -> void:
	var p := Progress.load_progress()
	Progress.record_best(p, 0, 72)
	Progress.mark_completed(p, 0)
	Progress.save(p)
	var s: Control = load(JOBS).instantiate()
	add_child_autofree(s)
	await wait_frames(2)
	assert_eq(s.rows.size(), Catalog.job_count(), "one row per job in jobs.json")
	assert_false(s.rows[0].disabled)
	assert_false(s.rows[1].disabled)
	assert_true(s.rows[2].disabled, "job 3 locked")
	assert_eq(s.rows[2].focus_mode, Control.FOCUS_NONE, "locked rows are skipped by controller focus")
	assert_eq(s.rows[0].find_child("Stars", true, false).count, 2, "72% on job 1 = 2 stars")
	assert_true(s.rows[1].has_focus(), "focus starts on the next job to play")
	assert_false(s.choose(2), "locked job can't be started")
	assert_eq(Progress.pending_job, -1)


func test_game_starts_the_chosen_job() -> void:
	var p := Progress.load_progress()
	Progress.mark_completed(p, 0)
	Progress.save(p)
	Progress.pending_job = 1
	var g: Node = load("res://scenes/game.tscn").instantiate()
	g.rng_seed = 5
	add_child_autofree(g)
	assert_eq(g.job_index, 1)
	assert_eq(Progress.pending_job, -1, "consumed")
