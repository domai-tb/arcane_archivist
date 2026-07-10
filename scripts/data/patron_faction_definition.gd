extends Resource
class_name PatronFactionDefinition

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var request_ids: Array[String] = []
@export var reputation_tiers: Array[Dictionary] = []
@export var ally_faction_ids: Array[String] = []
@export var rival_faction_ids: Array[String] = []
@export var tracked_tags: Array[String] = []
