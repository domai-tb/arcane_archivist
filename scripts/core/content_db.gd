extends Node

const CardDefinitionClass := preload("res://scripts/data/card_definition.gd")
const EnemyDefinitionClass := preload("res://scripts/data/enemy_definition.gd")
const KnowledgeTagDefinitionClass := preload("res://scripts/data/knowledge_tag_definition.gd")
const RequestDefinitionClass := preload("res://scripts/data/request_definition.gd")
const RequestStateDefinitionClass := preload("res://scripts/data/request_state_definition.gd")
const ResearchDefinitionClass := preload("res://scripts/data/research_definition.gd")
const StationDefinitionClass := preload("res://scripts/data/station_definition.gd")
const TomeDefinitionClass := preload("res://scripts/data/tome_definition.gd")
const RelicDefinitionClass := preload("res://scripts/data/relic_definition.gd")
const RoomTemplateDefinitionClass := preload("res://scripts/data/room_template_definition.gd")

var knowledge_tags: Dictionary = {}
var cards: Dictionary = {}
var enemies: Dictionary = {}
var requests: Dictionary = {}
var request_states: Dictionary = {}
var research_definitions: Dictionary = {}
var stations: Dictionary = {}
var tomes: Dictionary = {}
var relics: Dictionary = {}
var rooms: Dictionary = {}
var knowledge_tag_order: Array[String] = []
var request_state_order: Array[String] = []
var research_order: Array[String] = []
var station_order: Array[String] = []
var archive_bonuses: Array[Dictionary] = []
var starter_deck: Array[String] = [
	"swift_step",
	"arc_strike",
	"ward_sign",
	"arc_bolt",
	"study_note",
]
var request_order: Array[String] = []
var relic_reward_pool: Array[String] = []
var reward_card_pool: Array[String] = []

func _ready() -> void:
	_build_content()

func get_default_request_id() -> String:
	if request_order.is_empty():
		return ""
	return request_order[0]

func get_request_pool() -> Array[String]:
	return request_order.duplicate()

func get_next_request_id(current_request_id: String, completed_request_ids: Array) -> String:
	if request_order.is_empty():
		return ""

	var start_index := request_order.find(current_request_id)
	if start_index < 0:
		start_index = -1

	for offset in range(request_order.size()):
		var candidate_index := (start_index + 1 + offset) % request_order.size()
		var candidate_id := request_order[candidate_index]
		if not completed_request_ids.has(candidate_id):
			return candidate_id

	return request_order[0]

func get_request(id: String):
	return requests.get(id)

func get_request_runtime_data(id: String) -> Dictionary:
	var request = get_request(id)
	if request == null:
		return {}
	return {
		"id": request.id,
		"name": request.name,
		"tome_id": request.tome_id,
		"objective_text": request.objective_text,
		"reward_text": request.reward_text,
		"archive_reward_text": request.archive_reward_text,
		"deadline_turns": int(request.deadline_turns),
		"required_knowledge_tags": request.required_knowledge_tags.duplicate(),
		"required_tome_ids": request.required_tome_ids.duplicate(),
		"required_relic_ids": request.required_relic_ids.duplicate(),
		"required_essence": int(request.required_essence),
		"reward_essence": int(request.reward_essence),
		"reward_card_ids": request.reward_card_ids.duplicate(),
		"reward_room_ids": request.reward_room_ids.duplicate(),
		"unlock_card_ids": request.unlock_card_ids.duplicate(),
		"unlock_room_ids": request.unlock_room_ids.duplicate(),
	}

func get_request_queue_order() -> Array[String]:
	return request_order.duplicate()

