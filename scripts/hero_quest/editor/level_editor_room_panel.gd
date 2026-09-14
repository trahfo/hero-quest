class_name LevelEditorRoomPanel
extends PanelContainer

signal room_mode_selected(mode: String) # "brush", "box", "erase"

var room_manager: RefCounted

var room_name_input: LineEdit
var color_btn: Button
var brush_btn: Button
var box_btn: Button
var erase_btn: Button
var room_list_vbox: VBoxContainer
var active_mode_style: StyleBoxFlat

const PRESETS: Array[String] = [
	"The Great Hall", "Throne Room", "Armory", "Library",
	"Barracks", "Treasury", "Dungeon", "The Crypt",
	"Royal Chapel", "Kitchen", "Courtyard", "Corridor"
]

func _init(p_room_manager: RefCounted = null) -> void:
	room_manager = p_room_manager
	anchor_left = 0.72
	anchor_top = 0.08
	anchor_right = 0.98
	anchor_bottom = 0.92
	visible = false

	_init_styles()
	_build_ui()

	if room_manager:
		room_manager.rooms_updated.connect(refresh_room_list)
		room_manager.active_room_changed.connect(_on_active_room_changed)
		refresh_room_list()
		_update_active_room_ui()

func _init_styles() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	sb.border_width_left = 2
	sb.border_color = Color(0.4, 0.6, 0.9, 0.85)
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_top_left = 4
	add_theme_stylebox_override("panel", sb)

	active_mode_style = StyleBoxFlat.new()
	active_mode_style.bg_color = Color(0.2, 0.4, 0.7, 0.95)
	active_mode_style.border_width_bottom = 2
	active_mode_style.border_color = Color(1.0, 0.85, 0.2, 1.0)

