extends Node

signal save_changed
signal run_started
signal run_finished(success: bool, tome_id: String)

var save_data: Dictionary = {}
var current_run = null

func _ready() -> void:
	ensure_input_actions()
	initialize()

func initialize() -> void:
	save_data = SaveManager.load_save()
	if save_data.get("active_request_id", "") == "":
		save_data["active_request_id"] = ContentDB.get_default_request_id()
	_save()

func ensure_input_actions() -> void:
	_add_action_key("move_up", KEY_W)
	_add_action_key("move_up", KEY_UP)
	_add_action_key("move_down", KEY_S)
	_add_action_key("move_down", KEY_DOWN)
	_add_action_key("move_left", KEY_A)
	_add_action_key("move_left", KEY_LEFT)
	_add_action_key("move_right", KEY_D)
	_add_action_key("move_right", KEY_RIGHT)
	_add_action_key("interact", KEY_E)
	_add_action_key("interact", KEY_ENTER)
	_add_action_key("interact", KEY_SPACE)
	_add_action_key("ui_cancel", KEY_ESCAPE)
	_add_action_key("card_1", KEY_1)
	_add_action_key("card_2", KEY_2)
	_add_action_key("card_3", KEY_3)
	_add_action_key("card_4", KEY_4)
	_add_action_key("card_5", KEY_5)

func _add_action_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event = InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func get_active_request_id() -> String:
	return save_data.get("active_request_id", "")

func get_active_request():
	var request_id = get_active_request_id()
	if request_id == "":
		return null
	return ContentDB.get_request(request_id)

func get_active_request_tome_id() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.tome_id

func get_archive_tomes():
	return save_data.get("archived_tome_ids", []).duplicate()

func is_request_completed(request_id: String) -> bool:
	return request_id in save_data.get("completed_request_ids", [])

func start_run():
	current_run = preload("res://scripts/core/run_state.gd").new()
	current_run.request_id = get_active_request_id()
	current_run.seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_msec())
	current_run.deck_ids = ContentDB.get_starter_deck()
	current_run.room_sequence = ContentDB.build_0_1_dungeon_layout(current_run.seed)
	current_run.player_hp = 5
	current_run.player_max_hp = 5
	current_run.insight = 3
	current_run.shield = 0
	current_run.current_room_index = 0
	current_run.room_cleared = false
	run_started.emit()
	return current_run

func finish_run(success: bool, tome_id: String = "") -> void:
	if current_run != null:
		current_run.completed = success
		current_run.failed = not success
	if success and tome_id != "":
		mark_request_completed(get_active_request_id(), tome_id)
	run_finished.emit(success, tome_id)
	current_run = null
	_save()

func mark_request_completed(request_id: String, tome_id: String) -> void:
	var completed: Array = save_data.get("completed_request_ids", [])
	if request_id != "" and not completed.has(request_id):
		completed.append(request_id)
		save_data["completed_request_ids"] = completed
	var archive: Array = save_data.get("archived_tome_ids", [])
	if tome_id != "" and not archive.has(tome_id):
		archive.append(tome_id)
		save_data["archived_tome_ids"] = archive
	save_data["active_request_id"] = request_id
	save_changed.emit()

func _save() -> void:
	SaveManager.save_save(save_data)
	save_changed.emit()
