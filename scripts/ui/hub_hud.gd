extends CanvasLayer
class_name HubHud

signal pre_dive_confirmed(request_id: String, curse_id: String)

const ARCHIVE_SLOT_COUNT := 6
const HUD_MARGIN := 18
const INFO_PANEL_WIDTH := 320
const DETAIL_PANEL_HEIGHT := 132
var app_state = null
var content_db = null

var request_label: Label
var essence_label: Label
var request_queue_label: Label
var tracked_request_label: Label
var research_label: Label
var station_label: Label
var build_summary_label: Label
var pressure_label: Label
var controls_label: Label
var selected_item_label: Label
var prompt_label: Label
var message_label: Label
var archive_label: Label
var bonus_label: Label
var deck_label: Label
var deck_validation_label: Label
var deck_grid: GridContainer
var collection_grid: GridContainer
var reward_panel: PanelContainer
var reward_title: Label
var reward_text: Label
var reward_grid: GridContainer
var detail_panel: PanelContainer
var detail_title: Label
var detail_body: Label
var slot_grid: GridContainer
var inventory_grid: GridContainer
var slot_buttons: Array = []
var inventory_buttons: Array = []
var deck_buttons: Array = []
var collection_buttons: Array = []
var reward_buttons: Array = []
var station_layout_buttons: Array = []
var section_buttons: Array = []
var section_panels: Dictionary = {}
var active_section_id: String = "archive"
var selected_curse_id: String = ""
var selected_upgrade_layout_id: String = ""
var selected_progression_tag_id: String = ""
var pre_dive_request_id: String = ""
var progression_summary_label: Label
var progression_grid: GridContainer
var progression_detail_label: Label
var progression_buttons: Array = []
var pressure_summary_label: Label
var pressure_detail_label: Label
var pressure_button_box: VBoxContainer
var pressure_response_buttons: Array = []
var curses_summary_label: Label
var curse_grid: GridContainer
var curse_detail_label: Label
var curse_buttons: Array = []
var records_summary_label: Label
var records_grid: VBoxContainer
var copy_records_button: Button
var guidance_button: Button
var text_scale_button: Button
var contrast_button: Button
var palette_button: Button
var deck_sort_button: Button
var archive_filter_button: Button
var track_active_button: Button
var track_next_button: Button
var clear_track_button: Button
var accessibility_label: Label
var upgrade_summary_label: Label
var upgrade_grid: GridContainer
var upgrade_detail_label: Label
var apply_upgrade_button: Button
var upgrade_buttons: Array = []
var pre_dive_panel: PanelContainer
var pre_dive_request_label: Label
var pre_dive_theme_label: Label
var pre_dive_bonus_label: Label
var pre_dive_curse_label: Label
var pre_dive_detail_label: Label
var pre_dive_curse_grid: GridContainer
var pre_dive_confirm_button: Button
var pre_dive_cancel_button: Button
var touch_panel: PanelContainer
var touch_button_box: GridContainer
var touch_buttons: Dictionary = {}
var top_row: HBoxContainer
var info_panel: PanelContainer
var deck_panel: PanelContainer
var deck_box: VBoxContainer
var service_row: HBoxContainer
var pre_dive_outer: MarginContainer
var pre_dive_button_row: HBoxContainer
var pre_dive_restore_focus: Control
var compact_layout: bool = false
var selected_item_type: String = ""
var selected_item_id: String = ""
var selected_collection_card_id: String = ""
var selected_deck_slot_index: int = -1
var selected_reward_card_id: String = ""
var ui_root: Control
var ui_overlay_root: Control


func setup(new_app_state, new_content_db) -> void:
	app_state = new_app_state
	content_db = new_content_db
	if app_state != null:
		selected_curse_id = str(app_state.save_data.get("selected_curse_id", selected_curse_id))
		selected_upgrade_layout_id = str(app_state.save_data.get("station_layout_id", selected_upgrade_layout_id))
	if app_state != null and not app_state.save_changed.is_connected(refresh_archive_panel):
		app_state.save_changed.connect(refresh_archive_panel)
	if is_inside_tree():
		refresh_archive_panel()


func _ready() -> void:
	_build_ui()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	refresh_archive_panel()


func _exit_tree() -> void:
	_release_all_touch_actions()


