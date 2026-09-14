class_name LevelEditorUI
extends CanvasLayer

const LevelEditorChestPanel = preload("res://scripts/hero_quest/editor/level_editor_chest_panel.gd")
const LevelEditorDoorPanel = preload("res://scripts/hero_quest/editor/level_editor_door_panel.gd")

signal tool_selected(tool_name: String, data: Dictionary)
signal undo_pressed
signal redo_pressed
signal save_pressed
signal exit_pressed
signal discard_pressed
signal chest_config_changed(cfg: Dictionary)
signal door_config_changed(cfg: Dictionary)
signal level_name_changed(new_name: String)

var root_panel: Control
var top_bar: HBoxContainer
var category_tabs: TabContainer
var category_buttons: Array[Button] = []
var chest_panel: PanelContainer
var door_panel: PanelContainer
var room_panel: PanelContainer = null
var status_label: Label
var action_label: Label
var undo_btn: Button
var redo_btn: Button
var level_name_input: LineEdit

var active_btn: Button = null
var active_style: StyleBoxFlat
var active_cat_style: StyleBoxFlat

func _init() -> void:
	layer = 20
	_init_styles()
	_build_ui()

func _init_styles() -> void:
	active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.18, 0.38, 0.62, 0.95)
	active_style.set_border_width_all(3)
	active_style.border_color = Color(1.0, 0.84, 0.2, 1.0)
	active_style.set_corner_radius_all(4)

	active_cat_style = StyleBoxFlat.new()
	active_cat_style.bg_color = Color(0.2, 0.32, 0.48, 0.95)
	active_cat_style.border_width_left = 3
	active_cat_style.border_color = Color(1.0, 0.84, 0.2, 1.0)

func _build_ui() -> void:
	root_panel = Control.new()
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_panel)

	_build_top_bar()
	_build_palette()
	_build_chest_panel()
	_build_door_panel()
	_build_status_bar()

func _build_top_bar() -> void:
	var bar_panel = PanelContainer.new()
	bar_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_panel.custom_minimum_size = Vector2(0, 48)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.15, 0.9)
	sb.border_width_bottom = 2
	sb.border_color = Color(0.3, 0.4, 0.6, 0.8)
	bar_panel.add_theme_stylebox_override("panel", sb)
	root_panel.add_child(bar_panel)

	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	bar_panel.add_child(top_bar)

	var title = Label.new()
	title.text = "🏰 Level:"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_bar.add_child(title)

	level_name_input = LineEdit.new()
	level_name_input.text = "Untitled Level"
	level_name_input.custom_minimum_size = Vector2(200, 28)
	level_name_input.focus_mode = Control.FOCUS_CLICK
	level_name_input.text_changed.connect(func(t): level_name_changed.emit(t))
	level_name_input.text_submitted.connect(func(t): level_name_changed.emit(t))
	top_bar.add_child(level_name_input)

	action_label = Label.new()
	action_label.text = "Action: Place Stone Floor"
	action_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	top_bar.add_child(action_label)

	undo_btn = Button.new()
	undo_btn.text = "Undo (0)"
	undo_btn.focus_mode = Control.FOCUS_NONE
	undo_btn.pressed.connect(func(): undo_pressed.emit())
	top_bar.add_child(undo_btn)

	redo_btn = Button.new()
	redo_btn.text = "Redo (0)"
	redo_btn.focus_mode = Control.FOCUS_NONE
	redo_btn.pressed.connect(func(): redo_pressed.emit())
	top_bar.add_child(redo_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var save_btn = Button.new()
	save_btn.text = "💾 Save Level"
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.pressed.connect(func(): save_pressed.emit())
	top_bar.add_child(save_btn)

	var exit_btn = Button.new()
	exit_btn.text = "▶ Play / Save & Exit [TAB]"
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.pressed.connect(func(): exit_pressed.emit())
	top_bar.add_child(exit_btn)

	var discard_btn = Button.new()
	discard_btn.text = "❌ Discard & Exit [ESC]"
	discard_btn.focus_mode = Control.FOCUS_NONE
	discard_btn.pressed.connect(func(): discard_pressed.emit())
	top_bar.add_child(discard_btn)

func _build_palette() -> void:
	var side_panel = PanelContainer.new()
	side_panel.anchor_left = 0.0
	side_panel.anchor_top = 0.08
	side_panel.anchor_right = 0.32
	side_panel.anchor_bottom = 0.92
	side_panel.custom_minimum_size = Vector2(390, 0)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.92)
	sb.border_width_right = 2
	sb.border_color = Color(0.25, 0.35, 0.5, 0.8)
	side_panel.add_theme_stylebox_override("panel", sb)
	root_panel.add_child(side_panel)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 6)
	side_panel.add_child(main_hbox)

	var cat_vbox = VBoxContainer.new()
	cat_vbox.custom_minimum_size = Vector2(110, 0)
	cat_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cat_vbox.add_theme_constant_override("separation", 4)
	main_hbox.add_child(cat_vbox)

	category_tabs = TabContainer.new()
	category_tabs.tabs_visible = false
	category_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(category_tabs)

	_add_floors_tab()
	_add_walls_tab()
	_add_doors_tab()
	_add_wall_decor_tab()
	_add_floor_decor_tab()
	_add_furniture_tab()
	_add_graveyard_tab()
	_add_chests_tab()
	_add_tools_tab()

	_build_category_buttons(cat_vbox)