func get_request_queue_entries(active_request_id: String = "", completed_request_ids: Array = [], expired_request_ids: Array = [], in_progress_request_ids: Array = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for request_id in request_order:
		var state_id := get_request_state_for_request(
			request_id,
			active_request_id,
			completed_request_ids,
			expired_request_ids,
			in_progress_request_ids
		)
		var entry := get_request_runtime_data(request_id)
		if entry.is_empty():
			continue
		entry["state_id"] = state_id
		var state_def = get_request_state(state_id)
		entry["state_name"] = state_def.name if state_def != null else state_id
		entry["state_description"] = state_def.description if state_def != null else ""
		entries.append(entry)
	return entries

func get_request_state_for_request(request_id: String, active_request_id: String = "", completed_request_ids: Array = [], expired_request_ids: Array = [], in_progress_request_ids: Array = []) -> String:
	if request_id == "":
		return ""
	if completed_request_ids.has(request_id):
		return "completed"
	if expired_request_ids.has(request_id):
		return "expired"
	if in_progress_request_ids.has(request_id):
		return "in_progress"
	if active_request_id == request_id:
		return "active"
	return "queued"

func get_request_state(id: String):
	return request_states.get(id)

func get_request_state_ids() -> Array[String]:
	return request_state_order.duplicate()

func get_request_state_runtime_data(id: String) -> Dictionary:
	var state = get_request_state(id)
	if state == null:
		return {}
	return {
		"id": state.id,
		"name": state.name,
		"description": state.description,
		"ui_order": int(state.ui_order),
		"is_terminal": bool(state.is_terminal),
		"shows_in_queue": bool(state.shows_in_queue),
		"saves_progress": bool(state.saves_progress),
	}

func get_knowledge_tag(id: String):
	return knowledge_tags.get(id)

func get_knowledge_tag_ids() -> Array[String]:
	return knowledge_tag_order.duplicate()

func get_knowledge_tag_name(id: String) -> String:
	var tag = get_knowledge_tag(id)
	if tag == null:
		return id
	return tag.name

func get_knowledge_tag_runtime_data(id: String) -> Dictionary:
	var tag = get_knowledge_tag(id)
	if tag == null:
		return {}
	return {
		"id": tag.id,
		"name": tag.name,
		"description": tag.description,
		"category": tag.category,
		"ui_color": tag.ui_color,
	}

func get_research_definition(id: String):
	return research_definitions.get(id)

func get_research_definition_ids() -> Array[String]:
	return research_order.duplicate()

func get_research_runtime_data(id: String) -> Dictionary:
	var research = get_research_definition(id)
	if research == null:
		return {}
	return {
		"id": research.id,
		"name": research.name,
		"description": research.description,
		"knowledge_tags": research.knowledge_tags.duplicate(),
		"tome_ids": research.tome_ids.duplicate(),
		"relic_ids": research.relic_ids.duplicate(),
		"turn_cost": int(research.turn_cost),
		"essence_cost": int(research.essence_cost),
		"essence_reward": int(research.essence_reward),
		"reward_card_ids": research.reward_card_ids.duplicate(),
		"reward_room_ids": research.reward_room_ids.duplicate(),
	}

func get_station_definition(id: String):
	return stations.get(id)

func get_station_definition_ids() -> Array[String]:
	return station_order.duplicate()

func get_station_runtime_data(id: String) -> Dictionary:
	var station = get_station_definition(id)
	if station == null:
		return {}
	return {
		"id": station.id,
		"name": station.name,
		"description": station.description,
		"station_type": station.station_type,
		"essence_cost": int(station.essence_cost),
		"adjacency_bonus_text": station.adjacency_bonus_text,
		"adjacency_bonus_target_id": station.adjacency_bonus_target_id,
	}

func get_tome(id: String):
	return tomes.get(id)

func get_relic(id: String):
	return relics.get(id)

func get_card(id: String):
	return cards.get(id)

func get_enemy(id: String):
	return enemies.get(id)

func get_room(id: String):
	return rooms.get(id)

func get_archive_bonuses() -> Array[Dictionary]:
	return archive_bonuses.duplicate(true)

func get_relic_reward_pool() -> Array[String]:
	return relic_reward_pool.duplicate()

func get_reward_card_pool() -> Array[String]:
	return reward_card_pool.duplicate()

func pick_relic_reward(seed_value: int, excluded_ids: Array = []) -> String:
	var pool: Array[String] = []
	for relic_id in relic_reward_pool:
		if not excluded_ids.has(relic_id):
			pool.append(relic_id)

	if pool.is_empty():
		pool = relic_reward_pool.duplicate()
	if pool.is_empty():
		return ""

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return pool[rng.randi_range(0, pool.size() - 1)]

func get_all_card_ids() -> Array[String]:
	return cards.keys()

func get_card_tags(id: String) -> Array[String]:
	var card = get_card(id)
	if card == null:
		return []
	var tags: Array[String] = []
	if card.role != "":
		tags.append(card.role)
	for tag in card.tags:
		if not tags.has(tag):
			tags.append(tag)
	return tags

func get_card_runtime_data(id: String, active_bonuses: Array = []) -> Dictionary:
	var card = get_card(id)
	if card == null:
		return {}

	var runtime := {
		"id": card.id,
		"name": card.name,
		"description": card.description,
		"cost": card.cost,
		"cooldown": card.cooldown,
		"kind": card.kind,
		"role": card.role,
		"tags": get_card_tags(id),
		"power": card.power,
		"reach": card.reach,
		"move_bonus": card.move_bonus,
		"shield": card.shield,
		"insight_restore": card.insight_restore,
		"projectile_speed": card.projectile_speed,
		"notes": [],
	}

	var tag_lookup: Dictionary = {}
	for tag in runtime.tags:
		tag_lookup[str(tag)] = true

	for bonus in active_bonuses:
		var modifiers: Dictionary = bonus.get("modifiers", {})
		if int(modifiers.get("card_damage_bonus", 0)) != 0 and _card_matches_attack(runtime):
			runtime.power += int(modifiers.get("card_damage_bonus", 0))
			_append_runtime_note(runtime, bonus, "damage +%d" % int(modifiers.get("card_damage_bonus", 0)))
		if int(modifiers.get("reward_heal_bonus", 0)) != 0 and runtime.kind == "study":
			runtime.insight_restore += int(modifiers.get("reward_heal_bonus", 0))
			_append_runtime_note(runtime, bonus, "insight +%d" % int(modifiers.get("reward_heal_bonus", 0)))
		if float(modifiers.get("cooldown_reduction_bonus", 0.0)) != 0.0:
			runtime.cooldown = max(0.0, float(runtime.cooldown) - float(modifiers.get("cooldown_reduction_bonus", 0.0)))
			_append_runtime_note(runtime, bonus, "cooldown -%s" % str(modifiers.get("cooldown_reduction_bonus", 0.0)))

		for entry in bonus.get("card_modifiers", []):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var match_tag := str(entry.get("tag", ""))
			if match_tag == "" or not tag_lookup.has(match_tag):
				continue
			if int(entry.get("power_bonus", 0)) != 0:
				runtime.power += int(entry.get("power_bonus", 0))
				_append_runtime_note(runtime, bonus, "%s damage +%d" % [match_tag, int(entry.get("power_bonus", 0))])
			if int(entry.get("shield_bonus", 0)) != 0:
				runtime.shield += int(entry.get("shield_bonus", 0))
				_append_runtime_note(runtime, bonus, "%s shield +%d" % [match_tag, int(entry.get("shield_bonus", 0))])
			if int(entry.get("move_bonus", 0)) != 0:
				runtime.move_bonus += float(entry.get("move_bonus", 0))
				_append_runtime_note(runtime, bonus, "%s move +%d" % [match_tag, int(entry.get("move_bonus", 0))])
			if int(entry.get("insight_restore_bonus", 0)) != 0:
				runtime.insight_restore += int(entry.get("insight_restore_bonus", 0))
				_append_runtime_note(runtime, bonus, "%s insight +%d" % [match_tag, int(entry.get("insight_restore_bonus", 0))])
			if int(entry.get("cost_reduction", 0)) != 0:
				runtime.cost = max(0, int(runtime.cost) - int(entry.get("cost_reduction", 0)))
				_append_runtime_note(runtime, bonus, "%s cost -%d" % [match_tag, int(entry.get("cost_reduction", 0))])
			if float(entry.get("cooldown_bonus", 0.0)) != 0.0:
				runtime.cooldown = max(0.0, float(runtime.cooldown) + float(entry.get("cooldown_bonus", 0.0)))
				_append_runtime_note(runtime, bonus, "%s cooldown %+0.1f" % [match_tag, float(entry.get("cooldown_bonus", 0.0))])
			if float(entry.get("projectile_speed_bonus", 0.0)) != 0.0:
				runtime.projectile_speed += float(entry.get("projectile_speed_bonus", 0.0))
				_append_runtime_note(runtime, bonus, "%s projectile %+d" % [match_tag, int(entry.get("projectile_speed_bonus", 0.0))])

	return runtime

func get_card_runtime_summary(id: String, active_bonuses: Array = []) -> String:
	var runtime := get_card_runtime_data(id, active_bonuses)
	if runtime.is_empty():
		return id

	var tag_text := ""
	if not runtime.get("tags", []).is_empty():
		tag_text = " [%s]" % ", ".join(runtime.get("tags", []))
	var note_text := ""
	if not runtime.get("notes", []).is_empty():
		note_text = "\n" + "\n".join(runtime.get("notes", []))
	return "%s%s\nCost %d | Cooldown %.1f | Damage %d | Shield %d | Insight %d%s" % [
		runtime.get("name", id),
		tag_text,
		int(runtime.get("cost", 0)),
		float(runtime.get("cooldown", 0.0)),
		int(runtime.get("power", 0)),
		int(runtime.get("shield", 0)),
		int(runtime.get("insight_restore", 0)),
		note_text,
	]

func validate_deck(deck_ids: Array, owned_card_ids: Array) -> Dictionary:
	var deck_size := starter_deck.size()
	var sanitized: Array[String] = []
	var errors: Array[String] = []
	var roles_present: Dictionary = {
		"movement": false,
		"offense": false,
		"defense": false,
		"utility": false,
	}

	for card_id in deck_ids:
		var card_id_text := str(card_id)
		if card_id_text == "":
			continue
		var card = get_card(card_id_text)
		if card == null:
			errors.append("Unknown card id: %s" % card_id_text)
			continue
		if not owned_card_ids.has(card_id_text):
			errors.append("Card not owned: %s" % card_id_text)
			continue
		sanitized.append(card_id_text)
		if card.role != "" and roles_present.has(card.role):
			roles_present[card.role] = true

	if sanitized.size() != deck_size:
		errors.append("Deck must contain exactly %d cards." % deck_size)

	for role in roles_present.keys():
		if not bool(roles_present[role]):
			errors.append("Deck must include a %s card." % role)

	return {
		"valid": errors.is_empty(),
		"deck_ids": sanitized,
		"errors": errors,
		"roles_present": roles_present,
	}

func build_valid_deck(owned_card_ids: Array, preferred_deck_ids: Array = []) -> Array[String]:
	var preferred := preferred_deck_ids.duplicate()
	var validation := validate_deck(preferred, owned_card_ids)
	if bool(validation.get("valid", false)):
		return validation.get("deck_ids", starter_deck.duplicate())

	var fallback: Array[String] = []
	for card_id in starter_deck:
		if owned_card_ids.has(card_id):
			fallback.append(card_id)
	if fallback.size() < starter_deck.size():
		for card_id in owned_card_ids:
			var card_id_text := str(card_id)
			if card_id_text == "" or fallback.has(card_id_text):
				continue
			var card = get_card(card_id_text)
			if card == null:
				continue
			fallback.append(card_id_text)
			if fallback.size() >= starter_deck.size():
				break
	return fallback

func build_card_reward_options(seed_value: int, owned_card_ids: Array, bias_tags: Array = [], count: int = 3) -> Array[String]:
	var available: Array[String] = []
	for card_id in reward_card_pool:
		if not owned_card_ids.has(card_id):
			available.append(card_id)
	if available.is_empty():
		available = reward_card_pool.duplicate()
	if available.is_empty():
		return []

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var options: Array[String] = []
	var working := available.duplicate()
	while options.size() < count and not working.is_empty():
		var weighted: Array[String] = []
		for card_id in working:
			var weight := 1
			var card_tags := get_card_tags(card_id)
			for bias in bias_tags:
				if card_tags.has(str(bias)):
					weight += 2
			for _i in range(weight):
				weighted.append(card_id)
		if weighted.is_empty():
			weighted = working.duplicate()
		var chosen := weighted[rng.randi_range(0, weighted.size() - 1)]
		options.append(chosen)
		working.erase(chosen)

	return options

func validate_content() -> Array[String]:
	var errors: Array[String] = []
	for request_id in request_order:
		if get_request(request_id) == null:
			errors.append("Missing request id: %s" % request_id)
	for state_id in request_state_order:
		if get_request_state(state_id) == null:
			errors.append("Missing request state id: %s" % state_id)
	for tag_id in knowledge_tag_order:
		if get_knowledge_tag(tag_id) == null:
			errors.append("Missing knowledge tag id: %s" % tag_id)
	for research_id in research_order:
		if get_research_definition(research_id) == null:
			errors.append("Missing research id: %s" % research_id)
	for station_id in station_order:
		if get_station_definition(station_id) == null:
			errors.append("Missing station id: %s" % station_id)
	for tome_id in tomes.keys():
		if tome_id == "":
			errors.append("Empty tome id found.")
		var tome = get_tome(tome_id)
		if tome != null:
			for tag_id in tome.knowledge_tags:
				if get_knowledge_tag(str(tag_id)) == null:
					errors.append("Invalid tome knowledge tag: %s on %s" % [str(tag_id), tome_id])
	for relic_id in relics.keys():
		if relic_id == "":
			errors.append("Empty relic id found.")
		var relic = get_relic(relic_id)
		if relic != null:
			for tag_id in relic.knowledge_tags:
				if get_knowledge_tag(str(tag_id)) == null:
					errors.append("Invalid relic knowledge tag: %s on %s" % [str(tag_id), relic_id])
	for card_id in starter_deck:
		if get_card(card_id) == null:
			errors.append("Missing starter card id: %s" % card_id)
	for card_id in reward_card_pool:
		if get_card(card_id) == null:
			errors.append("Missing reward card id: %s" % card_id)
	for request_id in request_order:
		var request = get_request(request_id)
		if request == null:
			continue
		if request.tome_id != "" and get_tome(request.tome_id) == null:
			errors.append("Invalid request tome id: %s" % request.tome_id)
		for tag_id in request.required_knowledge_tags:
			if get_knowledge_tag(str(tag_id)) == null:
				errors.append("Invalid request knowledge tag: %s on %s" % [str(tag_id), request_id])
		for tome_id in request.required_tome_ids:
			if get_tome(str(tome_id)) == null:
				errors.append("Invalid request tome requirement: %s on %s" % [str(tome_id), request_id])
		for relic_id in request.required_relic_ids:
			if get_relic(str(relic_id)) == null:
				errors.append("Invalid request relic requirement: %s on %s" % [str(relic_id), request_id])
		for card_id in request.reward_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid request reward card id: %s on %s" % [str(card_id), request_id])
		for room_id in request.reward_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid request reward room id: %s on %s" % [str(room_id), request_id])
		for card_id in request.unlock_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid request unlock card id: %s on %s" % [str(card_id), request_id])
		for room_id in request.unlock_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid request unlock room id: %s on %s" % [str(room_id), request_id])
	for research_id in research_order:
		var research = get_research_definition(research_id)
		if research == null:
			continue
		for tag_id in research.knowledge_tags:
			if get_knowledge_tag(str(tag_id)) == null:
				errors.append("Invalid research knowledge tag: %s on %s" % [str(tag_id), research_id])
		for tome_id in research.tome_ids:
			if get_tome(str(tome_id)) == null:
				errors.append("Invalid research tome id: %s on %s" % [str(tome_id), research_id])
		for relic_id in research.relic_ids:
			if get_relic(str(relic_id)) == null:
				errors.append("Invalid research relic id: %s on %s" % [str(relic_id), research_id])
		for card_id in research.reward_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid research reward card id: %s on %s" % [str(card_id), research_id])
		for room_id in research.reward_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid research reward room id: %s on %s" % [str(room_id), research_id])
	for bonus in archive_bonuses:
		var tome_id := str(bonus.get("tome_id", ""))
		var relic_id := str(bonus.get("relic_id", ""))
		if get_tome(tome_id) == null:
			errors.append("Invalid archive bonus tome id: %s" % tome_id)
		if get_relic(relic_id) == null:
			errors.append("Invalid archive bonus relic id: %s" % relic_id)
	for room_id in rooms.keys():
		var room = get_room(room_id)
		if room == null:
			errors.append("Missing room id: %s" % room_id)
	return errors

func get_starter_deck() -> Array[String]:
	return starter_deck.duplicate()

func build_0_1_dungeon_layout(seed_value: int) -> Array[Dictionary]:
	return build_0_2_dungeon_layout(seed_value)

func build_0_2_dungeon_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var encounter_ids: Array[String] = ["encounter_mireling", "encounter_wisp"]
	if rng.randi_range(0, 1) == 1:
		encounter_ids.reverse()

	var layout: Array[Dictionary] = [
		{"room_id": "entrance", "role": "entrance"},
		{"room_id": encounter_ids[0], "role": "encounter"},
	]

	if rng.randf() < 0.75:
		var optional_ids: Array[String] = ["optional_cache", "optional_hazard", "optional_guard"]
		layout.append({
			"room_id": optional_ids[rng.randi_range(0, optional_ids.size() - 1)],
			"role": "optional",
		})

	layout.append({"room_id": encounter_ids[1], "role": "encounter"})
	layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func build_0_3_dungeon_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var variant := rng.randi_range(0, 2)
	var layout: Array[Dictionary] = [{"room_id": "entrance", "role": "entrance"}]

	match variant:
		0:
			layout.append({"room_id": "encounter_mireling", "role": "encounter"})
			layout.append({"room_id": "optional_card_choice", "role": "optional"})
			layout.append({"room_id": "elite_scriptorium", "role": "elite"})
			layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
		1:
			layout.append({"room_id": "encounter_wisp", "role": "encounter"})
			layout.append({"room_id": "encounter_mireling", "role": "encounter"})
			layout.append({"room_id": "optional_relic_cache", "role": "optional"})
			layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "card_choice"})
		_:
			layout.append({"room_id": "encounter_mireling", "role": "encounter"})
			layout.append({"room_id": "optional_puzzle_nook", "role": "optional"})
			layout.append({"room_id": "encounter_wisp", "role": "encounter"})
			layout.append({"room_id": "elite_scriptorium", "role": "elite"})
			layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})

	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func _build_content() -> void:
	if not cards.is_empty():
		return

	_add_request_state("queued", "Queued", "Waiting in the patron queue.", 0, false, true, false)
	_add_request_state("active", "Active", "Ready for the next dive.", 1, false, true, true)
	_add_request_state("in_progress", "In Progress", "Research or a dive is advancing the request.", 2, false, false, true)
	_add_request_state("completed", "Completed", "Finished and claimed.", 3, true, false, false)
	_add_request_state("expired", "Expired", "The request timed out and left the queue.", 4, true, false, false)

	_add_knowledge_tag("forbidden_history", "Forbidden History", "Records, censored lineages, and erased archives.", "archive", "#8B6A4C")
	_add_knowledge_tag("beast_lore", "Beast Lore", "Tracks, habits, bones, and living patterns.", "field", "#6D8B4F")
	_add_knowledge_tag("astral_theory", "Astral Theory", "Stars, tides, and unstable patterns in the sky.", "sky", "#6E78B8")
	_add_knowledge_tag("wardcraft", "Wardcraft", "Seals, protections, and the geometry of keeping things closed.", "sigil", "#5E9B9D")

	_add_request(
		"recover_ashen_index",
		"Recover Ashen Index",
		"ashen_index",
		"Find the soot-stained tome hidden below the library.",
		"The patron pays in a careful promise of future access.",
		"The archive remembers Ashen Index."
	)
	_add_request(
		"recover_gilded_ledger",
		"Recover Gilded Ledger",
		"gilded_ledger",
		"Bring back the ledger that records forbidden debts.",
		"The patron pays in sealed correspondence and access.",
		"The archive remembers Gilded Ledger."
	)
	_add_request(
		"recover_moon_catalog",
		"Recover Moon Catalog",
		"moon_catalog",
		"Return the catalog of tidal omens and lunar paths.",
		"The patron pays in cold silver and a standing favor.",
		"The archive remembers Moon Catalog."
	)
	_add_request(
		"recover_copper_atlas",
		"Recover Copper Atlas",
		"copper_atlas",
		"Retrieve the atlas of locked corridors and hinge-riddled vaults.",
		"The patron pays in a precise map of hidden paths.",
		"The archive remembers Copper Atlas."
	)
	_add_request(
		"recover_vellum_mirror",
		"Recover Vellum Mirror",
		"vellum_mirror",
		"Return the vellum mirror that reflects forgotten annotations.",
		"The patron pays in a citation for future use.",
		"The archive remembers Vellum Mirror."
	)
	_add_request(
		"recover_black_index",
		"Recover Black Index",
		"black_index",
		"Bring back the black index and a sample of its censored ink.",
		"The patron pays in essence and a whisper of hidden knowledge.",
		"The archive remembers Black Index.",
		4,
		["forbidden_history"],
		["black_index"],
		["void_ink_vial"],
		0,
		3,
		["sigil_chart"],
		["request_tome_cache"],
		["sigil_chart"],
		[]
	)
	_add_request(
		"catalog_wildbark_bestiary",
		"Catalog Wildbark Bestiary",
		"wildbark_bestiary",
		"Return the bestiary pages and a horn sample from the wilds.",
		"The patron pays in essence and a sharp, feral card pattern.",
		"The archive remembers Wildbark Bestiary.",
		4,
		["beast_lore"],
		["wildbark_bestiary"],
		["bramble_horn_sample"],
		0,
		2,
		["beast_snare"],
		["request_relic_cache"],
		["beast_snare"],
		[]
	)
	_add_request(
		"stabilize_ward_primer",
		"Stabilize Ward Primer",
		"ward_primer",
		"Deliver the ward primer and a sealing sample before the stacks shift.",
		"The patron pays in essence and a blueprint for stronger ordering.",
		"The archive remembers Ward Primer.",
		5,
		["wardcraft"],
		["ward_primer"],
		["sealwax_matrix"],
		1,
		4,
		["ward_echo", "lattice_bolt"],
		["request_archive_cache"],
		[],
		["request_archive_cache"]
	)

	_add_tome("ashen_index", "Ashen Index", "A soot-stained index of half-forgotten whispers.", ["forbidden_history"], 2, 1)
	_add_tome("gilded_ledger", "Gilded Ledger", "A ledger that keeps accounts the way curses do.", ["forbidden_history"], 2, 1)
	_add_tome("moon_catalog", "Moon Catalog", "A catalog of lunar movements and tidal annotations.", ["astral_theory"], 2, 1)
	_add_tome("copper_atlas", "Copper Atlas", "An atlas of hinges, corridors, and rotating shelves.", ["wardcraft"], 2, 1)
	_add_tome("vellum_mirror", "Vellum Mirror", "A mirror bound in vellum that returns written secrets.", ["forbidden_history", "astral_theory"], 2, 1)
	_add_tome("black_index", "Black Index", "A censored index with whole branches cut away.", ["forbidden_history"], 3, 1)
	_add_tome("wildbark_bestiary", "Wildbark Bestiary", "Field notes on tracks, teeth, and seasonal ferocity.", ["beast_lore"], 3, 1)
	_add_tome("tide_star_plates", "Tide-Star Plates", "Copper plates mapping tides to star positions.", ["astral_theory"], 3, 1)
	_add_tome("ward_primer", "Ward Primer", "A primer of seals, locks, and stacked protection glyphs.", ["wardcraft"], 3, 1)

	_add_relic("glass_lens", "Dormant Glass Lens", "A dormant lens that sharpens the hand that holds it.", "No active effect until paired.", ["astral_theory"], false, "", 0)
	_add_relic("ember_coil", "Ember Coil", "A coil that carries a tiny, stubborn heat.", "No active effect until paired.", ["wardcraft"], false, "", 0)
	_add_relic("threaded_sigil", "Threaded Sigil", "A sigil stitched into a thin silver mesh.", "No active effect until paired.", ["wardcraft"], false, "", 0)
	_add_relic("ivory_mark", "Ivory Mark", "A marker engraved with a watcher’s mark.", "No active effect until paired.", ["wardcraft"], false, "", 0)
	_add_relic("mothbone_charm", "Mothbone Charm", "A charm that hums in the presence of old paper.", "No active effect until paired.", ["forbidden_history"], false, "", 0)
	_add_relic("brass_key", "Brass Key", "A key that still feels warm from the last door it opened.", "No active effect until paired.", ["wardcraft"], false, "", 0)
	_add_relic("lunar_ribbon", "Lunar Ribbon", "A ribbon that shivers in moonlight.", "No active effect until paired.", ["astral_theory"], false, "", 0)
	_add_relic("ink_bell", "Ink Bell", "A small bell with a heavy ink-black clapper.", "No active effect until paired.", ["forbidden_history"], false, "", 0)
	_add_relic("void_ink_vial", "Void Ink Vial", "A vial of ink that swallows reflected light.", "Usable as a research sample.", ["forbidden_history"], true, "ink", 1)
	_add_relic("bramble_horn_sample", "Bramble Horn Sample", "A horn fragment scored by old growth and sharper teeth.", "Usable as a research sample.", ["beast_lore"], true, "bone", 1)
	_add_relic("star_salt_shard", "Star Salt Shard", "A crystalline shard that leaves frost on the palm.", "Usable as a research sample.", ["astral_theory"], true, "crystal", 1)
	_add_relic("sealwax_matrix", "Sealwax Matrix", "A hardened sealant sample used to bind wards.", "Usable as a research sample.", ["wardcraft"], true, "seal", 1)

	relic_reward_pool = [
		"glass_lens",
		"ember_coil",
		"threaded_sigil",
		"ivory_mark",
		"mothbone_charm",
		"brass_key",
		"lunar_ribbon",
		"ink_bell",
		"void_ink_vial",
		"bramble_horn_sample",
		"star_salt_shard",
		"sealwax_matrix",
	]

	_add_archive_bonus(
		"ashen_lens_guard",
		"Ashen Lens Guard",
		"Place Ashen Index beside Dormant Glass Lens to make Ward cards grant +1 shield and Quick cards dash farther.",
		"ashen_index",
		"glass_lens",
		{
			"starting_shield": 2,
			"card_modifiers": [
				{"tag": "ward", "shield_bonus": 1},
				{"tag": "quick", "move_bonus": 40, "cooldown_bonus": -0.1},
			],
		}
	)
	_add_archive_bonus(
		"ledger_coil_focus",
		"Ledger Coil Focus",
		"Place Gilded Ledger beside Ember Coil to make Heavy and Bolt cards deal +1 damage.",
		"gilded_ledger",
		"ember_coil",
		{
			"card_damage_bonus": 1,
			"card_modifiers": [
				{"tag": "heavy", "power_bonus": 1},
				{"tag": "bolt", "power_bonus": 1, "projectile_speed_bonus": 80},
			],
		}
	)
	_add_archive_bonus(
		"moon_sigil_rhythm",
		"Moon Sigil Rhythm",
		"Place Moon Catalog beside Threaded Sigil to make Scholarly cards restore +1 insight and Quick cards cycle faster.",
		"moon_catalog",
		"threaded_sigil",
		{
			"cooldown_reduction_bonus": 0.5,
			"card_modifiers": [
				{"tag": "scholarly", "insight_restore_bonus": 1},
				{"tag": "quick", "cooldown_bonus": -0.5},
			],
		}
	)
	_add_archive_bonus(
		"mothbone_lexicon",
		"Mothbone Lexicon",
		"Place Moon Catalog beside Mothbone Charm to lower the cost of Scholarly and Utility cards.",
		"moon_catalog",
		"mothbone_charm",
		{
			"card_modifiers": [
				{"tag": "scholarly", "cost_reduction": 1},
				{"tag": "utility", "cost_reduction": 1},
			],
		}
	)
	_add_archive_bonus(
		"ivory_watch",
		"Ivory Watch",
		"Place Gilded Ledger beside Ivory Mark so Defense cards gain +1 shield and stay valuable in elite rooms.",
		"gilded_ledger",
		"ivory_mark",
		{
			"card_modifiers": [
				{"tag": "defense", "shield_bonus": 1},
				{"tag": "ward", "shield_bonus": 1},
			],
		}
	)

	_add_card("swift_step", "Swift Step", "Dash short distance.", 1, 1.5, "dash", 0.0, 0.0, 180.0, 0, 0, 0.0, "movement", ["quick"])
	_add_card("arc_strike", "Arc Strike", "Hit the nearest foe for solid damage.", 1, 2.2, "strike", 2.0, 170.0, 0.0, 0, 0, 0.0, "offense", ["heavy"])
	_add_card("ward_sign", "Ward Sign", "Gain shielding against the next hits.", 1, 3.0, "ward", 0.0, 0.0, 0.0, 2, 0, 0.0, "defense", ["ward"])
	_add_card("arc_bolt", "Arc Bolt", "Fire a bolt at a distant enemy.", 1, 2.5, "bolt", 2.0, 300.0, 0.0, 0, 0, 620.0, "offense", ["bolt", "scholarly"])
	_add_card("study_note", "Study Note", "Restore insight on a slower cadence.", 0, 4.0, "study", 0.0, 0.0, 0.0, 0, 1, 0.0, "utility", ["scholarly"])
	_add_card("ember_lance", "Ember Lance", "Drive a hot spear of force through the nearest threat.", 1, 2.4, "strike", 3.0, 220.0, 0.0, 0, 0, 0.0, "offense", ["flame", "heavy"])
	_add_card("mirror_guard", "Mirror Guard", "Raise a clean ward that reflects a little pressure.", 1, 2.8, "ward", 0.0, 0.0, 0.0, 3, 0, 0.0, "defense", ["ward", "scholarly"])
	_add_card("lens_focus", "Lens Focus", "Refine your next move with precise study.", 0, 3.4, "study", 0.0, 0.0, 0.0, 0, 2, 0.0, "utility", ["scholarly"])
	_add_card("moon_stride", "Moon Stride", "Dash with a smoother arc and a longer reach.", 1, 1.9, "dash", 0.0, 0.0, 230.0, 0, 0, 0.0, "movement", ["quick", "lunar"])
	_add_card("chain_script", "Chain Script", "Link several letters into a heavier striking pattern.", 1, 2.6, "strike", 2.0, 190.0, 0.0, 0, 0, 0.0, "offense", ["heavy", "scholarly"])
	_add_card("veil_flare", "Veil Flare", "A compact flare that clears space and steadies your hands.", 1, 2.1, "bolt", 2.0, 260.0, 0.0, 0, 1, 560.0, "utility", ["quick", "flame"])
	_add_card("sigil_chart", "Sigil Chart", "Trace a line of defenses through the page.", 0, 3.1, "study", 0.0, 0.0, 0.0, 0, 2, 0.0, "utility", ["scholarly", "ward"], ["recover_black_index"])
	_add_card("beast_snare", "Beast Snare", "Anchor a target with a patient, hooked pattern.", 1, 2.7, "strike", 2.0, 210.0, 0.0, 1, 0, 0.0, "offense", ["heavy", "ward"], ["catalog_wildbark_bestiary"])
	_add_card("astral_focus", "Astral Focus", "Bring the sky into sharper alignment.", 0, 3.0, "study", 0.0, 0.0, 0.0, 0, 2, 0.0, "utility", ["scholarly", "lunar"], [])
	_add_card("ward_echo", "Ward Echo", "Let a shield rebound with a softer edge.", 1, 2.5, "ward", 0.0, 0.0, 0.0, 3, 0, 0.0, "defense", ["ward", "scholarly"], [])
	_add_card("ink_reversal", "Ink Reversal", "Turn a marked opening into a slip of momentum.", 0, 2.2, "dash", 0.0, 0.0, 210.0, 0, 0, 0.0, "movement", ["quick", "scholarly"], [])
	_add_card("lattice_bolt", "Lattice Bolt", "Fire a structured bolt that breaks lines cleanly.", 1, 2.3, "bolt", 2.0, 320.0, 0.0, 0, 0, 660.0, "offense", ["bolt", "ward"], [])

	reward_card_pool = [
		"ember_lance",
		"mirror_guard",
		"lens_focus",
		"moon_stride",
		"chain_script",
		"veil_flare",
		"sigil_chart",
		"beast_snare",
		"astral_focus",
		"ward_echo",
		"ink_reversal",
		"lattice_bolt",
	]

	_add_enemy("mireling", "Mireling", "A small chaser that keeps moving.", 3, 55.0, 1, 24.0, 1.0, "melee", 0.0)
	_add_enemy("scribal_wisp", "Scribal Wisp", "A shy ranged threat that hovers back.", 2, 40.0, 1, 170.0, 1.4, "ranged", 280.0)
	_add_enemy("elite_scribe", "Elite Scribe", "A disciplined vault-keeper that punishes slow approaches.", 8, 48.0, 2, 190.0, 1.1, "elite", 340.0)

	_add_room("entrance", "Entrance", "entrance", [], "", "")
	_add_room("encounter_mireling", "Echoing Stacks", "encounter", ["mireling"], "", "")
	_add_room("encounter_wisp", "Quiet Annex", "encounter", ["scribal_wisp"], "ink_pool", "")
	_add_room("reward_room", "Study Cache", "reward", [], "", "rest")
	_add_room("tome_room", "Sealed Archive", "tome", [], "", "tome")
	_add_room("optional_cache", "Whisper Cache", "optional", [], "", "relic_cache")
	_add_room("optional_hazard", "Ink Pool", "optional", [], "ink_pool", "")
	_add_room("optional_guard", "Watch Chamber", "optional", ["mireling", "scribal_wisp"], "", "")
	_add_room("optional_card_choice", "Card Cache", "optional", [], "", "card_choice")
	_add_room("optional_relic_cache", "Relic Cache", "optional", [], "", "relic_cache")
	_add_room("optional_puzzle_nook", "Puzzle Nook", "optional", ["scribal_wisp"], "", "card_choice")
	_add_room("elite_scriptorium", "Elite Scriptorium", "elite", ["elite_scribe"], "", "card_choice")
	_add_room("request_tome_cache", "Requested Tome Cache", "reward", [], "", "request_tome")
	_add_room("request_relic_cache", "Requested Reliquary Cache", "reward", [], "", "request_relic")
	_add_room("request_archive_cache", "Requested Archive Cache", "reward", [], "", "request_archive")

	_add_research_definition(
		"research_forbidden_history",
		"Forbidden History Research",
		"Cross-reference censored tomes and dark samples to recover erased context.",
		["forbidden_history"],
		["ashen_index", "black_index", "gilded_ledger"],
		["void_ink_vial", "ink_bell"],
		2,
		1,
		1,
		["sigil_chart"],
		["request_tome_cache"]
	)
	_add_research_definition(
		"research_beast_lore",
		"Beast Lore Research",
		"Study tracks, samples, and the way a creature refuses the page.",
		["beast_lore"],
		["wildbark_bestiary"],
		["bramble_horn_sample"],
		2,
		1,
		1,
		["beast_snare"],
		["request_relic_cache"]
	)
	_add_research_definition(
		"research_astral_theory",
		"Astral Theory Research",
		"Align measurements against tides, stars, and the way they shift in memory.",
		["astral_theory"],
		["moon_catalog", "tide_star_plates", "vellum_mirror"],
		["star_salt_shard", "lunar_ribbon", "glass_lens"],
		2,
		1,
		1,
		["astral_focus"],
		[]
	)
	_add_research_definition(
		"research_wardcraft",
		"Wardcraft Research",
		"Translate seals, keys, and closures into a working protection scheme.",
		["wardcraft"],
		["ward_primer", "copper_atlas"],
		["sealwax_matrix", "threaded_sigil", "brass_key"],
		2,
		1,
		1,
		["ward_echo", "lattice_bolt"],
		["request_archive_cache"]
	)

	_add_station_definition(
		"request_board",
		"Request Board",
		"Display active patron requests and their deadlines.",
		"request_board",
		0,
		"",
		""
	)
	_add_station_definition(
		"research_desk",
		"Research Desk",
		"Advance research jobs using recovered tomes and relic samples.",
		"research_desk",
		1,
		"Archive shelves next to the desk reduce research time.",
		"archive_shelf"
	)
	_add_station_definition(
		"archive_shelf",
		"Archive Shelf",
		"Store tomes and samples close enough to accelerate research.",
		"archive_shelf",
		0,
		"Placing this next to the research desk reduces research time.",
		"research_desk"
	)
	_add_station_definition(
		"essence_lamp",
		"Essence Lamp",
		"Spend essence to reroll, rush research, or stabilize a respec.",
		"essence_lamp",
		1,
		"",
		""
	)

	request_order = [
		"recover_ashen_index",
		"recover_gilded_ledger",
		"recover_moon_catalog",
		"recover_copper_atlas",
		"recover_vellum_mirror",
		"recover_black_index",
		"catalog_wildbark_bestiary",
		"stabilize_ward_primer",
	]
	request_state_order = ["queued", "active", "in_progress", "completed", "expired"]
	knowledge_tag_order = ["forbidden_history", "beast_lore", "astral_theory", "wardcraft"]
	research_order = [
		"research_forbidden_history",
		"research_beast_lore",
		"research_astral_theory",
		"research_wardcraft",
	]
	station_order = ["request_board", "research_desk", "archive_shelf", "essence_lamp"]

