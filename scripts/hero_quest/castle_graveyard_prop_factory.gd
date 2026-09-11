class_name CastleGraveyardPropFactory
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

var materials: CastleMaterials

func _init(p_materials: CastleMaterials) -> void:
	materials = p_materials

func _add_inspect(body: Node3D, prompt_text: String) -> void:
	var interact = HeroQuestInteractable.new()
	interact.name = "Interactable"
	interact.interact_type = HeroQuestInteractable.InteractType.INSPECT
	interact.custom_prompt = prompt_text
	body.add_child(interact)

func create_gravestone(parent: Node3D, pos: Vector3, rot_y: float = 0.0, epitaph: String = "Rest in Peace", style: int = 0, g_name: String = "Gravestone") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = g_name
	body.set_meta("is_gravestone", true)
	body.position = pos
	body.rotation.y = rot_y

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.4, 0.8)
	col.shape = shape
	col.position = Vector3(0, 0.7, 0)
	body.add_child(col)

	# Raised grave dirt mound
	var mound = MeshInstance3D.new()
	var m_mesh = BoxMesh.new()
	m_mesh.size = Vector3(1.1, 0.12, 1.2)
	m_mesh.material = materials.mat_floor_graveyard_dirt
	mound.mesh = m_mesh
	mound.position = Vector3(0, 0.06, 0.4)
	body.add_child(mound)

	# Base plinth
	var plinth = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.9, 0.22, 0.35)
	p_mesh.material = materials.mat_gravestone
	plinth.mesh = p_mesh
	plinth.position = Vector3(0, 0.11, 0)
	body.add_child(plinth)

	var stone = MeshInstance3D.new()
	stone.position = Vector3(0, 0.65, 0)
	if style == 3:
		# Weathered tilt
		stone.rotation.z = 0.08
		stone.rotation.x = -0.05

	if style == 1:
		# Celtic Stone Cross
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(0.24, 1.05, 0.18)
		c_mesh.material = materials.mat_gravestone
		stone.mesh = c_mesh
		var bar = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(0.68, 0.22, 0.18)
		b_mesh.material = materials.mat_gravestone
		bar.mesh = b_mesh
		bar.position = Vector3(0, 0.22, 0)
		stone.add_child(bar)
	elif style == 2:
		# Pointed Gothic Stele
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.7, 0.75, 0.2)
		s_mesh.material = materials.mat_gravestone
		stone.mesh = s_mesh
		var peak = MeshInstance3D.new()
		var pk_mesh = PrismMesh.new()
		pk_mesh.size = Vector3(0.7, 0.35, 0.2)
		pk_mesh.material = materials.mat_gravestone
		peak.mesh = pk_mesh
		peak.position = Vector3(0, 0.55, 0)
		stone.add_child(peak)
	else:
		# Classic Arched Headstone (Style 0 & 3)
		var h_mesh = BoxMesh.new()
		h_mesh.size = Vector3(0.75, 0.85, 0.2)
		h_mesh.material = materials.mat_gravestone
		stone.mesh = h_mesh
		var top = MeshInstance3D.new()
		var t_mesh = CylinderMesh.new()
		t_mesh.top_radius = 0.375
		t_mesh.bottom_radius = 0.375
		t_mesh.height = 0.2
		t_mesh.material = materials.mat_gravestone
		top.mesh = t_mesh
		top.rotation.x = PI * 0.5
		top.position = Vector3(0, 0.425, 0)
		stone.add_child(top)

	body.add_child(stone)
	_add_inspect(body, epitaph)
	parent.add_child(body)
	return body