func _unhandled_input(event: InputEvent) -> void:
	if pre_dive_panel != null and pre_dive_panel.visible and event.is_action_pressed("ui_cancel"):
		hide_pre_dive_panel()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	ui_overlay_root = root

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", HUD_MARGIN)
	margin.add_theme_constant_override("margin_top", HUD_MARGIN)
	margin.add_theme_constant_override("margin_right", HUD_MARGIN)
	margin.add_theme_constant_override("margin_bottom", HUD_MARGIN)
	root.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stack.add_theme_constant_override("separation", 12)
	scroll.add_child(stack)
	ui_root = stack

	top_row = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	stack.add_child(top_row)

	info_panel = PanelContainer.new()
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

	essence_label = _make_wrapped_label("Essence: 0", 280)
	info_box.add_child(essence_label)

	request_queue_label = _make_wrapped_label("Request queue unavailable.", 280)
	info_box.add_child(request_queue_label)

	tracked_request_label = _make_wrapped_label("Tracked request: none.", 280)
	info_box.add_child(tracked_request_label)

	var request_row := HBoxContainer.new()
	request_row.add_theme_constant_override("separation", 6)
	info_box.add_child(request_row)

	track_active_button = Button.new()
	track_active_button.text = "Track Active"
	track_active_button.pressed.connect(_on_track_active_request_pressed)
	request_row.add_child(track_active_button)

	track_next_button = Button.new()
	track_next_button.text = "Track Next"
	track_next_button.pressed.connect(_on_track_next_request_pressed)
	request_row.add_child(track_next_button)

	clear_track_button = Button.new()
	clear_track_button.text = "Clear Track"
	clear_track_button.pressed.connect(_on_clear_tracked_request_pressed)
	request_row.add_child(clear_track_button)

	research_label = _make_wrapped_label("No research job waiting.", 280)
	info_box.add_child(research_label)

	station_label = _make_wrapped_label("Stations: Balanced Layout", 280)
	info_box.add_child(station_label)

	build_summary_label = _make_wrapped_label("Build summary unavailable.", 280)
	info_box.add_child(build_summary_label)

	pressure_label = _make_wrapped_label("Pressure: calm.", 280)
	info_box.add_child(pressure_label)

	service_row = HBoxContainer.new()
	service_row.add_theme_constant_override("separation", 8)
	info_box.add_child(service_row)

	var inspect_button := Button.new()
	inspect_button.text = "Inspect Requests"
	inspect_button.pressed.connect(_on_inspect_requests_pressed)
	service_row.add_child(inspect_button)

	var research_button := Button.new()
	research_button.text = "Start Research"
	research_button.pressed.connect(_on_start_research_pressed)
	service_row.add_child(research_button)

	var station_button := Button.new()
	station_button.text = "Arrange Stations"
	station_button.pressed.connect(_on_arrange_stations_pressed)
	service_row.add_child(station_button)

	guidance_button = Button.new()
	guidance_button.text = "Guidance"
	guidance_button.pressed.connect(_on_toggle_guidance_pressed)
	service_row.add_child(guidance_button)

	text_scale_button = Button.new()
	text_scale_button.text = "Text Size"
	text_scale_button.pressed.connect(_on_cycle_text_scale_pressed)
	service_row.add_child(text_scale_button)

	contrast_button = Button.new()
	contrast_button.text = "Contrast"
	contrast_button.pressed.connect(_on_cycle_contrast_pressed)
	service_row.add_child(contrast_button)

	palette_button = Button.new()
	palette_button.text = "Palette"
	palette_button.pressed.connect(_on_cycle_palette_pressed)
	service_row.add_child(palette_button)

	selected_item_label = _make_wrapped_label("Selected: none", 280)
	info_box.add_child(selected_item_label)

	prompt_label = _make_wrapped_label("Move near the board, desk, shelf, or entrance.", 280)
	info_box.add_child(prompt_label)

	message_label = _make_wrapped_label("", 280)
	info_box.add_child(message_label)

	accessibility_label = _make_wrapped_label("Accessibility unavailable.", 280)
	info_box.add_child(accessibility_label)

	var archive_panel := PanelContainer.new()
	archive_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_row.add_child(archive_panel)

	var archive_box := VBoxContainer.new()
	archive_box.add_theme_constant_override("separation", 8)
	archive_panel.add_child(archive_box)

	var archive_title := Label.new()
	archive_title.text = "Archive Hub"
	archive_box.add_child(archive_title)

	var section_row := HBoxContainer.new()
	section_row.add_theme_constant_override("separation", 6)
	archive_box.add_child(section_row)

	_add_section_button(section_row, "archive", "Archive")
	_add_section_button(section_row, "progression", "Progression")
	_add_section_button(section_row, "pressure", "Pressure")
	_add_section_button(section_row, "curses", "Curses")
	_add_section_button(section_row, "records", "Records")
	_add_section_button(section_row, "upgrades", "Upgrades")

	var section_stack := VBoxContainer.new()
	section_stack.add_theme_constant_override("separation", 12)
	archive_box.add_child(section_stack)

	var archive_section := VBoxContainer.new()
	archive_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(archive_section)
	section_panels["archive"] = archive_section

	archive_label = _make_wrapped_label("", 440)
	archive_section.add_child(archive_label)

	bonus_label = _make_wrapped_label("", 440)
	archive_section.add_child(bonus_label)

	var slot_title := Label.new()
	slot_title.text = "Slots"
	archive_section.add_child(slot_title)

	slot_grid = GridContainer.new()
	slot_grid.columns = 3
	slot_grid.add_theme_constant_override("h_separation", 8)
	slot_grid.add_theme_constant_override("v_separation", 8)
	archive_section.add_child(slot_grid)

	for index in range(ARCHIVE_SLOT_COUNT):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(146, 58)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.pressed.connect(_on_slot_pressed.bind(index))
		slot_grid.add_child(slot_button)
		slot_buttons.append(slot_button)

	var inventory_title := Label.new()
	inventory_title.text = "Owned Items"
	archive_section.add_child(inventory_title)

	var archive_control_row := HBoxContainer.new()
	archive_control_row.add_theme_constant_override("separation", 6)
	archive_section.add_child(archive_control_row)

	archive_filter_button = Button.new()
	archive_filter_button.text = "Archive Filter: All"
	archive_filter_button.pressed.connect(_on_cycle_archive_filter_pressed)
	archive_control_row.add_child(archive_filter_button)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 2
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	archive_section.add_child(inventory_grid)

	var clear_button := Button.new()
	clear_button.text = "Clear Selection"
	clear_button.pressed.connect(_clear_selection)
	archive_section.add_child(clear_button)

	var progression_section := VBoxContainer.new()
	progression_section.visible = false
	progression_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(progression_section)
	section_panels["progression"] = progression_section

	var progression_title := Label.new()
	progression_title.text = "Archive Progression"
	progression_section.add_child(progression_title)

	var progression_summary := _make_wrapped_label("", 440)
	progression_section.add_child(progression_summary)
	progression_summary_label = progression_summary

	var progression_grid_title := Label.new()
	progression_grid_title.text = "Wing previews"
	progression_section.add_child(progression_grid_title)

	progression_grid = GridContainer.new()
	progression_grid.columns = 2
	progression_grid.add_theme_constant_override("h_separation", 8)
	progression_grid.add_theme_constant_override("v_separation", 8)
	progression_section.add_child(progression_grid)

	progression_detail_label = _make_wrapped_label("", 440)
	progression_section.add_child(progression_detail_label)

	var pressure_section := VBoxContainer.new()
	pressure_section.visible = false
	pressure_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(pressure_section)
	section_panels["pressure"] = pressure_section

	var pressure_title := Label.new()
	pressure_title.text = "Pressure Response"
	pressure_section.add_child(pressure_title)

	pressure_summary_label = _make_wrapped_label("", 440)
	pressure_section.add_child(pressure_summary_label)

	pressure_detail_label = _make_wrapped_label("", 440)
	pressure_section.add_child(pressure_detail_label)

	pressure_button_box = VBoxContainer.new()
	pressure_button_box.add_theme_constant_override("separation", 8)
	pressure_section.add_child(pressure_button_box)

	var curses_section := VBoxContainer.new()
	curses_section.visible = false
	curses_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(curses_section)
	section_panels["curses"] = curses_section

	var curses_title := Label.new()
	curses_title.text = "Curse Selection"
	curses_section.add_child(curses_title)

	curses_summary_label = _make_wrapped_label("", 440)
	curses_section.add_child(curses_summary_label)

	curse_grid = GridContainer.new()
	curse_grid.columns = 2
	curse_grid.add_theme_constant_override("h_separation", 8)
	curse_grid.add_theme_constant_override("v_separation", 8)
	curses_section.add_child(curse_grid)

	curse_detail_label = _make_wrapped_label("", 440)
	curses_section.add_child(curse_detail_label)

	var records_section := VBoxContainer.new()
	records_section.visible = false
	records_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(records_section)
	section_panels["records"] = records_section

	var records_title := Label.new()
	records_title.text = "Run History and Records"
	records_section.add_child(records_title)

	records_summary_label = _make_wrapped_label("", 440)
	records_section.add_child(records_summary_label)

	records_grid = VBoxContainer.new()
	records_grid.add_theme_constant_override("separation", 6)
	records_section.add_child(records_grid)

	copy_records_button = Button.new()
	copy_records_button.text = "Copy Summary"
	copy_records_button.pressed.connect(_on_copy_records_pressed)
	records_section.add_child(copy_records_button)

	var upgrades_section := VBoxContainer.new()
	upgrades_section.visible = false
	upgrades_section.add_theme_constant_override("separation", 8)
	section_stack.add_child(upgrades_section)
	section_panels["upgrades"] = upgrades_section

	var upgrades_title := Label.new()
	upgrades_title.text = "Upgrade Preview"
	upgrades_section.add_child(upgrades_title)

	upgrade_summary_label = _make_wrapped_label("", 440)
	upgrades_section.add_child(upgrade_summary_label)

	upgrade_grid = GridContainer.new()
	upgrade_grid.columns = 1
	upgrade_grid.add_theme_constant_override("h_separation", 8)
	upgrade_grid.add_theme_constant_override("v_separation", 8)
	upgrades_section.add_child(upgrade_grid)

	upgrade_detail_label = _make_wrapped_label("", 440)
	upgrades_section.add_child(upgrade_detail_label)

	apply_upgrade_button = Button.new()
	apply_upgrade_button.text = "Apply Previewed Upgrade"
	apply_upgrade_button.pressed.connect(_on_apply_upgrade_pressed)
	upgrades_section.add_child(apply_upgrade_button)

	section_panels["archive"] = archive_section
	_show_section(active_section_id)

	deck_panel = PanelContainer.new()
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(deck_panel)

	deck_box = VBoxContainer.new()
	deck_box.add_theme_constant_override("separation", 8)
	deck_panel.add_child(deck_box)

	var deck_title := Label.new()
	deck_title.text = "Deck Lab"
	deck_box.add_child(deck_title)

	var deck_control_row := HBoxContainer.new()
	deck_control_row.add_theme_constant_override("separation", 6)
	deck_box.add_child(deck_control_row)

	deck_sort_button = Button.new()
	deck_sort_button.text = "Sort Deck: Manual"
	deck_sort_button.pressed.connect(_on_sort_deck_pressed)
	deck_control_row.add_child(deck_sort_button)

	deck_label = _make_wrapped_label("", 760)
	deck_box.add_child(deck_label)

	deck_validation_label = _make_wrapped_label("", 760)
	deck_box.add_child(deck_validation_label)

	var deck_row := HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 12)
	deck_box.add_child(deck_row)

	var active_deck_panel := VBoxContainer.new()
	active_deck_panel.custom_minimum_size = Vector2(360, 0)
	active_deck_panel.add_theme_constant_override("separation", 8)
	deck_row.add_child(active_deck_panel)

	var active_deck_title := Label.new()
	active_deck_title.text = "Active Deck"
	active_deck_panel.add_child(active_deck_title)

	deck_grid = GridContainer.new()
	deck_grid.columns = 5
	deck_grid.add_theme_constant_override("h_separation", 8)
	deck_grid.add_theme_constant_override("v_separation", 8)
	active_deck_panel.add_child(deck_grid)

	var collection_panel := VBoxContainer.new()
	collection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_panel.add_theme_constant_override("separation", 8)
	deck_row.add_child(collection_panel)

	var collection_title := Label.new()
	collection_title.text = "Card Collection"
	collection_panel.add_child(collection_title)

	collection_grid = GridContainer.new()
	collection_grid.columns = 3
	collection_grid.add_theme_constant_override("h_separation", 8)
	collection_grid.add_theme_constant_override("v_separation", 8)
	collection_panel.add_child(collection_grid)

	reward_panel = PanelContainer.new()
	reward_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_box.add_child(reward_panel)

	var reward_box := VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 8)
	reward_panel.add_child(reward_box)

	reward_title = Label.new()
	reward_title.text = "Pending Reward"
	reward_box.add_child(reward_title)

	reward_text = _make_wrapped_label("", 760)
	reward_box.add_child(reward_text)

	reward_grid = GridContainer.new()
	reward_grid.columns = 3
	reward_grid.add_theme_constant_override("h_separation", 8)
	reward_grid.add_theme_constant_override("v_separation", 8)
	reward_box.add_child(reward_grid)

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

	touch_panel = PanelContainer.new()
	touch_panel.visible = false
	add_child(touch_panel)

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

	pre_dive_panel = PanelContainer.new()
	pre_dive_panel.visible = false
	pre_dive_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pre_dive_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pre_dive_panel)

	pre_dive_outer = MarginContainer.new()
	pre_dive_outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pre_dive_outer.add_theme_constant_override("margin_left", 140)
	pre_dive_outer.add_theme_constant_override("margin_top", 56)
	pre_dive_outer.add_theme_constant_override("margin_right", 140)
	pre_dive_outer.add_theme_constant_override("margin_bottom", 56)
	pre_dive_panel.add_child(pre_dive_outer)

	var pre_dive_box := VBoxContainer.new()
	pre_dive_box.add_theme_constant_override("separation", 10)
	pre_dive_outer.add_child(pre_dive_box)

	var pre_dive_title := Label.new()
	pre_dive_title.text = "Prepare the Dive"
	pre_dive_box.add_child(pre_dive_title)

	pre_dive_request_label = _make_wrapped_label("", 0)
	pre_dive_box.add_child(pre_dive_request_label)

	pre_dive_theme_label = _make_wrapped_label("", 0)
	pre_dive_box.add_child(pre_dive_theme_label)

	pre_dive_bonus_label = _make_wrapped_label("", 0)
	pre_dive_box.add_child(pre_dive_bonus_label)

	pre_dive_curse_label = _make_wrapped_label("", 0)
	pre_dive_box.add_child(pre_dive_curse_label)

	pre_dive_curse_grid = GridContainer.new()
	pre_dive_curse_grid.columns = 2
	pre_dive_curse_grid.add_theme_constant_override("h_separation", 8)
	pre_dive_curse_grid.add_theme_constant_override("v_separation", 8)
	pre_dive_box.add_child(pre_dive_curse_grid)

	pre_dive_detail_label = _make_wrapped_label("", 0)
	pre_dive_box.add_child(pre_dive_detail_label)

	pre_dive_button_row = HBoxContainer.new()
	pre_dive_button_row.add_theme_constant_override("separation", 8)
	pre_dive_box.add_child(pre_dive_button_row)

	pre_dive_confirm_button = Button.new()
	pre_dive_confirm_button.text = "Begin Dive"
	pre_dive_confirm_button.pressed.connect(_on_pre_dive_confirm_pressed)
	pre_dive_button_row.add_child(pre_dive_confirm_button)

	pre_dive_cancel_button = Button.new()
	pre_dive_cancel_button.text = "Cancel"
	pre_dive_cancel_button.pressed.connect(_on_pre_dive_cancel_pressed)
	pre_dive_button_row.add_child(pre_dive_cancel_button)
	_apply_responsive_layout()


