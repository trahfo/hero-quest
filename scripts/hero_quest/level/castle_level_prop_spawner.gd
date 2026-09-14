class_name CastleLevelPropSpawner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")
const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")
const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")

var materials: CastleMaterials
var grid_to_world_fn: Callable
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var graveyard_props: CastleGraveyardPropFactory
var wall_factory: CastleWallTileFactory

func _init(p_materials: CastleMaterials, p_grid_to_world: Callable, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory) -> void:
	materials = p_materials
	grid_to_world_fn = p_grid_to_world
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	decors = CastleDecorationFactory.new(materials, grid_to_world_fn)
	graveyard_props = CastleGraveyardPropFactory.new(materials)
	wall_factory = CastleWallTileFactory.new(materials)

func spawn_carpet(room: Node3D, data: Dictionary) -> MeshInstance3D:
	var carpet = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = CastleLevelData.arr_to_vec3(data.get("size", [3.8, 0.02, 2.0]))
	var m_name = data.get("mat", "cloth_red")
	b_mesh.material = CastleLevelData.name_to_mat(m_name, materials)
	carpet.mesh = b_mesh
	carpet.position = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0.01, 0]))
	room.add_child(carpet)
	return carpet

func spawn_pillar(room: Node3D, data: Dictionary, builder: Node3D) -> StaticBody3D:
	var cell = CastleLevelData.arr_to_vec2i(data.get("cell", [0, 0]))
	var h = float(data.get("height", 4.5))
	var p_body: StaticBody3D
	builder.place_blocking_prop(room, cell, "Pillar", func(p, pos):
		p_body = mesh_builder.create_pillar(p, pos, h)
		return p_body
	)
	return p_body

func spawn_torch(room: Node3D, data: Dictionary) -> Node3D:
	var pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
	var norm = CastleLevelData.arr_to_vec3(data.get("norm", [1, 0, 0]))
	return prop_factory.create_torch(room, pos, norm)

func spawn_light(room: Node3D, data: Dictionary) -> OmniLight3D:
	var light = OmniLight3D.new()
	if data.has("name"):
		light.name = data["name"]
	light.light_color = CastleLevelData.arr_to_color(data.get("color", [1, 1, 1, 1]))
	light.light_energy = float(data.get("energy", 1.0))
	light.omni_range = float(data.get("range", 10.0))
	light.position = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
	room.add_child(light)
	return light

func spawn_arch(room: Node3D, data: Dictionary) -> void:
	var a_type = data.get("type", "arch_3tile")
	if a_type != "curved_arch" and not data.has("cell"):
		return
	var a_name = data.get("name", "Arch")
	var cell = CastleLevelData.arr_to_vec2i(data.get("cell", [0, 0]))
	var axis = int(data.get("axis", 0))

	match a_type:
		"arch_3tile":
			mesh_builder.build_arch_3tile(room, cell, axis, a_name)
		"arch_spanning_3tiles":
			mesh_builder.build_arch_spanning_3tiles(room, cell, axis, a_name)
		"arch_5tile_twin":
			mesh_builder.build_arch_5tile_twin(room, cell, axis, a_name)
		"curved_arch":
			var pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
			var span = float(data.get("span", 6.0))
			var spring_h = float(data.get("spring_h", 3.6))
			var thick = float(data.get("thickness", 0.9))
			mesh_builder.create_curved_arch_mesh(room, pos, span, spring_h, axis, thick)

