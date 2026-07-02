extends CanvasLayer

signal card_selected(index: int)

var player = null
var buttons: Array = []
var info_label: Label

func setup(target_player) -> void:
	player = target_player

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var panel = PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.82
	panel.anchor_bottom = 0.97
	root.add_child(panel)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	info_label = Label.new()
	info_label.custom_minimum_size = Vector2(220, 48)
	info_label.text = "Insight hotbar"
	hbox.add_child(info_label)

	for i in range(5):
		var button = Button.new()
		var card_index = i
		button.custom_minimum_size = Vector2(120, 48)
		button.pressed.connect(func() -> void:
			card_selected.emit(card_index)
		)
		hbox.add_child(button)
		buttons.append(button)

func _process(_delta: float) -> void:
	if player == null:
		return

	for i in range(buttons.size()):
		var button = buttons[i]
		var card = player.get_card_def(i)
		if card == null:
			button.text = "Empty"
			continue

		var cooldown = player.get_card_cooldown(i)
		var state_text = "Ready" if cooldown <= 0.0 and player.insight >= card.cost else str(snapped(cooldown, 0.1))
		button.text = "%s\nC:%s %s" % [card.name, card.cost, state_text]
		button.disabled = cooldown > 0.0 or player.insight < card.cost

	info_label.text = "Insight: %d/%d" % [player.insight, player.insight_max]