func _make_wrapped_label(text: String, min_width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if min_width > 0:
		label.custom_minimum_size = Vector2(min_width, 0)
	return label


func _add_section_button(parent: Control, section_id: String, title: String) -> void:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_ALL
	button.toggle_mode = true
	button.pressed.connect(_on_section_pressed.bind(section_id))
	parent.add_child(button)
	section_buttons.append(button)


func _on_section_pressed(section_id: String) -> void:
	_show_section(section_id)
	refresh_archive_panel()


func _show_section(section_id: String) -> void:
	if section_id == "":
		section_id = "archive"
	if not section_panels.has(section_id):
		section_id = "archive"
	active_section_id = section_id
	for key in section_panels.keys():
		var panel: Control = section_panels[key]
		panel.visible = str(key) == section_id
	for index in range(section_buttons.size()):
		var button: Button = section_buttons[index]
		var pressed := button.text == _section_title_for_id(section_id)
		if button.has_method("set_pressed_no_signal"):
			button.set_pressed_no_signal(pressed)
		else:
			button.button_pressed = pressed


func _section_title_for_id(section_id: String) -> String:
	match section_id:
		"archive":
			return "Archive"
		"progression":
			return "Progression"
		"pressure":
			return "Pressure"
		"curses":
			return "Curses"
		"records":
			return "Records"
		"upgrades":
			return "Upgrades"
		_:
			return "Archive"


func refresh_archive_panel() -> void:
	if app_state == null or content_db == null:
		return

	var request = app_state.get_active_request()
	if request != null:
		var active_entry: Dictionary = app_state.get_active_request_entry()
		var state := str(active_entry.get("state", "active"))
		var deadline_kind := str(active_entry.get("deadline_kind", "dive"))
		var deadline_remaining := int(active_entry.get("deadline_turns_remaining", 0))
		var deadline_total := int(active_entry.get("deadline_turns_total", 0))
		request_label.text = "Request: %s\n%s\nState: %s\nDeadline: %d/%d %s turns" % [
			request.name,
			_shorten_text(request.objective_text, 92),
			state,
			deadline_remaining,
			deadline_total,
			deadline_kind,
		]
	else:
		request_label.text = "No active request."

	essence_label.text = "Essence: %d" % app_state.get_essence()
	request_queue_label.text = app_state.get_request_queue_text()
	tracked_request_label.text = app_state.get_tracked_request_text()
	research_label.text = app_state.get_research_job_text()
	station_label.text = "Stations: %s" % app_state.get_station_layout_text()
	build_summary_label.text = app_state.get_active_build_summary_text()
	accessibility_label.text = app_state.get_accessibility_summary_text()
	pressure_label.text = app_state.get_pressure_summary_text()
	archive_label.text = _build_archive_text()
	bonus_label.text = app_state.get_archive_bonus_overview_text() if app_state.has_method("get_archive_bonus_overview_text") else app_state.get_active_archive_bonus_text()
	deck_label.text = app_state.get_active_deck_brief_text()
	deck_validation_label.text = _build_deck_validation_text()
	if text_scale_button != null:
		text_scale_button.text = "Text Size: %s" % app_state.get_text_scale_label()
	if contrast_button != null:
		contrast_button.text = "Contrast: %s" % app_state.get_contrast_mode_label()
	if palette_button != null:
		palette_button.text = "Palette: %s" % app_state.get_palette_mode_label()
	if deck_sort_button != null:
		deck_sort_button.text = "Sort Deck: %s" % app_state.get_deck_sort_mode_label()
	if archive_filter_button != null:
		archive_filter_button.text = "Archive Filter: %s" % app_state.get_archive_filter_mode_label()
	if guidance_button != null:
		guidance_button.text = "Guidance: %s" % ("On" if app_state.get_show_tooltips_enabled() else "Off")
	if app_state.has_pending_pressure_event():
		if app_state.get_show_tooltips_enabled():
			prompt_label.text = "Pressure alert: respond in the Pressure section.\n\n%s" % _shorten_text(app_state.get_pressure_summary_text(), 220)
		else:
			prompt_label.text = "Pressure alert: open the Pressure section."
	else:
		if app_state.get_show_tooltips_enabled():
			prompt_label.text = "Move near the board, desk, shelf, or entrance."
		else:
			prompt_label.text = "Move to a hub point to continue."
	_update_selection_label()
	_refresh_slot_buttons()
	_refresh_inventory_buttons()
	_refresh_deck_buttons()
	_refresh_collection_buttons()
	_refresh_reward_panel()
	_refresh_progression_panel()
	_refresh_pressure_panel()
	_refresh_curse_panel()
	_refresh_record_panel()
	_refresh_upgrade_panel()
	_refresh_pre_dive_panel()
	_apply_accessibility_settings()
	_apply_responsive_layout()


func set_request_text(text: String) -> void:
	if request_label != null:
		request_label.text = text


func set_archive_text(text: String) -> void:
	if archive_label != null:
		archive_label.text = text


func set_bonus_text(text: String) -> void:
	if bonus_label != null:
		bonus_label.text = text

func set_deck_text(text: String) -> void:
	if deck_label != null:
		deck_label.text = text


func set_prompt_text(text: String) -> void:
	if prompt_label != null:
		prompt_label.text = text


func set_message(text: String) -> void:
	if message_label != null:
		message_label.text = text


func set_request_summary_text(text: String) -> void:
	if request_queue_label != null:
		request_queue_label.text = text


func set_research_summary_text(text: String) -> void:
	if research_label != null:
		research_label.text = text


func set_station_summary_text(text: String) -> void:
	if station_label != null:
		station_label.text = text


func show_detail(title: String, body: String) -> void:
	if detail_panel != null:
		detail_panel.visible = true
		detail_title.text = title
		detail_body.text = body


func hide_detail() -> void:
	if detail_panel != null:
		detail_panel.visible = false


func _on_inspect_requests_pressed() -> void:
	if app_state == null:
		return
	show_detail("Patron Queue", "%s\n\n%s" % [app_state.get_request_queue_text(), app_state.get_research_job_text()])


func _on_start_research_pressed() -> void:
	if app_state == null:
		return
	var worked := false
	if app_state.has_active_research_job():
		worked = app_state.work_research_job()
	else:
		worked = app_state.start_research_job()
	if worked:
		show_detail("Research Started", app_state.get_research_job_text())
	else:
		show_detail("Research", "No research job is ready to begin.")
	refresh_archive_panel()


func _on_toggle_guidance_pressed() -> void:
	if app_state == null:
		return
	app_state.toggle_show_tooltips()
	refresh_archive_panel()


func _on_cycle_text_scale_pressed() -> void:
	if app_state == null:
		return
	app_state.cycle_text_scale()
	refresh_archive_panel()


func _on_cycle_contrast_pressed() -> void:
	if app_state == null:
		return
	app_state.cycle_contrast_mode()
	refresh_archive_panel()


func _on_cycle_palette_pressed() -> void:
	if app_state == null:
		return
	app_state.cycle_palette_mode()
	refresh_archive_panel()


func _on_sort_deck_pressed() -> void:
	if app_state == null:
		return
	app_state.cycle_deck_sort_mode()
	show_detail("Deck Sorted", "Deck display is now sorted by %s." % app_state.get_deck_sort_mode_label())
	refresh_archive_panel()


func _on_cycle_archive_filter_pressed() -> void:
	if app_state == null:
		return
	app_state.cycle_archive_filter_mode()
	show_detail("Archive Filter", "Archive inventory is now filtered by %s." % app_state.get_archive_filter_mode_label())
	refresh_archive_panel()


func _on_track_active_request_pressed() -> void:
	if app_state == null:
		return
	if app_state.track_active_request():
		show_detail("Request Tracked", app_state.get_tracked_request_text())
		refresh_archive_panel()


func _on_track_next_request_pressed() -> void:
	if app_state == null:
		return
	if app_state.track_next_request():
		show_detail("Request Tracked", app_state.get_tracked_request_text())
		refresh_archive_panel()


func _on_clear_tracked_request_pressed() -> void:
	if app_state == null:
		return
	if app_state.clear_tracked_request():
		show_detail("Request Tracking", "Request tracking cleared.")
		refresh_archive_panel()


func open_pre_dive_panel(request_id: String) -> void:
	if app_state == null:
		return
	if get_viewport() != null:
		pre_dive_restore_focus = get_viewport().gui_get_focus_owner()
		if pre_dive_restore_focus != null and pre_dive_panel != null and pre_dive_panel.is_ancestor_of(pre_dive_restore_focus):
			pre_dive_restore_focus = null
	pre_dive_request_id = request_id
	if _get_curse_name(selected_curse_id) == "none":
		selected_curse_id = _get_default_curse_id()
	_refresh_pre_dive_panel()
	pre_dive_panel.visible = true
	_focus_pre_dive_default_button()


func hide_pre_dive_panel() -> void:
	if pre_dive_panel != null:
		pre_dive_panel.visible = false
	pre_dive_request_id = ""
	_restore_pre_dive_focus()


func get_selected_curse_id() -> String:
	return selected_curse_id


func _on_pre_dive_confirm_pressed() -> void:
	if pre_dive_request_id == "":
		return
	pre_dive_confirmed.emit(pre_dive_request_id, selected_curse_id)
	hide_pre_dive_panel()


func _on_pre_dive_cancel_pressed() -> void:
	hide_pre_dive_panel()


func _refresh_pre_dive_panel() -> void:
	if pre_dive_panel == null or app_state == null:
		return
	var request = null
	request = app_state.get_active_request()
	if request != null:
		var objective_text := _shorten_text(str(request.objective_text), 110)
		pre_dive_request_label.text = "Request: %s\n%s\nReward: %s" % [
			str(request.name),
			objective_text,
			str(request.reward_text),
		]
	else:
		pre_dive_request_label.text = "No active request."
	if app_state.get_show_tooltips_enabled():
		pre_dive_theme_label.text = app_state.get_dungeon_theme_preview_text(pre_dive_request_id)
	else:
		pre_dive_theme_label.text = "Dungeon theme: %s" % app_state.get_dungeon_theme_name(pre_dive_request_id)
	pre_dive_bonus_label.text = app_state.get_active_archive_bonus_text()
	var curse_data: Dictionary = app_state.get_curse_selection_data()
	pre_dive_curse_label.text = "Curse family: %s\nSelected: %s" % [
		str(curse_data.get("selected_family_name", "none")),
		_get_curse_name(selected_curse_id) if selected_curse_id != "" else "none",
	]
	pre_dive_detail_label.text = _get_curse_detail_text(selected_curse_id)
	_refresh_curse_grid(pre_dive_curse_grid, true)
	_apply_responsive_layout()


func _refresh_progression_panel() -> void:
	if progression_summary_label == null:
		return
	progression_summary_label.text = _build_progression_summary_text()
	_refresh_knowledge_wings()


func _refresh_pressure_panel() -> void:
	if pressure_summary_label == null or app_state == null:
		return

	pressure_summary_label.text = app_state.get_pressure_summary_text()
	for child in pressure_button_box.get_children():
		child.queue_free()
	pressure_response_buttons.clear()

	var event: Dictionary = app_state.get_pressure_event()
	if event.is_empty():
		pressure_detail_label.text = "No active pressure event."
		pressure_button_box.add_child(_make_wrapped_label("The archive is calm for now.", 440))
		return

	var event_id := str(event.get("event_id", ""))
	var event_data: Dictionary = content_db.get_pressure_event_runtime_data(event_id)
	if event_data.is_empty():
		pressure_detail_label.text = "Unknown pressure event."
		pressure_button_box.add_child(_make_wrapped_label("Unable to inspect the event details.", 440))
		return

	var lines: Array[String] = []
	lines.append("%s" % str(event_data.get("name", event_id)))
	lines.append(str(event_data.get("description", "")))
	var source_request_id := str(event.get("source_request_id", ""))
	if source_request_id != "":
		var request = content_db.get_request(source_request_id)
		lines.append("Triggered by: %s" % str(request.name if request != null else source_request_id))
	var assets: Array = event_data.get("threat_assets", [])
	if not assets.is_empty():
		lines.append("Threatened assets: %s" % ", ".join(assets))
	pressure_detail_label.text = "\n".join(lines)

	for option in event_data.get("response_options", []):
		if typeof(option) != TYPE_DICTIONARY:
			continue
		var option_id := str(option.get("id", ""))
		if option_id == "":
			continue
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(0, 54)
		var option_text := str(option.get("name", option_id))
		var option_cost := int(option.get("essence_cost", 0))
		if option_cost > 0:
			option_text += " (%d essence)" % option_cost
		button.text = option_text
		button.pressed.connect(_on_pressure_response_pressed.bind(option_id))
		pressure_button_box.add_child(button)
		pressure_response_buttons.append(button)


func _on_pressure_response_pressed(option_id: String) -> void:
	if app_state == null:
		return
	var pressure_text: String = app_state.get_pressure_summary_text()
	if app_state.resolve_pressure_event(option_id):
		show_detail("Pressure Resolved", pressure_text)
	else:
		show_detail("Pressure Response Failed", "That response could not be applied. Check your essence or the event state.")
	refresh_archive_panel()


func _refresh_curse_panel() -> void:
	if curses_summary_label == null:
		return
	curses_summary_label.text = "Select one curse before a dive. Only one family is available in this milestone."
	_refresh_curse_grid(curse_grid, false)
	curse_detail_label.text = _get_curse_detail_text(selected_curse_id)


func _refresh_record_panel() -> void:
	if records_summary_label == null:
		return
	records_summary_label.text = _build_records_summary_text()
	for child in records_grid.get_children():
		child.queue_free()
	var lines := _build_record_entries_text()
	if lines.is_empty():
		records_grid.add_child(_make_wrapped_label("No completed request records yet.", 440))
	else:
		for line in lines:
			records_grid.add_child(_make_wrapped_label(line, 440))


func _refresh_upgrade_panel() -> void:
	if upgrade_summary_label == null:
		return
	upgrade_summary_label.text = "Preview library upgrades before spending essence. Current essence: %d." % app_state.get_essence()
	_refresh_upgrade_grid()
	upgrade_detail_label.text = _build_upgrade_detail_text(selected_upgrade_layout_id)
	if apply_upgrade_button != null:
		apply_upgrade_button.disabled = selected_upgrade_layout_id == "" or selected_upgrade_layout_id == app_state.get_station_layout_id()


func _refresh_knowledge_wings() -> void:
	if progression_grid == null:
		return
	for child in progression_grid.get_children():
		child.queue_free()
	progression_buttons.clear()

	var tag_ids: Array[String] = content_db.get_knowledge_tag_ids()
	if tag_ids.is_empty():
		progression_grid.add_child(_make_wrapped_label("No knowledge tags are available.", 440))
		return

	for tag_id in tag_ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(200, 64)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.text = _build_wing_button_text(tag_id)
		button.pressed.connect(_on_progression_wing_pressed.bind(tag_id))
		progression_grid.add_child(button)
		progression_buttons.append(button)
	if selected_progression_tag_id == "" or not tag_ids.has(selected_progression_tag_id):
		selected_progression_tag_id = tag_ids[0]
	for index in range(progression_buttons.size()):
		var button: Button = progression_buttons[index]
		button.button_pressed = index < tag_ids.size() and str(tag_ids[index]) == selected_progression_tag_id
	progression_detail_label.text = _build_wing_detail_text(selected_progression_tag_id)


func _on_progression_wing_pressed(tag_id: String) -> void:
	selected_progression_tag_id = tag_id
	progression_detail_label.text = _build_wing_detail_text(tag_id)


func _refresh_curse_grid(grid: GridContainer, pre_dive: bool) -> void:
	if grid == null:
		return
	for child in grid.get_children():
		child.queue_free()
	if not pre_dive:
		curse_buttons.clear()

	for curse in _get_curse_options():
		var curse_id := str(curse.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 64)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.text = "%s\n%s" % [str(curse.get("name", curse_id)), str(curse.get("risk", ""))]
		button.pressed.connect(_on_curse_pressed.bind(curse_id))
		grid.add_child(button)
		if not pre_dive:
			curse_buttons.append(button)
		if curse_id == selected_curse_id:
			button.button_pressed = true


func _on_curse_pressed(curse_id: String) -> void:
	selected_curse_id = curse_id
	_refresh_curse_panel()
	_refresh_pre_dive_panel()


func _refresh_upgrade_grid() -> void:
	if upgrade_grid == null:
		return
	for child in upgrade_grid.get_children():
		child.queue_free()
	upgrade_buttons.clear()

	var options: Array[Dictionary] = app_state.get_station_layout_options()
	var current_layout_id: String = app_state.get_station_layout_id()
	var option_ids: Array[String] = []
	for option in options:
		option_ids.append(str(option.get("id", "")))
	if selected_upgrade_layout_id == "" or not option_ids.has(selected_upgrade_layout_id):
		selected_upgrade_layout_id = current_layout_id
	for option in options:
		var layout_id := str(option.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 58)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.text = "%s\nCost: 1 essence" % [str(option.get("name", layout_id))]
		button.pressed.connect(_on_upgrade_preview_pressed.bind(layout_id))
		upgrade_grid.add_child(button)
		upgrade_buttons.append(button)
		if layout_id == selected_upgrade_layout_id:
			button.button_pressed = true


func _on_upgrade_preview_pressed(layout_id: String) -> void:
	selected_upgrade_layout_id = layout_id
	upgrade_detail_label.text = _build_upgrade_detail_text(layout_id)
	if apply_upgrade_button != null:
		apply_upgrade_button.disabled = layout_id == app_state.get_station_layout_id()


func _on_apply_upgrade_pressed() -> void:
	if selected_upgrade_layout_id == "":
		return
	if app_state.set_station_layout(selected_upgrade_layout_id):
		show_detail("Upgrade Applied", app_state.get_station_layout_text())
	else:
		show_detail("Upgrade Locked", "Spend 1 essence to switch layouts.")
	refresh_archive_panel()


func _on_copy_records_pressed() -> void:
	var summary := _build_copyable_record_text()
	if summary == "":
		return
	DisplayServer.clipboard_set(summary)
	show_detail("Records Copied", "Run history copied to the clipboard.")


func _on_arrange_stations_pressed() -> void:
	if app_state == null:
		return
	var options: Array[Dictionary] = app_state.get_station_layout_options()
	if options.is_empty():
		return
	var current_id: String = app_state.get_station_layout_id()
	var option_index := 0
	for index in range(options.size()):
		if str(options[index].get("id", "")) == current_id:
			option_index = index
			break
	var next_option: Dictionary = options[(option_index + 1) % options.size()]
	if app_state.set_station_layout(str(next_option.get("id", ""))):
		show_detail("Stations Rearranged", app_state.get_station_layout_text())
	else:
		show_detail("Stations", "Need 1 essence to rearrange the station layout.")
	refresh_archive_panel()


func _refresh_inventory_buttons() -> void:
	if inventory_grid == null:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
	inventory_buttons.clear()

	var inventory: Array = app_state.get_archive_inventory(app_state.get_archive_filter_mode())
	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No owned items match the current filter."
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
		item_button.tooltip_text = app_state.get_archive_item_rule_text(item_type, item_id)

		if item_type == selected_item_type and item_id == selected_item_id:
			item_button.modulate = Color(1.0, 0.95, 0.75)

		item_button.pressed.connect(_on_inventory_pressed.bind(item_type, item_id))
		inventory_grid.add_child(item_button)
		inventory_buttons.append(item_button)


func _refresh_deck_buttons() -> void:
	if deck_grid == null:
		return
	for child in deck_grid.get_children():
		child.queue_free()
	deck_buttons.clear()

	var deck_entries: Array = app_state.get_active_deck_entries()
	for index in range(deck_entries.size()):
		var entry: Dictionary = deck_entries[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(132, 74)
		button.focus_mode = Control.FOCUS_ALL
		button.text = "Slot %d\n%s" % [int(entry.get("slot_index", 0)) + 1, _shorten_text(str(entry.get("name", "")), 16)]
		button.pressed.connect(_on_deck_slot_pressed.bind(int(entry.get("slot_index", 0))))
		deck_grid.add_child(button)
		deck_buttons.append(button)

	if deck_entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active deck."
		deck_grid.add_child(empty_label)


func _refresh_collection_buttons() -> void:
	if collection_grid == null:
		return
	for child in collection_grid.get_children():
		child.queue_free()
	collection_buttons.clear()

	var collection: Array = app_state.get_card_collection()
	if collection.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No owned cards yet."
		collection_grid.add_child(empty_label)
		return

	for entry in collection:
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 68)
		button.focus_mode = Control.FOCUS_ALL
		var card_id := str(entry.get("card_id", ""))
		button.text = "%s\n%s" % [
			str(entry.get("name", card_id)),
			_short_text_from_summary(str(entry.get("summary", ""))),
		]
		if card_id == selected_collection_card_id:
			button.modulate = Color(1.0, 0.95, 0.75)
		button.pressed.connect(_on_collection_card_pressed.bind(card_id))
		collection_grid.add_child(button)
		collection_buttons.append(button)


func _refresh_reward_panel() -> void:
	if reward_panel == null:
		return

	var pending: Array = app_state.get_pending_card_reward_options()
	reward_panel.visible = not pending.is_empty()
	if pending.is_empty():
		return

	var source_text := str(app_state.save_data.get("pending_card_reward_source", "dive"))
	reward_title.text = "Pending Reward (%s)" % source_text.capitalize()
	reward_text.text = "Choose one new card to keep. The others remain locked."

	for child in reward_grid.get_children():
		child.queue_free()
	reward_buttons.clear()

	for card_id_variant in pending:
		var card_id := str(card_id_variant)
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 84)
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		var reward_summary: String = content_db.get_card_runtime_summary(card_id, app_state.get_active_archive_bonuses())
		button.text = _shorten_text(reward_summary, 56)
		button.tooltip_text = reward_summary + "\n\nChoose this card to add it to the collection."
		button.pressed.connect(_on_reward_card_pressed.bind(card_id))
		reward_grid.add_child(button)
		reward_buttons.append(button)


