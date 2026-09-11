class_name CastleDecorationFactory
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

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

func create_fountain(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.6
	shape.height = 1.2
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	body.add_child(col)

	# Outer basin rim
	var basin = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 1.6
	b_mesh.bottom_radius = 1.7
	b_mesh.height = 0.7
	b_mesh.material = materials.mat_wall_trim
	basin.mesh = b_mesh
	basin.position = Vector3(0, 0.35, 0)
	body.add_child(basin)

	# Water disk
	var water = MeshInstance3D.new()
	var w_mesh = CylinderMesh.new()
	w_mesh.top_radius = 1.45
	w_mesh.bottom_radius = 1.45
	w_mesh.height = 0.05
	w_mesh.material = materials.mat_fountain_water
	water.mesh = w_mesh
	water.position = Vector3(0, 0.62, 0)
	body.add_child(water)

	# Center pedestal
	var ped = MeshInstance3D.new()
	var p_mesh = CylinderMesh.new()
	p_mesh.top_radius = 0.35
	p_mesh.bottom_radius = 0.5
	p_mesh.height = 1.5
	p_mesh.material = materials.mat_wall_trim
	ped.mesh = p_mesh
	ped.position = Vector3(0, 1.0, 0)
	body.add_child(ped)

	# Upper tier bowl
	var bowl = MeshInstance3D.new()
	var bw_mesh = CylinderMesh.new()
	bw_mesh.top_radius = 0.8
	bw_mesh.bottom_radius = 0.4
	bw_mesh.height = 0.35
	bw_mesh.material = materials.mat_wall_trim
	bowl.mesh = bw_mesh
	bowl.position = Vector3(0, 1.7, 0)
	body.add_child(bowl)

	# Water plume
	var plume = MeshInstance3D.new()
	var pl_mesh = SphereMesh.new()
	pl_mesh.radius = 0.22
	pl_mesh.height = 0.5
	pl_mesh.material = materials.mat_fountain_water
	plume.mesh = pl_mesh
	plume.position = Vector3(0, 2.05, 0)
	body.add_child(plume)

	# Fountain glow light
	var light = OmniLight3D.new()
	light.light_color = Color(0.4, 0.75, 0.95)
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position = Vector3(0, 1.8, 0)
	body.add_child(light)

	_add_inspect(body, "Stone Fountain")
	parent.add_child(body)
	return body

func create_bush(parent: Node3D, pos: Vector3, scale_factor: float = 1.0) -> Node3D:
	var bush = Node3D.new()
	bush.position = pos

	var offsets = [
		Vector3(0, 0.4, 0),
		Vector3(-0.25, 0.35, 0.2),
		Vector3(0.25, 0.38, -0.15),
		Vector3(0.1, 0.55, 0.1)
	]
	var radii = [0.45, 0.38, 0.40, 0.32]

	for i in range(offsets.size()):
		var leaf = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = radii[i] * scale_factor
		s_mesh.height = radii[i] * 1.8 * scale_factor
		s_mesh.material = materials.mat_plant_leaf
		leaf.mesh = s_mesh
		leaf.position = offsets[i] * scale_factor
		bush.add_child(leaf)

	parent.add_child(bush)
	return bush

func create_flower_patch(parent: Node3D, pos: Vector3) -> Node3D:
	var patch = Node3D.new()
	patch.position = pos

	var mats = [materials.mat_flower_red, materials.mat_flower_yellow, materials.mat_flower_purple]
	for i in range(5):
		var a = float(i) * 1.25
		var r = randf_range(0.2, 0.5)
		var fx = cos(a) * r
		var fz = sin(a) * r

		var stem = MeshInstance3D.new()
		var st_mesh = CylinderMesh.new()
		st_mesh.top_radius = 0.02
		st_mesh.bottom_radius = 0.03
		st_mesh.height = 0.35
		st_mesh.material = materials.mat_plant_leaf
		stem.mesh = st_mesh
		stem.position = Vector3(fx, 0.175, fz)
		patch.add_child(stem)

		var head = MeshInstance3D.new()
		var h_mesh = SphereMesh.new()
		h_mesh.radius = 0.1
		h_mesh.height = 0.12
		h_mesh.material = mats[i % mats.size()]
		head.mesh = h_mesh
		head.position = Vector3(fx, 0.38, fz)
		patch.add_child(head)

	parent.add_child(patch)
	return patch

func create_chimney_fireplace(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.2, 5.0, 1.6)
	col.shape = shape
	col.position = Vector3(0, 2.5, 0)
	body.add_child(col)

	var breast = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(3.2, 5.5, 1.5)
	b_mesh.material = materials.mat_wall_stone
	breast.mesh = b_mesh
	breast.position = Vector3(0, 2.75, 0)
	body.add_child(breast)

	var mantle = MeshInstance3D.new()
	var m_mesh = BoxMesh.new()
	m_mesh.size = Vector3(3.5, 0.35, 1.8)
	m_mesh.material = materials.mat_wall_trim
	mantle.mesh = m_mesh
	mantle.position = Vector3(0, 2.1, 0.1)
	body.add_child(mantle)

	var cavity = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(1.8, 1.5, 0.9)
	var cav_mat = StandardMaterial3D.new()
	cav_mat.albedo_color = Color(0.06, 0.06, 0.07)
	cavity.mesh = c_mesh
	cavity.material_override = cav_mat
	cavity.position = Vector3(0, 0.85, 0.4)
	body.add_child(cavity)

	for lx in [-0.4, 0.0, 0.4]:
		var log = MeshInstance3D.new()
		var l_mesh = CylinderMesh.new()
		l_mesh.top_radius = 0.12
		l_mesh.bottom_radius = 0.12
		l_mesh.height = 0.9
		l_mesh.material = materials.mat_wood_dark
		log.mesh = l_mesh
		log.rotation.z = PI * 0.5
		log.position = Vector3(lx * 0.7, 0.25, 0.4)
		body.add_child(log)

	var flame_group = Node3D.new()
	flame_group.name = "AnimatedFlames"
	flame_group.position = Vector3(0, 0.45, 0.4)
	body.add_child(flame_group)

	for fx in [-0.3, 0.0, 0.3]:
		var flame = MeshInstance3D.new()
		var f_mesh = PrismMesh.new()
		f_mesh.size = Vector3(0.35, 0.75, 0.25)
		f_mesh.material = materials.mat_fire_flame
		flame.mesh = f_mesh
		flame.position = Vector3(fx, 0.3, 0)
		flame_group.add_child(flame)

	var fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.45, 0.1)
	fire_light.light_energy = 3.5
	fire_light.omni_range = 14.0
	fire_light.shadow_enabled = true
	fire_light.position = Vector3(0, 1.0, 0.8)
	body.add_child(fire_light)

	var flicker_timer = Timer.new()
	flicker_timer.wait_time = 0.06
	flicker_timer.autostart = true
	flicker_timer.timeout.connect(func():
		fire_light.light_energy = 3.5 + randf_range(-0.7, 0.7)
		var s = randf_range(0.85, 1.2)
		flame_group.scale = Vector3(s, randf_range(0.8, 1.3), s)
	)
	body.add_child(flicker_timer)

	_add_inspect(body, "Castle Chimney Fireplace")
	parent.add_child(body)
	return body

