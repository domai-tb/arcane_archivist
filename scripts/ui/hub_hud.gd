extends CanvasLayer
class_name HubHud

const ARCHIVE_SLOT_COUNT := 6
const HUD_MARGIN := 18
const INFO_PANEL_WIDTH := 320
const DETAIL_PANEL_HEIGHT := 132

var app_state = null
var content_db = null

var request_label: Label
var controls_label: Label
var selected_item_label: Label
var prompt_label: Label
var message_label: Label
var archive_label: Label
var bonus_label: Label
var detail_panel: PanelContainer
var detail_title: Label
var detail_body: Label
var slot_grid: GridContainer
var inventory_grid: GridContainer
var slot_buttons: Array = []
var inventory_buttons: Array = []
var selected_item_type: String = ""
var selected_item_id: String = ""


func setup(new_app_state, new_content_db) -> void:
	app_state = new_app_state
	content_db = new_content_db
	if app_state != null and not app_state.save_changed.is_connected(refresh_archive_panel):
		app_state.save_changed.connect(refresh_archive_panel)
	if is_inside_tree():
		refresh_archive_panel()


func _ready() -> void:
	_build_ui()
	refresh_archive_panel()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", HUD_MARGIN)
	margin.add_theme_constant_override("margin_top", HUD_MARGIN)
	margin.add_theme_constant_override("margin_right", HUD_MARGIN)
	margin.add_theme_constant_override("margin_bottom", HUD_MARGIN)
	root.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	stack.add_child(top_row)

	var info_panel := PanelContainer.new()
	info_panel.custom_minimum_size = Vector2(INFO_PANEL_WIDTH, 0)
	info_panel.size_flags_horizontal = 0
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_row.add_child(info_panel)

	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 8)
	info_panel.add_child(info_box)

	var title_label := Label.new()
	title_label.text = "Hub: Arcane Archivist"
	info_box.add_child(title_label)

	controls_label = _make_wrapped_label("Move with WASD. Interact with E.", 280)
	info_box.add_child(controls_label)

	request_label = _make_wrapped_label("No active request.", 280)
	info_box.add_child(request_label)

	selected_item_label = _make_wrapped_label("Selected: none", 280)
	info_box.add_child(selected_item_label)

	prompt_label = _make_wrapped_label("Move near a desk, shelf, or entrance.", 280)
	info_box.add_child(prompt_label)

	message_label = _make_wrapped_label("", 280)
	info_box.add_child(message_label)

	var archive_panel := PanelContainer.new()
	archive_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_row.add_child(archive_panel)

	var archive_box := VBoxContainer.new()
	archive_box.add_theme_constant_override("separation", 8)
	archive_panel.add_child(archive_box)

	var archive_title := Label.new()
	archive_title.text = "Archive Layout"
	archive_box.add_child(archive_title)

	archive_label = _make_wrapped_label("", 440)
	archive_box.add_child(archive_label)

	bonus_label = _make_wrapped_label("", 440)
	archive_box.add_child(bonus_label)

	var slot_title := Label.new()
	slot_title.text = "Slots"
	archive_box.add_child(slot_title)

	slot_grid = GridContainer.new()
	slot_grid.columns = 3
	slot_grid.add_theme_constant_override("h_separation", 8)
	slot_grid.add_theme_constant_override("v_separation", 8)
	archive_box.add_child(slot_grid)

	for index in range(ARCHIVE_SLOT_COUNT):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(146, 58)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.pressed.connect(_on_slot_pressed.bind(index))
		slot_grid.add_child(slot_button)
		slot_buttons.append(slot_button)

	var inventory_title := Label.new()
	inventory_title.text = "Owned Items"
	archive_box.add_child(inventory_title)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 2
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	archive_box.add_child(inventory_grid)

	var clear_button := Button.new()
	clear_button.text = "Clear Selection"
	clear_button.pressed.connect(_clear_selection)
	archive_box.add_child(clear_button)

	detail_panel = PanelContainer.new()
	detail_panel.visible = false
	detail_panel.custom_minimum_size = Vector2(0, DETAIL_PANEL_HEIGHT)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(detail_panel)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 8)
	detail_panel.add_child(detail_box)

	detail_title = Label.new()
	detail_title.text = "Detail"
	detail_box.add_child(detail_title)

	detail_body = _make_wrapped_label("", 0)
	detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(detail_body)


