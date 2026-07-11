extends Node

const CardDefinitionClass := preload("res://scripts/data/card_definition.gd")
const EnemyDefinitionClass := preload("res://scripts/data/enemy_definition.gd")
const KnowledgeTagDefinitionClass := preload("res://scripts/data/knowledge_tag_definition.gd")
const RequestDefinitionClass := preload("res://scripts/data/request_definition.gd")
const RequestStateDefinitionClass := preload("res://scripts/data/request_state_definition.gd")
const ResearchDefinitionClass := preload("res://scripts/data/research_definition.gd")
const ArchiveWingDefinitionClass := preload("res://scripts/data/archive_wing_definition.gd")
const CardVariantDefinitionClass := preload("res://scripts/data/card_variant_definition.gd")
const CurseDefinitionClass := preload("res://scripts/data/curse_definition.gd")
const PatronFactionDefinitionClass := preload("res://scripts/data/patron_faction_definition.gd")
const StationDefinitionClass := preload("res://scripts/data/station_definition.gd")
const ReplayRecordDefinitionClass := preload("res://scripts/data/replay_record_definition.gd")
const RequestTemplateDefinitionClass := preload("res://scripts/data/request_template_definition.gd")
const TomeDefinitionClass := preload("res://scripts/data/tome_definition.gd")
const RelicDefinitionClass := preload("res://scripts/data/relic_definition.gd")
const RelicSetDefinitionClass := preload("res://scripts/data/relic_set_definition.gd")
const RoomTemplateDefinitionClass := preload("res://scripts/data/room_template_definition.gd")

var knowledge_tags: Dictionary = {}
var cards: Dictionary = {}
var enemies: Dictionary = {}
var requests: Dictionary = {}
var request_states: Dictionary = {}
var research_definitions: Dictionary = {}
var archive_wings: Dictionary = {}
var card_variants: Dictionary = {}
var curses: Dictionary = {}
var patron_factions: Dictionary = {}
var stations: Dictionary = {}
var replay_records: Dictionary = {}
var request_templates: Dictionary = {}
var tomes: Dictionary = {}
var relics: Dictionary = {}
var relic_sets: Dictionary = {}
var rooms: Dictionary = {}
var knowledge_tag_order: Array[String] = []
var request_state_order: Array[String] = []
var research_order: Array[String] = []
var archive_wing_order: Array[String] = []
var card_variant_order: Array[String] = []
var curse_order: Array[String] = []
var patron_faction_order: Array[String] = []
var station_order: Array[String] = []
var replay_record_order: Array[String] = []
var request_template_order: Array[String] = []
var relic_set_order: Array[String] = []
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

func get_archive_wing(id: String):
	return archive_wings.get(id)

func get_archive_wing_ids() -> Array[String]:
	return archive_wing_order.duplicate()

func get_archive_wing_runtime_data(id: String) -> Dictionary:
	var wing = get_archive_wing(id)
	if wing == null:
		return {}
	return {
		"id": wing.id,
		"name": wing.name,
		"description": wing.description,
		"focus_knowledge_tag": wing.focus_knowledge_tag,
		"specialization_path": wing.specialization_path,
		"base_modifiers": wing.base_modifiers.duplicate(true),
		"upgrade_tiers": wing.upgrade_tiers.duplicate(true),
		"unlock_card_ids": wing.unlock_card_ids.duplicate(),
		"unlock_request_ids": wing.unlock_request_ids.duplicate(),
	}

func get_relic_set(id: String):
	return relic_sets.get(id)

func get_relic_set_ids() -> Array[String]:
	return relic_set_order.duplicate()

func get_relic_set_runtime_data(id: String) -> Dictionary:
	var relic_set = get_relic_set(id)
	if relic_set == null:
		return {}
	return {
		"id": relic_set.id,
		"name": relic_set.name,
		"description": relic_set.description,
		"relic_ids": relic_set.relic_ids.duplicate(),
		"bonuses": relic_set.bonuses.duplicate(true),
	}

func get_patron_faction(id: String):
	return patron_factions.get(id)

func get_patron_faction_ids() -> Array[String]:
	return patron_faction_order.duplicate()

func get_patron_faction_runtime_data(id: String) -> Dictionary:
	var faction = get_patron_faction(id)
	if faction == null:
		return {}
	return {
		"id": faction.id,
		"name": faction.name,
		"description": faction.description,
		"request_ids": faction.request_ids.duplicate(),
		"reputation_tiers": faction.reputation_tiers.duplicate(true),
		"ally_faction_ids": faction.ally_faction_ids.duplicate(),
		"rival_faction_ids": faction.rival_faction_ids.duplicate(),
		"tracked_tags": faction.tracked_tags.duplicate(),
	}

func get_curse(id: String):
	return curses.get(id)

func get_curse_ids() -> Array[String]:
	return curse_order.duplicate()

func get_curse_runtime_data(id: String) -> Dictionary:
	var curse = get_curse(id)
	if curse == null:
		return {}
	return {
		"id": curse.id,
		"name": curse.name,
		"description": curse.description,
		"family": curse.family,
		"risk_text": curse.risk_text,
		"reward_text": curse.reward_text,
		"modifiers": curse.modifiers.duplicate(true),
		"reward_essence": int(curse.reward_essence),
		"reward_reputation": curse.reward_reputation.duplicate(true),
		"incompatible_request_ids": curse.incompatible_request_ids.duplicate(),
		"incompatible_room_types": curse.incompatible_room_types.duplicate(),
		"incompatible_tags": curse.incompatible_tags.duplicate(),
		"reward_record_ids": curse.reward_record_ids.duplicate(),
	}

func get_replay_record(id: String):
	return replay_records.get(id)

func get_replay_record_ids() -> Array[String]:
	return replay_record_order.duplicate()

func get_replay_record_runtime_data(id: String) -> Dictionary:
	var record = get_replay_record(id)
	if record == null:
		return {}
	return {
		"id": record.id,
		"name": record.name,
		"description": record.description,
		"category": record.category,
		"summary_template": record.summary_template,
		"tracked_fields": record.tracked_fields.duplicate(),
		"display_tags": record.display_tags.duplicate(),
	}

func get_request_template(id: String):
	return request_templates.get(id)

func get_request_template_ids() -> Array[String]:
	return request_template_order.duplicate()

func get_request_template_runtime_data(id: String) -> Dictionary:
	var template = get_request_template(id)
	if template == null:
		return {}
	return {
		"id": template.id,
		"name": template.name,
		"description": template.description,
		"template_kind": template.template_kind,
		"objective_text": template.objective_text,
		"reward_text": template.reward_text,
		"archive_reward_text": template.archive_reward_text,
		"required_knowledge_tags": template.required_knowledge_tags.duplicate(),
		"required_tome_ids": template.required_tome_ids.duplicate(),
		"required_relic_ids": template.required_relic_ids.duplicate(),
		"required_essence": int(template.required_essence),
		"reward_essence": int(template.reward_essence),
		"reward_card_ids": template.reward_card_ids.duplicate(),
		"reward_room_ids": template.reward_room_ids.duplicate(),
		"unlock_card_ids": template.unlock_card_ids.duplicate(),
		"unlock_room_ids": template.unlock_room_ids.duplicate(),
		"branch_reward_ids": template.branch_reward_ids.duplicate(),
		"faction_id": template.faction_id,
		"progression_rewards": template.progression_rewards.duplicate(true),
	}

func get_card_variant(id: String):
	return card_variants.get(id)

func get_card_variant_ids() -> Array[String]:
	return card_variant_order.duplicate()

