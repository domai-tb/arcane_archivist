extends CanvasLayer
class_name HubHud

var request_label: Label
var archive_label: Label
var prompt_label: Label
var detail_panel: PanelContainer
var detail_title: Label
var detail_body: Label
var close_button: Button

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var stack := VBoxContainer.new()
	stack.position = Vector2(16, 16)
	stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(stack)

	var mode := Label.new()
	mode.name = "Mode"
	mode.text = "Hub: Arcane Archivist"
	stack.add_child(mode)

	request_label = Label.new()
	request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	request_label.custom_minimum_size = Vector2(340, 80)
	stack.add_child(request_label)

	archive_label = Label.new()
	archive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	archive_label.custom_minimum_size = Vector2(340, 72)
	stack.add_child(archive_label)

	prompt_label = Label.new()
	prompt_label.custom_minimum_size = Vector2(340, 32)
	stack.add_child(prompt_label)

	detail_panel = PanelContainer.new()
	detail_panel.visible = false
	detail_panel.anchor_left = 0.58
	detail_panel.anchor_top = 0.08
	detail_panel.anchor_right = 0.97
	detail_panel.anchor_bottom = 0.62
	root.add_child(detail_panel)

	var detail_box := VBoxContainer.new()
	detail_panel.add_child(detail_box)

	detail_title = Label.new()
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(detail_title)

	detail_body = Label.new()
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.custom_minimum_size = Vector2(320, 120)
	detail_box.add_child(detail_body)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide_detail)
	detail_box.add_child(close_button)

func set_request_text(text: String) -> void:
	request_label.text = text

func set_archive_text(text: String) -> void:
	archive_label.text = text

func set_prompt_text(text: String) -> void:
	prompt_label.text = text

func show_detail(title_text: String, body_text: String) -> void:
	detail_panel.visible = true
	detail_title.text = title_text
	detail_body.text = body_text

func hide_detail() -> void:
	detail_panel.visible = false

