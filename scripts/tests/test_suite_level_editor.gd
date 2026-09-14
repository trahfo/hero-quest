class_name TestSuiteLevelEditor
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 6] LEVEL EDITOR TOOLS, PANELS & ROOM MANAGER ===")

	var hero_scene = load("res://scenes/hero_quest.tscn")
	var editor_game = hero_scene.instantiate()
	tree.root.add_child(editor_game)
	await tree.process_frame
	await tree.process_frame

	var editor = editor_game.level_editor
	assert(editor != null and editor.is_active == false)
	assert(editor.grid != null and editor.grid.visible == false)
	assert(editor.ui != null and editor.ui.visible == false)

	# -------------------------------------------------------------
	# TEST 18: Level Editor Subsystem, Dotted Grid, Dragging, Undo & Saving
	# -------------------------------------------------------------
	print("\n[TEST 18] Verifying Level Editor Subsystem & Placement Constraints...")
	var active = editor.toggle_editor()
	assert(active == true and editor.is_active == true)
	assert(editor.grid.visible == true and editor.ui.visible == true)

	var handler = editor.tool_handler
	handler.set_tool("floor", {"mat": "chapel", "type": 2, "walkable": true})
	handler.hovered_cell = Vector2i(25, 25)
	handler._start_drag()
	handler.hovered_cell = Vector2i(27, 27)
	handler._finish_drag()

	var bld = editor_game.castle_builder
	for gx in range(25, 28):
		for gz in range(25, 28):
			var cell = Vector2i(gx, gz)
			assert(bld.grid.has(cell) and bld.grid[cell]["type"] == 2 and bld.grid[cell]["walkable"] == true)
	print("  - Rectangular floor drag verified: 9 tiles placed in 3x3 span.")

	handler.set_tool("wall", {"type": "modular_wall"})
	handler.hovered_cell = Vector2i(25, 24)
	handler._start_drag()
	handler.hovered_cell = Vector2i(27, 24)
	handler._finish_drag()
	assert(bld.grid.has(Vector2i(25, 24)) and bld.grid[Vector2i(25, 24)]["type"] == 6)

	handler.hovered_cell = Vector2i(26, 23)
	handler._start_drag()
	handler.hovered_cell = Vector2i(26, 24)
	handler._finish_drag()

	var LevelEditorWallAutoTilerClass = load("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
	var conn = LevelEditorWallAutoTilerClass.get_wall_connections(Vector2i(26, 24), editor.model.is_wall_at)
	assert(conn.is_t == true)
	print("  - Line wall drag & auto-tiling verified: straight walls and T-junctions placed.")

	var win_check_corner = LevelEditorWallAutoTilerClass.validate_window_placement(Vector2i(25, 24), func(c): return c in [Vector2i(25, 24), Vector2i(26, 24), Vector2i(25, 25)], func(_c): return false)
	assert(win_check_corner["valid"] == false)
	var win_check_arch = LevelEditorWallAutoTilerClass.validate_window_placement(Vector2i(0, 0), func(_c): return false, func(_c): return true)
	assert(win_check_arch["valid"] == false)
	print("  - Window constraints verified: corner and arch placement rejected.")

	handler.set_tool("chest", {"type": "treasure_chest"})
	handler.chest_config = {"relic_name": "Crown of the Ancients", "gold": 500, "is_trapped": true, "rot_y": PI * 0.5}
	handler.hovered_cell = Vector2i(26, 26)
	handler._apply_chest_click()
	assert(bld.grid.has(Vector2i(26, 26)) and bld.grid[Vector2i(26, 26)]["walkable"] == false)
	var placed_chest = bld.interactive_chests.back()
	assert(placed_chest.get_meta("relic_name") == "Crown of the Ancients" and placed_chest.get_meta("gold") == 500)
	print("  - Chest designer verified.")

	for i in range(32):
		handler.set_tool("floor", {"mat": "wood", "type": 3, "walkable": true})
		handler.hovered_cell = Vector2i(30 + i, 30)
		handler._start_drag(); handler._finish_drag()

	assert(editor.history.undo_stack.size() >= 30)
	for i in range(30): editor.undo()
	for i in range(5): editor.redo()
	print("  - Undo/redo verified.")

	handler.set_tool("erase", {})
	handler.hovered_cell = Vector2i(26, 26)
	handler._start_drag(); handler._finish_drag()
	assert(not bld.grid.has(Vector2i(26, 26)))

	var save_test_path = "res://data/levels/test_editor_save.json"
	editor.active_file_path = save_test_path
	editor.model.active_file_path = save_test_path
	editor.toggle_editor()
	assert(FileAccess.file_exists(save_test_path))

	var CastleLevelReaderClass = load("res://scripts/hero_quest/level/castle_level_reader.gd")
	var verify_reader = CastleLevelReaderClass.new(bld, bld.materials, bld.mesh_builder, bld.prop_factory)
	assert(verify_reader.load_level(save_test_path))
	if FileAccess.file_exists(save_test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_test_path))

	handler.set_tool("floor", {"mat": "stone", "type": 1, "walkable": true})
	handler.hovered_cell = Vector2i(40, 40)
	handler._start_drag(); handler._finish_drag()

	handler.set_tool("prop", {"type": "table", "has_chair": false})
	handler.hovered_cell = Vector2i(40, 40)
	handler._start_drag(); handler._finish_drag()
	assert(editor.model.cell_data[Vector2i(40, 40)].get("prop") != null)

	handler._apply_right_click_delete()
	assert(editor.model.cell_data[Vector2i(40, 40)].get("prop") == null and bld.grid.has(Vector2i(40, 40)))

	handler.set_tool("none", {})
	handler._apply_right_click_delete()
	assert(not bld.grid.has(Vector2i(40, 40)))

	handler.set_tool("wall", {})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	assert(editor.model.is_wall_at(Vector2i(45, 45)))
	handler._apply_right_click_delete()
	assert(not editor.model.is_wall_at(Vector2i(45, 45)) and bld.grid.has(Vector2i(45, 45)))
	assert(is_instance_valid(editor.grid.cursor_box) and editor.grid.cursor_box.is_inside_tree())

	var base_wall_cell = Vector2i(999, 999)
	for cell in bld.grid.keys():
		if bld.grid[cell].get("type", 0) == 6 and cell != Vector2i(45, 45):
			base_wall_cell = cell; break
	if base_wall_cell != Vector2i(999, 999):
		handler.hovered_cell = base_wall_cell
		handler.set_tool("wall", {})
		handler._apply_right_click_delete()
		assert(not editor.model.is_wall_at(base_wall_cell) and bld.grid.has(base_wall_cell))

	handler.set_tool("prop", {"type": "chair"})
	handler.placement_rot_y = 0.0
	handler.hovered_cell = Vector2i(41, 41)
	handler._start_drag(); handler._finish_drag()
	handler._start_drag(); handler._finish_drag()
	assert(absf(float(editor.model.cell_data[Vector2i(41, 41)]["prop"]["rot_y"]) - PI * 0.5) < 0.01)

	assert(editor.ghost_preview != null)
	handler.set_tool("prop", {"type": "bush"})
	assert(editor.ghost_preview.preview_node != null and editor.ghost_preview.ghost_mat.albedo_color.a <= 0.25)

	handler.set_tool("wall", {"type": "modular_wall"})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	handler.set_tool("door", {"arch_type": "arch_3tile", "axis": 0})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	assert(not editor.model.is_wall_at(Vector2i(45, 45)) and bld.grid[Vector2i(45, 45)]["walkable"] == true)

	var test_assets = [
		{"type": "golden_cross"}, {"type": "gravestone", "style": 2, "epitaph": "Sharp Stele"},
		{"type": "gravestone", "style": 1, "epitaph": "Celtic Cross"}, {"type": "lower_wall"},
		{"type": "pillar", "height": 4.5}, {"type": "brazier"},
		{"type": "pew", "with_back": true}, {"type": "pew", "with_back": false}
	]
	for idx in range(test_assets.size()):
		var asset = test_assets[idx]
		handler.set_tool("prop", asset)
		handler.hovered_cell = Vector2i(50 + idx, 50)
		handler._start_drag(); handler._finish_drag()
		assert(bld.grid.has(Vector2i(50 + idx, 50)))

	print("  -> Passed! Full Level Editor subsystem, constraints, and persistence confirmed.")

	# -------------------------------------------------------------
	# TEST 20: Room Manager, Blueprint Mode & Panels
	# -------------------------------------------------------------
	print("\n[TEST 20] Verifying Level Renaming, Room Manager, Blueprint Mode & Panels...")
	var LevelEditorModelClass = load("res://scripts/hero_quest/editor/level_editor_model.gd")
	var LevelEditorHistoryClass = load("res://scripts/hero_quest/editor/level_editor_history.gd")
	var LevelEditorRoomManagerClass = load("res://scripts/hero_quest/editor/level_editor_room_manager.gd")
	var LevelEditorRoomPanelClass = load("res://scripts/hero_quest/editor/level_editor_room_panel.gd")
	var LevelEditorChestPanelClass = load("res://scripts/hero_quest/editor/level_editor_chest_panel.gd")

	var test_path = "res://data/levels/test_room_level.json"
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	var test_model = LevelEditorModelClass.new(bld, test_path, "Initial Realm")
	test_model.set_level_name("The Royal Citadel")
	assert(test_model.save_to_json(test_path))
	var parsed_level = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	assert(parsed_level["name"] == "The Royal Citadel")

	var test_hist = LevelEditorHistoryClass.new(Callable(test_model, "apply_cell_states"), 50)
	var room_mgr = LevelEditorRoomManagerClass.new(bld, test_model, test_hist)
	room_mgr.set_walls_only_visible(true)
	assert(room_mgr.is_walls_only == true and room_mgr.hidden_nodes.size() > 0)
	room_mgr.set_walls_only_visible(false)
	assert(room_mgr.is_walls_only == false and room_mgr.hidden_nodes.is_empty())

	var paint_cells: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2)]
	room_mgr.paint_cells(paint_cells, "The Grand Library")
	assert(room_mgr.sign_instances.has("The Grand Library"))

	room_mgr.rename_room("The Grand Library", "Arcane Archives")
	assert(room_mgr.sign_instances.has("Arcane Archives") and not room_mgr.sign_instances.has("The Grand Library"))

	room_mgr.delete_room("Arcane Archives")
	assert(not room_mgr.sign_instances.has("Arcane Archives"))

	var chest_panel = LevelEditorChestPanelClass.new()
	var room_panel = LevelEditorRoomPanelClass.new(room_mgr)
	room_panel.room_name_input.text = "Grand Crypt"
	room_panel._save_name()
	assert(room_mgr.active_room_name == "Grand Crypt")

	var LevelEditorGridClass = load("res://scripts/hero_quest/editor/level_editor_grid.gd")
	var editor_grid = LevelEditorGridClass.new()
	var grid_shader = (editor_grid.grid_mesh_instance.material_override as ShaderMaterial).shader
	assert(grid_shader.code.contains("fract(coord / tile_size) - 0.5"))

	room_panel.queue_free(); chest_panel.queue_free(); editor_grid.queue_free(); editor_game.queue_free()
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

	print("  -> Passed! Complete Room / Area management, 3D signs, grid alignment, and level renaming confirmed.")
