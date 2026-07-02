extends Node2D
class_name LibraryHub

signal start_dive_requested(request_id: String)

var app_state = null
var content_db = null
var player = null
var hud = null
var interactables: Array = []

func setup(new_app_state, new_content_db) -> void:
	app_state = new_app_state
	content_db = new_content_db
	if is_inside_tree():
		_build_scene()

func _ready() -> void:
	if app_state == null:
		return
	_build_scene()

func _build_scene() -> void:
	_clear_existing()
	_build_player()
	_build_interactables()
	_build_hud()
	_refresh_ui()
	queue_redraw()

func _clear_existing() -> void:
	for child in get_children():
		child.queue_free()
	interactables.clear()

func _build_player() -> void:
	player = preload("res://scenes/player/Player.tscn").instantiate()
	player.setup_player([], 5, 5, 0, 0, "hub")
	player.position = Vector2(300, 230)
	add_child(player)

func _build_interactables() -> void:
	var desk = preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	desk.kind = "request_desk"
	desk.display_name = "Request Desk"
	desk.body_text = "Review the active patron request."
	desk.accent_color = Color(0.75, 0.64, 0.4)
	desk.position = Vector2(155, 165)
	add_child(desk)
	interactables.append(desk)

	var shelf = preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	shelf.kind = "archive_shelf"
	shelf.display_name = "Archive Shelf"
	shelf.body_text = "Check which tome is archived."
	shelf.accent_color = Color(0.42, 0.58, 0.74)
	shelf.position = Vector2(360, 150)
	add_child(shelf)
	interactables.append(shelf)

	var entrance = preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	entrance.kind = "dungeon_entrance"
	entrance.display_name = "Dungeon Entrance"
	entrance.body_text = "Begin the current dive."
	entrance.accent_color = Color(0.58, 0.38, 0.7)
	entrance.position = Vector2(570, 230)
	add_child(entrance)
	interactables.append(entrance)

func _build_hud() -> void:
	hud = preload("res://scenes/ui/HubHud.tscn").instantiate()
	add_child(hud)

func _process(_delta: float) -> void:
	if player == null or hud == null:
		return

	var focused = _get_focused_interactable()
	if focused == null:
		hud.set_prompt_text("Move near a desk, shelf, or entrance. Press Interact to inspect or begin.")
	else:
		hud.set_prompt_text("Interact with %s" % focused.display_name)

	if Input.is_action_just_pressed("interact") and focused != null:
		_handle_interaction(focused)
	if Input.is_action_just_pressed("ui_cancel") and hud.detail_panel.visible:
		hud.hide_detail()

func _handle_interaction(focused) -> void:
	if focused.kind == "request_desk":
		var request = app_state.get_active_request()
		if request != null:
			hud.show_detail(request.name, "%s\n\nReward: %s" % [request.objective_text, request.reward_text])
			hud.set_request_text("Request: %s\n%s" % [request.name, request.objective_text])
		else:
			hud.show_detail("No Request", "The patron desk is quiet.")
	elif focused.kind == "archive_shelf":
		var archive_text = _build_archive_text()
		hud.show_detail("Archive Shelf", archive_text)
		hud.set_archive_text(archive_text)
	elif focused.kind == "dungeon_entrance":
		if app_state.is_request_completed(app_state.get_active_request_id()):
			hud.show_detail("Archive Complete", "The request is already complete. The archive is safe.")
		else:
			hud.show_detail("Begin Dive", "A short descent will search for the requested tome.")
			start_dive_requested.emit(app_state.get_active_request_id())

func _get_focused_interactable():
	var nearest = null
	var nearest_distance := 9999.0
	for interactable in interactables:
		var distance = player.global_position.distance_to(interactable.global_position)
		if distance < 74.0 and distance < nearest_distance:
			nearest = interactable
			nearest_distance = distance
	return nearest

func _refresh_ui() -> void:
	var request = app_state.get_active_request()
	if request != null:
		hud.set_request_text("Request: %s\n%s" % [request.name, request.objective_text])
	else:
		hud.set_request_text("No active request.")
	hud.set_archive_text(_build_archive_text())

func _build_archive_text() -> String:
	var tomes = app_state.get_archive_tomes()
	if tomes.is_empty():
		return "Archive: empty. The shelves are waiting."
	var labels: Array[String] = []
	for tome_id in tomes:
		var tome = content_db.get_tome(tome_id)
		if tome != null:
			labels.append(tome.name)
		else:
			labels.append(tome_id)
	return "Archive: " + ", ".join(labels)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 420)), Color(0.12, 0.1, 0.13), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 420)), Color(0.4, 0.34, 0.25), false, 3.0)
	draw_rect(Rect2(92, 128, 96, 84), Color(0.62, 0.5, 0.28), true)
	draw_rect(Rect2(298, 110, 108, 96), Color(0.34, 0.44, 0.66), true)
	draw_rect(Rect2(508, 190, 106, 84), Color(0.48, 0.34, 0.66), true)
