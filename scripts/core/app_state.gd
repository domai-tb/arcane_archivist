extends Node

signal save_changed
signal run_started
signal run_finished(success: bool, tome_id: String)
signal archive_changed

var save_data: Dictionary = {}
var current_run = null
var save_manager: Node = null
var content_db: Node = null

const ARCHIVE_GRID_COLUMNS := 3
const ARCHIVE_GRID_ROWS := 2
const ARCHIVE_SLOT_COUNT := ARCHIVE_GRID_COLUMNS * ARCHIVE_GRID_ROWS

func _ready() -> void:
	ensure_input_actions()
	save_manager = get_node_or_null("/root/SaveManager")
	content_db = get_node_or_null("/root/ContentDB")
	initialize()

func initialize() -> void:
	if save_manager == null:
		save_manager = get_node_or_null("/root/SaveManager")
	if content_db == null:
		content_db = get_node_or_null("/root/ContentDB")
	if save_manager == null or content_db == null:
		push_error("Arcane Archivist autoloads are not ready.")
		return
	save_data = save_manager.load_save()
	if save_data.get("active_request_id", "") == "":
		save_data["active_request_id"] = content_db.get_default_request_id()
	_normalize_archive_state()
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

	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func get_active_request_id() -> String:
	return save_data.get("active_request_id", "")

func get_active_request():
	var request_id := get_active_request_id()
	if request_id == "":
		return null
	return content_db.get_request(request_id)

func get_active_request_tome_id() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.tome_id

func get_active_request_name() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.name

func get_active_request_objective() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.objective_text

func get_active_request_reward_text() -> String:
	var request = get_active_request()
	if request == null:
		return ""
	return request.reward_text

func get_archive_tomes() -> Array:
	return save_data.get("archived_tome_ids", []).duplicate()

func get_archive_relics() -> Array:
	return save_data.get("archived_relic_ids", []).duplicate()

func get_archive_slots() -> Array:
	return _duplicate_archive_slots(save_data.get("archive_slots", []))

func get_archive_slot(slot_index: int) -> Dictionary:
	var slots := get_archive_slots()
	if slot_index < 0 or slot_index >= slots.size():
		return {"item_type": "", "item_id": ""}
	return slots[slot_index]

func get_owned_archive_item_ids(item_type: String) -> Array:
	if item_type == "tome":
		return get_archive_tomes()
	if item_type == "relic":
		return get_archive_relics()
	return []

func get_archive_inventory() -> Array:
	var inventory: Array = []
	var slots := get_archive_slots()

	for tome_id in get_archive_tomes():
		inventory.append({
			"item_type": "tome",
			"item_id": tome_id,
			"name": _get_item_name("tome", tome_id),
			"placed": _find_slot_index("tome", tome_id, slots) >= 0,
			"slot_index": _find_slot_index("tome", tome_id, slots),
		})

	for relic_id in get_archive_relics():
		inventory.append({
			"item_type": "relic",
			"item_id": relic_id,
			"name": _get_item_name("relic", relic_id),
			"placed": _find_slot_index("relic", relic_id, slots) >= 0,
			"slot_index": _find_slot_index("relic", relic_id, slots),
		})

	return inventory

func get_active_archive_bonuses() -> Array[Dictionary]:
	return save_data.get("active_archive_bonuses", []).duplicate(true)

func get_active_archive_bonus_text() -> String:
	var bonuses := get_active_archive_bonuses()
	if bonuses.is_empty():
		return "No active archive bonuses yet."

	var lines: Array[String] = []
	for bonus in bonuses:
		lines.append("%s: %s" % [bonus.get("name", bonus.get("id", "")), bonus.get("description", "")])
	return "Active bonuses:\n- " + "\n- ".join(lines)

func is_request_completed(request_id: String) -> bool:
	return request_id in save_data.get("completed_request_ids", [])

func place_archive_item(item_type: String, item_id: String, slot_index: int) -> bool:
	if not _is_valid_archive_item(item_type, item_id):
		return false
	if slot_index < 0 or slot_index >= ARCHIVE_SLOT_COUNT:
		return false

	var slots := get_archive_slots()
	slots = _remove_archive_item_from_slots(item_type, item_id, slots)
	slots[slot_index] = {
		"item_type": item_type,
		"item_id": item_id,
	}

	_commit_archive_slots(slots)
	return true

