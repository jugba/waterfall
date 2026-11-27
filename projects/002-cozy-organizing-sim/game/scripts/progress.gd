class_name Progress
extends RefCounted
## Career progress kept in SaveGame slot 0 as a plain Dictionary:
##   {"money": int, "next_job": int, "best": {job_id: score}, "completed": [job_id, ...]}
## A job is unlocked when it is the first job or the job before it has been completed
## (packed and returned). Stars come from each job's optional "stars" thresholds in jobs.json.

const SAVE_SLOT := 0
const DEFAULT_STARS := [55, 75, 90]

## Job the job-select screen asked the game scene to start (-1 = none). Consumed by game.gd.
static var pending_job := -1


static func load_progress() -> Dictionary:
	return normalize(SaveGame.load_slot(SAVE_SLOT))


static func save(p: Dictionary) -> Error:
	return SaveGame.save_slot(SAVE_SLOT, p)


## Fills in missing keys. v0.1.0 saves had no "completed" list: every job before "next_job"
## had been finished, so those count as completed.
static func normalize(p: Dictionary) -> Dictionary:
	if not (p.get("best") is Dictionary):
		p["best"] = {}
	p["money"] = int(p.get("money", 0))
	p["next_job"] = int(p.get("next_job", 0))
	if not (p.get("completed") is Array):
		var done: Array = []
		for i in mini(p["next_job"], Catalog.job_count()):
			done.append(String(Catalog.job(i).get("id", "")))
		p["completed"] = done
	return p


static func job_id(index: int) -> String:
	return String(Catalog.job(index).get("id", ""))


static func best(p: Dictionary, index: int) -> int:
	return int(p.get("best", {}).get(job_id(index), 0))


static func is_completed(p: Dictionary, index: int) -> bool:
	return p.get("completed", []).has(job_id(index))


static func is_unlocked(p: Dictionary, index: int) -> bool:
	if index <= 0:
		return true
	if index >= Catalog.job_count():
		return false
	return is_completed(p, index - 1)


static func unlocked_count(p: Dictionary) -> int:
	var n := 0
	for i in Catalog.job_count():
		n += 1 if is_unlocked(p, i) else 0
	return n


static func thresholds(job: Dictionary) -> Array:
	var s = job.get("stars", DEFAULT_STARS)
	return s if s is Array and s.size() == 3 else DEFAULT_STARS


## 0..3 stars for a score on this job (0 if never played).
static func stars_for(job: Dictionary, score: int) -> int:
	var n := 0
	for t in thresholds(job):
		n += 1 if score >= int(t) else 0
	return n


static func stars(p: Dictionary, index: int) -> int:
	return stars_for(Catalog.job(index), best(p, index)) if p.get("best", {}).has(job_id(index)) else 0


## Keeps the higher score. Returns true for a new best.
static func record_best(p: Dictionary, index: int, score: int) -> bool:
	var b: Dictionary = p.get("best", {})
	var id := job_id(index)
	var is_new := not b.has(id) or score > int(b[id])
	if is_new:
		b[id] = score
	p["best"] = b
	return is_new


## Marks a job finished. Returns the index of a job this unlocked, or -1.
static func mark_completed(p: Dictionary, index: int) -> int:
	var unlocked_before := is_unlocked(p, index + 1)
	var done: Array = p.get("completed", [])
	var id := job_id(index)
	if not done.has(id):
		done.append(id)
	p["completed"] = done
	p["next_job"] = mini(index + 1, Catalog.job_count() - 1)
	if not unlocked_before and is_unlocked(p, index + 1):
		return index + 1
	return -1


## The job to offer by default: the first unlocked job not yet completed, else the last one.
static func suggested_job(p: Dictionary) -> int:
	for i in Catalog.job_count():
		if is_unlocked(p, i) and not is_completed(p, i):
			return i
	return maxi(0, Catalog.job_count() - 1)
