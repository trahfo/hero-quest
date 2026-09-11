class_name CastleFurnitureFactory
extends RefCounted

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")
const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

var materials: CastleMaterials
var grid_to_world_fn: Callable

func _init(p_materials: CastleMaterials, p_grid_to_world: Callable) -> void:
	materials = p_materials
	grid_to_world_fn = p_grid_to_world

func _add_inspect(body: Node3D, prompt_text: String) -> void:
	var interact = HeroQuestInteractable.new()
	interact.name = "Interactable"
	interact.interact_type = HeroQuestInteractable.InteractType.INSPECT
	interact.custom_prompt = prompt_text
	body.add_child(interact)

func create_table(parent: Node3D, pos: Vector3, size: Vector3, custom_mat: Material = null) -> StaticBody3D:
	var mat = custom_mat if custom_mat else materials.mat_wood_dark
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var top = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(size.x, 0.12, size.z)
	t_mesh.material = mat
	top.mesh = t_mesh
	top.position = Vector3(0, size.y - 0.06, 0)
	body.add_child(top)

	var leg_w = 0.14
	var leg_h = size.y - 0.12
	var leg_x = size.x * 0.5 - 0.16
	var leg_z = size.z * 0.5 - 0.16
	for lx in [-leg_x, leg_x]:
		for lz in [-leg_z, leg_z]:
			var leg = MeshInstance3D.new()
			var l_mesh = BoxMesh.new()
			l_mesh.size = Vector3(leg_w, leg_h, leg_w)
			l_mesh.material = mat
			leg.mesh = l_mesh
			leg.position = Vector3(lx, leg_h * 0.5, lz)
			body.add_child(leg)

	_add_inspect(body, "Wooden Table")
	parent.add_child(body)
	return body

func create_bench(parent: Node3D, pos: Vector3, length: float, is_pew: bool = false, rot_y: float = 0.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var width = 0.7 if is_pew else 0.5
	var height = 0.9 if is_pew else 0.5

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(length, height, width)
	col.shape = shape
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)

	var seat = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(length, 0.1, width)
	s_mesh.material = materials.mat_wood_dark
	seat.mesh = s_mesh
	seat.position = Vector3(0, 0.45, 0)
	body.add_child(seat)

	# Legs and side support panels firmly grounded on the floor (y = 0.0 to 0.4)
	if is_pew:
		# Gothic pew end panels (legs + armrests extending up from floor to y = 0.85)
		for ex in [-length * 0.5 + 0.06, length * 0.5 - 0.06]:
			var end_panel = MeshInstance3D.new()
			var ep_mesh = BoxMesh.new()
			ep_mesh.size = Vector3(0.12, 0.85, width)
			ep_mesh.material = materials.mat_wood_dark
			end_panel.mesh = ep_mesh
			end_panel.position = Vector3(ex, 0.425, 0)
			body.add_child(end_panel)

		# Center support leg under seat
		if length > 2.0:
			var mid_leg = MeshInstance3D.new()
			var ml_mesh = BoxMesh.new()
			ml_mesh.size = Vector3(0.12, 0.4, width - 0.1)
			ml_mesh.material = materials.mat_wood_dark
			mid_leg.mesh = ml_mesh
			mid_leg.position = Vector3(0, 0.2, 0)
			body.add_child(mid_leg)

		var back = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(length - 0.24, 0.6, 0.1)
		b_mesh.material = materials.mat_wood_dark
		back.mesh = b_mesh
		# Backrest on South side (+Z) so sitting face is North (-Z) towards Altar
		back.position = Vector3(0, 0.7, width * 0.5 - 0.05)
		body.add_child(back)
		_add_inspect(body, "Chapel Pew")
	else:
		# Standard wooden bench legs
		var leg_positions = [-length * 0.5 + 0.15, length * 0.5 - 0.15]
		if length > 2.0:
			leg_positions.append(0.0)
		for lx in leg_positions:
			var leg = MeshInstance3D.new()
			var l_mesh = BoxMesh.new()
			l_mesh.size = Vector3(0.12, 0.4, width - 0.1)
			l_mesh.material = materials.mat_wood_dark
			leg.mesh = l_mesh
			leg.position = Vector3(lx, 0.2, 0)
			body.add_child(leg)
		_add_inspect(body, "Wooden Bench")

	parent.add_child(body)
	return body

func create_bench_2tile(parent: Node3D, pos: Vector3, is_pew: bool = true, rot_y: float = 0.0) -> StaticBody3D:
	return create_bench(parent, pos, 3.6, is_pew, rot_y)

func create_chair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.7, 1.1, 0.7)
	col.shape = shape
	col.position = Vector3(0, 0.55, 0)
	body.add_child(col)

	var seat = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.65, 0.08, 0.65)
	s_mesh.material = materials.mat_wood_dark
	seat.mesh = s_mesh
	seat.position = Vector3(0, 0.45, 0)
	body.add_child(seat)

	var back = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.65, 0.65, 0.08)
	b_mesh.material = materials.mat_wood_dark
	back.mesh = b_mesh
	back.position = Vector3(0, 0.78, 0.28)
	body.add_child(back)

	for lx in [-0.26, 0.26]:
		for lz in [-0.26, 0.26]:
			var leg = MeshInstance3D.new()
			var l_mesh = BoxMesh.new()
			l_mesh.size = Vector3(0.08, 0.45, 0.08)
			l_mesh.material = materials.mat_wood_dark
			leg.mesh = l_mesh
			leg.position = Vector3(lx, 0.225, lz)
			body.add_child(leg)

	_add_inspect(body, "Dining Chair")
	parent.add_child(body)
	return body

func create_cupboard(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var size = Vector3(1.8, 2.4, 0.8)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = size
	f_mesh.material = materials.mat_wood_dark
	frame.mesh = f_mesh
	frame.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(frame)

	_add_inspect(body, "Cupboard")
	parent.add_child(body)
	return body

func create_drawer(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var size = Vector3(1.6, 1.2, 0.8)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = size
	f_mesh.material = materials.mat_wood_light
	frame.mesh = f_mesh
	frame.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(frame)

	_add_inspect(body, "Wooden Drawer")
	parent.add_child(body)
	return body

func create_bookshelf(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var size = Vector3(1.8, 2.6, 0.6)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = size
	f_mesh.material = materials.mat_wood_dark
	frame.mesh = f_mesh
	frame.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(frame)

	_add_inspect(body, "Bookshelf")
	parent.add_child(body)
	return body

func create_arms_shelf(parent: Node3D, pos: Vector3, rot_y: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var size = Vector3(1.8, 1.8, 0.6)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(size.x, 0.1, size.z)
	f_mesh.material = materials.mat_wood_dark
	frame.mesh = f_mesh
	frame.position = Vector3(0, 0.5, 0)
	body.add_child(frame)

	for sx in [-0.5, 0.0, 0.5]:
		var blade = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(0.08, 1.5, 0.08)
		b_mesh.material = materials.mat_iron
		blade.mesh = b_mesh
		blade.position = Vector3(sx, 1.0, 0.05)
		body.add_child(blade)

	_add_inspect(body, "Arms Rack")
	parent.add_child(body)
	return body
