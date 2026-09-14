class_name HumanoidGearBuilder
extends RefCounted

var _mat_cache: Dictionary = {}

func get_material(color: Color, roughness: float = 0.7, metallic: float = 0.0, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var key = "%s_%.2f_%.2f_%s" % [color.to_html(), roughness, metallic, emission.to_html()]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.8
	_mat_cache[key] = mat
	return mat

func build_weapon(weapon_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "Weapon_" + weapon_id
	var steel = get_material(Color(0.85, 0.88, 0.92), 0.2, 0.9)
	var gold = get_material(Color(0.95, 0.78, 0.22), 0.3, 0.85)
	var wood = get_material(Color(0.42, 0.28, 0.16), 0.8, 0.0)

	match weapon_id:
		"sword":
			var blade = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.06, 0.75, 0.02)
			bm.material = steel
			blade.mesh = bm
			blade.position = Vector3(0, 0.45, 0)
			root.add_child(blade)

			var guard = MeshInstance3D.new()
			var gm = BoxMesh.new()
			gm.size = Vector3(0.24, 0.04, 0.05)
			gm.material = gold
			guard.mesh = gm
			guard.position = Vector3(0, 0.08, 0)
			root.add_child(guard)

			var grip = MeshInstance3D.new()
			var gp = CylinderMesh.new()
			gp.top_radius = 0.025
			gp.bottom_radius = 0.025
			gp.height = 0.18
			gp.material = wood
			grip.mesh = gp
			root.add_child(grip)
		"mace":
			var handle = MeshInstance3D.new()
			var hm = CylinderMesh.new()
			hm.top_radius = 0.03
			hm.bottom_radius = 0.03
			hm.height = 0.7
			hm.material = wood
			handle.mesh = hm
			handle.position = Vector3(0, 0.25, 0)
			root.add_child(handle)

			var head = MeshInstance3D.new()
			var s = SphereMesh.new()
			s.radius = 0.12
			s.height = 0.24
			s.material = steel
			head.mesh = s
			head.position = Vector3(0, 0.6, 0)
			root.add_child(head)
		"staff":
			var shaft = MeshInstance3D.new()
			var sm = CylinderMesh.new()
			sm.top_radius = 0.035
			sm.bottom_radius = 0.025
			sm.height = 1.7
			sm.material = wood
			shaft.mesh = sm
			shaft.position = Vector3(0, 0.4, 0)
			root.add_child(shaft)

			var crystal = MeshInstance3D.new()
			var c_mesh = SphereMesh.new()
			c_mesh.radius = 0.11
			c_mesh.height = 0.22
			c_mesh.material = get_material(Color(0.6, 0.2, 0.9), 0.1, 0.0, Color(0.7, 0.3, 1.0))
			crystal.mesh = c_mesh
			crystal.position = Vector3(0, 1.3, 0)
			root.add_child(crystal)
		"bow":
			var bow = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.04, 0.95, 0.08)
			bm.material = wood
			bow.mesh = bm
			root.add_child(bow)

			var string_line = MeshInstance3D.new()
			var st_m = BoxMesh.new()
			st_m.size = Vector3(0.01, 0.94, 0.01)
			st_m.material = get_material(Color(0.9, 0.9, 0.9), 0.5, 0.0)
			string_line.mesh = st_m
			string_line.position = Vector3(0, 0, 0.08)
			root.add_child(string_line)

	return root

func build_off_hand(gear_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "OffHand_" + gear_id

	match gear_id:
		"shield":
			var shield = MeshInstance3D.new()
			var sm = BoxMesh.new()
			sm.size = Vector3(0.42, 0.55, 0.06)
			sm.material = get_material(Color(0.25, 0.4, 0.65), 0.4, 0.3)
			shield.mesh = sm
			shield.position = Vector3(-0.06, 0, 0)
			root.add_child(shield)

			var boss = MeshInstance3D.new()
			var bm = SphereMesh.new()
			bm.radius = 0.08
			bm.height = 0.1
			bm.material = get_material(Color(0.95, 0.78, 0.2), 0.2, 0.85)
			boss.mesh = bm
			boss.position = Vector3(-0.06, 0, -0.04)
			root.add_child(boss)
		"spellbook":
			var book = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.28, 0.36, 0.09)
			bm.material = get_material(Color(0.45, 0.15, 0.2), 0.5, 0.1)
			book.mesh = bm
			root.add_child(book)
		"bow":
			var bow = build_weapon("bow")
			root.add_child(bow)

	return root

func build_back_gear(gear_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "BackGear_" + gear_id
	if gear_id == "quiver":
		var quiver = MeshInstance3D.new()
		var qm = CylinderMesh.new()
		qm.top_radius = 0.09
		qm.bottom_radius = 0.06
		qm.height = 0.6
		qm.material = get_material(Color(0.38, 0.24, 0.14), 0.8, 0.0)
		quiver.mesh = qm
		quiver.rotation.z = 0.4
		quiver.position = Vector3(0.08, 0.1, 0.22)
		root.add_child(quiver)

		for i in range(3):
			var arrow = MeshInstance3D.new()
			var am = CylinderMesh.new()
			am.top_radius = 0.015
			am.bottom_radius = 0.015
			am.height = 0.7
			am.material = get_material(Color(0.8, 0.75, 0.6), 0.7, 0.0)
			arrow.mesh = am
			arrow.position = Vector3(0.06 + i * 0.03, 0.35, 0.22)
			arrow.rotation.z = 0.4
			root.add_child(arrow)

	return root
