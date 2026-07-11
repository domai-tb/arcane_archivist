extends CanvasLayer

signal card_selected(index: int)

var title_label: Label
var stats_label: Label
var controls_label: Label
var prompt_label: Label
var message_label: Label
var bonus_label: Label
var build_label: Label
var deck_label: Label
var ui_root: Control
var touch_panel: PanelContainer
var touch_button_box: GridContainer
var touch_buttons: Dictionary = {}
var compact_layout: bool = false
var app_state = null
var hotbar = null
var pending_player = null

func _ready() -> void:
	if app_state == null:
		app_state = get_node_or_null("/root/AppState")
	_build_ui()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	if pending_player != null:
		_apply_player(pending_player)
	_apply_accessibility_settings()
	_apply_responsive_layout()

func _build_ui() -> void:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var stack := VBoxContainer.new()
	stack.position = Vector2(16, 16)
	stack.add_theme_constant_override("separation", 8)
	root.add_child(stack)
	ui_root = stack

	title_label = Label.new()
	title_label.text = "Dungeon Dive"
	stack.add_child(title_label)

	controls_label = Label.new()
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.custom_minimum_size = Vector2(360, 36)
	controls_label.text = "Move with WASD. Use 1-5 for cards. Press E to interact."
	stack.add_child(controls_label)

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

	bonus_label = Label.new()
	bonus_label.custom_minimum_size = Vector2(360, 60)
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(bonus_label)

	build_label = Label.new()
	build_label.custom_minimum_size = Vector2(360, 60)
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(build_label)

	deck_label = Label.new()
	deck_label.custom_minimum_size = Vector2(360, 60)
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(deck_label)

	touch_panel = PanelContainer.new()
	touch_panel.visible = false
	root.add_child(touch_panel)

	var touch_box := VBoxContainer.new()
	touch_box.add_theme_constant_override("separation", 6)
	touch_panel.add_child(touch_box)

	var touch_title := Label.new()
	touch_title.text = "Touch Controls"
	touch_box.add_child(touch_title)

	touch_button_box = GridContainer.new()
	touch_button_box.columns = 3
	touch_button_box.add_theme_constant_override("h_separation", 6)
	touch_button_box.add_theme_constant_override("v_separation", 6)
	touch_box.add_child(touch_button_box)

	_add_touch_button("", "")
	_add_touch_button("Up", "move_up")
	_add_touch_button("", "")
	_add_touch_button("Left", "move_left")
	_add_touch_button("Interact", "interact")
	_add_touch_button("Right", "move_right")
	_add_touch_button("", "")
	_add_touch_button("Down", "move_down")
	_add_touch_button("Cancel", "ui_cancel")

	hotbar = preload("res://scenes/cards/CardHotbar.tscn").instantiate()
	if hotbar.has_signal("card_selected"):
		hotbar.connect("card_selected", Callable(self, "_on_card_selected"))
	add_child(hotbar)


func _exit_tree() -> void:
	_release_all_touch_actions()

func setup(player, new_app_state = null) -> void:
	pending_player = player
	if new_app_state != null:
		app_state = new_app_state
	elif app_state == null:
		app_state = get_node_or_null("/root/AppState")
	if hotbar != null:
		_apply_player(player)
	_apply_accessibility_settings()

func _apply_player(player) -> void:
	if hotbar != null:
		hotbar.setup(player, app_state)
		if hotbar.has_method("focus_default_card"):
			hotbar.call_deferred("focus_default_card")

func _on_card_selected(index: int) -> void:
	card_selected.emit(index)

func set_room_title(text: String) -> void:
	if title_label != null:
		title_label.text = text

func set_stats_text(text: String) -> void:
	if stats_label != null:
		stats_label.text = text

func set_prompt_text(text: String) -> void:
	if prompt_label != null:
		prompt_label.text = text

func set_controls_text(text: String) -> void:
	if controls_label != null:
		controls_label.text = text

func set_message(text: String) -> void:
	if message_label != null:
		message_label.text = text

func set_active_bonuses_text(text: String) -> void:
	if bonus_label != null:
		bonus_label.text = text

func set_build_text(text: String) -> void:
	if build_label != null:
		build_label.text = text

func set_deck_text(text: String) -> void:
	if deck_label != null:
		deck_label.text = text

func _apply_accessibility_settings() -> void:
	if app_state == null:
		app_state = get_node_or_null("/root/AppState")
	if app_state == null:
		return

	var text_scale: float = max(0.9, float(app_state.get_text_scale()))
	if ui_root != null:
		ui_root.scale = Vector2(text_scale, text_scale)
		ui_root.pivot_offset = Vector2.ZERO

	var high_contrast: bool = app_state.get_contrast_mode() == "high"
	var text_color := Color(1.0, 1.0, 1.0) if high_contrast else Color(0.95, 0.93, 0.88)
	if ui_root != null:
		_apply_accessibility_to_node(ui_root, text_color, high_contrast, text_scale)
	if hotbar != null:
		_apply_accessibility_to_node(hotbar, text_color, high_contrast, text_scale)


func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if ui_root == null:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	compact_layout = viewport_size.x < 1100.0 or viewport_size.y < 720.0

	var margin_x := 16
	var margin_y := 16
	var label_width := 360
	if compact_layout:
		margin_x = 12
		margin_y = 12
		label_width = 280
	if viewport_size.x < 900.0 or viewport_size.y < 600.0:
		margin_x = 10
		margin_y = 10
		label_width = 240

	ui_root.position = Vector2(margin_x, margin_y)

	controls_label.custom_minimum_size = Vector2(label_width, 36)
	stats_label.custom_minimum_size = Vector2(label_width, 40)
	prompt_label.custom_minimum_size = Vector2(label_width, 40)
	message_label.custom_minimum_size = Vector2(label_width, 40)
	bonus_label.custom_minimum_size = Vector2(label_width, 60)
	build_label.custom_minimum_size = Vector2(label_width, 60)
	deck_label.custom_minimum_size = Vector2(label_width, 60)

	if hotbar != null and hotbar.has_method("apply_responsive_layout"):
		hotbar.call_deferred("apply_responsive_layout")

	if touch_panel != null:
		touch_panel.anchor_left = 0.64
		touch_panel.anchor_right = 0.98
		touch_panel.anchor_top = 0.66
		touch_panel.anchor_bottom = 0.98
		touch_panel.visible = compact_layout
		if touch_panel.visible:
			var touch_width := 260
			if viewport_size.x < 900.0 or viewport_size.y < 600.0:
				touch_width = 220
			touch_panel.custom_minimum_size = Vector2(touch_width, 0)


func _add_touch_button(title: String, action: String) -> void:
	if title == "":
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(76, 52)
		touch_button_box.add_child(spacer)
		return
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(76, 52)
	if action != "":
		button.button_down.connect(_press_touch_action.bind(action))
		button.button_up.connect(_release_touch_action.bind(action))
	touch_button_box.add_child(button)
	if action != "":
		touch_buttons[action] = button


func _press_touch_action(action: String) -> void:
	Input.action_press(action)


func _release_touch_action(action: String) -> void:
	Input.action_release(action)


func _release_all_touch_actions() -> void:
	for action in touch_buttons.keys():
		_release_touch_action(str(action))


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
