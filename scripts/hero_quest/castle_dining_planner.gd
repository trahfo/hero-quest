class_name CastleDiningPlanner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory, p_decors: CastleDecorationFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	decors = p_decors

func plan_and_build() -> Node3D:
	var dining = Node3D.new()
	dining.name = "GrandDiningHall"
	builder.add_child(dining)

	var zone_name = "The Grand Banquet Hall"

	# Floor tiles across gx: 8..15, gz: -18..-9
	for gx in range(8, 16):
		for gz in range(-18, -8):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, zone_name)
			var alt = (gx + gz) % 2 == 0
			mesh_builder.create_square_tile_mesh(dining, cell, materials.mat_floor_stone if alt else materials.mat_floor_stone_alt)

	# 10-Tile Banquet Table (gx: 11..12, gz: -16..-12 -> 2 x 5 = 10 tiles)
	var table_cells: Array[Vector2i] = []
	for gx in range(11, 13):
		for gz in range(-16, -11):
			table_cells.append(Vector2i(gx, gz))

	builder.place_multitile_prop(dining, table_cells, "GrandTable", func(p, pos):
		return prop_factory.furniture.create_table(p, pos, Vector3(3.6, 1.1, 9.6), materials.mat_wood_dark)
	)

	# Chairs placed along both sides of the table
	for gz in range(-16, -11):
		# West row facing East (rot_y = -PI * 0.5)
		builder.place_blocking_prop(dining, Vector2i(10, gz), "Chair", func(p, pos):
			return prop_factory.furniture.create_chair(p, pos, -PI * 0.5)
		)
		# East row facing West (rot_y = PI * 0.5)
		builder.place_blocking_prop(dining, Vector2i(13, gz), "Chair", func(p, pos):
			return prop_factory.furniture.create_chair(p, pos, PI * 0.5)
		)

	# Big Chimney Fireplace on the East wall (gz: -14)
	var chimney_cells: Array[Vector2i] = [Vector2i(15, -14), Vector2i(15, -13)]
	builder.place_multitile_prop(dining, chimney_cells, "Chimney", func(p, pos):
		return decors.create_chimney_fireplace(p, pos, -PI * 0.5)
	)

	# Paintings on the walls
	# North wall paintings
	decors.create_painting(dining, builder.grid_to_world(Vector2i(9, -18)) + Vector3(0, 2.5, -0.9), Vector3(0, 0, 1), 0)
	decors.create_painting(dining, builder.grid_to_world(Vector2i(14, -18)) + Vector3(0, 2.5, -0.9), Vector3(0, 0, 1), 1)
	# South wall paintings
	decors.create_painting(dining, builder.grid_to_world(Vector2i(10, -9)) + Vector3(0, 2.5, 0.9), Vector3(0, 0, -1), 2)
	decors.create_painting(dining, builder.grid_to_world(Vector2i(14, -9)) + Vector3(0, 2.5, 0.9), Vector3(0, 0, -1), 0)

	# Chandelier / Candelabras lighting
	builder.place_blocking_prop(dining, Vector2i(9, -12), "Candelabra", func(p, pos):
		return prop_factory.create_candelabra(p, pos)
	)
	builder.place_blocking_prop(dining, Vector2i(14, -16), "Candelabra", func(p, pos):
		return prop_factory.create_candelabra(p, pos)
	)

	# Connectors:
	# 1. West Portal into Grand Chapel (gx: 7, gz: -14)
	var chapel_conn = Vector2i(7, -14)
	builder.register_tile(chapel_conn, 2, true, "Dining Chapel Portal")
	mesh_builder.create_square_tile_mesh(dining, chapel_conn, materials.mat_floor_chapel)
	mesh_builder.build_arch_3tile(dining, chapel_conn, 1, "Dining Chapel Portal")

	# 2. South Portal into Blacksmith (gx: 12, gz: -8..-7)
	# Matching doors at both exits (leaving Dining at -8, entering Forge at -7)
	for gz in range(-8, -6):
		var forge_conn = Vector2i(12, gz)
		builder.register_tile(forge_conn, 1, true, "Dining Forge Corridor")
		mesh_builder.create_square_tile_mesh(dining, forge_conn, materials.mat_floor_stone)
	mesh_builder.build_arch_3tile(dining, Vector2i(12, -8), 0, "Dining Forge Gate")
	mesh_builder.build_arch_3tile(dining, Vector2i(12, -7), 0, "Forge Dining Gate")

	return dining