func _build_category_buttons(cat_vbox: VBoxContainer) -> void:
	var cat_defs = [
		{"name": "🏠 Floors", "idx": 0},
		{"name": "🧱 Walls", "idx": 1},
		{"name": "🚪 Doors", "idx": 2},
		{"name": "🖼️ Wall Decors", "idx": 3},
		{"name": "🌿 Floor Decors", "idx": 4},
		{"name": "🪑 Furniture", "idx": 5},
		{"name": "🪦 Graveyard", "idx": 6},
		{"name": "📦 Chests", "idx": 7},
		{"name": "🛠️ Tools", "idx": 8}
	]
	category_buttons.clear()
	for d in cat_defs:
		var btn = Button.new()
		btn.text = d["name"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(108, 34)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx = d["idx"]
		btn.pressed.connect(func(): _select_category(idx))
		cat_vbox.add_child(btn)
		category_buttons.append(btn)
	_select_category(0)

func _select_category(idx: int) -> void:
	category_tabs.current_tab = idx
	for i in range(category_buttons.size()):
		if i == idx:
			category_buttons[i].add_theme_stylebox_override("normal", active_cat_style)
		else:
			category_buttons[i].remove_theme_stylebox_override("normal")

func _create_grid_scroll(tab_name: String) -> GridContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	category_tabs.add_child(scroll)
	return grid

func _add_tool_button(grid: GridContainer, label: String, tool_name: String, data: Dictionary) -> void:
	var btn = Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(120, 36)
	btn.pressed.connect(func():
		_on_palette_item_clicked(tool_name, label, data, btn)
	)
	grid.add_child(btn)

func _on_palette_item_clicked(tool_name: String, label: String, data: Dictionary, btn: Button) -> void:
	if active_btn and is_instance_valid(active_btn):
		active_btn.remove_theme_stylebox_override("normal")
	active_btn = btn
	if active_btn:
		active_btn.add_theme_stylebox_override("normal", active_style)

	if chest_panel:
		chest_panel.visible = (tool_name == "chest")
	if door_panel:
		var arch_t = data.get("arch_type", "")
		door_panel.visible = (tool_name == "door" and ("door" in arch_t or "portcullis" in arch_t))
	if room_panel:
		room_panel.visible = (tool_name == "room")
	if action_label:
		if tool_name == "erase":
			action_label.text = "Action: Erase / Delete"
		elif tool_name == "room":
			action_label.text = "Action: Room & Area Manager"
		else:
			action_label.text = "Action: Place %s" % label
	tool_selected.emit(tool_name, data)

func clear_selection_highlight() -> void:
	if active_btn and is_instance_valid(active_btn):
		active_btn.remove_theme_stylebox_override("normal")
		active_btn = null
	if action_label:
		action_label.text = "Action: None (Ready)"
	if chest_panel:
		chest_panel.visible = false
	if door_panel:
		door_panel.visible = false
	if room_panel:
		room_panel.visible = false

func _add_floors_tab() -> void:
	var g = _create_grid_scroll("Floors")
	_add_tool_button(g, "Stone Floor", "floor", {"mat": "stone", "type": 1, "walkable": true})
	_add_tool_button(g, "Stone Alt", "floor", {"mat": "stone_alt", "type": 1, "walkable": true})
	_add_tool_button(g, "Chapel Floor", "floor", {"mat": "chapel", "type": 2, "walkable": true})
	_add_tool_button(g, "Wood Floor", "floor", {"mat": "wood", "type": 3, "walkable": true})
	_add_tool_button(g, "Bridge Walkway", "floor", {"mat": "bridge", "type": 4, "walkable": true})
	_add_tool_button(g, "Courtyard", "floor", {"mat": "courtyard", "type": 5, "walkable": true})
	_add_tool_button(g, "Garden Grass", "floor", {"mat": "garden_green", "type": 1, "walkable": true})
	_add_tool_button(g, "Graveyard Dirt", "floor", {"mat": "graveyard_dirt", "type": 8, "walkable": true})
	_add_tool_button(g, "Water Chasm", "floor", {"mat": "water_chasm", "type": 7, "walkable": false})

func _add_walls_tab() -> void:
	var g = _create_grid_scroll("Walls")
	_add_tool_button(g, "Stone Wall (Auto)", "wall", {"type": "modular_wall"})
	_add_tool_button(g, "Window Wall", "window", {"type": "window"})
	_add_tool_button(g, "Lower Thick Wall", "prop", {"type": "lower_wall"})

func _add_doors_tab() -> void:
	var g = _create_grid_scroll("Doors")
	_add_tool_button(g, "Wooden Door (1-Tile)", "door", {"arch_type": "wooden_door_1tile", "name": "WoodDoor1", "axis": 0})
	_add_tool_button(g, "Wooden Door (2-Tile)", "door", {"arch_type": "wooden_door_2tile", "name": "WoodDoor2", "axis": 0})
	_add_tool_button(g, "Iron Door (1-Tile)", "door", {"arch_type": "iron_door_1tile", "name": "IronDoor1", "axis": 0})
	_add_tool_button(g, "Iron Door (2-Tile)", "door", {"arch_type": "iron_door_2tile", "name": "IronDoor2", "axis": 0})
	_add_tool_button(g, "Portcullis (1-Tile)", "door", {"arch_type": "portcullis_1tile", "name": "Portcullis1", "axis": 0})
	_add_tool_button(g, "Portcullis (2-Tile)", "door", {"arch_type": "portcullis_2tile", "name": "Portcullis2", "axis": 0})
	_add_tool_button(g, "3-Tile Portal", "door", {"arch_type": "arch_3tile", "name": "Portal3", "axis": 0})
	_add_tool_button(g, "4-Tile Portal", "door", {"arch_type": "arch_4tile", "name": "Portal4", "axis": 0})
	_add_tool_button(g, "Spanning Arch", "door", {"arch_type": "arch_spanning_3tiles", "name": "SpanningGate", "axis": 0})
	_add_tool_button(g, "5-Tile Twin Arch", "door", {"arch_type": "arch_5tile_twin", "name": "TwinPortal", "axis": 0})

func _add_wall_decor_tab() -> void:
	var g = _create_grid_scroll("Wall Decors")
	_add_tool_button(g, "Wall Torch", "prop", {"type": "torch", "norm": [0, 0, 1]})
	_add_tool_button(g, "Painting (Portrait)", "prop", {"type": "painting", "index": 0})
	_add_tool_button(g, "Painting (Landscape)", "prop", {"type": "painting", "index": 1})
	_add_tool_button(g, "Painting (Crest)", "prop", {"type": "painting", "index": 2})
	_add_tool_button(g, "Painting (Icon)", "prop", {"type": "painting", "index": 3})

func _add_floor_decor_tab() -> void:
	var g = _create_grid_scroll("Floor Decors")
	_add_tool_button(g, "Red Carpet", "prop", {"type": "carpet", "mat": "cloth_red"})
	_add_tool_button(g, "Bush", "prop", {"type": "bush"})
	_add_tool_button(g, "Flower Patch", "prop", {"type": "flower_patch"})
	_add_tool_button(g, "Fountain", "prop", {"type": "fountain"})
	_add_tool_button(g, "Chimney", "prop", {"type": "chimney"})
	_add_tool_button(g, "Ancient Tree", "prop", {"type": "ancient_tree"})
	_add_tool_button(g, "Stake Torch", "prop", {"type": "torch_on_stick"})
	_add_tool_button(g, "Tower Brazier", "prop", {"type": "brazier"})
	_add_tool_button(g, "Gate Pillar", "prop", {"type": "stone_pillar"})
	_add_tool_button(g, "Cemetery Fence", "prop", {"type": "cemetery_fence"})
	_add_tool_button(g, "Iron Fence", "prop", {"type": "iron_fence"})

func _add_furniture_tab() -> void:
	var g = _create_grid_scroll("Furniture")
	_add_tool_button(g, "Golden Cross", "prop", {"type": "golden_cross"})
	_add_tool_button(g, "Church Pew (Back)", "prop", {"type": "pew", "with_back": true})
	_add_tool_button(g, "Church Bench", "prop", {"type": "pew", "with_back": false})
	_add_tool_button(g, "Hall Pillar", "prop", {"type": "pillar", "height": 4.5})
	_add_tool_button(g, "Table + Chair", "prop", {"type": "table", "has_chair": true})
	_add_tool_button(g, "Chair", "prop", {"type": "chair"})
	_add_tool_button(g, "Cupboard", "prop", {"type": "cupboard"})
	_add_tool_button(g, "Drawer", "prop", {"type": "drawer"})
	_add_tool_button(g, "Bookshelf", "prop", {"type": "bookshelf"})
	_add_tool_button(g, "Arms Shelf", "prop", {"type": "arms_shelf"})
	_add_tool_button(g, "Anvil", "prop", {"type": "anvil"})
	_add_tool_button(g, "Altar Table", "prop", {"type": "altar"})
	_add_tool_button(g, "Chapel Bell", "prop", {"type": "bell"})
	_add_tool_button(g, "Candelabra", "prop", {"type": "candelabra"})
	_add_tool_button(g, "Water Trough", "prop", {"type": "water_trough"})
	_add_tool_button(g, "Grindstone", "prop", {"type": "grindstone"})
	_add_tool_button(g, "Hay Bale", "prop", {"type": "hay_bale"})
	_add_tool_button(g, "Skeleton", "prop", {"type": "skeleton"})

func _add_graveyard_tab() -> void:
	var g = _create_grid_scroll("Graveyard")
	_add_tool_button(g, "Gothic Stele (Sharp)", "prop", {"type": "gravestone", "style": 2, "epitaph": "Rest in Peace"})
	_add_tool_button(g, "Celtic Cross Stone", "prop", {"type": "gravestone", "style": 1, "epitaph": "Rest in Peace"})
	_add_tool_button(g, "Arched Gravestone", "prop", {"type": "gravestone", "style": 0, "epitaph": "Rest in Peace"})
	_add_tool_button(g, "Weathered Stone", "prop", {"type": "gravestone", "style": 3, "epitaph": "Rest in Peace"})

func _add_chests_tab() -> void:
	var g = _create_grid_scroll("Chests & Items")
	_add_tool_button(g, "Treasure Chest", "chest", {"type": "treasure_chest"})
	_add_tool_button(g, "Floor Key", "item", {"type": "floor_key", "item_id": "iron_key"})

func _add_tools_tab() -> void:
	var g = _create_grid_scroll("Tools")
	_add_tool_button(g, "🏷️ Room / Area", "room", {})
	_add_tool_button(g, "❌ Delete / Erase", "erase", {})

func _build_chest_panel() -> void:
	chest_panel = LevelEditorChestPanel.new()
	chest_panel.chest_config_changed.connect(func(cfg): chest_config_changed.emit(cfg))
	root_panel.add_child(chest_panel)

func _build_door_panel() -> void:
	door_panel = LevelEditorDoorPanel.new()
	door_panel.door_config_changed.connect(func(cfg): door_config_changed.emit(cfg))
	root_panel.add_child(door_panel)

func set_room_panel(p_panel: PanelContainer) -> void:
	room_panel = p_panel
	if room_panel and not room_panel.is_inside_tree():
		root_panel.add_child(room_panel)

func set_level_name(p_name: String) -> void:
	if level_name_input:
		level_name_input.text = p_name

func _build_status_bar() -> void:
	var bar = PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.custom_minimum_size = Vector2(0, 32)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 0.9)
	bar.add_theme_stylebox_override("panel", sb)
	root_panel.add_child(bar)

	status_label = Label.new()
	status_label.text = "Level Editor Ready. Drag floors/walls. (ESC: Deselect / Exit without save | TAB: Save & Exit)"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	bar.add_child(status_label)

func set_status_notice(msg: String) -> void:
	if status_label:
		status_label.text = msg

func update_history_counts(undo_count: int, redo_count: int) -> void:
	if undo_btn: undo_btn.text = "Undo (%d)" % undo_count
	if redo_btn: redo_btn.text = "Redo (%d)" % redo_count
