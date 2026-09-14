class_name TestSuiteCharacterAndItems
extends RefCounted

static func run(tree: SceneTree) -> void:
	print("\n=== [SUITE 4] HERO CHARACTER, INVENTORY, ITEMS & MINI-GAMES ===")

	var ItemDbClass = load("res://scripts/hero_quest/item_database.gd")
	var HeroStatsClass = load("res://scripts/hero_quest/hero_stats.gd")
	var HeroInvClass = load("res://scripts/hero_quest/hero_inventory.gd")

	# -------------------------------------------------------------
	# TEST 15: Character Stats & Base/Equipment Modifiers
	# -------------------------------------------------------------
	print("\n[TEST 15] Verifying Hero Stats & Equipment Modifiers...")
	var test_stats = HeroStatsClass.new()
	assert(test_stats.current_attack == 1, "Base attack should be 1 die")
	assert(test_stats.current_armor == 2, "Base armor should be 2 dice")
	assert(test_stats.current_max_hp == 8, "Base HP should be 8")
	assert(test_stats.current_mind_points == 3, "Base Mind should be 3")

	var test_inv = HeroInvClass.new(test_stats)
	var blade = ItemDbClass.create_item("mastercrafted_steel_blade")
	test_inv.equip("main_hand", blade)
	assert(test_stats.current_attack == 4, "Expected attack 4")

	var helm = ItemDbClass.create_item("iron_helmet")
	var breast = ItemDbClass.create_item("breastplate")
	var shield = ItemDbClass.create_item("knight_shield")
	test_inv.equip("helmet", helm)
	test_inv.equip("breast_harness", breast)
	test_inv.equip("off_hand", shield)
	assert(test_stats.current_armor == 7, "Expected armor 7")

	var chalice = ItemDbClass.create_item("holy_chalice")
	test_stats.recalculate([blade, helm, breast, shield, chalice])
	assert(test_stats.current_max_hp == 11, "Expected max HP 11")
	print("  - Base stats and dynamic equipment modifiers verified.")
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

	var large1 = ItemDbClass.create_item("mastercrafted_steel_blade")
	var large2 = ItemDbClass.create_item("battle_axe")
	var small1 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.add_to_belt(large1) == true, "Should fit large1 in tall pouch 0")
	assert(belt_inv.add_to_belt(large2) == true, "Should fit large2 in tall pouch 1")
	assert(belt_inv.add_to_belt(small1) == true, "Should fit small1 in single pouch 2")
	var extra_item = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.can_fit_in_belt(extra_item) == false, "Belt should now be completely full")

	belt_inv.remove_from_belt(1, 0)
	var small2 = ItemDbClass.create_item("healing_potion")
	var small3 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.add_to_belt(small2) == true)
	assert(belt_inv.add_to_belt(small3) == true)
	assert(belt_inv.can_fit_in_belt(extra_item) == false)

	belt_inv.remove_from_belt(0, 0)
	var small4 = ItemDbClass.create_item("healing_potion")
	var small5 = ItemDbClass.create_item("healing_potion")
	assert(belt_inv.add_to_belt(small4) == true)
	assert(belt_inv.add_to_belt(small5) == true)
	assert(belt_inv.can_fit_in_belt(extra_item) == false)

	assert(belt_inv.rucksack.size() == 16, "Rucksack should have 16 slots")
	assert(belt_inv.add_to_first_rucksack_slot(small1) == true)
	assert(belt_inv.rucksack[0] == small1)
	var removed = belt_inv.remove_from_rucksack(0, 0)
	assert(removed == small1)
	assert(belt_inv.rucksack[0] == null)
	print("  - Belt 5-field allocation and 4x4 Rucksack grid storage verified.")
	print("  -> Passed! Belt and rucksack systems verified.")

	# -------------------------------------------------------------
	# TEST 17: Interactive Loot Dialogue, Drag/Drop Item Switching & 3D Floor Item Pickups
	# -------------------------------------------------------------
	print("\n[TEST 17] Verifying Loot Dialogue, Item Switching & 3D Floor Item Pickups...")
	var test_game_scene = load("res://scenes/hero_quest.tscn")
	var test_game = test_game_scene.instantiate()
	tree.root.add_child(test_game)
	await tree.process_frame
	await tree.process_frame

	var test_player = test_game.player
	var test_hud = test_game.hud
	test_hud.toggle_character_sheet()
	assert(test_hud.character_sheet.visible == true)
	test_hud.toggle_character_sheet()
	assert(test_hud.character_sheet.visible == false)

	var new_blade = ItemDbClass.create_item("mastercrafted_steel_blade")
	var initial_floor_count = test_player.floor_items.size()
	test_hud.character_sheet.handle_item_dropped(new_blade, "main_hand")

	assert(test_player.inventory.equipped["main_hand"].name == "Mastercrafted Steel Blade")
	assert(test_player.floor_items.size() == initial_floor_count + 1)
	var dropped_item_node = test_player.floor_items.back()
	assert(dropped_item_node.item_data.name == "Rusted Shortsword")
	assert(dropped_item_node.interactable != null)

	var pickup_result = dropped_item_node.collect()
	assert(pickup_result.name == "Rusted Shortsword")
	print("  - Item switching and 3D floor item pickups confirmed.")
	print("  -> Passed! Loot dialogue, gear switching, and 3D floor item pickups confirmed.")
	test_game.queue_free()
	await tree.process_frame

	# -------------------------------------------------------------
	# TEST 19: Test MiniGameManager, Extensibility & Easter Egg Chest
	# -------------------------------------------------------------
	print("\n[TEST 19] Verifying MiniGameManager, Extensible Registry & Easter Egg Chest...")
	var MiniGameManager = load("res://scripts/hero_quest/mini_game_manager.gd")
	assert(MiniGameManager.has_mini_game("pacman"))
	var pacman_meta = MiniGameManager.get_mini_game("pacman")
	assert(pacman_meta["id"] == "pacman")

	MiniGameManager.register_mini_game("space_invaders_demo", {
		"id": "space_invaders_demo", "title": "Space Invaders", "tagline": "Retro Arcade",
		"description": "Defend realm", "icon": "👾", "scene_path": "res://mini-games/pacman/pacman_game.tscn"
	})
	assert(MiniGameManager.has_mini_game("space_invaders_demo"))
	MiniGameManager.unregister_mini_game("space_invaders_demo")
	assert(not MiniGameManager.has_mini_game("space_invaders_demo"))

	var event_received: Array = []
	MiniGameManager.subscribe_event("chest_opened", func(data): event_received.append(data))
	MiniGameManager.trigger_event("chest_opened", {"chest_id": "yard_chest", "mini_game": "pacman"})
	assert(event_received.size() > 0 and event_received[0].get("mini_game") == "pacman")

	var dummy_tile = Vector2i(4, 14)
	MiniGameManager.saved_player_tile = dummy_tile
	MiniGameManager.saved_level_path = "res://data/levels/first_level.json"
	MiniGameManager.has_return_state = true
	MiniGameManager.active_game_id = "pacman"
	var consumed = MiniGameManager.consume_return_state()
	assert(consumed["has_state"] == true and consumed["player_tile"] == dummy_tile)

	var easter_game_scene = load("res://scenes/hero_quest.tscn")
	var t_game = easter_game_scene.instantiate()
	tree.root.add_child(t_game)
	await tree.process_frame
	await tree.process_frame

	var t_builder = t_game.get_node("CastleBuilder")
	var found_easter_egg_chest: bool = false
	for chest_node in t_builder.interactive_chests:
		if chest_node.has_meta("mini_game_id") and chest_node.get_meta("mini_game_id") == "pacman":
			found_easter_egg_chest = true
			break
	assert(found_easter_egg_chest, "Castle world must contain a treasure chest with mini_game_id == 'pacman'")

	var MiniGameDialogClass = load("res://scripts/hero_quest/mini_game_dialog.gd")
	var dialog = MiniGameDialogClass.new()
	tree.root.add_child(dialog)
	await tree.process_frame
	dialog.show_dialog("pacman")
	assert(dialog.visible == true)
	var play_requested_box: Array = [""]
	dialog.play_requested.connect(func(gid): play_requested_box[0] = gid)
	dialog.play_btn.emit_signal("pressed")
	assert(play_requested_box[0] == "pacman")
	dialog.queue_free()
	t_game.queue_free()
	await tree.process_frame
	print("  -> Passed! Complete Mini-Games system, easter egg chest, and transitions confirmed.")

	# -------------------------------------------------------------
	# TEST 26: Camera Occlusion Mesh Fading
	# -------------------------------------------------------------
	print("\n[TEST 26] Verifying HeroQuestCameraOcclusion Mesh Fading...")
	var HeroQuestCameraOcclusionClass = load("res://scripts/hero_quest/hero_quest_camera_occlusion.gd")
	var occlusion_node = HeroQuestCameraOcclusionClass.new()
	tree.root.add_child(occlusion_node)

	var imm_inst = MeshInstance3D.new()
	imm_inst.mesh = ImmediateMesh.new()
	tree.root.add_child(imm_inst)

	var box_inst = MeshInstance3D.new()
	box_inst.mesh = BoxMesh.new()
	tree.root.add_child(box_inst)

	occlusion_node._fade_mesh(imm_inst)
	occlusion_node._fade_mesh(box_inst)
	assert(occlusion_node.faded_meshes.has(imm_inst) and occlusion_node.faded_meshes.has(box_inst))
	assert(imm_inst.material_override != null and box_inst.material_override != null)

	occlusion_node._restore_mesh(imm_inst)
	occlusion_node._restore_mesh(box_inst)
	assert(imm_inst.material_override == null and box_inst.material_override == null)

	imm_inst.queue_free(); box_inst.queue_free(); occlusion_node.queue_free()
	print("  -> Passed! HeroQuestCameraOcclusion robust mesh fading confirmed.")

	# -------------------------------------------------------------
	# TEST 27: HeroBox Freed Instance Safety & Proximity Checks
	# -------------------------------------------------------------
	print("\n[TEST 27] Verifying HeroBox Freed Instance Safety & Proximity Checks...")
	var HeroBoxScene = load("res://scenes/hero_quest/hero_box.tscn")
	var t27_player = HeroBoxScene.instantiate()
	tree.root.add_child(t27_player)

	var t27_builder = Node3D.new()
	t27_builder.set_script(load("res://scripts/hero_quest/castle_builder.gd"))
	tree.root.add_child(t27_builder)
	t27_builder.register_tile(Vector2i(0, 0), 1, true, "TestHall")
	t27_builder.register_tile(Vector2i(0, -1), 1, false, "TestHall")

	var doomed_prop = Node3D.new()
	tree.root.add_child(doomed_prop)
	t27_builder.grid[Vector2i(0, -1)]["prop"] = doomed_prop
	t27_builder.interactive_altar = doomed_prop
	t27_player.setup(t27_builder, null, Vector2i(0, 0))
	doomed_prop.free()

	var fetched_prop = t27_player._get_prop_at_cell(Vector2i(0, -1))
	assert(fetched_prop == null, "_get_prop_at_cell must return null for freed prop instance")
	t27_player._check_interaction_proximity()
	assert(t27_player.nearby_interactable == null)
	t27_player._try_interact()

	t27_player.queue_free()
	t27_builder.queue_free()
	print("  -> Passed! HeroBox freed instance resilience confirmed.")
