class_name LevelEditorCustomPropSpawner
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")
const CastleLevelPropSpawner = preload("res://scripts/hero_quest/level/castle_level_prop_spawner.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")

var builder: Node3D
var materials: CastleMaterials
var mesh_builder: CastleMeshBuilder
var prop_factory: CastlePropFactory
var decors: CastleDecorationFactory
var graveyard_props: CastleGraveyardPropFactory
var prop_spawner: CastleLevelPropSpawner

func _init(p_builder: Node3D, p_mat: CastleMaterials, p_mb: CastleMeshBuilder, p_pf: CastlePropFactory, p_dec: CastleDecorationFactory, p_gy: CastleGraveyardPropFactory, p_ps: CastleLevelPropSpawner) -> void:
	builder = p_builder
	materials = p_mat
	mesh_builder = p_mb
	prop_factory = p_pf
	decors = p_dec
	graveyard_props = p_gy
	prop_spawner = p_ps

func spawn(parent: Node3D, cell: Vector2i, p_info: Dictionary) -> Node3D:
	var p_type = p_info.get("type", "")
	var pos = builder.grid_to_world(cell)
	var rot_y = float(p_info.get("rot_y", 0.0))

	if p_type == "treasure_chest" or p_type == "chest":
		var relic = p_info.get("relic_name", "Gold Relic")
		var chest = prop_factory.create_treasure_chest(parent, pos + Vector3(0, 0.12, 0), rot_y, relic)
		chest.set_meta("gold", int(p_info.get("gold", 100)))
		chest.set_meta("is_trapped", bool(p_info.get("is_trapped", false)))
		chest.set_meta("relic_name", relic)
		builder.interactive_chests.append(chest)
		_register_blocking(cell, chest)
		return chest
	if p_info.get("is_arch", false) or p_type.begins_with("arch") or p_type == "door":
		return _spawn_arch(parent, cell, p_info)
	if p_type == "carpet":
		return prop_spawner.spawn_carpet(parent, {"pos": CastleLevelData.vec3_to_arr(pos + Vector3(0, 0.01, 0)), "size": [2.0, 0.02, 2.0], "mat": p_info.get("mat", "cloth_red")})
	if p_type == "fountain":
		var f = decors.create_fountain(parent, pos); f.rotation.y = rot_y; _register_blocking(cell, f); return f
	if p_type == "chimney":
		var c = decors.create_chimney_fireplace(parent, pos, rot_y); _register_blocking(cell, c); return c
	if p_type == "pillar":
		var p = mesh_builder.create_pillar(parent, pos, float(p_info.get("height", 4.5))); _register_blocking(cell, p); return p
	if p_type == "golden_cross":
		var cr = _create_altar_cross(parent, pos); cr.rotation.y = rot_y; _register_blocking(cell, cr); return cr
	if p_type == "pew":
		var pew = prop_factory.create_bench_2tile(parent, pos, p_info.get("with_back", true), rot_y); _register_blocking(cell, pew); return pew
	if p_type == "lower_wall":
		var w = mesh_builder.create_wall_segment(parent, cell, 1.8); w.rotation.y = rot_y; _register_blocking(cell, w); return w
	if p_type == "stone_pillar":
		var sp = graveyard_props.create_stone_pillar(parent, pos, "StonePillar"); sp.rotation.y = rot_y; _register_blocking(cell, sp); return sp
	if p_type == "brazier":
		var bz = prop_factory.create_brazier(parent, pos); bz.rotation.y = rot_y; _register_blocking(cell, bz); return bz
	if p_type == "torch":
		var norm = CastleLevelData.arr_to_vec3(p_info.get("norm", [0, 0, 1]))
		return prop_factory.create_torch(parent, pos + norm * 0.46 + Vector3(0, 2.2, 0), norm)
	if p_type == "painting":
		var norm = CastleLevelData.arr_to_vec3(p_info.get("norm", [0, 0, 1]))
		return decors.create_painting(parent, pos + norm * 0.46 + Vector3(0, 2.0, 0), norm, int(p_info.get("index", 0)))
	if p_type == "gravestone":
		var g = graveyard_props.create_gravestone(parent, pos, rot_y, p_info.get("epitaph", "Rest in Peace"), int(p_info.get("style", 0))); _register_blocking(cell, g); return g
	if p_type == "skeleton":
		var s = graveyard_props.create_skeleton(parent, pos, rot_y); _register_blocking(cell, s); return s
	if p_type == "ancient_tree":
		var t = graveyard_props.create_cemetery_tree(parent, pos); t.rotation.y = rot_y; _register_blocking(cell, t); return t
	if p_type == "torch_on_stick":
		var ts = graveyard_props.create_torch_on_stick(parent, pos); ts.rotation.y = rot_y; return ts
	if p_type == "cemetery_fence":
		var is_z = absf(rot_y - PI * 0.5) < 0.2 or absf(rot_y - PI * 1.5) < 0.2
		var cf = graveyard_props.create_cemetery_fence(parent, pos, 2.0, is_z); cf.rotation.y = rot_y; return cf
	if p_type == "iron_fence":
		var ifc = decors.create_iron_fence(parent, pos, 2.0); ifc.rotation.y = rot_y; return ifc

	p_info["pos"] = CastleLevelData.vec3_to_arr(pos)
	p_info["cell"] = CastleLevelData.vec2i_to_arr(cell)
	var spawned = prop_spawner.spawn_prop(parent, p_info, builder)
	if spawned and is_instance_valid(spawned) and not (p_type in ["torch", "painting"]):
		spawned.rotation.y = rot_y
	return spawned

