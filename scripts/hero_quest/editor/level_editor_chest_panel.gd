class_name LevelEditorChestPanel
extends PanelContainer

signal chest_config_changed(cfg: Dictionary)

var relic_input: LineEdit
var gold_input: SpinBox
var trap_check: CheckBox

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
	title.text = "📦 Chest Config"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	relic_input = LineEdit.new()
	relic_input.text = "Gold Relic of the King"
	relic_input.focus_mode = Control.FOCUS_CLICK
	relic_input.text_changed.connect(func(_t): _emit_chest_config())
	vbox.add_child(relic_input)

	gold_input = SpinBox.new()
	gold_input.min_value = 0
	gold_input.max_value = 5000
	gold_input.value = 100
	gold_input.focus_mode = Control.FOCUS_CLICK
	gold_input.value_changed.connect(func(_v): _emit_chest_config())
	vbox.add_child(gold_input)

	trap_check = CheckBox.new()
	trap_check.text = "Is Trapped"
	trap_check.focus_mode = Control.FOCUS_NONE
	trap_check.toggled.connect(func(_b): _emit_chest_config())
	vbox.add_child(trap_check)

func _emit_chest_config() -> void:
	var cfg = {
		"relic_name": relic_input.text,
		"gold": int(gold_input.value),
		"is_trapped": trap_check.button_pressed
	}
	chest_config_changed.emit(cfg)

func get_chest_config() -> Dictionary:
	return {
		"relic_name": relic_input.text if relic_input else "Gold Relic",
		"gold": int(gold_input.value) if gold_input else 100,
		"is_trapped": trap_check.button_pressed if trap_check else false
	}
