extends Resource
class_name ArchiveWingDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var focus_knowledge_tag: String = ""
@export var specialization_path: String = ""
@export var base_modifiers: Dictionary = {}
@export var upgrade_tiers: Array[Dictionary] = []
@export var unlock_card_ids: Array[String] = []
@export var unlock_request_ids: Array[String] = []
@export var unlocked_by_default: bool = false