func _add_request(id: String, request_name: String, tome_id: String, objective_text: String, reward_text: String, archive_reward_text: String, deadline_turns: int = 0, required_knowledge_tags: Array[String] = [], required_tome_ids: Array[String] = [], required_relic_ids: Array[String] = [], required_essence: int = 0, reward_essence: int = 0, reward_card_ids: Array[String] = [], reward_room_ids: Array[String] = [], unlock_card_ids: Array[String] = [], unlock_room_ids: Array[String] = []) -> void:
	var request := RequestDefinitionClass.new()
	request.id = id
	request.name = request_name
	request.tome_id = tome_id
	request.objective_text = objective_text
	request.reward_text = reward_text
	request.archive_reward_text = archive_reward_text
	request.deadline_turns = deadline_turns
	request.required_knowledge_tags = required_knowledge_tags
	request.required_tome_ids = required_tome_ids
	request.required_relic_ids = required_relic_ids
	request.required_essence = required_essence
	request.reward_essence = reward_essence
	request.reward_card_ids = reward_card_ids
	request.reward_room_ids = reward_room_ids
	request.unlock_card_ids = unlock_card_ids
	request.unlock_room_ids = unlock_room_ids
	requests[id] = request

func _add_knowledge_tag(id: String, tag_name: String, description: String, category: String, ui_color: String) -> void:
	var tag := KnowledgeTagDefinitionClass.new()
	tag.id = id
	tag.name = tag_name
	tag.description = description
	tag.category = category
	tag.ui_color = ui_color
	knowledge_tags[id] = tag
	if not knowledge_tag_order.has(id):
		knowledge_tag_order.append(id)

