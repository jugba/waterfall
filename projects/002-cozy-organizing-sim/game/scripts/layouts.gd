class_name Layouts
extends RefCounted
## Tidy reference layouts in grid cells. Used by the tests (to prove different tidy layouts
## all score high), by the debug "auto-arrange" key, and by the greybox capture.


## Rows left to right, wrapping at `cols` (`row_gap` between rows). `groups[i]` is a group key per item (same order as
## `sizes`); a change of group adds `group_gap` instead of `gap`. Returns one Rect2i per size.
static func shelf(sizes: Array[Vector2i], cols: int, gap := 1, groups: Array = [], group_gap := -1, row_gap := -1) -> Array[Rect2i]:
	if group_gap < 0:
		group_gap = gap
	if row_gap < 0:
		row_gap = gap
	var out: Array[Rect2i] = []
	var x := 0
	var y := 0
	var row_h := 0
	for i in sizes.size():
		var s := sizes[i]
		var step := 0
		if x > 0:
			var changed: bool = not groups.is_empty() and groups[i] != groups[i - 1]
			step = group_gap if changed else gap
		if x > 0 and x + step + s.x > cols:
			x = 0
			y += row_h + row_gap
			row_h = 0
			step = 0
		x += step
		out.append(Rect2i(Vector2i(x, y), s))
		x += s.x
		row_h = maxi(row_h, s.y)
	return out


## Swap x/y of every rect: rows become columns and every item turns 90 degrees.
static func transposed(rects: Array[Rect2i]) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	for r in rects:
		out.append(Rect2i(Vector2i(r.position.y, r.position.x), Vector2i(r.size.y, r.size.x)))
	return out


static func bounds(rects: Array[Rect2i]) -> Rect2i:
	if rects.is_empty():
		return Rect2i()
	var b := rects[0]
	for r in rects:
		b = b.merge(r)
	return b


## Moves the layout so its bounding box is centred in a cols x rows area.
static func centred(rects: Array[Rect2i], cols: int, rows: int) -> Array[Rect2i]:
	var b := bounds(rects)
	var off := Vector2i((cols - b.size.x) / 2, (rows - b.size.y) / 2) - b.position
	off = Vector2i(maxi(off.x, -b.position.x), maxi(off.y, -b.position.y))
	var out: Array[Rect2i] = []
	for r in rects:
		out.append(Rect2i(r.position + off, r.size))
	return out


## Sort key used by auto-arrange: category, then colour, then longest first.
static func sort_by_type(items: Array) -> Array:
	var sorted := items.duplicate()
	sorted.sort_custom(func(a, b):
		var da: Dictionary = a if a is Dictionary else a.data
		var db: Dictionary = b if b is Dictionary else b.data
		if da["category"] != db["category"]:
			return da["category"] < db["category"]
		if da["colour"] != db["colour"]:
			return da["colour"] < db["colour"]
		return int(da["w"]) * 10 + int(da["h"]) > int(db["w"]) * 10 + int(db["h"]))
	return sorted


## Same, but colour first (rainbow-style knolling).
static func sort_by_colour(items: Array) -> Array:
	var sorted := items.duplicate()
	sorted.sort_custom(func(a, b):
		var da: Dictionary = a if a is Dictionary else a.data
		var db: Dictionary = b if b is Dictionary else b.data
		if da["colour"] != db["colour"]:
			return da["colour"] < db["colour"]
		return int(da["w"]) * 10 + int(da["h"]) > int(db["w"]) * 10 + int(db["h"]))
	return sorted


## One row per group (wrapping inside a group if it is wider than `cols`): `gap` between items,
## `group_gap` between rows. `groups[i]` is the group key of item i; items must be sorted by it.
static func grouped_rows(sizes: Array[Vector2i], groups: Array, cols: int, gap := 1, group_gap := 2) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var x := 0
	var y := 0
	var row_h := 0
	for i in sizes.size():
		var s := sizes[i]
		var new_group: bool = i > 0 and groups[i] != groups[i - 1]
		if i > 0 and (new_group or x + gap + s.x > cols):
			y += row_h + (group_gap if new_group else gap)
			x = 0
			row_h = 0
		elif i > 0:
			x += gap
		out.append(Rect2i(Vector2i(x, y), s))
		x += s.x
		row_h = maxi(row_h, s.y)
	return out


## Tidy layout that fits a cols x rows desk: one row per group if that fits, else groups
## flowing along rows with wider gaps between groups and rows. Centred.
static func fit_desk(sizes: Array[Vector2i], groups: Array, cols: int, rows: int) -> Array[Rect2i]:
	var r := grouped_rows(sizes, groups, cols - 2, 1, 2)
	if bounds(r).size.y > rows:
		r = shelf(sizes, cols - 2, 1, groups, 3, 2)
	if bounds(r).size.y > rows:
		r = shelf(sizes, cols, 1, groups, 2, 1)
	return centred(r, cols, rows)


## Packs footprints into a cols x rows container: biggest first, each at the first free cell in
## reading order, trying it as given (long axis horizontal) and then turned 90 deg. `occupied`
## cells are already taken. Returns one Rect2i per size (same order; a rect whose size is
## swapped means "turned"), or an empty array if something does not fit.
static func pack_into(sizes: Array[Vector2i], cols: int, rows: int, occupied: Array[Rect2i] = []) -> Array[Rect2i]:
	var order: Array = range(sizes.size())
	order.sort_custom(func(a, b):
		var sa: Vector2i = sizes[a]
		var sb: Vector2i = sizes[b]
		if sa.x * sa.y != sb.x * sb.y:
			return sa.x * sa.y > sb.x * sb.y
		return maxi(sa.x, sa.y) > maxi(sb.x, sb.y))
	var taken: Array[Rect2i] = occupied.duplicate()
	var out: Array[Rect2i] = []
	out.resize(sizes.size())
	for i in order:
		var s: Vector2i = sizes[i]
		var found := false
		for y in rows:
			for x in cols:
				for size in [s, Vector2i(s.y, s.x)]:
					var r := Rect2i(Vector2i(x, y), size)
					if r.end.x > cols or r.end.y > rows:
						continue
					var free := true
					for t in taken:
						if t.intersects(r):
							free = false
							break
					if free:
						out[i] = r
						taken.append(r)
						found = true
						break
				if found:
					break
			if found:
				break
		if not found:
			return []
	return out