func spawn_prop(room: Node3D, data: Dictionary, builder: Node3D) -> Node3D:
	var p_type = data.get("type", "")
	var pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
	var rot_y = float(data.get("rot_y", 0.0))
	var p_cell = CastleLevelData.arr_to_vec2i(data.get("cell", [0, 0]))

	match p_type:
		"torch":
			var norm = CastleLevelData.arr_to_vec3(data.get("norm", [1, 0, 0]))
			return prop_factory.create_torch(room, pos, norm)
		"brazier":
			var b_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Brazier", func(p, ppos):
				b_node = prop_factory.create_brazier(p, ppos)
				return b_node
			)
			return b_node
		"table":
			var size = CastleLevelData.arr_to_vec3(data.get("size", [1.8, 1.0, 1.8]))
			var mat = CastleLevelData.name_to_mat(data.get("mat", ""), materials) if data.has("mat") else null
			var t_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Table", func(p, ppos):
				t_node = prop_factory.create_table(p, ppos, size, mat)
				if data.get("has_chair", false):
					var ch_offset = CastleLevelData.arr_to_vec3(data.get("chair_offset", [0, 0, 0.7]))
					var ch_rot = float(data.get("chair_rot", 0.0))
					prop_factory.furniture.create_chair(t_node, ch_offset, ch_rot)
				return t_node
			)
			return t_node
		"chair":
			var c_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Chair", func(p, ppos):
				c_node = prop_factory.furniture.create_chair(p, ppos, rot_y)
				return c_node
			)
			return c_node
		"cupboard":
			var cp_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Cupboard", func(p, ppos):
				cp_node = prop_factory.create_cupboard(p, ppos, rot_y)
				return cp_node
			)
			return cp_node
		"drawer":
			var d_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Drawer", func(p, ppos):
				d_node = prop_factory.create_drawer(p, ppos, rot_y)
				return d_node
			)
			return d_node
		"bookshelf":
			var bs_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Bookshelf", func(p, ppos):
				bs_node = prop_factory.create_bookshelf(p, ppos, rot_y)
				return bs_node
			)
			return bs_node
		"arms_shelf":
			var as_node: Node3D
			builder.place_blocking_prop(room, p_cell, "ArmsShelf", func(p, ppos):
				as_node = prop_factory.create_arms_shelf(p, ppos, rot_y)
				return as_node
			)
			return as_node
		"treasure_chest":
			var relic = data.get("relic_name", "Ancient Relic")
			var mini_game = data.get("mini_game_id", "")
			var chest = prop_factory.create_treasure_chest(room, pos, rot_y, relic, mini_game)
			builder.interactive_chests.append(chest)
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
			return chest
		"candelabra":
			var cd_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Candelabra", func(p, ppos):
				cd_node = prop_factory.create_candelabra(p, ppos)
				return cd_node
			)
			return cd_node
		"anvil":
			var anvil = prop_factory.create_anvil(room, pos)
			anvil.name = "BlacksmithAnvil"
			builder.interactive_anvil = anvil
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
			return anvil
		"altar":
			var altar_size = CastleLevelData.arr_to_vec3(data.get("size", [2.6, 1.2, 1.6]))
			var altar = prop_factory.create_table(room, pos, altar_size, materials.mat_wall_trim)
			altar.name = "AltarTable"
			var altar_interact = HeroQuestInteractable.new()
			altar_interact.name = "Interactable"
			altar_interact.interact_type = HeroQuestInteractable.InteractType.ALTAR
			altar.add_child(altar_interact)
			builder.interactive_altar = altar
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
			return altar
		"bell":
			var b_pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
			var _post = prop_factory.create_box_prop(room, b_pos + Vector3(0, 2.5, 0), Vector3(0.4, 5.0, 0.4), materials.mat_wood_dark, true)
			var bell = prop_factory.create_box_prop(room, b_pos + Vector3(0, 3.8, 0), Vector3(0.8, 0.9, 0.8), materials.mat_gold, true)
			bell.name = "ChapelBell"
			var bell_interact = HeroQuestInteractable.new()
			bell_interact.name = "Interactable"
			bell_interact.interact_type = HeroQuestInteractable.InteractType.BELL
			bell.add_child(bell_interact)
			builder.interactive_bell = bell
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
			return bell
		"pew":
			var cells_arr: Array = data.get("cells", [])
			var cells: Array[Vector2i] = []
			for c in cells_arr:
				cells.append(CastleLevelData.arr_to_vec2i(c))
			var with_back = data.get("with_back", true)
			return builder.place_multitile_prop(room, cells, "Pew", func(p, ppos):
				return prop_factory.create_bench_2tile(p, ppos, with_back, rot_y)
			)
		"water_trough":
			var wt_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Trough", func(p, ppos):
				wt_node = prop_factory.create_water_trough(p, ppos)
				return wt_node
			)
			return wt_node
		"grindstone":
			var gs_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Grindstone", func(p, ppos):
				gs_node = prop_factory.create_grindstone(p, ppos)
				return gs_node
			)
			return gs_node
		"hay_bale":
			var hb_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Hay", func(p, ppos):
				hb_node = prop_factory.create_hay_bale(p, ppos)
				return hb_node
			)
			return hb_node
		"box_prop":
			var size = CastleLevelData.arr_to_vec3(data.get("size", [1, 1, 1]))
			var mat = CastleLevelData.name_to_mat(data.get("mat", "stone"), materials)
			var has_col = data.get("collision", true)
			var bp = prop_factory.create_box_prop(room, pos, size, mat, has_col)
			if data.has("name"):
				bp.name = data["name"]
			return bp
		_:
			return _spawn_special_prop(room, data, builder, p_type, pos, rot_y, p_cell)

