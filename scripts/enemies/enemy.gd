extends Node2D
class_name DungeonEnemy

var controller = null
var definition = null
var room = null
var hp: int = 1
var attack_timer: float = 0.0
var dead: bool = false
var spawn_position: Vector2 = Vector2.ZERO

func setup(new_controller, new_definition, new_room, new_spawn_position: Vector2) -> void:
	controller = new_controller
	definition = new_definition
	room = new_room
	spawn_position = new_spawn_position
	position = spawn_position
	z_as_relative = false
	z_index = 30
	hp = definition.max_hp if definition != null else 1
	queue_redraw()

func is_alive() -> bool:
	return not dead and hp > 0

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	if hp <= 0:
		dead = true
		queue_redraw()
		queue_free()
	else:
		queue_redraw()

func _process(delta: float) -> void:
	if not is_alive() or controller == null:
		return
	var player = controller.player
	if player == null or not player.is_alive():
		return
	# Only the active room may engage the player. Enemies in later rooms
	# remain dormant until the run advances into their encounter.
	if controller.has_method("_get_current_room") and room != controller._get_current_room():
		return

	attack_timer = max(0.0, attack_timer - delta)
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	if definition.kind == "ranged":
		var desired_distance = definition.attack_range * 0.8
		if distance > desired_distance:
			position += to_player.normalized() * definition.move_speed * delta
		elif distance < desired_distance * 0.6:
			position -= to_player.normalized() * definition.move_speed * delta
		if attack_timer <= 0.0 and distance <= definition.attack_range:
			player.take_damage(definition.damage)
			attack_timer = definition.attack_cooldown
	else:
		if distance > definition.attack_range:
			position += to_player.normalized() * definition.move_speed * delta
		if attack_timer <= 0.0 and distance <= definition.attack_range:
			player.take_damage(definition.damage)
			attack_timer = definition.attack_cooldown

func _draw() -> void:
	if not is_alive():
		return
	var body_color = Color(0.96, 0.52, 0.26) if definition != null and definition.kind == "melee" else Color(0.34, 0.78, 1.0)
	draw_circle(Vector2.ZERO, 20.0, Color(0.1, 0.08, 0.12))
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_circle(Vector2.ZERO, 7.0, Color(0.06, 0.06, 0.08))
	draw_line(Vector2(-10.0, 0.0), Vector2(10.0, 0.0), Color(1.0, 0.96, 0.8), 2.0, true)
