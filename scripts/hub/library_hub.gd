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
	if app_state != null and not app_state.save_changed.is_connected(_refresh_ui):
		app_state.save_changed.connect(_refresh_ui)
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
	for child in get_children().duplicate():
		remove_child(child)
		child.queue_free()
	interactables.clear()

func _build_player() -> void:
	player = preload("res://scenes/player/Player.tscn").instantiate()
	player.setup_player([], 5, 5, 0, 0, "hub")
	player.position = Vector2(300, 230)
	add_child(player)

func _build_interactables() -> void:
	var board := preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	board.kind = "request_board"
	board.display_name = "Request Board"
	board.body_text = "Review the patron queue and request deadlines."
	board.accent_color = _get_interactable_accent("request_board")
	board.position = Vector2(145, 170)
	add_child(board)
	interactables.append(board)

	var desk := preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	desk.kind = "research_desk"
	desk.display_name = "Research Desk"
	desk.body_text = "Process the latest dive results into essence."
	desk.accent_color = _get_interactable_accent("research_desk")
	desk.position = Vector2(300, 145)
	add_child(desk)
	interactables.append(desk)

	var shelf := preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	shelf.kind = "archive_shelf"
	shelf.display_name = "Archive Shelf"
	shelf.body_text = "Arrange stations and archive items to tune the library."
	shelf.accent_color = _get_interactable_accent("archive_shelf")
	shelf.position = Vector2(460, 150)
	add_child(shelf)
	interactables.append(shelf)

	var entrance := preload("res://scenes/interactables/HubInteractable.tscn").instantiate()
	entrance.kind = "dungeon_entrance"
	entrance.display_name = "Dungeon Entrance"
	entrance.body_text = "Begin the current dive."
	entrance.accent_color = _get_interactable_accent("dungeon_entrance")
	entrance.position = Vector2(610, 230)
	add_child(entrance)
	interactables.append(entrance)

func _build_hud() -> void:
	hud = preload("res://scenes/ui/HubHud.tscn").instantiate()
	add_child(hud)
	hud.setup(app_state, content_db)
	if not hud.pre_dive_confirmed.is_connected(_on_pre_dive_confirmed):
		hud.pre_dive_confirmed.connect(_on_pre_dive_confirmed)

func _process(_delta: float) -> void:
	if player == null or hud == null:
		return

	var focused = _get_focused_interactable()
	if focused == null:
		hud.set_prompt_text("Move near the board, desk, shelf, or entrance. Press Interact to inspect or begin.")
	else:
		hud.set_prompt_text("Interact with %s." % focused.display_name)
	if hud.pre_dive_panel != null and hud.pre_dive_panel.visible:
		hud.set_prompt_text("Choose a curse preview, then confirm the dive.")
		return

	if Input.is_action_just_pressed("interact") and focused != null:
		_handle_interaction(focused)

	if Input.is_action_just_pressed("ui_cancel") and hud.detail_panel != null and hud.detail_panel.visible:
		hud.hide_detail()

func _handle_interaction(focused) -> void:
	if focused.kind == "request_board" or focused.kind == "request_desk":
		var request = app_state.get_active_request()
		if request != null:
			hud.show_detail(request.name, "%s\n\nReward: %s\n\n%s" % [
				request.objective_text,
				request.reward_text,
				app_state.get_request_queue_text(),
			])
		else:
			hud.show_detail("No Request", "The patron board is quiet.")
	elif focused.kind == "research_desk":
		if app_state.has_pending_research_job():
			if app_state.has_active_research_job():
				app_state.work_research_job()
			else:
				app_state.start_research_job()
			hud.show_detail("Research Desk", app_state.get_research_job_text())
		else:
			hud.show_detail("Research Desk", "No research job is waiting. Complete a dive to queue one.")
	elif focused.kind == "archive_shelf":
		hud.show_detail("Archive Shelf", "%s\n\n%s" % [_build_archive_text(), app_state.get_station_layout_text()])
	elif focused.kind == "dungeon_entrance":
		if app_state.has_pending_card_reward_options():
			hud.show_detail("Reward Pending", "Choose a card reward before starting the next dive.")
			return
		if not app_state.is_active_deck_valid():
			hud.show_detail("Deck Invalid", "Repair the active deck before diving again.")
			return
		if app_state.get_active_request_id() == "":
			hud.show_detail("No Request", "There is no active patron request to dive for.")
			return
		var theme_text: String = app_state.get_dungeon_theme_preview_text(app_state.get_active_request_id())
		if not app_state.get_show_tooltips_enabled():
			theme_text = "Dungeon theme: %s" % app_state.get_dungeon_theme_name(app_state.get_active_request_id())
		var dive_text := "A short descent will search for the requested tome.\n\n%s\n\n%s" % [
			theme_text,
			app_state.get_active_deck_brief_text(),
		]
		if app_state.has_pending_research_job():
			dive_text = "A research job is waiting, but the active request can still be dived.\n\n%s\n\n%s" % [
				theme_text,
				app_state.get_active_deck_brief_text(),
			]
		hud.show_detail("Begin Dive", dive_text + "\n\nSelect a curse preview before confirming the dive.")
		hud.open_pre_dive_panel(app_state.get_active_request_id())

