extends Node
## Save slots as JSON in user://saves/slot_<n>.json, written atomically (tmp file + rename)
## so a crash or power loss mid-save never corrupts the previous save.
##
## Usage: SaveGame.save_slot(0, {"level": 3}); var data := SaveGame.load_slot(0)
## Every file carries "format_version"; bump FORMAT_VERSION and extend _migrate() when the
## shape of the data changes, so old saves keep loading after a patch.
## Steam Cloud: enable Auto-Cloud in Steamworks for the user:// path (see template README).

signal saved(slot: int)
signal loaded(slot: int)

const FORMAT_VERSION := 1

var directory := "user://saves"


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [directory, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_slot(slot: int, data: Dictionary) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(directory)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	var payload := {
		"format_version": FORMAT_VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version", ""),
		"saved_at": Time.get_datetime_string_from_system(true),
		"data": data,
	}
	var final_path := slot_path(slot)
	var tmp_path := final_path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	err = DirAccess.rename_absolute(tmp_path, final_path)
	if err == OK:
		saved.emit(slot)
	return err


## Returns the saved data, or an empty Dictionary if the slot is missing or unreadable.
func load_slot(slot: int) -> Dictionary:
	var p := slot_path(slot)
	if not FileAccess.file_exists(p):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (parsed is Dictionary) or not (parsed.get("data") is Dictionary):
		push_warning("SaveGame: slot %d is unreadable, ignoring it" % slot)
		return {}
	var data: Dictionary = _migrate(parsed["data"], int(parsed.get("format_version", 0)))
	loaded.emit(slot)
	return data


func delete_slot(slot: int) -> Error:
	if not has_slot(slot):
		return OK
	return DirAccess.remove_absolute(slot_path(slot))


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# Example: if from_version < 2: data["coins"] = data.get("gold", 0)
	if from_version > FORMAT_VERSION:
		push_warning("SaveGame: save is from a newer game version (%d)" % from_version)
	return data
