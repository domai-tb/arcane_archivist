@tool
extends McpTestSuite

var _content_db: Node = null
var _save_manager: Node = null
var _app_state: Node = null
var _temp_dir: String = ""
var _save_path: String = ""
var _backup_path: String = ""
var _temp_path: String = ""


func suite_name() -> String:
	return "release_gate"


func suite_setup(_ctx: Dictionary) -> void:
	var content_script: Script = load("res://scripts/core/content_db.gd")
	var save_script: Script = load("res://scripts/core/save_manager.gd")
	var app_state_script: Script = load("res://scripts/core/app_state.gd")
	if content_script == null or save_script == null or app_state_script == null:
		fail_setup("Core scripts failed to load")
		return

	_content_db = content_script.new()
	_save_manager = save_script.new()
	_app_state = app_state_script.new()

	if _content_db == null or _save_manager == null or _app_state == null:
		fail_setup("Core services failed to instantiate")
		return

	_content_db._build_content()
	_temp_dir = "/tmp/arcane_archivist_tests/%d/release_gate" % OS.get_process_id()
	var dir_error := DirAccess.make_dir_recursive_absolute(_temp_dir)
	if dir_error != OK:
		fail_setup("Unable to create temporary test directory: %s" % _temp_dir)
		return

	_save_path = _temp_dir + "/save.json"
	_backup_path = _temp_dir + "/save.bak.json"
	_temp_path = _temp_dir + "/save.tmp.json"
	_save_manager.set_save_path_overrides(_save_path, _backup_path, _temp_path)
	_app_state.save_manager = _save_manager
	_app_state.content_db = _content_db
	_app_state.initialize()
	_app_state.ensure_input_actions()


func suite_teardown() -> void:
	_cleanup_temp_files()
	if _save_manager != null and _save_manager.has_method("clear_save_path_overrides"):
		_save_manager.clear_save_path_overrides()
	if _app_state != null and is_instance_valid(_app_state):
		_app_state.free()
	if _save_manager != null and is_instance_valid(_save_manager):
		_save_manager.free()
	if _content_db != null and is_instance_valid(_content_db):
		_content_db.free()


func test_content_validation() -> void:
	var errors: Array = _content_db.validate_content()
	assert_eq(errors.size(), 0, "Content database should validate cleanly.")


func test_dungeon_layout_is_deterministic() -> void:
	var request_id: String = _content_db.get_default_request_id()
	var seed_value: int = 1729
	var layout_a: Array = _content_db.build_dungeon_layout(seed_value, request_id)
	var layout_b: Array = _content_db.build_dungeon_layout(seed_value, request_id)
	assert_eq(layout_a, layout_b, "Dungeon layout should be deterministic for the same seed and request.")
	assert_true(not layout_a.is_empty(), "Dungeon layout should not be empty.")
	assert_eq(str(layout_a.back().get("role", "")), "tome", "Dungeon layout should end with the tome room.")


func test_save_round_trip_and_backup_recovery() -> void:
	var payload: Dictionary = _save_manager.default_save_data()
	var payload_settings: Dictionary = payload.get("settings", {})
	payload["essence"] = 12
	payload["active_request_id"] = "recover_ashen_index"
	payload_settings["text_scale"] = 1.15
	payload_settings["contrast_mode"] = "high"
	payload_settings["palette_mode"] = "accessible"
	payload["settings"] = payload_settings

	assert_true(_save_manager.save_save(payload), "The temporary save should write successfully.")
	var loaded: Dictionary = _save_manager.load_save()
	var loaded_settings: Dictionary = loaded.get("settings", {})
	assert_eq(int(loaded.get("essence", -1)), 12, "Round-tripped save should preserve essence.")
	assert_eq(str(loaded.get("active_request_id", "")), "recover_ashen_index", "Round-tripped save should preserve the active request.")
	assert_eq(float(loaded_settings.get("text_scale", 0.0)), 1.15, "Round-tripped save should preserve text scale.")

	var save_file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	assert_true(save_file != null, "The save file should be writable for the corruption check.")
	if save_file != null:
		save_file.store_string("{ invalid json")

	var recovered: Dictionary = _save_manager.load_save()
	var recovered_settings: Dictionary = recovered.get("settings", {})
	assert_eq(int(recovered.get("essence", -1)), 12, "Backup recovery should restore the last valid save.")
	assert_eq(str(recovered.get("active_request_id", "")), "recover_ashen_index", "Backup recovery should restore the active request.")
	assert_eq(str(recovered_settings.get("palette_mode", "")), "accessible", "Backup recovery should preserve accessibility settings.")


