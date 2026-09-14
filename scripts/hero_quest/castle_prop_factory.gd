class_name CastlePropFactory
extends RefCounted

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")
const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastleFurnitureFactory = preload("res://scripts/hero_quest/castle_furniture_factory.gd")

var materials: CastleMaterials
var grid_to_world_fn: Callable
var furniture: CastleFurnitureFactory

func _init(p_materials: CastleMaterials, p_grid_to_world: Callable) -> void:
	materials = p_materials
	grid_to_world_fn = p_grid_to_world
	furniture = CastleFurnitureFactory.new(materials, grid_to_world_fn)

# ---------------------------------------------------------
# LIGHTING PROPS
# ---------------------------------------------------------

func create_torch(parent: Node3D, pos: Vector3, wall_normal: Vector3) -> Node3D:
	var torch = Node3D.new()
	torch.position = pos

	var bracket = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.12, 0.12, 0.45)
	b_mesh.material = materials.mat_iron
	bracket.mesh = b_mesh
	bracket.rotation.y = atan2(wall_normal.x, wall_normal.z)
	bracket.position = wall_normal * 0.2
	torch.add_child(bracket)

	var cup = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.16
	c_mesh.bottom_radius = 0.08
	c_mesh.height = 0.3
	c_mesh.material = materials.mat_iron
	cup.mesh = c_mesh
	cup.position = wall_normal * 0.35 + Vector3(0, 0.15, 0)
	torch.add_child(cup)

	var flame = MeshInstance3D.new()
	var f_mesh = SphereMesh.new()
	f_mesh.radius = 0.15
	f_mesh.height = 0.3
	f_mesh.material = materials.mat_torch_glow
	flame.mesh = f_mesh
	flame.position = cup.position + Vector3(0, 0.22, 0)
	torch.add_child(flame)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.22)
	light.light_energy = 1.8
	light.omni_range = 9.0
	light.shadow_enabled = true
	light.position = flame.position
	torch.add_child(light)

	var timer = Timer.new()
	timer.wait_time = 0.08
	timer.autostart = true
	timer.timeout.connect(func():
		light.light_energy = 1.8 + randf_range(-0.35, 0.35)
	)
	torch.add_child(timer)

	parent.add_child(torch)
	return torch

func create_brazier(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = 1.2
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	body.add_child(col)

	var basin = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.7
	c_mesh.bottom_radius = 0.3
	c_mesh.height = 0.8
	c_mesh.material = materials.mat_iron
	basin.mesh = c_mesh
	basin.position = Vector3(0, 0.6, 0)
	body.add_child(basin)

	var coals = MeshInstance3D.new()
	var coal_mesh = SphereMesh.new()
	coal_mesh.radius = 0.55
	coal_mesh.height = 0.4
	coal_mesh.material = materials.mat_ember
	coals.mesh = coal_mesh
	coals.position = Vector3(0, 0.95, 0)
	body.add_child(coals)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.45, 0.12)
	light.light_energy = 3.0
	light.omni_range = 10.0
	light.position = Vector3(0, 1.2, 0)
	body.add_child(light)

	var timer = Timer.new()
	timer.wait_time = 0.07
	timer.autostart = true
	timer.timeout.connect(func():
		light.light_energy = 3.0 + randf_range(-0.5, 0.5)
	)
	body.add_child(timer)

	parent.add_child(body)
	return body

