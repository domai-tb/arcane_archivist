extends Node2D

@onready var world: Node2D = Node2D.new()
var app_state: Node = null
var content_db: Node = null

func _ready() -> void:
	world.name = "World"
	add_child(world)
	app_state = get_node_or_null("/root/AppState")
	content_db = get_node_or_null("/root/ContentDB")
	show_hub()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave_state()

func show_hub() -> void:
	_autosave_state()
	_clear_world()
	var hub_scene := preload("res://scenes/hub/LibraryHub.tscn").instantiate()
	hub_scene.setup(app_state, content_db)
	hub_scene.start_dive_requested.connect(_on_start_dive_requested)
	world.add_child(hub_scene)

func show_dungeon(run_state) -> void:
	_autosave_state()
	_clear_world()
	var dungeon_scene := preload("res://scenes/dungeon/DungeonRun.tscn").instantiate()
	dungeon_scene.setup(app_state, content_db, run_state)
	dungeon_scene.run_finished.connect(_on_run_finished)
	world.add_child(dungeon_scene)

func _on_start_dive_requested(request_id: String) -> void:
	if request_id == "":
		return
	_autosave_state()
	var run_state = app_state.start_run()
	if run_state == null:
		return
	show_dungeon(run_state)

func _on_run_finished(success: bool, tome_id: String) -> void:
	app_state.finish_run(success, tome_id)
	show_hub()

func _clear_world() -> void:
	for child in world.get_children().duplicate():
		world.remove_child(child)
		child.queue_free()

func _autosave_state() -> void:
	if app_state != null and app_state.has_method("save_now"):
		app_state.save_now()
