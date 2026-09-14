class_name LevelEditorDoorPanel
extends PanelContainer

## Inspector panel for configuring door states (locked, open, closed) and required keys.

signal door_config_changed(cfg: Dictionary)

var state_option: OptionButton
var key_input: LineEdit
var consume_check: CheckBox

func _init() -> void:
	anchor_left = 0.72
	anchor_top = 0.08
	anchor_right = 0.98
	anchor_bottom = 0.45
	visible = false

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	sb.border_width_left = 2
	sb.border_color = Color(0.8, 0.7, 0.3, 0.8)
	add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var title = Label.new()
	title.text = "🚪 Door Configuration"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var lbl_state = Label.new()
	lbl_state.text = "Initial Door State:"
	vbox.add_child(lbl_state)

	state_option = OptionButton.new()
	state_option.add_item("Closed (Unlocked)", 0)
	state_option.add_item("Closed (Locked)", 1)
	state_option.add_item("Open", 2)
	state_option.selected = 0 # Default to Closed (Unlocked)
	state_option.item_selected.connect(func(_idx): _on_state_changed())
	vbox.add_child(state_option)

	var lbl_key = Label.new()
	lbl_key.text = "Required Key Item:"
	vbox.add_child(lbl_key)

	key_input = LineEdit.new()
	key_input.text = "Iron Key"
	key_input.placeholder_text = "e.g. Iron Key, Golden Key"
	key_input.text_changed.connect(func(_t): _emit_door_config())
	vbox.add_child(key_input)

	consume_check = CheckBox.new()
	consume_check.text = "Consume Key On Unlock"
	consume_check.button_pressed = true
	consume_check.toggled.connect(func(_b): _emit_door_config())
	vbox.add_child(consume_check)

	_on_state_changed()

func _on_state_changed() -> void:
	var is_locked = (state_option.selected == 1)
	key_input.editable = is_locked
	consume_check.disabled = not is_locked
	_emit_door_config()

func _emit_door_config() -> void:
	var cfg = get_door_config()
	door_config_changed.emit(cfg)

func get_door_config() -> Dictionary:
	var sel = state_option.selected if state_option else 0
	var is_open = (sel == 2)
	var is_locked = (sel == 1)
	return {
		"is_open": is_open,
		"is_locked": is_locked,
		"required_key": key_input.text.strip_edges() if key_input else "Iron Key",
		"consumes_key": consume_check.button_pressed if consume_check else true
	}
