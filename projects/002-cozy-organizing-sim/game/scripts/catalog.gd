class_name Catalog
extends RefCounted
## Data-driven content: the item catalogue (res://data/items.json) and the handcrafted jobs
## (res://data/jobs.json). Loaded once and cached. Uses JSON.new().parse() because
## JSON.parse_string() logs engine errors on bad input (memories/tech/gut-fails-tests-on-unasserted-engine-errors).

const ITEMS_PATH := "res://data/items.json"
const JOBS_PATH := "res://data/jobs.json"

## Greybox palette. Item "colour" fields are keys of this table (they also drive colour grouping).
const COLOURS := {
	"red": Color("e05a4f"), "orange": Color("f0954a"), "yellow": Color("f2cf4a"),
	"green": Color("72bb66"), "teal": Color("4fb3a9"), "blue": Color("5b8fd9"),
	"purple": Color("9b72cf"), "pink": Color("e98bb5"), "brown": Color("a87b55"),
	"black": Color("3c3f47"), "grey": Color("9aa1ab"), "white": Color("ece8df"),
}

static var _items: Dictionary = {}
static var _jobs: Array = []


static func items() -> Dictionary:
	if _items.is_empty():
		var root = _load_json(ITEMS_PATH)
		if root is Dictionary:
			for it in root.get("items", []):
				_items[String(it["id"])] = it
	return _items


static func item(id: String) -> Dictionary:
	return items().get(id, {})


static func jobs() -> Array:
	if _jobs.is_empty():
		var root = _load_json(JOBS_PATH)
		if root is Dictionary:
			_jobs = root.get("jobs", [])
	return _jobs


static func job_count() -> int:
	return jobs().size()


static func job(index: int) -> Dictionary:
	var all := jobs()
	if all.is_empty():
		return {}
	return all[posmod(index, all.size())]


## The job's items resolved against the catalogue, in job order (duplicates allowed).
static func job_items(j: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in j.get("items", []):
		var d := item(String(id))
		if not d.is_empty():
			out.append(d)
	return out


static func colour(name: String) -> Color:
	return COLOURS.get(name, Color.MAGENTA)


static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Catalog: missing %s" % path)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("Catalog: %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