func _get_focused_interactable():
	if player == null:
		return null

	var nearest = null
	var nearest_distance: float = 74.0
	for interactable in interactables:
		var distance: float = player.global_position.distance_to(interactable.global_position)
		if distance < nearest_distance:
			nearest = interactable
			nearest_distance = distance
	return nearest

func _refresh_ui() -> void:
	if hud == null:
		return

	var request = app_state.get_active_request()
	if request != null:
		var active_entry: Dictionary = app_state.get_active_request_entry()
		var state := str(active_entry.get("state", "active"))
		hud.set_request_text("%s\n%s\nState: %s" % [request.name, request.objective_text, state])
		hud.set_message("Request is %s." % state)
	else:
		hud.set_request_text("No active request.")
		hud.set_message("No active request.")

	hud.set_request_summary_text(app_state.get_request_queue_text())
	hud.set_research_summary_text(app_state.get_research_job_text())
	hud.set_station_summary_text("Stations: %s" % app_state.get_station_layout_text())
	hud.set_archive_text(_build_archive_text())
	hud.set_bonus_text(app_state.get_active_archive_bonus_text())
	hud.set_deck_text(app_state.get_active_deck_brief_text())

func _on_pre_dive_confirmed(request_id: String, curse_id: String) -> void:
	if app_state != null:
		app_state.save_data["selected_curse_id"] = curse_id
		if app_state.has_method("_save"):
			app_state._save()
	if hud != null:
		hud.hide_pre_dive_panel()
	start_dive_requested.emit(request_id)

func _build_archive_text() -> String:
	var tomes: Array = app_state.get_archive_tomes()
	var relics: Array = app_state.get_archive_relics()
	var slots: Array = app_state.get_archive_slots()

	var lines: Array[String] = []
	var tome_labels: Array[String] = []
	for tome_id in tomes:
		var tome = content_db.get_tome(tome_id)
		tome_labels.append(tome.name if tome != null else str(tome_id))

	var relic_labels: Array[String] = []
	for relic_id in relics:
		var relic = content_db.get_relic(relic_id)
		relic_labels.append(relic.name if relic != null else str(relic_id))

	lines.append("Tomes: %s" % ("none" if tome_labels.is_empty() else ", ".join(tome_labels)))
	lines.append("Relics: %s" % ("none" if relic_labels.is_empty() else ", ".join(relic_labels)))
	lines.append("Archive slots: %d" % slots.size())
	return "\n".join(lines)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 420)), Color(0.12, 0.1, 0.13), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 420)), Color(0.4, 0.34, 0.25), false, 3.0)
	draw_rect(Rect2(92, 128, 96, 84), _get_interactable_accent("request_board"), true)
	draw_rect(Rect2(250, 118, 92, 84), _get_interactable_accent("research_desk"), true)
	draw_rect(Rect2(408, 110, 108, 96), _get_interactable_accent("archive_shelf"), true)
	draw_rect(Rect2(560, 190, 106, 84), _get_interactable_accent("dungeon_entrance"), true)

func _get_interactable_accent(kind: String) -> Color:
	var palette_mode := "default"
	if app_state != null and app_state.has_method("get_palette_mode"):
		palette_mode = app_state.get_palette_mode()
	if palette_mode == "accessible":
		match kind:
			"request_board":
				return Color(0.92, 0.82, 0.35)
			"research_desk":
				return Color(0.34, 0.82, 0.78)
			"archive_shelf":
				return Color(0.95, 0.64, 0.28)
			"dungeon_entrance":
				return Color(0.76, 0.46, 0.92)
			_:
				return Color(0.86, 0.86, 0.86)
	match kind:
		"request_board":
			return Color(0.8, 0.67, 0.42)
		"research_desk":
			return Color(0.55, 0.72, 0.5)
		"archive_shelf":
			return Color(0.42, 0.58, 0.74)
		"dungeon_entrance":
			return Color(0.58, 0.38, 0.7)
		_:
			return Color(0.7, 0.7, 0.8)
