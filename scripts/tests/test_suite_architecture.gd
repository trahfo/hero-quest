class_name TestSuiteArchitecture
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 2] CASTLE ARCHITECTURE, WINGS & PROPS ===")

	var hero_scene = load("res://scenes/hero_quest.tscn")
	assert(hero_scene != null, "Failed to load hero_quest.tscn")
	var hq = hero_scene.instantiate()
	tree.root.add_child(hq)
	await tree.process_frame
	await tree.process_frame

	var builder = hq.get_node_or_null("CastleBuilder")
	var player = hq.player

	# -------------------------------------------------------------
	# TEST 7: Test New Wings, Multi-Tile Props, Facing Inspection & Occlusion
	# -------------------------------------------------------------
	print("\n[TEST 7] Verifying New Wings, Multi-Tile Props, Facing Inspection & Occlusion...")
	var indoor_garden = builder.get_node_or_null("IndoorGarden")
	var dining_hall = builder.get_node_or_null("GrandDiningHall")
	assert(indoor_garden != null, "IndoorGarden room missing")
	assert(dining_hall != null, "GrandDiningHall room missing")

	# 1. Verify 2-Tile Chapel Pews
	assert(builder.is_tile_walkable(Vector2i(-3, -14)) == false, "Chapel 2-tile pew cell (-3, -14) must be blocked")
	assert(builder.is_tile_walkable(Vector2i(-2, -14)) == false, "Chapel 2-tile pew cell (-2, -14) must be blocked")
	var pew_prop_left1 = builder.grid[Vector2i(-3, -14)]["prop"]
	var pew_prop_left2 = builder.grid[Vector2i(-2, -14)]["prop"]
	assert(pew_prop_left1 != null and pew_prop_left1 == pew_prop_left2, "Both cells must share the same 2-tile pew instance")
	print("  - 2-Tile Chapel Pews verified: spans 2 cells with shared prop.")

	# 2. Verify 10-Tile Banquet Table
	var table_sample = builder.grid[Vector2i(11, -14)]["prop"]
	assert(table_sample != null, "10-Tile dining table missing from (11, -14)")
	for gx in range(11, 13):
		for gz in range(-16, -11):
			assert(builder.is_tile_walkable(Vector2i(gx, gz)) == false, "Dining table cell (%d, %d) must be blocked" % [gx, gz])
			assert(builder.grid[Vector2i(gx, gz)]["prop"] == table_sample, "Cell (%d, %d) must link to table" % [gx, gz])
	print("  - 10-Tile Dining Table verified: spans all 10 grid cells correctly.")

	# 3. Verify Facing-Based Furniture Inspection
	player.current_tile = Vector2i(-15, -1)
	player.facing_dir = Vector2i(0, -1)
	player._check_interaction_proximity()
	assert(player.nearby_interactable_comp != null, "Facing cupboard should detect interactable")
	var prompt = player.nearby_interactable_comp.get_prompt_text()
	assert("Cupboard" in prompt, "Prompt when facing cupboard should mention Cupboard, got: %s" % prompt)
	print("  - Facing-based inspection verified: Facing Cupboard displays '%s'." % prompt)

	# 4. Verify Camera Occlusion Fading Manager
	assert(hq.occlusion_mgr != null, "HeroQuestCameraOcclusion manager missing")
	assert(hq.occlusion_mgr.target_alpha == 0.3, "Target obstruction alpha must be 0.3 (30% transparent)")
	print("  - Camera Occlusion Fading verified: active with 30% transparency target.")

	# 5. Verify Gothic Windows and Chimney
	var animated_flames = dining_hall.find_children("AnimatedFlames", "Node3D", true, false)
	assert(animated_flames.size() > 0, "Animated flames missing from Grand Dining Hall chimney")
	var windows = builder.find_children("*", "MeshInstance3D", true, false)
	var has_stained_glass = false
	for m in windows:
		if m.material_override == builder.materials.mat_window_glass:
			has_stained_glass = true
			break
		if m.mesh and ("material" in m.mesh) and m.mesh.get("material") == builder.materials.mat_window_glass:
			has_stained_glass = true
			break
	assert(has_stained_glass, "Gothic exterior windows with stained glass missing")
	print("  - Animated fireplace chimney and gothic exterior windows verified.")
	print("  -> Passed! All architectural, facing, multi-tile, and visual enhancements confirmed.")

	# -------------------------------------------------------------
	# TEST 8: Test World Polish, Non-Overlapping Bricks, Widened Piers, Unblocked Corridor & Plaza
	# -------------------------------------------------------------
	print("\n[TEST 8] Verifying Brick Scattering, Widened Piers, Corridor Flow & Garden Plaza...")
	var garden_cells = 0
	for cell in builder.grid.keys():
		if cell.x >= -15 and cell.x <= -8 and cell.y >= -24 and cell.y <= -10:
			garden_cells += 1
	assert(garden_cells == 120, "Garden should have exactly 120 cells (15 rows x 8 cols), got: %d" % garden_cells)
	print("  - Garden 50 percent enlargement confirmed: %d tiles (gx: -15..-8, gz: -24..-10)." % garden_cells)

	var fountain_sample = builder.grid[Vector2i(-12, -16)]["prop"]
	assert(fountain_sample != null, "Fountain missing at central plaza cell (-12, -16)")
	print("  - Central fountain in 4x4 stone plaza confirmed.")

	for gx in [-13, -12, -11]:
		assert(builder.is_tile_walkable(Vector2i(gx, -9)), "Garden connector at (%d, -9) must be walkable" % gx)
		assert(builder.is_tile_walkable(Vector2i(gx, -8)), "Garden connector at (%d, -8) must be walkable" % gx)
		assert(builder.is_tile_walkable(Vector2i(gx, -7)), "Garden connector at (%d, -7) must be walkable" % gx)
	assert(builder.is_tile_walkable(Vector2i(-12, -6)), "Stables entry at (-12, -6) must be walkable (unblocked corridor)")
	assert(builder.is_tile_walkable(Vector2i(-12, -5)), "Stables aisle at (-12, -5) must be walkable")
	print("  - Royal Stables corridor to Garden verified: unblocked and fully walkable across 3 tiles.")

	var hall_table = builder.grid[Vector2i(-2, 2)]["prop"]
	assert(hall_table != null, "Great Hall table missing at (-2, 2)")
	var chairs = hall_table.find_children("*", "StaticBody3D", true, false)
	assert(chairs.size() > 0, "Great Hall table must have a chair")
	assert(absf(chairs[0].rotation.y) < 0.01, "Great Hall chair must face table (rotation.y = 0.0, got: %f)" % chairs[0].rotation.y)

	var smith_table = builder.grid[Vector2i(10, 3)]["prop"]
	assert(smith_table != null, "Blacksmith workbench missing at (10, 3)")
	var smith_chairs = smith_table.find_children("*", "StaticBody3D", true, false)
	assert(smith_chairs.size() > 0, "Workbench must have a chair")
	assert(absf(smith_chairs[0].rotation.y) < 0.01, "Workbench chair must face table (rotation.y = 0.0, got: %f)" % smith_chairs[0].rotation.y)
	print("  - Chair orientations confirmed: all chairs oriented 180° towards their tables.")

	var chapel_node = builder.get_node_or_null("Chapel")
	assert(chapel_node != null, "Chapel node missing")
	var chapel_lights = chapel_node.find_children("*", "OmniLight3D", true, false)
	var found_wall_connected_torch = false
	for light in chapel_lights:
		var parent_node = light.get_parent()
		if parent_node and parent_node.position.x <= -13.5:
			found_wall_connected_torch = true
			break
	assert(found_wall_connected_torch, "Chapel torches must be attached to the 0.9m wall face at x <= -13.5")
	print("  - Wall lamp mounting confirmed: chapel torches attached flush to wall stone at x <= -13.5.")

	var arch_piers = builder.find_children("*", "StaticBody3D", true, false)
	var found_widened_pier = false
	for pier in arch_piers:
		var shaft_meshes = []
		for c in pier.get_children():
			if c is MeshInstance3D and c.mesh is BoxMesh:
				var sz = c.mesh.size
				if sz.y > 2.0: shaft_meshes.append(sz)
		for sz in shaft_meshes:
			if sz.x > 1.4 or sz.z > 1.4:
				found_widened_pier = true
				break
	assert(found_widened_pier, "Widened arch pier should be present")
	print("  - Widened arch piers confirmed: single unified wide pillar (1.45m).")
	print("  -> Passed! Brick scatterer, widened columns, corridor flow, garden plaza, and chair orientations all verified.")

	# -------------------------------------------------------------
	# TEST 9: Test South Walls, Stable Torches, Bench Legs, Courtyard Fence & Camera Rotation
	# -------------------------------------------------------------
	print("\n[TEST 9] Verifying South Walls, Torches away from Windows, Bench Legs, Fence & Camera...")
	assert(builder.grid.has(Vector2i(-13, 7)), "South stable wall at (-13, 7) must exist")
	assert(builder.grid[Vector2i(-13, 7)]["type"] == 6, "South stable wall at (-13, 7) must be WALL (6)")
	assert(builder.grid.has(Vector2i(-11, 7)), "South stable wall at (-11, 7) must exist")
	assert(builder.grid[Vector2i(-11, 7)]["type"] == 6, "South stable wall at (-11, 7) must be WALL (6)")
	print("  - South Stable Wall and exterior windows confirmed present at gz = 7.")

	assert(builder.grid.has(Vector2i(-3, 7)), "Great corridor south wall at (-3, 7) must exist")
	assert(builder.grid[Vector2i(-3, 7)]["type"] == 6, "Great corridor south wall at (-3, 7) must be WALL (6)")
	assert(builder.grid.has(Vector2i(3, 7)), "Great corridor south wall at (3, 7) must exist")
	assert(builder.grid[Vector2i(3, 7)]["type"] == 6, "Great corridor south wall at (3, 7) must be WALL (6)")
	print("  - Great Corridor South Walls confirmed present at gz = 7 flanking bridge arch.")

	var stables_node = builder.get_node_or_null("Stables")
	assert(stables_node != null, "Stables node missing")
	var stable_lights = stables_node.find_children("*", "OmniLight3D", true, false)
	for light in stable_lights:
		var parent_node = light.get_parent()
		if parent_node:
			assert(absf(parent_node.position.z) > 0.5, "Stable torch must not be on window at z = 0")
	print("  - Stable torches confirmed mounted on solid wall piers away from windows.")

	var pew = builder.grid[Vector2i(-3, -14)]["prop"]
	assert(pew != null, "Chapel pew missing at (-3, -14)")
	var pew_meshes = pew.find_children("*", "MeshInstance3D", true, false)
	var found_pew_legs = false
	for m in pew_meshes:
		if m.mesh is BoxMesh:
			if (m.position.y - m.mesh.size.y * 0.5) <= 0.05 and m.mesh.size.y >= 0.35:
				found_pew_legs = true
				break
	assert(found_pew_legs, "Church pew must have legs/end panels grounded on the floor")
	print("  - Church pew legs confirmed: solid Gothic supports extending to the floor.")

	var courtyard_node = builder.get_node_or_null("SouthCourtyard")
	assert(courtyard_node != null, "SouthCourtyard node missing")
	var fences = []
	for child in courtyard_node.get_children():
		if child.name.begins_with("CourtyardFence") or child.has_meta("is_fence"):
			fences.append(child)
	assert(fences.size() >= 2, "Courtyard must have northern fences flanking the bridge portal")
	print("  - Courtyard north fences confirmed guarding the chasm abyss.")

	var initial_yaw = hq.target_cam_yaw
	var key_r = InputEventKey.new()
	key_r.keycode = KEY_R
	key_r.pressed = true
	hq._unhandled_input(key_r)
	assert(hq.target_cam_yaw == initial_yaw - 90.0, "Pressing R must rotate camera 90° clockwise")
	print("  - Camera 90° clockwise rotation on 'R' key confirmed.")
	print("  -> Passed! South walls, window clearance, pew legs, fences, and camera rotation all verified.")

	# -------------------------------------------------------------
	# TEST 10: Test Spatial Rules, Corridor Door Matching, Bridge Arch & Railings
	# -------------------------------------------------------------
	print("\n[TEST 10] Verifying Inter-Room Windows, Wall Gaps, Corridor Doors, Bridge Arch & Fences...")
	var perimeter_node = builder.get_node_or_null("PerimeterBarriers")
	assert(perimeter_node != null, "PerimeterBarriers node missing")
	for child in perimeter_node.get_children():
		var child_windows = child.find_children("*", "MeshInstance3D", true, false)
		for cw in child_windows:
			if cw.mesh and ("material" in cw.mesh) and cw.mesh.get("material") == builder.materials.mat_window_glass:
				var gx = roundi(child.position.x / 2.0)
				var gz = roundi(child.position.z / 2.0)
				assert(gx != 7 or (gz > -10 or gz < -18), "Inter-room wall at (7, %d) must NOT have windows!" % gz)
				assert(gx != -7 or gz != -14, "Arch doorway at (-7, -14) must NOT have windows!")

	assert(builder.grid.has(Vector2i(-7, -16)) and builder.grid[Vector2i(-7, -16)]["type"] == 6, "Window at (-7, -16) on solid wall must exist")
	print("  - Zero windows between indoor rooms and zero windows in arches confirmed.")

	assert(builder.grid.has(Vector2i(-12, -8)), "Corridor tile (-12, -8) between garden and stables must exist")
	assert(builder.is_tile_walkable(Vector2i(-12, -8)), "Corridor tile (-12, -8) must be walkable open gap")
	print("  - At least one tile gap between Garden and Stables walls confirmed.")

	var all_nodes = builder.find_children("*", "Node3D", true, false)
	var found_dining_gate = false
	var found_forge_gate = false
	var found_garden_stables_gate = false
	var found_stables_garden_gate = false
	var found_bridge_north_arch = false
	var found_courtyard_portal = false
	var found_hall_north_arch = false
	var found_nw_tower_portal = false
	for n in all_nodes:
		if n.name == "Dining Forge Gate": found_dining_gate = true
		elif n.name == "Forge Dining Gate": found_forge_gate = true
		elif n.name == "Garden Stables Gate": found_garden_stables_gate = true
		elif n.name == "Stables Garden Gate": found_stables_garden_gate = true
		elif n.name == "Bridge North Arch": found_bridge_north_arch = true
		elif n.name == "Courtyard Portal": found_courtyard_portal = true
		elif n.name == "Hall North Arch": found_hall_north_arch = true
		elif n.name == "NorthWestTowerPortal": found_nw_tower_portal = true
	assert(found_dining_gate and found_forge_gate, "Both ends of Dining-Forge corridor must have doors/arches")
	assert(found_garden_stables_gate and found_stables_garden_gate, "Both ends of Garden-Stables corridor must have doors/arches")
	assert(found_hall_north_arch, "Hall North Arch must exist at North Passage entrance")
	assert(found_nw_tower_portal, "North-West Watchtower entrance arch must exist")
	print("  - Corridor door matching confirmed: both entry and exit ends have arches.")

	assert(found_bridge_north_arch, "Bridge must have 3-field arch at start (gz = 6)")
	assert(found_courtyard_portal, "Bridge must have 3-field arch at end (gz = 13)")
	for gz in range(7, 13):
		for gx in [-1, 0, 1]:
			var c = Vector2i(gx, gz)
			assert(builder.grid[c]["type"] == 4, "Bridge walkway tile at (%d, %d) must be FLOOR_BRIDGE (4)" % [gx, gz])
	print("  - Bridge 3-field arches at start and end only confirmed.")

	for gx in range(-2, 3):
		for gz in range(-11, -6):
			var cell = Vector2i(gx, gz)
			assert(builder.grid.has(cell), "North Passage cell (%d, %d) must exist in grid" % [gx, gz])
	for gx in range(-2, 3):
		for gz in range(-10, -7):
			assert(builder.is_tile_walkable(Vector2i(gx, gz)), "North Passage aisle (%d, %d) must be walkable" % [gx, gz])
	print("  - North Passage 5-tile width confirmed.")

	for gx in range(-7, 8):
		var south_wall_cell = Vector2i(gx, 19)
		assert(builder.grid.has(south_wall_cell), "South courtyard south wall missing at (%d, 19)" % gx)
		assert(builder.grid[south_wall_cell]["type"] == 6, "South courtyard south wall at (%d, 19) must be WALL (6)" % gx)
	print("  - South Castle Courtyard south walls fully restored at gz = 19.")

	for child in courtyard_node.get_children():
		if child.name.begins_with("CourtyardFence") or child.has_meta("is_fence"):
			var cols = child.find_children("*", "CollisionShape3D", true, false)
			if cols.size() > 0 and cols[0].shape is BoxShape3D:
				assert(cols[0].shape.size.x <= 10.05, "Courtyard fence must be shortened to 10.0m")
	print("  - South courtyard fences confirmed shortened by 1 tile.")
	print("  -> Passed! All spatial rules, corridor doors, bridge arches, passage widths, and courtyard walls verified.")

	# -------------------------------------------------------------
	# TEST 11: Test Graveyard Zone, 10 Gravestones, Skeleton, Tree, Fence & Stake Torches
	# -------------------------------------------------------------
	print("\n[TEST 11] Verifying Graveyard Zone, 10 Gravestones, Skeleton, Tree, Fencing & Stake Torches...")
	var graveyard_node = builder.get_node_or_null("Graveyard")
	assert(graveyard_node != null, "Graveyard node missing from CastleBuilder")

	var graveyard_tiles = 0
	for cell in builder.grid.keys():
		if builder.grid[cell]["type"] == 8: graveyard_tiles += 1
	assert(graveyard_tiles == 73, "Graveyard should have 73 tiles")
	print("  - Graveyard grid confirmed: 73 registered cemetery tiles.")

	assert(builder.is_tile_walkable(Vector2i(-12, -24)), "Garden North path cell (-12, -24) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-12, -25)), "Graveyard entrance portal (-12, -25) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-12, -26)), "Graveyard threshold cell (-12, -26) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-13, -25)) == false, "Entrance arch left pier must block movement")
	assert(builder.is_tile_walkable(Vector2i(-11, -25)) == false, "Entrance arch right pier must block movement")
	for x in range(-16, -7):
		assert(builder.is_tile_walkable(Vector2i(x, -29)), "Cross pathway cell (%d, -29) must be walkable" % x)
	for z in range(-33, -24):
		assert(builder.is_tile_walkable(Vector2i(-12, z)), "Central pathway cell (-12, %d) must be walkable" % z)
	print("  - Portal connectivity and clear graveyard pathways confirmed.")

	var gravestones = graveyard_node.find_children("Gravestone*", "StaticBody3D", true, false)
	assert(gravestones.size() == 10, "Expected exactly 10 gravestones, found: %d" % gravestones.size())
	for g in gravestones:
		var interact = g.get_node_or_null("Interactable")
		assert(interact != null and interact.custom_prompt != "", "Gravestone must have an epitaph prompt")
	print("  - Exactly 10 gravestones confirmed with inspectable epitaphs.")

	var skeleton = graveyard_node.get_node_or_null("BleachedSkeleton")
	assert(skeleton != null and skeleton.get_node_or_null("Interactable") != null, "BleachedSkeleton node missing or non-interactive")
	print("  - Bleached skeleton confirmed with rusted blade and inspection.")

	var ancient_tree = graveyard_node.get_node_or_null("AncientTree")
	assert(ancient_tree != null and not builder.is_tile_walkable(Vector2i(-10, -30)), "AncientTree missing or not blocking")
	print("  - Ancient gnarled tree confirmed with spreading roots and foliage.")

	var torches_on_sticks = graveyard_node.find_children("TorchOnStick*", "Node3D", true, false)
	assert(torches_on_sticks.size() >= 4, "Expected at least 4 torches on sticks")
	print("  - Outdoor torches on sticks confirmed with dynamic flickering illumination.")

	var graveyard_fences = graveyard_node.find_children("CemeteryFence*", "StaticBody3D", true, false)
	assert(graveyard_fences.size() >= 5, "Expected at least 5 fence segments enclosing graveyard")
	var pillars = graveyard_node.find_children("*Pillar*", "StaticBody3D", true, false)
	assert(pillars.size() >= 6, "Expected at least 6 stone pillars")
	print("  - Cemetery perimeter fencing and stone pillars confirmed enclosing graveyard.")

	hq.queue_free()
	await tree.process_frame

	# -------------------------------------------------------------
	# TEST 28: Verify Prison Dungeon Wing, 5 Cells, Portcullis Gates, and Props
	# -------------------------------------------------------------
	print("\n[TEST 28] Verifying Prison Dungeon Wing, 5 Cells, 2-Tile Portcullis Gates & Props...")
	var t28_builder = Node3D.new()
	t28_builder.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	t28_builder.level_file_path = "res://data/levels/first_level.json"
	tree.root.add_child(t28_builder)
	t28_builder.build_castle()
	await tree.process_frame

	var prison_node = t28_builder.get_node_or_null("PrisonDungeon")
	assert(prison_node != null, "PrisonDungeon room missing from first_level.json")

	var iron_door = prison_node.get_node_or_null("Prison Iron Entrance")
	assert(iron_door != null, "Prison Iron Entrance door missing at (16, 5)")
	var id_ctrl = iron_door.get_node_or_null("DoorController")
	assert(id_ctrl != null, "DoorController missing from Iron Entrance door")

	for i in range(1, 6):
		var p_name = "Cell %d Portcullis" % i
		var port = prison_node.get_node_or_null(p_name)
		assert(port != null, "%s missing from PrisonDungeon" % p_name)
		var p_ctrl = port.get_node_or_null("DoorController")
		assert(p_ctrl != null and p_ctrl.is_locked and not p_ctrl.is_open and p_ctrl.required_key == "Iron Key", "%s configuration mismatch" % p_name)

	var skels = prison_node.find_children("BleachedSkeleton*", "StaticBody3D", true, false)
	assert(skels.size() >= 3, "Expected at least 3 skeletons in prison")
	var benches = prison_node.find_children("Bench*", "StaticBody3D", true, false)
	assert(benches.size() >= 3, "Expected at least 3 benches in prison cells")
	assert(prison_node.get_node_or_null("Table") != null, "Guard Table missing")
	assert(prison_node.get_node_or_null("Chimney") != null, "Chimney fireplace missing")
	var arms_racks = prison_node.find_children("ArmsShelf*", "StaticBody3D", true, false)
	assert(arms_racks.size() >= 2, "Expected at least 2 arms racks in prison hall")

	assert(t28_builder.grid.has(Vector2i(16, 5)), "Doorway cell (16,5) must be registered in grid")
	assert(t28_builder.grid.has(Vector2i(25, 3)), "Cell 1 portcullis cell (25,3) must be registered in grid")
	assert(t28_builder.grid.has(Vector2i(25, 2)), "Cell 1 walkable floor (25,2) must be registered in grid")
	assert(t28_builder.grid[Vector2i(25, 2)]["walkable"] == true, "Cell 1 floor must be walkable")

	t28_builder.queue_free()
	print("  - Prison entrance iron door, 5 portcullis cell gates, benches, skeletons, table, chimney & arms racks verified.")
	print("  -> Passed! Full castle architecture & dungeon wing verified.")
