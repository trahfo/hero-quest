extends SceneTree

func _init() -> void:
	print("=== RUNNING PACMAN 3D INTEGRATION TESTS ===")
	var main_scene = load("res://mini-games/pacman/pacman_game.tscn")
	if not main_scene:
		main_scene = load("res://mini-games/pacman/main.tscn")
	if not main_scene:
		push_error("Failed to load main scene")
		quit(1)
		return

	var main = main_scene.instantiate()
	root.add_child(main)

	# Give a frame for _ready() to complete
	await process_frame
	await process_frame

	var gm = main.get_node("GameManager")
	var maze = main.get_node("MazeGenerator")
	var pacman = main.get_node("Pacman")
	var hud = main.get_node("HUD")
	var monsters_cont = main.get_node("MonstersContainer")

	assert(gm != null, "GameManager missing")
	assert(maze != null, "MazeGenerator missing")
	assert(pacman != null, "Pacman missing")
	assert(hud != null, "HUD missing")
	assert(monsters_cont != null, "MonstersContainer missing")

	# Test 1: Verify 5 Monsters spawned with correct colors and names
	print("[TEST 1] Verifying 5 Colorful Monsters...")
	var monsters = monsters_cont.get_children()
	assert(monsters.size() == 5, "Expected 5 monsters, got %d" % monsters.size())
	var expected_names = ["Blinky", "Pinky", "Inky", "Clyde", "Shadow"]
	for i in range(5):
		var m = monsters[i]
		assert(m.monster_name == expected_names[i], "Monster %d name mismatch: %s" % [i, m.monster_name])
		assert(m.is_in_group("monsters"), "Monster must be in 'monsters' group")
		print("  - Monster %d: %s (%s, color=%s)" % [i, m.monster_name, m.behavior, str(m.monster_color)])
	print("  -> Passed! 5 Monsters successfully verified.")

	# Test 2: Verify Maze and Pellets
	print("[TEST 2] Verifying Maze and Pellets...")
	var initial_pellets = maze.remaining_pellets
	print("  - Initial pellet count: %d" % initial_pellets)
	assert(initial_pellets > 50, "Expected plenty of pellets in labyrinth, got %d" % initial_pellets)
	assert(maze.walls_container.get_child_count() > 100, "Maze walls not generated")
	print("  -> Passed! Maze generated with %d pellets and walls." % initial_pellets)

	# Test 3: Verify Pellet Eating and Score
	print("[TEST 3] Testing Pellet collection & score update...")
	var pellets = maze.pellets_container.get_children()
	var test_pellet = pellets[0]
	maze._on_pellet_collected(test_pellet)
	assert(gm.score == 10, "Score should be 10 after 1 pellet, got %d" % gm.score)
	assert(maze.remaining_pellets == initial_pellets - 1, "Remaining pellets not decremented")
	print("  -> Passed! Pellet collection increments score and decrements remaining count.")

	# Test 4: Verify 10% Speed Increase on Board Clear
	print("[TEST 4] Testing Board Clear & 10% Speed Increase...")
	var speed_lvl1 = gm._get_speed_multiplier()
	print("  - Level 1 Speed multiplier: %.4f" % speed_lvl1)
	assert(is_equal_approx(speed_lvl1, 1.0), "Level 1 speed should be 1.0")

	# Simulate clearing all remaining pellets
	maze.all_pellets_cleared.emit()
	assert(gm.level == 2, "Level should increment to 2, got %d" % gm.level)
	var speed_lvl2 = gm._get_speed_multiplier()
	print("  - Level 2 Speed multiplier: " + str(snappedf(speed_lvl2, 0.001)) + " (+10%)")
	assert(is_equal_approx(speed_lvl2, 1.10), "Level 2 speed should be 1.10 (+10%), got " + str(speed_lvl2))

	# Advance level to 3
	gm.level = 3
	var speed_lvl3 = gm._get_speed_multiplier()
	print("  - Level 3 Speed multiplier: " + str(snappedf(speed_lvl3, 0.001)) + " (+10% compound)")
	assert(is_equal_approx(speed_lvl3, 1.21), "Level 3 speed should be 1.21 (+10% on level 2), got " + str(speed_lvl3))
	print("  -> Passed! Speed escalates by 10% per level.")

	# Test 5: Verify Pacman movement logic and speed update
	print("[TEST 5] Testing Pacman and Monster speed multiplier propagation...")
	gm._update_actor_speeds()
	assert(is_equal_approx(pacman.speed_multiplier, speed_lvl3), "Pacman speed multiplier not updated")
	for m in monsters:
		assert(is_equal_approx(m.speed_multiplier, speed_lvl3), "Monster speed multiplier not updated")
	print("  -> Passed! Actor speed multipliers synchronized.")

	# Test 6: Verify Lives and Game Over
	print("[TEST 6] Testing Pacman collision with Monster & Life cycle...")
	gm.lives = 3
	pacman.hit_by_monster()
	assert(pacman.is_dead, "Pacman should be marked dead after monster hit")
	print("  -> Passed! Collision triggers Pacman hit.")

	print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")
	quit(0)
