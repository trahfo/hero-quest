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
const CastleDoorBuilder = preload("res://scripts/hero_quest/castle_door_builder.gd")
const HeroQuestDoor = preload("res://scripts/hero_quest/hero_quest_door.gd")
const HeroQuestFloorItem = preload("res://scripts/hero_quest/hero_quest_floor_item.gd")
const ItemDatabase = preload("res://scripts/hero_quest/item_database.gd")

var materials: CastleMaterials
var grid_to_world_fn: Callable
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var graveyard_props: CastleGraveyardPropFactory
var wall_factory: CastleWallTileFactory
var door_builder: CastleDoorBuilder

func _init(p_materials: CastleMaterials, p_grid_to_world: Callable, p_mesh_builder: CastleMeshBuilder, p_prop_factory: CastlePropFactory) -> void:
	materials = p_materials
	grid_to_world_fn = p_grid_to_world
	mesh_builder = p_mesh_builder
	prop_factory = p_prop_factory
	decors = CastleDecorationFactory.new(materials, grid_to_world_fn)
	graveyard_props = CastleGraveyardPropFactory.new(materials)
	wall_factory = CastleWallTileFactory.new(materials)
	door_builder = CastleDoorBuilder.new(materials)

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

func spawn_arch(room: Node3D, data: Dictionary, builder: Node3D = null) -> void:
	var a_type = data.get("type", "arch_3tile")
	if a_type != "curved_arch" and not data.has("cell"):
		return
	var a_name = data.get("name", "Arch")
	var cell = CastleLevelData.arr_to_vec2i(data.get("cell", [0, 0]))
	var axis = int(data.get("axis", 0))

	if "door" in a_type or "portcullis" in a_type:
		var is_2tile = ("2tile" in a_type)
		var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
		var arch_node = Node3D.new()
		arch_node.name = a_name
		room.add_child(arch_node)

		var door_sub = Node3D.new()
		var center_pos = grid_to_world_fn.call(cell) if not is_2tile else (grid_to_world_fn.call(cell) + grid_to_world_fn.call(cell + off)) * 0.5
		door_sub.position = center_pos
		arch_node.add_child(door_sub)

		var door_res: Dictionary
		match a_type:
			"wooden_door_1tile":
				door_res = door_builder.build_wooden_door_1tile(door_sub, axis)
			"wooden_door_2tile":
				door_res = door_builder.build_wooden_door_2tile(door_sub, axis)
			"iron_door_1tile":
				door_res = door_builder.build_iron_door_1tile(door_sub, axis)
			"iron_door_2tile":
				door_res = door_builder.build_iron_door_2tile(door_sub, axis)
			"portcullis_1tile":
				door_res = door_builder.build_portcullis(door_sub, 1, axis)
			"portcullis_2tile":
				door_res = door_builder.build_portcullis(door_sub, 2, axis)
			_:
				door_res = door_builder.build_wooden_door_1tile(door_sub, axis)

		var occupied_cells: Array[Vector2i] = []
		if is_2tile:
			occupied_cells.append_array([cell, cell + off])
		else:
			occupied_cells.append(cell)
		var is_open = bool(data.get("is_open", false))
		if builder:
			for c in occupied_cells:
				if not builder.grid.has(c):
					builder.register_tile(c, 1, is_open, "Doorway")
				else:
					builder.grid[c]["walkable"] = is_open
				builder.grid[c]["prop"] = arch_node

		var door_controller = HeroQuestDoor.new()
		door_controller.name = "DoorController"
		arch_node.add_child(door_controller)
		var audio_mgr = builder.get_node_or_null("AudioManager") if (builder and builder.has_node("AudioManager")) else null
		var d_info = data.duplicate()
		d_info["occupied_cells"] = occupied_cells
		var pivots: Array[Node3D] = []
		pivots.assign(door_res.get("pivots", []))
		door_controller.setup(builder, audio_mgr, d_info, pivots, door_res.get("is_slide", false))
		return

	var created_arch: Node3D = null
	match a_type:
		"arch_3tile":
			created_arch = mesh_builder.build_arch_3tile(room, cell, axis, a_name)
		"arch_4tile":
			var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
			created_arch = mesh_builder.build_arch_4tile(room, cell, cell + off, axis, a_name)
		"arch_spanning_3tiles":
			created_arch = mesh_builder.build_arch_spanning_3tiles(room, cell, axis, a_name)
		"arch_5tile_twin":
			created_arch = mesh_builder.build_arch_5tile_twin(room, cell, axis, a_name)
		"curved_arch":
			var pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0]))
			var span = float(data.get("span", 6.0))
			var spring_h = float(data.get("spring_h", 3.6))
			var thick = float(data.get("thickness", 0.9))
			created_arch = mesh_builder.create_curved_arch_mesh(room, pos, span, spring_h, axis, thick)

	if created_arch and builder and builder.grid.has(cell):
		builder.grid[cell]["prop"] = created_arch

