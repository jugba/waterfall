class_name Neatness
extends RefCounted
## Freeform neatness scorer. There is no target layout: any tidy arrangement scores well
## (memories/design/freeform-scoring-beats-single-solution-in-cozy-puzzles).
##
## Input: one entry per item, made with Neatness.entry():
##   rect      Rect2 in desk grid cells (axis-aligned footprint at the item's nearest 90 deg turn)
##   angle     rotation in degrees (any value; 0/90/180/270 are "square")
##   category  e.g. "writing"
##   colour    e.g. "red"
## Output (evaluate): {"total": 0..100 int, "parts": {name: 0..1}, "reasons": [{key, text, points, max}]}
##
## Four parts, each 0..1, weighted into the total:
##   square   items at right angles, and long items parallel within their category
##   align    each item shares an edge or centre line with a nearby item (rows / columns)
##   spacing  each item's gap to its nearest neighbour matches the layout's typical gap; overlaps cost
##   group    row/column neighbours share the item's category or colour, above what chance would give

const WEIGHTS := {"square": 20.0, "align": 30.0, "spacing": 25.0, "group": 25.0}
const ORDER := ["square", "align", "spacing", "group"]
const EPS := 0.2               ## cells: two edges closer than this count as aligned
const REACH := 4.0             ## cells: max gap between two items that line up as row/column mates
const SQUARE_TOL_DEG := 10.0   ## an item this far off a right angle scores 0 for squareness
const SPACING_TOL := 0.35      ## cells: a nearest gap within this of the median gap is "even"


static func entry(rect: Rect2, angle_deg: float, category: String, colour: String) -> Dictionary:
	return {"rect": rect, "angle": angle_deg, "category": category, "colour": colour}


static func evaluate(entries: Array) -> Dictionary:
	var n := entries.size()
	var parts := {"square": 0.0, "align": 0.0, "spacing": 0.0, "group": 0.0}
	var info := {"square_count": 0, "overlaps": 0, "group_by": "type"}
	if n == 0:
		return _result(parts, info, n)
	var sq: Array[float] = []
	for e in entries:
		var s := squareness(float(e["angle"]))
		sq.append(s)
		if s >= 0.5:
			info["square_count"] += 1
	parts["square"] = _square_part(entries, sq)
	if n == 1:
		parts["align"] = sq[0]
		parts["spacing"] = 1.0
		parts["group"] = 1.0
		return _result(parts, info, n)
	parts["align"] = _align_part(entries, sq)
	parts["spacing"] = _spacing_part(entries, info)
	parts["group"] = _group_part(entries, info)
	return _result(parts, info, n)


## 1.0 at a right angle, falling to 0.0 at SQUARE_TOL_DEG off.
static func squareness(angle_deg: float) -> float:
	var dev := absf(fposmod(angle_deg + 45.0, 90.0) - 45.0)
	return clampf(1.0 - dev / SQUARE_TOL_DEG, 0.0, 1.0)


static func _square_part(entries: Array, sq: Array[float]) -> float:
	var mean_sq := 0.0
	for s in sq:
		mean_sq += s
	mean_sq /= sq.size()
	# Parallel: long items within one category point the same way (rows of pens, not a pick-up-sticks pile).
	var dirs := {}  # category -> [horizontal, vertical]
	var elongated := 0
	for i in entries.size():
		var r: Rect2 = entries[i]["rect"]
		if is_equal_approx(r.size.x, r.size.y):
			continue
		elongated += 1
		if sq[i] < 0.5:
			continue
		var cat: String = entries[i]["category"]
		if not dirs.has(cat):
			dirs[cat] = [0, 0]
		dirs[cat][0 if r.size.x > r.size.y else 1] += 1
	var parallel := mean_sq
	if elongated > 0:
		var matched := 0
		for cat in dirs:
			matched += maxi(dirs[cat][0], dirs[cat][1])
		parallel = float(matched) / elongated
	return 0.6 * mean_sq + 0.4 * parallel


## Signed gaps between two rects on each axis (negative = they overlap on that axis).
static func _gaps(a: Rect2, b: Rect2) -> Vector2:
	return Vector2(
		maxf(b.position.x - a.end.x, a.position.x - b.end.x),
		maxf(b.position.y - a.end.y, a.position.y - b.end.y))


static func _align_part(entries: Array, sq: Array[float]) -> float:
	var total := 0.0
	for i in entries.size():
		var a: Rect2 = entries[i]["rect"]
		var row := false
		var col := false
		for j in entries.size():
			if i == j or sq[j] < 0.5:
				continue
			var b: Rect2 = entries[j]["rect"]
			var g := _gaps(a, b)
			if not row and g.x >= -EPS and g.x <= REACH and (
					absf(a.position.y - b.position.y) < EPS or absf(a.end.y - b.end.y) < EPS
					or absf(a.get_center().y - b.get_center().y) < EPS):
				row = true
			if not col and g.y >= -EPS and g.y <= REACH and (
					absf(a.position.x - b.position.x) < EPS or absf(a.end.x - b.end.x) < EPS
					or absf(a.get_center().x - b.get_center().x) < EPS):
				col = true
		var s := (0.75 if (row or col) else 0.0) + (0.25 if (row and col) else 0.0)
		total += s * sq[i]
	return total / entries.size()