func _on_deck_slot_pressed(slot_index: int) -> void:
	if selected_collection_card_id == "":
		selected_deck_slot_index = slot_index
		var deck_entry := _get_deck_entry(slot_index)
		if deck_entry.is_empty():
			return
		show_detail("Deck Slot %d" % (slot_index + 1), str(deck_entry.get("summary", "")))
		return

	if app_state.set_active_deck_slot(slot_index, selected_collection_card_id):
		selected_collection_card_id = ""
		selected_deck_slot_index = -1
		_clear_selection()
		refresh_archive_panel()
	else:
		show_detail("Deck Swap Failed", "The selected card would make the deck invalid. It must keep movement, offense, defense, and utility.")


func _on_collection_card_pressed(card_id: String) -> void:
	if selected_collection_card_id == card_id:
		_clear_selection()
		return
	selected_collection_card_id = card_id
	selected_deck_slot_index = -1
	var entry: Dictionary = _get_collection_entry(card_id)
	if entry.is_empty():
		return
	show_detail(str(entry.get("name", card_id)), str(entry.get("summary", "")) + "\n\nClick a deck slot to swap this card in.")
	refresh_archive_panel()


func _on_reward_card_pressed(card_id: String) -> void:
	if app_state.choose_pending_card_reward(card_id):
		selected_reward_card_id = card_id
		show_detail("Reward Claimed", "You added %s to the collection." % _get_item_name("card", card_id))
		refresh_archive_panel()
	else:
		show_detail("Reward Failed", "That reward card is no longer available.")


