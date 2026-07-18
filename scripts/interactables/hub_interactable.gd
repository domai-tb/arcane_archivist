extends Node2D
class_name HubInteractable

signal interacted(kind: String)

@export var kind: String = "desk"
@export var display_name: String = ""
@export var body_text: String = ""
@export var accent_color: Color = Color(0.7, 0.7, 0.8)
@export var size: Vector2 = Vector2(64, 64)

func _ready() -> void:
	var click_area := Area2D.new()
	click_area.input_pickable = true
	var click_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	click_shape.shape = rectangle
	click_area.add_child(click_shape)
	add_child(click_area)
	click_area.input_event.connect(_on_click_area_input_event)
	queue_redraw()

func trigger() -> void:
	interacted.emit(kind)

func _on_click_area_input_event(_viewport, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		trigger()

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), accent_color, true)
	draw_rect(Rect2(-size * 0.5, size), Color(0.18, 0.13, 0.08), false, 2.0)
