class_name LevelEditorRoomPanel
extends PanelContainer

signal room_mode_selected(mode: String) # "brush", "box", "erase"
signal status_notice(msg: String)

var room_manager: RefCounted

var room_name_input: LineEdit
var save_btn: Button
var color_btn: Button
var active_badge_lbl: Label
var feedback_lbl: Label

var brush_btn: Button
var box_btn: Button
var erase_btn: Button
var room_list_vbox: VBoxContainer
var rooms_header_lbl: Label

var active_mode_style: StyleBoxFlat
var unsaved_save_style: StyleBoxFlat
var normal_save_style: StyleBoxFlat

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

	unsaved_save_style = StyleBoxFlat.new()
	unsaved_save_style.bg_color = Color(0.22, 0.55, 0.32, 1.0)
	unsaved_save_style.border_width_left = 1
	unsaved_save_style.border_width_top = 1
	unsaved_save_style.border_width_right = 1
	unsaved_save_style.border_width_bottom = 2
	unsaved_save_style.border_color = Color(0.6, 1.0, 0.6, 1.0)
	unsaved_save_style.corner_radius_top_left = 3
	unsaved_save_style.corner_radius_top_right = 3
	unsaved_save_style.corner_radius_bottom_right = 3
	unsaved_save_style.corner_radius_bottom_left = 3

	normal_save_style = StyleBoxFlat.new()
	normal_save_style.bg_color = Color(0.18, 0.22, 0.28, 0.9)
	normal_save_style.border_width_bottom = 1
	normal_save_style.border_color = Color(0.35, 0.45, 0.6, 0.8)
	normal_save_style.corner_radius_top_left = 3
	normal_save_style.corner_radius_top_right = 3
	normal_save_style.corner_radius_bottom_right = 3
	normal_save_style.corner_radius_bottom_left = 3

func _build_ui() -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 7)
	add_child(root_vbox)

	var title = Label.new()
	title.text = "🏰 Room & Area Manager"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(title)

	# Active Room Badge Card
	var badge_panel = PanelContainer.new()
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color(0.12, 0.15, 0.22, 0.9)
	b_sb.corner_radius_top_left = 4
	b_sb.corner_radius_top_right = 4
	b_sb.corner_radius_bottom_right = 4
	b_sb.corner_radius_bottom_left = 4
	badge_panel.add_theme_stylebox_override("panel", b_sb)
	root_vbox.add_child(badge_panel)

	var badge_hbox = HBoxContainer.new()
	badge_hbox.add_theme_constant_override("separation", 6)
	badge_panel.add_child(badge_hbox)

	color_btn = Button.new()
	color_btn.custom_minimum_size = Vector2(28, 24)
	color_btn.text = "🎨"
	color_btn.tooltip_text = "Cycle Room Color (affects tiles & 3D sign)"
	color_btn.focus_mode = Control.FOCUS_NONE
	color_btn.pressed.connect(_on_cycle_color)
	badge_hbox.add_child(color_btn)

	active_badge_lbl = Label.new()
	active_badge_lbl.text = "Active: Room 1 (0 tiles)"
	active_badge_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_badge_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	badge_hbox.add_child(active_badge_lbl)

	# Room Name Input + Save Button Row
	var name_lbl = Label.new()
	name_lbl.text = "Room Name:"
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	root_vbox.add_child(name_lbl)

	var room_hbox = HBoxContainer.new()
	room_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(room_hbox)

	room_name_input = LineEdit.new()
	room_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_name_input.text = "Room 1"
	room_name_input.placeholder_text = "Enter room name..."
	room_name_input.focus_mode = Control.FOCUS_CLICK
	room_name_input.text_submitted.connect(_on_name_submitted)
	room_name_input.text_changed.connect(_on_name_text_changed)
	room_hbox.add_child(room_name_input)

	save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.tooltip_text = "Save name (renames room, 3D sign, and all assigned tiles) [Enter]"
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.pressed.connect(_save_name)
	save_btn.add_theme_stylebox_override("normal", normal_save_style)
	room_hbox.add_child(save_btn)

	# Actions: + New Room, 🗑️ Delete Room
	var act_hbox = HBoxContainer.new()
	act_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(act_hbox)

	var new_btn = Button.new()
	new_btn.text = "+ New Room"
	new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_btn.focus_mode = Control.FOCUS_NONE
	new_btn.pressed.connect(_on_new_room)
	act_hbox.add_child(new_btn)

	var delete_btn = Button.new()
	delete_btn.text = "🗑️ Delete Room"
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_btn.focus_mode = Control.FOCUS_NONE
	delete_btn.pressed.connect(_on_delete_pressed)
	act_hbox.add_child(delete_btn)

	# Paint Modes Row
	var mode_lbl = Label.new()
	mode_lbl.text = "Painting Tool:"
	mode_lbl.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	root_vbox.add_child(mode_lbl)

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

	# Presets
	var pres_lbl = Label.new()
	pres_lbl.text = "Quick Presets:"
	pres_lbl.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
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

	# Existing Rooms in Level
	rooms_header_lbl = Label.new()
	rooms_header_lbl.text = "Rooms in Level:"
	rooms_header_lbl.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	root_vbox.add_child(rooms_header_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	room_list_vbox = VBoxContainer.new()
	room_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(room_list_vbox)

	# Inline Feedback & Shortcuts
	feedback_lbl = Label.new()
	feedback_lbl.text = "• Click / drag tiles to paint\n• Enter / 💾 Save to rename\n• 3D signs appear in room center"
	feedback_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8))
	feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	root_vbox.add_child(feedback_lbl)

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
	if room_name_input:
		room_name_input.text = p_name
	_save_name()