func _get_deck_entry(slot_index: int) -> Dictionary:
	for entry in app_state.get_active_deck_entries():
		if int(entry.get("slot_index", -1)) == slot_index:
			return entry
	return {}


func _get_collection_entry(card_id: String) -> Dictionary:
	for entry in app_state.get_card_collection():
		if str(entry.get("card_id", "")) == card_id:
			return entry
	return {}


func _build_deck_validation_text() -> String:
	var validation: Dictionary = app_state.get_active_deck_validation()
	if bool(validation.get("valid", false)):
		return "Deck valid: movement, offense, defense, and utility are covered."
	return "Deck invalid: %s" % "; ".join(validation.get("errors", []))


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
	selected_collection_card_id = ""
	selected_deck_slot_index = -1
	selected_reward_card_id = ""
	_update_selection_label()
	refresh_archive_panel()


func _update_selection_label() -> void:
	if selected_item_label == null:
		return
	if selected_item_type != "":
		selected_item_label.text = "Selected: %s (%s)" % [_get_item_name(selected_item_type, selected_item_id), selected_item_type]
	elif selected_collection_card_id != "":
		var card_entry := _get_collection_entry(selected_collection_card_id)
		selected_item_label.text = "Selected card: %s" % str(card_entry.get("name", selected_collection_card_id))
	else:
		selected_item_label.text = "Selected: none"


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
	elif item_type == "card":
		var card = content_db.get_card(item_id)
		if card != null:
			return card.name
	return item_id