func _add_request_state(id: String, state_name: String, description: String, ui_order: int, is_terminal: bool, shows_in_queue: bool, saves_progress: bool) -> void:
	var state := RequestStateDefinitionClass.new()
	state.id = id
	state.name = state_name
	state.description = description
	state.ui_order = ui_order
	state.is_terminal = is_terminal
	state.shows_in_queue = shows_in_queue
	state.saves_progress = saves_progress
	request_states[id] = state
	if not request_state_order.has(id):
		request_state_order.append(id)

func _add_tome(id: String, tome_name: String, description: String, knowledge_tags_list: Array[String] = [], research_value: int = 1, essence_value: int = 0) -> void:
	var tome := TomeDefinitionClass.new()
	tome.id = id
	tome.name = tome_name
	tome.description = description
	tome.knowledge_tags = knowledge_tags_list
	tome.research_value = research_value
	tome.essence_value = essence_value
	tomes[id] = tome

func _add_relic(id: String, relic_name: String, description: String, dormant_note: String, knowledge_tags_list: Array[String] = [], is_research_sample: bool = false, sample_kind: String = "", essence_value: int = 0) -> void:
	var relic := RelicDefinitionClass.new()
	relic.id = id
	relic.name = relic_name
	relic.description = description
	relic.dormant_note = dormant_note
	relic.knowledge_tags = knowledge_tags_list
	relic.is_research_sample = is_research_sample
	relic.sample_kind = sample_kind
	relic.essence_value = essence_value
	relics[id] = relic