static func _spacing_part(entries: Array, info: Dictionary) -> float:
	var n := entries.size()
	var nearest: Array[float] = []
	var overlapping := 0
	for i in n:
		var a: Rect2 = entries[i]["rect"]
		var best := INF
		var overlaps := false
		for j in n:
			if i == j:
				continue
			var g := _gaps(a, entries[j]["rect"])
			var d: float
			if g.x < -EPS and g.y < -EPS:
				overlaps = true
				d = 0.0
			elif g.x > 0.0 and g.y > 0.0:
				d = g.length()  # diagonal neighbour
			else:
				d = maxf(maxf(g.x, g.y), 0.0)
			best = minf(best, d)
		if overlaps:
			overlapping += 1
		nearest.append(best)
	info["overlaps"] = overlapping
	var sorted := nearest.duplicate()
	sorted.sort()
	var median: float = sorted[n / 2] if n % 2 == 1 else (sorted[n / 2 - 1] + sorted[n / 2]) * 0.5
	var even := 0
	for d in nearest:
		if absf(d - median) <= SPACING_TOL:
			even += 1
	return float(even) / n * (1.0 - float(overlapping) / n)


static func _group_part(entries: Array, info: Dictionary) -> float:
	var nbs: Array = []
	for i in entries.size():
		nbs.append(neighbours(entries, i))
	var by_type := _scheme_score(entries, nbs, "category")
	var by_colour := _scheme_score(entries, nbs, "colour")
	info["group_by"] = "colour" if by_colour > by_type else "type"
	return maxf(by_type, by_colour)


## How well items are grouped by one key ("category" or "colour"): the share of each item's
## neighbours with the same key, rescaled so chance level is 0 and perfect is 1.
## Items with no other item of the same key are left out (they cannot be grouped).
static func _scheme_score(entries: Array, nbs: Array, key: String) -> float:
	var n := entries.size()
	var count := {}
	for e in entries:
		count[e[key]] = count.get(e[key], 0) + 1
	var observed := 0.0
	var baseline := 0.0
	var counted := 0
	for i in n:
		var v: String = entries[i][key]
		if count[v] < 2:
			continue
		var nb: Array[int] = nbs[i]
		var same := 0
		for j in nb:
			same += 1 if entries[j][key] == v else 0
		observed += float(same) / nb.size()
		baseline += float(count[v] - 1) / (n - 1)
		counted += 1
	if counted == 0:
		return 0.0
	observed /= counted
	baseline /= counted
	if baseline >= 0.999:
		return 1.0
	return clampf((observed - baseline) / (1.0 - baseline), 0.0, 1.0)


## The items "next to" item i: its nearest row mate on the left and right and nearest column
## mate above and below (aligned and within REACH), keeping only those at the smallest of
## those gaps. With no mates, its nearest item by edge gap.
static func neighbours(entries: Array, i: int) -> Array[int]:
	var a: Rect2 = entries[i]["rect"]
	var best := {"l": [INF, -1], "r": [INF, -1], "u": [INF, -1], "d": [INF, -1]}
	var nearest := -1
	var nearest_d := INF
	for j in entries.size():
		if j == i:
			continue
		var b: Rect2 = entries[j]["rect"]
		var g := _gaps(a, b)
		var d := maxf(g.x, 0.0) + maxf(g.y, 0.0) + a.get_center().distance_to(b.get_center()) * 0.001
		if d < nearest_d:
			nearest_d = d
			nearest = j
		if g.x >= -EPS and g.x <= REACH and (absf(a.position.y - b.position.y) < EPS
				or absf(a.end.y - b.end.y) < EPS or absf(a.get_center().y - b.get_center().y) < EPS):
			var side := "r" if b.get_center().x > a.get_center().x else "l"
			if g.x < best[side][0]:
				best[side] = [g.x, j]
		if g.y >= -EPS and g.y <= REACH and (absf(a.position.x - b.position.x) < EPS
				or absf(a.end.x - b.end.x) < EPS or absf(a.get_center().x - b.get_center().x) < EPS):
			var side := "d" if b.get_center().y > a.get_center().y else "u"
			if g.y < best[side][0]:
				best[side] = [g.y, j]
	# Only mates at the item's smallest gap count: a wider gap is how knolling separates groups.
	var min_gap := INF
	for side in best:
		if best[side][1] >= 0:
			min_gap = minf(min_gap, best[side][0])
	var out: Array[int] = []
	for side in best:
		var j: int = best[side][1]
		if j >= 0 and best[side][0] <= min_gap + SPACING_TOL and not out.has(j):
			out.append(j)
	if out.is_empty() and nearest >= 0:
		out.append(nearest)
	return out


static func _result(parts: Dictionary, info: Dictionary, n: int) -> Dictionary:
	var total := 0.0
	var reasons: Array[Dictionary] = []
	for key in ORDER:
		var pts: float = parts[key] * WEIGHTS[key]
		total += pts
		reasons.append({"key": key, "text": _reason_text(key, parts[key], info, n),
			"points": roundi(pts), "max": int(WEIGHTS[key])})
	return {"total": clampi(roundi(total), 0, 100), "parts": parts, "reasons": reasons, "info": info}


static func _reason_text(key: String, v: float, info: Dictionary, n: int) -> String:
	match key:
		"square":
			return "Square to the desk (%d/%d)" % [info["square_count"], n]
		"align":
			return "Lined up in rows" if v >= 0.6 else ("Some rows line up" if v >= 0.3 else "Nothing lines up")
		"spacing":
			if info["overlaps"] > 0:
				return "Even spacing (%d overlapping)" % info["overlaps"]
			return "Even spacing" if v >= 0.6 else "Uneven gaps"
		"group":
			return ("Grouped by %s" % info["group_by"]) if v >= 0.5 else "Mixed-up groups"
	return key
