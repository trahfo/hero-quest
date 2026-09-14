extends Node

enum State { PLAYING, LEVEL_CLEARED, RESPAWNING, GAME_OVER }

@export var maze_node: Node3D
@export var pacman_node: CharacterBody3D
@export var hud_node: CanvasLayer
@export var sound_node: Node
@export var monsters_container: Node3D

var monster_scene: PackedScene = preload("res://mini-games/pacman/monster.tscn")

var current_state: State = State.PLAYING
var score: int = 0
var level: int = 1
var lives: int = 3
var time_elapsed: float = 0.0

var monsters: Array[CharacterBody3D] = []

const MONSTER_CONFIGS = [
	{ "name": "Blinky", "color": Color(1.0, 0.2, 0.25), "behavior": 0 },     # Red - Chase
	{ "name": "Pinky",  "color": Color(1.0, 0.45, 0.75), "behavior": 1 },    # Pink - Ambush
	{ "name": "Inky",   "color": Color(0.1, 0.85, 1.0),  "behavior": 2 },    # Cyan - Patrol
	{ "name": "Clyde",  "color": Color(1.0, 0.55, 0.1),  "behavior": 3 },    # Orange - Scatter Close
	{ "name": "Shadow", "color": Color(0.65, 0.2, 1.0),  "behavior": 4 }     # Purple - Random Roam
]

func _ready() -> void:
	# Enable fullscreen by default
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if maze_node:
		maze_node.pellet_eaten.connect(_on_pellet_eaten)
		maze_node.all_pellets_cleared.connect(_on_all_pellets_cleared)

	if hud_node:
		hud_node.restart_pressed.connect(restart_game)

	if pacman_node:
		pacman_node.died.connect(_on_pacman_died)
		pacman_node.setup(maze_node, maze_node.pacman_spawn)

	_spawn_monsters()
	_update_hud_all()

func _spawn_monsters() -> void:
	monsters.clear()
	for child in monsters_container.get_children():
		child.queue_free()

	for i in range(5):
		var cfg = MONSTER_CONFIGS[i]
		var monster = monster_scene.instantiate()
		var spawn_cell = maze_node.monster_spawns.get(i, Vector2i(9, 8))
		monsters_container.add_child(monster)
		monster.setup(maze_node, pacman_node, spawn_cell, cfg.name, cfg.color, cfg.behavior)
		monster.caught_pacman.connect(_on_pacman_caught)
		monsters.append(monster)

func _process(delta: float) -> void:
	if current_state == State.PLAYING:
		time_elapsed += delta
		hud_node.update_time(time_elapsed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_F11):
		_toggle_fullscreen()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart_game()

func _toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _get_speed_multiplier() -> float:
	# 10% speed increase per level (1.0 for Level 1, 1.10 for Level 2, 1.21 for Level 3...)
	return pow(1.10, level - 1)

func _update_actor_speeds() -> void:
	var mult = _get_speed_multiplier()
	if pacman_node:
		pacman_node.set_speed_multiplier(mult)
	for m in monsters:
		if is_instance_valid(m):
			m.set_speed_multiplier(mult)

func _on_pellet_eaten(_pellet: Node3D) -> void:
	if current_state != State.PLAYING:
		return
	score += 10
	hud_node.update_score(score)
	if sound_node:
		sound_node.play_chomp()

func _on_all_pellets_cleared() -> void:
	if current_state != State.PLAYING:
		return
	current_state = State.LEVEL_CLEARED
	score += 200 # Bonus points for clearing board
	hud_node.update_score(score)
	
	if sound_node:
		sound_node.play_level_clear()

	# Freeze actors during celebration
	pacman_node.can_move = false
	for m in monsters:
		m.is_active = false

	level += 1
	var next_speed_pct = _get_speed_multiplier() * 100.0
	hud_node.show_level_cleared(level - 1, next_speed_pct)

	# Transition to next level after delay
	await get_tree().create_timer(2.4).timeout
	if current_state == State.LEVEL_CLEARED:
		_start_next_level()

func _start_next_level() -> void:
	hud_node.hide_level_cleared()
	_update_actor_speeds()
	maze_node.spawn_pellets()
	pacman_node.reset_to_start()
	for m in monsters:
		if is_instance_valid(m):
			m.reset_to_start()
	current_state = State.PLAYING
	_update_hud_all()

func _on_pacman_caught() -> void:
	# Pacman handles its own died signal
	pass

func _on_pacman_died() -> void:
	if current_state != State.PLAYING:
		return
	
	current_state = State.RESPAWNING
	if sound_node:
		sound_node.play_death()

	for m in monsters:
		m.is_active = false

	lives -= 1
	hud_node.update_lives(lives)

	if lives > 0:
		await get_tree().create_timer(1.2).timeout
		pacman_node.reset_to_start()
		for m in monsters:
			if is_instance_valid(m):
				m.reset_to_start()
		current_state = State.PLAYING
	else:
		current_state = State.GAME_OVER
		hud_node.show_game_over(score, time_elapsed)

func restart_game() -> void:
	score = 0
	level = 1
	lives = 3
	time_elapsed = 0.0
	current_state = State.PLAYING
	
	hud_node.hide_game_over()
	hud_node.hide_level_cleared()
	
	_update_actor_speeds()
	maze_node.spawn_pellets()
	pacman_node.reset_to_start()
	for m in monsters:
		if is_instance_valid(m):
			m.reset_to_start()
	
	_update_hud_all()

func _update_hud_all() -> void:
	var speed_pct = _get_speed_multiplier() * 100.0
	hud_node.update_score(score)
	hud_node.update_time(time_elapsed)
	hud_node.update_level(level, speed_pct)
	hud_node.update_lives(lives)
