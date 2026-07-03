extends Resource
class_name ResearchDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var knowledge_tags: Array[String] = []
@export var tome_ids: Array[String] = []
@export var relic_ids: Array[String] = []
@export var turn_cost: int = 1
@export var essence_cost: int = 0
@export var essence_reward: int = 0
@export var reward_card_ids: Array[String] = []
@export var reward_room_ids: Array[String] = []
