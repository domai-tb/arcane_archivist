extends Node2D
class_name DungeonRun

signal run_finished(success: bool, tome_id: String)

var app_state = null
var content_db = null
var run_state = null
var player = null
var camera = null
var hud = null
var rooms: Array = []
var current_room_index: int = 0
var room_stride: float = 820.0

func setup(new_app_state, new_content_db, new_run_state) -> void:
	app_state = new_app_state
	content_db = new_content_db
	run_state = new_run_state

func _ready() -> void:
	if app_state == null:
		return
	_build_scene()

func _build_scene() -> void:
	_generate_rooms()
	current_room_index = 0

	player = preload("res://scenes/player/Player.tscn").instantiate()
	player.setup_player(
		run_state.deck_ids,
		run_state.player_hp,
		run_state.player_max_hp,
		run_state.shield,
		run_state.insight,
		"dungeon"
	)
	player.z_as_relative = false
	player.z_index = 40
	add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(0.72, 0.72)
	camera.offset = Vector2(0.0, -24.0)
	player.add_child(camera)
	camera.call_deferred("make_current")

	hud = preload("res://scenes/ui/DiveHud.tscn").instantiate()
	add_child(hud)
	hud.setup(player)
	hud.card_selected.connect(_on_card_selected)
	hud.set_active_bonuses_text(app_state.get_active_archive_bonus_text())

	_sync_player_to_room(0)
	_refresh_hud("The dive begins.")

func _generate_rooms() -> void:
	for child in rooms:
		if is_instance_valid(child):
			child.queue_free()
	rooms.clear()

	var sequence: Array = run_state.room_sequence
	for index in range(sequence.size()):
		var room_scene = preload("res://scenes/rooms/DungeonRoom.tscn").instantiate()
		var data: Dictionary = sequence[index]
		var origin := Vector2(index * room_stride, 120.0)
		room_scene.setup(self, data, index, origin)
		room_scene.z_as_relative = false
		room_scene.z_index = 0
		add_child(room_scene)
		rooms.append(room_scene)

func _process(_delta: float) -> void:
	if player == null or run_state == null:
		return

	var room = _get_current_room()
	if room == null:
		return

	player.set_bounds(room.room_bounds)
	if room.is_cleared():
		run_state.room_cleared = true

	if hud != null:
		hud.set_room_title(room.room_title)
		hud.set_stats_text(room.get_stats_text())
		hud.set_prompt_text(room.get_prompt_text())
		hud.set_active_bonuses_text(app_state.get_active_archive_bonus_text())

func _unhandled_input(event: InputEvent) -> void:
	if player == null or run_state == null:
		return

	if event.is_action_pressed("ui_cancel"):
		_finish_run(false, "")
		return

	if event.is_action_pressed("interact"):
		_handle_interact()
		return

	for i in range(5):
		if event.is_action_pressed("card_%d" % (i + 1)):
			_on_card_selected(i)
			return

func _handle_interact() -> void:
	var current_room = _get_current_room()
	if current_room == null:
		return

	var result: Dictionary = current_room.handle_interact(player)
	if result.get("message", "") != "":
		_refresh_hud(result["message"])

	if result.get("complete", false):
		run_state.tome_acquired = true
		_finish_run(true, result.get("tome_id", ""))
		return

	if result.get("advance", false):
		_advance_room()

func _advance_room() -> void:
	var next_index: int = current_room_index + 1
	if next_index >= rooms.size():
		_finish_run(true, app_state.get_active_request_tome_id())
		return

	current_room_index = next_index
	_sync_player_to_room(current_room_index)
	player.restore_insight(player.insight_max)
	_refresh_hud("You move deeper below.")

func _sync_player_to_room(room_index: int) -> void:
	var room = _get_room(room_index)
	if room == null:
		return
	player.position = room.room_bounds.position + Vector2(120.0, 210.0)
	player.set_bounds(room.room_bounds)

func _get_room(index: int):
	if index < 0 or index >= rooms.size():
		return null
	return rooms[index]

func _get_current_room():
	return _get_room(current_room_index)

func _on_card_selected(index: int) -> void:
	if player == null or not player.has_card(index):
		return

	var card = player.get_card_def(index)
	if card == null:
		return

	if not player.is_card_ready(index):
		_refresh_hud("%s is not ready." % card.name)
		return

	if card.kind == "dash":
		player.do_dash(_movement_direction(), card.move_bonus)
	elif card.kind == "strike":
		_damage_nearest_enemy(card.power, card.reach)
	elif card.kind == "ward":
		player.gain_shield(card.shield)
	elif card.kind == "bolt":
		_damage_nearest_enemy(card.power, card.reach)
	elif card.kind == "study":
		player.restore_insight(card.insight_restore)

	_reduce_cooldowns(0.5)
	player.insight = max(0, player.insight - card.cost)
	player.set_card_cooldown(card.id)
	_refresh_hud("%s cast." % card.name)

func _movement_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _damage_nearest_enemy(amount: float, range_limit: float) -> void:
	var room = _get_current_room()
	if room == null:
		return

	var nearest_enemy = null
	var nearest_distance: float = range_limit
	for enemy in room.get_children():
		if not enemy.has_method("is_alive"):
			continue
		if not enemy.is_alive():
			continue
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist <= nearest_distance:
			nearest_distance = dist
			nearest_enemy = enemy

	if nearest_enemy != null:
		var final_damage: int = int(amount) + int(run_state.bonus_damage)
		var enemy_def = nearest_enemy.definition
		if enemy_def != null and run_state.bonus_vs_enemy_kind != "" and enemy_def.kind == run_state.bonus_vs_enemy_kind:
			final_damage += run_state.bonus_vs_enemy_kind_damage
		nearest_enemy.take_damage(final_damage)
		if room.is_cleared():
			_refresh_hud("The room quiets as the last threat falls.")

func _reduce_cooldowns(amount: float) -> void:
	var cooldown_delta: float = amount + float(run_state.bonus_cooldown_reduction)
	for card_id in player.cooldowns.keys():
		player.cooldowns[card_id] = max(0.0, float(player.cooldowns[card_id]) - cooldown_delta)

func _refresh_hud(message: String) -> void:
	if hud == null:
		return

	var room = _get_current_room()
	if room != null:
		hud.set_room_title(room.room_title)
		hud.set_stats_text(room.get_stats_text())
		hud.set_prompt_text(room.get_prompt_text())
	else:
		hud.set_room_title("Dungeon Dive")
		hud.set_stats_text("")
		hud.set_prompt_text("")
	hud.set_message(message)
	hud.set_active_bonuses_text(app_state.get_active_archive_bonus_text())

func _finish_run(success: bool, tome_id: String) -> void:
	run_finished.emit(success, tome_id)
	queue_free()