func remove_archive_item(slot_index: int) -> bool:
	var slots := get_archive_slots()
	if slot_index < 0 or slot_index >= slots.size():
		return false

	slots[slot_index] = {
		"item_type": "",
		"item_id": "",
	}
	_commit_archive_slots(slots)
	return true

func clear_archive_slot(slot_index: int) -> bool:
	return remove_archive_item(slot_index)

func start_run():
	current_run = preload("res://scripts/core/run_state.gd").new()
	current_run.request_id = get_active_request_id()
	current_run.run_seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_msec())
	current_run.deck_ids = content_db.get_starter_deck()
	current_run.room_sequence = content_db.build_0_2_dungeon_layout(current_run.run_seed)
	current_run.player_hp = 5
	current_run.player_max_hp = 5
	current_run.insight = 3
	current_run.shield = 0
	current_run.current_room_index = 0
	current_run.room_cleared = false
	current_run.reward_relic_id = ""
	current_run.active_bonuses = get_active_archive_bonuses()
	_apply_active_bonuses_to_run(current_run)
	run_started.emit()
	return current_run

func finish_run(success: bool, tome_id: String = "", relic_id: String = "") -> void:
	if current_run != null:
		current_run.completed = success
		current_run.failed = not success

	if success and tome_id != "":
		grant_tome(tome_id)
	if success and relic_id != "":
		grant_relic(relic_id)
	if success and current_run != null and current_run.reward_relic_id != "":
		grant_relic(current_run.reward_relic_id)

	if success:
		var current_request_id := get_active_request_id()
		mark_request_completed(current_request_id, tome_id)
		save_data["active_request_id"] = content_db.get_next_request_id(
			current_request_id,
			save_data.get("completed_request_ids", [])
		)

	run_finished.emit(success, tome_id)
	current_run = null
	_save()

func grant_tome(tome_id: String) -> void:
	if tome_id == "":
		return
	var tomes: Array = save_data.get("archived_tome_ids", [])
	if not tomes.has(tome_id):
		tomes.append(tome_id)
		save_data["archived_tome_ids"] = tomes
		archive_changed.emit()

func grant_relic(relic_id: String) -> void:
	if relic_id == "":
		return
	var relics: Array = save_data.get("archived_relic_ids", [])
	if not relics.has(relic_id):
		relics.append(relic_id)
		save_data["archived_relic_ids"] = relics
		archive_changed.emit()

func mark_request_completed(request_id: String, tome_id: String) -> void:
	var completed: Array = save_data.get("completed_request_ids", [])
	if request_id != "" and not completed.has(request_id):
		completed.append(request_id)
		save_data["completed_request_ids"] = completed

	if tome_id != "":
		grant_tome(tome_id)

	save_changed.emit()

func _apply_active_bonuses_to_run(run_state) -> void:
	run_state.bonus_shield = 0
	run_state.bonus_damage = 0
	run_state.bonus_cooldown_reduction = 0.0
	run_state.bonus_reward_heal = 0
	run_state.bonus_vs_enemy_kind = ""
	run_state.bonus_vs_enemy_kind_damage = 0

	for bonus in get_active_archive_bonuses():
		var modifiers: Dictionary = bonus.get("modifiers", {})
		run_state.bonus_shield += int(modifiers.get("starting_shield", 0))
		run_state.bonus_damage += int(modifiers.get("card_damage_bonus", 0))
		run_state.bonus_cooldown_reduction += float(modifiers.get("cooldown_reduction_bonus", 0.0))
		run_state.bonus_reward_heal += int(modifiers.get("reward_heal_bonus", 0))

		var enemy_kind := str(modifiers.get("bonus_vs_enemy_kind", ""))
		if enemy_kind != "":
			run_state.bonus_vs_enemy_kind = enemy_kind
			run_state.bonus_vs_enemy_kind_damage = max(
				run_state.bonus_vs_enemy_kind_damage,
				int(modifiers.get("bonus_vs_enemy_kind_damage", 0))
			)

	run_state.shield += run_state.bonus_shield

func _commit_archive_slots(slots: Array) -> void:
	save_data["archive_slots"] = _duplicate_archive_slots(slots)
	_rebuild_owned_items_from_slots()
	_recompute_archive_bonuses()
	save_changed.emit()
	archive_changed.emit()
	_save()

