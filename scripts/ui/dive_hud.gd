extends CanvasLayer

signal card_selected(index: int)

var title_label: Label
var stats_label: Label
var prompt_label: Label
var message_label: Label
var hotbar = null
var pending_player = null

func _ready() -> void:
	_build_ui()
	if pending_player != null:
		_apply_player(pending_player)

func _build_ui() -> void:
	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var stack = VBoxContainer.new()
	stack.position = Vector2(16, 16)
	root.add_child(stack)

	title_label = Label.new()
	title_label.text = "Dungeon Dive"
	stack.add_child(title_label)

	stats_label = Label.new()
	stats_label.custom_minimum_size = Vector2(360, 40)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(stats_label)

	prompt_label = Label.new()
	prompt_label.custom_minimum_size = Vector2(360, 40)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(prompt_label)

	message_label = Label.new()
	message_label.custom_minimum_size = Vector2(360, 40)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(message_label)

	hotbar = preload("res://scenes/cards/CardHotbar.tscn").instantiate()
	hotbar.card_selected.connect(_on_card_selected)
	add_child(hotbar)

func setup(player) -> void:
	pending_player = player
	if hotbar != null:
		_apply_player(player)

func _apply_player(player) -> void:
	if hotbar != null:
		hotbar.setup(player)

func _on_card_selected(index: int) -> void:
	card_selected.emit(index)

func set_room_title(text: String) -> void:
	title_label.text = text

func set_stats_text(text: String) -> void:
	stats_label.text = text

func set_prompt_text(text: String) -> void:
	prompt_label.text = text

func set_message(text: String) -> void:
	message_label.text = text
