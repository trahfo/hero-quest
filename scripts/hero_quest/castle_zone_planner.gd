class_name CastleZonePlanner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")
const CastleGardenPlanner = preload("res://scripts/hero_quest/castle_garden_planner.gd")
const CastleDiningPlanner = preload("res://scripts/hero_quest/castle_dining_planner.gd")
const CastlePerimeterBuilder = preload("res://scripts/hero_quest/castle_perimeter_builder.gd")
const CastleGraveyardPlanner = preload("res://scripts/hero_quest/castle_graveyard_planner.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")
const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

const TILE_SIZE: float = 2.0

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var garden_planner: CastleGardenPlanner
var dining_planner: CastleDiningPlanner
var perimeter_builder: CastlePerimeterBuilder
var graveyard_planner: CastleGraveyardPlanner

func _init(p_builder: Node3D, p_materials: CastleMaterials, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory) -> void:
	builder = p_builder
	materials = p_materials
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	decors = CastleDecorationFactory.new(materials, builder.grid_to_world)
	garden_planner = CastleGardenPlanner.new(builder, materials, mesh_builder, decors)
	dining_planner = CastleDiningPlanner.new(builder, materials, mesh_builder, prop_factory, decors)
	perimeter_builder = CastlePerimeterBuilder.new(builder, materials, mesh_builder, prop_factory)
	var graveyard_props = CastleGraveyardPropFactory.new(materials)
	graveyard_planner = CastleGraveyardPlanner.new(builder, materials, mesh_builder, graveyard_props)

func plan_and_build_all() -> void:
	plan_and_build_great_hall()
	plan_and_build_chapel()
	plan_and_build_blacksmith()
	plan_and_build_stables()
	garden_planner.plan_and_build()
	dining_planner.plan_and_build()
	graveyard_planner.plan_and_build()
	plan_and_build_chasm_and_bridges()
	plan_and_build_south_courtyard()
	plan_and_build_round_towers()
	build_grid_perimeter_walls()

func plan_and_build_great_hall() -> void:
	var room = Node3D.new()
	room.name = "GreatHall"
	builder.add_child(room)

	var zone_name = "The Great Corridor"

	for gx in range(-3, 4):
		for gz in range(-6, 7):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, zone_name) # FLOOR_STONE = 1
			var alt = (gx + gz) % 2 == 0
			mesh_builder.create_square_tile_mesh(room, cell, materials.mat_floor_stone if alt else materials.mat_floor_stone_alt)

	for gz in range(-5, 6):
		var carpet = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(TILE_SIZE * 2.0 - 0.2, 0.02, TILE_SIZE)
		b_mesh.material = materials.mat_cloth_red
		carpet.mesh = b_mesh
		carpet.position = builder.grid_to_world(Vector2i(0, gz)) + Vector3(0, 0.01, 0)
		room.add_child(carpet)

	for gz in [-4, 4]:
		builder.place_blocking_prop(room, Vector2i(-2, gz), "Pillar", func(p, pos): return mesh_builder.create_pillar(p, pos))
		builder.place_blocking_prop(room, Vector2i(2, gz), "Pillar", func(p, pos): return mesh_builder.create_pillar(p, pos))

	prop_factory.create_torch(room, builder.grid_to_world(Vector2i(-3, -3)) + Vector3(-1.55, 2.2, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(room, builder.grid_to_world(Vector2i(-3, 3)) + Vector3(-1.55, 2.2, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(room, builder.grid_to_world(Vector2i(3, -3)) + Vector3(1.55, 2.2, 0), Vector3(-1, 0, 0))
	prop_factory.create_torch(room, builder.grid_to_world(Vector2i(3, 3)) + Vector3(1.55, 2.2, 0), Vector3(-1, 0, 0))

	builder.place_blocking_prop(room, Vector2i(-2, 2), "Table", func(p, pos):
		var t = prop_factory.create_table(p, pos, Vector3(1.8, 1.0, 1.8))
		prop_factory.furniture.create_chair(t, Vector3(0, 0, 0.7), 0.0)
		return t
	)
	builder.place_blocking_prop(room, Vector2i(-3, -5), "Cupboard", func(p, pos): return prop_factory.create_cupboard(p, pos, PI * 0.5))
	builder.place_blocking_prop(room, Vector2i(-3, 5), "Drawer", func(p, pos): return prop_factory.create_drawer(p, pos, PI * 0.5))
	builder.place_blocking_prop(room, Vector2i(3, -5), "Bookshelf", func(p, pos): return prop_factory.create_bookshelf(p, pos, -PI * 0.5))
	builder.place_blocking_prop(room, Vector2i(3, 5), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, -PI * 0.5))

	var chest = prop_factory.create_treasure_chest(room, builder.grid_to_world(Vector2i(2, -2)) + Vector3(0, 0.12, 0), PI * 0.75, "Gold Relic of the King")
	builder.interactive_chests.append(chest)
	builder.grid[Vector2i(2, -2)]["walkable"] = false

	# West Connector Corridor directly into Stables: gx: -8..-4, gz: -1..1
	for gx in range(-8, -3):
		for gz in range(-1, 2):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, "West Passage")
			mesh_builder.create_square_tile_mesh(room, cell, materials.mat_floor_stone)

	mesh_builder.build_arch_3tile(room, Vector2i(-4, 0), 1, "West Portal") # ArchAxis.ALONG_Z = 1
	mesh_builder.build_arch_3tile(room, Vector2i(-8, 0), 1, "Stables Gate")

	# East Connector Corridor directly into Smith: gx: 4..8, gz: -1..1
	for gx in range(4, 9):
		for gz in range(-1, 2):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, "East Passage")
			mesh_builder.create_square_tile_mesh(room, cell, materials.mat_floor_stone)

	mesh_builder.build_arch_3tile(room, Vector2i(4, 0), 1, "East Portal")
	mesh_builder.build_arch_3tile(room, Vector2i(8, 0), 1, "Forge Gate")

	# North Connector Corridor directly into Chapel: gx: -2..2, gz: -11..-7 (widened to 5 tiles)
	for gx in range(-2, 3):
		for gz in range(-11, -6):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 2, true, "North Passage") # FLOOR_CHAPEL = 2
			mesh_builder.create_square_tile_mesh(room, cell, materials.mat_floor_chapel)

	# 3-Field Spanning Arch centered on red carpet axis at (0, -7), piers at gx = ±2, walls at gx = ±3
	mesh_builder.build_arch_spanning_3tiles(room, Vector2i(0, -7), 0, "Hall North Arch")