func _rebuild_owned_items_from_slots() -> void:
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))
	var tome_ids: Array = save_data.get("archived_tome_ids", [])
	var relic_ids: Array = save_data.get("archived_relic_ids", [])

	for slot in slots:
		var item_type := str(slot.get("item_type", ""))
		var item_id := str(slot.get("item_id", ""))
		if item_type == "tome" and item_id != "":
			if not tome_ids.has(item_id):
				tome_ids.append(item_id)
		elif item_type == "relic" and item_id != "":
			if not relic_ids.has(item_id):
				relic_ids.append(item_id)

	save_data["archived_tome_ids"] = tome_ids
	save_data["archived_relic_ids"] = relic_ids

func _recompute_archive_bonuses() -> void:
	var bonuses: Array[Dictionary] = []
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))

	for bonus in content_db.get_archive_bonuses():
		var tome_id := str(bonus.get("tome_id", ""))
		var relic_id := str(bonus.get("relic_id", ""))
		var tome_slot := _find_slot_index("tome", tome_id, slots)
		var relic_slot := _find_slot_index("relic", relic_id, slots)
		if tome_slot >= 0 and relic_slot >= 0 and _slots_are_adjacent(tome_slot, relic_slot):
			bonuses.append(bonus.duplicate(true))

	save_data["active_archive_bonuses"] = bonuses
	var bonus_ids: Array[String] = []
	for bonus in bonuses:
		bonus_ids.append(str(bonus.get("id", "")))
	save_data["active_archive_bonus_ids"] = bonus_ids

func _normalize_archive_state() -> void:
	var slots := _duplicate_archive_slots(save_data.get("archive_slots", []))
	if slots.is_empty():
		slots = _make_empty_archive_slots()
	save_data["archive_slots"] = slots

	var tome_ids: Array = save_data.get("archived_tome_ids", [])
	var relic_ids: Array = save_data.get("archived_relic_ids", [])
	save_data["archived_tome_ids"] = tome_ids
	save_data["archived_relic_ids"] = relic_ids
	_rebuild_owned_items_from_slots()
	_recompute_archive_bonuses()

func _make_empty_archive_slots() -> Array:
	var slots: Array = []
	for _i in range(ARCHIVE_SLOT_COUNT):
		slots.append({"item_type": "", "item_id": ""})
	return slots

func _duplicate_archive_slots(source_slots: Array) -> Array:
	var slots: Array = []
	if source_slots.is_empty():
		return _make_empty_archive_slots()

	for index in range(ARCHIVE_SLOT_COUNT):
		var slot: Dictionary = {}
		if index < source_slots.size() and typeof(source_slots[index]) == TYPE_DICTIONARY:
			slot = source_slots[index].duplicate(true)
		slot = {
			"item_type": str(slot.get("item_type", "")),
			"item_id": str(slot.get("item_id", "")),
		}
		slots.append(slot)
	return slots

func _remove_archive_item_from_slots(item_type: String, item_id: String, source_slots: Array) -> Array:
	var slots := _duplicate_archive_slots(source_slots)
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		if slot.get("item_type", "") == item_type and slot.get("item_id", "") == item_id:
			slots[index] = {"item_type": "", "item_id": ""}
	return slots

func _find_slot_index(item_type: String, item_id: String, source_slots: Array) -> int:
	for index in range(source_slots.size()):
		var slot: Dictionary = source_slots[index]
		if slot.get("item_type", "") == item_type and slot.get("item_id", "") == item_id:
			return index
	return -1

func _slots_are_adjacent(first_index: int, second_index: int) -> bool:
	var first_x := first_index % ARCHIVE_GRID_COLUMNS
	var first_y := float(first_index) / float(ARCHIVE_GRID_COLUMNS)
	var second_x := second_index % ARCHIVE_GRID_COLUMNS
	var second_y := float(second_index) / float(ARCHIVE_GRID_COLUMNS)
	return abs(first_x - second_x) + abs(first_y - second_y) == 1

func _is_valid_archive_item(item_type: String, item_id: String) -> bool:
	if item_type == "tome":
		return content_db.get_tome(item_id) != null and get_archive_tomes().has(item_id)
	if item_type == "relic":
		return content_db.get_relic(item_id) != null and get_archive_relics().has(item_id)
	return false

func _get_item_name(item_type: String, item_id: String) -> String:
	if item_type == "tome":
		var tome = content_db.get_tome(item_id)
		if tome != null:
			return tome.name
	if item_type == "relic":
		var relic = content_db.get_relic(item_id)
		if relic != null:
			return relic.name
	return item_id

func _save() -> void:
	save_manager.save_save(save_data)
	save_changed.emit()
