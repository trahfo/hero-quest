class_name HumanoidMeshBuilder
extends RefCounted

const HumanoidGearBuilder = preload("res://scripts/hero_quest/character/humanoid_gear_builder.gd")

var gear_builder: HumanoidGearBuilder = HumanoidGearBuilder.new()
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

# --- HUMAN HEAD, BEAUTIFUL FACE & HAIR ---

func build_head_mesh(shape: String, skin_color: Color) -> Node3D:
	var head_root = Node3D.new()
	head_root.name = "HeadModel"
	var skin_mat = get_material(skin_color, 0.65, 0.0)

	# 1. Cranium (smooth rounded skull)
	var cranium = MeshInstance3D.new()
	var c_mesh = SphereMesh.new()
	c_mesh.radius = 0.18
	c_mesh.height = 0.32
	c_mesh.radial_segments = 16
	c_mesh.rings = 10
	c_mesh.material = skin_mat
	cranium.mesh = c_mesh
	cranium.position = Vector3(0, 0.05, 0.01)
	head_root.add_child(cranium)

	# 2. Lower Face & Defined Jawline (tapering to chin)
	var jaw = MeshInstance3D.new()
	var j_mesh = BoxMesh.new()
	if shape == "chiseled" or shape == "square":
		j_mesh.size = Vector3(0.24, 0.20, 0.22)
	else: # "oval" / "round"
		j_mesh.size = Vector3(0.21, 0.20, 0.20)
	j_mesh.material = skin_mat
	jaw.mesh = j_mesh
	jaw.position = Vector3(0, -0.09, -0.03)
	head_root.add_child(jaw)

	# 3. Delicate Stylized Nose (subtle bridge & tip, no block box)
	var nose = MeshInstance3D.new()
	var n_mesh = BoxMesh.new()
	n_mesh.size = Vector3(0.035, 0.06, 0.045)
	n_mesh.material = skin_mat
	nose.mesh = n_mesh
	nose.position = Vector3(0, -0.035, -0.165)
	nose.rotation.x = -0.2
	head_root.add_child(nose)

	# 4. Subtle Brow Ridge
	var brow = MeshInstance3D.new()
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(0.24, 0.03, 0.05)
	br_mesh.material = skin_mat
	brow.mesh = br_mesh
	brow.position = Vector3(0, 0.055, -0.145)
	head_root.add_child(brow)

	# 5. Mouth (natural lip tone)
	var mouth = MeshInstance3D.new()
	var m_mesh = BoxMesh.new()
	m_mesh.size = Vector3(0.075, 0.016, 0.02)
	var lip_color = skin_color.darkened(0.25).lerp(Color(0.85, 0.45, 0.45), 0.2)
	m_mesh.material = get_material(lip_color, 0.7, 0.0)
	mouth.mesh = m_mesh
	mouth.position = Vector3(0, -0.10, -0.145)
	head_root.add_child(mouth)

	# 6. Ears
	for side in [-1.0, 1.0]:
		var ear = MeshInstance3D.new()
		var e_mesh = BoxMesh.new()
		e_mesh.size = Vector3(0.025, 0.08, 0.05)
		e_mesh.material = skin_mat
		ear.mesh = e_mesh
		ear.position = Vector3(side * 0.175, 0.01, 0.0)
		ear.rotation.y = side * 0.18
		head_root.add_child(ear)

	return head_root

func build_eyes(eye_color: Color) -> Node3D:
	var eyes_node = Node3D.new()
	eyes_node.name = "Eyes"
	var white_mat = get_material(Color(0.96, 0.96, 0.98), 0.3, 0.0)
	var iris_mat = get_material(eye_color, 0.2, 0.1)
	var pupil_mat = get_material(Color(0.05, 0.05, 0.08), 0.1, 0.0)
	var highlight_mat = get_material(Color(1.0, 1.0, 1.0), 0.0, 0.0, Color(1.0, 1.0, 1.0))
	var lash_mat = get_material(Color(0.12, 0.09, 0.08), 0.8, 0.0)

	for side in [-1.0, 1.0]:
		# Eyelash / Upper lid rim
		var lash = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.085, 0.015, 0.03)
		lm.material = lash_mat
		lash.mesh = lm
		lash.position = Vector3(side * 0.075, 0.05, -0.145)
		eyes_node.add_child(lash)

		# Sclera (Eye White)
		var sclera = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(0.075, 0.055, 0.025)
		sm.material = white_mat
		sclera.mesh = sm
		sclera.position = Vector3(side * 0.075, 0.025, -0.14)
		eyes_node.add_child(sclera)

		# Iris
		var iris = MeshInstance3D.new()
		var im = BoxMesh.new()
		im.size = Vector3(0.045, 0.045, 0.015)
		im.material = iris_mat
		iris.mesh = im
		iris.position = Vector3(side * 0.075, 0.025, -0.15)
		eyes_node.add_child(iris)

		# Pupil
		var pupil = MeshInstance3D.new()
		var pm = BoxMesh.new()
		pm.size = Vector3(0.024, 0.024, 0.015)
		pm.material = pupil_mat
		pupil.mesh = pm
		pupil.position = Vector3(side * 0.075, 0.025, -0.155)
		eyes_node.add_child(pupil)

		# Bright Specular Catchlight (vital highlight that makes eyes alive!)
		var catchlight = MeshInstance3D.new()
		var clm = BoxMesh.new()
		clm.size = Vector3(0.014, 0.014, 0.01)
		clm.material = highlight_mat
		catchlight.mesh = clm
		catchlight.position = Vector3(side * 0.075 + 0.01, 0.032, -0.16)
		eyes_node.add_child(catchlight)

	return eyes_node

