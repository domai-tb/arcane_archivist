extends Node2D

@onready var world: Node2D = Node2D.new()

func _ready() -> void:
	world.name = "World"
	add_child(world)
	show_hub()

func show_hub() -> void:
	_clear_world()
	var hub_scene = preload("res://scenes/hub/LibraryHub.tscn").instantiate()
	hub_scene.setup(AppState, ContentDB)
	hub_scene.start_dive_requested.connect(_on_start_dive_requested)
	world.add_child(hub_scene)

func show_dungeon(run_state) -> void:
	_clear_world()
	var dungeon_scene = preload("res://scenes/dungeon/DungeonRun.tscn").instantiate()
	dungeon_scene.setup(AppState, ContentDB, run_state)
	dungeon_scene.run_finished.connect(_on_run_finished)
	world.add_child(dungeon_scene)

func _on_start_dive_requested(request_id: String) -> void:
	if request_id == "":
		return
	var run_state = AppState.start_run()
	show_dungeon(run_state)

func _on_run_finished(success: bool, tome_id: String) -> void:
	AppState.finish_run(success, tome_id)
	show_hub()

func _clear_world() -> void:
	for child in world.get_children():
		child.queue_free()
