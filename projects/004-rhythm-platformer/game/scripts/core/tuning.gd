class_name Tuning
extends RefCounted
## Loads res://data/movement.json (all movement and feel tuning) into a Dictionary.
## Usage: var t := Tuning.load_default(); t["jump"]["height"]

const PATH := "res://data/movement.json"

static var _cache: Dictionary = {}


static func load_default(force := false) -> Dictionary:
	if force or _cache.is_empty():
		_cache = load_file(PATH)
	return _cache


static func load_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK or not (j.data is Dictionary):
		return {}
	return j.data


## Piecewise-linear curve from [[x, y], ...] points (x ascending).
static func sample_curve(points: Array, x: float) -> float:
	if points.is_empty():
		return 1.0
	if x <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		var a: Array = points[i - 1]
		var b: Array = points[i]
		if x <= float(b[0]):
			var span := float(b[0]) - float(a[0])
			var k := 0.0 if span <= 0.0 else (x - float(a[0])) / span
			return lerpf(float(a[1]), float(b[1]), k)
	return float(points[-1][1])
