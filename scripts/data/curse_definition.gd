extends Resource
class_name CurseDefinition

@export var id: String = ""
@export var family: String = ""
@export var name: String = ""
@export var description: String = ""
@export var risk_text: String = ""
@export var reward_text: String = ""
@export var modifiers: Dictionary = {}
@export var reward_essence: int = 0
@export var reward_reputation: Dictionary = {}
@export var incompatible_request_ids: Array[String] = []
@export var incompatible_room_types: Array[String] = []
@export var incompatible_tags: Array[String] = []
@export var reward_record_ids: Array[String] = []
