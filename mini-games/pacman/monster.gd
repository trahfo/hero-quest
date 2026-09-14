extends CharacterBody3D

signal caught_pacman

enum Behavior { CHASE, AMBUSH, PATROL, SCATTER_CLOSE, RANDOM_ROAM }

@export var monster_name: String = "Blinky"
@export var monster_color: Color = Color(1.0, 0.2, 0.25)
@export var behavior: Behavior = Behavior.CHASE
@export var base_speed: float = 6.2

var speed_multiplier: float = 1.0
var maze: Node = null
var pacman_node: Node3D = null

var current_dir: Vector2i = Vector2i(0, -1)
var start_grid_pos: Vector2i = Vector2i(9, 9)
var is_active: bool = true

@onready var body_mesh: MeshInstance3D = $Visuals/BodyMesh
@onready var skirt_mesh: MeshInstance3D = $Visuals/SkirtMesh
@onready var eyes_container: Node3D = $Visuals/Eyes
@onready var pupil_left: Node3D = $Visuals/Eyes/EyeLeft/PupilLeft
@onready var pupil_right: Node3D = $Visuals/Eyes/EyeRight/PupilRight

var hover_time: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	apply_color(monster_color)

func setup(maze_ref: Node, pacman_ref: Node3D, spawn_pos: Vector2i, m_name: String, m_color: Color, m_behavior: Behavior) -> void:
	maze = maze_ref
	pacman_node = pacman_ref
	start_grid_pos = spawn_pos
	monster_name = m_name
	monster_color = m_color
	behavior = m_behavior
	apply_color(m_color)
	reset_to_start()

func apply_color(col: Color) -> void:
	monster_color = col
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3
	mat.metallic_specular = 0.6
	mat.emission_enabled = true
	mat.emission = col * 0.25
	mat.emission_energy_multiplier = 0.6
	
	if body_mesh:
		body_mesh.material_override = mat
	if skirt_mesh:
		skirt_mesh.material_override = mat

func reset_to_start() -> void:
	is_active = true
	current_dir = Vector2i(0, -1)
	if maze:
		var w_pos = maze.grid_to_world(start_grid_pos)
		global_position = Vector3(w_pos.x, 0.6, w_pos.z)

func set_speed_multiplier(mult: float) -> void:
	speed_multiplier = mult

func _physics_process(delta: float) -> void:
	if not is_active or not maze or not pacman_node:
		return

	_update_movement(delta)
	_update_animation(delta)
	_check_pacman_collision()

func _update_movement(_delta: float) -> void:
	var cur_pos = global_position
	var cur_grid = maze.world_to_grid(cur_pos)
	var tile_center_world = maze.grid_to_world(cur_grid)
	var offset_from_center = Vector2(cur_pos.x - tile_center_world.x, cur_pos.z - tile_center_world.z)
	var dist_to_center = offset_from_center.length()

	# If very close to tile center, determine next direction at intersection
	if dist_to_center <= 0.25:
		var valid_dirs: Array[Vector2i] = []
		var all_dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		
		for d in all_dirs:
			# Do not allow immediate 180 reverse unless trapped in dead end
			if d == -current_dir and all_dirs.size() > 1:
				continue
			var test_cell = cur_grid + d
			if not maze.is_wall(test_cell.x, test_cell.y):
				valid_dirs.append(d)

		if valid_dirs.is_empty():
			# Dead end, allow reverse
			var test_cell = cur_grid - current_dir
			if not maze.is_wall(test_cell.x, test_cell.y):
				valid_dirs.append(-current_dir)

		if not valid_dirs.is_empty():
			var chosen_dir = _choose_best_direction(cur_grid, valid_dirs)
			if chosen_dir != current_dir:
				current_dir = chosen_dir
				# Snap orthogonal position to center line
				if current_dir.x != 0:
					global_position.z = tile_center_world.z
				else:
					global_position.x = tile_center_world.x

	# Handle forward movement
	var next_cell = cur_grid + current_dir
	if maze.is_wall(next_cell.x, next_cell.y):
		var forward_offset = offset_from_center.x if current_dir.x != 0 else offset_from_center.y
		var sign_dir = current_dir.x if current_dir.x != 0 else current_dir.y
		if forward_offset * sign_dir >= 0.0:
			if current_dir.x != 0:
				global_position.x = tile_center_world.x
			else:
				global_position.z = tile_center_world.z
			# Reverse or pick available side
			current_dir = -current_dir

	var move_speed = base_speed * speed_multiplier
	velocity = Vector3(current_dir.x, 0, current_dir.y) * move_speed
	move_and_slide()

	# Side tunnel wrap
	var min_x = maze.get_min_world_x()
	var max_x = maze.get_max_world_x()
	if global_position.x < min_x - 1.0:
		global_position.x = max_x + 0.5
	elif global_position.x > max_x + 1.0:
		global_position.x = min_x - 0.5

