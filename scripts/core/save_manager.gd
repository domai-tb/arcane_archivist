extends Node

const SAVE_PATH := "user://arcane_archivist_save_0.json"
const SAVE_VERSION := 4

func default_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"active_request_id": "",
		"completed_request_ids": [],
		"request_queue": [],
		"request_history": [],
		"library_turn_count": 0,
		"patron_reroll_count": 0,
		"research_job": {},
		"essence": 0,
		"station_layout_id": "balanced",
		"station_slots": [],
		"archived_tome_ids": [],
		"archived_relic_ids": [],
		"archive_slots": [],
		"active_archive_bonus_ids": [],
		"owned_card_ids": [],
		"active_deck_ids": [],
		"unlocked_reward_card_ids": [],
		"pending_card_reward_options": [],
		"pending_card_reward_source": "",
		"settings": {
			"text_scale": 1.0,
			"show_tooltips": true,
		},
		"debug": {
			"last_opened_version": "0.4",
		},
	}

func load_save() -> Dictionary:
	_ensure_save_dir()
	var save_path := _resolved_save_path()
	if not FileAccess.file_exists(save_path):
		return default_save_data()

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return default_save_data()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_save_data()

	return _merge_defaults(parsed)

func save_save(data: Dictionary) -> bool:
	_ensure_save_dir()
	var file := FileAccess.open(_resolved_save_path(), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true

func _merge_defaults(data: Dictionary) -> Dictionary:
	var merged := default_save_data()
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

func _ensure_save_dir() -> void:
	var save_dir := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(save_dir)

func _resolved_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)