func plan_and_build_chapel() -> void:
	var chapel = Node3D.new()
	chapel.name = "Chapel"
	builder.add_child(chapel)

	var zone_name = "The Grand Chapel"

	for gx in range(-6, 7):
		for gz in range(-20, -11):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 2, true, zone_name)
			mesh_builder.create_square_tile_mesh(chapel, cell, materials.mat_floor_chapel)

	# Twin Portal arch is now part of the south wall at gz = -11
	mesh_builder.build_arch_5tile_twin(chapel, Vector2i(0, -11), 0, "Chapel Twin Portal")

	for gz in [-14, -17]:
		builder.place_blocking_prop(chapel, Vector2i(-4, gz), "Pillar", func(p, pos): return mesh_builder.create_pillar(p, pos, 6.0))
		builder.place_blocking_prop(chapel, Vector2i(4, gz), "Pillar", func(p, pos): return mesh_builder.create_pillar(p, pos, 6.0))

	for gz in [-14, -16, -18]:
		builder.place_multitile_prop(chapel, [Vector2i(-3, gz), Vector2i(-2, gz)], "Pew", func(p, pos):
			return prop_factory.create_bench_2tile(p, pos, true)
		)
		builder.place_multitile_prop(chapel, [Vector2i(2, gz), Vector2i(3, gz)], "Pew", func(p, pos):
			return prop_factory.create_bench_2tile(p, pos, true)
		)

	var altar_cell = Vector2i(0, -20)
	builder.grid[altar_cell]["walkable"] = false
	var altar_pos = builder.grid_to_world(altar_cell)
	var altar = prop_factory.create_table(chapel, altar_pos + Vector3(0, 0.12, 0), Vector3(2.6, 1.2, 1.6), materials.mat_wall_trim)
	altar.name = "AltarTable"
	var altar_interact = HeroQuestInteractable.new()
	altar_interact.name = "Interactable"
	altar_interact.interact_type = HeroQuestInteractable.InteractType.ALTAR
	altar.add_child(altar_interact)
	builder.interactive_altar = altar

	prop_factory.create_box_prop(chapel, altar_pos + Vector3(0, 1.9, 0), Vector3(0.2, 1.4, 0.2), materials.mat_gold, false)
	prop_factory.create_box_prop(chapel, altar_pos + Vector3(0, 2.2, 0), Vector3(0.8, 0.2, 0.2), materials.mat_gold, false)

	builder.place_blocking_prop(chapel, Vector2i(-2, -20), "Candelabra", func(p, pos): return prop_factory.create_candelabra(p, pos))
	builder.place_blocking_prop(chapel, Vector2i(2, -20), "Candelabra", func(p, pos): return prop_factory.create_candelabra(p, pos))

	var bell_cell = Vector2i(5, -19)
	builder.grid[bell_cell]["walkable"] = false
	var bell_pos = builder.grid_to_world(bell_cell)
	var _bell_post = prop_factory.create_box_prop(chapel, bell_pos + Vector3(0, 2.5, 0), Vector3(0.4, 5.0, 0.4), materials.mat_wood_dark, true)
	var bell = prop_factory.create_box_prop(chapel, bell_pos + Vector3(0, 3.8, 0), Vector3(0.8, 0.9, 0.8), materials.mat_gold, true)
	bell.name = "ChapelBell"
	var bell_interact = HeroQuestInteractable.new()
	bell_interact.name = "Interactable"
	bell_interact.interact_type = HeroQuestInteractable.InteractType.BELL
	bell.add_child(bell_interact)
	builder.interactive_bell = bell

	var divine_light = OmniLight3D.new()
	divine_light.light_color = Color(0.9, 0.85, 1.0)
	divine_light.light_energy = 2.5
	divine_light.omni_range = 16.0
	divine_light.position = builder.grid_to_world(Vector2i(0, -20)) + Vector3(0, 4.0, 0)
	chapel.add_child(divine_light)

	prop_factory.create_torch(chapel, builder.grid_to_world(Vector2i(-6, -15)) + Vector3(-1.55, 2.5, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(chapel, builder.grid_to_world(Vector2i(-6, -17)) + Vector3(-1.55, 2.5, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(chapel, builder.grid_to_world(Vector2i(6, -15)) + Vector3(1.55, 2.5, 0), Vector3(-1, 0, 0))
	prop_factory.create_torch(chapel, builder.grid_to_world(Vector2i(6, -17)) + Vector3(1.55, 2.5, 0), Vector3(-1, 0, 0))

	var chest_cell = Vector2i(-5, -19)
	builder.grid[chest_cell]["walkable"] = false
	var chest = prop_factory.create_treasure_chest(chapel, builder.grid_to_world(chest_cell) + Vector3(0, 0.12, 0), PI * 0.25, "Holy Chalice of Light")
	builder.interactive_chests.append(chest)

func plan_and_build_blacksmith() -> void:
	var smith = Node3D.new()
	smith.name = "Blacksmith"
	builder.add_child(smith)

	var zone_name = "The Blacksmith & Forge"

	for gx in range(9, 16):
		for gz in range(-6, 7):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 1, true, zone_name)
			mesh_builder.create_square_tile_mesh(smith, cell, materials.mat_floor_stone)

	for fgx in range(14, 16):
		for fgz in range(-1, 2):
			builder.grid[Vector2i(fgx, fgz)]["walkable"] = false

	var forge_center = builder.grid_to_world(Vector2i(14, 0)) + Vector3(1.0, 0, 0)
	prop_factory.create_box_prop(smith, forge_center + Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 4.0), materials.mat_wall_stone, true)
	prop_factory.create_box_prop(smith, forge_center + Vector3(0, 3.5, 0), Vector3(1.8, 3.0, 2.4), materials.mat_wall_trim, true)
	prop_factory.create_box_prop(smith, forge_center + Vector3(-0.6, 1.1, 0), Vector3(1.2, 0.4, 2.4), materials.mat_ember, false)

	var forge_light = OmniLight3D.new()
	forge_light.light_color = Color(1.0, 0.35, 0.05)
	forge_light.light_energy = 4.0
	forge_light.omni_range = 14.0
	forge_light.position = forge_center + Vector3(-0.5, 1.6, 0)
	smith.add_child(forge_light)

	var anvil_cell = Vector2i(12, 0)
	builder.grid[anvil_cell]["walkable"] = false
	var anvil = prop_factory.create_anvil(smith, builder.grid_to_world(anvil_cell) + Vector3(0, 0.12, 0))
	anvil.name = "BlacksmithAnvil"
	builder.interactive_anvil = anvil

	builder.place_blocking_prop(smith, Vector2i(14, 3), "Trough", func(p, pos): return prop_factory.create_water_trough(p, pos))
	builder.place_blocking_prop(smith, Vector2i(14, -3), "Grindstone", func(p, pos): return prop_factory.create_grindstone(p, pos))
	builder.place_blocking_prop(smith, Vector2i(11, -5), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, 0.0))
	builder.place_blocking_prop(smith, Vector2i(13, -5), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, 0.0))
	builder.place_blocking_prop(smith, Vector2i(11, 5), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, PI))
	builder.place_blocking_prop(smith, Vector2i(10, 3), "Workbench", func(p, pos):
		var wb = prop_factory.create_table(p, pos, Vector3(1.8, 1.0, 1.8))
		prop_factory.furniture.create_chair(wb, Vector3(0, 0, 0.7), 0.0)
		return wb
	)

	prop_factory.create_torch(smith, builder.grid_to_world(Vector2i(15, -4)) + Vector3(1.55, 2.2, 0), Vector3(-1, 0, 0))
	prop_factory.create_torch(smith, builder.grid_to_world(Vector2i(15, 4)) + Vector3(1.55, 2.2, 0), Vector3(-1, 0, 0))

	var chest_cell = Vector2i(14, 5)
	builder.grid[chest_cell]["walkable"] = false
	var chest = prop_factory.create_treasure_chest(smith, builder.grid_to_world(chest_cell) + Vector3(0, 0.12, 0), -PI * 0.75, "Mastercrafted Steel Blade")
	builder.interactive_chests.append(chest)

