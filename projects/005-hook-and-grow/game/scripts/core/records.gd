class_name Records
extends RefCounted
## Personal records kept in SaveGame slot 0: runs, wins, best time to eat the boss, biggest size.
## Pure functions so tests can check them without the scene.


static func from_save(data: Dictionary) -> Dictionary:
	return {
		"runs": int(_num(data.get("runs"), 0.0)),
		"wins": int(_num(data.get("wins"), 0.0)),
		"best_win_time": _num(data.get("best_win_time"), -1.0),
		"best_size": _num(data.get("best_size"), 0.0),
	}


## Save files are user data: anything that isn't a number falls back to the default.
static func _num(v, fallback: float) -> float:
	if v is int or v is float:
		return float(v)
	return fallback


static func add_run(rec: Dictionary, run_time: float, final_size: float, won: bool) -> Dictionary:
	var r := from_save(rec)
	r["runs"] += 1
	r["best_size"] = maxf(r["best_size"], final_size)
	if won:
		r["wins"] += 1
		if r["best_win_time"] < 0.0 or run_time < r["best_win_time"]:
			r["best_win_time"] = run_time
	return r


static func format_time(t: float) -> String:
	if t < 0.0:
		return "--:--"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
