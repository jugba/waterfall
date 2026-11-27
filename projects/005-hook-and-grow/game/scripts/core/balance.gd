class_name Balance
extends RefCounted
## Loads res://data/balance.json once (all tuning lives there). Balance.data() returns the parsed
## Dictionary; tests may pass their own Dictionary to ArenaSim instead.

const PATH := "res://data/balance.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(PATH)) == OK and json.data is Dictionary:
			_data = json.data
	return _data


## A deep copy, so a test can tweak values without touching the shared data.
static func copy() -> Dictionary:
	return data().duplicate(true)