func _add_archive_bonus(id: String, bonus_name: String, description: String, tome_id: String, relic_id: String, modifiers: Dictionary) -> void:
	archive_bonuses.append({
		"id": id,
		"name": bonus_name,
		"description": description,
		"tome_id": tome_id,
		"relic_id": relic_id,
		"modifiers": modifiers,
	})

func _add_research_definition(id: String, research_name: String, description: String, knowledge_tags_list: Array[String] = [], tome_ids: Array[String] = [], relic_ids: Array[String] = [], turn_cost: int = 1, essence_cost: int = 0, essence_reward: int = 0, reward_card_ids: Array[String] = [], reward_room_ids: Array[String] = []) -> void:
	var research := ResearchDefinitionClass.new()
	research.id = id
	research.name = research_name
	research.description = description
	research.knowledge_tags = knowledge_tags_list
	research.tome_ids = tome_ids
	research.relic_ids = relic_ids
	research.turn_cost = turn_cost
	research.essence_cost = essence_cost
	research.essence_reward = essence_reward
	research.reward_card_ids = reward_card_ids
	research.reward_room_ids = reward_room_ids
	research_definitions[id] = research
	if not research_order.has(id):
		research_order.append(id)

func _add_station_definition(id: String, station_name: String, description: String, station_type: String, essence_cost: int = 0, adjacency_bonus_text: String = "", adjacency_bonus_target_id: String = "") -> void:
	var station := StationDefinitionClass.new()
	station.id = id
	station.name = station_name
	station.description = description
	station.station_type = station_type
	station.essence_cost = essence_cost
	station.adjacency_bonus_text = adjacency_bonus_text
	station.adjacency_bonus_target_id = adjacency_bonus_target_id
	stations[id] = station
	if not station_order.has(id):
		station_order.append(id)