func _short_text_from_summary(summary: String) -> String:
	var first_line := summary.split("\n", false, 1)[0]
	return _shorten_text(first_line, 82)


func _apply_accessibility_settings() -> void:
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
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if info_panel == null or pre_dive_outer == null or pre_dive_curse_grid == null:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	compact_layout = viewport_size.x < 1400.0 or viewport_size.y < 820.0
	if deck_panel != null:
		# The dive HUD already exposes the active starter deck. Keep the hub's
		# collection editor out of the compact viewport so the request and
		# archive panels remain usable without horizontal clipping. A pending
		# reward is the exception: its choice must remain actionable before the
		# next dive.
		var reward_pending: bool = app_state != null and app_state.has_method("has_pending_card_reward_options") and app_state.has_pending_card_reward_options()
		if compact_layout and reward_pending and reward_panel != null and ui_overlay_root != null:
			# Pull the actionable reward out of the wide desktop Deck Lab so a
			# completed dive can always be resolved on a small viewport.
			if reward_panel.get_parent() != ui_overlay_root:
				reward_panel.get_parent().remove_child(reward_panel)
				ui_overlay_root.add_child(reward_panel)
				reward_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
			var reward_box := reward_panel.get_child(0) as Control
			if reward_box != null:
				reward_box.custom_minimum_size = Vector2.ZERO
				reward_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				for child in reward_box.get_children():
					if child is Control:
						child.custom_minimum_size.x = 0.0
			reward_panel.position = Vector2(18.0, 150.0)
			reward_panel.clip_contents = true
			reward_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			reward_panel.custom_minimum_size = Vector2(min(760.0, viewport_size.x - 36.0), 0.0)
			deck_panel.visible = false
		else:
			if reward_panel != null and reward_panel.get_parent() == ui_overlay_root and deck_box != null:
				ui_overlay_root.remove_child(reward_panel)
				deck_box.add_child(reward_panel)
				reward_panel.position = Vector2.ZERO
				reward_panel.custom_minimum_size = Vector2.ZERO
			deck_panel.visible = not compact_layout
		if deck_box != null:
			for child in deck_box.get_children():
				child.visible = not compact_layout or (reward_pending and child == reward_panel)
		if reward_text != null:
			reward_text.custom_minimum_size.x = 0.0 if compact_layout else 760.0
		if reward_grid != null:
			reward_grid.columns = 1 if compact_layout else 3
			for child in reward_grid.get_children():
				if child is Button and compact_layout:
					child.custom_minimum_size.x = min(700.0, viewport_size.x - 72.0)
		if compact_layout and reward_pending and reward_panel != null:
			# Reparenting preserves the old desktop container size; clear it so
			# the overlay recomputes from its compact children.
			reward_panel.reset_size()
			reward_panel.size = Vector2(min(760.0, viewport_size.x - 36.0), min(300.0, viewport_size.y - 180.0))
			reward_panel.set_deferred("size", Vector2(min(760.0, viewport_size.x - 36.0), min(300.0, viewport_size.y - 180.0)))
	if service_row != null:
		# These are expansion-system shortcuts. The active 0.1 loop remains
		# available through the request, archive, entrance, and touch controls;
		# hiding the wide shortcut row prevents it from forcing the whole HUD
		# beyond a small viewport.
		service_row.visible = not compact_layout

	var info_width := clampi(int(viewport_size.x * 0.24), 240, 360)
	if compact_layout:
		info_width = min(info_width, 300)
	info_panel.custom_minimum_size = Vector2(info_width, 0)

	var margin_x := 140
	var margin_y := 56
	if compact_layout:
		margin_x = 72
		margin_y = 40
	if viewport_size.x < 1024.0 or viewport_size.y < 720.0:
		margin_x = 40
		margin_y = 28
	pre_dive_outer.add_theme_constant_override("margin_left", margin_x)
	pre_dive_outer.add_theme_constant_override("margin_right", margin_x)
	pre_dive_outer.add_theme_constant_override("margin_top", margin_y)
	pre_dive_outer.add_theme_constant_override("margin_bottom", margin_y)

	pre_dive_curse_grid.columns = 1 if viewport_size.x < 1100.0 else 2

	if pre_dive_button_row != null:
		pre_dive_button_row.alignment = BoxContainer.ALIGNMENT_CENTER if compact_layout else BoxContainer.ALIGNMENT_BEGIN

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


