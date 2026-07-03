extends RefCounted
class_name RunState

var request_id: String = ""
var run_seed: int = 0
var room_sequence: Array = []
var current_room_index: int = 0
var player_hp: int = 5
var player_max_hp: int = 5
var shield: int = 0
var insight: int = 3
var tome_acquired: bool = false
var completed: bool = false
var failed: bool = false
var deck_ids: Array[String] = []
var cooldowns: Dictionary = {}
var room_cleared: bool = false
var bonus_shield: int = 0
var bonus_damage: int = 0
var bonus_cooldown_reduction: float = 0.0
var bonus_reward_heal: int = 0
var bonus_vs_enemy_kind: String = ""
var bonus_vs_enemy_kind_damage: int = 0
var reward_relic_id: String = ""
var reward_choice_bonus_count: int = 0
var active_bonuses: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {
		"request_id": request_id,
		"seed": run_seed,
		"room_sequence": room_sequence,
		"current_room_index": current_room_index,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"shield": shield,
		"insight": insight,
		"tome_acquired": tome_acquired,
		"completed": completed,
		"failed": failed,
		"deck_ids": deck_ids,
		"cooldowns": cooldowns,
		"room_cleared": room_cleared,
		"bonus_shield": bonus_shield,
		"bonus_damage": bonus_damage,
		"bonus_cooldown_reduction": bonus_cooldown_reduction,
		"bonus_reward_heal": bonus_reward_heal,
		"bonus_vs_enemy_kind": bonus_vs_enemy_kind,
		"bonus_vs_enemy_kind_damage": bonus_vs_enemy_kind_damage,
		"reward_relic_id": reward_relic_id,
		"reward_choice_bonus_count": reward_choice_bonus_count,
		"active_bonuses": active_bonuses,
	}

func from_dict(data: Dictionary) -> void:
	request_id = data.get("request_id", "")
	run_seed = int(data.get("seed", 0))
	room_sequence = data.get("room_sequence", [])
	current_room_index = int(data.get("current_room_index", 0))
	player_hp = int(data.get("player_hp", 5))
	player_max_hp = int(data.get("player_max_hp", 5))
	shield = int(data.get("shield", 0))
	insight = int(data.get("insight", 3))
	tome_acquired = bool(data.get("tome_acquired", false))
	completed = bool(data.get("completed", false))
	failed = bool(data.get("failed", false))
	deck_ids = data.get("deck_ids", [])
	cooldowns = data.get("cooldowns", {})
	room_cleared = bool(data.get("room_cleared", false))
	bonus_shield = int(data.get("bonus_shield", 0))
	bonus_damage = int(data.get("bonus_damage", 0))
	bonus_cooldown_reduction = float(data.get("bonus_cooldown_reduction", 0.0))
	bonus_reward_heal = int(data.get("bonus_reward_heal", 0))
	bonus_vs_enemy_kind = str(data.get("bonus_vs_enemy_kind", ""))
	bonus_vs_enemy_kind_damage = int(data.get("bonus_vs_enemy_kind_damage", 0))
	reward_relic_id = str(data.get("reward_relic_id", ""))
	reward_choice_bonus_count = int(data.get("reward_choice_bonus_count", 0))
	active_bonuses = data.get("active_bonuses", [])