func _spawn_special_prop(room: Node3D, data: Dictionary, builder: Node3D, p_type: String, pos: Vector3, rot_y: float, p_cell: Vector2i) -> Node3D:
	match p_type:
		"fountain":
			var f_cells: Array[Vector2i] = []
			for c in data.get("cells", []): f_cells.append(CastleLevelData.arr_to_vec2i(c))
			return builder.place_multitile_prop(room, f_cells, "Fountain", func(p, ppos): return decors.create_fountain(p, ppos))
		"bush":
			var rad = float(data.get("radius", 1.2))
			var b_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Bush", func(p, ppos):
				b_node = decors.create_bush(p, ppos, rad)
				return b_node
			)
			return b_node
		"flower_patch":
			return decors.create_flower_patch(room, pos)
		"painting":
			var norm = CastleLevelData.arr_to_vec3(data.get("norm", [0, 0, 1]))
			var idx = int(data.get("index", 0))
			return decors.create_painting(room, pos, norm, idx)
		"grand_table":
			var gt_cells: Array[Vector2i] = []
			for c in data.get("cells", []): gt_cells.append(CastleLevelData.arr_to_vec2i(c))
			var size = CastleLevelData.arr_to_vec3(data.get("size", [3.6, 1.1, 9.6]))
			return builder.place_multitile_prop(room, gt_cells, "GrandTable", func(p, ppos):
				return prop_factory.furniture.create_table(p, ppos, size, materials.mat_wood_dark)
			)
		"chimney":
			var ch_cells: Array[Vector2i] = []
			for c in data.get("cells", []): ch_cells.append(CastleLevelData.arr_to_vec2i(c))
			return builder.place_multitile_prop(room, ch_cells, "Chimney", func(p, ppos):
				return decors.create_chimney_fireplace(p, ppos, rot_y)
			)
		"gravestone":
			var epitaph = data.get("epitaph", "Rest in Peace")
			var style = int(data.get("style", 0))
			var g_name = data.get("name", "Gravestone")
			var gs_node: Node3D
			builder.place_blocking_prop(room, p_cell, g_name, func(p, ppos):
				gs_node = graveyard_props.create_gravestone(p, ppos, rot_y, epitaph, style, g_name)
				return gs_node
			)
			return gs_node
		"skeleton":
			var sk_node: Node3D
			builder.place_blocking_prop(room, p_cell, "Skeleton", func(p, ppos):
				sk_node = graveyard_props.create_skeleton(p, ppos, rot_y)
				return sk_node
			)
			return sk_node
		"ancient_tree":
			var tr_node: Node3D
			builder.place_blocking_prop(room, p_cell, "AncientTree", func(p, ppos):
				tr_node = graveyard_props.create_cemetery_tree(p, ppos)
				return tr_node
			)
			return tr_node
		"torch_on_stick":
			var t_name = data.get("name", "TorchOnStick")
			var ts_node: Node3D
			builder.place_blocking_prop(room, p_cell, t_name, func(p, ppos):
				ts_node = graveyard_props.create_torch_on_stick(p, ppos, t_name)
				return ts_node
			)
			return ts_node
		"cemetery_fence":
			var length = float(data.get("length", 10.0))
			var is_z = data.get("is_z", false)
			var f_name = data.get("name", "CemeteryFence")
			return graveyard_props.create_cemetery_fence(room, pos, length, is_z, f_name)
		"iron_fence":
			var length = float(data.get("length", 10.0))
			var height = float(data.get("height", 1.3))
			var f_name = data.get("name", "CourtyardFence")
			return decors.create_iron_fence(room, pos, length, height, f_name)
		"stone_pillar":
			var p_name = data.get("name", "StonePillar")
			return graveyard_props.create_stone_pillar(room, pos, p_name)
		"bridge_rail":
			var rail_h = float(data.get("height", 1.8))
			var rail = mesh_builder.create_wall_segment(room, p_cell, rail_h)
			if data.has("name"):
				rail.name = data["name"]
			return rail
		_:
			return null
