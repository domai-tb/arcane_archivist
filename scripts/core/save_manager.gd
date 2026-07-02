extends Node

const SAVE_PATH := "user://arcane_archivist_save_0.json"
const SAVE_VERSION := 1

func default_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"active_request_id": "",
		"completed_request_ids": [],
		"archived_tome_ids": [],
		"settings": {
			"text_scale": 1.0,
			"show_tooltips": true,
		},
		"debug": {
			"last_opened_version": "0.1",
		},
	}

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_save_data()

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_save_data()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_save_data()

	return _merge_defaults(parsed)

func save_save(data: Dictionary) -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true

func _merge_defaults(data: Dictionary) -> Dictionary:
	var merged = default_save_data()
	for key in data.keys():
		if key == "settings" and typeof(data[key]) == TYPE_DICTIONARY:
			for setting_key in data[key].keys():
				merged["settings"][setting_key] = data[key][setting_key]
		elif key == "debug" and typeof(data[key]) == TYPE_DICTIONARY:
			for debug_key in data[key].keys():
				merged["debug"][debug_key] = data[key][debug_key]
		else:
			merged[key] = data[key]
	return merged
