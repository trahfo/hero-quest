class_name CastleGraveyardPlanner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")

const TILE_SIZE: float = 2.0

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var graveyard_props: CastleGraveyardPropFactory

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_graveyard_props: CastleGraveyardPropFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	graveyard_props = p_graveyard_props

func plan_and_build() -> Node3D:
	var graveyard = Node3D.new()
	graveyard.name = "Graveyard"
	builder.add_child(graveyard)

	var zone_name = "The Graveyard"

	# 1. Entrance Portal from Cloister Garden at (-12, -25)
	var gate_cell = Vector2i(-12, -25)
	builder.register_tile(gate_cell, 8, true, "Graveyard Entrance Portal")
	mesh_builder.create_square_tile_mesh(graveyard, gate_cell, materials.mat_floor_stone)
	mesh_builder.build_arch_3tile(graveyard, gate_cell, 0, "Graveyard Entrance Arch")

	# 2. Register Cemetery Ground Grid: gx: -16..-8 (9 cols), gz: -33..-26 (8 rows)
	for gx in range(-16, -7):
		for gz in range(-33, -25):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 8, true, zone_name)
			var is_path_ns = (gx == -12)
			var is_cross_path = (gz == -29)
			if is_path_ns or is_cross_path:
				mesh_builder.create_square_tile_mesh(graveyard, cell, materials.mat_floor_stone_alt)
			else:
				mesh_builder.create_square_tile_mesh(graveyard, cell, materials.mat_floor_graveyard_dirt)

	# 3. Exactly 10 Gravestones with Epitaphs & Inspection
	var gravestone_defs = [
		# West Quadrant (5 gravestones)
		{"cell": Vector2i(-15, -27), "rot": 0.0, "epitaph": "Sir Roderick the Valiant (1142 - 1189) - Slain defending the North Gate", "style": 0},
		{"cell": Vector2i(-14, -27), "rot": 0.0, "epitaph": "Lady Isolde of Dunmere (1150 - 1210) - Beloved healer and herbalist", "style": 1},
		{"cell": Vector2i(-15, -29), "rot": 0.05, "epitaph": "Brother Alistair (1130 - 1195) - Devoted monk of the Grand Chapel", "style": 2},
		{"cell": Vector2i(-14, -31), "rot": -0.04, "epitaph": "Master Blacksmith Thorne (1148 - 1204) - His steel forged the realm's peace", "style": 3},
		{"cell": Vector2i(-15, -32), "rot": 0.0, "epitaph": "Captain Gerald (1138 - 1192) - Commander of the Royal Guard", "style": 0},
		# East Quadrant (5 gravestones)
		{"cell": Vector2i(-9, -27), "rot": 0.0, "epitaph": "Eleanor of the White Raven (1165 - 1215) - Court astronomer and scholar", "style": 1},
		{"cell": Vector2i(-10, -27), "rot": -0.03, "epitaph": "Unknown Knight of the Order - His deeds remembered by stone alone", "style": 0},
		{"cell": Vector2i(-9, -29), "rot": 0.0, "epitaph": "High Steward Balin (1122 - 1180) - Faithful keeper of the castle vaults", "style": 2},
		{"cell": Vector2i(-10, -31), "rot": 0.06, "epitaph": "Squire Marcus (1175 - 1198) - Fallen young in foreign crusades", "style": 3},
		{"cell": Vector2i(-9, -32), "rot": 0.0, "epitaph": "Father Gregory (1110 - 1172) - First Abbot of the Cloister", "style": 1}
	]
	for i in range(gravestone_defs.size()):
		var g_def = gravestone_defs[i]
		var g_name = "Gravestone_%d" % (i + 1)
		builder.place_blocking_prop(graveyard, g_def["cell"], g_name, func(p, pos):
			return graveyard_props.create_gravestone(p, pos, g_def["rot"], g_def["epitaph"], g_def["style"], g_name)
		)

	# 4. Bleached Skeleton
	builder.place_blocking_prop(graveyard, Vector2i(-13, -28), "Skeleton", func(p, pos):
		return graveyard_props.create_skeleton(p, pos, PI * 0.25)
	)

	# 5. Ancient Gnarled Tree
	builder.place_blocking_prop(graveyard, Vector2i(-10, -30), "AncientTree", func(p, pos):
		return graveyard_props.create_cemetery_tree(p, pos)
	)

	# 6. Outdoor Stake Torches
	var torch_cells = [
		Vector2i(-13, -26), Vector2i(-11, -26), # Flanking entrance gate
		Vector2i(-13, -29),                      # Near skeleton and cross-path
		Vector2i(-13, -32), Vector2i(-11, -32)  # Northern path ends
	]
	for i in range(torch_cells.size()):
		var t_cell = torch_cells[i]
		var t_name = "TorchOnStick_%d" % (i + 1)
		builder.place_blocking_prop(graveyard, t_cell, t_name, func(p, pos):
			return graveyard_props.create_torch_on_stick(p, pos, t_name)
		)

	# 7. Cemetery Perimeter Fence & Stone Pillars
	# Bounds: gx: -16..-8 (x: -33.0 to -15.0), gz: -33..-26 (z: -67.0 to -51.0)
	graveyard_props.create_cemetery_fence(graveyard, Vector3(-24.0, 0, -67.0), 18.0, false, "CemeteryFenceNorth")
	graveyard_props.create_cemetery_fence(graveyard, Vector3(-33.0, 0, -59.0), 16.0, true, "CemeteryFenceWest")
	graveyard_props.create_cemetery_fence(graveyard, Vector3(-15.0, 0, -59.0), 16.0, true, "CemeteryFenceEast")

	# South fence (split around gate at x = -24.0)
	graveyard_props.create_cemetery_fence(graveyard, Vector3(-29.25, 0, -51.0), 7.5, false, "CemeteryFenceSouthWest")
	graveyard_props.create_cemetery_fence(graveyard, Vector3(-18.75, 0, -51.0), 7.5, false, "CemeteryFenceSouthEast")

	# Stone Corner & Gate Pillars
	graveyard_props.create_stone_pillar(graveyard, Vector3(-33.0, 0, -67.0), "PillarNW")
	graveyard_props.create_stone_pillar(graveyard, Vector3(-15.0, 0, -67.0), "PillarNE")
	graveyard_props.create_stone_pillar(graveyard, Vector3(-33.0, 0, -51.0), "PillarSW")
	graveyard_props.create_stone_pillar(graveyard, Vector3(-15.0, 0, -51.0), "PillarSE")
	graveyard_props.create_stone_pillar(graveyard, Vector3(-25.5, 0, -51.0), "GatePillarWest")
	graveyard_props.create_stone_pillar(graveyard, Vector3(-22.5, 0, -51.0), "GatePillarEast")

	# 8. Eerie Atmospheric Pale Moonlight
	var moon = OmniLight3D.new()
	moon.name = "GraveyardMoonlight"
	moon.light_color = Color(0.65, 0.75, 0.95)
	moon.light_energy = 1.6
	moon.omni_range = 28.0
	moon.position = Vector3(-24.0, 7.0, -59.0)
	graveyard.add_child(moon)

	return graveyard
