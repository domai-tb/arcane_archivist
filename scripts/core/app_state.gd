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
const REQUEST_QUEUE_SIZE := 3
const RESEARCH_TURNS_BASE := 2

const STATION_LAYOUTS := {
	"balanced": {
		"name": "Balanced Layout",
		"description": "Default spacing. Research takes the normal amount of library turns.",
		"research_turns_modifier": 0,
		"essence_bonus": 0,
	},
	"shelf_adjacent": {
		"name": "Shelf Adjacent",
		"description": "Archive shelf beside the research desk. Research takes 1 fewer library turn.",
		"research_turns_modifier": -1,
		"essence_bonus": 0,
	},
	"lamp_focus": {
		"name": "Lamp Focus",
		"description": "The essence lamp is tuned to patron work. Completed research grants +1 essence.",
		"research_turns_modifier": 0,
		"essence_bonus": 1,
	},
}

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
	var content_errors: Array[String] = content_db.validate_content()
	for error_text in content_errors:
		push_warning(error_text)
	save_data = save_manager.load_save()
	if save_data.get("active_request_id", "") == "":
		save_data["active_request_id"] = content_db.get_default_request_id()
	_normalize_essence_state()
	_normalize_request_state()
	_normalize_research_job_state()
	_normalize_archive_state()
	_normalize_card_state()
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
	var request_id: String = get_active_request_id()
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

func get_essence() -> int:
	return int(save_data.get("essence", 0))

func add_essence(amount: int) -> void:
	if amount == 0:
		return
	save_data["essence"] = max(0, get_essence() + amount)
	save_changed.emit()
	_save()