func create_candelabra(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position = Vector3(0, 0.9, 0)
	body.add_child(col)

	var stand = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.08
	s_mesh.bottom_radius = 0.3
	s_mesh.height = 1.6
	s_mesh.material = materials.mat_gold
	stand.mesh = s_mesh
	stand.position = Vector3(0, 0.8, 0)
	body.add_child(stand)

	var flame = MeshInstance3D.new()
	var f_mesh = SphereMesh.new()
	f_mesh.radius = 0.1
	f_mesh.height = 0.2
	f_mesh.material = materials.mat_torch_glow
	flame.mesh = f_mesh
	flame.position = Vector3(0, 1.7, 0)
	body.add_child(flame)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.position = Vector3(0, 1.8, 0)
	body.add_child(light)

	parent.add_child(body)
	return body

# ---------------------------------------------------------
# FURNITURE (DELEGATED TO CastleFurnitureFactory)
# ---------------------------------------------------------

func create_table(parent: Node3D, pos: Vector3, size: Vector3, custom_mat: Material = null) -> StaticBody3D: return furniture.create_table(parent, pos, size, custom_mat)
func create_bench(parent: Node3D, pos: Vector3, length: float, is_pew: bool = false, rot_y: float = 0.0, bench_name: String = "") -> StaticBody3D: return furniture.create_bench(parent, pos, length, is_pew, rot_y, bench_name)
func create_bench_2tile(parent: Node3D, pos: Vector3, is_pew: bool = true, rot_y: float = 0.0, bench_name: String = "") -> StaticBody3D: return furniture.create_bench_2tile(parent, pos, is_pew, rot_y, bench_name)
func create_chair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D: return furniture.create_chair(parent, pos, rot_y)
func create_cupboard(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D: return furniture.create_cupboard(parent, pos, rot_y)
func create_drawer(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D: return furniture.create_drawer(parent, pos, rot_y)
func create_bookshelf(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D: return furniture.create_bookshelf(parent, pos, rot_y)
func create_arms_shelf(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D: return furniture.create_arms_shelf(parent, pos, rot_y)

# ---------------------------------------------------------
# INTERACTIVE WORLD ENTITIES & BLOCKERS
# ---------------------------------------------------------

func create_treasure_chest(parent: Node3D, pos: Vector3, rot_y: float, loot_name: String, mini_game_id: String = "") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	body.set_meta("is_chest", true)
	body.set_meta("loot_name", loot_name)
	body.set_meta("is_opened", false)
	if mini_game_id != "":
		body.set_meta("mini_game_id", mini_game_id)

	var size = Vector3(1.2, 0.9, 0.8)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(size.x, 0.5, size.z)
	b_mesh.material = materials.mat_wood_dark
	base.mesh = b_mesh
	base.position = Vector3(0, 0.25, 0)
	body.add_child(base)

	var lid = Node3D.new()
	lid.name = "ChestLid"
	lid.position = Vector3(0, 0.5, -size.z * 0.5)
	body.add_child(lid)

	var lid_mesh = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(size.x, 0.35, size.z)
	l_box.material = materials.mat_wood_dark
	lid_mesh.mesh = l_box
	lid_mesh.position = Vector3(0, 0.175, size.z * 0.5)
	lid.add_child(lid_mesh)

	var lock = MeshInstance3D.new()
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(0.18, 0.2, 0.08)
	k_mesh.material = materials.mat_gold
	lock.mesh = k_mesh
	lock.position = Vector3(0, 0.45, size.z * 0.5 + 0.04)
	body.add_child(lock)

	var interactable = HeroQuestInteractable.new()
	interactable.name = "Interactable"
	interactable.interact_type = HeroQuestInteractable.InteractType.CHEST
	interactable.loot_name = loot_name
	if mini_game_id != "":
		interactable.mini_game_id = mini_game_id
	body.add_child(interactable)

	parent.add_child(body)
	return body

func create_anvil(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.4, 1.1, 0.7)
	col.shape = shape
	col.position = Vector3(0, 0.55, 0)
	body.add_child(col)

	var stump = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.5
	s_mesh.bottom_radius = 0.55
	s_mesh.height = 0.6
	s_mesh.material = materials.mat_wood_dark
	stump.mesh = s_mesh
	stump.position = Vector3(0, 0.3, 0)
	body.add_child(stump)

	var iron_top = MeshInstance3D.new()
	var i_mesh = BoxMesh.new()
	i_mesh.size = Vector3(1.3, 0.4, 0.6)
	i_mesh.material = materials.mat_iron
	iron_top.mesh = i_mesh
	iron_top.position = Vector3(0, 0.8, 0)
	body.add_child(iron_top)

	var interactable = HeroQuestInteractable.new()
	interactable.name = "Interactable"
	interactable.interact_type = HeroQuestInteractable.InteractType.ANVIL
	body.add_child(interactable)

	parent.add_child(body)
	return body

func create_water_trough(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 0.7, 0.8)
	col.shape = shape
	col.position = Vector3(0, 0.35, 0)
	body.add_child(col)

	var trough = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(1.5, 0.65, 0.8)
	t_mesh.material = materials.mat_wood_dark
	trough.mesh = t_mesh
	trough.position = Vector3(0, 0.325, 0)
	body.add_child(trough)

	var water = MeshInstance3D.new()
	var w_mesh = BoxMesh.new()
	w_mesh.size = Vector3(1.3, 0.05, 0.65)
	w_mesh.material = materials.mat_water_chasm
	water.mesh = w_mesh
	water.position = Vector3(0, 0.55, 0)
	body.add_child(water)

	parent.add_child(body)
	return body

func create_grindstone(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.0, 0.8)
	col.shape = shape
	col.position = Vector3(0, 0.5, 0)
	body.add_child(col)

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(1.1, 0.6, 0.7)
	f_mesh.material = materials.mat_wood_dark
	frame.mesh = f_mesh
	frame.position = Vector3(0, 0.3, 0)
	body.add_child(frame)

	var wheel = MeshInstance3D.new()
	var w_mesh = CylinderMesh.new()
	w_mesh.top_radius = 0.45
	w_mesh.bottom_radius = 0.45
	w_mesh.height = 0.22
	w_mesh.material = materials.mat_wall_stone
	wheel.mesh = w_mesh
	wheel.rotation.x = PI * 0.5
	wheel.position = Vector3(0, 0.75, 0)
	body.add_child(wheel)

	parent.add_child(body)
	return body

func create_hay_bale(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var size = Vector3(1.4, 0.9, 1.1)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = size
	b_mesh.material = materials.mat_hay
	mesh_inst.mesh = b_mesh
	mesh_inst.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body

func create_box_prop(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, has_collision: bool = true) -> Node3D:
	if has_collision:
		var body = StaticBody3D.new()
		body.position = pos

		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = size
		b_mesh.material = mat
		mesh_inst.mesh = b_mesh
		body.add_child(mesh_inst)

		parent.add_child(body)
		return body
	else:
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.position = pos
		var b_mesh = BoxMesh.new()
		b_mesh.size = size
		b_mesh.material = mat
		mesh_inst.mesh = b_mesh
		parent.add_child(mesh_inst)
		return mesh_inst