func spawn_prop(room: Node3D, data: Dictionary, builder: Node3D) -> Node3D:
	var p_type = data.get("type", "")
	var p_cell = CastleLevelData.arr_to_vec2i(data.get("cell", [0, 0]))
	var pos = CastleLevelData.arr_to_vec3(data.get("pos", [0, 0, 0])) if data.has("pos") else (grid_to_world_fn.call(p_cell) if (grid_to_world_fn.is_valid() and data.has("cell")) else Vector3.ZERO)
	var rot_y = float(data.get("rot_y", 0.0))

	match p_type:
		"torch":
			var norm = CastleLevelData.arr_to_vec3(data.get("norm", [1, 0, 0]))
			return prop_factory.create_torch(room, pos, norm)
		"brazier":
			return builder.place_blocking_prop(room, p_cell, "Brazier", func(p, ppos):
				return prop_factory.create_brazier(p, ppos)
			)
		"table":
			var size = CastleLevelData.arr_to_vec3(data.get("size", [1.8, 1.0, 1.8]))
			var mat = CastleLevelData.name_to_mat(data.get("mat", ""), materials) if data.has("mat") else null
			var t_name = data.get("name", "Table")
			var t_node = builder.place_blocking_prop(room, p_cell, t_name, func(p, ppos):
				var node = prop_factory.create_table(p, ppos, size, mat)
				node.name = t_name
				if data.get("has_chair", false):
					var ch_offset = CastleLevelData.arr_to_vec3(data.get("chair_offset", [0, 0, 0.7]))
					var ch_rot = float(data.get("chair_rot", 0.0))
					prop_factory.furniture.create_chair(node, ch_offset, ch_rot)
				return node
			)
			return t_node
		"chair":
			return builder.place_blocking_prop(room, p_cell, "Chair", func(p, ppos):
				return prop_factory.furniture.create_chair(p, ppos, rot_y)
			)
		"cupboard":
			return builder.place_blocking_prop(room, p_cell, "Cupboard", func(p, ppos):
				return prop_factory.create_cupboard(p, ppos, rot_y)
			)
		"drawer":
			return builder.place_blocking_prop(room, p_cell, "Drawer", func(p, ppos):
				return prop_factory.create_drawer(p, ppos, rot_y)
			)
		"bookshelf":
			return builder.place_blocking_prop(room, p_cell, "Bookshelf", func(p, ppos):
				return prop_factory.create_bookshelf(p, ppos, rot_y)
			)
		"arms_shelf":
			var as_name = data.get("name", "ArmsShelf")
			return builder.place_blocking_prop(room, p_cell, as_name, func(p, ppos):
				var as_node = prop_factory.create_arms_shelf(p, ppos, rot_y)
				as_node.name = as_name
				return as_node
			)
		"treasure_chest", "chest":
			var relic = data.get("relic_name", "Ancient Relic")
			var mini_game = data.get("mini_game_id", "")
			var chest = prop_factory.create_treasure_chest(room, pos, rot_y, relic, mini_game)
			builder.interactive_chests.append(chest)
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
				builder.grid[p_cell]["prop"] = chest
			return chest
		"floor_item", "floor_key":
			var item_id = data.get("item_id", "iron_key")
			var item_data = ItemDatabase.create_item(item_id)
			var floor_item = HeroQuestFloorItem.new()
			room.add_child(floor_item)
			floor_item.setup(item_data, pos)
			if builder:
				if not builder.grid.has(p_cell):
					builder.register_tile(p_cell, 1, true, "Floor")
				else:
					builder.grid[p_cell]["walkable"] = true
				builder.grid[p_cell]["prop"] = floor_item
			return floor_item
		"candelabra":
			return builder.place_blocking_prop(room, p_cell, "Candelabra", func(p, ppos):
				return prop_factory.create_candelabra(p, ppos)
			)
		"anvil":
			var anvil = prop_factory.create_anvil(room, pos)
			anvil.name = "BlacksmithAnvil"
			builder.interactive_anvil = anvil
			if builder.grid.has(p_cell):
				builder.grid[p_cell]["walkable"] = false
				builder.grid[p_cell]["prop"] = anvil
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
		"bench", "pew":
			var cells_arr: Array = data.get("cells", [])
			var cells: Array[Vector2i] = []
			for c in cells_arr:
				cells.append(CastleLevelData.arr_to_vec2i(c))
			if cells.is_empty():
				cells.append(p_cell)
			var with_back = data.get("with_back", p_type == "pew")
			var b_name = data.get("name", "WoodenBench" if p_type == "bench" else "Pew")
			return builder.place_multitile_prop(room, cells, b_name, func(p, ppos):
				return prop_factory.create_bench_2tile(p, ppos, with_back, rot_y, b_name)
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
			if f_cells.is_empty(): f_cells.append(p_cell)
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
			if gt_cells.is_empty(): gt_cells.append(p_cell)
			var size = CastleLevelData.arr_to_vec3(data.get("size", [3.6, 1.1, 9.6]))
			return builder.place_multitile_prop(room, gt_cells, "GrandTable", func(p, ppos):
				return prop_factory.furniture.create_table(p, ppos, size, materials.mat_wood_dark)
			)
		"chimney":
			var ch_cells: Array[Vector2i] = []
			for c in data.get("cells", []): ch_cells.append(CastleLevelData.arr_to_vec2i(c))
			if ch_cells.is_empty(): ch_cells.append(p_cell)
			var ch_name = data.get("name", "Chimney")
			return builder.place_multitile_prop(room, ch_cells, ch_name, func(p, ppos):
				var ch = decors.create_chimney_fireplace(p, ppos, rot_y)
				ch.name = ch_name
				return ch
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
			var sk_name = data.get("name", "BleachedSkeleton")
			builder.place_blocking_prop(room, p_cell, sk_name, func(p, ppos):
				sk_node = graveyard_props.create_skeleton(p, ppos, rot_y, sk_name)
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
			return graveyard_props.create_cemetery_fence(room, pos, float(data.get("length", 10.0)), bool(data.get("is_z", false)), data.get("name", "CemeteryFence"))
		"iron_fence":
			return decors.create_iron_fence(room, pos, float(data.get("length", 10.0)), float(data.get("height", 1.3)), data.get("name", "CourtyardFence"))
		"stone_pillar":
			return graveyard_props.create_stone_pillar(room, pos, data.get("name", "StonePillar"))
		"bridge_rail":
			var rail = mesh_builder.create_wall_segment(room, p_cell, float(data.get("height", 1.8)))
			if data.has("name"): rail.name = data["name"]
			return rail
		_:
			return null

