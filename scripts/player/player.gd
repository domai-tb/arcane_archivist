extends Node2D
class_name PlayerCharacter

@export var base_speed: float = 180.0
@export var dash_speed: float = 420.0
@export var dash_duration: float = 0.18

var mode: String = "hub"
var deck_ids: Array = []
var hp: int = 5
var max_hp: int = 5
var shield: int = 0
var insight: int = 3
var insight_max: int = 3
var cooldowns: Dictionary = {}
var current_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(700, 420))
var input_enabled: bool = true
var invuln_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func setup_player(new_deck, new_hp: int, new_max_hp: int, new_shield: int, new_insight: int, new_mode: String) -> void:
	deck_ids = new_deck.duplicate()
	hp = new_hp
	max_hp = new_max_hp
	shield = new_shield
	insight = new_insight
	insight_max = max(new_insight, 3)
	mode = new_mode
	if mode == "dungeon":
		z_as_relative = false
		z_index = 40
	_reset_cooldowns()
	queue_redraw()

func set_bounds(bounds: Rect2) -> void:
	current_bounds = bounds

func is_alive() -> bool:
	return hp > 0

func has_card(index: int) -> bool:
	return index >= 0 and index < deck_ids.size()

func get_card_id(index: int) -> String:
	if not has_card(index):
		return ""
	return deck_ids[index]

func get_card_def(index: int):
	return ContentDB.get_card(get_card_id(index))

func is_card_ready(index: int) -> bool:
	var card = get_card_def(index)
	if card == null:
		return false
	return float(cooldowns.get(card.id, 0.0)) <= 0.0 and insight >= card.cost

func get_card_cooldown(index: int) -> float:
	var card = get_card_def(index)
	if card == null:
		return 0.0
	return float(cooldowns.get(card.id, 0.0))

func set_card_cooldown(card_id: String) -> void:
	var card = ContentDB.get_card(card_id)
	if card == null:
		return
	cooldowns[card_id] = card.cooldown

func tick_cooldowns(delta: float) -> void:
	for card_id in cooldowns.keys():
		cooldowns[card_id] = max(0.0, float(cooldowns[card_id]) - delta)
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
	if dash_timer > 0.0:
		dash_timer = max(0.0, dash_timer - delta)

func restore_insight(amount: int) -> void:
	insight = min(insight_max, insight + amount)

func gain_shield(amount: int) -> void:
	shield += amount

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func take_damage(amount: int) -> int:
	if invuln_timer > 0.0:
		return 0
	var remaining = amount
	if shield > 0:
		var absorbed = min(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0:
		hp = max(0, hp - remaining)
	queue_redraw()
	return remaining

func do_dash(direction: Vector2, strength: float) -> void:
	if direction.length() == 0.0:
		direction = Vector2.RIGHT
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	invuln_timer = max(invuln_timer, dash_duration)
	position += dash_direction * strength * 0.02

func _process(delta: float) -> void:
	tick_cooldowns(delta)
	if not input_enabled or not is_alive():
		return

	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed = base_speed
	if dash_timer > 0.0:
		speed = dash_speed
		position += dash_direction * speed * delta
	else:
		position += move_input * speed * delta

	position.x = clamp(position.x, current_bounds.position.x, current_bounds.position.x + current_bounds.size.x)
	position.y = clamp(position.y, current_bounds.position.y, current_bounds.position.y + current_bounds.size.y)
	queue_redraw()

func request_card_use(index: int) -> void:
	if not input_enabled:
		return
	if not has_card(index):
		return
	var card = get_card_def(index)
	if card == null:
		return
	if not is_card_ready(index):
		return
	if insight < card.cost:
		return
	insight -= card.cost
	set_card_cooldown(card.id)

func _reset_cooldowns() -> void:
	cooldowns = {}
	for card_id in deck_ids:
		cooldowns[card_id] = 0.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 22.0, Color(0.98, 0.99, 1.0))
	draw_circle(Vector2.ZERO, 16.0, Color(0.71, 0.80, 0.99))
	draw_circle(Vector2.ZERO, 8.0, Color(0.14, 0.18, 0.32))
	draw_line(Vector2.ZERO, Vector2(0.0, -16.0), Color(1.0, 0.94, 0.65), 3.0, true)
