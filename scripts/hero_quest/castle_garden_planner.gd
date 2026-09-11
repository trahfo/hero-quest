class_name CastleGardenPlanner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var decors: CastleDecorationFactory

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_decors: CastleDecorationFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	decors = p_decors

func plan_and_build() -> Node3D:
	var garden = Node3D.new()
	garden.name = "IndoorGarden"
	builder.add_child(garden)

	var zone_name = "The Cloister Garden"

	# Enlarged Garden: 50% larger (120 tiles: gx: -15..-8 [8 cols], gz: -24..-10 [15 rows])
	# Features a central 4x4 stone plaza with a fountain and cruciform straight stone paths
	for gx in range(-15, -7):
		for gz in range(-24, -9):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, zone_name)

			var is_plaza = (gx >= -13 and gx <= -10 and gz >= -17 and gz <= -14)
			var is_path_ns = (gx == -12)
			var is_path_ew = (gz == -14)

			if is_plaza or is_path_ns or is_path_ew:
				mesh_builder.create_square_tile_mesh(garden, cell, materials.mat_floor_stone)
			else:
				mesh_builder.create_square_tile_mesh(garden, cell, materials.mat_floor_garden_green)

	# Central Fountain placed squarely in the center of the 4x4 stone plaza
	var fountain_cells: Array[Vector2i] = [
		Vector2i(-12, -16), Vector2i(-11, -16),
		Vector2i(-12, -15), Vector2i(-11, -15)
	]
	builder.place_multitile_prop(garden, fountain_cells, "Fountain", func(p, pos):
		return decors.create_fountain(p, pos)
	)

	# Bushes placed within lawn quadrants away from straight paths
	var bush_cells = [
		# North quadrants
		Vector2i(-14, -21), Vector2i(-9, -21),
		Vector2i(-15, -19), Vector2i(-8, -19),
		# South quadrants
		Vector2i(-14, -11), Vector2i(-9, -11),
		Vector2i(-15, -12), Vector2i(-8, -12)
	]
	for b_cell in bush_cells:
		builder.place_blocking_prop(garden, b_cell, "Bush", func(p, pos):
			return decors.create_bush(p, pos, 1.2)
		)

	# Flower patches accenting the lawn quadrants and plaza perimeter
	var flower_cells = [
		Vector2i(-14, -19), Vector2i(-9, -19),
		Vector2i(-14, -10), Vector2i(-9, -10),
		Vector2i(-13, -16), Vector2i(-10, -16)
	]
	for f_cell in flower_cells:
		var pos = builder.grid_to_world(f_cell) + Vector3(0, 0.12, 0)
		decors.create_flower_patch(garden, pos)

	# Arcade Columns framing the central plaza on North and South
	var pillar_cells = [
		Vector2i(-13, -18), Vector2i(-10, -18),
		Vector2i(-13, -13), Vector2i(-10, -13)
	]
	for p_cell in pillar_cells:
		builder.place_blocking_prop(garden, p_cell, "ArcadePillar", func(p, _pos):
			return mesh_builder.create_arch_pier(p, p_cell, 3.6)
		)

	# Arcade arches framing the central plaza (span: 6.0m = 3 tiles, spring_height: 3.6m)
	var arch_pos_n = (builder.grid_to_world(Vector2i(-13, -18)) + builder.grid_to_world(Vector2i(-10, -18))) * 0.5
	mesh_builder.create_curved_arch_mesh(garden, arch_pos_n, 6.0, 3.6, 0, 0.9)

	var arch_pos_s = (builder.grid_to_world(Vector2i(-13, -13)) + builder.grid_to_world(Vector2i(-10, -13))) * 0.5
	mesh_builder.create_curved_arch_mesh(garden, arch_pos_s, 6.0, 3.6, 0, 0.9)

	# Connectors:
	# 1. East Portal into Grand Chapel (gx: -7, gz: -14)
	var chapel_conn = Vector2i(-7, -14)
	builder.register_tile(chapel_conn, 2, true, "Garden Cloister Portal")
	mesh_builder.create_square_tile_mesh(garden, chapel_conn, materials.mat_floor_chapel)
	mesh_builder.build_arch_3tile(garden, chapel_conn, 1, "Garden Chapel Portal")

	# 2. South Portal into Royal Stables (gx: -13..-11, gz: -9..-7)
	# Widened by 2 tiles (3 tiles wide); matching 3-field spanning arches at both exits
	for gx in range(-13, -10):
		for gz in range(-9, -6):
			var stable_conn = Vector2i(gx, gz)
			builder.register_tile(stable_conn, 3, true, "Garden Stable Corridor")
			mesh_builder.create_square_tile_mesh(garden, stable_conn, materials.mat_floor_wood)
	mesh_builder.build_arch_spanning_3tiles(garden, Vector2i(-12, -9), 0, "Garden Stables Gate")
	mesh_builder.build_arch_spanning_3tiles(garden, Vector2i(-12, -7), 0, "Stables Garden Gate")

	# Ambient Soft Garden Sunlight
	var sun = OmniLight3D.new()
	sun.light_color = Color(0.85, 0.95, 0.8)
	sun.light_energy = 2.2
	sun.omni_range = 24.0
	sun.position = builder.grid_to_world(Vector2i(-12, -15)) + Vector3(0, 6.0, 0)
	garden.add_child(sun)

	return garden
