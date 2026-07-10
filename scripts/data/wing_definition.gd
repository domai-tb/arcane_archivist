extends Resource
class_name WingDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var knowledge_tags: Array[String] = []
@export var unlock_cost: int = 0
@export var max_tier: int = 3
@export var upgrade_tiers: Array[Dictionary] = []
