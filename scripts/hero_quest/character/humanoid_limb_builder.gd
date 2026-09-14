class_name HumanoidLimbBuilder
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

# --- TORSO & PELVIS (ANATOMICAL PROPORTIONS) ---

func build_hips_mesh(pants_color: Color, belt_color: Color) -> Node3D:
	var hips_root = Node3D.new()
	hips_root.name = "HipsModel"
	var p_mat = get_material(pants_color, 0.7, 0.05)
	var b_mat = get_material(belt_color, 0.4, 0.6)

	# Pelvis block (connecting thighs to torso seamlessly)
	var pelvis = MeshInstance3D.new()
	var pm = BoxMesh.new()
	pm.size = Vector3(0.36, 0.18, 0.24)
	pm.material = p_mat
	pelvis.mesh = pm
	pelvis.position = Vector3(0, -0.04, 0)
	hips_root.add_child(pelvis)

	# Waist belt with gold/brass buckle
	var belt = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.38, 0.08, 0.26)
	bm.material = b_mat
	belt.mesh = bm
	belt.position = Vector3(0, 0.04, 0)
	hips_root.add_child(belt)

	return hips_root

func build_torso_mesh(shirt_color: Color, _trim_color: Color = Color.BLACK) -> Node3D:
	var torso = Node3D.new()
	torso.name = "TorsoModel"
	var t_mat = get_material(shirt_color, 0.65, 0.1)

	# Tapered upper chest (broader at shoulders, tapering to waist)
	var chest = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(0.46, 0.38, 0.28)
	cm.material = t_mat
	chest.mesh = cm
	chest.position = Vector3(0, 0.04, 0)
	torso.add_child(chest)

	return torso

func build_arm_mesh(color: Color, is_upper: bool) -> Node3D:
	var arm_root = Node3D.new()
	var mat = get_material(color, 0.7, 0.05)

	var part = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.material = mat
	if is_upper:
		cm.top_radius = 0.085
		cm.bottom_radius = 0.072
		cm.height = 0.30
		part.position = Vector3(0, -0.15, 0)
	else:
		cm.top_radius = 0.072
		cm.bottom_radius = 0.062
		cm.height = 0.28
		part.position = Vector3(0, -0.14, 0)
	cm.radial_segments = 10
	part.mesh = cm
	arm_root.add_child(part)
	return arm_root

func build_hand_mesh(skin_or_glove: Color) -> MeshInstance3D:
	var hand = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.09, 0.11, 0.11)
	hm.material = get_material(skin_or_glove, 0.8, 0.05)
	hand.mesh = hm
	return hand

# --- REALISTIC HUMAN LEGS (THIGHS, KNEES, CALVES, BOOTS) ---

func build_thigh_mesh(pants_color: Color) -> Node3D:
	var thigh_root = Node3D.new()
	thigh_root.name = "ThighModel"
	var mat = get_material(pants_color, 0.7, 0.05)

	# 1. Tapered Thigh (wider at hips, tapering toward knee)
	var thigh = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.105
	tm.bottom_radius = 0.082
	tm.height = 0.44
	tm.radial_segments = 12
	tm.material = mat
	thigh.mesh = tm
	thigh.position = Vector3(0, -0.22, 0)
	thigh_root.add_child(thigh)

	# 2. Rounded Kneecap (Patella)
	var knee = MeshInstance3D.new()
	var km = BoxMesh.new()
	km.size = Vector3(0.10, 0.10, 0.055)
	km.material = mat
	knee.mesh = km
	knee.position = Vector3(0, -0.42, -0.055)
	thigh_root.add_child(knee)

	return thigh_root

func build_shin_mesh(pants_color: Color, boots_color: Color) -> Node3D:
	var shin_root = Node3D.new()
	shin_root.name = "ShinModel"
	var pants_mat = get_material(pants_color, 0.7, 0.05)
	var boot_mat = get_material(boots_color, 0.75, 0.05)

	# 1. Main Lower Leg (tapering to ankle)
	var shin = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.082
	sm.bottom_radius = 0.068
	sm.height = 0.42
	sm.radial_segments = 12
	sm.material = pants_mat
	shin.mesh = sm
	shin.position = Vector3(0, -0.21, 0)
	shin_root.add_child(shin)

	# 2. Calf Muscle Bulge (posterior volume)
	var calf = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.068
	cm.bottom_radius = 0.048
	cm.height = 0.22
	cm.radial_segments = 10
	cm.material = pants_mat
	calf.mesh = cm
	calf.position = Vector3(0, -0.14, 0.035)
	shin_root.add_child(calf)

	# 3. Boot Cuff
	var cuff = MeshInstance3D.new()
	var cfm = CylinderMesh.new()
	cfm.top_radius = 0.078
	cfm.bottom_radius = 0.072
	cfm.height = 0.20
	cfm.radial_segments = 12
	cfm.material = boot_mat
	cuff.mesh = cfm
	cuff.position = Vector3(0, -0.31, 0)
	shin_root.add_child(cuff)

	return shin_root

func build_foot_mesh(boot_color: Color) -> Node3D:
	var foot_root = Node3D.new()
	foot_root.name = "FootModel"
	var boot_mat = get_material(boot_color, 0.75, 0.05)
	var sole_mat = get_material(boot_color.darkened(0.4), 0.9, 0.0)

	# 1. Heel Block
	var heel = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(0.13, 0.10, 0.12)
	hm.material = boot_mat
	heel.mesh = hm
	heel.position = Vector3(0, -0.03, 0.03)
	foot_root.add_child(heel)

	# 2. Forefoot & Tapered Toe Box
	var toe = MeshInstance3D.new()
	var tm = BoxMesh.new()
	tm.size = Vector3(0.12, 0.075, 0.17)
	tm.material = boot_mat
	toe.mesh = tm
	toe.position = Vector3(0, -0.045, -0.11)
	foot_root.add_child(toe)

	# 3. Boot Sole (flush at y = -0.08m)
	var sole = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.135, 0.02, 0.28)
	sm.material = sole_mat
	sole.mesh = sm
	sole.position = Vector3(0, -0.07, -0.04)
	foot_root.add_child(sole)

	return foot_root
