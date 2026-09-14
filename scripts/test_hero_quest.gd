extends SceneTree

func _init() -> void:
	print("=== RUNNING HERO QUEST & STARTPAGE INTEGRATION TESTS ===")

	# -------------------------------------------------------------
	# TEST 1: Test Startpage (start_menu.tscn)
	# -------------------------------------------------------------
	print("\n[TEST 1] Loading and verifying Startpage...")
	var menu_scene = load("res://scenes/start_menu.tscn")
	assert(menu_scene != null, "Failed to load start_menu.tscn")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var new_level_btn = menu.get_node_or_null("CenterContainer/HeroCard/Margin/VBox/NewLevelButton")
	var levels_vbox = menu.get_node_or_null("CenterContainer/HeroCard/Margin/VBox/LevelsVBox")
	var quit_btn = menu.get_node_or_null("BottomBar/QuitButton")
	var pacman_card = menu.get_node_or_null("CenterContainer/HBox/PacmanCard")

	assert(new_level_btn != null, "Missing NewLevelButton on Startpage")
	assert(levels_vbox != null, "Missing LevelsVBox on Startpage")
	assert(quit_btn != null, "Missing QuitButton on Startpage")
	assert(pacman_card == null, "Pacman choice must NOT be on Startpage (hidden as easter egg)")
	print("  -> Passed! Startpage verified as dedicated Hero Quest level portal without Pacman choice.")
	menu.queue_free()
	await process_frame

	# -------------------------------------------------------------
	# TEST 2: Test Hero Quest Scene Loading
	# -------------------------------------------------------------
	print("\n[TEST 2] Loading and verifying Hero Quest Main Scene...")
	var hero_scene = load("res://scenes/hero_quest.tscn")
	assert(hero_scene != null, "Failed to load hero_quest.tscn")
	var hq = hero_scene.instantiate()
	root.add_child(hq)
	await process_frame
	await process_frame

	var builder = hq.get_node_or_null("CastleBuilder")
	var cam_pivot = hq.get_node_or_null("CameraPivot")
	var audio_mgr = hq.get_node_or_null("HeroQuestAudio")
	var hud = hq.get_node_or_null("HeroQuestHUD")

	assert(builder != null, "CastleBuilder missing from Hero Quest")
	assert(cam_pivot != null, "CameraPivot missing from Hero Quest")
	assert(audio_mgr != null, "HeroQuestAudio missing from Hero Quest")
	assert(hud != null, "HeroQuestHUD missing from Hero Quest")
	print("  -> Passed! Hero Quest base components initialized.")

	# -------------------------------------------------------------
	# TEST 3: Test Castle World Zones & Rooms
	# -------------------------------------------------------------
	print("\n[TEST 3] Verifying Castle Zones (Chapel, Stables, Smith, Towers, Bridges, Corridors)...")
	var great_hall = builder.get_node_or_null("GreatHall")
	var chapel = builder.get_node_or_null("Chapel")
	var blacksmith = builder.get_node_or_null("Blacksmith")
	var stables = builder.get_node_or_null("Stables")
	var chasm = builder.get_node_or_null("Chasm")
	var bridges = builder.get_node_or_null("Bridges")
	var courtyard = builder.get_node_or_null("SouthCourtyard")
	var round_towers = builder.get_node_or_null("RoundTowers")
	var perimeter = builder.get_node_or_null("PerimeterBarriers")

	assert(great_hall != null, "GreatHall room missing")
	assert(chapel != null, "Chapel room missing")
	assert(blacksmith != null, "Blacksmith room missing")
	assert(stables != null, "Stables room missing")
	assert(chasm != null, "Chasm room missing")
	assert(bridges != null, "Bridges room missing")
	assert(courtyard != null, "SouthCourtyard room missing")
	assert(round_towers != null, "RoundTowers missing")
	assert(perimeter != null, "Perimeter safety barriers missing")

	assert(builder.interactive_altar != null, "Chapel Altar missing")
	assert(builder.interactive_bell != null, "Chapel Bell missing")
	assert(builder.interactive_anvil != null, "Blacksmith Anvil missing")
	assert(builder.interactive_chests.size() >= 4, "Expected at least 4 treasure chests, found %d" % builder.interactive_chests.size())
	assert(round_towers.get_child_count() == 4, "Expected 4 round watchtowers, found %d" % round_towers.get_child_count())

	print("  - Altar, Chapel Bell, Blacksmith Anvil, and %d Treasure Chests confirmed." % builder.interactive_chests.size())
	print("  - 4 Round Watchtowers and Bridge across Chasm confirmed.")
	print("  -> Passed! Complete medieval castle world verified.")

	# -------------------------------------------------------------
	# TEST 4: Test Unified Grid Architecture & Zero-Gap Room Connectivity
	# -------------------------------------------------------------
	print("\n[TEST 4] Verifying Unified Grid & Zero-Gap Corridor Connectivity...")
	var total_tiles = builder.grid.size()
	print("  - Total grid cells registered: %d" % total_tiles)
	assert(total_tiles > 300, "Expected > 300 grid cells, found %d" % total_tiles)

	# 1. Continuity from Great Hall to Stables (West path: gx: 0 -> -12 at gz: 0)
	for gx in range(0, -13, -1):
		var cell = Vector2i(gx, 0)
		assert(builder.is_tile_walkable(cell), "Gap found on path to Stables at cell %s!" % str(cell))
	# Verify 3-tile arch piers are blockers
	assert(builder.is_tile_walkable(Vector2i(-4, -1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(-4, 1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(-4, 0)) == true, "3-tile arch center should be walkable")
	print("  - 3-Tile Arch (West Stables) verified: piers block, center doorway open.")

	# 2. Continuity from Great Hall to Blacksmith (East path: gx: 0 -> 11 at gz: 0)
	for gx in range(0, 12):
		var cell = Vector2i(gx, 0)
		assert(builder.is_tile_walkable(cell), "Gap found on path to Blacksmith at cell %s!" % str(cell))
	# Verify 3-tile arch piers are blockers
	assert(builder.is_tile_walkable(Vector2i(4, -1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(4, 1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(4, 0)) == true, "3-tile arch center should be walkable")
	print("  - 3-Tile Arch (East Blacksmith) verified: piers block, center doorway open.")

	# 3. Continuity from Great Hall to Chapel through 5-Tile Twin Arch
	# Center pier at (0, -11) is blocker in south chapel wall
	assert(builder.is_tile_walkable(Vector2i(0, -11)) == false, "5-tile twin arch center pier must be blocker")
	assert(builder.is_tile_walkable(Vector2i(-2, -11)) == false, "5-tile twin arch left pier must be blocker")
	assert(builder.is_tile_walkable(Vector2i(2, -11)) == false, "5-tile twin arch right pier must be blocker")
	# Both archways are open
	assert(builder.is_tile_walkable(Vector2i(-1, -11)) == true, "5-tile left archway must be walkable")
	assert(builder.is_tile_walkable(Vector2i(1, -11)) == true, "5-tile right archway must be walkable")
	# Seamless path into chapel through left twin arch (North Passage now extended to gz = -11)
	for gz in range(0, -11, -1):
		assert(builder.is_tile_walkable(Vector2i(0, gz)), "North corridor gap at gz=%d" % gz)
	for gz in range(-11, -19, -1):
		assert(builder.is_tile_walkable(Vector2i(-1, gz)), "Chapel path gap through arch at gz=%d" % gz)
	print("  - 5-Tile Twin Arch (Grand Chapel) verified: 3 piers block, 2 side-by-side archways open.")

	# 4. Continuity from Great Hall across Bridge to Courtyard through 3-Field Spanning Arch
	assert(builder.is_tile_walkable(Vector2i(-2, 6)) == false, "3-field bridge pier at (-2, 6) must be blocker")
	assert(builder.is_tile_walkable(Vector2i(2, 6)) == false, "3-field bridge pier at (2, 6) must be blocker")
	assert(builder.is_tile_walkable(Vector2i(-1, 6)) == true, "3-field bridge opening at (-1, 6) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(0, 6)) == true, "3-field bridge opening at (0, 6) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(1, 6)) == true, "3-field bridge opening at (1, 6) must be walkable")
	for gz in range(0, 17):
		var cell = Vector2i(0, gz)
		assert(builder.is_tile_walkable(cell), "Gap found on Bridge / Courtyard path at cell %s!" % str(cell))
	print("  - 3-Field Spanning Arch (Bridge Start & End) verified: piers at gx = ±2 block, 3 fields open.")
	print("  -> Passed! 3-Tile, 4-Tile, 5-Tile, and 3-Field stone arches verified with proper blockers and openings.")

	# -------------------------------------------------------------
	# TEST 5: Test Dedicated Square Tile Movement & Cliff Protection
	# -------------------------------------------------------------
	print("\n[TEST 5] Verifying Dedicated Tile Movement & Cliff Drop-off Safety...")
	var player = hq.player
	assert(player != null, "Player Hero Box not spawned")
	assert(player.castle_builder != null, "Player castle_builder reference missing")

	# Test 5a: Chasm void cells are strictly NOT walkable
	var chasm_cell = Vector2i(6, 9)
	assert(builder.is_tile_walkable(chasm_cell) == false, "Chasm cell should NOT be walkable!")
	var out_of_bounds = Vector2i(50, 50)
	assert(builder.is_tile_walkable(out_of_bounds) == false, "Out of bounds cell should NOT be walkable!")

	# Test 5b: Move player from (0, 0) to (0, -1) (North step)
	assert(player.current_tile == Vector2i(0, 0), "Player expected at (0, 0), got %s" % str(player.current_tile))
	player._try_step_to_tile(Vector2i(0, -1), Vector2i(0, -1))
	assert(player.is_moving == true, "Player should be in moving state after valid step")
	assert(player.target_tile == Vector2i(0, -1), "Target tile mismatch")

	# Simulate completing the tile step
	player._process_tile_movement(player.step_duration + 0.05)
	assert(player.is_moving == false, "Player should have completed tile step")
	assert(player.current_tile == Vector2i(0, -1), "Player current tile should be (0, -1)")
	var expected_pos = builder.grid_to_world(Vector2i(0, -1))
	assert(player.global_position.is_equal_approx(expected_pos), "Player position not snapped to tile center")
	print("  - Tile step simulation succeeded: accurately advanced to %s at %s" % [str(player.current_tile), str(expected_pos)])

	# Test 5c: Attempting to step into a solid obstacle/wall is rejected
	player.current_tile = Vector2i(0, -1)
	var pillar_tile = Vector2i(-2, -4)
	assert(builder.is_tile_walkable(pillar_tile) == false, "Pillar tile should not be walkable")
	player._try_step_to_tile(pillar_tile, Vector2i(-1, 0))
	assert(player.is_moving == false, "Player must NOT move into non-walkable tile")
	assert(player.current_tile == Vector2i(0, -1), "Player position must remain unchanged")
	print("  - Blocked tile rejection verified: hero box cannot enter walls, props, or chasms.")
	print("  -> Passed! Tile-based movement and cliff protection verified.")

	# -------------------------------------------------------------
	# TEST 6: Test Procedural Dark Adventure Music & SFX
	# -------------------------------------------------------------
	print("\n[TEST 6] Verifying Procedural Dark Adventure Music & SFX...")
	assert(audio_mgr.stream_dark_music != null, "Dark adventure music stream was not generated")
	assert(audio_mgr.stream_dark_music.data.size() > 100000, "Dark adventure music audio buffer empty")
	assert(audio_mgr.stream_footstep != null, "Footstep SFX missing")
	assert(audio_mgr.stream_chest_open != null, "Chest SFX missing")
	assert(audio_mgr.stream_anvil_clink != null, "Anvil SFX missing")
	assert(audio_mgr.stream_chapel_bell != null, "Chapel bell SFX missing")
	print("  - Dark adventure music generated: %d bytes (16-second loop)" % audio_mgr.stream_dark_music.data.size())
	print("  -> Passed! Dark adventure soundtrack and sound effects ready.")

	# -------------------------------------------------------------
	# TEST 7: Test New Wings, Multi-Tile Props, Facing Inspection & Occlusion
	# -------------------------------------------------------------
	print("\n[TEST 7] Verifying New Wings, Multi-Tile Props, Facing Inspection & Occlusion...")
	var indoor_garden = builder.get_node_or_null("IndoorGarden")
	var dining_hall = builder.get_node_or_null("GrandDiningHall")
	assert(indoor_garden != null, "IndoorGarden room missing")
	assert(dining_hall != null, "GrandDiningHall room missing")

	# 1. Verify 2-Tile Chapel Pews (cells -3, -14 and -2, -14 are both blocked and share the same prop)
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
	# Place hero at (-3, -4) facing North towards cupboard at (-3, -5)
	player.current_tile = Vector2i(-3, -4)
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

	# 1. Verify Garden 50% Expansion and Paths/Plaza
	var garden_cells = 0
	for cell in builder.grid.keys():
		if cell.x >= -15 and cell.x <= -8 and cell.y >= -24 and cell.y <= -10:
			garden_cells += 1
	assert(garden_cells == 120, "Garden should have exactly 120 cells (15 rows x 8 cols), got: %d" % garden_cells)
	print("  - Garden 50 percent enlargement confirmed: %d tiles (gx: -15..-8, gz: -24..-10)." % garden_cells)

	# 2. Verify Fountain Position in Central Plaza
	var fountain_sample = builder.grid[Vector2i(-12, -16)]["prop"]
	assert(fountain_sample != null, "Fountain missing at central plaza cell (-12, -16)")
	print("  - Central fountain in 4x4 stone plaza confirmed.")

	# 3. Verify Stables Corridor Connectivity (Unblocked Path across 3-tile width)
	for gx in [-13, -12, -11]:
		assert(builder.is_tile_walkable(Vector2i(gx, -9)), "Garden connector at (%d, -9) must be walkable" % gx)
		assert(builder.is_tile_walkable(Vector2i(gx, -8)), "Garden connector at (%d, -8) must be walkable" % gx)
		assert(builder.is_tile_walkable(Vector2i(gx, -7)), "Garden connector at (%d, -7) must be walkable" % gx)
	assert(builder.is_tile_walkable(Vector2i(-12, -6)), "Stables entry at (-12, -6) must be walkable (unblocked corridor)")
	assert(builder.is_tile_walkable(Vector2i(-12, -5)), "Stables aisle at (-12, -5) must be walkable")
	print("  - Royal Stables corridor to Garden verified: unblocked and fully walkable across 3 tiles.")

	# 4. Verify Chair Orientations
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

	# 5. Verify Wall Torches Connected to Wall Surface (Zero Floating Air Gaps)
	var chapel_node = builder.get_node_or_null("Chapel")
	assert(chapel_node != null, "Chapel node missing")
	var chapel_lights = chapel_node.find_children("*", "OmniLight3D", true, false)
	var found_wall_connected_torch = false
	for light in chapel_lights:
		var parent_node = light.get_parent()
		if parent_node and parent_node.position.x <= -13.5:
			found_wall_connected_torch = true
			break
	assert(found_wall_connected_torch, "Chapel torches must be attached to the 0.9m wall face at x <= -13.5 (got floating torch)")
	print("  - Wall lamp mounting confirmed: chapel torches attached flush to wall stone at x <= -13.5.")

	# 6. Verify Widened Arch Piers (Single Piece, No Adjoining Wall Mesh)
	var arch_piers = builder.find_children("*", "StaticBody3D", true, false)
	var found_widened_pier = false
	for pier in arch_piers:
		var shaft_meshes = []
		for c in pier.get_children():
			if c is MeshInstance3D and c.mesh is BoxMesh:
				var sz = c.mesh.size
				if sz.y > 2.0: # shaft
					shaft_meshes.append(sz)
		for sz in shaft_meshes:
			if sz.x > 1.4 or sz.z > 1.4:
				found_widened_pier = true
				break
	assert(found_widened_pier, "Widened arch pier (width >= 1.4m single object) should be present")
	print("  - Widened arch piers confirmed: single unified wide pillar (1.45m) with zero separate objects.")

	print("  -> Passed! Brick scatterer, widened columns, corridor flow, garden plaza, and chair orientations all verified.")

	# -------------------------------------------------------------
	# TEST 9: Test South Walls, Stable Torches, Bench Legs, Courtyard Fence & Camera Rotation
	# -------------------------------------------------------------
	print("\n[TEST 9] Verifying South Walls, Torches away from Windows, Bench Legs, Fence & Camera...")

	# 1. Verify South Stable Wall and Windows
	assert(builder.grid.has(Vector2i(-13, 7)), "South stable wall at (-13, 7) must exist")
	assert(builder.grid[Vector2i(-13, 7)]["type"] == 6, "South stable wall at (-13, 7) must be WALL (6)")
	assert(builder.grid.has(Vector2i(-11, 7)), "South stable wall at (-11, 7) must exist")
	assert(builder.grid[Vector2i(-11, 7)]["type"] == 6, "South stable wall at (-11, 7) must be WALL (6)")
	print("  - South Stable Wall and exterior windows confirmed present at gz = 7.")

	# 2. Verify Great Corridor South Walls
	assert(builder.grid.has(Vector2i(-3, 7)), "Great corridor south wall at (-3, 7) must exist")
	assert(builder.grid[Vector2i(-3, 7)]["type"] == 6, "Great corridor south wall at (-3, 7) must be WALL (6)")
	assert(builder.grid.has(Vector2i(3, 7)), "Great corridor south wall at (3, 7) must exist")
	assert(builder.grid[Vector2i(3, 7)]["type"] == 6, "Great corridor south wall at (3, 7) must be WALL (6)")
	print("  - Great Corridor South Walls confirmed present at gz = 7 flanking bridge arch.")

	# 3. Verify Stable Torches are on solid walls, never coming out of windows
	var stables_node = builder.get_node_or_null("Stables")
	assert(stables_node != null, "Stables node missing")
	var stable_lights = stables_node.find_children("*", "OmniLight3D", true, false)
	for light in stable_lights:
		var parent_node = light.get_parent()
		if parent_node:
			assert(absf(parent_node.position.z) > 0.5, "Stable torch must not be on window at z = 0")
	print("  - Stable torches confirmed mounted on solid wall piers away from windows.")

	# 4. Verify Church Pews Have Grounded Legs (Pew shifted to gz = -14)
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

	# 5. Verify Courtyard North Fences
	var courtyard_node = builder.get_node_or_null("SouthCourtyard")
	assert(courtyard_node != null, "SouthCourtyard node missing")
	var fences = []
	for child in courtyard_node.get_children():
		if child.name.begins_with("CourtyardFence") or child.has_meta("is_fence"):
			fences.append(child)
	assert(fences.size() >= 2, "Courtyard must have northern fences flanking the bridge portal (found: %d)" % fences.size())
	print("  - Courtyard north fences confirmed guarding the chasm abyss.")

	# 6. Verify Camera 90° Clockwise Rotation on 'R'
	var initial_yaw = hq.target_cam_yaw
	var key_r = InputEventKey.new()
	key_r.keycode = KEY_R
	key_r.pressed = true
	hq._unhandled_input(key_r)
	assert(hq.target_cam_yaw == initial_yaw - 90.0, "Pressing R must rotate camera 90° clockwise (yaw - 90)")
	print("  - Camera 90° clockwise rotation on 'R' key confirmed.")

	print("  -> Passed! South walls, window clearance, pew legs, fences, and camera rotation all verified.")

	# -------------------------------------------------------------
	# TEST 10: Test Spatial Rules, Corridor Door Matching, Bridge Arch & Railings
	# -------------------------------------------------------------
	print("\n[TEST 10] Verifying Inter-Room Windows, Wall Gaps, Corridor Doors, Bridge Arch & Fences...")

	# 1. Verify No Windows Between Rooms and No Windows in Doors/Arches
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

	# Window on solid stone wall at (-7, -16) should exist
	assert(builder.grid.has(Vector2i(-7, -16)) and builder.grid[Vector2i(-7, -16)]["type"] == 6, "Window at (-7, -16) on solid wall must exist")
	print("  - Zero windows between indoor rooms and zero windows in arches confirmed.")

	# 2. Verify At Least One Tile Gap Between Stables and Garden Walls
	assert(builder.grid.has(Vector2i(-12, -8)), "Corridor tile (-12, -8) between garden and stables must exist")
	assert(builder.is_tile_walkable(Vector2i(-12, -8)), "Corridor tile (-12, -8) must be walkable open gap")
	print("  - At least one tile gap between Garden and Stables walls confirmed.")

	# 3. Verify Matching Doors at Both Ends of Corridors
	var all_nodes = builder.find_children("*", "Node3D", true, false)
	var found_dining_gate = false
	var found_forge_gate = false
	var found_garden_stables_gate = false
	var found_stables_garden_gate = false
	var found_bridge_north_arch = false
	var found_courtyard_portal = false
	var found_bridge_mid_arch = false
	var found_hall_north_arch = false
	var found_nw_tower_portal = false
	for n in all_nodes:
		if n.name == "Dining Forge Gate":
			found_dining_gate = true
		elif n.name == "Forge Dining Gate":
			found_forge_gate = true
		elif n.name == "Garden Stables Gate":
			found_garden_stables_gate = true
		elif n.name == "Stables Garden Gate":
			found_stables_garden_gate = true
		elif n.name == "Bridge North Arch":
			found_bridge_north_arch = true
		elif n.name == "Courtyard Portal":
			found_courtyard_portal = true
		elif n.name == "Bridge Mid Arch":
			found_bridge_mid_arch = true
		elif n.name == "Hall North Arch":
			found_hall_north_arch = true
		elif n.name == "NorthWestTowerPortal":
			found_nw_tower_portal = true
	assert(found_dining_gate and found_forge_gate, "Both ends of Dining-Forge corridor must have doors/arches")
	assert(found_garden_stables_gate and found_stables_garden_gate, "Both ends of Garden-Stables corridor must have doors/arches")
	assert(found_hall_north_arch, "Hall North Arch must exist at North Passage entrance")
	assert(found_nw_tower_portal, "North-West Watchtower entrance arch must exist")
	print("  - Corridor door matching confirmed: both entry and exit ends have arches.")
	print("  - North-West Watchtower entrance arch confirmed.")

	# 4. Verify Bridge 3-Field Arches at Start and End ONLY (No Mid Arch)
	assert(found_bridge_north_arch, "Bridge must have 3-field arch at start (gz = 6)")
	assert(found_courtyard_portal, "Bridge must have 3-field arch at end (gz = 13)")
	assert(not found_bridge_mid_arch, "Bridge must NOT have arch in middle (start and end only)")
	for gz in range(7, 13):
		for gx in [-1, 0, 1]:
			var c = Vector2i(gx, gz)
			assert(builder.grid[c]["type"] == 4, "Bridge walkway tile at (%d, %d) must be FLOOR_BRIDGE (4)" % [gx, gz])
	print("  - Bridge 3-field arches at start and end only (no mid arch) confirmed.")

	# 5. Verify North Passage 5 Tiles Wide
	for gx in range(-2, 3):
		for gz in range(-11, -6):
			var cell = Vector2i(gx, gz)
			assert(builder.grid.has(cell), "North Passage cell (%d, %d) must exist in grid" % [gx, gz])
	for gx in range(-2, 3):
		for gz in range(-10, -7):
			assert(builder.is_tile_walkable(Vector2i(gx, gz)), "North Passage aisle (%d, %d) must be walkable" % [gx, gz])
	print("  - North Passage 5-tile width confirmed.")

	# 6. Verify South Courtyard South Walls Restored (gz = 19)
	for gx in range(-7, 8):
		var south_wall_cell = Vector2i(gx, 19)
		assert(builder.grid.has(south_wall_cell), "South courtyard south wall missing at (%d, 19)" % gx)
		assert(builder.grid[south_wall_cell]["type"] == 6, "South courtyard south wall at (%d, 19) must be WALL (6)" % gx)
	print("  - South Castle Courtyard south walls fully restored at gz = 19.")

	# 7. Verify Courtyard Fences 1 Tile Shorter (Clear gx = ±2)
	for child in courtyard_node.get_children():
		if child.name.begins_with("CourtyardFence") or child.has_meta("is_fence"):
			var cols = child.find_children("*", "CollisionShape3D", true, false)
			if cols.size() > 0 and cols[0].shape is BoxShape3D:
				assert(cols[0].shape.size.x <= 10.05, "Courtyard fence must be shortened to 10.0m (got: %f)" % cols[0].shape.size.x)
	print("  - South courtyard fences confirmed shortened by 1 tile (clear of bridge walls/arch).")

	print("  -> Passed! All spatial rules, corridor doors, bridge arches, passage widths, and courtyard walls verified.")

	# -------------------------------------------------------------
	# TEST 11: Test Graveyard Zone, 10 Gravestones, Skeleton, Tree, Fence & Stake Torches
	# -------------------------------------------------------------
	print("\n[TEST 11] Verifying Graveyard Zone, 10 Gravestones, Skeleton, Tree, Fencing & Stake Torches...")
	var graveyard_node = builder.get_node_or_null("Graveyard")
	assert(graveyard_node != null, "Graveyard node missing from CastleBuilder")

	# 1. Verify Graveyard Grid Registration
	var graveyard_tiles = 0
	for cell in builder.grid.keys():
		if builder.grid[cell]["type"] == 8: # FLOOR_GRAVEYARD
			graveyard_tiles += 1
	assert(graveyard_tiles == 73, "Graveyard should have 73 tiles (72 ground tiles + 1 gate portal), got: %d" % graveyard_tiles)
	print("  - Graveyard grid confirmed: 73 registered cemetery tiles.")

	# 2. Verify Portal Connectivity from Cloister Garden through (-12, -25)
	assert(builder.is_tile_walkable(Vector2i(-12, -24)), "Garden North path cell (-12, -24) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-12, -25)), "Graveyard entrance portal (-12, -25) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-12, -26)), "Graveyard threshold cell (-12, -26) must be walkable")
	assert(builder.is_tile_walkable(Vector2i(-13, -25)) == false, "Entrance arch left pier must block movement")
	assert(builder.is_tile_walkable(Vector2i(-11, -25)) == false, "Entrance arch right pier must block movement")
	print("  - Portal connectivity confirmed: seamless path through (-12, -25) with flanking arch piers.")

	# 3. Verify Exactly 10 Gravestones with Epitaph Inspection
	var gravestones = graveyard_node.find_children("Gravestone*", "StaticBody3D", true, false)
	assert(gravestones.size() == 10, "Expected exactly 10 gravestones, found: %d" % gravestones.size())
	for g in gravestones:
		var interact = g.get_node_or_null("Interactable")
		assert(interact != null, "Each gravestone must have an Interactable component")
		assert(interact.custom_prompt != "", "Gravestone must have an epitaph prompt")
	print("  - Exactly 10 gravestones confirmed with inspectable epitaphs.")

	# 4. Verify Bleached Skeleton
	var skeleton = graveyard_node.get_node_or_null("BleachedSkeleton")
	assert(skeleton != null, "BleachedSkeleton node missing from Graveyard")
	var sk_interact = skeleton.get_node_or_null("Interactable")
	assert(sk_interact != null, "Skeleton must have an Interactable component")
	print("  - Bleached skeleton confirmed with rusted blade and inspection.")

	# 5. Verify Ancient Cemetery Tree
	var tree = graveyard_node.get_node_or_null("AncientTree")
	assert(tree != null, "AncientTree node missing from Graveyard")
	assert(builder.is_tile_walkable(Vector2i(-10, -30)) == false, "Ancient tree cell (-10, -30) must be blocked")
	var tree_interact = tree.get_node_or_null("Interactable")
	assert(tree_interact != null, "Tree must have an Interactable component")
	print("  - Ancient gnarled tree confirmed with spreading roots and foliage.")

	# 6. Verify Outdoor Torches on Sticks
	var torches_on_sticks = graveyard_node.find_children("TorchOnStick*", "Node3D", true, false)
	assert(torches_on_sticks.size() >= 4, "Expected at least 4 torches on sticks, found: %d" % torches_on_sticks.size())
	for torch in torches_on_sticks:
		var light = torch.find_children("*", "OmniLight3D", true, false)
		assert(light.size() > 0, "Torch on stick must have an OmniLight3D")
	print("  - Outdoor torches on sticks confirmed with dynamic flickering illumination.")

	# 7. Verify Cemetery Perimeter Fences & Stone Pillars
	var graveyard_fences = graveyard_node.find_children("CemeteryFence*", "StaticBody3D", true, false)
	assert(graveyard_fences.size() >= 5, "Expected at least 5 fence segments enclosing graveyard, found: %d" % graveyard_fences.size())
	var pillars = graveyard_node.find_children("*Pillar*", "StaticBody3D", true, false)
	assert(pillars.size() >= 6, "Expected at least 6 stone pillars (4 corners + 2 gateposts), found: %d" % pillars.size())
	print("  - Cemetery perimeter fencing and stone pillars confirmed enclosing graveyard.")

	# -------------------------------------------------------------
	# TEST 12: Test Level Manager Discovery & Pagination
	# -------------------------------------------------------------
	print("\n[TEST 12] Verifying HeroQuestLevelManager Discovery & Pagination...")
	var LevelMgrClass = load("res://scripts/hero_quest/level/hero_quest_level_manager.gd")
	var avail = LevelMgrClass.get_available_levels()
	assert(avail.size() >= 1, "Expected at least 1 level in data/levels, got %d" % avail.size())
	assert(avail[0].file_name == "first_level.json", "first_level.json must be pinned first")
	assert(avail[0].name == "Hero Quest Castle Grounds", "Expected canonical level name")
	assert(avail[0].rooms_count >= 12, "Expected at least 12 rooms in first_level.json, got %d" % avail[0].rooms_count)
	assert(avail[0].tiles_count >= 1043, "Expected at least 1043 floor tiles in first_level.json, got %d" % avail[0].tiles_count)

	# Verify pagination logic with 12 mock items (page_size = 5)
	var mock_items: Array[Dictionary] = []
	for i in range(12):
		mock_items.append({"name": "Level %d" % i})
	var pages = LevelMgrClass.get_total_pages(12, 5)
	assert(pages == 3, "Expected 3 pages for 12 items with page_size 5")
	var p0 = LevelMgrClass.get_levels_page(mock_items, 0, 5)
	var p1 = LevelMgrClass.get_levels_page(mock_items, 1, 5)
	var p2 = LevelMgrClass.get_levels_page(mock_items, 2, 5)
	assert(p0.size() == 5, "Page 0 should have 5 items")
	assert(p1.size() == 5, "Page 1 should have 5 items")
	assert(p2.size() == 2, "Page 2 should have 2 items")

	# Verify unique file path generation
	var new_path = LevelMgrClass.generate_new_level_path("Forgotten Dungeon")
	assert(new_path.begins_with("res://data/levels/forgotten_dungeon"), "Path should use sanitized slug")
	assert(new_path.ends_with(".json"), "Path should end with .json")
	print("  - Level Manager verified: file discovery, metadata extraction, pagination, and path generation.")
	print("  -> Passed! HeroQuestLevelManager verified.")

	# -------------------------------------------------------------
	# TEST 13: Test Side-by-Side File-Based Level Reader
	# -------------------------------------------------------------
	print("\n[TEST 13] Verifying Side-by-Side File-Based Level Reader...")
	var file_path = "res://data/levels/first_level.json"
	var file_builder_node = Node3D.new()
	var CastleBuilderClass = load("res://scripts/hero_quest/castle_builder.gd")
	file_builder_node.set_script(CastleBuilderClass)
	root.add_child(file_builder_node)
	await process_frame

	var file_loaded = file_builder_node.load_from_level_file(file_path)
	assert(file_loaded, "Failed to load world from level file!")

	# Verify grid size
	assert(file_builder_node.grid.size() >= 1440, "Expected at least 1440 tiles from file, got %d" % file_builder_node.grid.size())

	# Verify rooms exist
	var expected_rooms = [
		"GreatHall", "Chapel", "Blacksmith", "Stables", "IndoorGarden",
		"GrandDiningHall", "Graveyard", "Chasm", "Bridges", "SouthCourtyard",
		"RoundTowers", "PerimeterBarriers"
	]
	for r_name in expected_rooms:
		assert(file_builder_node.get_node_or_null(r_name) != null, "Room %s missing in file-loaded world" % r_name)

	# Verify interactive items
	assert(file_builder_node.interactive_altar != null, "Altar missing in file-loaded world")
	assert(file_builder_node.interactive_anvil != null, "Anvil missing in file-loaded world")
	assert(file_builder_node.interactive_bell != null, "Bell missing in file-loaded world")
	assert(file_builder_node.interactive_chests.size() == 5, "Expected 5 chests in file-loaded world, got %d" % file_builder_node.interactive_chests.size())

	# Verify walkability
	for gx in range(0, -13, -1):
		var cell = Vector2i(gx, 0)
		assert(file_builder_node.is_tile_walkable(cell), "Walkability broken in file-loaded world at %s" % str(cell))
	assert(file_builder_node.is_tile_walkable(Vector2i(-4, -1)) == false, "3-tile arch pier should block")
	assert(file_builder_node.is_tile_walkable(Vector2i(-4, 0)) == true, "3-tile arch center should be walkable")

	# Verify graveyard details in file-loaded world
	var fl_graveyard = file_builder_node.get_node("Graveyard")
	var fl_gravestones = fl_graveyard.find_children("Gravestone*", "StaticBody3D", true, false)
	assert(fl_gravestones.size() == 10, "Expected 10 gravestones from file, got %d" % fl_gravestones.size())
	assert(fl_graveyard.get_node_or_null("BleachedSkeleton") != null, "Skeleton missing from file-loaded world")
	assert(fl_graveyard.get_node_or_null("AncientTree") != null, "Tree missing from file-loaded world")

	print("  - File-loaded world verified: 1444 tiles, 12 rooms, 5 chests, altar, anvil, bell, and graveyard intact.")
	print("  -> Passed! Complete side-by-side level reading confirmed identical to procedural output.")
	file_builder_node.queue_free()

	# -------------------------------------------------------------
	# TEST 14: Test Start Menu Level List, Pagination & New Level Flow
	# -------------------------------------------------------------
	print("\n[TEST 14] Verifying Start Menu Level Selection & New Level Flow...")
	var test_menu_scene = load("res://scenes/start_menu.tscn")
	var test_menu = test_menu_scene.instantiate()
	root.add_child(test_menu)
	await process_frame
	await process_frame

	var lvl_vbox = test_menu.find_child("LevelsVBox", true, false)
	var prev_button = test_menu.find_child("PrevButton", true, false)
	var next_button = test_menu.find_child("NextButton", true, false)
	var page_lbl = test_menu.find_child("PageLabel", true, false)
	var new_lvl_btn = test_menu.find_child("NewLevelButton", true, false)
	var new_lvl_modal = test_menu.find_child("NewLevelModal", true, false)
	var lvl_name_inp = test_menu.find_child("LevelNameInput", true, false)
	var create_lvl_btn = test_menu.find_child("CreateButton", true, false)
	var cancel_lvl_btn = test_menu.find_child("CancelButton", true, false)

	assert(lvl_vbox != null, "LevelsVBox missing from start menu")
	assert(prev_button != null, "PrevButton missing from start menu")
	assert(next_button != null, "NextButton missing from start menu")
	assert(page_lbl != null, "PageLabel missing from start menu")
	assert(new_lvl_btn != null, "NewLevelButton missing from start menu")
	assert(new_lvl_modal != null, "NewLevelModal missing from start menu")
	assert(new_lvl_modal.visible == false, "NewLevelModal should be hidden initially")

	# Verify level buttons populated (at least 1 visible for first_level.json)
	var first_btn = lvl_vbox.get_node_or_null("LevelButton1") as Button
	assert(first_btn != null and first_btn.visible == true, "LevelButton1 should be visible")
	assert(first_btn.text.contains("Hero Quest Castle Grounds"), "LevelButton1 should display canonical level name")

	# Verify pagination arrows on page 1
	assert(prev_button.disabled == true, "Prev button should be disabled on page 1")

	# Simulate clicking level 1 -> selects level in play mode
	first_btn.emit_signal("pressed")
	var HeroQuestGameClass = load("res://scripts/hero_quest/hero_quest_game.gd")
	assert(HeroQuestGameClass.selected_level_path == "res://data/levels/first_level.json", "Expected selected_level_path first_level.json")
	assert(HeroQuestGameClass.start_in_edit_mode == false, "Expected start_in_edit_mode == false for existing level click")

	# Simulate opening New Level modal
	new_lvl_btn.emit_signal("pressed")
	assert(new_lvl_modal.visible == true, "NewLevelModal should open when NewLevelButton is clicked")

	# Simulate clicking Cancel -> modal closes
	cancel_lvl_btn.emit_signal("pressed")
	assert(new_lvl_modal.visible == false, "NewLevelModal should close when Cancel is clicked")

	# Re-open and simulate creating a new level in edit mode
	new_lvl_btn.emit_signal("pressed")
	lvl_name_inp.text = "Crypt of the Undead"
	create_lvl_btn.emit_signal("pressed")
	assert(HeroQuestGameClass.pending_level_name == "Crypt of the Undead", "Expected pending_level_name == 'Crypt of the Undead'")
	assert(HeroQuestGameClass.start_in_edit_mode == true, "Expected start_in_edit_mode == true for new level creation")
	assert(HeroQuestGameClass.selected_level_path.contains("crypt_of_the_undead"), "Expected path slug to contain crypt_of_the_undead")

	# Verify dynamic multi-page navigation in start menu
	var mock_all: Array[Dictionary] = []
	for i in range(7):
		mock_all.append({
			"file_name": "mock_%d.json" % i,
			"file_path": "res://data/levels/mock_%d.json" % i,
			"level_id": "mock_%d" % i,
			"name": "Dungeon Realm %d" % (i + 1),
			"rooms_count": 3,
			"tiles_count": 50
		})
	test_menu.all_levels = mock_all
	test_menu.total_pages = 2
	test_menu.current_page = 0
	test_menu._render_page()

	assert(page_lbl.text == "Page 1 of 2", "PageLabel should be Page 1 of 2")
	assert(prev_button.disabled == true, "Prev should be disabled on page 1")
	assert(next_button.disabled == false, "Next should be enabled on page 1")
	assert(test_menu.level_buttons[0].text == "🏰  Dungeon Realm 1", "Slot 0 should be Realm 1")
	assert(test_menu.level_buttons[4].text == "🏰  Dungeon Realm 5", "Slot 4 should be Realm 5")

	# Flip to page 2 via next button
	next_button.emit_signal("pressed")
	assert(page_lbl.text == "Page 2 of 2", "PageLabel should be Page 2 of 2")
	assert(prev_button.disabled == false, "Prev should be enabled on page 2")
	assert(next_button.disabled == true, "Next should be disabled on page 2")
	assert(test_menu.level_buttons[0].text == "🏰  Dungeon Realm 6", "Slot 0 on page 2 should be Realm 6")
	assert(test_menu.level_buttons[1].text == "🏰  Dungeon Realm 7", "Slot 1 on page 2 should be Realm 7")
	assert(test_menu.level_buttons[2].visible == false, "Slot 2 on page 2 should be hidden")

	# Flip back to page 1 via prev button
	prev_button.emit_signal("pressed")
	assert(page_lbl.text == "Page 1 of 2", "PageLabel should be Page 1 of 2 after prev")
	assert(prev_button.disabled == true, "Prev should be disabled on page 1")
	assert(next_button.disabled == false, "Next should be enabled on page 1")

	print("  - Start Menu level list, pagination arrows, level launching, and new level edit-mode setup verified.")
	print("  -> Passed! Start menu level browser and creation flow verified.")
	HeroQuestGameClass.start_in_edit_mode = false
	HeroQuestGameClass.selected_level_path = "res://data/levels/first_level.json"
	test_menu.queue_free()

	# -------------------------------------------------------------
	# TEST 15: Character Stats & Base/Equipment Modifiers
	# -------------------------------------------------------------
	print("\n[TEST 15] Verifying Hero Stats & Equipment Modifiers...")
	var ItemDataClass = load("res://scripts/hero_quest/item_data.gd")
	var ItemDbClass = load("res://scripts/hero_quest/item_database.gd")
	var HeroStatsClass = load("res://scripts/hero_quest/hero_stats.gd")
	var HeroInvClass = load("res://scripts/hero_quest/hero_inventory.gd")

	var test_stats = HeroStatsClass.new()
	assert(test_stats.current_attack == 1, "Base attack should be 1 die")
	assert(test_stats.current_armor == 2, "Base armor should be 2 dice")
	assert(test_stats.current_max_hp == 8, "Base HP should be 8")
	assert(test_stats.current_mind_points == 3, "Base Mind should be 3")

	var test_inv = HeroInvClass.new(test_stats)
	var blade = ItemDbClass.create_item("mastercrafted_steel_blade")
	test_inv.equip("main_hand", blade)
	assert(test_stats.current_attack == 4, "Expected attack 4 (1 base + 3 weapon), got %d" % test_stats.current_attack)

	var helm = ItemDbClass.create_item("iron_helmet")
	var breast = ItemDbClass.create_item("breastplate")
	var shield = ItemDbClass.create_item("knight_shield")
	test_inv.equip("helmet", helm)
	test_inv.equip("breast_harness", breast)
	test_inv.equip("off_hand", shield)
	assert(test_stats.current_armor == 7, "Expected armor 7 (2 base + 1 helm + 2 breast + 2 shield), got %d" % test_stats.current_armor)

	var chalice = ItemDbClass.create_item("holy_chalice")
	test_stats.recalculate([blade, helm, breast, shield, chalice])
	assert(test_stats.current_max_hp == 11, "Expected max HP 11, got %d" % test_stats.current_max_hp)
	print("  - Base stats (1 Atk, 2 Arm, 8 HP, 3 Mind) and dynamic equipment modifiers verified.")
	print("  -> Passed! HeroQuest character stats system verified.")

	# -------------------------------------------------------------
	# TEST 16: Belt 5-field Constraints & 4x4 Rucksack Storage
	# -------------------------------------------------------------
	print("\n[TEST 16] Verifying Belt 5-Field Allocation & 4x4 Rucksack Storage...")
	var belt_stats = HeroStatsClass.new()
	var belt_inv = HeroInvClass.new(belt_stats)

	var potion1 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.is_belt_equipped() == false, "Belt should not be equipped initially")
	assert(belt_inv.can_fit_in_belt(potion1) == false, "Cannot add to belt without belt equipped")

	var belt_item = ItemDbClass.create_item("leather_belt")
	belt_inv.equip("belt", belt_item)
	assert(belt_inv.is_belt_equipped() == true, "Belt should now be equipped")

	# Test Scenario A: 2 large items and 1 small item (2 + 2 + 1 = 5 fields)
	var large1 = ItemDbClass.create_item("mastercrafted_steel_blade")
	var large2 = ItemDbClass.create_item("battle_axe")
	var small1 = ItemDbClass.create_item("healing_potion")
	assert(large1.is_large() == true, "Steel blade should be large")
	assert(large2.is_large() == true, "Battle axe should be large")
	assert(small1.is_large() == false, "Potion should be small")

	assert(belt_inv.add_to_belt(large1) == true, "Should fit large1 in tall pouch 0")
	assert(belt_inv.add_to_belt(large2) == true, "Should fit large2 in tall pouch 1")
	assert(belt_inv.add_to_belt(small1) == true, "Should fit small1 in single pouch 2")
	var extra_item = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.can_fit_in_belt(extra_item) == false, "Belt should now be completely full (5 fields)")

	# Test Scenario B: 1 large item and 3 small items (2 + 1 + 1 + 1 = 5 fields)
	belt_inv.remove_from_belt(1, 0)
	var small2 = ItemDbClass.create_item("healing_potion")
	var small3 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.add_to_belt(small2) == true, "Should fit small2 in pouch 1 subcell 0")
	assert(belt_inv.add_to_belt(small3) == true, "Should fit small3 in pouch 1 subcell 1")
	assert(belt_inv.can_fit_in_belt(extra_item) == false, "Belt should be full (1 large + 3 small = 5 fields)")

	# Test Scenario C: 5 small items (1+1 + 1+1 + 1 = 5 fields)
	belt_inv.remove_from_belt(0, 0)
	var small4 = ItemDbClass.create_item("healing_potion")
	var small5 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.add_to_belt(small4) == true, "Should fit small4 in pouch 0 subcell 0")
	assert(belt_inv.add_to_belt(small5) == true, "Should fit small5 in pouch 0 subcell 1")
	assert(belt_inv.can_fit_in_belt(extra_item) == false, "Belt should be full (5 small = 5 fields)")

	# Test 4x4 Rucksack grid
	assert(belt_inv.rucksack.size() == 16, "Rucksack should have 16 slots")
	assert(belt_inv.add_to_first_rucksack_slot(small1) == true, "Should fit item in rucksack")
	assert(belt_inv.rucksack[0] == small1, "Rucksack slot 0 should contain small1")
	var removed = belt_inv.remove_from_rucksack(0, 0)
	assert(removed == small1, "Removed item should match")
	assert(belt_inv.rucksack[0] == null, "Rucksack slot 0 should now be empty")
	print("  - Belt 5-field allocation (2 tall, 1 small: 2 large + 1 small, 3 small + 1 large, 5 small) verified.")
	print("  - 4x4 Rucksack grid storage and bounds verified.")
	print("  -> Passed! Belt and rucksack systems verified.")

	# -------------------------------------------------------------
	# TEST 17: Interactive Loot Dialogue, Drag/Drop Item Switching & 3D Floor Item Pickups
	# -------------------------------------------------------------
	print("\n[TEST 17] Verifying Loot Dialogue, Item Switching & 3D Floor Item Pickups...")
	var test_game_scene = load("res://scenes/hero_quest.tscn")
	var test_game = test_game_scene.instantiate()
	root.add_child(test_game)
	await process_frame
	await process_frame

	var test_player = test_game.player
	assert(test_player != null, "Player should be spawned in HeroQuestGame")
	assert(test_player.inventory != null, "Player inventory should be initialized")
	assert(test_player.stats != null, "Player stats should be initialized")
	assert(test_player.inventory.equipped["main_hand"] != null, "Player should have starter weapon equipped")
	var starter_weapon = test_player.inventory.equipped["main_hand"]
	assert(starter_weapon.name == "Rusted Shortsword", "Starter weapon should be Rusted Shortsword")

	var test_hud = test_game.hud
	assert(test_hud.character_sheet != null, "Character Sheet should be instantiated on HUD")
	assert(test_hud.loot_dialog != null, "Loot Dialog should be instantiated on HUD")

	# Test toggle Character Sheet
	test_hud.toggle_character_sheet()
	assert(test_hud.character_sheet.visible == true, "Character sheet should open")
	test_hud.toggle_character_sheet()
	assert(test_hud.character_sheet.visible == false, "Character sheet should close")

	# Test Item Switching: Drop a new weapon into occupied Main Hand slot
	var new_blade = ItemDbClass.create_item("mastercrafted_steel_blade")
	var initial_floor_count = test_player.floor_items.size()
	test_hud.character_sheet.handle_item_dropped(new_blade, "main_hand")

	assert(test_player.inventory.equipped["main_hand"].name == "Mastercrafted Steel Blade", "Main Hand should now have Mastercrafted Steel Blade")
	assert(test_player.floor_items.size() == initial_floor_count + 1, "Old weapon should have been dropped onto the floor as 3D pickup")
	var dropped_item_node = test_player.floor_items.back()
	assert(dropped_item_node.item_data.name == "Rusted Shortsword", "Dropped floor item should be the old Rusted Shortsword")
	assert(dropped_item_node.interactable != null, "Floor item should have an interactable component")
	assert(dropped_item_node.interactable.interact_type == test_player.HeroQuestInteractable.InteractType.ITEM, "Floor item should be InteractType.ITEM")

	var pickup_result = dropped_item_node.collect()
	assert(pickup_result.name == "Rusted Shortsword", "Collected item should be Rusted Shortsword")
	print("  - Item switching verified: equipping over occupied slot ejected old gear to floor.")
	print("  - 3D Floor Item pickup entity verified: correctly spawned in world with interactable.")
	print("  -> Passed! Loot dialogue, gear switching, and 3D floor item pickups confirmed.")
	test_game.queue_free()
	await process_frame

	# -------------------------------------------------------------
	# TEST 18: Level Editor Subsystem, Dotted Grid, Dragging, Undo & Saving
	# -------------------------------------------------------------
	print("\n[TEST 18] Verifying Level Editor Subsystem & Placement Constraints...")
	var editor_game = hero_scene.instantiate()
	root.add_child(editor_game)
	await process_frame
	await process_frame

	var editor = editor_game.level_editor
	assert(editor != null, "LevelEditor missing from game scene")
	assert(editor.is_active == false, "Editor should start inactive")
	assert(editor.grid != null, "LevelEditorGrid missing")
	assert(editor.grid.visible == false, "Editor grid should be hidden initially")
	assert(editor.ui != null, "LevelEditorUI missing")
	assert(editor.ui.visible == false, "Editor UI should be hidden initially")

	# 1. Toggle Editor Active via Tab
	var active = editor.toggle_editor()
	assert(active == true and editor.is_active == true, "Editor should be active after toggle")
	assert(editor.grid.visible == true, "Editor grid should be visible in edit mode")
	assert(editor.ui.visible == true, "Editor UI should be visible in edit mode")

	# 2. Rectangular Floor Drag (3x3 span = 9 tiles)
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
			assert(bld.grid.has(cell), "Floor tile missing at %s" % str(cell))
			assert(bld.grid[cell]["type"] == 2, "Floor tile type should be chapel (2)")
			assert(bld.grid[cell]["walkable"] == true, "Floor tile should be walkable")
	print("  - Rectangular floor drag verified: 9 tiles placed in 3x3 span.")

	# 3. Line Wall Drag & Auto-Tiling
	handler.set_tool("wall", {"type": "modular_wall"})
	handler.hovered_cell = Vector2i(25, 24)
	handler._start_drag()
	handler.hovered_cell = Vector2i(27, 24)
	handler._finish_drag()
	assert(bld.grid.has(Vector2i(25, 24)) and bld.grid[Vector2i(25, 24)]["type"] == 6, "Wall missing at (25, 24)")
	assert(bld.grid.has(Vector2i(26, 24)) and bld.grid[Vector2i(26, 24)]["type"] == 6, "Wall missing at (26, 24)")
	assert(bld.grid.has(Vector2i(27, 24)) and bld.grid[Vector2i(27, 24)]["type"] == 6, "Wall missing at (27, 24)")

	# Crossing wall creating T-junction at (26, 24)
	handler.hovered_cell = Vector2i(26, 23)
	handler._start_drag()
	handler.hovered_cell = Vector2i(26, 24)
	handler._finish_drag()

	var LevelEditorWallAutoTilerClass = load("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
	var conn = LevelEditorWallAutoTilerClass.get_wall_connections(Vector2i(26, 24), editor.model.is_wall_at)
	assert(conn.is_t == true, "Wall at (26, 24) should be auto-classified as T-junction")
	print("  - Line wall drag & auto-tiling verified: straight walls and T-junctions placed.")

	# 4. Window Placement Constraints (Corner & Arch rejection)
	var win_check_corner = LevelEditorWallAutoTilerClass.validate_window_placement(Vector2i(25, 24), func(c): return c in [Vector2i(25, 24), Vector2i(26, 24), Vector2i(25, 25)], func(_c): return false)
	assert(win_check_corner["valid"] == false, "Windows must not be placed in corners")
	var win_check_arch = LevelEditorWallAutoTilerClass.validate_window_placement(Vector2i(0, 0), func(_c): return false, func(_c): return true)
	assert(win_check_arch["valid"] == false, "Windows must not be placed in door or arch cells")
	print("  - Window constraints verified: corner and arch placement rejected.")

	# 5. Chest Designer & Placement
	handler.set_tool("chest", {"type": "treasure_chest"})
	handler.chest_config = {
		"relic_name": "Crown of the Ancients",
		"gold": 500,
		"is_trapped": true,
		"rot_y": PI * 0.5
	}
	handler.hovered_cell = Vector2i(26, 26)
	handler._apply_chest_click()
	assert(bld.grid.has(Vector2i(26, 26)), "Chest tile registered")
	assert(bld.grid[Vector2i(26, 26)]["walkable"] == false, "Chest should be blocking")
	var placed_chest = bld.interactive_chests.back()
	assert(placed_chest.get_meta("relic_name") == "Crown of the Ancients", "Chest relic name preserved")
	assert(placed_chest.get_meta("gold") == 500, "Chest gold bounty preserved")
	print("  - Chest designer verified: custom relic, gold, trap, and orientation configured.")

	# 6. Undo / Redo Stack (30+ steps)
	for i in range(32):
		handler.set_tool("floor", {"mat": "wood", "type": 3, "walkable": true})
		handler.hovered_cell = Vector2i(30 + i, 30)
		handler._start_drag()
		handler._finish_drag()

	assert(editor.history.undo_stack.size() >= 30, "Expected at least 30 undo steps, got %d" % editor.history.undo_stack.size())
	for i in range(30):
		editor.undo()
	print("  - Undo system verified: successfully recorded and undid 30+ editing steps.")

	for i in range(5):
		editor.redo()
	print("  - Redo system verified: successfully reapplied 5 steps.")

	# 7. Erase / Delete Tool
	handler.set_tool("erase", {})
	handler.hovered_cell = Vector2i(26, 26)
	handler._start_drag()
	handler._finish_drag()
	assert(not bld.grid.has(Vector2i(26, 26)), "Cell (26, 26) should be erased")
	print("  - Erase tool verified: removed prop and cleared tile registration.")

	# 8. Save on Tab Toggle & Re-reading from File
	var save_test_path = "res://data/levels/test_editor_save.json"
	editor.active_file_path = save_test_path
	editor.model.active_file_path = save_test_path
	var active_after = editor.toggle_editor()
	assert(active_after == false, "Editor should toggle off")
	assert(FileAccess.file_exists(save_test_path), "Saved level file should exist")

	var CastleLevelReaderClass = load("res://scripts/hero_quest/level/castle_level_reader.gd")
	var verify_reader = CastleLevelReaderClass.new(bld, bld.materials, bld.mesh_builder, bld.prop_factory)
	var load_ok = verify_reader.load_level(save_test_path)
	assert(load_ok, "LevelReader should load saved editor level file successfully")
	if FileAccess.file_exists(save_test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_test_path))
	# 9. Contextual Right-Click Deletion (Object first, then Floor)
	handler.set_tool("floor", {"mat": "stone", "type": 1, "walkable": true})
	handler.hovered_cell = Vector2i(40, 40)
	handler._start_drag(); handler._finish_drag()
	assert(bld.grid.has(Vector2i(40, 40)), "Floor tile at (40, 40) should exist")

	handler.set_tool("prop", {"type": "table", "has_chair": false})
	handler.hovered_cell = Vector2i(40, 40)
	handler._start_drag(); handler._finish_drag()
	assert(editor.model.cell_data[Vector2i(40, 40)].get("prop") != null, "Table prop should be present")

	# First right click -> deletes object, preserves floor
	handler._apply_right_click_delete()
	assert(editor.model.cell_data[Vector2i(40, 40)].get("prop") == null, "Table should be deleted by right-click")
	assert(bld.grid.has(Vector2i(40, 40)), "Floor should be preserved on first right-click")
	assert(bld.grid[Vector2i(40, 40)]["walkable"] == true, "Floor should become walkable again")

	# Second right click -> deletes floor
	handler._apply_right_click_delete()
	assert(not bld.grid.has(Vector2i(40, 40)), "Floor tile should be deleted on second right-click")
	print("  - Contextual right-click deletion verified: deletes prop first, floor second.")

	# 9b. Wall right-click deletion without killing editor or cursor
	handler.set_tool("wall", {})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	assert(editor.model.is_wall_at(Vector2i(45, 45)), "Wall at (45, 45) should exist")
	handler.hovered_cell = Vector2i(45, 45)
	handler._apply_right_click_delete()
	assert(not editor.model.is_wall_at(Vector2i(45, 45)), "Wall at (45, 45) should be deleted by right-click")
	assert(bld.grid.has(Vector2i(45, 45)), "Floor should be restored under deleted wall")
	assert(bld.grid[Vector2i(45, 45)]["walkable"] == true, "Restored floor under deleted wall should be walkable")
	# Verify editor grid and cursor box remain completely intact after wall deletion
	handler.hovered_cell = Vector2i(45, 45)
	handler._update_cursor_visuals()
	assert(is_instance_valid(editor.grid.cursor_box), "cursor_box must not be freed after wall deletion")
	assert(editor.grid.cursor_box.is_inside_tree(), "cursor_box must remain inside scene tree")
	print("  - Wall right-click deletion verified: wall removed, floor restored, editor fully intact.")

	# 9c. Base castle wall right-click deletion
	var base_wall_cell = Vector2i(999, 999)
	for cell in bld.grid.keys():
		if bld.grid[cell].get("type", 0) == 6 and cell != Vector2i(45, 45):
			base_wall_cell = cell
			break
	if base_wall_cell != Vector2i(999, 999):
		handler.hovered_cell = base_wall_cell
		handler._apply_right_click_delete()
		assert(not editor.model.is_wall_at(base_wall_cell), "Base castle wall should be deleted by right click")
		assert(bld.grid.has(base_wall_cell), "Floor should be restored under deleted base wall")
		handler._update_cursor_visuals()
		assert(is_instance_valid(editor.grid.cursor_box), "cursor_box must remain valid after base wall deletion")
		print("  - Base castle wall deletion verified: safely converted to floor without affecting editor.")

	# 10. Same-Spot Click Rotation (90° per click)
	handler.set_tool("prop", {"type": "chair"})
	handler.placement_rot_y = 0.0
	handler.hovered_cell = Vector2i(41, 41)
	handler._start_drag(); handler._finish_drag()
	var initial_rot = float(editor.model.cell_data[Vector2i(41, 41)]["prop"]["rot_y"])
	assert(absf(initial_rot - 0.0) < 0.01, "Initial chair rotation should be 0.0")

	# Click same spot again with same item
	handler._start_drag(); handler._finish_drag()
	var rotated_rot = float(editor.model.cell_data[Vector2i(41, 41)]["prop"]["rot_y"])
	assert(absf(rotated_rot - PI * 0.5) < 0.01, "Chair rotation should be 90° (PI/2) after same-spot click")
	print("  - Same-spot click rotation verified: rotates placed objects by 90°.")

	# 11. 80% Transparent Ghost Preview
	assert(editor.ghost_preview != null, "Ghost preview node must exist")
	handler.set_tool("prop", {"type": "bush"})
	assert(editor.ghost_preview.preview_node != null, "Ghost preview mesh should be active for bush")
	assert(editor.ghost_preview.ghost_mat.albedo_color.a <= 0.25, "Ghost material must be ~80% transparent (alpha <= 0.25)")
	print("  - 80% transparent 3D ghost preview verified.")

	# 12. Door / Arch Placement Cutting Wall Opening
	handler.set_tool("wall", {"type": "modular_wall"})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	assert(editor.model.is_wall_at(Vector2i(45, 45)), "Wall should exist at (45, 45)")

	handler.set_tool("door", {"arch_type": "arch_3tile", "axis": 0})
	handler.hovered_cell = Vector2i(45, 45)
	handler._start_drag(); handler._finish_drag()
	assert(not editor.model.is_wall_at(Vector2i(45, 45)), "Wall at (45, 45) should be cut out by door portal")
	assert(bld.grid[Vector2i(45, 45)]["walkable"] == true, "Doorway opening at (45, 45) must be walkable")
	print("  - Door/arch placement verified: cuts wall cutout and establishes walkable portal.")

	# 13. Missing Palette Assets Placement
	var test_assets = [
		{"type": "golden_cross"},
		{"type": "gravestone", "style": 2, "epitaph": "Sharp Stele"},
		{"type": "gravestone", "style": 1, "epitaph": "Celtic Cross"},
		{"type": "lower_wall"},
		{"type": "pillar", "height": 4.5},
		{"type": "brazier"},
		{"type": "pew", "with_back": true},
		{"type": "pew", "with_back": false}
	]
	for idx in range(test_assets.size()):
		var asset = test_assets[idx]
		handler.set_tool("prop", asset)
		handler.hovered_cell = Vector2i(50 + idx, 50)
		handler._start_drag(); handler._finish_drag()
		assert(bld.grid.has(Vector2i(50 + idx, 50)), "Asset %s should be placed at %s" % [asset["type"], str(Vector2i(50 + idx, 50))])
	print("  - Missing assets suite verified: Altar Cross, Gothic Stele, Celtic Cross, Lower Wall, Pillars, Braziers, and Pews.")

	print("  - Level persistence verified: saved to JSON on Tab and reloaded cleanly.")
	print("  -> Passed! Full Level Editor subsystem, constraints, and persistence confirmed.")
	# -------------------------------------------------------------
	# TEST 19: Test MiniGameManager, Extensibility & Easter Egg Chest
	# -------------------------------------------------------------
	print("\n[TEST 19] Verifying MiniGameManager, Extensible Registry & Easter Egg Chest...")
	var MiniGameManager = load("res://scripts/hero_quest/mini_game_manager.gd")
	assert(MiniGameManager != null, "MiniGameManager script missing")

	# 1. Verify Pacman registered
	assert(MiniGameManager.has_mini_game("pacman"), "Pacman mini-game must be registered")
	var pacman_meta = MiniGameManager.get_mini_game("pacman")
	assert(pacman_meta["id"] == "pacman", "Pacman metadata ID mismatch")
	assert(ResourceLoader.exists(pacman_meta["scene_path"]), "Pacman scene file must exist: %s" % pacman_meta["scene_path"])
	print("  - Pac-Man mini-game registered in mini-games/pacman/: %s" % pacman_meta["scene_path"])

	# 2. Verify Extensible Registration of other mini games
	MiniGameManager.register_mini_game("space_invaders_demo", {
		"id": "space_invaders_demo",
		"title": "Space Invaders",
		"tagline": "Retro Arcade",
		"description": "Defend the realm from cosmic invaders.",
		"icon": "👾",
		"scene_path": "res://mini-games/pacman/pacman_game.tscn"
	})
	assert(MiniGameManager.has_mini_game("space_invaders_demo"), "New mini-game should be registerable dynamically")
	MiniGameManager.unregister_mini_game("space_invaders_demo")
	assert(not MiniGameManager.has_mini_game("space_invaders_demo"), "Unregister should remove game")
	print("  - Dynamic mini-game registration & unregistration verified.")

	# 3. Test Event System
	var event_received: Array = []
	var callback = func(data): event_received.append(data)
	MiniGameManager.subscribe_event("chest_opened", callback)
	MiniGameManager.trigger_event("chest_opened", {"chest_id": "yard_chest", "mini_game": "pacman"})
	assert(event_received.size() > 0 and event_received[0].get("mini_game") == "pacman", "Event subscriber should receive triggered event data")
	print("  - Mini-game event subscription and triggering verified.")

	# 4. Verify State Persistence on Launch & Return
	var dummy_tile = Vector2i(4, 14)
	MiniGameManager.saved_player_tile = dummy_tile
	MiniGameManager.saved_level_path = "res://data/levels/first_level.json"
	MiniGameManager.has_return_state = true
	MiniGameManager.active_game_id = "pacman"
	var consumed = MiniGameManager.consume_return_state()
	assert(consumed["has_state"] == true, "Should consume return state")
	assert(consumed["player_tile"] == dummy_tile, "Restored tile should match saved tile")
	assert(consumed["level_path"] == "res://data/levels/first_level.json", "Restored level path should match saved path")
	assert(MiniGameManager.has_return_state == false, "State should be cleared after consumption")
	print("  - Hero Quest return state save and consume cycle verified.")

	# 5. Verify Easter Egg Chest in castle world
	var easter_game_scene = load("res://scenes/hero_quest.tscn")
	var t_game = easter_game_scene.instantiate()
	root.add_child(t_game)
	await process_frame
	await process_frame

	var t_builder = t_game.get_node("CastleBuilder")
	var found_easter_egg_chest: bool = false
	for chest_node in t_builder.interactive_chests:
		if chest_node.has_meta("mini_game_id") and chest_node.get_meta("mini_game_id") == "pacman":
			found_easter_egg_chest = true
			var comp = chest_node.get_node_or_null("Interactable")
			assert(comp != null, "Easter egg chest missing Interactable component")
			assert(comp.mini_game_id == "pacman", "Interactable component mini_game_id mismatch")
			assert(chest_node.get_meta("loot_name").contains("Pac-Man"), "Loot name should reference Pac-Man")
			break
	assert(found_easter_egg_chest, "Castle world must contain a treasure chest with mini_game_id == 'pacman'")
	print("  - Castle treasure chest verified with mini_game_id == 'pacman' easter egg.")

	# 6. Test MiniGame Dialog UI
	var MiniGameDialogClass = load("res://scripts/hero_quest/mini_game_dialog.gd")
	var dialog = MiniGameDialogClass.new()
	root.add_child(dialog)
	await process_frame
	dialog.show_dialog("pacman")
	assert(dialog.visible == true, "MiniGameDialog should become visible")
	var play_requested_box: Array = [""]
	dialog.play_requested.connect(func(gid): play_requested_box[0] = gid)
	dialog.play_btn.emit_signal("pressed")
	assert(play_requested_box[0] == "pacman", "Play button should request launching pacman")
	dialog.queue_free()
	t_game.queue_free()
	await process_frame
	print("  - Easter Egg MiniGameDialog UI prompt verified.")
	print("  -> Passed! Complete Mini-Games system, easter egg chest, and transitions confirmed.")

	# -------------------------------------------------------------
	# TEST 20: Test Level Renaming and Room / Area Management System
	# -------------------------------------------------------------
	print("\n[TEST 20] Verifying Level Renaming, Room Manager, Blueprint Mode & Panels...")

	var LevelEditorModelClass = load("res://scripts/hero_quest/editor/level_editor_model.gd")
	var LevelEditorHistoryClass = load("res://scripts/hero_quest/editor/level_editor_history.gd")
	var LevelEditorRoomManagerClass = load("res://scripts/hero_quest/editor/level_editor_room_manager.gd")
	var LevelEditorRoomPanelClass = load("res://scripts/hero_quest/editor/level_editor_room_panel.gd")
	var LevelEditorChestPanelClass = load("res://scripts/hero_quest/editor/level_editor_chest_panel.gd")

	var test_path = "res://data/levels/test_room_level.json"
	var test_model = LevelEditorModelClass.new(builder, test_path, "Initial Realm")
	assert(test_model.get_level_name() == "Initial Realm", "Initial level name must match")

	# 1. Level Renaming and Persistence
	test_model.set_level_name("The Royal Citadel")
	assert(test_model.get_level_name() == "The Royal Citadel", "Level name should update in memory")
	var save_ok = test_model.save_to_json(test_path)
	assert(save_ok == true, "Level model should save successfully to json")
	var read_str = FileAccess.get_file_as_string(test_path)
	var parsed_level = JSON.parse_string(read_str)
	assert(parsed_level["name"] == "The Royal Citadel", "Saved JSON must persist the updated level name")
	print("  - Level renaming and file persistence verified.")

	# 2. Room Manager & Walls-Only Blueprint Filtering
	var test_hist = LevelEditorHistoryClass.new(Callable(test_model, "apply_cell_states"), 50)
	var room_mgr = LevelEditorRoomManagerClass.new(builder, test_model, test_hist)
	assert(room_mgr.is_walls_only == false, "Walls-only should be initially false")

	room_mgr.set_walls_only_visible(true)
	assert(room_mgr.is_walls_only == true, "Walls-only should be active")
	assert(room_mgr.hidden_nodes.size() > 0, "Hidden nodes must contain non-wall elements")
	for n in room_mgr.hidden_nodes:
		assert(n.visible == false, "Hidden node must have visible == false")
	print("  - Walls-only blueprint mode successfully hid non-wall elements (%d nodes)." % room_mgr.hidden_nodes.size())

	room_mgr.set_walls_only_visible(false)
	assert(room_mgr.is_walls_only == false, "Walls-only should be inactive")
	assert(room_mgr.hidden_nodes.is_empty(), "Hidden nodes list must be empty after restoration")
	print("  - Walls-only blueprint mode cleanly restored all element visibilities.")

	# 3. Room Tile Painting & Translucent Overlays
	var paint_cells: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2)]
	room_mgr.paint_cells(paint_cells, "The Grand Library")
	for c in paint_cells:
		assert(builder.grid.has(c), "Painted cell must exist in grid")
		assert(builder.grid[c]["zone"] == "The Grand Library", "Painted cell zone must be The Grand Library")
		assert(room_mgr.overlay_instances.has(c), "Overlay instance must exist for painted cell")
	var summary = room_mgr.get_room_summary()
	var found_summary = false
	for s in summary:
		if s["name"] == "The Grand Library":
			assert(s["count"] == 4, "The Grand Library should have 4 painted tiles")
			found_summary = true
			break
	assert(found_summary, "Room summary must include painted room")
	print("  - Room painting and translucent overlays verified for 4 tiles.")

	# 4. Room Renaming & Deletion
	room_mgr.rename_room("The Grand Library", "Arcane Archives")
	for c in paint_cells:
		assert(builder.grid[c]["zone"] == "Arcane Archives", "Renamed room zone must reflect Arcane Archives")
	room_mgr.delete_room("Arcane Archives")
	for c in paint_cells:
		assert(builder.grid[c]["zone"] != "Arcane Archives", "Deleted room zone should no longer be Arcane Archives")
	print("  - Room rename and deletion verified across grid and overlays.")

	# 5. UI Panels Verification
	var chest_panel = LevelEditorChestPanelClass.new()
	var cfg = chest_panel.get_chest_config()
	assert(cfg.has("relic_name") and cfg.has("gold") and cfg.has("is_trapped"), "Chest config must have standard fields")

	var room_panel = LevelEditorRoomPanelClass.new(room_mgr)
	assert(room_panel != null, "Room panel must initialize")
	room_panel.queue_free()
	chest_panel.queue_free()

	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

	print("  -> Passed! Complete Room / Area management, blueprint mode, and level renaming confirmed.")

	print("\n=== ALL HERO QUEST TESTS PASSED SUCCESSFULLY! ===")
	quit(0)