func _add_card(id: String, card_name: String, description: String, cost: int, cooldown: float, kind: String, damage: float, card_reach: float, move_bonus: float, shield: int, insight_restore: int, projectile_speed: float, role: String = "", tags: Array[String] = [], unlock_request_ids: Array[String] = []) -> void:
	var card := CardDefinitionClass.new()
	card.id = id
	card.name = card_name
	card.description = description
	card.cost = cost
	card.cooldown = cooldown
	card.kind = kind
	card.role = role
	card.tags = tags
	card.power = damage
	card.reach = card_reach
	card.move_bonus = move_bonus
	card.shield = shield
	card.insight_restore = insight_restore
	card.projectile_speed = projectile_speed
	card.unlock_request_ids = unlock_request_ids
	cards[id] = card

func _card_matches_attack(card_data: Dictionary) -> bool:
	var role := str(card_data.get("role", ""))
	var tags: Array = card_data.get("tags", [])
	return role == "offense" or tags.has("heavy") or tags.has("bolt") or tags.has("flame")

func _append_runtime_note(runtime: Dictionary, bonus: Dictionary, suffix: String) -> void:
	var note := "%s: %s" % [str(bonus.get("name", bonus.get("id", ""))), suffix]
	var notes: Array = runtime.get("notes", [])
	if not notes.has(note):
		notes.append(note)
		runtime["notes"] = notes

func _add_enemy(id: String, enemy_name: String, description: String, max_hp: int, move_speed: float, damage: int, attack_range: float, attack_cooldown: float, kind: String, projectile_speed: float) -> void:
	var enemy := EnemyDefinitionClass.new()
	enemy.id = id
	enemy.name = enemy_name
	enemy.description = description
	enemy.max_hp = max_hp
	enemy.move_speed = move_speed
	enemy.damage = damage
	enemy.attack_range = attack_range
	enemy.attack_cooldown = attack_cooldown
	enemy.kind = kind
	enemy.projectile_speed = projectile_speed
	enemies[id] = enemy

func _add_room(id: String, room_name: String, room_type: String, enemy_ids: Array[String], hazard_kind: String, reward_kind: String) -> void:
	var room := RoomTemplateDefinitionClass.new()
	room.id = id
	room.name = room_name
	room.room_type = room_type
	room.enemy_ids = enemy_ids
	room.hazard_kind = hazard_kind
	room.reward_kind = reward_kind
	rooms[id] = room