func build_hair(style: String, hair_color: Color, length: float) -> Node3D:
	var hair_node = Node3D.new()
	hair_node.name = "Hair"
	if style == "bald":
		return hair_node

	var mat = get_material(hair_color, 0.8, 0.05)

	# Scalp cap with volume
	var cap = MeshInstance3D.new()
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = 0.195
	cap_mesh.height = 0.30
	cap_mesh.radial_segments = 14
	cap_mesh.rings = 8
	cap_mesh.material = mat
	cap.mesh = cap_mesh
	cap.position = Vector3(0, 0.09, 0.015)
	hair_node.add_child(cap)

	match style:
		"short_parted":
			# Flowing front fringe & side locks
			var fringe = MeshInstance3D.new()
			var fm = BoxMesh.new()
			fm.size = Vector3(0.26, 0.08, 0.08)
			fm.material = mat
			fringe.mesh = fm
			fringe.position = Vector3(0.02, 0.11, -0.12)
			fringe.rotation.z = -0.08
			hair_node.add_child(fringe)

			for s in [-1.0, 1.0]:
				var side_lock = MeshInstance3D.new()
				var sm = BoxMesh.new()
				sm.size = Vector3(0.04, 0.14, 0.09)
				sm.material = mat
				side_lock.mesh = sm
				side_lock.position = Vector3(s * 0.17, 0.01, -0.05)
				hair_node.add_child(side_lock)
		"helmet":
			var helm_mat = get_material(Color(0.68, 0.70, 0.74), 0.25, 0.9)
			cap.material_override = helm_mat
			var nasal = MeshInstance3D.new()
			var nm = BoxMesh.new()
			nm.size = Vector3(0.05, 0.20, 0.07)
			nm.material = helm_mat
			nasal.mesh = nm
			nasal.position = Vector3(0, 0.02, -0.17)
			hair_node.add_child(nasal)
		"ponytail":
			var tail = MeshInstance3D.new()
			var tm = CylinderMesh.new()
			tm.top_radius = 0.07
			tm.bottom_radius = 0.03
			tm.height = 0.55 * length
			tm.material = mat
			tail.mesh = tm
			tail.position = Vector3(0, 0.02 - (0.2 * length), 0.24 + (0.05 * length))
			tail.rotation.x = -0.55
			hair_node.add_child(tail)
		"long_wizard":
			for s in [-1.0, 1.0]:
				var lock = MeshInstance3D.new()
				var lm = BoxMesh.new()
				lm.size = Vector3(0.07, 0.55 * length, 0.14)
				lm.material = mat
				lock.mesh = lm
				lock.position = Vector3(s * 0.17, -0.15 * length, 0.02)
				hair_node.add_child(lock)
			var back_lock = MeshInstance3D.new()
			var blm = BoxMesh.new()
			blm.size = Vector3(0.30, 0.65 * length, 0.12)
			blm.material = mat
			back_lock.mesh = blm
			back_lock.position = Vector3(0, -0.2 * length, 0.16)
			hair_node.add_child(back_lock)

	return hair_node

func build_facial_hair(style: String, beard_color: Color) -> Node3D:
	var beard_node = Node3D.new()
	beard_node.name = "Beard"
	if style == "none":
		return beard_node

	var mat = get_material(beard_color, 0.85, 0.05)

	match style:
		"goatee":
			var g = MeshInstance3D.new()
			var gm = BoxMesh.new()
			gm.size = Vector3(0.09, 0.11, 0.06)
			gm.material = mat
			g.mesh = gm
			g.position = Vector3(0, -0.16, -0.12)
			beard_node.add_child(g)
		"full_beard":
			var b = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.26, 0.46, 0.18)
			bm.material = mat
			b.mesh = bm
			b.position = Vector3(0, -0.26, -0.10)
			b.rotation.x = 0.12
			beard_node.add_child(b)

	return beard_node

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

func build_torso_mesh(shirt_color: Color, trim_color: Color) -> Node3D:
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

	# Ankle pivot is at local (0, 0, 0).
	# Bottom of sole sits at exactly y = -0.08m, so when ankle is at y = 0.10m,
	# the bottom of the boot rests at y = 0.02m (cleanly on top of floors & carpets)!

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

# --- EQUIPMENT DELEGATION ---

func build_weapon(weapon_id: String) -> Node3D:
	return gear_builder.build_weapon(weapon_id)

func build_off_hand(gear_id: String) -> Node3D:
	return gear_builder.build_off_hand(gear_id)

func build_back_gear(gear_id: String) -> Node3D:
	return gear_builder.build_back_gear(gear_id)
