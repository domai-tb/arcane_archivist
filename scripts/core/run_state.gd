extends RefCounted
class_name RunState

var request_id: String = ""
var seed: int = 0
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

func to_dict() -> Dictionary:
	return {
		"request_id": request_id,
		"seed": seed,
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
	}

func from_dict(data: Dictionary) -> void:
	request_id = data.get("request_id", "")
	seed = int(data.get("seed", 0))
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