func spend_essence(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_essence() < amount:
		return false
	save_data["essence"] = get_essence() - amount
	save_changed.emit()
	_save()
	return true

func get_station_layout_id() -> String:
	var layout_id := str(save_data.get("station_layout_id", "balanced"))
	if not STATION_LAYOUTS.has(layout_id):
		return "balanced"
	return layout_id

func get_station_layout_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for layout_id in STATION_LAYOUTS.keys():
		var layout: Dictionary = STATION_LAYOUTS[layout_id]
		options.append({
			"id": layout_id,
			"name": str(layout.get("name", layout_id)),
			"description": str(layout.get("description", "")),
			"research_turns_modifier": int(layout.get("research_turns_modifier", 0)),
			"essence_bonus": int(layout.get("essence_bonus", 0)),
		})
	return options

func get_station_layout_text() -> String:
	var layout_id := get_station_layout_id()
	var layout: Dictionary = STATION_LAYOUTS.get(layout_id, STATION_LAYOUTS["balanced"])
	return "%s\n%s" % [str(layout.get("name", layout_id)), str(layout.get("description", ""))]

func set_station_layout(layout_id: String) -> bool:
	if not STATION_LAYOUTS.has(layout_id):
		return false
	if get_station_layout_id() == layout_id:
		return true
	if not spend_essence(1):
		return false
	save_data["station_layout_id"] = layout_id
	advance_library_turn()
	save_changed.emit()
	_save()
	return true

func get_request_queue_entries() -> Array:
	return _duplicate_request_queue(save_data.get("request_queue", []))

func get_active_request_entry():
	var queue := get_request_queue_entries()
	if queue.is_empty():
		return {}
	return queue[0]

func get_request_entry(request_id: String):
	for entry in get_request_queue_entries():
		if str(entry.get("request_id", "")) == request_id:
			return entry
	return {}

func get_request_queue_text() -> String:
	var queue := get_request_queue_entries()
	if queue.is_empty():
		return "Request queue is empty."

	var lines: Array[String] = []
	lines.append("Patron queue:")
	for index in range(queue.size()):
		var entry: Dictionary = queue[index]
		var request_id: String = str(entry.get("request_id", ""))
		var request = content_db.get_request(request_id)
		var title := str(request.name if request != null else request_id)
		var state := str(entry.get("state", "queued"))
		var deadline_kind := str(entry.get("deadline_kind", "dive"))
		var deadline_remaining := int(entry.get("deadline_turns_remaining", 0))
		var deadline_total := int(entry.get("deadline_turns_total", 0))
		lines.append("%d. %s [%s] - %d/%d %s turns" % [
			index + 1,
			title,
			state,
			deadline_remaining,
			deadline_total,
			deadline_kind,
		])
	return "\n".join(lines)

func get_research_job():
	return _duplicate_research_job(save_data.get("research_job", {}))

func has_pending_research_job() -> bool:
	var job: Dictionary = get_research_job()
	return not job.is_empty() and str(job.get("state", "")) in ["pending", "researching"]

func has_active_research_job() -> bool:
	var job: Dictionary = get_research_job()
	return not job.is_empty() and str(job.get("state", "")) == "researching"

func get_research_job_text() -> String:
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return "No research job is waiting."

	var request_id: String = str(job.get("request_id", ""))
	var request = content_db.get_request(request_id)
	var title: String = str(request.name if request != null else request_id)
	var state: String = str(job.get("state", "pending"))
	var turns_remaining: int = int(job.get("turns_remaining", 0))
	var turns_total: int = int(job.get("turns_total", RESEARCH_TURNS_BASE))
	var essence_reward: int = int(job.get("essence_reward", 0))
	var source_tome: String = str(job.get("tome_id", ""))
	var source_relic: String = str(job.get("relic_id", ""))
	var lines: Array[String] = []
	lines.append("Research job: %s" % title)
	lines.append("State: %s" % state)
	lines.append("Time: %d/%d library turns remaining" % [turns_remaining, turns_total])
	if source_tome != "":
		lines.append("Tome: %s" % source_tome)
	if source_relic != "":
		lines.append("Relic: %s" % source_relic)
	lines.append("Essence on completion: %d" % essence_reward)
	return "\n".join(lines)

func get_request_state_summary() -> String:
	var active_entry: Dictionary = get_active_request_entry()
	if active_entry.is_empty():
		return "No active request."

	var request_id: String = str(active_entry.get("request_id", ""))
	var request = content_db.get_request(request_id)
	if request == null:
		return "No active request."

	var state: String = str(active_entry.get("state", "active"))
	var deadline_kind: String = str(active_entry.get("deadline_kind", "dive"))
	var deadline_remaining: int = int(active_entry.get("deadline_turns_remaining", 0))
	var deadline_total: int = int(active_entry.get("deadline_turns_total", 0))
	return "%s\nState: %s\nDeadline: %d/%d %s turns" % [
		str(request.name),
		state,
		deadline_remaining,
		deadline_total,
		deadline_kind,
	]

func set_active_request(request_id: String) -> bool:
	if request_id == "":
		return false
	var queue := _duplicate_request_queue(save_data.get("request_queue", []))
	var request_index: int = _find_request_queue_index(queue, request_id)
	if request_index < 0:
		return false
	var entry: Dictionary = queue[request_index]
	if str(entry.get("state", "")) in ["completed", "expired"]:
		return false

	queue.remove_at(request_index)
	entry["state"] = "active"
	queue.insert(0, entry)
	save_data["active_request_id"] = request_id
	save_data["request_queue"] = queue
	_save_request_queue(queue)
	return true

func get_request_progress_text(request_id: String = "") -> String:
	var entry: Dictionary = {}
	if request_id == "":
		entry = get_active_request_entry()
	else:
		entry = get_request_entry(request_id)
	if entry.is_empty():
		return "No request progress available."

	var progress: int = int(entry.get("progress", 0))
	var progress_total: int = max(1, int(entry.get("progress_total", 1)))
	var state: String = str(entry.get("state", "queued"))
	return "Progress: %d/%d\nState: %s" % [progress, progress_total, state]

func get_request_board_text() -> String:
	var lines: Array[String] = []
	lines.append(get_request_queue_text())
	lines.append("")
	lines.append("Active request:")
	lines.append(get_request_state_summary())
	return "\n".join(lines)

func can_start_research_job(request_id: String = "") -> bool:
	if has_active_research_job():
		return false
	if request_id == "":
		request_id = get_active_request_id()
	return request_id != "" and content_db.get_request(request_id) != null

func start_research_job(request_id: String = "") -> bool:
	if request_id == "":
		request_id = get_active_request_id()
	if not can_start_research_job(request_id):
		return false
	_queue_research_job(request_id, "", "")
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return false
	job["state"] = "researching"
	save_data["research_job"] = job
	save_changed.emit()
	_save()
	return true

func work_research_job() -> bool:
	if not has_pending_research_job():
		return false
	var job: Dictionary = get_research_job()
	if job.is_empty():
		return false
	job["state"] = "researching"
	save_data["research_job"] = job
	advance_library_turn()
	return true

func get_station_layout_effect_text() -> String:
	var layout: Dictionary = STATION_LAYOUTS.get(get_station_layout_id(), STATION_LAYOUTS["balanced"])
	return "%s\n%s" % [str(layout.get("name", "balanced")), str(layout.get("description", ""))]

func advance_library_turn(turn_kind: String = "library") -> void:
	var queue := get_request_queue_entries()
	if not queue.is_empty():
		var active_entry: Dictionary = queue[0]
		if str(active_entry.get("state", "")) in ["active", "in_progress"]:
			if str(active_entry.get("deadline_kind", "")) == turn_kind:
				var remaining := int(active_entry.get("deadline_turns_remaining", 0)) - 1
				active_entry["deadline_turns_remaining"] = max(0, remaining)
				queue[0] = active_entry
				if remaining <= 0 and str(active_entry.get("state", "")) != "completed":
					_expire_active_request(queue)
					return
		save_data["request_queue"] = queue

	var job: Dictionary = get_research_job()
	if turn_kind != "dive" and not job.is_empty() and str(job.get("state", "")) == "researching":
		job["turns_remaining"] = max(0, int(job.get("turns_remaining", 0)) - 1)
		if int(job.get("turns_remaining", 0)) <= 0:
			_complete_research_job(job)
		else:
			save_data["research_job"] = job

		save_changed.emit()
		_save()

func advance_dive_turn() -> void:
	advance_library_turn("dive")

func _normalize_research_job_state() -> void:
	var job: Dictionary = _duplicate_research_job(save_data.get("research_job", {}))
	if job.is_empty():
		save_data["research_job"] = {}
		return
	var job_state: String = str(job.get("state", "pending"))
	if not (job_state in ["pending", "researching", "completed", "expired"]):
		job["state"] = "pending"
	job["turns_total"] = max(1, int(job.get("turns_total", RESEARCH_TURNS_BASE)))
	job["turns_remaining"] = clamp(int(job.get("turns_remaining", job.get("turns_total", RESEARCH_TURNS_BASE))), 0, int(job.get("turns_total", RESEARCH_TURNS_BASE)))
	job["essence_reward"] = max(0, int(job.get("essence_reward", 0)))
	save_data["research_job"] = job

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

func _normalize_card_state() -> void:
	var owned_cards: Array[String] = []
	for card_id in save_data.get("owned_card_ids", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if not owned_cards.has(card_id_text):
			owned_cards.append(card_id_text)
	for starter_card_id in content_db.get_starter_deck():
		if not owned_cards.has(starter_card_id) and content_db.get_card(starter_card_id) != null:
			owned_cards.append(starter_card_id)
	save_data["owned_card_ids"] = owned_cards

	var active_deck: Array = save_data.get("active_deck_ids", [])
	if active_deck.is_empty():
		active_deck = content_db.get_starter_deck()
	var validation: Dictionary = content_db.validate_deck(active_deck, owned_cards)
	if not bool(validation.get("valid", false)):
		active_deck = content_db.build_valid_deck(owned_cards, active_deck)
		validation = content_db.validate_deck(active_deck, owned_cards)
	if not bool(validation.get("valid", false)):
		active_deck = content_db.get_starter_deck()
	save_data["active_deck_ids"] = active_deck

	var unlocked_cards: Array[String] = []
	for card_id in save_data.get("unlocked_reward_card_ids", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if not unlocked_cards.has(card_id_text):
			unlocked_cards.append(card_id_text)
	save_data["unlocked_reward_card_ids"] = unlocked_cards

	var pending_options: Array[String] = []
	for card_id in save_data.get("pending_card_reward_options", []):
		var card_id_text: String = str(card_id)
		if card_id_text == "":
			continue
		if content_db.get_card(card_id_text) == null:
			continue
		if pending_options.has(card_id_text):
			continue
		pending_options.append(card_id_text)
	save_data["pending_card_reward_options"] = pending_options
	if pending_options.is_empty():
		save_data["pending_card_reward_source"] = ""

func _sanitize_request_entry(entry: Dictionary, request_data: Dictionary = {}) -> Dictionary:
	if request_data.is_empty():
		var request_id: String = str(entry.get("request_id", ""))
		request_data = content_db.get_request_runtime_data(request_id)
	if request_data.is_empty():
		return {}
	var progress_total: int = max(1, int(entry.get("progress_total", 0)))
	if progress_total <= 1:
		progress_total = max(
			1,
			request_data.get("required_knowledge_tags", []).size() +
			request_data.get("required_tome_ids", []).size() +
			request_data.get("required_relic_ids", []).size()
		)
	var deadline_total: int = int(entry.get("deadline_turns_total", 0))
	if deadline_total <= 0:
		deadline_total = max(2, int(request_data.get("deadline_turns", 0)))
	return {
		"request_id": str(request_data.get("id", entry.get("request_id", ""))),
		"state": str(entry.get("state", "queued")),
		"deadline_kind": str(entry.get("deadline_kind", _get_request_deadline_kind(request_data))),
		"deadline_turns_total": deadline_total,
		"deadline_turns_remaining": max(0, int(entry.get("deadline_turns_remaining", deadline_total))),
		"progress": max(0, int(entry.get("progress", 0))),
		"progress_total": progress_total,
		"tome_id": str(request_data.get("tome_id", "")),
		"required_knowledge_tags": _copy_string_array(request_data.get("required_knowledge_tags", [])),
		"required_tome_ids": _copy_string_array(request_data.get("required_tome_ids", [])),
		"required_relic_ids": _copy_string_array(request_data.get("required_relic_ids", [])),
		"required_essence": max(0, int(request_data.get("required_essence", 0))),
		"reward_essence": max(0, int(request_data.get("reward_essence", 0))),
		"reward_card_ids": _copy_string_array(request_data.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(request_data.get("reward_room_ids", [])),
		"unlock_card_ids": _copy_string_array(request_data.get("unlock_card_ids", [])),
		"unlock_room_ids": _copy_string_array(request_data.get("unlock_room_ids", [])),
	}

func _find_next_request_id_for_queue(queue: Array) -> String:
	var request_ids: Array[String] = content_db.get_request_pool()
	if request_ids.is_empty():
		return ""
	var completed_request_ids: Array = save_data.get("completed_request_ids", [])
	var used_ids: Array[String] = []
	for entry in queue:
		var request_id: String = str(entry.get("request_id", ""))
		if request_id != "":
			used_ids.append(request_id)
	var start_index: int = request_ids.find(get_active_request_id())
	if start_index < 0:
		start_index = 0
	for offset in range(request_ids.size()):
		var candidate_id: String = request_ids[(start_index + offset) % request_ids.size()]
		if candidate_id == "" or completed_request_ids.has(candidate_id) or used_ids.has(candidate_id):
			continue
		return candidate_id
	return ""

func _complete_request_entry(entry: Dictionary, source: String = "") -> void:
	var request_id: String = str(entry.get("request_id", ""))
	if request_id == "":
		return
	var queue: Array = get_request_queue_entries()
	var index: int = _find_request_queue_index(queue, request_id)
	if index >= 0:
		queue.remove_at(index)
	var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
	if int(request_data.get("required_essence", 0)) > 0:
		spend_essence(int(request_data.get("required_essence", 0)))
	add_essence(int(request_data.get("reward_essence", 0)))
	for card_id in request_data.get("unlock_card_ids", []):
		grant_card_to_collection(str(card_id))
	for room_id in request_data.get("unlock_room_ids", []):
		var unlocked_rooms: Array = save_data.get("unlocked_room_blueprint_ids", [])
		var room_id_text: String = str(room_id)
		if room_id_text != "" and not unlocked_rooms.has(room_id_text):
			unlocked_rooms.append(room_id_text)
			save_data["unlocked_room_blueprint_ids"] = unlocked_rooms
	grant_card_to_collection(str(request_data.get("reward_card_ids", []).front() if not request_data.get("reward_card_ids", []).is_empty() else ""))
	var active_request_id: String = _refill_request_queue_after_removal(queue)
	save_data["request_queue"] = queue
	save_data["active_request_id"] = active_request_id
	save_data["completed_request_ids"] = _unique_string_array(save_data.get("completed_request_ids", []) + [request_id])
	_record_request_history(request_id, "completed", source)
	save_changed.emit()
	_save()

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

func get_owned_card_ids() -> Array[String]:
	return _copy_string_array(save_data.get("owned_card_ids", []))

func get_active_deck_ids() -> Array[String]:
	return _copy_string_array(save_data.get("active_deck_ids", []))

func get_pending_card_reward_options() -> Array[String]:
	return _copy_string_array(save_data.get("pending_card_reward_options", []))

func has_pending_card_reward_options() -> bool:
	return not get_pending_card_reward_options().is_empty()

func get_unlocked_reward_card_ids() -> Array[String]:
	return _copy_string_array(save_data.get("unlocked_reward_card_ids", []))

func get_active_deck_validation() -> Dictionary:
	return content_db.validate_deck(get_active_deck_ids(), get_owned_card_ids())

func is_active_deck_valid() -> bool:
	return bool(get_active_deck_validation().get("valid", false))

func get_card_collection() -> Array:
	var collection: Array = []
	var active_deck := get_active_deck_ids()
	for card_id in get_owned_card_ids():
		var card = content_db.get_card(card_id)
		if card == null:
			continue
		collection.append({
			"card_id": card_id,
			"name": card.name,
			"role": card.role,
			"tags": content_db.get_card_tags(card_id),
			"starter": content_db.get_starter_deck().has(card_id),
			"active": active_deck.has(card_id),
			"summary": content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses()),
		})
	return collection

func get_active_deck_entries() -> Array:
	var deck: Array = []
	var deck_ids := get_active_deck_ids()
	for index in range(deck_ids.size()):
		var card_id := deck_ids[index]
		var card = content_db.get_card(card_id)
		if card == null:
			continue
		deck.append({
			"slot_index": index,
			"card_id": card_id,
			"name": card.name,
			"role": card.role,
			"tags": content_db.get_card_tags(card_id),
			"summary": content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses()),
		})
	return deck

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

func get_active_deck_text() -> String:
	var validation := get_active_deck_validation()
	var lines: Array[String] = []
	lines.append("Deck status: %s" % ("valid" if bool(validation.get("valid", false)) else "invalid"))
	if not bool(validation.get("errors", []).is_empty()):
		lines.append("Deck check: %s" % "; ".join(validation.get("errors", [])))
	var deck_entries := get_active_deck_entries()
	for entry in deck_entries:
		lines.append("%d. %s" % [int(entry.get("slot_index", 0)) + 1, str(entry.get("summary", ""))])
	return "\n".join(lines)

func get_active_deck_brief_text() -> String:
	var validation := get_active_deck_validation()
	var deck_ids := get_active_deck_ids()
	var lines: Array[String] = []
	lines.append("Active deck (%d/%d): %s" % [deck_ids.size(), content_db.get_starter_deck().size(), "valid" if bool(validation.get("valid", false)) else "needs repair"])
	for entry in get_active_deck_entries():
		lines.append("- %s" % str(entry.get("name", entry.get("card_id", ""))))
	return "\n".join(lines)

func get_card_detail_text(card_id: String) -> String:
	return content_db.get_card_runtime_summary(card_id, get_active_archive_bonuses())

func is_request_completed(request_id: String) -> bool:
	return request_id in save_data.get("completed_request_ids", [])

func set_active_deck_slot(slot_index: int, card_id: String) -> bool:
	var deck_ids := get_active_deck_ids()
	if slot_index < 0 or slot_index >= deck_ids.size():
		return false
	if card_id == "" or not get_owned_card_ids().has(card_id):
		return false
	deck_ids[slot_index] = card_id
	return set_active_deck(deck_ids)

func set_active_deck(deck_ids: Array) -> bool:
	var validation: Dictionary = content_db.validate_deck(deck_ids, get_owned_card_ids())
	if not bool(validation.get("valid", false)):
		return false
	save_data["active_deck_ids"] = validation.get("deck_ids", [])
	save_changed.emit()
	_save()
	return true

func grant_card_to_collection(card_id: String) -> bool:
	if card_id == "":
		return false
	var card = content_db.get_card(card_id)
	if card == null:
		return false
	var owned_cards: Array = get_owned_card_ids()
	var changed := false
	if not owned_cards.has(card_id):
		owned_cards.append(card_id)
		save_data["owned_card_ids"] = owned_cards
		changed = true
	if not content_db.get_starter_deck().has(card_id):
		var unlocked_cards: Array = get_unlocked_reward_card_ids()
		if not unlocked_cards.has(card_id):
			unlocked_cards.append(card_id)
			save_data["unlocked_reward_card_ids"] = unlocked_cards
			changed = true
	_normalize_card_state()
	if changed:
		save_changed.emit()
		_save()
	return true

func queue_card_reward_options(option_ids: Array, source: String) -> void:
	var cleaned: Array[String] = []
	for option_id in option_ids:
		var card_id := str(option_id)
		if card_id == "":
			continue
		if content_db.get_card(card_id) == null:
			continue
		if cleaned.has(card_id):
			continue
		if content_db.get_reward_card_pool().has(card_id):
			cleaned.append(card_id)
	save_data["pending_card_reward_options"] = cleaned
	save_data["pending_card_reward_source"] = source
	save_changed.emit()
	_save()

func choose_pending_card_reward(card_id: String) -> bool:
	if card_id == "":
		return false
	var options: Array[String] = get_pending_card_reward_options()
	if not options.has(card_id):
		return false
	if not grant_card_to_collection(card_id):
		return false
	clear_pending_card_reward_options()
	return true

func clear_pending_card_reward_options() -> void:
	save_data["pending_card_reward_options"] = []
	save_data["pending_card_reward_source"] = ""
	save_changed.emit()
	_save()

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
	if has_pending_card_reward_options():
		push_warning("Cannot start a dive while a card reward is pending.")
		return null
	current_run = preload("res://scripts/core/run_state.gd").new()
	current_run.request_id = get_active_request_id()
	current_run.run_seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_msec())
	if not is_active_deck_valid():
		_normalize_card_state()
	current_run.deck_ids = get_active_deck_ids()
	current_run.room_sequence = content_db.build_0_3_dungeon_layout(current_run.run_seed)
	current_run.player_hp = 5
	current_run.player_max_hp = 5
	current_run.insight = 3
	current_run.shield = 0
	current_run.current_room_index = 0
	current_run.room_cleared = false
	current_run.reward_relic_id = ""
	current_run.reward_choice_bonus_count = 0
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
		if current_request_id != "":
			mark_request_completed(current_request_id, tome_id)
			_rotate_request_queue_after_completion(current_request_id)
			_queue_research_job(current_request_id, tome_id, relic_id)
		var reward_count := 3
		var reward_seed := Time.get_ticks_msec()
		if current_run != null:
			reward_count += max(0, int(current_run.reward_choice_bonus_count))
			reward_seed = int(current_run.run_seed)
		var reward_options: Array[String] = content_db.build_card_reward_options(
			reward_seed,
			get_owned_card_ids(),
			[],
			reward_count
		)
		queue_card_reward_options(reward_options, "dive")
	else:
		clear_pending_card_reward_options()

	advance_dive_turn()

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

func clear_research_job() -> void:
	save_data["research_job"] = {}
	save_changed.emit()
	_save()

func set_research_job_from_run(request_id: String, tome_id: String, relic_id: String, turns_total: int, essence_reward: int) -> void:
	var normalized_turns: int = max(1, turns_total)
	save_data["research_job"] = {
		"request_id": request_id,
		"tome_id": tome_id,
		"relic_id": relic_id,
		"state": "pending",
		"turns_total": normalized_turns,
		"turns_remaining": normalized_turns,
		"essence_reward": max(0, essence_reward),
	}
	save_changed.emit()
	_save()

func _expire_active_request(queue: Array) -> void:
	if queue.is_empty():
		return
	var active_entry: Dictionary = queue[0]
	active_entry["state"] = "expired"
	active_entry["deadline_turns_remaining"] = 0
	queue[0] = active_entry
	_rotate_request_queue_after_expiry(queue)

func _rotate_request_queue_after_expiry(queue: Array) -> void:
	if not queue.is_empty():
		queue.pop_front()
	while queue.size() < REQUEST_QUEUE_SIZE:
		var next_request_id := _next_queue_request_id("", queue)
		if next_request_id == "":
			break
		queue.append(_make_request_entry(next_request_id, "queued", queue.size()))
	_save_request_queue(queue)

func _next_queue_request_id(after_request_id: String, queue: Array) -> String:
	var completed_ids: Array = save_data.get("completed_request_ids", [])
	var request_id: String = content_db.get_next_request_id(after_request_id, completed_ids)
	if request_id == "":
		return ""
	while _queue_has_request_id(queue, request_id) and request_id != "":
		var next_id: String = content_db.get_next_request_id(request_id, completed_ids)
		if next_id == request_id:
			break
		request_id = next_id
		if request_id == "":
			break
	return request_id

func _queue_has_request_id(queue: Array, request_id: String) -> bool:
	for entry in queue:
		if str(entry.get("request_id", "")) == request_id:
			return true
	return false

func _make_request_entry(request_id: String, state: String, position: int) -> Dictionary:
	var request = content_db.get_request(request_id)
	if request == null:
		return {}
	var deadline_kind := "dive" if position % 2 == 0 else "library"
	var deadline_turns := 2 if deadline_kind == "dive" else 3
	var queue_state := state if state != "" else "queued"
	if position == 0 and queue_state == "queued":
		queue_state = "active"
	return {
		"request_id": request_id,
		"state": queue_state,
		"deadline_kind": deadline_kind,
		"deadline_turns_total": deadline_turns,
		"deadline_turns_remaining": deadline_turns,
	}

func _build_request_queue(active_request_id: String = "") -> Array:
	var queue: Array = []
	var request_pool: Array[String] = content_db.get_request_pool()
	if request_pool.is_empty():
		return queue
	var start_id: String = active_request_id
	if start_id == "":
		start_id = content_db.get_default_request_id()
	var start_index: int = request_pool.find(start_id)
	if start_index < 0:
		start_index = 0
	for offset in range(min(REQUEST_QUEUE_SIZE, request_pool.size())):
		var request_id: String = request_pool[(start_index + offset) % request_pool.size()]
		if _queue_has_request_id(queue, request_id):
			continue
		queue.append(_make_request_entry(request_id, "active" if offset == 0 else "queued", queue.size()))
	return queue

func _save_request_queue(queue: Array) -> void:
	var normalized := _duplicate_request_queue(queue)
	for index in range(normalized.size()):
		var entry: Dictionary = normalized[index]
		if index == 0 and not entry.is_empty():
			var entry_state := str(entry.get("state", "active"))
			entry["state"] = "active" if not (entry_state in ["completed", "expired"]) else entry_state
			entry["deadline_turns_remaining"] = int(entry.get("deadline_turns_total", 0))
		elif not entry.is_empty() and str(entry.get("state", "")) in ["active", "in_progress"]:
			entry["state"] = "queued"
		normalized[index] = entry
	if not normalized.is_empty():
		save_data["active_request_id"] = str(normalized[0].get("request_id", ""))
	save_data["request_queue"] = normalized
	save_changed.emit()
	_save()

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

func _copy_string_array(source: Array) -> Array[String]:
	var values: Array[String] = []
	for value in source:
		var value_text := str(value)
		if value_text != "":
			values.append(value_text)
	return values

func _unique_string_array(values: Array) -> Array[String]:
	var unique: Array[String] = []
	for value in values:
		var value_text := str(value)
		if value_text != "" and not unique.has(value_text):
			unique.append(value_text)
	return unique

func _record_request_history(request_id: String, state: String, note: String = "") -> void:
	if request_id == "":
		return
	var history: Array = save_data.get("request_history", [])
	history.append({
		"request_id": request_id,
		"state": state,
		"turn": int(save_data.get("library_turn_count", 0)),
		"note": note,
	})
	save_data["request_history"] = history

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

func _normalize_essence_state() -> void:
	save_data["essence"] = max(0, int(save_data.get("essence", 0)))
	save_data["library_turn_count"] = max(0, int(save_data.get("library_turn_count", 0)))
	save_data["patron_reroll_count"] = max(0, int(save_data.get("patron_reroll_count", 0)))
	var layout_id := str(save_data.get("station_layout_id", "balanced"))
	if not STATION_LAYOUTS.has(layout_id):
		save_data["station_layout_id"] = "balanced"

func _normalize_request_state() -> void:
	var queue := _duplicate_request_queue(save_data.get("request_queue", []))
	if queue.is_empty():
		queue = _build_initial_request_queue()
	else:
		queue = _normalize_request_queue(queue)
	save_data["request_queue"] = queue
	var active_request_id := str(save_data.get("active_request_id", ""))
	if active_request_id == "" or _find_request_queue_index(queue, active_request_id) < 0:
		active_request_id = str(queue[0].get("request_id", "")) if not queue.is_empty() else content_db.get_default_request_id()
	save_data["active_request_id"] = active_request_id
	var research_job := _duplicate_research_job(save_data.get("research_job", {}))
	if not research_job.is_empty():
		var request_id := str(research_job.get("request_id", ""))
		if request_id == "" or _find_request_queue_index(queue, request_id) < 0:
			research_job = {}
	save_data["research_job"] = research_job

func _duplicate_request_queue(source_queue: Array) -> Array:
	var queue: Array = []
	for entry in source_queue:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var request_id := str(entry.get("request_id", ""))
		if request_id == "":
			continue
		var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
		if request_data.is_empty():
			continue
		queue.append(_sanitize_request_entry(entry, request_data))
	return queue

func _duplicate_research_job(source_job: Dictionary) -> Dictionary:
	if source_job.is_empty():
		return {}
	return {
		"request_id": str(source_job.get("request_id", "")),
		"state": str(source_job.get("state", "pending")),
		"turns_total": max(0, int(source_job.get("turns_total", 0))),
		"turns_remaining": max(0, int(source_job.get("turns_remaining", 0))),
		"tome_id": str(source_job.get("tome_id", "")),
		"relic_id": str(source_job.get("relic_id", "")),
		"progress": max(0, int(source_job.get("progress", 0))),
		"progress_total": max(1, int(source_job.get("progress_total", 1))),
		"essence_reward": max(0, int(source_job.get("essence_reward", 0))),
		"essence_cost": max(0, int(source_job.get("essence_cost", 0))),
		"paid": bool(source_job.get("paid", false)),
		"reward_card_ids": _copy_string_array(source_job.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(source_job.get("reward_room_ids", [])),
		"knowledge_tags": _copy_string_array(source_job.get("knowledge_tags", [])),
	}

func _find_request_queue_index(queue: Array, request_id: String) -> int:
	for index in range(queue.size()):
		var entry: Dictionary = queue[index]
		if str(entry.get("request_id", "")) == request_id:
			return index
	return -1

func _get_request_deadline_kind(request_data: Dictionary) -> String:
	if int(request_data.get("required_essence", 0)) > 0:
		return "library"
	if request_data.get("required_knowledge_tags", []).size() > 0:
		return "library"
	return "dive"

func _get_request_queue_entry_for_id(request_id: String) -> Dictionary:
	var queue := get_request_queue_entries()
	for entry in queue:
		if str(entry.get("request_id", "")) == request_id:
			return entry
	return {}

func _pick_research_definition(request_data: Dictionary) -> Dictionary:
	var research_ids: Array[String] = content_db.get_research_definition_ids()
	if research_ids.is_empty():
		return {}
	var request_key := str(request_data.get("id", request_data.get("request_id", "")))
	var index: int = abs(hash(request_key)) % research_ids.size()
	return content_db.get_research_runtime_data(research_ids[index])

func _normalize_request_queue(queue: Array) -> Array:
	var normalized: Array = []
	var completed_request_ids: Array = save_data.get("completed_request_ids", [])
	for entry in queue:
		var sanitized := _sanitize_request_entry(entry)
		if sanitized.is_empty():
			continue
		var request_id := str(sanitized.get("request_id", ""))
		if request_id == "" or completed_request_ids.has(request_id):
			continue
		if int(sanitized.get("deadline_turns_remaining", 0)) <= 0 and str(sanitized.get("state", "")) not in ["completed", "expired"]:
			sanitized["state"] = "expired"
		normalized.append(sanitized)
	if normalized.is_empty():
		return _build_initial_request_queue()
	normalized[0]["state"] = "active"
	for index in range(1, normalized.size()):
		if str(normalized[index].get("state", "")) == "active":
			normalized[index]["state"] = "queued"
	return normalized

func _build_initial_request_queue() -> Array:
	var queue: Array = []
	var request_ids: Array[String] = content_db.get_request_pool()
	if request_ids.is_empty():
		return queue
	var active_request_id := str(save_data.get("active_request_id", ""))
	var start_index := request_ids.find(active_request_id)
	if start_index < 0:
		start_index = 0
	for offset in range(request_ids.size()):
		if queue.size() >= REQUEST_QUEUE_SIZE:
			break
		var candidate_id := request_ids[(start_index + offset) % request_ids.size()]
		if candidate_id == "" or _find_request_queue_index(queue, candidate_id) >= 0:
			continue
		queue.append(_make_request_queue_entry(candidate_id, "active" if queue.is_empty() else "queued"))
	return queue

func _make_request_queue_entry(request_id: String, state: String) -> Dictionary:
	var request_data: Dictionary = content_db.get_request_runtime_data(request_id)
	if request_data.is_empty():
		return {}
	var entry: Dictionary = _sanitize_request_entry({
		"request_id": request_id,
		"state": state,
		"deadline_turns_remaining": max(2, int(request_data.get("deadline_turns", 0))),
		"deadline_turns_total": max(2, int(request_data.get("deadline_turns", 0))),
		"progress": 0,
		"progress_total": 1,
	}, request_data)
	entry["progress_total"] = max(
		1,
		int(request_data.get("required_knowledge_tags", []).size()) +
		int(request_data.get("required_tome_ids", []).size()) +
		int(request_data.get("required_relic_ids", []).size())
	)
	return entry

func _queue_research_job(request_id: String, tome_id: String, relic_id: String) -> void:
	if request_id == "":
		return
	var research_def: Dictionary = _pick_research_definition(content_db.get_request_runtime_data(request_id))
	save_data["research_job"] = {
		"request_id": request_id,
		"state": "pending",
		"turns_total": max(1, int(research_def.get("turn_cost", RESEARCH_TURNS_BASE))),
		"turns_remaining": max(1, int(research_def.get("turn_cost", RESEARCH_TURNS_BASE))),
		"tome_id": tome_id,
		"relic_id": relic_id,
		"progress": 0,
		"progress_total": 1,
		"essence_reward": int(research_def.get("essence_reward", 0)),
		"essence_cost": int(research_def.get("essence_cost", 0)),
		"paid": false,
		"reward_card_ids": _copy_string_array(research_def.get("reward_card_ids", [])),
		"reward_room_ids": _copy_string_array(research_def.get("reward_room_ids", [])),
		"knowledge_tags": _copy_string_array(research_def.get("knowledge_tags", [])),
	}
	save_changed.emit()
	_save()

func _advance_research_job_turn() -> void:
	var job: Dictionary = _duplicate_research_job(save_data.get("research_job", {}))
	if job.is_empty() or str(job.get("state", "")) != "researching":
		return
	job["turns_remaining"] = max(0, int(job.get("turns_remaining", 0)) - 1)
	if int(job.get("turns_remaining", 0)) <= 0:
		_complete_research_job(job)
		return
	save_data["research_job"] = job

func _complete_research_job(job: Dictionary) -> void:
	if job.is_empty():
		return
	if not bool(job.get("paid", false)) and int(job.get("essence_cost", 0)) > 0:
		if not spend_essence(int(job.get("essence_cost", 0))):
			return
		job["paid"] = true
	var request_id := str(job.get("request_id", ""))
	if request_id != "":
		var entry := _get_request_queue_entry_for_id(request_id)
		if not entry.is_empty():
			_complete_request_entry(entry, "research")
			return
	if int(job.get("essence_reward", 0)) > 0:
		add_essence(int(job.get("essence_reward", 0)))
	for card_id in job.get("reward_card_ids", []):
		grant_card_to_collection(str(card_id))
	save_data["research_job"] = {}
	save_changed.emit()
	_save()

func _rotate_request_queue_after_completion(request_id: String) -> void:
	if request_id == "":
		return
	var queue := get_request_queue_entries()
	var index := _find_request_queue_index(queue, request_id)
	if index >= 0:
		queue.remove_at(index)
	_refill_request_queue_after_removal(queue)
	_commit_request_queue(queue)

func _refill_request_queue_after_removal(queue: Array) -> String:
	while queue.size() < REQUEST_QUEUE_SIZE:
		var next_request_id := _find_next_request_id_for_queue(queue)
		if next_request_id == "":
			break
		queue.append(_make_request_queue_entry(next_request_id, "queued"))
	if not queue.is_empty():
		queue[0]["state"] = "active"
		for index in range(1, queue.size()):
			if str(queue[index].get("state", "")) == "active":
				queue[index]["state"] = "queued"
		return str(queue[0].get("request_id", ""))
	return content_db.get_default_request_id()

func _commit_request_queue(queue: Array) -> void:
	var normalized: Array = _duplicate_request_queue(queue)
	if normalized.is_empty():
		normalized = _build_initial_request_queue()
	else:
		normalized = _normalize_request_queue(normalized)
	save_data["request_queue"] = normalized
	if normalized.is_empty():
		save_data["active_request_id"] = content_db.get_default_request_id()
	else:
		save_data["active_request_id"] = str(normalized[0].get("request_id", ""))
	save_changed.emit()
	_save()
