class_name TestSuiteDoorsAndInteractions
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 5] DOORS, KEYS, CHIMNEY & CONTEXTUAL INTERACTIONS ===")

	var CastleDoorBuilderClass = load("res://scripts/hero_quest/castle_door_builder.gd")
	var HeroQuestDoorClass = load("res://scripts/hero_quest/hero_quest_door.gd")
	var CastleMaterialsClass = load("res://scripts/hero_quest/castle_materials.gd")
	var ItemDatabaseClass = load("res://scripts/hero_quest/item_database.gd")
	var HeroInventoryClass = load("res://scripts/hero_quest/hero_inventory.gd")
	var LevelEditorClass = load("res://scripts/hero_quest/editor/level_editor.gd")
	var CastleLevelReaderClass = load("res://scripts/hero_quest/level/castle_level_reader.gd")
	var HeroBoxScene = load("res://scenes/hero_quest/hero_box.tscn")

	var t_mats = CastleMaterialsClass.new()
	var door_bld = CastleDoorBuilderClass.new(t_mats)
	var tp25 = Node3D.new()
	tree.root.add_child(tp25)

	# -------------------------------------------------------------
	# TEST 25: Test Door Types, Interactive Locked/Open States, Keys, and Persistence
	# -------------------------------------------------------------
	print("\n[TEST 25] Verifying Door Types, Locked/Open States, Key Inventory & Persistence...")
	var res_wood1 = door_bld.build_wooden_door_1tile(tp25, 0)
	assert(res_wood1.has("pivots") and res_wood1["pivots"].size() == 1)
	assert(res_wood1["is_slide"] == false)

	var res_wood2 = door_bld.build_wooden_door_2tile(tp25, 0)
	assert(res_wood2.has("pivots") and res_wood2["pivots"].size() == 2)

	var res_iron1 = door_bld.build_iron_door_1tile(tp25, 0)
	assert(res_iron1.has("pivots") and res_iron1["pivots"].size() == 1)

	var res_iron2 = door_bld.build_iron_door_2tile(tp25, 0)
	assert(res_iron2.has("pivots") and res_iron2["pivots"].size() == 2)

	var res_port1 = door_bld.build_portcullis(tp25, 1, 0)
	assert(res_port1.has("pivots") and res_port1["pivots"].size() == 1 and res_port1["is_slide"])

	var res_port2 = door_bld.build_portcullis(tp25, 2, 0)
	assert(res_port2.has("pivots") and res_port2["pivots"].size() == 1 and res_port2["is_slide"])
	print("  - Procedural door geometry verified for all 6 door variants.")

	var iron_key = ItemDatabaseClass.create_item("iron_key")
	assert(iron_key != null and iron_key.name == "Iron Key")

	var mock_builder = Node3D.new()
	mock_builder.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	mock_builder.materials = t_mats
	mock_builder.grid = { Vector2i(10, 10): {"walkable": false, "type": 1, "prop": null} }
	tp25.add_child(mock_builder)

	var door_obj = HeroQuestDoorClass.new()
	tp25.add_child(door_obj)
	var door_info = {
		"type": "wooden_door_1tile", "cell": Vector2i(10, 10), "axis": 0,
		"is_open": false, "is_locked": true, "required_key": "Iron Key", "consumes_key": true
	}
	var wood_pivots: Array[Node3D] = []
	wood_pivots.assign(res_wood1["pivots"])
	door_obj.setup(mock_builder, null, door_info, wood_pivots, false)

	var mock_player = Node3D.new()
	var mock_scr = GDScript.new()
	mock_scr.source_code = "extends Node3D\nvar inventory = null\n"
	mock_scr.reload()
	mock_player.set_script(mock_scr)
	var mock_inv = HeroInventoryClass.new()
	mock_player.inventory = mock_inv

	var locked_notice = door_obj.on_door_interacted(mock_player, null)
	assert(locked_notice.to_lower().contains("locked") and door_obj.is_open == false)

	mock_inv.add_to_first_rucksack_slot(iron_key)
	var unlock_notice = door_obj.on_door_interacted(mock_player, null)
	assert(unlock_notice.to_lower().contains("unlocked") and door_obj.is_open == true)
	assert(mock_builder.grid[Vector2i(10, 10)]["walkable"] == true)

	door_obj.on_door_interacted(mock_player, null)
	assert(door_obj.is_open == false and mock_builder.grid[Vector2i(10, 10)]["walkable"] == false)
	door_obj.on_door_interacted(mock_player, null)
	assert(door_obj.is_open == true and mock_builder.grid[Vector2i(10, 10)]["walkable"] == true)

	var port_obj = HeroQuestDoorClass.new()
	tp25.add_child(port_obj)
	var port_pivots: Array[Node3D] = []
	port_pivots.assign(res_port1["pivots"])
	port_obj.setup(mock_builder, null, {"type": "portcullis_1tile", "cell": Vector2i(11, 11), "is_open": false}, port_pivots, true)
	assert(absf(res_port1["pivots"][0].position.y - 0.0) < 0.01)
	port_obj.set_open(true, false)
	assert(absf(res_port1["pivots"][0].position.y - 3.2) < 0.01)

	var t_game25 = Node3D.new()
	var b25 = Node3D.new()
	b25.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	var cam25 = Camera3D.new()
	var piv25 = Node3D.new(); piv25.add_child(cam25)
	t_game25.add_child(b25); t_game25.add_child(piv25)
	tree.root.add_child(t_game25)
	b25.init_new_level("Doors Test Realm")
	var ed25 = LevelEditorClass.new()
	t_game25.add_child(ed25)
	var lvl_path25 = "res://data/levels/test_doors_persistence.json"
	ed25.setup(t_game25, b25, cam25, piv25, lvl_path25)
	ed25.toggle_editor()

	var h25 = ed25.tool_handler
	h25.set_tool("door", {"arch_type": "wooden_door_1tile", "axis": 0})
	h25.door_config = {"is_open": false, "is_locked": true, "required_key": "Iron Key"}
	h25.hovered_cell = Vector2i(10, 10)
	h25._start_drag(); h25._finish_drag()

	h25.set_tool("door", {"arch_type": "iron_door_2tile", "axis": 0})
	h25.door_config = {"is_open": true, "is_locked": false, "required_key": ""}
	h25.hovered_cell = Vector2i(15, 10)
	h25._start_drag(); h25._finish_drag()

	h25.set_tool("item", {"item_id": "iron_key"})
	h25.hovered_cell = Vector2i(12, 10)
	h25._start_drag(); h25._finish_drag()

	ed25.save_level()
	assert(FileAccess.file_exists(lvl_path25))

	var reload_parent = Node3D.new()
	var reload_builder = Node3D.new()
	reload_builder.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	reload_parent.add_child(reload_builder)
	tree.root.add_child(reload_parent)
	var reader = CastleLevelReaderClass.new(reload_builder, t_mats, ed25.model.mesh_builder, ed25.model.prop_factory)
	var ok = reader.load_level(lvl_path25)
	assert(ok)
	assert(reload_builder.grid[Vector2i(10, 10)]["walkable"] == false)
	assert(reload_builder.grid[Vector2i(15, 10)]["walkable"] == true)

	t_game25.queue_free(); reload_parent.queue_free(); tp25.queue_free()
	if FileAccess.file_exists(lvl_path25):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lvl_path25))

	# -------------------------------------------------------------
	# TEST 29: Unlocked Door Interaction, Chimney Plate & Connections
	# -------------------------------------------------------------
	print("\n[TEST 29] Verifying Unlocked Door HeroBox Interaction, Chimney Plate Height, Window Erasure & Connections...")
	var t29_root = Node3D.new()
	tree.root.add_child(t29_root)

	var t29_builder = Node3D.new()
	t29_builder.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	t29_builder.materials = t_mats
	t29_root.add_child(t29_builder)

	t29_builder.register_tile(Vector2i(5, 5), 1, true, "Hall")
	t29_builder.register_tile(Vector2i(5, 4), 1, false, "Doorway")
	var t29_door_arch = Node3D.new()
	t29_door_arch.name = "UnlockedWoodenDoor"
	t29_root.add_child(t29_door_arch)
	t29_builder.grid[Vector2i(5, 4)]["prop"] = t29_door_arch

	var fresh_wood = door_bld.build_wooden_door_1tile(t29_door_arch, 0)
	var t29_door_ctrl = HeroQuestDoorClass.new()
	t29_door_ctrl.name = "DoorController"
	t29_door_arch.add_child(t29_door_ctrl)
	var t29_pivots: Array[Node3D] = []
	t29_pivots.assign(fresh_wood["pivots"])
	t29_door_ctrl.setup(t29_builder, null, {"type": "wooden_door_1tile", "cell": Vector2i(5, 4), "axis": 0, "is_open": false, "is_locked": false}, t29_pivots, false)

	var t29_hero = HeroBoxScene.instantiate()
	t29_root.add_child(t29_hero)
	t29_hero.setup(t29_builder, null, Vector2i(5, 5))
	t29_hero.facing_dir = Vector2i(0, -1)
	t29_hero._check_interaction_proximity()

	assert(t29_hero.nearby_interactable_node != null and t29_hero.nearby_interactable_comp != null)
	assert(t29_hero.nearby_interactable_comp.get_prompt_text().to_lower().contains("open door"))

	t29_hero._try_interact()
	assert(t29_door_ctrl.is_open == true and t29_builder.grid[Vector2i(5, 4)]["walkable"] == true)

	t29_hero._try_interact()
	assert(t29_door_ctrl.is_open == false and t29_builder.grid[Vector2i(5, 4)]["walkable"] == false)

	var DecorFactoryClass = load("res://scripts/hero_quest/castle_decoration_factory.gd")
	var decor_fact = DecorFactoryClass.new(t_mats, t29_builder.grid_to_world)
	var fireplace = decor_fact.create_chimney_fireplace(t29_root, Vector3.ZERO)
	var cavity_found = false
	for ch in fireplace.get_children():
		if ch is MeshInstance3D and ch.mesh is BoxMesh:
			var bm = ch.mesh as BoxMesh
			if absf(bm.size.x - 1.8) < 0.05 and absf(bm.size.z - 0.9) < 0.05:
				cavity_found = true
				assert(bm.size.y <= 0.51 and ch.position.y <= 0.26)
	assert(cavity_found)

	var cam29 = Camera3D.new()
	var piv29 = Node3D.new(); piv29.add_child(cam29)
	t29_root.add_child(piv29)

	var ed29 = LevelEditorClass.new()
	t29_root.add_child(ed29)
	var lvl_path29 = "res://data/levels/test_window_edit.json"
	ed29.setup(t29_root, t29_builder, cam29, piv29, lvl_path29)
	ed29.toggle_editor()
	var h29 = ed29.tool_handler

	h29.set_tool("window", {"type": "window"})
	h29.hovered_cell = Vector2i(6, 6)
	h29._start_drag(); h29._finish_drag()
	assert(ed29.model.cell_data[Vector2i(6, 6)]["wall"]["type"] == "window")

	h29.set_tool("wall", {"type": "modular"})
	h29.hovered_cell = Vector2i(6, 6)
	h29._apply_right_click_delete()
	assert(ed29.model.cell_data[Vector2i(6, 6)]["wall"] == null)

	h29.set_tool("door", {"arch_type": "wooden_door_1tile", "axis": 0})
	h29.hovered_cell = Vector2i(8, 8)
	h29._start_drag(); h29._finish_drag()

	h29.set_tool("wall", {"type": "modular"})
	h29.hovered_cell = Vector2i(7, 8)
	h29._start_drag(); h29._finish_drag()
	assert(ed29.model.cell_data[Vector2i(7, 8)]["wall"]["right"] == true)

	h29.set_tool("wall", {"type": "modular"})
	h29.hovered_cell = Vector2i(10, 10)
	h29._start_drag(); h29._finish_drag()

	h29.set_tool("prop", {"type": "torch", "norm": [0, 0, 1]})
	h29.hovered_cell = Vector2i(10, 10)
	h29._start_drag(); h29._finish_drag()
	assert(ed29.model.cell_data[Vector2i(10, 10)]["prop"] != null and ed29.model.is_wall_at(Vector2i(10, 10)))

	h29.set_tool("none")
	h29.hovered_cell = Vector2i(10, 10)
	h29._apply_right_click_delete()
	assert(ed29.model.cell_data[Vector2i(10, 10)]["prop"] == null and ed29.model.is_wall_at(Vector2i(10, 10)))

	h29._apply_right_click_delete()
	assert(ed29.model.cell_data[Vector2i(10, 10)]["wall"] == null and not ed29.model.is_wall_at(Vector2i(10, 10)))

	t29_root.queue_free()
	if FileAccess.file_exists(lvl_path29):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lvl_path29))

	print("  -> Passed! Unlocked door interaction, chimney plate, window erasing, wall-door connections & wall decos confirmed.")
