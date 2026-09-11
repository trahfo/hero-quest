class_name CastlePerimeterBuilder
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var wall_factory: CastleWallTileFactory

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	wall_factory = CastleWallTileFactory.new(p_materials)

func build_round_towers() -> Node3D:
	var towers = Node3D.new()
	towers.name = "RoundTowers"
	builder.add_child(towers)

	var tower_defs = [
		{"name": "North-West Watchtower", "center": Vector2i(-18, -15), "conn": Vector2i(-15, -15)},
		{"name": "North-East Watchtower", "center": Vector2i(18, -15), "conn": Vector2i(15, -15)},
		{"name": "South-West Watchtower", "center": Vector2i(-13, 16), "conn": Vector2i(-8, 16)},
		{"name": "South-East Watchtower", "center": Vector2i(13, 16), "conn": Vector2i(8, 16)}
	]

	for t_info in tower_defs:
		var t_name: String = t_info["name"]
		var center: Vector2i = t_info["center"]
		var t_node = Node3D.new()
		t_node.name = t_name.replace(" ", "")
		towers.add_child(t_node)

		for dx in range(-2, 3):
			for dz in range(-2, 3):
				if absi(dx) == 2 and absi(dz) == 2:
					continue
				var cell = center + Vector2i(dx, dz)
				if not builder.grid.has(cell):
					builder.register_tile(cell, 1, true, t_name)
					mesh_builder.create_square_tile_mesh(t_node, cell, materials.mat_floor_stone)

		builder.place_blocking_prop(t_node, center, "Brazier", func(p, pos): return prop_factory.create_brazier(p, pos))

		var start_gx = mini(center.x, t_info["conn"].x)
		var end_gx = maxi(center.x, t_info["conn"].x)
		var cy = center.y
		for gx in range(start_gx, end_gx + 1):
			var cell = Vector2i(gx, cy)
			if not builder.grid.has(cell):
				builder.register_tile(cell, 1, true, t_name)
				mesh_builder.create_square_tile_mesh(t_node, cell, materials.mat_floor_stone)

		if t_name == "North-West Watchtower":
			# North-West Watchtower entrance arch framing the threshold from Cloister Garden
			mesh_builder.build_arch_3tile(t_node, Vector2i(-16, -15), 1, "NorthWestTowerPortal")

	return towers

func build_grid_perimeter_walls() -> Node3D:
	var walls = Node3D.new()
	walls.name = "PerimeterBarriers"
	builder.add_child(walls)

	var window_spots = [
		# Chapel Windows (all away from corners, looking out to exterior/garden; NO windows into indoor rooms or door/arch cells)
		{"cell": Vector2i(-3, -21), "norm": Vector3(0, 0, 1)},
		{"cell": Vector2i(0, -21), "norm": Vector3(0, 0, 1)},
		{"cell": Vector2i(3, -21), "norm": Vector3(0, 0, 1)},
		{"cell": Vector2i(-7, -18), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(-7, -16), "norm": Vector3(1, 0, 0)},
		# Stable Windows (away from corners)
		{"cell": Vector2i(-16, -4), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(-16, 0), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(-16, 4), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(-13, 7), "norm": Vector3(0, 0, -1)},
		{"cell": Vector2i(-11, 7), "norm": Vector3(0, 0, -1)},
		# Tower Lookout Windows (at least one in each watchtower)
		{"cell": Vector2i(-21, -15), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(21, -15), "norm": Vector3(-1, 0, 0)},
		{"cell": Vector2i(-13, 19), "norm": Vector3(0, 0, -1)},
		{"cell": Vector2i(13, 19), "norm": Vector3(0, 0, -1)},
		# Wings & Courtyards (centered on straight walls)
		{"cell": Vector2i(12, -19), "norm": Vector3(0, 0, 1)},
		{"cell": Vector2i(-16, -14), "norm": Vector3(1, 0, 0)},
		{"cell": Vector2i(16, -14), "norm": Vector3(-1, 0, 0)},
		{"cell": Vector2i(16, -3), "norm": Vector3(-1, 0, 0)}
	]

	var window_dict: Dictionary = {}
	for w_def in window_spots:
		window_dict[w_def["cell"]] = w_def["norm"]

	var neighbor_offsets = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	var diagonal_offsets = [
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]

	# Collect all perimeter wall cells: non-room cells adjacent (orthogonal and diagonal) to rooms
	# Adding diagonal coverage seals zig-zag outer corners (e.g. watchtowers) with zero gaps
	var perimeter_cells: Dictionary = {}
	var all_cells = builder.grid.keys()
	for cell in all_cells:
		var info = builder.grid[cell]
		var type = info.get("type", 0)
		if type == 0 or type == 6 or type == 7 or type == 4 or type == 8:
			continue

		for offset in neighbor_offsets:
			var neighbor = cell + offset
			var n_info = builder.grid.get(neighbor, null)
			if n_info == null:
				perimeter_cells[neighbor] = true
			elif n_info.get("type", 0) == 7 and type != 5:
				# Indoor room bordering chasm (Stables, Great Corridor, Smith): must have a wall!
				perimeter_cells[neighbor] = true

		for diag in diagonal_offsets:
			var diag_neighbor = cell + diag
			var dn_info = builder.grid.get(diag_neighbor, null)
			if dn_info == null:
				perimeter_cells[diag_neighbor] = true
			elif dn_info.get("type", 0) == 7 and type != 5:
				perimeter_cells[diag_neighbor] = true

	# Ensure all window spots are registered and tracked
	for w_cell in window_dict.keys():
		perimeter_cells[w_cell] = true

	# Register all perimeter wall tiles in builder grid
	for p_cell in perimeter_cells.keys():
		builder.register_tile(p_cell, 6, false, "Castle Walls") # WALL = 6

	# Build modular 0.9m walls (window wall tiles, T-connectors, L-corners, straight wall tiles)
	for w_cell in perimeter_cells.keys():
		var w_pos = builder.grid_to_world(w_cell)

		if window_dict.has(w_cell):
			# Dedicated window wall tile with corner reveals and zero z-fighting
			wall_factory.create_window_wall(walls, w_pos, window_dict[w_cell], 4.5)
		else:
			var has_left = perimeter_cells.has(w_cell + Vector2i(-1, 0))
			var has_right = perimeter_cells.has(w_cell + Vector2i(1, 0))
			var has_up = perimeter_cells.has(w_cell + Vector2i(0, -1))
			var has_down = perimeter_cells.has(w_cell + Vector2i(0, 1))

			if not has_left and not has_right and not has_up and not has_down:
				# Fallback: check adjacent room direction
				if builder.grid.has(w_cell + Vector2i(0, 1)) or builder.grid.has(w_cell + Vector2i(0, -1)):
					has_left = true
					has_right = true
				else:
					has_up = true
					has_down = true

			# create_modular_wall handles straight walls, L-corners, T-junctions, and 4-way junctions seamlessly
			wall_factory.create_modular_wall(walls, w_pos, has_left, has_right, has_up, has_down, 4.5)

	return walls
