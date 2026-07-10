extends Resource
class_name CardVariantDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var base_card_id: String = ""
@export var variant_kind: String = ""
@export var cost_delta: int = 0
@export var cooldown_delta: float = 0.0
@export var power_delta: float = 0.0
@export var reach_delta: float = 0.0
@export var move_bonus_delta: float = 0.0
@export var shield_delta: int = 0
@export var insight_restore_delta: int = 0
@export var projectile_speed_delta: float = 0.0
@export var added_tags: Array[String] = []
@export var removed_tags: Array[String] = []
@export var unlock_request_ids: Array[String] = []
@export var unlock_reward_room_ids: Array[String] = []