func create_skeleton(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "BleachedSkeleton"
	body.position = pos
	body.rotation.y = rot_y

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 0.6, 1.2)
	col.shape = shape
	col.position = Vector3(0, 0.3, 0)
	body.add_child(col)

	# Cranium / Skull
	var skull = MeshInstance3D.new()
	var sk_mesh = SphereMesh.new()
	sk_mesh.radius = 0.16
	sk_mesh.height = 0.3
	sk_mesh.material = materials.mat_bone
	skull.mesh = sk_mesh
	skull.position = Vector3(0, 0.16, -0.4)
	body.add_child(skull)

	# Ribcage and Spine
	var ribs = MeshInstance3D.new()
	var rb_mesh = BoxMesh.new()
	rb_mesh.size = Vector3(0.38, 0.22, 0.45)
	rb_mesh.material = materials.mat_bone
	ribs.mesh = rb_mesh
	ribs.position = Vector3(0, 0.12, -0.05)
	body.add_child(ribs)

	# Pelvis
	var pelvis = MeshInstance3D.new()
	var pv_mesh = BoxMesh.new()
	pv_mesh.size = Vector3(0.34, 0.14, 0.2)
	pv_mesh.material = materials.mat_bone
	pelvis.mesh = pv_mesh
	pelvis.position = Vector3(0, 0.08, 0.24)
	body.add_child(pelvis)

	# Crossed leg bones
	for dx in [-0.14, 0.14]:
		var leg = MeshInstance3D.new()
		var l_mesh = CylinderMesh.new()
		l_mesh.top_radius = 0.04
		l_mesh.bottom_radius = 0.04
		l_mesh.height = 0.55
		l_mesh.material = materials.mat_bone
		leg.mesh = l_mesh
		leg.rotation.x = PI * 0.48
		leg.rotation.z = -dx * 0.5
		leg.position = Vector3(dx, 0.06, 0.55)
		body.add_child(leg)

	# Rusted sword resting beside skeleton
	var sword = MeshInstance3D.new()
	var sw_mesh = BoxMesh.new()
	sw_mesh.size = Vector3(0.08, 0.04, 0.9)
	sw_mesh.material = materials.mat_iron
	sword.mesh = sw_mesh
	sword.position = Vector3(0.32, 0.04, 0.0)
	sword.rotation.y = 0.2
	body.add_child(sword)

	_add_inspect(body, "Bleached Skeleton: Ancient remains of a warrior clutching a rusted blade.")
	parent.add_child(body)
	return body

func create_cemetery_tree(parent: Node3D, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "AncientTree"
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 3.5
	col.shape = shape
	col.position = Vector3(0, 1.75, 0)
	body.add_child(col)

	# Gnarled trunk
	var trunk = MeshInstance3D.new()
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.45
	t_mesh.bottom_radius = 0.75
	t_mesh.height = 3.2
	t_mesh.material = materials.mat_wood_dark
	trunk.mesh = t_mesh
	trunk.position = Vector3(0, 1.6, 0)
	body.add_child(trunk)

	# Spreading root flares
	for rot in [0.0, 1.3, 2.6, 3.9, 5.2]:
		var root = MeshInstance3D.new()
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(0.28, 0.32, 0.95)
		r_mesh.material = materials.mat_wood_dark
		root.mesh = r_mesh
		root.rotation.y = rot
		root.position = Vector3(sin(rot) * 0.55, 0.16, cos(rot) * 0.55)
		body.add_child(root)

	# Heavy twisted boughs
	var branch_angles = [0.2, 1.5, 2.9, 4.4]
	for i in range(branch_angles.size()):
		var angle = branch_angles[i]
		var branch = MeshInstance3D.new()
		var b_mesh = CylinderMesh.new()
		b_mesh.top_radius = 0.16
		b_mesh.bottom_radius = 0.28
		b_mesh.height = 2.4
		b_mesh.material = materials.mat_wood_dark
		branch.mesh = b_mesh
		branch.position = Vector3(sin(angle) * 0.9, 3.1, cos(angle) * 0.9)
		branch.rotation.z = 0.6 if i % 2 == 0 else -0.6
		branch.rotation.y = angle
		body.add_child(branch)

	# Dark eerie foliage clusters
	for f_pos in [Vector3(0, 4.2, 0), Vector3(1.2, 3.8, 0.8), Vector3(-1.1, 3.9, -0.6)]:
		var leaf = MeshInstance3D.new()
		var lf_mesh = SphereMesh.new()
		lf_mesh.radius = 0.95
		lf_mesh.height = 1.3
		lf_mesh.material = materials.mat_floor_garden_green
		leaf.mesh = lf_mesh
		leaf.position = f_pos
		body.add_child(leaf)

	_add_inspect(body, "Ancient Cemetery Tree: Its gnarled boughs twist over the silent graves.")
	parent.add_child(body)
	return body

func create_torch_on_stick(parent: Node3D, pos: Vector3, t_name: String = "TorchOnStick") -> Node3D:
	var torch = Node3D.new()
	torch.name = t_name
	torch.set_meta("is_torch_on_stick", true)
	torch.position = pos

	# Wooden stake
	var stake = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.05
	s_mesh.bottom_radius = 0.07
	s_mesh.height = 1.8
	s_mesh.material = materials.mat_wood_dark
	stake.mesh = s_mesh
	stake.position = Vector3(0, 0.9, 0)
	torch.add_child(stake)

	# Iron cradle
	var iron_cup = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.16
	c_mesh.bottom_radius = 0.08
	c_mesh.height = 0.22
	c_mesh.material = materials.mat_iron
	iron_cup.mesh = c_mesh
	iron_cup.position = Vector3(0, 1.82, 0)
	torch.add_child(iron_cup)

	# Flame
	var flame = MeshInstance3D.new()
	var f_mesh = SphereMesh.new()
	f_mesh.radius = 0.14
	f_mesh.height = 0.28
	f_mesh.material = materials.mat_torch_glow
	flame.mesh = f_mesh
	flame.position = Vector3(0, 2.0, 0)
	torch.add_child(flame)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.22)
	light.light_energy = 1.8
	light.omni_range = 8.5
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