func _make_wrapped_label(text: String, min_width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if min_width > 0:
		label.custom_minimum_size = Vector2(min_width, 0)
	return label


func refresh_archive_panel() -> void:
	if app_state == null or content_db == null:
		return

	var request = app_state.get_active_request()
	if request != null:
		var completed_text := "completed" if app_state.is_request_completed(request.id) else "active"
		request_label.text = "Request: %s\n%s\nStatus: %s" % [request.name, _shorten_text(request.objective_text, 92), completed_text]
	else:
		request_label.text = "No active request."

	archive_label.text = _build_archive_text()
	bonus_label.text = app_state.get_active_archive_bonus_text()
	_update_selection_label()
	_refresh_slot_buttons()
	_refresh_inventory_buttons()


func set_request_text(text: String) -> void:
	if request_label != null:
		request_label.text = text


func set_archive_text(text: String) -> void:
	if archive_label != null:
		archive_label.text = text


func set_bonus_text(text: String) -> void:
	if bonus_label != null:
		bonus_label.text = text


func set_prompt_text(text: String) -> void:
	if prompt_label != null:
		prompt_label.text = text


func set_message(text: String) -> void:
	if message_label != null:
		message_label.text = text


func show_detail(title: String, body: String) -> void:
	if detail_panel != null:
		detail_panel.visible = true
		detail_title.text = title
		detail_body.text = body


func hide_detail() -> void:
	if detail_panel != null:
		detail_panel.visible = false


func _refresh_inventory_buttons() -> void:
	if inventory_grid == null:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
	inventory_buttons.clear()

	var inventory: Array = app_state.get_archive_inventory()
	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No owned items yet."
		inventory_grid.add_child(empty_label)
		return

	for entry in inventory:
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(170, 50)
		item_button.focus_mode = Control.FOCUS_ALL

		var item_type: String = str(entry.get("item_type", ""))
		var item_id: String = str(entry.get("item_id", ""))
		var item_name: String = str(entry.get("name", item_id))
		var placed_text := " (placed)" if bool(entry.get("placed", false)) else ""
		item_button.text = "%s\n%s%s" % [item_name, item_type.capitalize(), placed_text]

		if item_type == selected_item_type and item_id == selected_item_id:
			item_button.modulate = Color(1.0, 0.95, 0.75)

		item_button.pressed.connect(_on_inventory_pressed.bind(item_type, item_id))
		inventory_grid.add_child(item_button)
		inventory_buttons.append(item_button)


func _refresh_slot_buttons() -> void:
	if slot_grid == null:
		return
	for child in slot_grid.get_children():
		child.queue_free()
	slot_buttons.clear()

	var slots: Array = app_state.get_archive_slots()
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(146, 58)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.pressed.connect(_on_slot_pressed.bind(index))
		slot_button.text = _build_slot_button_text(index, slot)
		slot_grid.add_child(slot_button)
		slot_buttons.append(slot_button)


func _build_slot_button_text(index: int, slot: Dictionary) -> String:
	var slot_type: String = str(slot.get("item_type", ""))
	var slot_id: String = str(slot.get("item_id", ""))
	if slot_type == "":
		return "Slot %d\nEmpty" % [index + 1]
	return "Slot %d\n%s" % [index + 1, _get_item_name(slot_type, slot_id)]


func _on_inventory_pressed(item_type: String, item_id: String) -> void:
	if selected_item_type == item_type and selected_item_id == item_id:
		_clear_selection()
		return
	selected_item_type = item_type
	selected_item_id = item_id
	_update_selection_label()
	refresh_archive_panel()


func _on_slot_pressed(slot_index: int) -> void:
	var slots: Array = app_state.get_archive_slots()
	if slot_index < 0 or slot_index >= slots.size():
		return

	var slot: Dictionary = slots[slot_index]
	var slot_type: String = str(slot.get("item_type", ""))
	var slot_id: String = str(slot.get("item_id", ""))

	if selected_item_type != "":
		if selected_item_type == slot_type and selected_item_id == slot_id:
			app_state.remove_archive_item(slot_index)
			_clear_selection()
			return
		if app_state.place_archive_item(selected_item_type, selected_item_id, slot_index):
			_clear_selection()
			return
	elif slot_type != "":
		app_state.remove_archive_item(slot_index)


func _clear_selection() -> void:
	selected_item_type = ""
	selected_item_id = ""
	_update_selection_label()
	refresh_archive_panel()


func _update_selection_label() -> void:
	if selected_item_label == null:
		return
	if selected_item_type == "":
		selected_item_label.text = "Selected: none"
	else:
		selected_item_label.text = "Selected: %s (%s)" % [_get_item_name(selected_item_type, selected_item_id), selected_item_type]


func _shorten_text(text: String, max_chars: int) -> String:
	var clean := text.replace("\n", " ").strip_edges()
	if clean.length() <= max_chars:
		return clean
	return clean.substr(0, max_chars - 1).strip_edges() + "…"


func _build_archive_text() -> String:
	var tomes: Array = app_state.get_archive_tomes()
	var relics: Array = app_state.get_archive_relics()

	var tome_labels: Array[String] = []
	var relic_labels: Array[String] = []

	for tome_id in tomes:
		var tome = content_db.get_tome(tome_id)
		tome_labels.append(tome.name if tome != null else str(tome_id))

	for relic_id in relics:
		var relic = content_db.get_relic(relic_id)
		relic_labels.append(relic.name if relic != null else str(relic_id))

	return "Tomes: %s\nRelics: %s" % [
		"none" if tome_labels.is_empty() else ", ".join(tome_labels),
		"none" if relic_labels.is_empty() else ", ".join(relic_labels),
	]


func _get_item_name(item_type: String, item_id: String) -> String:
	if content_db == null:
		return item_id
	if item_type == "tome":
		var tome = content_db.get_tome(item_id)
		if tome != null:
			return tome.name
	elif item_type == "relic":
		var relic = content_db.get_relic(item_id)
		if relic != null:
			return relic.name
	return item_id
