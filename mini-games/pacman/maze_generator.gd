extends Node3D

signal pellet_eaten(pellet_node)
signal all_pellets_cleared

const TILE_SIZE: float = 2.0

const MAZE_MAP: Array[String] = [
	"###################",
	"#........#........#",
	"#.##.###.#.###.##.#",
	"#.##.###.#.###.##.#",
	"#.................#",
	"#.##.#.#####.#.##.#",
	"#....#...#...#....#",
	"####.### # ###.####",
	"   #.#   1   #.#   ",
	"####.# ##-## #.####",
	"    .  #234#  .    ",
	"####.# ##### #.####",
	"   #.#   5   #.#   ",
	"####.# ##### #.####",
	"#........#........#",
	"#.##.###.#.###.##.#",
	"#..#.....P.....#..#",
	"##.#.#.#####.#.#.##",
	"#....#...#...#....#",
	"#........#........#",
	"###################"
]

var grid_width: int = 0
var grid_height: int = 0
var pellet_scene: PackedScene = preload("res://mini-games/pacman/pellet.tscn")

var walls_container: Node3D
var pellets_container: Node3D
var floor_node: MeshInstance3D

var pacman_spawn: Vector2i = Vector2i(9, 16)
var monster_spawns: Dictionary = {}
var remaining_pellets: int = 0

# Cached grid for O(1) wall queries
var wall_grid: Array = []

func _ready() -> void:
	grid_height = MAZE_MAP.size()
	grid_width = MAZE_MAP[0].length()
	
	walls_container = Node3D.new()
	walls_container.name = "Walls"
	add_child(walls_container)
	
	pellets_container = Node3D.new()
	pellets_container.name = "Pellets"
	add_child(pellets_container)
	
	_build_floor()
	_parse_and_build_maze()
	spawn_pellets()

func _build_floor() -> void:
	floor_node = MeshInstance3D.new()
	floor_node.name = "LabyrinthFloor"
	
	var plane_mesh = PlaneMesh.new()
	var total_w = grid_width * TILE_SIZE + 4.0
	var total_h = grid_height * TILE_SIZE + 4.0
	plane_mesh.size = Vector2(total_w, total_h)
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.04, 0.05, 0.11, 1.0)
	floor_mat.roughness = 0.45
	floor_mat.metallic = 0.2
	plane_mesh.material = floor_mat
	
	floor_node.mesh = plane_mesh
	floor_node.position = Vector3(0, 0, 0)
	add_child(floor_node)

func _parse_and_build_maze() -> void:
	wall_grid.clear()
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			row.append(false)
		wall_grid.append(row)

	# Shared materials for comic walls
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.08, 0.16, 0.48, 1.0)
	wall_mat.roughness = 0.35
	wall_mat.metallic_specular = 0.5

	var trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.18, 0.65, 0.98, 1.0)
	trim_mat.emission_enabled = true
	trim_mat.emission = Color(0.12, 0.55, 0.9, 1.0)
	trim_mat.emission_energy_multiplier = 0.8

	var wall_box_mesh = BoxMesh.new()
	wall_box_mesh.size = Vector3(TILE_SIZE, 1.5, TILE_SIZE)
	wall_box_mesh.material = wall_mat

	var trim_box_mesh = BoxMesh.new()
	trim_box_mesh.size = Vector3(TILE_SIZE * 0.95, 0.15, TILE_SIZE * 0.95)
	trim_box_mesh.material = trim_mat

	var wall_shape = BoxShape3D.new()
	wall_shape.size = Vector3(TILE_SIZE, 1.5, TILE_SIZE)

	for y in range(grid_height):
		var line = MAZE_MAP[y]
		for x in range(grid_width):
			var c = line[x]
			if c == '#':
				wall_grid[y][x] = true
				_create_wall_tile(x, y, wall_box_mesh, trim_box_mesh, wall_shape)
			elif c == 'P':
				pacman_spawn = Vector2i(x, y)
			elif c >= '1' and c <= '5':
				monster_spawns[int(c) - 1] = Vector2i(x, y)
			elif c == '-':
				# Ghost gate: let monsters pass, wall_grid is false
				wall_grid[y][x] = false

func _create_wall_tile(x: int, y: int, body_mesh: BoxMesh, trim_mesh: BoxMesh, col_shape: BoxShape3D) -> void:
	var w_pos = grid_to_world(Vector2i(x, y))
	
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.position = Vector3(w_pos.x, 0.75, w_pos.z)
	
	var col = CollisionShape3D.new()
	col.shape = col_shape
	static_body.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = body_mesh
	static_body.add_child(mesh_inst)
	
	var trim_inst = MeshInstance3D.new()
	trim_inst.mesh = trim_mesh
	trim_inst.position = Vector3(0, 0.75, 0)
	static_body.add_child(trim_inst)
	
	walls_container.add_child(static_body)

func spawn_pellets() -> void:
	# Clear old pellets
	for child in pellets_container.get_children():
		child.queue_free()

	remaining_pellets = 0
	for y in range(grid_height):
		var line = MAZE_MAP[y]
		for x in range(grid_width):
			var c = line[x]
			if c == '.':
				var pellet = pellet_scene.instantiate()
				var w_pos = grid_to_world(Vector2i(x, y))
				pellet.position = Vector3(w_pos.x, 0, w_pos.z)
				pellet.collected.connect(_on_pellet_collected)
				pellets_container.add_child(pellet)
				remaining_pellets += 1

func _on_pellet_collected(pellet: Node3D) -> void:
	remaining_pellets -= 1
	pellet_eaten.emit(pellet)
	if remaining_pellets <= 0:
		all_pellets_cleared.emit()

func is_wall(x: int, y: int) -> bool:
	if y < 0 or y >= grid_height:
		return true
	if x < 0 or x >= grid_width:
		# Side wrap tunnels are not walls
		if y == 10:
			return false
		return true
	return wall_grid[y][x]

func world_to_grid(w_pos: Vector3) -> Vector2i:
	var half_w = float(grid_width) * TILE_SIZE * 0.5
	var half_h = float(grid_height) * TILE_SIZE * 0.5
	var gx = int(floor((w_pos.x + half_w) / TILE_SIZE))
	var gy = int(floor((w_pos.z + half_h) / TILE_SIZE))
	return Vector2i(clamp(gx, 0, grid_width - 1), clamp(gy, 0, grid_height - 1))

func grid_to_world(g_pos: Vector2i) -> Vector3:
	var half_w = float(grid_width) * TILE_SIZE * 0.5
	var half_h = float(grid_height) * TILE_SIZE * 0.5
	var wx = (float(g_pos.x) + 0.5) * TILE_SIZE - half_w
	var wz = (float(g_pos.y) + 0.5) * TILE_SIZE - half_h
	return Vector3(wx, 0, wz)

func get_min_world_x() -> float:
	return -float(grid_width) * TILE_SIZE * 0.5

func get_max_world_x() -> float:
	return float(grid_width) * TILE_SIZE * 0.5