func create_cemetery_fence(parent: Node3D, pos: Vector3, length: float, is_z_axis: bool = false, fence_name: String = "CemeteryFence") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = fence_name
	body.position = pos

	var height: float = 1.3
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, height, length) if is_z_axis else Vector3(length, height, 0.3)
	col.shape = shape
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)

	# Horizontal rails
	for ry in [0.35, 1.05]:
		var rail = MeshInstance3D.new()
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(0.08, 0.06, length) if is_z_axis else Vector3(length, 0.06, 0.08)
		r_mesh.material = materials.mat_iron
		rail.mesh = r_mesh
		rail.position = Vector3(0, ry, 0)
		body.add_child(rail)

	# Spiked pickets spaced every 0.6m
	var picket_count = maxi(2, int(length / 0.6))
	var step = length / float(picket_count)
	var start_offset = -length * 0.5 + step * 0.5
	for i in range(picket_count):
		var offset = start_offset + i * step
		var picket = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.03
		p_mesh.bottom_radius = 0.03
		p_mesh.height = 1.2
		p_mesh.material = materials.mat_iron
		picket.mesh = p_mesh
		picket.position = Vector3(0, 0.6, offset) if is_z_axis else Vector3(offset, 0.6, 0)
		body.add_child(picket)

		# Spearhead tip
		var spear = MeshInstance3D.new()
		var sp_mesh = PrismMesh.new()
		sp_mesh.size = Vector3(0.08, 0.18, 0.04) if is_z_axis else Vector3(0.04, 0.18, 0.08)
		sp_mesh.material = materials.mat_iron
		spear.mesh = sp_mesh
		spear.position = picket.position + Vector3(0, 0.65, 0)
		body.add_child(spear)

	parent.add_child(body)
	return body

func create_stone_pillar(parent: Node3D, pos: Vector3, pillar_name: String = "CemeteryPillar") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = pillar_name
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.65, 1.6, 0.65)
	col.shape = shape
	col.position = Vector3(0, 0.8, 0)
	body.add_child(col)

	var pillar = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.6, 1.45, 0.6)
	p_mesh.material = materials.mat_wall_trim
	pillar.mesh = p_mesh
	pillar.position = Vector3(0, 0.725, 0)
	body.add_child(pillar)

	var cap = MeshInstance3D.new()
	var cp_mesh = PrismMesh.new()
	cp_mesh.size = Vector3(0.7, 0.28, 0.7)
	cp_mesh.material = materials.mat_wall_trim
	cap.mesh = cp_mesh
	cap.position = Vector3(0, 1.55, 0)
	body.add_child(cap)

	parent.add_child(body)
	return body
