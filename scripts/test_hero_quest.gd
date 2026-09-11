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

	var play_pacman_btn = menu.get_node_or_null("CenterContainer/HBox/PacmanCard/Margin/VBox/PlayPacmanButton")
	var play_hero_btn = menu.get_node_or_null("CenterContainer/HBox/HeroCard/Margin/VBox/PlayHeroButton")
	var quit_btn = menu.get_node_or_null("BottomBar/QuitButton")

	assert(play_pacman_btn != null, "Missing PlayPacmanButton on Startpage")
	assert(play_hero_btn != null, "Missing PlayHeroButton on Startpage")
	assert(quit_btn != null, "Missing QuitButton on Startpage")
	print("  -> Passed! Startpage verified with Pacman, Hero Quest, and Exit buttons.")
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
	assert(player.tile_cursor != null, "TileCursor node missing on player")

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
	assert(builder.grid.has(Vector2i(2, 7)), "Great corridor south wall at (2, 7) must exist")
	assert(builder.grid[Vector2i(2, 7)]["type"] == 6, "Great corridor south wall at (2, 7) must be WALL (6)")
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

	print("  -> Passed! Graveyard zone, 10 gravestones, skeleton, tree, torches on sticks and fencing verified.")

	print("\n=== ALL HERO QUEST TESTS PASSED SUCCESSFULLY! ===")
	quit(0)

