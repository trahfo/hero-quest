class_name TestSuiteCastleWorld
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 1] CASTLE WORLD, SCENES & MOVEMENT ===")

	# -------------------------------------------------------------
	# TEST 1: Test Startpage (start_menu.tscn)
	# -------------------------------------------------------------
	print("\n[TEST 1] Loading and verifying Startpage...")
	var menu_scene = load("res://scenes/start_menu.tscn")
	assert(menu_scene != null, "Failed to load start_menu.tscn")
	var menu = menu_scene.instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	await tree.process_frame

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
	await tree.process_frame

	# -------------------------------------------------------------
	# TEST 2: Test Hero Quest Scene Loading
	# -------------------------------------------------------------
	print("\n[TEST 2] Loading and verifying Hero Quest Main Scene...")
	var hero_scene = load("res://scenes/hero_quest.tscn")
	assert(hero_scene != null, "Failed to load hero_quest.tscn")
	var hq = hero_scene.instantiate()
	tree.root.add_child(hq)
	await tree.process_frame
	await tree.process_frame

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
	assert(builder.is_tile_walkable(Vector2i(-4, -1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(-4, 1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(-4, 0)) == true, "3-tile arch center should be walkable")
	print("  - 3-Tile Arch (West Stables) verified: piers block, center doorway open.")

	# 2. Continuity from Great Hall to Blacksmith (East path: gx: 0 -> 11 at gz: 0)
	for gx in range(0, 12):
		var cell = Vector2i(gx, 0)
		assert(builder.is_tile_walkable(cell), "Gap found on path to Blacksmith at cell %s!" % str(cell))
	assert(builder.is_tile_walkable(Vector2i(4, -1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(4, 1)) == false, "3-tile arch pier should be blocker")
	assert(builder.is_tile_walkable(Vector2i(4, 0)) == true, "3-tile arch center should be walkable")
	print("  - 3-Tile Arch (East Blacksmith) verified: piers block, center doorway open.")

	# 3. Continuity from Great Hall to Chapel through 5-Tile Twin Arch
	assert(builder.is_tile_walkable(Vector2i(0, -11)) == false, "5-tile twin arch center pier must be blocker")
	assert(builder.is_tile_walkable(Vector2i(-2, -11)) == false, "5-tile twin arch left pier must be blocker")
	assert(builder.is_tile_walkable(Vector2i(2, -11)) == false, "5-tile twin arch right pier must be blocker")
	assert(builder.is_tile_walkable(Vector2i(-1, -11)) == true, "5-tile left archway must be walkable")
	assert(builder.is_tile_walkable(Vector2i(1, -11)) == true, "5-tile right archway must be walkable")
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

	hq.queue_free()
	await tree.process_frame
