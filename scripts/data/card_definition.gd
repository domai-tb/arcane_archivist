extends Resource
class_name CardDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var cost: int = 1
@export var cooldown: float = 1.0
@export var kind: String = ""
@export var role: String = ""
@export var tags: Array[String] = []
@export var power: float = 0.0
@export var reach: float = 0.0
@export var move_bonus: float = 0.0
@export var shield: int = 0
@export var insight_restore: int = 0
@export var projectile_speed: float = 0.0
@export var unlock_request_ids: Array[String] = []
