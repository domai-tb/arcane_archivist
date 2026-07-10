extends Resource
class_name RequestTemplateDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var template_kind: String = ""
@export var objective_text: String = ""
@export var reward_text: String = ""
@export var archive_reward_text: String = ""
@export var required_knowledge_tags: Array[String] = []
@export var required_tome_ids: Array[String] = []
@export var required_relic_ids: Array[String] = []
@export var required_essence: int = 0
@export var reward_essence: int = 0
@export var reward_card_ids: Array[String] = []
@export var reward_room_ids: Array[String] = []
@export var unlock_card_ids: Array[String] = []
@export var unlock_room_ids: Array[String] = []
@export var branch_reward_ids: Array[String] = []
@export var faction_id: String = ""
@export var progression_rewards: Dictionary = {}
