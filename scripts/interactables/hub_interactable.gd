extends Node2D
class_name HubInteractable

signal interacted(kind: String)

@export var kind: String = "desk"
@export var display_name: String = ""
@export var body_text: String = ""
@export var accent_color: Color = Color(0.7, 0.7, 0.8)
@export var size: Vector2 = Vector2(64, 64)

var label_node: Label

func _ready() -> void:
	label_node = Label.new()
	label_node.text = display_name
	label_node.position = Vector2(-size.x * 0.5, -size.y * 0.5 - 20.0)
	add_child(label_node)
	queue_redraw()

func trigger() -> void:
	interacted.emit(kind)

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), accent_color, true)
	draw_rect(Rect2(-size * 0.5, size), Color(0.18, 0.13, 0.08), false, 2.0)