func _focus_pre_dive_default_button() -> void:
	if pre_dive_panel == null or not pre_dive_panel.visible or pre_dive_curse_grid == null:
		return

	var selected_button: Button = null
	var first_button: Button = null
	for child in pre_dive_curse_grid.get_children():
		if child is Button:
			var button: Button = child
			if first_button == null:
				first_button = button
			if button.button_pressed:
				selected_button = button
				break

	if selected_button != null and selected_button.is_inside_tree():
		selected_button.grab_focus()
	elif first_button != null and first_button.is_inside_tree():
		first_button.grab_focus()
	elif pre_dive_confirm_button != null and pre_dive_confirm_button.is_inside_tree():
		pre_dive_confirm_button.grab_focus()


func _restore_pre_dive_focus() -> void:
	if pre_dive_restore_focus != null and is_instance_valid(pre_dive_restore_focus) and pre_dive_restore_focus.is_inside_tree():
		call_deferred("_focus_if_valid", pre_dive_restore_focus)
		pre_dive_restore_focus = null
		return

	pre_dive_restore_focus = null
	if section_buttons.is_empty():
		return

	var fallback_button: Button = section_buttons[0]
	if fallback_button != null and is_instance_valid(fallback_button) and fallback_button.is_inside_tree():
		call_deferred("_focus_if_valid", fallback_button)


