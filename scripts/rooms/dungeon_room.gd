extends Node2D
class_name DungeonRoom

signal room_cleared(room_index: int)

var controller = null
var room_data: Dictionary = {}
var room_index: int = 0
var room_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(720, 420))
var hazard_timer: float = 0.0
var has_spawned: bool = false
var cleared: bool = false
var reward_used: bool = false
var room_title: String = ""

func setup(new_controller, new_room_data: Dictionary, new_index: int, new_origin: Vector2) -> void:
	controller = new_controller
	room_data = new_room_data
	room_index = new_index
	room_bounds = Rect2(new_origin, Vector2(720, 420))
	position = new_origin
	if is_inside_tree():
		_build_room()

func _ready() -> void:
	if room_data.is_empty():
		return
	_build_room()

func _build_room() -> void:
	if has_spawned:
		return
	has_spawned = true
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	room_title = template.name if template != null else "Entrance"
	_spawn_contents()
	queue_redraw()

func _spawn_contents() -> void:
	if controller == null:
		return
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	if template == null:
		return
	for enemy_id in template.enemy_ids:
		var enemy_scene = preload("res://scenes/enemies/Enemy.tscn").instantiate()
		enemy_scene.setup(controller, controller.content_db.get_enemy(enemy_id), self, _pick_spawn_point())
		add_child(enemy_scene)

func _pick_spawn_point() -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(room_index) * 7919 + int(room_bounds.position.x)
	var offset_x = rng.randi_range(120, 580)
	var offset_y = rng.randi_range(110, 300)
	return room_bounds.position + Vector2(offset_x, offset_y)

func get_room_type() -> String:
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	if template == null:
		return "entrance"
	return template.room_type

func is_cleared() -> bool:
	if cleared:
		return true
	for enemy in get_children():
		if enemy.has_method("is_alive") and enemy.is_alive():
			return false
	cleared = true
	room_cleared.emit(room_index)
	return true

func get_prompt_text() -> String:
	var room_type = get_room_type()
	if room_type == "entrance":
		return "Press Interact at the door to begin the dive."
	if room_type == "reward":
		return "Clear the room, then use Interact to recover insight and HP."
	if room_type == "tome":
		if is_cleared():
			return "Press Interact to recover the requested tome."
		return "Clear the room to reach the tome."
	return "Defeat the threats, then use Interact to advance."

func get_stats_text() -> String:
	var room_type = get_room_type()
	return "%s | Enemies: %d | Reward ready: %s" % [room_type.capitalize(), _alive_enemy_count(), "yes" if room_type == "reward" and not reward_used else "no"]

func handle_interact(player) -> Dictionary:
	if get_room_type() == "reward" and is_cleared() and not reward_used:
		reward_used = true
		player.heal(1)
		player.restore_insight(player.insight_max)
		return {"advance": true, "message": "A quiet rest restores your resolve."}

	if get_room_type() == "tome" and is_cleared():
		return {"complete": true, "message": "The tome is secured for the archive.", "tome_id": controller.app_state.get_active_request_tome_id()}

	if is_cleared():
		return {"advance": true, "message": "The path forward opens."}

	return {"message": "The room is still contested."}

func get_exit_zone() -> Rect2:
	return Rect2(room_bounds.position + Vector2(room_bounds.size.x - 72.0, 170.0), Vector2(68.0, 90.0))

func _alive_enemy_count() -> int:
	var count := 0
	for enemy in get_children():
		if enemy.has_method("is_alive") and enemy.is_alive():
			count += 1
	return count

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, room_bounds.size), Color(0.13, 0.12, 0.16), true)
	draw_rect(Rect2(Vector2.ZERO, room_bounds.size), Color(0.45, 0.4, 0.28), false, 2.0)
	draw_rect(Rect2(room_bounds.size.x - 72.0, 170.0, 68.0, 90.0), Color(0.2, 0.18, 0.28), true)
	draw_rect(Rect2(room_bounds.size.x - 72.0, 170.0, 68.0, 90.0), Color(0.7, 0.62, 0.35), false, 2.0)