func get_card_variant_runtime_data(id: String) -> Dictionary:
	var variant = get_card_variant(id)
	if variant == null:
		return {}
	return {
		"id": variant.id,
		"name": variant.name,
		"description": variant.description,
		"base_card_id": variant.base_card_id,
		"variant_kind": variant.variant_kind,
		"cost_delta": int(variant.cost_delta),
		"cooldown_delta": float(variant.cooldown_delta),
		"power_delta": float(variant.power_delta),
		"reach_delta": float(variant.reach_delta),
		"move_bonus_delta": float(variant.move_bonus_delta),
		"shield_delta": int(variant.shield_delta),
		"insight_restore_delta": int(variant.insight_restore_delta),
		"projectile_speed_delta": float(variant.projectile_speed_delta),
		"added_tags": variant.added_tags.duplicate(),
		"removed_tags": variant.removed_tags.duplicate(),
		"unlock_request_ids": variant.unlock_request_ids.duplicate(),
		"unlock_reward_room_ids": variant.unlock_reward_room_ids.duplicate(),
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
	for wing_id in archive_wing_order:
		var wing = get_archive_wing(wing_id)
		if wing == null:
			errors.append("Missing archive wing id: %s" % wing_id)
			continue
		if wing.focus_knowledge_tag != "" and get_knowledge_tag(wing.focus_knowledge_tag) == null:
			errors.append("Invalid archive wing knowledge tag: %s on %s" % [wing.focus_knowledge_tag, wing_id])
		for card_id in wing.unlock_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid archive wing unlock card id: %s on %s" % [str(card_id), wing_id])
		for request_id in wing.unlock_request_ids:
			if get_request(str(request_id)) == null:
				errors.append("Invalid archive wing unlock request id: %s on %s" % [str(request_id), wing_id])
		for tier in wing.upgrade_tiers:
			if typeof(tier) != TYPE_DICTIONARY:
				errors.append("Invalid archive wing tier on %s." % wing_id)
				continue
			for card_id in tier.get("unlock_card_ids", []):
				if get_card(str(card_id)) == null:
					errors.append("Invalid archive wing tier unlock card id: %s on %s" % [str(card_id), wing_id])
			for request_id in tier.get("unlock_request_ids", []):
				if get_request(str(request_id)) == null:
					errors.append("Invalid archive wing tier unlock request id: %s on %s" % [str(request_id), wing_id])
	for relic_set_id in relic_set_order:
		var relic_set = get_relic_set(relic_set_id)
		if relic_set == null:
			errors.append("Missing relic set id: %s" % relic_set_id)
			continue
		for relic_id in relic_set.relic_ids:
			if get_relic(str(relic_id)) == null:
				errors.append("Invalid relic set relic id: %s on %s" % [str(relic_id), relic_set_id])
		for bonus in relic_set.bonuses:
			if typeof(bonus) != TYPE_DICTIONARY:
				errors.append("Invalid relic set bonus on %s." % relic_set_id)
				continue
			for card_id in bonus.get("reward_card_ids", []):
				if get_card(str(card_id)) == null:
					errors.append("Invalid relic set reward card id: %s on %s" % [str(card_id), relic_set_id])
			for request_id in bonus.get("unlock_request_ids", []):
				if get_request(str(request_id)) == null:
					errors.append("Invalid relic set unlock request id: %s on %s" % [str(request_id), relic_set_id])
	for faction_id in patron_faction_order:
		var faction = get_patron_faction(faction_id)
		if faction == null:
			errors.append("Missing patron faction id: %s" % faction_id)
			continue
		for request_id in faction.request_ids:
			if get_request(str(request_id)) == null:
				errors.append("Invalid patron faction request id: %s on %s" % [str(request_id), faction_id])
		for ally_id in faction.ally_faction_ids:
			if ally_id != "" and get_patron_faction(str(ally_id)) == null:
				errors.append("Invalid patron faction ally id: %s on %s" % [str(ally_id), faction_id])
		for rival_id in faction.rival_faction_ids:
			if rival_id != "" and get_patron_faction(str(rival_id)) == null:
				errors.append("Invalid patron faction rival id: %s on %s" % [str(rival_id), faction_id])
		for tier in faction.reputation_tiers:
			if typeof(tier) != TYPE_DICTIONARY:
				errors.append("Invalid patron faction tier on %s." % faction_id)
				continue
			for request_id in tier.get("unlock_request_ids", []):
				if get_request(str(request_id)) == null:
					errors.append("Invalid patron faction tier unlock request id: %s on %s" % [str(request_id), faction_id])
			for card_id in tier.get("unlock_card_ids", []):
				if get_card(str(card_id)) == null:
					errors.append("Invalid patron faction tier unlock card id: %s on %s" % [str(card_id), faction_id])
	for curse_id in curse_order:
		var curse = get_curse(curse_id)
		if curse == null:
			errors.append("Missing curse id: %s" % curse_id)
			continue
		for request_id in curse.incompatible_request_ids:
			if get_request(str(request_id)) == null:
				errors.append("Invalid curse incompatible request id: %s on %s" % [str(request_id), curse_id])
		for record_id in curse.reward_record_ids:
			if get_replay_record(str(record_id)) == null:
				errors.append("Invalid curse reward record id: %s on %s" % [str(record_id), curse_id])
	for record_id in replay_record_order:
		if get_replay_record(record_id) == null:
			errors.append("Missing replay record id: %s" % record_id)
	for template_id in request_template_order:
		var template = get_request_template(template_id)
		if template == null:
			errors.append("Missing request template id: %s" % template_id)
			continue
		if template.faction_id != "" and get_patron_faction(template.faction_id) == null:
			errors.append("Invalid request template faction id: %s on %s" % [template.faction_id, template_id])
		for tag_id in template.required_knowledge_tags:
			if get_knowledge_tag(str(tag_id)) == null:
				errors.append("Invalid request template knowledge tag: %s on %s" % [str(tag_id), template_id])
		for tome_id in template.required_tome_ids:
			if get_tome(str(tome_id)) == null:
				errors.append("Invalid request template tome id: %s on %s" % [str(tome_id), template_id])
		for relic_id in template.required_relic_ids:
			if get_relic(str(relic_id)) == null:
				errors.append("Invalid request template relic id: %s on %s" % [str(relic_id), template_id])
		for card_id in template.reward_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid request template reward card id: %s on %s" % [str(card_id), template_id])
		for room_id in template.reward_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid request template reward room id: %s on %s" % [str(room_id), template_id])
		for card_id in template.unlock_card_ids:
			if get_card(str(card_id)) == null:
				errors.append("Invalid request template unlock card id: %s on %s" % [str(card_id), template_id])
		for room_id in template.unlock_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid request template unlock room id: %s on %s" % [str(room_id), template_id])
		if template.faction_id != "" and get_patron_faction(template.faction_id) == null:
			errors.append("Invalid request template faction id: %s on %s" % [template.faction_id, template_id])
		for branch_id in template.branch_reward_ids:
			var branch_id_text := str(branch_id)
			if branch_id_text == "":
				errors.append("Empty request template branch reward id on %s." % template_id)
			elif get_card(branch_id_text) == null and get_request(branch_id_text) == null and get_replay_record(branch_id_text) == null:
				errors.append("Invalid request template branch reward id: %s on %s" % [branch_id_text, template_id])
	for pressure_event_id in get_pressure_event_ids():
		var pressure_event = get_pressure_event_runtime_data(pressure_event_id)
		if pressure_event.is_empty():
			errors.append("Missing pressure event id: %s" % pressure_event_id)
			continue
		var effect_types := ["clear", "remove_archive_item", "delay_request", "set_station_layout"]
		for option in pressure_event.get("response_options", []):
			if typeof(option) != TYPE_DICTIONARY:
				errors.append("Invalid pressure event option on %s." % pressure_event_id)
				continue
			if str(option.get("id", "")) == "":
				errors.append("Empty pressure event option id on %s." % pressure_event_id)
			var effect_type := str(option.get("effect_type", ""))
			if not effect_types.has(effect_type):
				errors.append("Invalid pressure event option effect: %s on %s" % [effect_type, pressure_event_id])
			if effect_type == "set_station_layout" and str(option.get("layout_id", "")) == "":
				errors.append("Invalid pressure event layout id on %s." % pressure_event_id)
	for variant_id in card_variant_order:
		var variant = get_card_variant(variant_id)
		if variant == null:
			errors.append("Missing card variant id: %s" % variant_id)
			continue
		if variant.base_card_id == "" or get_card(variant.base_card_id) == null:
			errors.append("Invalid card variant base card id: %s on %s" % [variant.base_card_id, variant_id])
		for request_id in variant.unlock_request_ids:
			if get_request(str(request_id)) == null:
				errors.append("Invalid card variant unlock request id: %s on %s" % [str(request_id), variant_id])
		for room_id in variant.unlock_reward_room_ids:
			if get_room(str(room_id)) == null:
				errors.append("Invalid card variant unlock reward room id: %s on %s" % [str(room_id), variant_id])
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
		if request.faction_id != "" and get_patron_faction(request.faction_id) == null:
			errors.append("Invalid request faction id: %s on %s" % [request.faction_id, request_id])
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
		for wing_id in request.progression_rewards.get("unlock_wing_ids", []):
			if get_archive_wing(str(wing_id)) == null:
				errors.append("Invalid request progression wing id: %s on %s" % [str(wing_id), request_id])
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

func get_dungeon_theme_ids() -> Array[String]:
	return ["forbidden_history", "beast_lore", "astral_theory", "wardcraft"]

func get_dungeon_theme_runtime_data(theme_id: String) -> Dictionary:
	var themes := {
		"forbidden_history": {
			"id": "forbidden_history",
			"name": "Archive Echoes",
			"description": "Censored stacks and card-choice rooms make the dive feel like a tight archival audit.",
			"preview_text": "Expect a higher chance of elite pressure and reward routing that leans toward card choices.",
		},
		"beast_lore": {
			"id": "beast_lore",
			"name": "Feral Stacks",
			"description": "Mireling-heavy chambers and hazard rooms reward measured movement.",
			"preview_text": "Expect more melee pressure, more hazard rooms, and steadier rest rewards.",
		},
		"astral_theory": {
			"id": "astral_theory",
			"name": "Starfall Annex",
			"description": "Wisp-led routes and puzzle nooks reward precise card sequencing.",
			"preview_text": "Expect ranged pressure, puzzle rooms, and a stronger card-choice bias.",
		},
		"wardcraft": {
			"id": "wardcraft",
			"name": "Wardline Vault",
			"description": "Guard rooms and sturdy recovery make the route feel safer but slower.",
			"preview_text": "Expect steadier enemy mixes, fewer hazards, and more rest-oriented rewards.",
		},
	}
	var theme: Dictionary = themes.get(theme_id, themes["wardcraft"])
	if typeof(theme) != TYPE_DICTIONARY:
		return {}
	return theme.duplicate(true)

func get_dungeon_theme_id_for_request(request_id: String) -> String:
	var request = get_request(request_id)
	if request == null:
		return "wardcraft"

	var tags: Array = request.required_knowledge_tags
	if tags.has("astral_theory"):
		return "astral_theory"
	if tags.has("beast_lore"):
		return "beast_lore"
	if tags.has("forbidden_history"):
		return "forbidden_history"
	if tags.has("wardcraft"):
		return "wardcraft"
	return "wardcraft"

func get_dungeon_theme_preview_data(request_id: String) -> Dictionary:
	var theme_id := get_dungeon_theme_id_for_request(request_id)
	var theme := get_dungeon_theme_runtime_data(theme_id)
	if theme.is_empty():
		return {}
	var request = get_request(request_id)
	return {
		"theme_id": theme_id,
		"name": str(theme.get("name", theme_id)),
		"description": str(theme.get("description", "")),
		"preview_text": str(theme.get("preview_text", "")),
		"request_name": request.name if request != null else "",
	}

func get_dungeon_theme_preview_text(request_id: String) -> String:
	var data := get_dungeon_theme_preview_data(request_id)
	if data.is_empty():
		return "Dungeon theme: Wardline Vault\nA safe, balanced route."
	var lines: Array[String] = []
	lines.append("Dungeon theme: %s" % str(data.get("name", data.get("theme_id", ""))))
	lines.append(str(data.get("description", "")))
	var preview_text := str(data.get("preview_text", ""))
	if preview_text != "":
		lines.append(preview_text)
	return "\n".join(lines)

func build_dungeon_layout(seed_value: int, request_id: String = "") -> Array[Dictionary]:
	var theme_id := get_dungeon_theme_id_for_request(request_id)
	var layout := _build_dungeon_theme_layout(theme_id, seed_value)
	for entry in layout:
		if typeof(entry) == TYPE_DICTIONARY:
			entry["theme_id"] = theme_id
	return layout

func _build_dungeon_theme_layout(theme_id: String, seed_value: int) -> Array[Dictionary]:
	match theme_id:
		"beast_lore":
			return _build_beast_lore_layout(seed_value)
		"astral_theory":
			return _build_astral_theory_layout(seed_value)
		"wardcraft":
			return _build_wardcraft_layout(seed_value)
		_:
			return _build_forbidden_history_layout(seed_value)

func _build_forbidden_history_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x6F5A
	var layout: Array[Dictionary] = [{"room_id": "entrance", "role": "entrance"}]
	if rng.randf() < 0.5:
		layout.append({"room_id": "encounter_wisp", "role": "encounter"})
		layout.append({"room_id": "optional_card_choice", "role": "optional"})
		layout.append({"room_id": "encounter_mireling", "role": "encounter"})
		layout.append({"room_id": "elite_scriptorium", "role": "elite"})
		layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "card_choice"})
	else:
		layout.append({"room_id": "optional_puzzle_nook", "role": "optional"})
		layout.append({"room_id": "encounter_mireling", "role": "encounter"})
		layout.append({"room_id": "optional_relic_cache", "role": "optional"})
		layout.append({"room_id": "encounter_wisp", "role": "encounter"})
		layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func _build_beast_lore_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x2B71
	var layout: Array[Dictionary] = [{"room_id": "entrance", "role": "entrance"}]
	layout.append({"room_id": "encounter_mireling", "role": "encounter"})
	if rng.randf() < 0.5:
		layout.append({"room_id": "optional_hazard", "role": "optional"})
		layout.append({"room_id": "encounter_mireling", "role": "encounter"})
	else:
		layout.append({"room_id": "optional_guard", "role": "optional"})
		layout.append({"room_id": "encounter_wisp", "role": "encounter"})
	layout.append({"room_id": "optional_relic_cache", "role": "optional"})
	layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func _build_astral_theory_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x44C3
	var layout: Array[Dictionary] = [{"room_id": "entrance", "role": "entrance"}]
	layout.append({"room_id": "encounter_wisp", "role": "encounter"})
	if rng.randf() < 0.5:
		layout.append({"room_id": "optional_puzzle_nook", "role": "optional"})
		layout.append({"room_id": "encounter_wisp", "role": "encounter"})
	else:
		layout.append({"room_id": "optional_card_choice", "role": "optional"})
		layout.append({"room_id": "encounter_mireling", "role": "encounter"})
	layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "card_choice"})
	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func _build_wardcraft_layout(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5C29
	var layout: Array[Dictionary] = [{"room_id": "entrance", "role": "entrance"}]
	layout.append({"room_id": "encounter_mireling", "role": "encounter"})
	if rng.randf() < 0.5:
		layout.append({"room_id": "optional_guard", "role": "optional"})
		layout.append({"room_id": "encounter_wisp", "role": "encounter"})
		layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
	else:
		layout.append({"room_id": "optional_relic_cache", "role": "optional"})
		layout.append({"room_id": "elite_scriptorium", "role": "elite"})
		layout.append({"room_id": "reward_room", "role": "reward", "reward_kind": "rest"})
	layout.append({"room_id": "tome_room", "role": "tome"})
	return layout

func get_pressure_event_ids() -> Array[String]:
	return ["archive_breach", "shelf_shift", "relic_drift", "queue_clog", "station_stutter", "visitor_rush"]

func get_pressure_event_runtime_data(event_id: String) -> Dictionary:
	var events := {
		"shelf_shift": {
			"id": "shelf_shift",
			"name": "Shelf Shift",
			"description": "A shelf tremor threatens a placed tome or relic.",
			"threat_kind": "archive",
			"threat_assets": ["tome", "relic"],
			"response_options": [
				{
					"id": "brace",
					"name": "Brace the shelves",
					"description": "Spend 1 essence to stabilize the archive.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "tome_shift",
					"name": "Unpin a tome",
					"description": "Move one tome out of the archive to protect the rest.",
					"essence_cost": 0,
					"effect_type": "remove_archive_item",
					"item_type": "tome",
				},
				{
					"id": "relic_shift",
					"name": "Unpin a relic",
					"description": "Move one relic out of the archive to protect the rest.",
					"essence_cost": 0,
					"effect_type": "remove_archive_item",
					"item_type": "relic",
				},
			],
		},
		"archive_breach": {
			"id": "archive_breach",
			"name": "Archive Breach",
			"description": "A hostile raider force tries to crack open the archive stacks.",
			"threat_kind": "attack",
			"threat_assets": ["archive", "station"],
			"response_options": [
				{
					"id": "seal",
					"name": "Seal the breach",
					"description": "Spend 1 essence to lock the attack down before it spreads.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "relocate",
					"name": "Relocate a tome",
					"description": "Move one tome out of danger to preserve the archive.",
					"essence_cost": 0,
					"effect_type": "remove_archive_item",
					"item_type": "tome",
				},
				{
					"id": "reroute",
					"name": "Reroute the queue",
					"description": "Delay the active request while staff seal the stacks.",
					"essence_cost": 0,
					"effect_type": "delay_request",
					"delay_turns": 1,
				},
			],
		},
		"relic_drift": {
			"id": "relic_drift",
			"name": "Relic Drift",
			"description": "A catalog surge nudges a relic off its marked placement.",
			"threat_kind": "archive",
			"threat_assets": ["relic"],
			"response_options": [
				{
					"id": "brace",
					"name": "Brace the reliquary",
					"description": "Spend 1 essence to hold the placement steady.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "relic_shift",
					"name": "Re-shelve the relic",
					"description": "Move one relic out of the archive to avoid the drift.",
					"essence_cost": 0,
					"effect_type": "remove_archive_item",
					"item_type": "relic",
				},
			],
		},
		"queue_clog": {
			"id": "queue_clog",
			"name": "Queue Clog",
			"description": "The patron board buckles under too many requests at once.",
			"threat_kind": "queue",
			"threat_assets": ["request"],
			"response_options": [
				{
					"id": "brace",
					"name": "Smooth the queue",
					"description": "Spend 1 essence to steady the request board.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "delay",
					"name": "Delay the active request",
					"description": "Buy one extra turn for the current request.",
					"essence_cost": 0,
					"effect_type": "delay_request",
					"delay_turns": 1,
				},
			],
		},
		"station_stutter": {
			"id": "station_stutter",
			"name": "Station Stutter",
			"description": "The station layout slips out of alignment.",
			"threat_kind": "station",
			"threat_assets": ["station"],
			"response_options": [
				{
					"id": "brace",
					"name": "Reanchor the stations",
					"description": "Spend 1 essence to hold the current layout.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "reset",
					"name": "Reset to balanced",
					"description": "Return the layout to its balanced baseline.",
					"essence_cost": 0,
					"effect_type": "set_station_layout",
					"layout_id": "balanced",
				},
			],
		},
		"visitor_rush": {
			"id": "visitor_rush",
			"name": "Visitor Rush",
			"description": "A crowd surge crowds the request board and the archive desk.",
			"threat_kind": "visitor",
			"threat_assets": ["request", "station"],
			"response_options": [
				{
					"id": "brace",
					"name": "Guide the crowd",
					"description": "Spend 1 essence to calm the rush.",
					"essence_cost": 1,
					"effect_type": "clear",
				},
				{
					"id": "delay",
					"name": "Absorb the backlog",
					"description": "Buy one extra turn for the active request.",
					"essence_cost": 0,
					"effect_type": "delay_request",
					"delay_turns": 1,
				},
			],
		},
	}
	var event: Dictionary = events.get(event_id, events["station_stutter"])
	if typeof(event) != TYPE_DICTIONARY:
		return {}
	return event.duplicate(true)

func get_pressure_event_id_for_request(request_id: String, turn_index: int = 0) -> String:
	var pool: Array[String] = get_pressure_event_ids()
	if pool.is_empty():
		return ""
	var request = get_request(request_id)
	if request == null:
		return pool[turn_index % pool.size()]

	var themed_pool: Array[String] = []
	var tags: Array = request.required_knowledge_tags
	if tags.has("forbidden_history"):
		themed_pool = ["archive_breach", "shelf_shift", "relic_drift", "station_stutter"]
	elif tags.has("beast_lore"):
		themed_pool = ["visitor_rush", "queue_clog", "archive_breach"]
	elif tags.has("astral_theory"):
		themed_pool = ["queue_clog", "visitor_rush", "archive_breach"]
	elif tags.has("wardcraft"):
		themed_pool = ["archive_breach", "station_stutter", "shelf_shift", "relic_drift"]
	if themed_pool.is_empty():
		themed_pool = pool
	return themed_pool[turn_index % themed_pool.size()]

func get_pressure_event_preview_text(request_id: String, turn_index: int = 0) -> String:
	var event_id := get_pressure_event_id_for_request(request_id, turn_index)
	var event := get_pressure_event_runtime_data(event_id)
	if event.is_empty():
		return "No pressure event is currently available."
	var lines: Array[String] = []
	lines.append("%s: %s" % [str(event.get("name", event_id)), str(event.get("description", ""))])
	var assets: Array = event.get("threat_assets", [])
	if not assets.is_empty():
		lines.append("Threatened assets: %s." % ", ".join(assets))
	return "\n".join(lines)

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
	_add_card("wardline_sigil", "Wardline Sigil", "A ward-sign variant tuned for the Bastion Wing.", 1, 2.9, "ward", 0.0, 0.0, 0.0, 4, 0, 0.0, "defense", ["ward", "scholarly"], ["quiet_margin_audience"])
	_add_card("sealed_step", "Sealed Step", "A swift-step variant that trades freedom for sturdier positioning.", 1, 1.4, "dash", 0.0, 0.0, 260.0, 0, 0, 0.0, "movement", ["quick", "ward"], ["quiet_margin_relay"])
	_add_card("lattice_guard", "Lattice Guard", "A mirror-guard variant used once the faction chain reaches its final accord.", 1, 2.6, "ward", 0.0, 0.0, 0.0, 5, 1, 0.0, "defense", ["ward", "scholarly"], ["quiet_margin_accord"])

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
		"wardline_sigil",
		"sealed_step",
		"lattice_guard",
		"sigil_chart_prime",
		"moon_stride_lens",
		"arc_bolt_lattice",
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

	_add_archive_wing(
		"astral_wing",
		"Astral Wing",
		"Specialize in foresight, reward choice, and smoother cooldowns.",
		"astral_theory",
		"foresight",
		{"reward_choice_bonus_count": 1},
		[
			{
				"id": "astral_gallery",
				"name": "Observation Gallery",
				"description": "Adds another reward preview and a bit more choice control.",
				"essence_cost": 2,
				"modifiers": {"reward_choice_bonus_count": 1},
			},
			{
				"id": "astral_vault",
				"name": "Star Vault",
				"description": "Reduces cooldown pressure and improves study value.",
				"essence_cost": 4,
				"modifiers": {"cooldown_reduction_bonus": 0.25, "reward_heal_bonus": 1},
			},
			{
				"id": "astral_lane",
				"name": "Lens Lane",
				"description": "A sharper layout that rewards focused offense.",
				"essence_cost": 6,
				"modifiers": {"card_damage_bonus": 1, "reward_heal_bonus": 1},
			},
		],
		["astral_focus"],
		["recover_moon_catalog"]
	)
	_add_archive_wing(
		"beast_wing",
		"Beast Wing",
		"Specialize in resilience, close-range pressure, and safer dives.",
		"beast_lore",
		"survival",
		{"starting_shield": 1},
		[
			{
				"id": "beast_trail",
				"name": "Trail Chamber",
				"description": "Starts dives with more protection and recovery.",
				"essence_cost": 2,
				"modifiers": {"starting_shield": 1, "reward_heal_bonus": 1},
			},
			{
				"id": "beast_trap",
				"name": "Trap Gallery",
				"description": "Improves pressure against tougher foes.",
				"essence_cost": 4,
				"modifiers": {"card_damage_bonus": 1, "bonus_vs_enemy_kind": "melee", "bonus_vs_enemy_kind_damage": 1},
			},
			{
				"id": "beast_hunt",
				"name": "Hunt Wing",
				"description": "A broader reward spread for risky dives.",
				"essence_cost": 6,
				"modifiers": {"starting_shield": 1, "reward_choice_bonus_count": 1},
			},
		],
		["beast_snare"],
		["catalog_wildbark_bestiary"]
	)
	_add_archive_wing(
		"ward_wing",
		"Ward Wing",
		"Specialize in protection, stability, and archive control.",
		"wardcraft",
		"containment",
		{"starting_shield": 2},
		[
			{
				"id": "ward_seal",
				"name": "Seal Bay",
				"description": "A sturdier start for tight dives.",
				"essence_cost": 2,
				"modifiers": {"starting_shield": 2},
			},
			{
				"id": "ward_lattice",
				"name": "Lattice Alcove",
				"description": "Shaves cooldowns and favors defense.",
				"essence_cost": 4,
				"modifiers": {"cooldown_reduction_bonus": 0.25, "card_damage_bonus": 1},
			},
			{
				"id": "ward_archive",
				"name": "Archive Lock",
				"description": "Improves reward reliability and resilience.",
				"essence_cost": 6,
				"modifiers": {"reward_choice_bonus_count": 1, "reward_heal_bonus": 1},
			},
		],
		["ward_echo"],
		["stabilize_ward_primer"]
	)

	_add_relic_set(
		"quiet_stack",
		"Quiet Stack",
		"The archive remembers old paperwork and the hands that kept it together.",
		["ashen_index", "gilded_ledger", "mothbone_charm"],
		[
			{"required_count": 1, "name": "Quiet Baseline", "modifiers": {"reward_heal_bonus": 1}},
			{"required_count": 2, "name": "Quiet Pattern", "modifiers": {"reward_choice_bonus_count": 1}},
			{"required_count": 3, "name": "Quiet Stack Complete", "modifiers": {"card_damage_bonus": 1}, "record_id": "relic_set_complete"},
		]
	)
	_add_relic_set(
		"warded_route",
		"Warded Route",
		"Tooling for corridors, keys, and walls that prefer to stay closed.",
		["copper_atlas", "brass_key", "sealwax_matrix"],
		[
			{"required_count": 1, "name": "Mapped", "modifiers": {"starting_shield": 1}},
			{"required_count": 2, "name": "Routed", "modifiers": {"cooldown_reduction_bonus": 0.25}},
			{"required_count": 3, "name": "Secured", "modifiers": {"reward_choice_bonus_count": 1}, "record_id": "relic_set_complete"},
		]
	)
	_add_relic_set(
		"lunar_trace",
		"Lunar Trace",
		"Measurements that keep the sky aligned with the archive.",
		["moon_catalog", "lunar_ribbon", "glass_lens"],
		[
			{"required_count": 1, "name": "Moonlit", "modifiers": {"reward_choice_bonus_count": 1}},
			{"required_count": 2, "name": "Aligned", "modifiers": {"cooldown_reduction_bonus": 0.25}},
			{"required_count": 3, "name": "Perfect Trace", "modifiers": {"reward_heal_bonus": 1}, "record_id": "relic_set_complete"},
		]
	)

	_add_patron_faction(
		"scholars",
		"Scholars of the Quiet Stack",
		"Archivists and researchers who care about lost texts.",
		["recover_ashen_index", "recover_gilded_ledger", "recover_vellum_mirror", "recover_black_index", "prepare_astral_catalog"],
		[
			{"threshold": 3, "name": "Trusted", "modifiers": {"reward_choice_bonus_count": 1}},
			{"threshold": 6, "name": "Preferred", "modifiers": {"cooldown_reduction_bonus": 0.25}},
			{"threshold": 10, "name": "Inner Circle", "modifiers": {"card_damage_bonus": 1}, "record_id": "faction_milestone"},
		],
		[],
		["wardens"],
		["forbidden_history", "astral_theory"]
	)
	_add_patron_faction(
		"wardens",
		"Wardens of the Measuring Seal",
		"Protective patrons who value containment and reliability.",
		["recover_copper_atlas", "stabilize_ward_primer", "reinforce_ward_shelf", "seal_ink_containment"],
		[
			{"threshold": 3, "name": "Trusted", "modifiers": {"starting_shield": 1}},
			{"threshold": 6, "name": "Preferred", "modifiers": {"reward_heal_bonus": 1}},
			{"threshold": 10, "name": "Inner Circle", "modifiers": {"bonus_vs_enemy_kind": "melee", "bonus_vs_enemy_kind_damage": 1}, "record_id": "faction_milestone"},
		],
		["scholars"],
		["fieldwardens"],
		["wardcraft", "forbidden_history"]
	)
	_add_patron_faction(
		"fieldwardens",
		"Fieldwardens of the Living Shelf",
		"Trackers who prefer bones, tracks, and living routes.",
		["catalog_wildbark_bestiary", "survey_living_trail", "echoing_paths", "bone_patrol"],
		[
			{"threshold": 3, "name": "Trusted", "modifiers": {"reward_heal_bonus": 1}},
			{"threshold": 6, "name": "Preferred", "modifiers": {"starting_shield": 1}},
			{"threshold": 10, "name": "Inner Circle", "modifiers": {"reward_choice_bonus_count": 1}, "record_id": "faction_milestone"},
		],
		["wardens"],
		[],
		["beast_lore", "astral_theory"]
	)

	_add_curse(
		"glass_shards",
		"glass_family",
		"Glass Shards",
		"Enemies bite harder, but the archive rewards the risk.",
		"Sharpness cuts both ways.",
		"Better rewards for a brittle run.",
		{"card_damage_bonus": 1},
		1,
		{},
		[],
		[],
		["quick"],
		[]
	)
	_add_curse(
		"glass_reflection",
		"glass_family",
		"Reflection Loss",
		"Cooldowns recover slower, but the archive learns faster.",
		"Harder to settle, easier to profit.",
		"Improved rewards from control play.",
		{"cooldown_reduction_bonus": -0.25},
		0,
		{"scholars": 1},
		[],
		[],
		["scholarly"],
		[]
	)
	_add_curse(
		"ink_tide",
		"ink_family",
		"Ink Tide",
		"The dive starts with less certainty and a broader reward spread.",
		"The page runs dark.",
		"Risk opens wider choices.",
		{"starting_shield": -1},
		2,
		{},
		[],
		["ink_pool"],
		["scholarly"],
		["curse_clear"]
	)
	_add_curse(
		"ink_echo",
		"ink_family",
		"Ink Echo",
		"Card recovery is noisier, but rare relics surface more often.",
		"Expect drift.",
		"More relic bias in the aftermath.",
		{"reward_heal_bonus": -1},
		0,
		{},
		[],
		[],
		["quick"],
		[]
	)
	_add_curse(
		"bone_drain",
		"bone_family",
		"Bone Drain",
		"The run opens with less shield, but the archive records the win.",
		"Hard on the body, good for the ledger.",
		"Challenges leave a memorial entry.",
		{"starting_shield": -1},
		1,
		{},
		[],
		[],
		["heavy"],
		["curse_clear"]
	)
	_add_curse(
		"bone_patience",
		"bone_family",
		"Bone Patience",
		"Longer cooldowns, steadier essence.",
		"A slower rhythm with a cleaner end.",
		"More essence after the run.",
		{"cooldown_reduction_bonus": -0.25},
		2,
		{},
		[],
		[],
		["ward"],
		[]
	)

	_add_replay_record("wing_unlock", "Wing Unlock", "Unlocked or upgraded a wing specialization.", "progression", "Wing unlocked: {wing_name}", ["wing"], ["progression"])
	_add_replay_record("relic_set_complete", "Relic Set Complete", "Completed a relic set bonus.", "collection", "Relic set complete: {set_name}", ["set"], ["archive"])
	_add_replay_record("faction_milestone", "Faction Milestone", "Reached a notable faction reputation threshold.", "reputation", "Faction milestone: {faction_name}", ["faction"], ["social"])
	_add_replay_record("curse_clear", "Curse Clear", "Cleared a dive while a curse was active.", "challenge", "Curse cleared: {curse_name}", ["curse"], ["challenge"])
	_add_replay_record("recorded_request_chain", "Request Chain", "Completed a branch of related patron requests.", "progression", "Request chain: {request_name}", ["request"], ["progression"])
	_add_replay_record("rare_archive_entry", "Rare Archive Entry", "Recorded a noteworthy archive state.", "archive", "Archive record: {summary}", ["archive"], ["archive"])

	_add_card_variant("ember_lance_echo", "Ember Lance Echo", "A sharper but shorter arc for Ember Lance.", "ember_lance", "variant", 0, -0.1, 1.0, 0.0, 0.0, 0, 0, 0.0, ["flame"], [], [])
	_add_card_variant("mirror_guard_shield", "Mirror Guard Shield", "A heavier guard that starts stronger.", "mirror_guard", "variant", 0, 0.0, 0.0, 0.0, 0.0, 1, 0, 0.0, ["ward"], [], [])
	_add_card_variant("arc_bolt_long", "Arc Bolt Longshot", "A longer shot with a cleaner opening.", "arc_bolt", "variant", 0, 0.0, 0.0, 40.0, 0.0, 0, 0, 40.0, ["bolt"], [], [])
	_add_card_variant("ward_echo_lens", "Ward Echo Lens", "A more scholarly ward that steadies insight.", "ward_echo", "variant", 0, 0.0, 0.0, 0.0, 0.0, 0, 1, 0.0, ["scholarly"], [], [])

	_add_request_template(
		"prepare_astral_catalog",
		"Prepare Astral Catalog",
		"Organize lunar observations into a usable archive packet.",
		"faction",
		"Create an aligned catalog for the scholars.",
		"The scholars respond with new favor.",
		"The archive remembers the catalog work.",
		["astral_theory"],
		["moon_catalog"],
		[],
		0,
		2,
		["astral_focus"],
		[],
		["astral_focus"],
		[],
		"scholars",
		{"faction_reputation": {"scholars": 1}}
	)
	_add_request_template(
		"reinforce_ward_shelf",
		"Reinforce Ward Shelf",
		"Rebuild the archival shelf with better seal geometry.",
		"faction",
		"Reinforce the warded shelves and keep the stacks stable.",
		"The wardens record the work.",
		"The archive remembers the reinforcement.",
		["wardcraft"],
		["copper_atlas"],
		["sealwax_matrix"],
		1,
		3,
		["ward_echo"],
		[],
		[],
		["ward_echo"],
		"wardens",
		{"faction_reputation": {"wardens": 1}}
	)
	_add_request_template(
		"survey_living_trail",
		"Survey Living Trail",
		"Mark the safer route through a shifting route of tracks and pages.",
		"faction",
		"Mark the living path for fieldwardens.",
		"The fieldwardens gain a better trail.",
		"The archive remembers the survey.",
		["beast_lore"],
		["wildbark_bestiary"],
		["bramble_horn_sample"],
		0,
		2,
		["beast_snare"],
		[],
		[],
		[],
		"fieldwardens",
		{"faction_reputation": {"fieldwardens": 1}}
	)
	_add_request_template(
		"seal_ink_containment",
		"Seal Ink Containment",
		"Close a spill of impossible ink and catalog the aftermath.",
		"curse",
		"Contain the ink before it spreads again.",
		"The archive keeps the sealed sample.",
		"The archive remembers the containment trial.",
		["forbidden_history"],
		["black_index"],
		["void_ink_vial"],
		0,
		3,
		["sigil_chart"],
		[],
		[],
		["sigil_chart"],
		"scholars",
		{"faction_reputation": {"scholars": 1}, "unlock_curse_ids": ["ink_tide"]}
	)

	_add_archive_wing(
		"wardwing_bastion",
		"Bastion Wing",
		"A ward-focused wing that turns the archive into a defended route instead of a universal upgrade pile.",
		"wardcraft",
		"wardcraft_bastion",
		{
			"station_slots": 1,
			"relic_capacity": 1,
		},
		[
			{
				"tier": 1,
				"name": "Threshold Shelves",
				"description": "Ward cards gain extra shielding and the first wing slot opens.",
				"required_essence": 1,
				"modifiers": {
					"station_slots": 1,
					"card_modifiers": [
						{"tag": "ward", "shield_bonus": 1},
					],
				},
				"unlock_card_ids": ["wardline_sigil"],
			},
			{
				"tier": 2,
				"name": "Interlocked Galleries",
				"description": "The wing starts to favor faster setup and deeper storage.",
				"required_essence": 2,
				"modifiers": {
					"relic_capacity": 1,
					"card_modifiers": [
						{"tag": "ward", "shield_bonus": 1},
						{"tag": "quick", "cooldown_bonus": -0.2},
					],
				},
				"unlock_request_ids": ["quiet_margin_relay"],
			},
			{
				"tier": 3,
				"name": "Sanctum Index",
				"description": "Defense and scholarship become the wing's default posture.",
				"required_essence": 3,
				"modifiers": {
					"station_slots": 1,
					"relic_capacity": 1,
					"card_modifiers": [
						{"tag": "defense", "shield_bonus": 1},
						{"tag": "scholarly", "cost_reduction": 1},
					],
				},
				"unlock_card_ids": ["lattice_guard"],
				"unlock_request_ids": ["quiet_margin_accord"],
			},
		],
		["wardline_sigil", "sealed_step", "lattice_guard"],
		["quiet_margin_audience", "quiet_margin_relay", "quiet_margin_accord"]
	)

	_add_relic_set(
		"sealbound_triad",
		"Sealbound Triad",
		"Three ward relics that reward disciplined placement and layered defenses.",
		["brass_key", "threaded_sigil", "ivory_mark"],
		[
			{
				"threshold": 2,
				"name": "Interlocked Protection",
				"description": "Two pieces make warded cards sturdier and less fragile to play around.",
				"modifiers": {
					"card_modifiers": [
						{"tag": "ward", "shield_bonus": 1},
						{"tag": "defense", "shield_bonus": 1},
					],
				},
				"reward_card_ids": ["wardline_sigil"],
			},
			{
				"threshold": 3,
				"name": "Sanctum Circuit",
				"description": "The complete triad converts motion and study into a tighter loop.",
				"modifiers": {
					"card_modifiers": [
						{"tag": "quick", "move_bonus": 40},
						{"tag": "scholarly", "insight_restore_bonus": 1},
					],
				},
				"reward_card_ids": ["sealed_step"],
				"unlock_request_ids": ["quiet_margin_accord"],
			},
		]
	)

	_add_patron_faction(
		"quiet_margin_conclave",
		"Quiet Margin Conclave",
		"A patron faction that values ordered shelves, sealed routes, and reversible losses.",
		["quiet_margin_audience", "quiet_margin_relay", "quiet_margin_accord"],
		[
			{
				"tier": 1,
				"name": "Audience",
				"description": "The conclave starts trusting the archive's ward work.",
				"reputation": 1,
				"reward_essence": 1,
				"unlock_card_ids": ["wardline_sigil"],
			},
			{
				"tier": 2,
				"name": "Relay",
				"description": "They begin forwarding better routes and cleaner requests.",
				"reputation": 3,
				"reward_essence": 2,
				"unlock_card_ids": ["sealed_step"],
			},
			{
				"tier": 3,
				"name": "Accord",
				"description": "The faction grants enough confidence to reshape the wing itself.",
				"reputation": 5,
				"reward_essence": 3,
				"unlock_card_ids": ["lattice_guard"],
			},
		],
		[],
		[],
		["wardcraft"]
	)

	_add_curse(
		"smudged_margin",
		"ink_burden",
		"Smudged Margin",
		"Ink thickens around the edges of a dive and blurs the safest lines.",
		"Rooms fill with cluttered pressure and slower decisions.",
		"Clearing the curse returns extra essence and a replay note.",
		{
			"archive_pressure": 1,
			"reward_essence_bonus": 2,
		},
		2,
		{"quiet_margin_conclave": 1},
		[],
		["reward"],
		["clutter", "tutorial"],
		["record_curse_clear"]
	)
	_add_curse(
		"blackout_margin",
		"ink_burden",
		"Blackout Margin",
		"The archive goes dim enough that careless dives lose the shape of a route.",
		"Optional rooms become riskier but the reward table gets heavier.",
		"Clearing the curse records a faction-friendly accomplishment.",
		{
			"hazard_density": 1,
			"rare_relic_chance": 1,
		},
		3,
		{"quiet_margin_conclave": 1},
		[],
		[],
		["story_critical"],
		["record_faction_milestone"]
	)
	_add_curse(
		"redacted_margin",
		"ink_burden",
		"Redacted Margin",
		"Whole paragraphs vanish, forcing the player to commit to a narrower plan.",
		"Card choice quality improves if the dive survives the redaction.",
		"Clearing the curse grants a record for the wing path.",
		{
			"request_delay": 2,
			"card_choice_bonus": 1,
		},
		4,
		{"quiet_margin_conclave": 1},
		["recover_black_index"],
		[],
		[],
		["record_wing_upgrade"]
	)

	_add_replay_record(
		"record_wing_upgrade",
		"Wing Upgrade",
		"Tracks the highest archive wing tier reached in a run or save.",
		"wing",
		"{wing_name} reached tier {tier}.",
		["wing_id", "tier", "wing_name"],
		["wing", "progression"]
	)
	_add_replay_record(
		"record_relic_set",
		"Relic Set Completion",
		"Tracks completion of a named relic family.",
		"relic_set",
		"{set_name} completed with {completed_relic_count}/{total_relic_count} relics.",
		["relic_set_id", "completed_relic_count", "total_relic_count", "set_name"],
		["relic", "set"]
	)
	_add_replay_record(
		"record_faction_milestone",
		"Faction Milestone",
		"Tracks a notable reputation break in a patron chain.",
		"faction",
		"{faction_name} reached reputation {reputation}.",
		["faction_id", "reputation", "faction_name"],
		["faction", "reputation"]
	)
	_add_replay_record(
		"record_curse_clear",
		"Curse Clear",
		"Tracks a successful run completed under one optional curse.",
		"curse",
		"{curse_name} was cleared on the way out.",
		["curse_id", "curse_name"],
		["curse", "clear"]
	)
	_add_replay_record(
		"record_request_chain",
		"Request Chain",
		"Tracks a completed multi-step request chain.",
		"request_chain",
		"{chain_name} finished across {step_count} steps.",
		["chain_id", "chain_name", "step_count"],
		["request", "chain"]
	)
	_add_replay_record(
		"record_rare_unlock",
		"Rare Unlock",
		"Tracks any rare content unlock granted by progression.",
		"unlock",
		"{content_name} unlocked for future runs.",
		["content_id", "content_name", "unlock_source"],
		["unlock", "rare"]
	)

	_add_request_template(
		"quiet_margin_audience_template",
		"Quiet Margin Audience",
		"A patron request template for establishing the first trust step in a faction chain.",
		"faction",
		"Deliver a ward sample and prove the archive can hold the line.",
		"The conclave pays in essence and a guarded card pattern.",
		"The archive remembers the first warding favor.",
		["wardcraft"],
		[],
		["sealwax_matrix"],
		1,
		2,
		["wardline_sigil"],
		[],
		["wardline_sigil"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}},
		["record_faction_milestone"]
	)
	_add_request_template(
		"quiet_margin_relay_template",
		"Quiet Margin Relay",
		"A patron request template for routing work through a calmer second step.",
		"faction",
		"Bring back a corridor map and the supplies to seal it.",
		"The conclave pays in essence and a faster movement pattern.",
		"The archive remembers the relay favor.",
		["wardcraft"],
		["copper_atlas"],
		["threaded_sigil"],
		1,
		2,
		["sealed_step"],
		[],
		["sealed_step"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}},
		["record_request_chain"]
	)
	_add_request_template(
		"quiet_margin_accord_template",
		"Quiet Margin Accord",
		"A patron request template for the final wing commitment in the chain.",
		"faction",
		"Return the highest-value ward relics and prove the wing can specialize.",
		"The conclave pays in essence and a final defensive card pattern.",
		"The archive remembers the accord.",
		["wardcraft"],
		["copper_atlas", "ward_primer"],
		["ivory_mark"],
		2,
		3,
		["lattice_guard"],
		[],
		["lattice_guard"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 2}},
		["record_wing_upgrade"]
	)

	_add_card_variant(
		"wardline_sigil",
		"Wardline Sigil",
		"A ward-sign variant tuned for the Bastion Wing.",
		"ward_sign",
		"wing_upgrade",
		0,
		0.0,
		0.0,
		0.0,
		0.0,
		1,
		0,
		0.0,
		["ward", "scholarly"],
		[],
		["quiet_margin_audience"],
		[]
	)
	_add_card_variant(
		"sealed_step",
		"Sealed Step",
		"A swift-step variant that trades freedom for sturdier positioning.",
		"swift_step",
		"relic_set",
		0,
		-0.1,
		0.0,
		0.0,
		40.0,
		0,
		0,
		0.0,
		["quick", "ward"],
		[],
		["quiet_margin_relay"],
		[]
	)
	_add_card_variant(
		"lattice_guard",
		"Lattice Guard",
		"A mirror-guard variant used once the faction chain reaches its final accord.",
		"mirror_guard",
		"faction_reward",
		0,
		0.0,
		0.0,
		0.0,
		0.0,
		1,
		1,
		0.0,
		["ward", "scholarly"],
		[],
		["quiet_margin_accord"],
		[]
	)
	_add_card_variant(
		"sigil_chart_prime",
		"Sigil Chart Prime",
		"A more decisive sigil chart for archive audits.",
		"sigil_chart",
		"archive_bastion",
		0,
		-0.2,
		0.0,
		0.0,
		0.0,
		0,
		1,
		0.0,
		["forbidden_history"],
		[],
		["quiet_margin_bastion"],
		[]
	)
	_add_card_variant(
		"moon_stride_lens",
		"Moon Stride Lens",
		"A quieter moon stride that carries the runner farther.",
		"moon_stride",
		"astral_branch",
		0,
		-0.2,
		0.0,
		0.0,
		40.0,
		0,
		0,
		0.0,
		["astral_theory"],
		[],
		["quiet_margin_lens"],
		[]
	)
	_add_card_variant(
		"arc_bolt_lattice",
		"Arc Bolt Lattice",
		"A structured arc bolt tuned to the ward chain.",
		"arc_bolt",
		"ward_branch",
		0,
		0.0,
		1.0,
		40.0,
		0.0,
		0,
		0,
		40.0,
		["wardcraft"],
		[],
		["quiet_margin_cloister"],
		[]
	)

	_add_request(
		"quiet_margin_audience",
		"Quiet Margin Audience",
		"ward_primer",
		"Deliver a ward sample and prove the archive can hold the line.",
		"The conclave pays in essence and a guarded card pattern.",
		"The archive remembers the first warding favor.",
		2,
		["wardcraft"],
		[],
		["sealwax_matrix"],
		0,
		2,
		["wardline_sigil"],
		[],
		["wardline_sigil"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_relay",
		"Quiet Margin Relay",
		"copper_atlas",
		"Bring back a corridor map and the supplies to seal it.",
		"The conclave pays in essence and a faster movement pattern.",
		"The archive remembers the relay favor.",
		3,
		["wardcraft"],
		["ward_primer"],
		["threaded_sigil"],
		1,
		2,
		["sealed_step"],
		[],
		["sealed_step"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_accord",
		"Quiet Margin Accord",
		"copper_atlas",
		"Return the highest-value ward relics and prove the wing can specialize.",
		"The conclave pays in essence and a final defensive card pattern.",
		"The archive remembers the accord.",
		4,
		["wardcraft"],
		["ward_primer", "copper_atlas"],
		["ivory_mark"],
		2,
		3,
		["lattice_guard"],
		[],
		["lattice_guard"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 2}, "wing_progression": {"wardwing_bastion": 2}, "unlock_wing_ids": ["wardwing_bastion"], "record_kind": "wing_unlock"}
	)
	_add_request(
		"quiet_margin_bastion",
		"Quiet Margin Bastion",
		"ward_primer",
		"Return a ward primer and a forbidden-ink sample to reinforce the archive's outer margin.",
		"The conclave pays in essence and a sharper defensive pattern.",
		"The archive remembers the bastion line.",
		4,
		["wardcraft", "forbidden_history"],
		["ward_primer"],
		["void_ink_vial"],
		1,
		3,
		["sigil_chart_prime"],
		["request_archive_cache"],
		["sigil_chart_prime"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_lens",
		"Quiet Margin Lens",
		"moon_catalog",
		"Bring a moon catalog and a star sample so the conclave can chart a safer route.",
		"The conclave pays in essence and a brighter movement pattern.",
		"The archive remembers the lens route.",
		4,
		["wardcraft", "astral_theory"],
		["copper_atlas"],
		["star_salt_shard"],
		0,
		3,
		["moon_stride_lens"],
		["request_tome_cache"],
		["moon_stride_lens"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_cloister",
		"Quiet Margin Cloister",
		"wildbark_bestiary",
		"Return the bestiary and a horn sample so the conclave can quiet the field wing.",
		"The conclave pays in essence and a steadier striking pattern.",
		"The archive remembers the cloister route.",
		4,
		["wardcraft", "beast_lore"],
		["wildbark_bestiary"],
		["bramble_horn_sample"],
		0,
		3,
		["arc_bolt_lattice"],
		["request_relic_cache"],
		["arc_bolt_lattice"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_archive",
		"Quiet Margin Archive",
		"black_index",
		"Return the black index and a vial of void ink so the conclave can audit censored holdings.",
		"The conclave pays in essence and a more disciplined archive pattern.",
		"The archive remembers the audit route.",
		5,
		["wardcraft", "forbidden_history"],
		["black_index"],
		["sealwax_matrix"],
		1,
		4,
		["sealed_step"],
		["request_archive_cache"],
		["sealed_step"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 1}, "wing_progression": {"wardwing_bastion": 1}}
	)
	_add_request(
		"quiet_margin_concord",
		"Quiet Margin Concord",
		"vellum_mirror",
		"Bring the mirror, a sealing sample, and a corridor map to close the loop on the ward chain.",
		"The conclave pays in essence and a final control pattern.",
		"The archive remembers the concord.",
		5,
		["wardcraft", "astral_theory", "forbidden_history"],
		["copper_atlas", "vellum_mirror"],
		["sealwax_matrix"],
		2,
		5,
		["lattice_guard"],
		["request_archive_cache"],
		["lattice_guard"],
		[],
		"quiet_margin_conclave",
		{"faction_reputation": {"quiet_margin_conclave": 2}, "wing_progression": {"wardwing_bastion": 2}, "unlock_wing_ids": ["wardwing_bastion"], "record_kind": "request_chain"}
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
		"quiet_margin_audience",
		"quiet_margin_relay",
		"quiet_margin_accord",
		"quiet_margin_bastion",
		"quiet_margin_lens",
		"quiet_margin_cloister",
		"quiet_margin_archive",
		"quiet_margin_concord",
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
	archive_wing_order = ["wardwing_bastion"]
	relic_set_order = ["sealbound_triad"]
	patron_faction_order = ["quiet_margin_conclave"]
	curse_order = ["smudged_margin", "blackout_margin", "redacted_margin"]
	replay_record_order = [
		"record_wing_upgrade",
		"record_relic_set",
		"record_faction_milestone",
		"record_curse_clear",
		"record_request_chain",
		"record_rare_unlock",
	]
	request_template_order = [
		"quiet_margin_audience_template",
		"quiet_margin_relay_template",
		"quiet_margin_accord_template",
	]
	card_variant_order = ["wardline_sigil", "sealed_step", "lattice_guard", "sigil_chart_prime", "moon_stride_lens", "arc_bolt_lattice"]

func _add_request(id: String, request_name: String, tome_id: String, objective_text: String, reward_text: String, archive_reward_text: String, deadline_turns: int = 0, required_knowledge_tags: Array[String] = [], required_tome_ids: Array[String] = [], required_relic_ids: Array[String] = [], required_essence: int = 0, reward_essence: int = 0, reward_card_ids: Array[String] = [], reward_room_ids: Array[String] = [], unlock_card_ids: Array[String] = [], unlock_room_ids: Array[String] = [], faction_id: String = "", progression_rewards: Dictionary = {}) -> void:
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
	request.faction_id = faction_id
	request.progression_rewards = progression_rewards
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

func _add_archive_wing(id: String, wing_name: String, description: String, focus_knowledge_tag: String, specialization_path: String, base_modifiers: Dictionary, upgrade_tiers: Array[Dictionary], unlock_card_ids: Array[String] = [], unlock_request_ids: Array[String] = []) -> void:
	var wing := ArchiveWingDefinitionClass.new()
	wing.id = id
	wing.name = wing_name
	wing.description = description
	wing.focus_knowledge_tag = focus_knowledge_tag
	wing.specialization_path = specialization_path
	wing.base_modifiers = base_modifiers
	wing.upgrade_tiers = upgrade_tiers
	wing.unlock_card_ids = unlock_card_ids
	wing.unlock_request_ids = unlock_request_ids
	archive_wings[id] = wing
	if not archive_wing_order.has(id):
		archive_wing_order.append(id)

func _add_relic_set(id: String, relic_set_name: String, description: String, relic_ids: Array[String], bonuses: Array[Dictionary]) -> void:
	var relic_set := RelicSetDefinitionClass.new()
	relic_set.id = id
	relic_set.name = relic_set_name
	relic_set.description = description
	relic_set.relic_ids = relic_ids
	relic_set.bonuses = bonuses
	relic_sets[id] = relic_set
	if not relic_set_order.has(id):
		relic_set_order.append(id)

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

func _add_patron_faction(id: String, faction_name: String, description: String, request_ids: Array[String] = [], reputation_tiers: Array[Dictionary] = [], ally_faction_ids: Array[String] = [], rival_faction_ids: Array[String] = [], tracked_tags: Array[String] = []) -> void:
	var faction := PatronFactionDefinitionClass.new()
	faction.id = id
	faction.name = faction_name
	faction.description = description
	faction.request_ids = request_ids
	faction.reputation_tiers = reputation_tiers
	faction.ally_faction_ids = ally_faction_ids
	faction.rival_faction_ids = rival_faction_ids
	faction.tracked_tags = tracked_tags
	patron_factions[id] = faction
	if not patron_faction_order.has(id):
		patron_faction_order.append(id)

func _add_curse(id: String, family: String, curse_name: String, description: String, risk_text: String, reward_text: String, modifiers: Dictionary = {}, reward_essence: int = 0, reward_reputation: Dictionary = {}, incompatible_request_ids: Array[String] = [], incompatible_room_types: Array[String] = [], incompatible_tags: Array[String] = [], reward_record_ids: Array[String] = []) -> void:
	var curse := CurseDefinitionClass.new()
	curse.id = id
	curse.family = family
	curse.name = curse_name
	curse.description = description
	curse.risk_text = risk_text
	curse.reward_text = reward_text
	curse.modifiers = modifiers
	curse.reward_essence = reward_essence
	curse.reward_reputation = reward_reputation
	curse.incompatible_request_ids = incompatible_request_ids
	curse.incompatible_room_types = incompatible_room_types
	curse.incompatible_tags = incompatible_tags
	curse.reward_record_ids = reward_record_ids
	curses[id] = curse
	if not curse_order.has(id):
		curse_order.append(id)

func _add_replay_record(id: String, record_name: String, description: String, category: String, summary_template: String, tracked_fields: Array[String] = [], display_tags: Array[String] = []) -> void:
	var record := ReplayRecordDefinitionClass.new()
	record.id = id
	record.name = record_name
	record.description = description
	record.category = category
	record.summary_template = summary_template
	record.tracked_fields = tracked_fields
	record.display_tags = display_tags
	replay_records[id] = record
	if not replay_record_order.has(id):
		replay_record_order.append(id)

func _add_request_template(id: String, template_name: String, description: String, template_kind: String, objective_text: String, reward_text: String, archive_reward_text: String, required_knowledge_tags: Array[String] = [], required_tome_ids: Array[String] = [], required_relic_ids: Array[String] = [], required_essence: int = 0, reward_essence: int = 0, reward_card_ids: Array[String] = [], reward_room_ids: Array[String] = [], unlock_card_ids: Array[String] = [], unlock_room_ids: Array[String] = [], faction_id: String = "", progression_rewards: Dictionary = {}, branch_reward_ids: Array[String] = []) -> void:
	var template := RequestTemplateDefinitionClass.new()
	template.id = id
	template.name = template_name
	template.description = description
	template.template_kind = template_kind
	template.objective_text = objective_text
	template.reward_text = reward_text
	template.archive_reward_text = archive_reward_text
	template.required_knowledge_tags = required_knowledge_tags
	template.required_tome_ids = required_tome_ids
	template.required_relic_ids = required_relic_ids
	template.required_essence = required_essence
	template.reward_essence = reward_essence
	template.reward_card_ids = reward_card_ids
	template.reward_room_ids = reward_room_ids
	template.unlock_card_ids = unlock_card_ids
	template.unlock_room_ids = unlock_room_ids
	template.faction_id = faction_id
	template.progression_rewards = progression_rewards
	template.branch_reward_ids = branch_reward_ids
	request_templates[id] = template
	if not request_template_order.has(id):
		request_template_order.append(id)

func _add_card_variant(id: String, variant_name: String, description: String, base_card_id: String, variant_kind: String, cost_delta: int = 0, cooldown_delta: float = 0.0, power_delta: float = 0.0, reach_delta: float = 0.0, move_bonus_delta: float = 0.0, shield_delta: int = 0, insight_restore_delta: int = 0, projectile_speed_delta: float = 0.0, added_tags: Array[String] = [], removed_tags: Array[String] = [], unlock_request_ids: Array[String] = [], unlock_reward_room_ids: Array[String] = []) -> void:
	var variant := CardVariantDefinitionClass.new()
	variant.id = id
	variant.name = variant_name
	variant.description = description
	variant.base_card_id = base_card_id
	variant.variant_kind = variant_kind
	variant.cost_delta = cost_delta
	variant.cooldown_delta = cooldown_delta
	variant.power_delta = power_delta
	variant.reach_delta = reach_delta
	variant.move_bonus_delta = move_bonus_delta
	variant.shield_delta = shield_delta
	variant.insight_restore_delta = insight_restore_delta
	variant.projectile_speed_delta = projectile_speed_delta
	variant.added_tags = added_tags
	variant.removed_tags = removed_tags
	variant.unlock_request_ids = unlock_request_ids
	variant.unlock_reward_room_ids = unlock_reward_room_ids
	card_variants[id] = variant
	if not card_variant_order.has(id):
		card_variant_order.append(id)

	if cards.has(id):
		return

	var base_card = get_card(base_card_id)
	if base_card == null:
		return

	var card := CardDefinitionClass.new()
	card.id = id
	card.name = variant_name
	card.description = description
	card.cost = max(0, int(base_card.cost) + cost_delta)
	card.cooldown = max(0.0, float(base_card.cooldown) + cooldown_delta)
	card.kind = base_card.kind
	card.role = base_card.role
	card.tags = base_card.tags.duplicate()
	for tag in removed_tags:
		card.tags.erase(str(tag))
	for tag in added_tags:
		var tag_text := str(tag)
		if tag_text != "" and not card.tags.has(tag_text):
			card.tags.append(tag_text)
	card.power = float(base_card.power) + power_delta
	card.reach = float(base_card.reach) + reach_delta
	card.move_bonus = float(base_card.move_bonus) + move_bonus_delta
	card.shield = max(0, int(base_card.shield) + shield_delta)
	card.insight_restore = max(0, int(base_card.insight_restore) + insight_restore_delta)
	card.projectile_speed = float(base_card.projectile_speed) + projectile_speed_delta
	card.unlock_request_ids = base_card.unlock_request_ids.duplicate()
	for request_id in unlock_request_ids:
		var request_id_text := str(request_id)
		if request_id_text != "" and not card.unlock_request_ids.has(request_id_text):
			card.unlock_request_ids.append(request_id_text)
	cards[id] = card