func create_painting(parent: Node3D, pos: Vector3, wall_normal: Vector3, style_idx: int = 0) -> Node3D:
	var painting = Node3D.new()
	painting.position = pos
	var angle = atan2(wall_normal.x, wall_normal.z)
	painting.rotation.y = angle

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(1.8, 1.4, 0.1)
	f_mesh.material = materials.mat_frame_gold
	frame.mesh = f_mesh
	painting.add_child(frame)

	var canvas = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(1.5, 1.1, 0.08)
	var art_mat = StandardMaterial3D.new()
	if style_idx % 3 == 0:
		art_mat.albedo_color = Color(0.2, 0.35, 0.5)
	elif style_idx % 3 == 1:
		art_mat.albedo_color = Color(0.5, 0.2, 0.2)
	else:
		art_mat.albedo_color = Color(0.35, 0.45, 0.25)
	canvas.mesh = c_mesh
	canvas.material_override = art_mat
	canvas.position = Vector3(0, 0, 0.04)
	painting.add_child(canvas)

	var interact = HeroQuestInteractable.new()
	interact.name = "Interactable"
	interact.interact_type = HeroQuestInteractable.InteractType.INSPECT
	interact.custom_prompt = "Framed Castle Painting"
	painting.add_child(interact)

	parent.add_child(painting)
	return painting

func create_iron_fence(parent: Node3D, pos: Vector3, length: float, height: float = 1.3, fence_name: String = "CourtyardFence") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = fence_name
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(length, height, 0.35)
	col.shape = shape
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)

	# Stone base curb
	var curb = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(length, 0.25, 0.35)
	c_mesh.material = materials.mat_wall_stone
	curb.mesh = c_mesh
	curb.position = Vector3(0, 0.125, 0)
	body.add_child(curb)

	# Stone end posts
	for px in [-length * 0.5 + 0.15, length * 0.5 - 0.15]:
		var post = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(0.3, height + 0.1, 0.35)
		p_mesh.material = materials.mat_wall_trim
		post.mesh = p_mesh
		post.position = Vector3(px, (height + 0.1) * 0.5, 0)
		body.add_child(post)

	# Top handrail
	var top_rail = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(length, 0.1, 0.2)
	tr_mesh.material = materials.mat_wall_trim
	top_rail.mesh = tr_mesh
	top_rail.position = Vector3(0, height - 0.05, 0)
	body.add_child(top_rail)

	# Bottom iron rail
	var bot_rail = MeshInstance3D.new()
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(length - 0.3, 0.06, 0.08)
	br_mesh.material = materials.mat_iron
	bot_rail.mesh = br_mesh
	bot_rail.position = Vector3(0, 0.35, 0)
	body.add_child(bot_rail)

	# Vertical iron pickets spaced every 0.3m
	var num_pickets = int((length - 0.6) / 0.3)
	var picket_h = height - 0.45
	for i in range(num_pickets + 1):
		var picket_x = - (length - 0.6) * 0.5 + i * 0.3
		var picket = MeshInstance3D.new()
		var pk_mesh = BoxMesh.new()
		pk_mesh.size = Vector3(0.06, picket_h, 0.06)
		pk_mesh.material = materials.mat_iron
		picket.mesh = pk_mesh
		picket.position = Vector3(picket_x, 0.35 + picket_h * 0.5, 0)
		body.add_child(picket)

	_add_inspect(body, "Courtyard Balustrade")
	body.set_meta("is_fence", true)
	parent.add_child(body, true)
	return body