func _register_blocking(cell: Vector2i, node: Node3D) -> void:
	if not builder.grid.has(cell):
		builder.register_tile(cell, 1, false, "Custom")
	else:
		builder.grid[cell]["walkable"] = false
	builder.grid[cell]["prop"] = node

func _spawn_arch(parent: Node3D, cell: Vector2i, a_info: Dictionary) -> Node3D:
	var a_name = a_info.get("name", "CustomArch")
	var axis = int(a_info.get("axis", 0))
	var a_type = a_info.get("arch_type", a_info.get("type", "arch_3tile"))
	var arch_node = Node3D.new()
	arch_node.name = a_name
	parent.add_child(arch_node)

	if not builder.grid.has(cell):
		builder.register_tile(cell, 1, true, "Portal")
	else:
		builder.grid[cell]["walkable"] = true
		builder.grid[cell]["type"] = 1

	var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	if a_type == "arch_spanning_3tiles":
		mesh_builder.build_arch_spanning_3tiles(arch_node, cell, axis, a_name)
		builder.register_tile(cell - off * 2, 6, false, "Arch Pier")
		builder.register_tile(cell + off * 2, 6, false, "Arch Pier")
	elif a_type == "arch_5tile_twin":
		mesh_builder.build_arch_5tile_twin(arch_node, cell, axis, a_name)
		builder.register_tile(cell - off * 2, 6, false, "Arch Pier")
		builder.register_tile(cell, 6, false, "Arch Pier")
		builder.register_tile(cell + off * 2, 6, false, "Arch Pier")
	else:
		mesh_builder.build_arch_3tile(arch_node, cell, axis, a_name)
		builder.register_tile(cell - off, 6, false, "Arch Pier")
		builder.register_tile(cell + off, 6, false, "Arch Pier")

	builder.grid[cell]["prop"] = arch_node
	return arch_node

func _create_altar_cross(parent: Node3D, pos: Vector3) -> Node3D:
	var root = Node3D.new(); root.position = pos; parent.add_child(root)
	var p1 = MeshInstance3D.new(); var b1 = BoxMesh.new(); b1.size = Vector3(0.2, 1.4, 0.2); b1.material = materials.mat_gold; p1.mesh = b1; p1.position = Vector3(0, 0.7, 0); root.add_child(p1)
	var p2 = MeshInstance3D.new(); var b2 = BoxMesh.new(); b2.size = Vector3(0.8, 0.2, 0.2); b2.material = materials.mat_gold; p2.mesh = b2; p2.position = Vector3(0, 1.0, 0); root.add_child(p2)
	return root
