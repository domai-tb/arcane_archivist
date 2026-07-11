extends Node

const SAVE_PATH := "user://arcane_archivist_save_0.json"
const SAVE_BACKUP_PATH := "user://arcane_archivist_save_0.bak.json"
const SAVE_TEMP_PATH := "user://arcane_archivist_save_0.tmp.json"
const SAVE_VERSION := 8

var _save_path_override: String = ""
var _backup_path_override: String = ""
var _temp_path_override: String = ""

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
		"wing_progression": {},
		"active_wing_id": "",
		"selected_curse_family_id": "",
		"selected_curse_id": "",
		"selected_curse_ids": [],
		"unlocked_curse_ids": [],
		"pressure_event": {},
		"faction_reputation": {},
		"faction_unlock_ids": [],
		"meta_unlock_ids": [],
		"meta_spent_essence": 0,
		"replay_records": [],
		"archived_tome_ids": [],
		"archived_relic_ids": [],
		"archive_slots": [],
		"active_archive_bonus_ids": [],
		"owned_card_ids": [],
		"active_deck_ids": [],
		"unlocked_reward_card_ids": [],
		"pending_card_reward_options": [],
		"pending_card_reward_source": "",
		"narrative_unlock_ids": [],
		"settings": {
			"text_scale": 1.0,
			"show_tooltips": true,
			"contrast_mode": "normal",
			"palette_mode": "default",
			"deck_sort_mode": "manual",
			"archive_filter_mode": "all",
			"tracked_request_id": "",
		},
		"debug": {
			"last_opened_version": "0.9",
		},
	}

func load_save() -> Dictionary:
	_ensure_save_dir()
	var save_path := _resolved_save_path()
	if not FileAccess.file_exists(save_path):
		var backup_data := _load_dictionary_file(_resolved_backup_save_path())
		if not backup_data.is_empty():
			return _migrate_save_data(_merge_defaults(backup_data))
		return default_save_data()

	var parsed := _load_dictionary_file(save_path)
	if parsed.is_empty():
		parsed = _load_dictionary_file(_resolved_backup_save_path())
		if parsed.is_empty():
			return default_save_data()

	return _migrate_save_data(_merge_defaults(parsed))

func save_save(data: Dictionary) -> bool:
	_ensure_save_dir()
	var save_path := _resolved_save_path()
	var backup_path := _resolved_backup_save_path()
	var temp_path := _resolved_temp_save_path()
	var payload := JSON.stringify(data, "\t")
	if not _write_text_file(temp_path, payload):
		return false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(backup_path)
		var backup_error := DirAccess.rename_absolute(save_path, backup_path)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_path)
			return false
	var move_error := DirAccess.rename_absolute(temp_path, save_path)
	if move_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, save_path)
		DirAccess.remove_absolute(temp_path)
		return false
	if FileAccess.file_exists(save_path):
		_write_text_file(backup_path, payload)
		DirAccess.remove_absolute(temp_path)
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

func _migrate_save_data(data: Dictionary) -> Dictionary:
	var save_version := int(data.get("save_version", 0))
	if save_version < SAVE_VERSION:
		if not data.has("wing_progression") or typeof(data.get("wing_progression", {})) != TYPE_DICTIONARY:
			data["wing_progression"] = {}
		if not data.has("selected_curse_ids") or typeof(data.get("selected_curse_ids", [])) != TYPE_ARRAY:
			data["selected_curse_ids"] = []
		if not data.has("selected_curse_family_id"):
			data["selected_curse_family_id"] = ""
		if not data.has("selected_curse_id"):
			data["selected_curse_id"] = ""
		if not data.has("unlocked_curse_ids") or typeof(data.get("unlocked_curse_ids", [])) != TYPE_ARRAY:
			data["unlocked_curse_ids"] = []
		if not data.has("pressure_event") or typeof(data.get("pressure_event", {})) != TYPE_DICTIONARY:
			data["pressure_event"] = {}
		if not data.has("faction_reputation") or typeof(data.get("faction_reputation", {})) != TYPE_DICTIONARY:
			data["faction_reputation"] = {}
		if not data.has("faction_unlock_ids") or typeof(data.get("faction_unlock_ids", [])) != TYPE_ARRAY:
			data["faction_unlock_ids"] = []
		if not data.has("meta_unlock_ids") or typeof(data.get("meta_unlock_ids", [])) != TYPE_ARRAY:
			data["meta_unlock_ids"] = []
		if not data.has("replay_records") or typeof(data.get("replay_records", [])) != TYPE_ARRAY:
			data["replay_records"] = []
		if not data.has("active_wing_id"):
			data["active_wing_id"] = ""
		if not data.has("narrative_unlock_ids") or typeof(data.get("narrative_unlock_ids", [])) != TYPE_ARRAY:
			data["narrative_unlock_ids"] = []
		if not data.has("settings") or typeof(data.get("settings", {})) != TYPE_DICTIONARY:
			data["settings"] = default_save_data().get("settings", {}).duplicate(true)
		data["save_version"] = SAVE_VERSION
	return data

func _ensure_save_dir() -> void:
	var save_dir := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(save_dir)

func _resolved_save_path() -> String:
	if _save_path_override != "":
		return _save_path_override
	return ProjectSettings.globalize_path(SAVE_PATH)

func _resolved_backup_save_path() -> String:
	if _backup_path_override != "":
		return _backup_path_override
	return ProjectSettings.globalize_path(SAVE_BACKUP_PATH)

func _resolved_temp_save_path() -> String:
	if _temp_path_override != "":
		return _temp_path_override
	return ProjectSettings.globalize_path(SAVE_TEMP_PATH)

func set_save_path_overrides(save_path: String, backup_path: String = "", temp_path: String = "") -> void:
	_save_path_override = save_path
	_backup_path_override = backup_path if backup_path != "" else _derive_backup_path(save_path)
	_temp_path_override = temp_path if temp_path != "" else _derive_temp_path(save_path)

func clear_save_path_overrides() -> void:
	_save_path_override = ""
	_backup_path_override = ""
	_temp_path_override = ""

func _load_dictionary_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	return true

func _derive_backup_path(save_path: String) -> String:
	if save_path == "":
		return ""
	return save_path.get_basename() + ".bak.json"

func _derive_temp_path(save_path: String) -> String:
	if save_path == "":
		return ""
	return save_path.get_basename() + ".tmp.json"