func test_archive_breach_expires_into_damage() -> void:
	_app_state.grant_tome("ashen_index")
	assert_true(_app_state.get_archive_tomes().has("ashen_index"), "The test should be able to own the tome.")
	assert_true(_app_state.place_archive_item("tome", "ashen_index", 0), "The tome should be placeable in the archive.")
	var essence_before: int = _app_state.get_essence()
	_app_state.save_data["essence"] = max(1, essence_before)
	_app_state.save_data["pressure_event"] = {
		"event_id": "archive_breach",
		"source_request_id": "recover_ashen_index",
		"turn": 1,
		"turns_remaining": 1,
	}
	_app_state.advance_library_turn("library")

	assert_false(_app_state.has_pending_pressure_event(), "The breach should clear after expiring.")
	assert_eq(str(_app_state.get_archive_slots()[0].get("item_id", "")), "", "The breach should clear the damaged archive slot.")
	assert_true(_app_state.get_archive_tomes().has("ashen_index"), "The breach should not revoke archive ownership.")
	assert_eq(_app_state.get_essence(), max(0, max(1, essence_before) - 1), "The breach should cost one essence when possible.")


func test_narrative_unlock_records_story_beats() -> void:
	_app_state.save_data["replay_records"] = []
	_app_state.save_data["narrative_unlock_ids"] = []
	_app_state.record_replay_entry(
		"wing_upgrade",
		"Wing Upgrade",
		"Opened a new wing path.",
		{"wing_id": "astral_wing"},
		""
	)

	var narrative_unlocks: Array[String] = _app_state.get_narrative_unlock_ids()
	assert_true(narrative_unlocks.has("first_wing_upgrade"), "Wing upgrades should unlock a story beat.")
	assert_contains(_app_state.get_narrative_unlock_text(), "First Wing Specialization", "The story beat should be visible in the narrative summary.")

	var reloaded: Dictionary = _save_manager.load_save()
	var reloaded_narrative: Array = reloaded.get("narrative_unlock_ids", [])
	assert_true(reloaded_narrative.has("first_wing_upgrade"), "Narrative unlocks should persist in the save file.")


func test_touch_helpers_drive_existing_input_actions() -> void:
	var dive_hud_script: Script = load("res://scripts/ui/dive_hud.gd")
	var hub_hud_script: Script = load("res://scripts/ui/hub_hud.gd")
	assert_true(dive_hud_script != null, "Dive HUD script should load.")
	assert_true(hub_hud_script != null, "Hub HUD script should load.")

	var dive_hud = track(dive_hud_script.new())
	var hub_hud = track(hub_hud_script.new())
	assert_true(dive_hud != null, "Dive HUD should instantiate.")
	assert_true(hub_hud != null, "Hub HUD should instantiate.")

	dive_hud.call("_build_ui")
	hub_hud.call("_build_ui")
	assert_true(dive_hud.get("touch_panel") != null, "Dive HUD should create a touch panel.")
	assert_true(hub_hud.get("touch_panel") != null, "Hub HUD should create a touch panel.")

	var dive_touch_buttons: Dictionary = dive_hud.get("touch_buttons")
	var hub_touch_buttons: Dictionary = hub_hud.get("touch_buttons")
	assert_true(dive_touch_buttons.has("move_up"), "Dive HUD should register a move_up touch button.")
	assert_true(hub_touch_buttons.has("interact"), "Hub HUD should register an interact touch button.")

	var dive_up_button: Button = dive_touch_buttons.get("move_up")
	var hub_interact_button: Button = hub_touch_buttons.get("interact")
	assert_true(dive_up_button != null, "Dive HUD move_up button should exist.")
	assert_true(hub_interact_button != null, "Hub HUD interact button should exist.")
	assert_gt(dive_up_button.get_signal_connection_list("button_down").size(), 0, "Dive HUD move_up button should wire button_down.")
	assert_gt(dive_up_button.get_signal_connection_list("button_up").size(), 0, "Dive HUD move_up button should wire button_up.")
	assert_gt(hub_interact_button.get_signal_connection_list("button_down").size(), 0, "Hub HUD interact button should wire button_down.")
	assert_gt(hub_interact_button.get_signal_connection_list("button_up").size(), 0, "Hub HUD interact button should wire button_up.")


func _cleanup_temp_files() -> void:
	if _save_path != "" and FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	if _backup_path != "" and FileAccess.file_exists(_backup_path):
		DirAccess.remove_absolute(_backup_path)
	if _temp_path != "" and FileAccess.file_exists(_temp_path):
		DirAccess.remove_absolute(_temp_path)
	if _temp_dir != "":
		DirAccess.remove_absolute(_temp_dir)
