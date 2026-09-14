extends CharacterBody3D

signal died

@export var base_speed: float = 7.5
var speed_multiplier: float = 1.0

var maze: Node = null
var current_dir: Vector2i = Vector2i.ZERO
var desired_dir: Vector2i = Vector2i.ZERO
var start_grid_pos: Vector2i = Vector2i(9, 16)

@onready var visuals: Node3D = $Visuals
@onready var jaw_upper: Node3D = $Visuals/JawUpper
@onready var jaw_lower: Node3D = $Visuals/JawLower

var chomp_time: float = 0.0
var is_dead: bool = false
var can_move: bool = true

func _ready() -> void:
	add_to_group("pacman")

func setup(maze_ref: Node, spawn_grid: Vector2i) -> void:
	maze = maze_ref
	start_grid_pos = spawn_grid
	reset_to_start()

func reset_to_start() -> void:
	is_dead = false
	can_move = true
	current_dir = Vector2i.ZERO
	desired_dir = Vector2i.ZERO
	if maze:
		var w_pos = maze.grid_to_world(start_grid_pos)
		global_position = Vector3(w_pos.x, 0.6, w_pos.z)
	if visuals:
		visuals.rotation = Vector3.ZERO

func set_speed_multiplier(mult: float) -> void:
	speed_multiplier = mult

func _unhandled_input(event: InputEvent) -> void:
	if not can_move or is_dead:
		return
	
	if event.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		desired_dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		desired_dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		desired_dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		desired_dir = Vector2i(1, 0)

func _physics_process(delta: float) -> void:
	if not can_move or is_dead or not maze:
		return

	_handle_input_polling()
	_update_movement(delta)
	_update_animation(delta)

func _handle_input_polling() -> void:
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		desired_dir = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		desired_dir = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		desired_dir = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		desired_dir = Vector2i(1, 0)

func _update_movement(_delta: float) -> void:
	var cur_pos = global_position
	var cur_grid = maze.world_to_grid(cur_pos)
	var tile_center_world = maze.grid_to_world(cur_grid)
	var offset_from_center = Vector2(cur_pos.x - tile_center_world.x, cur_pos.z - tile_center_world.z)

	# Check if player wants to immediately reverse direction
	if desired_dir != Vector2i.ZERO and desired_dir == -current_dir:
		current_dir = desired_dir

	# Near tile center, evaluate turning into desired direction
	var dist_to_center = offset_from_center.length()
	var turn_threshold = 0.35
	if desired_dir != Vector2i.ZERO and desired_dir != current_dir:
		var target_cell = cur_grid + desired_dir
		if not maze.is_wall(target_cell.x, target_cell.y):
			# If turning perpendicular, only turn when sufficiently aligned with corridor center
			var is_perpendicular = (current_dir.x != 0 and desired_dir.y != 0) or (current_dir.y != 0 and desired_dir.x != 0) or current_dir == Vector2i.ZERO
			if not is_perpendicular or dist_to_center <= turn_threshold:
				current_dir = desired_dir
				# Snap orthogonal axis to center
				if current_dir.x != 0:
					global_position.z = tile_center_world.z
				else:
					global_position.x = tile_center_world.x

	# Handle forward movement or hitting wall
	if current_dir != Vector2i.ZERO:
		var next_cell = cur_grid + current_dir
		if maze.is_wall(next_cell.x, next_cell.y):
			# Approaching wall: stop at center
			var forward_offset = offset_from_center.x if current_dir.x != 0 else offset_from_center.y
			var sign_dir = current_dir.x if current_dir.x != 0 else current_dir.y
			if forward_offset * sign_dir >= 0.0:
				# Snapped to center
				if current_dir.x != 0:
					global_position.x = tile_center_world.x
				else:
					global_position.z = tile_center_world.z
				current_dir = Vector2i.ZERO

	var move_speed = base_speed * speed_multiplier
	velocity = Vector3(current_dir.x, 0, current_dir.y) * move_speed
	move_and_slide()

	# Wrap around side tunnels if maze has open edges
	_handle_maze_tunnel_wrap()

func _handle_maze_tunnel_wrap() -> void:
	var min_x = maze.get_min_world_x()
	var max_x = maze.get_max_world_x()
	if global_position.x < min_x - 1.0:
		global_position.x = max_x + 0.5
	elif global_position.x > max_x + 1.0:
		global_position.x = min_x - 0.5

func _update_animation(delta: float) -> void:
	if current_dir != Vector2i.ZERO:
		chomp_time += delta * 12.0 * speed_multiplier
		var target_angle = 0.0
		if current_dir == Vector2i(1, 0):
			target_angle = 0.0
		elif current_dir == Vector2i(-1, 0):
			target_angle = PI
		elif current_dir == Vector2i(0, 1):
			target_angle = -PI / 2.0
		elif current_dir == Vector2i(0, -1):
			target_angle = PI / 2.0
		
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, delta * 18.0)
		
		# Chomp angle
		var chomp_val = abs(sin(chomp_time)) * 0.55
		if jaw_upper and jaw_lower:
			jaw_upper.rotation.z = chomp_val
			jaw_lower.rotation.z = -chomp_val
	else:
		if jaw_upper and jaw_lower:
			jaw_upper.rotation.z = lerpf(jaw_upper.rotation.z, 0.05, delta * 10.0)
			jaw_lower.rotation.z = lerpf(jaw_lower.rotation.z, -0.05, delta * 10.0)

func hit_by_monster() -> void:
	if is_dead:
		return
	is_dead = true
	can_move = false
	died.emit()
