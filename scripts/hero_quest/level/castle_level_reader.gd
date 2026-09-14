class_name CastleLevelReader
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")
const CastleLevelPropSpawner = preload("res://scripts/hero_quest/level/castle_level_prop_spawner.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var wall_factory: CastleWallTileFactory
var prop_spawner: CastleLevelPropSpawner

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	wall_factory = CastleWallTileFactory.new(materials)
	prop_spawner = CastleLevelPropSpawner.new(materials, builder.grid_to_world, mesh_builder, prop_factory)

func load_level(file_path: String = "res://data/levels/first_level.json") -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("Castle level file not found: " + file_path)
		return false

	var json_str = FileAccess.get_file_as_string(file_path)
	var json_data = JSON.parse_string(json_str)
	if not (json_data is Dictionary) or not json_data.has("rooms"):
		push_error("Invalid castle level format in: " + file_path)
		return false

	_clear_builder()

	for room_data in json_data["rooms"]:
		var r_name: String = room_data.get("name", "")
		if r_name == "RoundTowers":
			_build_round_towers(room_data)
		elif r_name == "PerimeterBarriers":
			_build_perimeter_barriers(room_data)
		else:
			_build_standard_room(room_data)

	print("Successfully loaded castle level from: ", file_path, " (tiles: ", builder.grid.size(), ")")
	return true

func _clear_builder() -> void:
	builder.grid.clear()
	mesh_builder.clear_cache()
	builder.interactive_chests.clear()
	builder.interactive_altar = null
	builder.interactive_anvil = null
	builder.interactive_bell = null

	for child in builder.get_children():
		builder.remove_child(child)
		child.queue_free()

func _build_standard_room(room_data: Dictionary) -> void:
	var r_name = room_data.get("name", "Room")
	var room_node = Node3D.new()
	room_node.name = r_name
	builder.add_child(room_node)

	# 1. Tiles
	for t_info in room_data.get("tiles", []):
		var cell = CastleLevelData.arr_to_vec2i(t_info["cell"])
		var t_type = int(t_info.get("type", 1))
		var walkable = bool(t_info.get("walkable", true))
		var zone = str(t_info.get("zone", "Castle Grounds"))
		builder.register_tile(cell, t_type, walkable, zone)

		if t_type != 7: # CHASM tiles have no floor mesh
			var m_name = t_info.get("mat", "stone")
			var mat = CastleLevelData.name_to_mat(m_name, materials)
			mesh_builder.create_square_tile_mesh(room_node, cell, mat)

	# 2. Carpets
	for c_info in room_data.get("carpets", []):
		prop_spawner.spawn_carpet(room_node, c_info)

	# 3. Pillars
	for p_info in room_data.get("pillars", []):
		prop_spawner.spawn_pillar(room_node, p_info, builder)

	# 4. Torches
	for t_info in room_data.get("torches", []):
		prop_spawner.spawn_torch(room_node, t_info)

	# 5. Arches & Doors
	for a_info in room_data.get("arches", []):
		prop_spawner.spawn_arch(room_node, a_info, builder)

	# 6. Props
	for pr_info in room_data.get("props", []):
		prop_spawner.spawn_prop(room_node, pr_info, builder)

	# 7. Lights
	for l_info in room_data.get("lights", []):
		prop_spawner.spawn_light(room_node, l_info)

	# 8. Windows
	for w_info in room_data.get("windows", []):
		var cell = CastleLevelData.arr_to_vec2i(w_info["cell"])
		var norm = CastleLevelData.arr_to_vec3(w_info["norm"])
		var h = float(w_info.get("height", 4.5))
		builder.register_tile(cell, 6, false, "Castle Walls")
		mesh_builder.create_square_tile_mesh(room_node, cell, materials.mat_floor_stone)
		wall_factory.create_window_wall(room_node, builder.grid_to_world(cell), norm, h)

	# 9. Modular Walls
	for m_info in room_data.get("modular_walls", []):
		var cell = CastleLevelData.arr_to_vec2i(m_info["cell"])
		var left = bool(m_info.get("left", false))
		var right = bool(m_info.get("right", false))
		var up = bool(m_info.get("up", false))
		var down = bool(m_info.get("down", false))
		var h = float(m_info.get("height", 4.5))
		builder.register_tile(cell, 6, false, "Castle Walls")
		mesh_builder.create_square_tile_mesh(room_node, cell, materials.mat_floor_stone)
		wall_factory.create_modular_wall(room_node, builder.grid_to_world(cell), left, right, up, down, h)

func _build_round_towers(room_data: Dictionary) -> void:
	var towers = Node3D.new()
	towers.name = "RoundTowers"
	builder.add_child(towers)

	for t_def in room_data.get("towers", []):
		var t_name: String = t_def["name"]
		var center = CastleLevelData.arr_to_vec2i(t_def["center"])
		var t_node = Node3D.new()
		t_node.name = t_name.replace(" ", "")
		towers.add_child(t_node)

		for t_info in t_def.get("tiles", []):
			var cell = CastleLevelData.arr_to_vec2i(t_info["cell"])
			var t_type = int(t_info.get("type", 1))
			var walkable = bool(t_info.get("walkable", true))
			var zone = str(t_info.get("zone", t_name))
			if not builder.grid.has(cell):
				builder.register_tile(cell, t_type, walkable, zone)
				var mat = CastleLevelData.name_to_mat(t_info.get("mat", "stone"), materials)
				mesh_builder.create_square_tile_mesh(t_node, cell, mat)

		builder.place_blocking_prop(t_node, center, "Brazier", func(p, pos):
			return prop_factory.create_brazier(p, pos)
		)

func _build_perimeter_barriers(room_data: Dictionary) -> void:
	var walls = Node3D.new()
	walls.name = "PerimeterBarriers"
	builder.add_child(walls)

	for w_info in room_data.get("windows", []):
		var cell = CastleLevelData.arr_to_vec2i(w_info["cell"])
		var norm = CastleLevelData.arr_to_vec3(w_info["norm"])
		var h = float(w_info.get("height", 4.5))
		builder.register_tile(cell, 6, false, "Castle Walls")
		mesh_builder.create_square_tile_mesh(walls, cell, materials.mat_floor_stone)
		wall_factory.create_window_wall(walls, builder.grid_to_world(cell), norm, h)

	for m_info in room_data.get("modular_walls", []):
		var cell = CastleLevelData.arr_to_vec2i(m_info["cell"])
		var left = bool(m_info.get("left", false))
		var right = bool(m_info.get("right", false))
		var up = bool(m_info.get("up", false))
		var down = bool(m_info.get("down", false))
		var h = float(m_info.get("height", 4.5))
		builder.register_tile(cell, 6, false, "Castle Walls")
		mesh_builder.create_square_tile_mesh(walls, cell, materials.mat_floor_stone)
		wall_factory.create_modular_wall(walls, builder.grid_to_world(cell), left, right, up, down, h)
