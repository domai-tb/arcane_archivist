extends Node

const CardDefinitionClass := preload("res://scripts/data/card_definition.gd")
const EnemyDefinitionClass := preload("res://scripts/data/enemy_definition.gd")
const RequestDefinitionClass := preload("res://scripts/data/request_definition.gd")
const TomeDefinitionClass := preload("res://scripts/data/tome_definition.gd")
const RelicDefinitionClass := preload("res://scripts/data/relic_definition.gd")
const RoomTemplateDefinitionClass := preload("res://scripts/data/room_template_definition.gd")

var cards: Dictionary = {}
var enemies: Dictionary = {}
var requests: Dictionary = {}
var tomes: Dictionary = {}
var relics: Dictionary = {}
var rooms: Dictionary = {}
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

func _build_content() -> void:
	if not cards.is_empty():
		return

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

	_add_tome("ashen_index", "Ashen Index", "A soot-stained index of half-forgotten whispers.")
	_add_tome("gilded_ledger", "Gilded Ledger", "A ledger that keeps accounts the way curses do.")
	_add_tome("moon_catalog", "Moon Catalog", "A catalog of lunar movements and tidal annotations.")

	_add_relic("glass_lens", "Dormant Glass Lens", "A dormant lens that sharpens the hand that holds it.", "No active effect until paired.")
	_add_relic("ember_coil", "Ember Coil", "A coil that carries a tiny, stubborn heat.", "No active effect until paired.")
	_add_relic("threaded_sigil", "Threaded Sigil", "A sigil stitched into a thin silver mesh.", "No active effect until paired.")
	_add_relic("ivory_mark", "Ivory Mark", "A marker engraved with a watcher’s mark.", "No active effect until paired.")
	_add_relic("mothbone_charm", "Mothbone Charm", "A charm that hums in the presence of old paper.", "No active effect until paired.")

	relic_reward_pool = ["glass_lens", "ember_coil", "threaded_sigil", "ivory_mark", "mothbone_charm"]

	_add_archive_bonus(
		"ashen_lens_guard",
		"Ashen Lens Guard",
		"Place Ashen Index beside Dormant Glass Lens to start the next dive with 2 extra shield.",
		"ashen_index",
		"glass_lens",
		{"starting_shield": 2}
	)
	_add_archive_bonus(
		"ledger_coil_focus",
		"Ledger Coil Focus",
		"Place Gilded Ledger beside Ember Coil to increase all card damage by 1.",
		"gilded_ledger",
		"ember_coil",
		{"card_damage_bonus": 1}
	)
	_add_archive_bonus(
		"moon_sigil_rhythm",
		"Moon Sigil Rhythm",
		"Place Moon Catalog beside Threaded Sigil to reduce cooldowns more efficiently.",
		"moon_catalog",
		"threaded_sigil",
		{"cooldown_reduction_bonus": 0.5}
	)

	_add_card("swift_step", "Swift Step", "Dash short distance.", 1, 1.5, "dash", 0.0, 0.0, 180.0, 0, 0, 0.0)
	_add_card("arc_strike", "Arc Strike", "Hit the nearest foe for solid damage.", 1, 2.2, "strike", 2.0, 170.0, 0.0, 0, 0, 0.0)
	_add_card("ward_sign", "Ward Sign", "Gain shielding against the next hits.", 1, 3.0, "ward", 0.0, 0.0, 0.0, 2, 0, 0.0)
	_add_card("arc_bolt", "Arc Bolt", "Fire a bolt at a distant enemy.", 1, 2.5, "bolt", 2.0, 300.0, 0.0, 0, 0, 620.0)
	_add_card("study_note", "Study Note", "Restore insight on a slower cadence.", 0, 4.0, "study", 0.0, 0.0, 0.0, 0, 1, 0.0)

	_add_enemy("mireling", "Mireling", "A small chaser that keeps moving.", 3, 55.0, 1, 24.0, 1.0, "melee", 0.0)
	_add_enemy("scribal_wisp", "Scribal Wisp", "A shy ranged threat that hovers back.", 2, 40.0, 1, 170.0, 1.4, "ranged", 280.0)

	_add_room("entrance", "Entrance", "entrance", [], "", "")
	_add_room("encounter_mireling", "Echoing Stacks", "encounter", ["mireling"], "", "")
	_add_room("encounter_wisp", "Quiet Annex", "encounter", ["scribal_wisp"], "ink_pool", "")
	_add_room("reward_room", "Study Cache", "reward", [], "", "rest")
	_add_room("tome_room", "Sealed Archive", "tome", [], "", "tome")
	_add_room("optional_cache", "Whisper Cache", "optional", [], "", "relic_cache")
	_add_room("optional_hazard", "Ink Pool", "optional", [], "ink_pool", "")
	_add_room("optional_guard", "Watch Chamber", "optional", ["mireling", "scribal_wisp"], "", "")

	request_order = ["recover_ashen_index", "recover_gilded_ledger", "recover_moon_catalog"]

func _add_request(id: String, request_name: String, tome_id: String, objective_text: String, reward_text: String, archive_reward_text: String) -> void:
	var request := RequestDefinitionClass.new()
	request.id = id
	request.name = request_name
	request.tome_id = tome_id
	request.objective_text = objective_text
	request.reward_text = reward_text
	request.archive_reward_text = archive_reward_text
	requests[id] = request

func _add_tome(id: String, tome_name: String, description: String) -> void:
	var tome := TomeDefinitionClass.new()
	tome.id = id
	tome.name = tome_name
	tome.description = description
	tomes[id] = tome

func _add_relic(id: String, relic_name: String, description: String, dormant_note: String) -> void:
	var relic := RelicDefinitionClass.new()
	relic.id = id
	relic.name = relic_name
	relic.description = description
	relic.dormant_note = dormant_note
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

func _add_card(id: String, card_name: String, description: String, cost: int, cooldown: float, kind: String, damage: float, card_reach: float, move_bonus: float, shield: int, insight_restore: int, projectile_speed: float) -> void:
	var card := CardDefinitionClass.new()
	card.id = id
	card.name = card_name
	card.description = description
	card.cost = cost
	card.cooldown = cooldown
	card.kind = kind
	card.power = damage
	card.reach = card_reach
	card.move_bonus = move_bonus
	card.shield = shield
	card.insight_restore = insight_restore
	card.projectile_speed = projectile_speed
	cards[id] = card

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
