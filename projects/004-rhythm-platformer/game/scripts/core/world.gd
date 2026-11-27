class_name World
extends RefCounted
## Axis-aligned level geometry for the custom platformer physics.
## A solid is a Dictionary: {rect: Rect2, kind: String, alive: bool, id: int, data: Dictionary}.
## kinds: "solid", "oneway" (land from above only), "breakable" (solid until punched), "bounce" (solid pad).

const CELL := 128.0

var solids: Array = []
var _cells: Dictionary = {}  # int column -> Array of solids


func add(rect: Rect2, kind := "solid", data := {}) -> Dictionary:
	var s := {"rect": rect, "kind": kind, "alive": true, "id": solids.size(), "data": data}
	solids.append(s)
	var c0 := int(floorf(rect.position.x / CELL))
	var c1 := int(floorf(rect.end.x / CELL))
	for c in range(c0, c1 + 1):
		if not _cells.has(c):
			_cells[c] = []
		_cells[c].append(s)
	return s


## Alive solids whose rect overlaps r (strictly; touching edges do not count).
func query(r: Rect2) -> Array:
	var out: Array = []
	var seen := {}
	var c0 := int(floorf(r.position.x / CELL))
	var c1 := int(floorf(r.end.x / CELL))
	for c in range(c0, c1 + 1):
		for s in _cells.get(c, []):
			if s["alive"] and not seen.has(s["id"]) and r.intersects(s["rect"]):
				seen[s["id"]] = true
				out.append(s)
	return out


func bounds() -> Rect2:
	if solids.is_empty():
		return Rect2()
	var b: Rect2 = solids[0]["rect"]
	for s in solids:
		b = b.merge(s["rect"])
	return b
