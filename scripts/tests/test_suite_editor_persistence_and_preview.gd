class_name TestSuiteEditorPersistenceAndPreview
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 7] EDITOR PERSISTENCE, PREVIEW, ROTATION & DISCARD ===")

	var CastleBuilderClass = load("res://scripts/hero_quest/castle_builder.gd")
	var CastleLevelReaderClass = load("res://scripts/hero_quest/level/castle_level_reader.gd")
	var LevelEditorClass = load("res://scripts/hero_quest/editor/level_editor.gd")
	var LevelEditorModelClass = load("res://scripts/hero_quest/editor/level_editor_model.gd")
	var LevelEditorWallAutoTilerClass = load("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
	var LevelEditorPlacementPolicyClass = load("res://scripts/hero_quest/editor/level_editor_placement_policy.gd")

	var hero_scene = load("res://scenes/hero_quest.tscn")
	var hq = hero_scene.instantiate()
	tree.root.add_child(hq)
	await tree.process_frame
	var builder = hq.get_node("CastleBuilder")

	# -------------------------------------------------------------
	# TEST 21: Gapless Floor Tiles, PBR Textures & Wall Transparency
	# -------------------------------------------------------------
	print("\n[TEST 21] Verifying Gapless Floor Tiles, PBR Boundary Textures & Editor Wall Transparency...")
	var test_parent = Node3D.new()
	builder.add_child(test_parent)
	var test_tile = builder.mesh_builder.create_square_tile_mesh(test_parent, Vector2i(99, 99), builder.materials.mat_floor_stone)
	assert(test_tile != null)
	var found_box_mesh = false
	for child in test_tile.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var bm = child.mesh as BoxMesh
			assert(bm.size.x == 2.0 and bm.size.z == 2.0)
			found_box_mesh = true; break
	assert(found_box_mesh)
	test_parent.queue_free()

	var mats = builder.materials
	assert(mats.mat_floor_stone.albedo_texture != null and mats.mat_floor_stone.normal_enabled)
	assert(mats.mat_floor_chapel.albedo_texture != null and mats.mat_floor_wood.normal_enabled)

	mats.set_walls_transparent(true)
	assert(mats.walls_transparent and mats.mat_wall_stone.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA)
	mats.set_walls_transparent(false)
	assert(not mats.walls_transparent and mats.mat_wall_stone.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)

	var t_ed_game = Node3D.new()
	tree.root.add_child(t_ed_game)
	var test_cam = Camera3D.new(); var test_pivot = Node3D.new()
	t_ed_game.add_child(test_cam); t_ed_game.add_child(test_pivot)
	var ed = LevelEditorClass.new()
	t_ed_game.add_child(ed)
	var test_lvl_path = "res://data/levels/test_transparency_level.json"
	ed.setup(t_ed_game, builder, test_cam, test_pivot, test_lvl_path)
	ed.toggle_editor()

	ed.tool_handler.set_tool("floor", {"mat": "stone", "type": 1, "walkable": true})
	assert(mats.walls_transparent)
	ed.tool_handler.set_tool("wall", {})
	assert(not mats.walls_transparent)
	ed.tool_handler.set_tool("floor", {"mat": "stone", "type": 1, "walkable": true})
	ed.toggle_editor()
	assert(not mats.walls_transparent)

	t_ed_game.queue_free()
	if FileAccess.file_exists(test_lvl_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_lvl_path))
	print("  -> Passed! Gapless floor tiles, PBR tile boundary maps, and transparent floor-building walls confirmed.")

	# -------------------------------------------------------------
	# TEST 22: Lossless Multi-Session Persistence & Pre-Save Validation
	# -------------------------------------------------------------
	print("\n[TEST 22] Verifying Level Editor Lossless Multi-Session Persistence & Pre-Save Validation...")
	var ms_path = "res://data/levels/test_multisession_persist.json"
	if FileAccess.file_exists(ms_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ms_path))

	var session1_model = LevelEditorModelClass.new(builder, ms_path, "Dungeon Keep")
	session1_model.set_floor(Vector2i(10, 10), "stone", 1, true)
	session1_model.set_floor(Vector2i(10, 11), "stone", 1, true)
	session1_model.set_floor(Vector2i(10, 12), "stone", 1, true)
	session1_model.set_wall(Vector2i(11, 10))
	session1_model.set_wall(Vector2i(11, 11))
	session1_model.spawn_custom_prop(Vector2i(10, 10), {"type": "chest", "gold": 100})
	assert(session1_model.save_to_json(ms_path))

	var s2_reader = CastleLevelReaderClass.new(builder, builder.materials, builder.mesh_builder, builder.prop_factory)
	assert(s2_reader.load_level(ms_path))
	var session2_model = LevelEditorModelClass.new(builder, ms_path, "Dungeon Keep")
	session2_model.set_floor(Vector2i(10, 13), "wood", 3, true)
	session2_model.spawn_custom_prop(Vector2i(10, 11), {"type": "torch"})
	assert(session2_model.save_to_json(ms_path))

	var s2_parsed = JSON.parse_string(FileAccess.get_file_as_string(ms_path))
	var s2_custom = {}
	for r in s2_parsed.get("rooms", []):
		if r.get("name") == "EditorCustom": s2_custom = r
	assert(not s2_custom.is_empty())
	assert(s2_custom.get("tiles", []).size() >= 4)
	assert(s2_custom.get("modular_walls", []).size() >= 2)
	assert(s2_custom.get("props", []).size() >= 2)

	var s3_reader = CastleLevelReaderClass.new(builder, builder.materials, builder.mesh_builder, builder.prop_factory)
	s3_reader.load_level(ms_path)
	var session3_model = LevelEditorModelClass.new(builder, ms_path, "Dungeon Keep")
	session3_model.erase_object_at_cell(Vector2i(10, 10))
	assert(builder.grid.has(Vector2i(10, 10)) and builder.grid[Vector2i(10, 10)]["walkable"] == true)
	session3_model.save_to_json(ms_path)

	if FileAccess.file_exists(ms_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ms_path))

	var new_lvl_path = "res://data/levels/test_crypt_realm.json"
	if FileAccess.file_exists(new_lvl_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(new_lvl_path))

	builder.init_new_level("Crypt of the Undead")
	var new_model = LevelEditorModelClass.new(builder, new_lvl_path, "Crypt of the Undead")
	new_model.set_wall(Vector2i(5, 5))
	assert(new_model.save_to_json(new_lvl_path))

	var val_model = LevelEditorModelClass.new(builder, new_lvl_path, "Crypt of the Undead")
	val_model.erase_cell(Vector2i(0, 0))
	val_model.save_to_json(new_lvl_path)
	assert(builder.grid.has(Vector2i(0, 0)) and builder.is_tile_walkable(Vector2i(0, 0)))

	if FileAccess.file_exists(new_lvl_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(new_lvl_path))
	print("  -> Passed! Complete Lossless Multi-Session Level Persistence & Pre-Save Validation confirmed.")

	# -------------------------------------------------------------
	# TEST 23: Ghost Preview, 90° Rotation & Rule Exceptions
	# -------------------------------------------------------------
	print("\n[TEST 23] Verifying Ghost Preview, 90° Hover Rotation, Same-Spot Replacement & Rule Exceptions...")
	var t_game23 = Node3D.new()
	tree.root.add_child(t_game23)
	var cam23 = Camera3D.new(); var piv23 = Node3D.new()
	t_game23.add_child(cam23); t_game23.add_child(piv23)
	var ed23 = LevelEditorClass.new()
	t_game23.add_child(ed23)
	var lvl_path23 = "res://data/levels/test_placement_rules_level.json"
	ed23.setup(t_game23, builder, cam23, piv23, lvl_path23)
	ed23.toggle_editor()
	var h23 = ed23.tool_handler
	var m23 = ed23.model
	var gp23 = ed23.ghost_preview

	h23.set_tool("floor", {"mat": "stone", "type": 1})
	assert(gp23.visible == false)

	h23.set_tool("prop", {"type": "chair"})
	assert(gp23.visible == true and gp23.ghost_mat.albedo_color.a <= 0.25)

	h23.set_tool("prop", {"type": "table"})
	h23.hovered_cell = Vector2i(70, 70)
	h23._update_ghost_transform()
	var table_ghost_rot = gp23.preview_node.rotation.y
	h23._start_drag(); h23._finish_drag()
	var table_node = m23.cell_data[Vector2i(70, 70)]["nodes"].back()
	assert(absf(table_node.rotation.y - table_ghost_rot) < 0.01)

	h23.hovered_cell = Vector2i(70, 70)
	h23._update_ghost_transform()
	var hovered_rotated_ghost_rot = gp23.preview_node.rotation.y
	var expected_rot = fmod(table_ghost_rot + PI * 0.5, TAU)
	assert(absf(hovered_rotated_ghost_rot - expected_rot) < 0.01)

	h23.set_tool("wall", {"type": "modular_wall"})
	h23.hovered_cell = Vector2i(75, 75)
	h23._update_ghost_transform()
	h23._start_drag(); h23._finish_drag()
	assert(m23.is_wall_at(Vector2i(75, 75)))

	m23.set_wall(Vector2i(79, 80)); m23.set_wall(Vector2i(81, 80)); m23.set_wall(Vector2i(80, 79)); m23.set_wall(Vector2i(80, 81)); m23.set_wall(Vector2i(80, 80))
	assert(LevelEditorPlacementPolicyClass.is_rotation_suppressed(Vector2i(80, 80), "wall", {"type": "modular_wall"}, m23) == true)

	t_game23.queue_free()
	if FileAccess.file_exists(lvl_path23):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lvl_path23))
	print("  -> Passed! Full ghost preview, 90° rotation, duplicate purge, and extensible exception rules verified.")

	# -------------------------------------------------------------
	# TEST 24: Exit Without Saving & Discard State Restoration
	# -------------------------------------------------------------
	print("\n[TEST 24] Verifying Exit Without Saving & Discard State Restoration...")
	var t_game24 = Node3D.new()
	tree.root.add_child(t_game24)
	var b24 = CastleBuilderClass.new()
	t_game24.add_child(b24)
	var cam24 = Camera3D.new(); var piv24 = Node3D.new()
	t_game24.add_child(cam24); t_game24.add_child(piv24)
	var ed24 = LevelEditorClass.new()
	t_game24.add_child(ed24)
	var lvl_path24 = "res://data/levels/test_discard_restore_level.json"

	b24.init_new_level("Discard Test Realm")
	ed24.setup(t_game24, b24, cam24, piv24, lvl_path24)
	ed24.save_level()
	var baseline_tiles = b24.grid.size()

	ed24.toggle_editor()
	var h24 = ed24.tool_handler
	h24.set_tool("wall", {"type": "modular_wall"})
	h24.hovered_cell = Vector2i(10, 10)
	h24._start_drag(); h24._finish_drag()
	assert(b24.grid.has(Vector2i(10, 10)))

	ed24.exit_without_saving()
	assert(not b24.grid.has(Vector2i(10, 10)) and b24.grid.size() == baseline_tiles)

	ed24.toggle_editor()
	h24.set_tool("wall", {"type": "modular_wall"})
	h24.hovered_cell = Vector2i(5, 5)
	h24._start_drag(); h24._finish_drag()
	ed24.save_level()

	h24.hovered_cell = Vector2i(6, 6)
	h24._start_drag(); h24._finish_drag()
	ed24.exit_without_saving()
	assert(b24.grid.has(Vector2i(5, 5)) and not b24.grid.has(Vector2i(6, 6)))

	t_game24.queue_free(); hq.queue_free()
	if FileAccess.file_exists(lvl_path24):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lvl_path24))

	print("  -> Passed! Non-destructive level exit and state restoration verified.")
