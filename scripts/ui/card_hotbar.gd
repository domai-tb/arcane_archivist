extends CanvasLayer

signal card_selected(index: int)

var player = null
var app_state = null
var content_db = null
var ui_root: Control
var panel: PanelContainer
var hbox: HBoxContainer
var buttons: Array = []
var info_label: Label
var compact_layout: bool = false
var did_focus_default_card: bool = false

func setup(target_player, new_app_state = null) -> void:
	player = target_player
	if new_app_state != null:
		app_state = new_app_state
	elif app_state == null:
		app_state = get_node_or_null("/root/AppState")

func _ready() -> void:
	if app_state == null:
		app_state = get_node_or_null("/root/AppState")
	if content_db == null:
		content_db = get_node_or_null("/root/ContentDB")
	_build_ui()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_apply_accessibility_settings()
	apply_responsive_layout()
	focus_default_card()

func _build_ui() -> void:
	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)
	ui_root = root

	panel = PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.82
	panel.anchor_bottom = 0.97
	root.add_child(panel)

	hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	info_label = Label.new()
	info_label.custom_minimum_size = Vector2(220, 52)
	info_label.text = "Insight hotbar"
	hbox.add_child(info_label)

	for i in range(5):
		var button = Button.new()
		var card_index = i
		button.custom_minimum_size = Vector2(118, 54)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			card_selected.emit(card_index)
		)
		hbox.add_child(button)
		buttons.append(button)

func _process(_delta: float) -> void:
	_apply_accessibility_settings()
	if player == null:
		return

	for i in range(buttons.size()):
		var button = buttons[i]
		var card = player.get_card_def(i)
		if card == null:
			button.text = "Empty"
			continue

		var cooldown = player.get_card_cooldown(i)
		var runtime: Dictionary = {}
		var content_db_ref = _get_content_db()
		if content_db_ref != null and content_db_ref.has_method("get_card_runtime_data"):
			runtime = content_db_ref.get_card_runtime_data(card.id, _get_active_bonuses())
		var cost := int(runtime.get("cost", card.cost))
		var state_text = "Ready" if cooldown <= 0.0 and player.insight >= cost else str(snapped(cooldown, 0.1))
		button.text = "%s\nC:%d %s" % [card.name, cost, state_text]
		button.disabled = cooldown > 0.0 or player.insight < cost

	info_label.text = "Insight: %d/%d" % [player.insight, player.insight_max]
	if not did_focus_default_card:
		focus_default_card()

func _apply_accessibility_settings() -> void:
	if app_state == null:
		app_state = get_node_or_null("/root/AppState")
	if app_state == null or ui_root == null:
		return

	var text_scale: float = max(0.9, float(app_state.get_text_scale()))
	ui_root.scale = Vector2(text_scale, text_scale)
	ui_root.pivot_offset = Vector2.ZERO

	var high_contrast: bool = app_state.get_contrast_mode() == "high"
	var text_color := Color(1.0, 1.0, 1.0) if high_contrast else Color(0.95, 0.93, 0.88)
	_apply_accessibility_to_node(ui_root, text_color, high_contrast, text_scale)


func _apply_accessibility_to_node(node: Node, text_color: Color, high_contrast: bool, text_scale: float) -> void:
	if node is Label:
		var label: Label = node
		label.add_theme_color_override("font_color", text_color)
		if high_contrast:
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 2)
		else:
			label.remove_theme_color_override("font_outline_color")
			label.remove_theme_constant_override("outline_size")
	elif node is Button:
		var button: Button = node
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.72) if high_contrast else Color(1.0, 0.95, 0.82))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.5) if high_contrast else Color(0.95, 0.9, 0.75))
		button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.72, 0.72, 0.72))
		button.add_theme_color_override("font_outline_color", Color.BLACK if high_contrast else Color(0.15, 0.15, 0.15))
		button.add_theme_constant_override("outline_size", 2 if high_contrast else 1)
		var min_size := button.custom_minimum_size
		min_size.y = max(min_size.y, 42.0 * text_scale)
		button.custom_minimum_size = min_size

	for child in node.get_children():
		if child is Node:
			_apply_accessibility_to_node(child, text_color, high_contrast, text_scale)


func _on_viewport_size_changed() -> void:
	apply_responsive_layout()


func apply_responsive_layout() -> void:
	if panel == null or hbox == null:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	compact_layout = viewport_size.x < 1100.0 or viewport_size.y < 720.0

	if compact_layout:
		panel.anchor_left = 0.03
		panel.anchor_right = 0.97
		panel.anchor_top = 0.79
		panel.anchor_bottom = 0.98
		hbox.add_theme_constant_override("separation", 6)
		info_label.custom_minimum_size = Vector2(180, 52)
	else:
		panel.anchor_left = 0.08
		panel.anchor_right = 0.92
		panel.anchor_top = 0.82
		panel.anchor_bottom = 0.97
		hbox.add_theme_constant_override("separation", 8)
		info_label.custom_minimum_size = Vector2(220, 52)

	for button in buttons:
		if button is Button:
			var hotbar_button: Button = button
			hotbar_button.custom_minimum_size = Vector2(118 if not compact_layout else 106, 54)


func focus_default_card() -> void:
	if buttons.is_empty():
		return

	for button in buttons:
		if button is Button and not button.disabled:
			(button as Button).grab_focus()
			did_focus_default_card = true
			return

	var first_button: Button = buttons[0]
	if first_button != null:
		first_button.grab_focus()
		did_focus_default_card = true

func _get_active_bonuses() -> Array:
	var active_app_state = get_node_or_null("/root/AppState")
	if active_app_state != null and active_app_state.has_method("get_active_archive_bonuses"):
		return active_app_state.get_active_archive_bonuses()
	return []


func _get_content_db():
	if content_db == null:
		content_db = get_node_or_null("/root/ContentDB")
	return content_db