func _choose_best_direction(cur_grid: Vector2i, valid_dirs: Array[Vector2i]) -> Vector2i:
	if valid_dirs.size() == 1:
		return valid_dirs[0]

	var pacman_grid = maze.world_to_grid(pacman_node.global_position)
	var target_grid = pacman_grid

	match behavior:
		Behavior.CHASE:
			target_grid = pacman_grid
		Behavior.AMBUSH:
			var pac_dir = pacman_node.current_dir
			target_grid = pacman_grid + pac_dir * 3
		Behavior.PATROL:
			# Target alternate corners based on time
			var t = int(Time.get_ticks_msec() / 6000.0) % 4
			match t:
				0: target_grid = Vector2i(1, 1)
				1: target_grid = Vector2i(17, 1)
				2: target_grid = Vector2i(17, 19)
				3: target_grid = Vector2i(1, 19)
		Behavior.SCATTER_CLOSE:
			var dist_to_pacman = (Vector2(cur_grid) - Vector2(pacman_grid)).length()
			if dist_to_pacman < 6.0:
				target_grid = Vector2i(1, 19) # Run away to bottom left corner
			else:
				target_grid = pacman_grid
		Behavior.RANDOM_ROAM:
			if randf() < 0.4:
				return valid_dirs[randi() % valid_dirs.size()]
			target_grid = pacman_grid

	# Pick valid direction that brings us closest to target_grid
	var best_dir = valid_dirs[0]
	var best_dist = INF
	for d in valid_dirs:
		var candidate_cell = cur_grid + d
		var dist_sq = (Vector2(candidate_cell) - Vector2(target_grid)).length_squared()
		if dist_sq < best_dist:
			best_dist = dist_sq
			best_dir = d

	return best_dir

func _update_animation(delta: float) -> void:
	hover_time += delta * 6.0
	# Comic bobbing up and down
	$Visuals.position.y = 0.6 + sin(hover_time) * 0.08
	# Wavy skirt scale
	if skirt_mesh:
		skirt_mesh.scale.x = 1.0 + sin(hover_time * 1.5) * 0.08
		skirt_mesh.scale.z = 1.0 + cos(hover_time * 1.5) * 0.08

	# Orient eyes in direction of movement
	var look_offset = Vector3.ZERO
	if current_dir == Vector2i(1, 0):
		look_offset = Vector3(0.04, 0, 0)
	elif current_dir == Vector2i(-1, 0):
		look_offset = Vector3(-0.04, 0, 0)
	elif current_dir == Vector2i(0, 1):
		look_offset = Vector3(0, 0, 0.04)
	elif current_dir == Vector2i(0, -1):
		look_offset = Vector3(0, 0, -0.04)

	if pupil_left and pupil_right:
		pupil_left.position = pupil_left.position.lerp(Vector3(0.06, 0.02, 0.07) + look_offset, delta * 12.0)
		pupil_right.position = pupil_right.position.lerp(Vector3(0.06, 0.02, -0.07) + look_offset, delta * 12.0)

func _check_pacman_collision() -> void:
	if not pacman_node or pacman_node.is_dead:
		return
	var dist = global_position.distance_to(pacman_node.global_position)
	if dist < 0.95:
		caught_pacman.emit()
		pacman_node.hit_by_monster()