func _on_name_text_changed(new_text: String) -> void:
	_update_save_btn_state()

func _on_name_submitted(new_text: String) -> void:
	_save_name()

func _save_name() -> void:
	if not room_manager or not room_name_input:
		return
	var res = room_manager.save_or_rename_active_room(room_name_input.text)
	if res.get("success", false):
		_update_active_room_ui()
		refresh_room_list()
		_update_feedback(res.get("message", ""))
	else:
		_update_feedback("⚠ " + res.get("message", "Could not save room name."))
	_update_save_btn_state()

func _update_save_btn_state() -> void:
	if not save_btn or not room_name_input or not room_manager:
		return
	var cur_text = room_name_input.text.strip_edges()
	var act_name = room_manager.active_room_name
	var has_diff = (!cur_text.is_empty() and cur_text != act_name)
	if has_diff:
		save_btn.add_theme_stylebox_override("normal", unsaved_save_style)
		save_btn.text = "💾 Save *"
	else:
		save_btn.add_theme_stylebox_override("normal", normal_save_style)
		save_btn.text = "💾 Save"

func _on_new_room() -> void:
	var count = 1
	var candidate = "Room %d" % count
	if room_manager:
		var summary = room_manager.get_room_summary()
		var existing_names = []
		for s in summary: existing_names.append(s["name"])
		while candidate in existing_names:
			count += 1
			candidate = "Room %d" % count
		room_manager.set_active_room(candidate)
	if room_name_input:
		room_name_input.text = candidate
		room_name_input.grab_focus()
		room_name_input.select_all()
	_update_active_room_ui()
	_update_save_btn_state()
	_update_feedback("Created new room '%s'. Type name and paint tiles." % candidate)

func _on_delete_pressed() -> void:
	if not room_manager:
		return
	var old = room_manager.active_room_name
	room_manager.delete_room(old)
	_update_feedback("Deleted room '%s' and cleared its tile assignment." % old)
	_update_active_room_ui()

func _on_cycle_color() -> void:
	if not room_manager:
		return
	room_manager.cycle_room_color(room_manager.active_room_name)
	_update_color_btn()
	_update_active_room_ui()

func _on_active_room_changed(r_name: String) -> void:
	_update_active_room_ui()

func _update_active_room_ui() -> void:
	if not room_manager:
		return
	var act_name = room_manager.active_room_name
	if room_name_input and room_name_input.text != act_name:
		room_name_input.text = act_name
	var cnt = room_manager.get_room_tile_count(act_name)
	if active_badge_lbl:
		active_badge_lbl.text = "%s (%d tiles)" % [act_name, cnt]
	_update_color_btn()
	_update_save_btn_state()

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

func _update_feedback(msg: String) -> void:
	if feedback_lbl:
		feedback_lbl.text = msg
	status_notice.emit(msg)

func refresh_room_list() -> void:
	if not room_list_vbox:
		return
	for c in room_list_vbox.get_children():
		c.queue_free()

	if not room_manager:
		return
	var summary = room_manager.get_room_summary()
	if rooms_header_lbl:
		rooms_header_lbl.text = "Rooms in Level (%d):" % summary.size()

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
			_update_active_room_ui()
			refresh_room_list()
		)
		room_list_vbox.add_child(btn)