func _build_ui() -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	var title = Label.new()
	title.text = "🏰 Room & Area Manager"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root_vbox.add_child(title)

	var room_hbox = HBoxContainer.new()
	room_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(room_hbox)

	room_name_input = LineEdit.new()
	room_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_name_input.text = "The Great Hall"
	room_name_input.placeholder_text = "Room Name..."
	room_name_input.focus_mode = Control.FOCUS_CLICK
	room_name_input.text_submitted.connect(_on_name_submitted)
	room_hbox.add_child(room_name_input)

	color_btn = Button.new()
	color_btn.custom_minimum_size = Vector2(34, 28)
	color_btn.text = "🎨"
	color_btn.tooltip_text = "Cycle Room Color"
	color_btn.focus_mode = Control.FOCUS_NONE
	color_btn.pressed.connect(_on_cycle_color)
	room_hbox.add_child(color_btn)

	var act_hbox = HBoxContainer.new()
	act_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(act_hbox)

	var new_btn = Button.new()
	new_btn.text = "+ New"
	new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_btn.focus_mode = Control.FOCUS_NONE
	new_btn.pressed.connect(_on_new_room)
	act_hbox.add_child(new_btn)

	var rename_btn = Button.new()
	rename_btn.text = "✏️ Rename"
	rename_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rename_btn.focus_mode = Control.FOCUS_NONE
	rename_btn.pressed.connect(_on_rename_pressed)
	act_hbox.add_child(rename_btn)

	var delete_btn = Button.new()
	delete_btn.text = "🗑️ Delete"
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_btn.focus_mode = Control.FOCUS_NONE
	delete_btn.pressed.connect(_on_delete_pressed)
	act_hbox.add_child(delete_btn)

	var mode_hbox = HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(mode_hbox)

	brush_btn = Button.new()
	brush_btn.text = "🖌️ Brush"
	brush_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brush_btn.focus_mode = Control.FOCUS_NONE
	brush_btn.pressed.connect(func(): _set_mode("brush"))
	mode_hbox.add_child(brush_btn)

	box_btn = Button.new()
	box_btn.text = "⬜ Box"
	box_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_btn.focus_mode = Control.FOCUS_NONE
	box_btn.pressed.connect(func(): _set_mode("box"))
	mode_hbox.add_child(box_btn)

	erase_btn = Button.new()
	erase_btn.text = "❌ Erase"
	erase_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	erase_btn.focus_mode = Control.FOCUS_NONE
	erase_btn.pressed.connect(func(): _set_mode("erase"))
	mode_hbox.add_child(erase_btn)
	_set_mode("brush")

	var pres_lbl = Label.new()
	pres_lbl.text = "Quick Presets:"
	pres_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	root_vbox.add_child(pres_lbl)

	var pres_grid = GridContainer.new()
	pres_grid.columns = 3
	pres_grid.add_theme_constant_override("h_separation", 4)
	pres_grid.add_theme_constant_override("v_separation", 4)
	root_vbox.add_child(pres_grid)

	for p_name in PRESETS:
		var p_btn = Button.new()
		p_btn.text = p_name
		p_btn.focus_mode = Control.FOCUS_NONE
		p_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_btn.pressed.connect(func(): _select_preset(p_name))
		pres_grid.add_child(p_btn)

	var list_lbl = Label.new()
	list_lbl.text = "Existing Rooms in Level:"
	list_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	root_vbox.add_child(list_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	room_list_vbox = VBoxContainer.new()
	room_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(room_list_vbox)

	var hint = Label.new()
	hint.text = "• Click/drag tiles to paint room\n• Right-click to unassign\n• ESC to exit room mode"
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	root_vbox.add_child(hint)

func _set_mode(mode: String) -> void:
	if room_manager:
		room_manager.paint_mode = mode
	brush_btn.remove_theme_stylebox_override("normal")
	box_btn.remove_theme_stylebox_override("normal")
	erase_btn.remove_theme_stylebox_override("normal")
	match mode:
		"brush": brush_btn.add_theme_stylebox_override("normal", active_mode_style)
		"box": box_btn.add_theme_stylebox_override("normal", active_mode_style)
		"erase": erase_btn.add_theme_stylebox_override("normal", active_mode_style)
	room_mode_selected.emit(mode)

func _select_preset(p_name: String) -> void:
	if room_manager:
		room_manager.set_active_room(p_name)
	if room_name_input:
		room_name_input.text = p_name
	_update_color_btn()

func _on_name_submitted(new_text: String) -> void:
	var trimmed = new_text.strip_edges()
	if trimmed.is_empty():
		return
	if room_manager:
		room_manager.set_active_room(trimmed)
	_update_color_btn()

func _on_new_room() -> void:
	var count = 1
	var candidate = "New Room %d" % count
	if room_manager:
		var summary = room_manager.get_room_summary()
		var existing_names = []
		for s in summary: existing_names.append(s["name"])
		while candidate in existing_names:
			count += 1
			candidate = "New Room %d" % count
		room_manager.set_active_room(candidate)
	if room_name_input:
		room_name_input.text = candidate
		room_name_input.grab_focus()
		room_name_input.select_all()
	_update_color_btn()

func _on_rename_pressed() -> void:
	if not room_manager or not room_name_input:
		return
	var old_name = room_manager.active_room_name
	var new_name = room_name_input.text.strip_edges()
	if new_name != "" and new_name != old_name:
		room_manager.rename_room(old_name, new_name)

func _on_delete_pressed() -> void:
	if not room_manager:
		return
	room_manager.delete_room(room_manager.active_room_name)

func _on_cycle_color() -> void:
	if not room_manager:
		return
	room_manager.cycle_room_color(room_manager.active_room_name)
	_update_color_btn()

func _on_active_room_changed(r_name: String) -> void:
	if room_name_input:
		room_name_input.text = r_name
	_update_color_btn()

func _update_active_room_ui() -> void:
	if room_manager and room_name_input:
		room_name_input.text = room_manager.active_room_name
	_update_color_btn()

func _update_color_btn() -> void:
	if not room_manager or not color_btn:
		return
	var col = room_manager.get_room_color(room_manager.active_room_name)
	var sb = StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1, 1, 1, 0.8)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	color_btn.add_theme_stylebox_override("normal", sb)

func refresh_room_list() -> void:
	if not room_list_vbox:
		return
	for c in room_list_vbox.get_children():
		c.queue_free()

	if not room_manager:
		return
	var summary = room_manager.get_room_summary()
	if summary.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No rooms painted yet."
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		room_list_vbox.add_child(empty_lbl)
		return

	for info in summary:
		var r_name: String = info["name"]
		var count: int = info["count"]
		var col: Color = info["color"]

		var btn = Button.new()
		btn.text = "● %s (%d)" % [r_name, count]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_color_override("font_color", Color(col.r + 0.3, col.g + 0.3, col.b + 0.3, 1.0).clamp())

		var is_active = (r_name == room_manager.active_room_name)
		if is_active:
			btn.add_theme_stylebox_override("normal", active_mode_style)

		btn.pressed.connect(func():
			room_manager.set_active_room(r_name)
			refresh_room_list()
		)
		room_list_vbox.add_child(btn)
