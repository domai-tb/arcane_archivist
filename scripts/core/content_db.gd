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

var starter_deck: Array[String] = [
	"swift_step",
	"arc_strike",
	"ward_sign",
	"arc_bolt",
	"study_note",
]

func _ready() -> void:
	_build_content()

func get_default_request_id() -> String:
	return "recover_ashen_index"

func get_request(id: String):
	return requests.get(id)

func get_tome(id: String):
	return tomes.get(id)

func get_card(id: String):
	return cards.get(id)

func get_enemy(id: String):
	return enemies.get(id)

func get_room(id: String):
	return rooms.get(id)

func get_starter_deck() -> Array[String]:
	return starter_deck.duplicate()

func build_0_1_dungeon_layout(seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var encounter_variants: Array[String] = ["encounter_mireling", "encounter_wisp"]
	if rng.randi_range(0, 1) == 1:
		encounter_variants.reverse()

	var reward_kind := "rest_cache" if rng.randi_range(0, 1) == 0 else "reader_cache"
	return [
		{"room_id": "entrance", "role": "entrance"},
		{"room_id": encounter_variants[0], "role": "encounter"},
		{"room_id": encounter_variants[1], "role": "encounter"},
		{"room_id": "reward_room", "role": "reward", "reward_kind": reward_kind},
		{"room_id": "tome_room", "role": "tome"},
	]

func _build_content() -> void:
	if not cards.is_empty():
		return

	_add_request("recover_ashen_index", "Recover the Ashen Index", "ashen_index", "Find the tome hidden below the library.", "A patron reward of essence and trust.", "The archive remembers the Ashen Index.")
	_add_tome("ashen_index", "Ashen Index", "A soot-stained index of borrowed whispers.")
	_add_relic("glass_lens", "Dormant Glass Lens", "A dormant lens that will matter in later versions.", "No active effect in 0.1.")

	_add_card("swift_step", "Swift Step", "Dash a short distance.", 1, 1.5, "dash", 0.0, 0.0, 180.0, 0, 0, 0.0)
	_add_card("arc_strike", "Arc Strike", "Hit the nearest foe for solid damage.", 1, 2.2, "strike", 2.0, 170.0, 0.0, 0, 0, 0.0)
	_add_card("ward_sign", "Ward Sign", "Gain shielding for the next hit.", 1, 3.0, "ward", 0.0, 0.0, 0.0, 2, 0, 0.0)
	_add_card("arc_bolt", "Arc Bolt", "Fire a bolt at a distant enemy.", 1, 2.5, "bolt", 2.0, 300.0, 0.0, 0, 0, 620.0)
	_add_card("study_note", "Study Note", "Restore insight and steady the pace.", 0, 4.0, "study", 0.0, 0.0, 0.0, 0, 1, 0.0)

	_add_enemy("mireling", "Mireling", "A small chaser that keeps moving.", 3, 55.0, 1, 24.0, 1.0, "melee", 0.0)
	_add_enemy("scribal_wisp", "Scribal Wisp", "A shy ranged threat from the stacks.", 2, 40.0, 1, 170.0, 1.4, "ranged", 280.0)

	_add_room("entrance", "Entrance", "entrance", [], "", "")
	_add_room("encounter_mireling", "Echoing Stacks", "encounter", ["mireling"], "", "")
	_add_room("encounter_wisp", "Quiet Annex", "encounter", ["scribal_wisp"], "ink_pool", "")
	_add_room("reward_room", "Study Cache", "reward", [], "", "rest")
	_add_room("tome_room", "Sealed Archive", "tome", [], "", "tome")

func _add_card(id: String, name: String, description: String, cost: int, cooldown: float, kind: String, damage: float, card_range: float, move_bonus: float, shield: int, insight_restore: int, projectile_speed: float) -> void:
	var card := CardDefinitionClass.new()
	card.id = id
	card.name = name
	card.description = description
	card.cost = cost
	card.cooldown = cooldown
	card.kind = kind
	card.power = damage
	card.range = card_range
	card.move_bonus = move_bonus
	card.shield = shield
	card.insight_restore = insight_restore
	card.projectile_speed = projectile_speed
	cards[id] = card

func _add_enemy(id: String, name: String, description: String, max_hp: int, move_speed: float, damage: int, attack_range: float, attack_cooldown: float, kind: String, projectile_speed: float) -> void:
	var enemy := EnemyDefinitionClass.new()
	enemy.id = id
	enemy.name = name
	enemy.description = description
	enemy.max_hp = max_hp
	enemy.move_speed = move_speed
	enemy.damage = damage
	enemy.attack_range = attack_range
	enemy.attack_cooldown = attack_cooldown
	enemy.kind = kind
	enemy.projectile_speed = projectile_speed
	enemies[id] = enemy

func _add_request(id: String, name: String, tome_id: String, objective_text: String, reward_text: String, archive_reward_text: String) -> void:
	var request := RequestDefinitionClass.new()
	request.id = id
	request.name = name
	request.tome_id = tome_id
	request.objective_text = objective_text
	request.reward_text = reward_text
	request.archive_reward_text = archive_reward_text
	requests[id] = request

func _add_tome(id: String, name: String, description: String) -> void:
	var tome := TomeDefinitionClass.new()
	tome.id = id
	tome.name = name
	tome.description = description
	tomes[id] = tome

func _add_relic(id: String, name: String, description: String, dormant_note: String) -> void:
	var relic := RelicDefinitionClass.new()
	relic.id = id
	relic.name = name
	relic.description = description
	relic.dormant_note = dormant_note
	relics[id] = relic

func _add_room(id: String, name: String, room_type: String, enemy_ids: Array[String], hazard_kind: String, reward_kind: String) -> void:
	var room := RoomTemplateDefinitionClass.new()
	room.id = id
	room.name = name
	room.room_type = room_type
	room.enemy_ids = enemy_ids
	room.hazard_kind = hazard_kind
	room.reward_kind = reward_kind
	rooms[id] = room
