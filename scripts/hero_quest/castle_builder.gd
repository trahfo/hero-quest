extends Node3D

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleLevelReader = preload("res://scripts/hero_quest/level/castle_level_reader.gd")

const TILE_SIZE: float = 2.0

@export var level_file_path: String = "res://data/levels/first_level.json"

enum TileType {
	NONE,
	FLOOR_STONE,
	FLOOR_CHAPEL,
	FLOOR_WOOD,
	FLOOR_BRIDGE,
	FLOOR_COURTYARD,
	WALL,
	CHASM,
	FLOOR_GRAVEYARD
}

enum ArchAxis {
	ALONG_X, # Wall runs along X axis, passage opens through Z (North-South)
	ALONG_Z  # Wall runs along Z axis, passage opens through X (East-West)
}

# Grid registry: Vector2i -> Dictionary
# Keys: "type": TileType, "walkable": bool, "zone": String, "prop": Node3D
var grid: Dictionary = {}

# Materials cache
var materials: CastleMaterials
var mat_floor_stone: StandardMaterial3D:
	get: return materials.mat_floor_stone
var mat_floor_stone_alt: StandardMaterial3D:
	get: return materials.mat_floor_stone_alt
var mat_floor_chapel: StandardMaterial3D:
	get: return materials.mat_floor_chapel
var mat_floor_wood: StandardMaterial3D:
	get: return materials.mat_floor_wood
var mat_floor_bridge: StandardMaterial3D:
	get: return materials.mat_floor_bridge
var mat_wall_stone: StandardMaterial3D:
	get: return materials.mat_wall_stone
var mat_wall_trim: StandardMaterial3D:
	get: return materials.mat_wall_trim
var mat_wood_dark: StandardMaterial3D:
	get: return materials.mat_wood_dark
var mat_wood_light: StandardMaterial3D:
	get: return materials.mat_wood_light
var mat_iron: StandardMaterial3D:
	get: return materials.mat_iron
var mat_gold: StandardMaterial3D:
	get: return materials.mat_gold
var mat_torch_glow: StandardMaterial3D:
	get: return materials.mat_torch_glow
var mat_ember: StandardMaterial3D:
	get: return materials.mat_ember
var mat_water_chasm: StandardMaterial3D:
	get: return materials.mat_water_chasm
var mat_hay: StandardMaterial3D:
	get: return materials.mat_hay
var mat_cloth_red: StandardMaterial3D:
	get: return materials.mat_cloth_red

# Interactive props list
var interactive_chests: Array[Node3D] = []
var interactive_altar: Node3D = null
var interactive_anvil: Node3D = null
var interactive_bell: Node3D = null

# Sub-system collaborators
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var level_reader: CastleLevelReader

func _ready() -> void:
	_init_subsystems()
	build_castle()

func _init_subsystems() -> void:
	materials = CastleMaterials.new()
	mesh_builder = CastleMeshBuilder.new(materials, grid_to_world, register_tile)
	prop_factory = CastlePropFactory.new(materials, grid_to_world)
	level_reader = CastleLevelReader.new(self, materials, mesh_builder, prop_factory)

func build_castle() -> void:
	if not level_reader:
		_init_subsystems()

	if FileAccess.file_exists(level_file_path):
		var ok = level_reader.load_level(level_file_path)
		if ok:
			return

	init_new_level("New Castle Realm")

func init_new_level(level_name: String = "New Level") -> void:
	if not level_reader:
		_init_subsystems()

	grid.clear()
	mesh_builder.clear_cache()
	interactive_chests.clear()
	interactive_altar = null
	interactive_anvil = null
	interactive_bell = null
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var start_room = Node3D.new()
	start_room.name = "StartingHall"
	add_child(start_room)

	# 5x5 starting stone floor canvas around spawn (0, 0)
	for gx in range(-2, 3):
		for gz in range(-2, 3):
			var cell = Vector2i(gx, gz)
			register_tile(cell, 1, true, level_name)
			var alt = (gx + gz) % 2 == 0
			mesh_builder.create_square_tile_mesh(start_room, cell, materials.mat_floor_stone if alt else materials.mat_floor_stone_alt)

func load_from_level_file(file_path: String = "res://data/levels/first_level.json", force_reload: bool = false) -> bool:
	if not level_reader:
		_init_subsystems()
	if not force_reload and level_file_path == file_path and not grid.is_empty():
		return true
	level_file_path = file_path
	if FileAccess.file_exists(file_path):
		return level_reader.load_level(file_path)
	init_new_level("New Castle Realm")
	return true

# ---------------------------------------------------------
# GRID COORDINATE CONVERSIONS & QUERIES
# ---------------------------------------------------------

func grid_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * TILE_SIZE, 0.0, cell.y * TILE_SIZE)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		roundi(world_pos.x / TILE_SIZE),
		roundi(world_pos.z / TILE_SIZE)
	)

func is_tile_walkable(cell: Vector2i) -> bool:
	if not grid.has(cell):
		return false
	return grid[cell].get("walkable", false)

func get_zone_at_tile(cell: Vector2i) -> String:
	if grid.has(cell):
		return grid[cell].get("zone", "Castle Grounds")
	return "Outside the Castle"

func get_zone_at_position(pos: Vector3) -> String:
	return get_zone_at_tile(world_to_grid(pos))

func register_tile(cell: Vector2i, type: int, walkable: bool, zone: String) -> void:
	grid[cell] = {
		"type": type,
		"walkable": walkable,
		"zone": zone,
		"prop": null
	}

func place_blocking_prop(parent: Node3D, cell: Vector2i, _prop_name: String, create_fn: Callable) -> Node3D:
	if grid.has(cell):
		grid[cell]["walkable"] = false
	var pos = grid_to_world(cell) + Vector3(0, 0.12, 0)
	var prop_node = create_fn.call(parent, pos)
	if grid.has(cell) and prop_node:
		grid[cell]["prop"] = prop_node
	return prop_node

func place_multitile_prop(parent: Node3D, cells: Array, _prop_name: String, create_fn: Callable) -> Node3D:
	if cells.is_empty():
		return null
	var center_world = Vector3.ZERO
	for cell in cells:
		if grid.has(cell):
			grid[cell]["walkable"] = false
		center_world += grid_to_world(cell)
	center_world /= float(cells.size())
	center_world.y += 0.12

	var prop_node = create_fn.call(parent, center_world)
	if prop_node:
		for cell in cells:
			if grid.has(cell):
				grid[cell]["prop"] = prop_node
	return prop_node
