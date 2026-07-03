extends Node2D
class_name DungeonRoom

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

	var spawn_index: int = 0
	for enemy_id in template.enemy_ids:
		var enemy_scene = preload("res://scenes/enemies/Enemy.tscn").instantiate()
		enemy_scene.setup(controller, controller.content_db.get_enemy(enemy_id), self, _pick_spawn_point(spawn_index))
		add_child(enemy_scene)
		spawn_index += 1

func _pick_spawn_point(spawn_index: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(room_index) * 7919 + int(room_bounds.position.x)
	var base_x := room_bounds.position.x + 200.0 + float(spawn_index) * 180.0
	var base_y := room_bounds.position.y + 180.0
	return Vector2(base_x + rng.randf_range(-40.0, 40.0), base_y + rng.randf_range(-70.0, 70.0))

func get_room_type() -> String:
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	if template == null:
		return "entrance"
	return template.room_type

func get_reward_kind() -> String:
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	if template == null:
		return ""
	return template.reward_kind

func get_hazard_kind() -> String:
	var template = controller.content_db.get_room(room_data.get("room_id", "entrance"))
	if template == null:
		return ""
	return template.hazard_kind

func is_cleared() -> bool:
	return _alive_enemy_count() == 0

func get_prompt_text() -> String:
	var room_type := get_room_type()
	if room_type == "entrance":
		return "Press Interact at the door to begin the dive."
	if room_type == "reward":
		if reward_used:
			return "The rest cache is spent. Interact to move on."
		if is_cleared():
			return "Press Interact to take a restorative pause."
		return "Defeat threats, then claim the cache."
	if room_type == "optional":
		if get_reward_kind() == "relic_cache":
			if reward_used:
				return "The relic cache is empty. Interact to move on."
			if is_cleared():
				return "Press Interact to claim the relic cache."
		if get_hazard_kind() == "ink_pool":
			if is_cleared():
				return "Press Interact to force through the ink pool."
			return "Clear the room, then force through the hazard."
		if is_cleared():
			return "Press Interact to advance."
		return "The watch chamber is still contested."
	if room_type == "tome":
		if is_cleared():
			return "Press Interact to recover the requested tome."
		return "Clear the room to reach the tome."
	if is_cleared():
		return "Press Interact to advance."
	return "Defeat threats, then use Interact to advance."

func get_stats_text() -> String:
	var room_type := get_room_type()
	var reward_state := "no"
	if room_type == "reward":
		reward_state = "yes" if not reward_used and is_cleared() else "no"
	elif room_type == "optional":
		reward_state = "yes" if not reward_used and is_cleared() else "no"
	return "%s | Enemies: %d | Reward ready: %s" % [room_type.capitalize(), _alive_enemy_count(), reward_state]

func handle_interact(player) -> Dictionary:
	if get_room_type() == "reward" and is_cleared() and not reward_used:
		reward_used = true
		var heal_amount: int = 1 + int(controller.run_state.bonus_reward_heal)
		player.heal(heal_amount)
		player.restore_insight(player.insight_max)
		return {"advance": true, "message": "A quiet rest restores resolve (+%d HP)." % heal_amount}

	if get_room_type() == "optional" and is_cleared() and not reward_used:
		reward_used = true
		if get_reward_kind() == "relic_cache":
			var seed_value: int = int(controller.run_state.run_seed) + room_index * 31
			var relic_id: String = controller.content_db.pick_relic_reward(seed_value, controller.app_state.get_archive_relics())
			controller.run_state.reward_relic_id = relic_id
			var relic_name: String = relic_id
			var relic_def = controller.content_db.get_relic(relic_id)
			if relic_def != null:
				relic_name = relic_def.name
			return {"advance": true, "message": "You uncover a relic cache: %s." % relic_name}

		if get_hazard_kind() == "ink_pool":
			player.take_damage(1)
			return {"advance": true, "message": "You force through the ink pool and lose 1 HP."}

		return {"advance": true, "message": "The chamber yields a small advantage."}

	if get_room_type() == "tome" and is_cleared():
		return {"complete": true, "message": "The tome secured archive.", "tome_id": controller.app_state.get_active_request_tome_id()}

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