func _focus_if_valid(control: Control) -> void:
	if control != null and is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()


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


func _get_default_curse_id() -> String:
	var curse_options: Array[Dictionary] = _get_curse_options()
	if curse_options.is_empty():
		return ""
	return str(curse_options[0].get("id", ""))


func _get_curse_name(curse_id: String) -> String:
	for curse in _get_curse_options():
		if str(curse.get("id", "")) == curse_id:
			return str(curse.get("name", curse_id))
	return "none"


func _get_curse_detail_text(curse_id: String) -> String:
	if curse_id == "":
		return "Choose a curse to preview the risk and reward text for the next dive."
	for curse in _get_curse_options():
		if str(curse.get("id", "")) == curse_id:
			return "%s\nRisk: %s\nReward: %s" % [
				str(curse.get("name", curse_id)),
				str(curse.get("risk", "")),
				str(curse.get("reward", "")),
			]
	return "Unknown curse selection."


func _get_curse_options() -> Array[Dictionary]:
	if app_state != null and app_state.has_method("get_available_curse_options"):
		var options: Array = app_state.get_available_curse_options()
		if not options.is_empty():
			return options
	return []


func _build_progression_summary_text() -> String:
	var request_text: String = app_state.get_request_queue_text()
	var lines: Array[String] = []
	lines.append("Archive progression uses the tag wings already present in this build.")
	lines.append("Essence: %d" % app_state.get_essence())
	lines.append("Active request queue:")
	lines.append(request_text)
	lines.append("")
	lines.append("Active archive bonuses:")
	lines.append(app_state.get_active_archive_bonus_text())
	return "\n".join(lines)


func _build_wing_button_text(tag_id: String) -> String:
	var tag: Object = content_db.get_knowledge_tag(tag_id)
	var tag_name := str(tag.name if tag != null else tag_id)
	var counts := _get_wing_item_counts(tag_id)
	return "%s\nTomes %d | Relics %d" % [tag_name, int(counts.get("tomes", 0)), int(counts.get("relics", 0))]


func _build_wing_detail_text(tag_id: String) -> String:
	var tag: Object = content_db.get_knowledge_tag(tag_id)
	if tag == null:
		return "No wing data available."
	var counts := _get_wing_item_counts(tag_id)
	var research_id := _find_research_for_tag(tag_id)
	var research_text := "No research track found."
	if research_id != "":
		var research: Dictionary = content_db.get_research_runtime_data(research_id)
		research_text = "%s\n%s" % [str(research.get("name", research_id)), str(research.get("description", ""))]
	return "%s\n%s\nOwned tomes: %d\nOwned relics: %d\nResearch preview:\n%s" % [
		str(tag.name),
		str(tag.description),
		int(counts.get("tomes", 0)),
		int(counts.get("relics", 0)),
		research_text,
	]


func _get_wing_item_counts(tag_id: String) -> Dictionary:
	var tome_count := 0
	var relic_count := 0
	for tome_id in app_state.get_archive_tomes():
		var tome = content_db.get_tome(tome_id)
		if tome != null and tome.knowledge_tags.has(tag_id):
			tome_count += 1
	for relic_id in app_state.get_archive_relics():
		var relic = content_db.get_relic(relic_id)
		if relic != null and relic.knowledge_tags.has(tag_id):
			relic_count += 1
	return {
		"tomes": tome_count,
		"relics": relic_count,
	}


func _find_research_for_tag(tag_id: String) -> String:
	for research_id in content_db.get_research_definition_ids():
		var research: Dictionary = content_db.get_research_runtime_data(research_id)
		if research.get("knowledge_tags", []).has(tag_id):
			return research_id
	return ""


func _build_records_summary_text() -> String:
	var history: Array = []
	if app_state != null:
		history = app_state.save_data.get("request_history", [])
	var completed_count := 0
	var expired_count := 0
	for entry in history:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var state := str(entry.get("state", ""))
		if state == "completed":
			completed_count += 1
		elif state == "expired":
			expired_count += 1
	var curse_text := "none selected"
	if app_state != null:
		curse_text = _get_curse_name(str(app_state.save_data.get("selected_curse_id", "")))
	if curse_text == "none":
		curse_text = "none selected"
	return "Completed records: %d\nExpired records: %d\nLast curse preview: %s\nCopyable summaries are available below." % [completed_count, expired_count, curse_text]


func _build_record_entries_text() -> Array[String]:
	var lines: Array[String] = []
	var history: Array = []
	if app_state != null:
		history = app_state.save_data.get("request_history", [])
	if history.is_empty():
		return lines
	var start_index: int = max(0, history.size() - 6)
	for index in range(start_index, history.size()):
		if typeof(history[index]) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = history[index]
		var request_id := str(entry.get("request_id", ""))
		var request: Object = content_db.get_request(request_id)
		var title := str(request.name if request != null else request_id)
		var state := str(entry.get("state", ""))
		var turn := int(entry.get("turn", 0))
		var note := str(entry.get("note", ""))
		lines.append("%s [%s] on turn %d%s" % [
			title,
			state,
			turn,
			(" - %s" % note) if note != "" else "",
		])
	return lines


func _build_copyable_record_text() -> String:
	var lines: Array[String] = []
	lines.append("Arcane Archivist records")
	lines.append("Essence: %d" % app_state.get_essence())
	lines.append("Active request: %s" % app_state.get_active_request_name())
	lines.append("Last curse preview: %s" % _get_curse_name(str(app_state.save_data.get("selected_curse_id", ""))))
	for entry_text in _build_record_entries_text():
		lines.append(entry_text)
	return "\n".join(lines)


func _build_upgrade_detail_text(layout_id: String) -> String:
	if layout_id == "":
		return "Select a layout to preview its effect."
	var options: Array[Dictionary] = app_state.get_station_layout_options()
	var current_id: String = app_state.get_station_layout_id()
	var selected: Dictionary = {}
	var current: Dictionary = {}
	for option in options:
		if str(option.get("id", "")) == layout_id:
			selected = option
		if str(option.get("id", "")) == current_id:
			current = option
	if selected.is_empty():
		return "Unknown layout."
	var current_name := str(current.get("name", current_id))
	var selected_name := str(selected.get("name", layout_id))
	return "Current: %s\nPreview: %s\n\n%s\n\nSelecting this layout will replace the current station plan." % [
		current_name,
		selected_name,
		str(selected.get("description", "")),
	]