func plan_and_build_stables() -> void:
	var stables = Node3D.new()
	stables.name = "Stables"
	builder.add_child(stables)

	var zone_name = "The Royal Stables"

	for gx in range(-15, -8):
		for gz in range(-6, 7):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 3, true, zone_name) # FLOOR_WOOD = 3
			mesh_builder.create_square_tile_mesh(stables, cell, materials.mat_floor_wood)

	for gx in [-14, -10]:
		builder.place_blocking_prop(stables, Vector2i(gx, -5), "Hay", func(p, pos): return prop_factory.create_hay_bale(p, pos))
		builder.place_blocking_prop(stables, Vector2i(gx, -6), "Trough", func(p, pos): return prop_factory.create_water_trough(p, pos))
		builder.place_blocking_prop(stables, Vector2i(gx, 5), "Hay", func(p, pos): return prop_factory.create_hay_bale(p, pos))
		builder.place_blocking_prop(stables, Vector2i(gx, 6), "Trough", func(p, pos): return prop_factory.create_water_trough(p, pos))

	builder.place_blocking_prop(stables, Vector2i(-15, -2), "Cupboard", func(p, pos): return prop_factory.create_cupboard(p, pos, PI * 0.5))
	builder.place_blocking_prop(stables, Vector2i(-15, 2), "Drawer", func(p, pos): return prop_factory.create_drawer(p, pos, PI * 0.5))

	# Torches mounted on solid wall piers flanking the chest (strictly away from windows at gz = -4, 0, 4)
	prop_factory.create_torch(stables, builder.grid_to_world(Vector2i(-15, -1)) + Vector3(-1.55, 2.2, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(stables, builder.grid_to_world(Vector2i(-15, 1)) + Vector3(-1.55, 2.2, 0), Vector3(1, 0, 0))

	var chest_cell = Vector2i(-14, 0)
	builder.grid[chest_cell]["walkable"] = false
	var chest = prop_factory.create_treasure_chest(stables, builder.grid_to_world(chest_cell) + Vector3(0, 0.12, 0), PI * 0.5, "Rider's Swift Boots")
	builder.interactive_chests.append(chest)

func plan_and_build_chasm_and_bridges() -> void:
	var chasm = Node3D.new()
	chasm.name = "Chasm"
	builder.add_child(chasm)

	var bridges = Node3D.new()
	bridges.name = "Bridges"
	builder.add_child(bridges)

	var zone_chasm = "The Chasm Bridge"

	for gx in range(-18, 19):
		for gz in range(7, 13):
			var cell = Vector2i(gx, gz)
			if gx >= -1 and gx <= 1:
				builder.register_tile(cell, 4, true, zone_chasm) # FLOOR_BRIDGE = 4
				mesh_builder.create_square_tile_mesh(bridges, cell, materials.mat_floor_bridge)
			else:
				builder.register_tile(cell, 7, false, zone_chasm) # CHASM = 7

	var chasm_floor = prop_factory.create_box_prop(chasm, Vector3(0, -8.0, 9.5 * TILE_SIZE), Vector3(72, 1.0, 6 * TILE_SIZE), materials.mat_water_chasm, true)
	chasm_floor.name = "AbyssBed"

	var chasm_light = OmniLight3D.new()
	chasm_light.light_color = Color(0.12, 0.28, 0.55)
	chasm_light.light_energy = 1.6
	chasm_light.omni_range = 28.0
	chasm_light.position = Vector3(0, -4.0, 9.5 * TILE_SIZE)
	chasm.add_child(chasm_light)

	for gz in range(7, 13):
		var p_left = mesh_builder.create_wall_segment(bridges, Vector2i(-2, gz), 1.8)
		p_left.name = "BridgeRailLeft"
		var p_right = mesh_builder.create_wall_segment(bridges, Vector2i(2, gz), 1.8)
		p_right.name = "BridgeRailRight"

	prop_factory.create_torch(bridges, builder.grid_to_world(Vector2i(-1, 7)) + Vector3(-1.55, 1.8, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(bridges, builder.grid_to_world(Vector2i(1, 7)) + Vector3(1.55, 1.8, 0), Vector3(-1, 0, 0))
	prop_factory.create_torch(bridges, builder.grid_to_world(Vector2i(-1, 12)) + Vector3(-1.55, 1.8, 0), Vector3(1, 0, 0))
	prop_factory.create_torch(bridges, builder.grid_to_world(Vector2i(1, 12)) + Vector3(1.55, 1.8, 0), Vector3(-1, 0, 0))

	# Bridge 3-field spanning arches at start (gz = 6) and end (gz = 13) only
	mesh_builder.build_arch_spanning_3tiles(bridges, Vector2i(0, 6), 0, "Bridge North Arch")

func plan_and_build_south_courtyard() -> void:
	var yard = Node3D.new()
	yard.name = "SouthCourtyard"
	builder.add_child(yard)

	var zone_name = "South Castle Courtyard"

	for gx in range(-7, 8):
		for gz in range(13, 19):
			var cell = Vector2i(gx, gz)
			builder.register_tile(cell, 5, true, zone_name) # FLOOR_COURTYARD = 5
			mesh_builder.create_square_tile_mesh(yard, cell, materials.mat_floor_stone)

	# Courtyard Portal: 3-field spanning arch across the bridge walkway at the south end
	mesh_builder.build_arch_spanning_3tiles(yard, Vector2i(0, 13), 0, "Courtyard Portal")

	# North Chasm Balustrades / Fences guarding the abyss (flanking the bridge portal)
	# Shortened by 1 tile (length 10.0m instead of 12.0m) to keep gx = ±2 completely clear of bridge rails & arch
	# Left section: gx: -7..-3 (length 10.0m centered at x = -10.0, z = 25.0)
	decors.create_iron_fence(yard, Vector3(-10.0, 0, 25.0), 10.0, 1.3, "CourtyardFenceLeft")
	# Right section: gx: 3..7 (length 10.0m centered at x = 10.0, z = 25.0)
	decors.create_iron_fence(yard, Vector3(10.0, 0, 25.0), 10.0, 1.3, "CourtyardFenceRight")

	builder.place_blocking_prop(yard, Vector2i(-3, 15), "Brazier", func(p, pos): return prop_factory.create_brazier(p, pos))
	builder.place_blocking_prop(yard, Vector2i(3, 15), "Brazier", func(p, pos): return prop_factory.create_brazier(p, pos))
	builder.place_blocking_prop(yard, Vector2i(-6, 17), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, PI * 0.5))
	builder.place_blocking_prop(yard, Vector2i(6, 17), "ArmsShelf", func(p, pos): return prop_factory.create_arms_shelf(p, pos, -PI * 0.5))

	prop_factory.create_box_prop(yard, builder.grid_to_world(Vector2i(0, 18)) + Vector3(0, 2.5, 0.9), Vector3(4.0, 5.0, 0.4), materials.mat_iron, true)

	var chest_cell = Vector2i(4, 14)
	builder.grid[chest_cell]["walkable"] = false
	var chest = prop_factory.create_treasure_chest(yard, builder.grid_to_world(chest_cell) + Vector3(0, 0.12, 0), -PI * 0.25, "Knight Commander's Shield")
	builder.interactive_chests.append(chest)

func plan_and_build_round_towers() -> void:
	perimeter_builder.build_round_towers()

func build_grid_perimeter_walls() -> void:
	perimeter_builder.build_grid_perimeter_walls()
