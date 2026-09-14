class_name HumanoidAnimator
extends RefCounted

static func create_animation_library() -> AnimationLibrary:
	var lib = AnimationLibrary.new()
	lib.add_animation("idle", _create_idle_animation())
	lib.add_animation("walk", _create_walk_animation())
	return lib

static func _create_idle_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 2.4
	anim.loop_mode = Animation.LOOP_LINEAR

	# Hips resting at y = 1.02m with subtle breathing bob
	_add_vec3_track(anim, "Root/Hips:position", [
		[0.0, Vector3(0, 1.02, 0)],
		[1.2, Vector3(0, 1.035, 0)],
		[2.4, Vector3(0, 1.02, 0)]
	])

	# Chest gentle breathing expansion
	_add_vec3_track(anim, "Root/Hips/Chest:rotation", [
		[0.0, Vector3(0.02, 0, 0)],
		[1.2, Vector3(-0.02, 0, 0)],
		[2.4, Vector3(0.02, 0, 0)]
	])

	# Head micro-sway
	_add_vec3_track(anim, "Root/Hips/Chest/Head:rotation", [
		[0.0, Vector3(-0.02, 0, 0.01)],
		[1.2, Vector3(0.02, 0, -0.01)],
		[2.4, Vector3(-0.02, 0, 0.01)]
	])

	# Left & Right Arms subtle resting sway
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_L:rotation", [
		[0.0, Vector3(0.04, 0, 0.08)],
		[1.2, Vector3(-0.02, 0, 0.12)],
		[2.4, Vector3(0.04, 0, 0.08)]
	])
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_R:rotation", [
		[0.0, Vector3(0.04, 0, -0.08)],
		[1.2, Vector3(-0.02, 0, -0.12)],
		[2.4, Vector3(0.04, 0, -0.08)]
	])

	_add_vec3_track(anim, "Root/Hips/Chest/Arm_L/Forearm_L:rotation", [
		[0.0, Vector3(0.18, 0, 0)],
		[1.2, Vector3(0.12, 0, 0)],
		[2.4, Vector3(0.18, 0, 0)]
	])
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_R/Forearm_R:rotation", [
		[0.0, Vector3(0.18, 0, 0)],
		[1.2, Vector3(0.12, 0, 0)],
		[2.4, Vector3(0.18, 0, 0)]
	])

	# Legs neutral standing
	_add_vec3_track(anim, "Root/Hips/Leg_L:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])
	_add_vec3_track(anim, "Root/Hips/Leg_R:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])
	_add_vec3_track(anim, "Root/Hips/Leg_L/Shin_L:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])
	_add_vec3_track(anim, "Root/Hips/Leg_R/Shin_R:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])
	_add_vec3_track(anim, "Root/Hips/Leg_L/Shin_L/Foot_L:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])
	_add_vec3_track(anim, "Root/Hips/Leg_R/Shin_R/Foot_R:rotation", [[0.0, Vector3.ZERO], [2.4, Vector3.ZERO]])

	return anim

static func _create_walk_animation() -> Animation:
	var anim = Animation.new()
	anim.length = 0.8
	anim.loop_mode = Animation.LOOP_LINEAR

	# 1. HIPS: Pelvis elevation & lateral weight shift
	# Hips remain at y >= 1.025m so the stance boot sole stays squarely on top of floor & carpets (y = 0.02m)!
	_add_vec3_track(anim, "Root/Hips:position", [
		[0.0, Vector3(0.0, 1.025, 0.0)],
		[0.2, Vector3(-0.03, 1.050, 0.0)], # Peak over stance left foot
		[0.4, Vector3(0.0, 1.025, 0.0)],
		[0.6, Vector3(0.03, 1.050, 0.0)],  # Peak over stance right foot
		[0.8, Vector3(0.0, 1.025, 0.0)]
	])

	# Pelvis frontal tilt (Z) and transversal rotation (Y)
	_add_vec3_track(anim, "Root/Hips:rotation", [
		[0.0, Vector3(0.03, 0.08, 0.0)],
		[0.2, Vector3(0.01, 0.0, -0.04)],
		[0.4, Vector3(0.03, -0.08, 0.0)],
		[0.6, Vector3(0.01, 0.0, 0.04)],
		[0.8, Vector3(0.03, 0.08, 0.0)]
	])

	# 2. SPINE / CHEST: Counter-rotation opposing pelvis
	_add_vec3_track(anim, "Root/Hips/Chest:rotation", [
		[0.0, Vector3(0.03, -0.10, 0.0)],
		[0.2, Vector3(0.01, 0.0, 0.03)],
		[0.4, Vector3(0.03, 0.10, 0.0)],
		[0.6, Vector3(0.01, 0.0, -0.03)],
		[0.8, Vector3(0.03, -0.10, 0.0)]
	])

	# 3. HEAD: Gaze stabilization forward
	_add_vec3_track(anim, "Root/Hips/Chest/Head:rotation", [
		[0.0, Vector3(-0.02, 0.03, 0.0)],
		[0.2, Vector3(-0.01, 0.0, 0.0)],
		[0.4, Vector3(-0.02, -0.03, 0.0)],
		[0.6, Vector3(-0.01, 0.0, 0.0)],
		[0.8, Vector3(-0.02, 0.03, 0.0)]
	])

	# 4. ARMS: Contralateral counter-swing (opposing leg motion) with forward elbow flexion
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_L:rotation", [
		[0.0, Vector3(-0.32, 0.0, 0.08)], # Left leg forward -> Left arm swings back
		[0.2, Vector3(0.0, 0.0, 0.10)],
		[0.4, Vector3(0.32, 0.0, 0.08)],  # Left leg back -> Left arm swings forward
		[0.6, Vector3(0.0, 0.0, 0.10)],
		[0.8, Vector3(-0.32, 0.0, 0.08)]
	])
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_L/Forearm_L:rotation", [
		[0.0, Vector3(0.12, 0, 0)],
		[0.2, Vector3(0.22, 0, 0)],
		[0.4, Vector3(0.36, 0, 0)],       # Forward elbow bend during forward arm swing
		[0.6, Vector3(0.22, 0, 0)],
		[0.8, Vector3(0.12, 0, 0)]
	])

	_add_vec3_track(anim, "Root/Hips/Chest/Arm_R:rotation", [
		[0.0, Vector3(0.32, 0.0, -0.08)], # Left leg forward -> Right arm swings forward
		[0.2, Vector3(0.0, 0.0, -0.10)],
		[0.4, Vector3(-0.32, 0.0, -0.08)],# Left leg back -> Right arm swings back
		[0.6, Vector3(0.0, 0.0, -0.10)],
		[0.8, Vector3(0.32, 0.0, -0.08)]
	])
	_add_vec3_track(anim, "Root/Hips/Chest/Arm_R/Forearm_R:rotation", [
		[0.0, Vector3(0.36, 0, 0)],       # Forward elbow bend during forward arm swing
		[0.2, Vector3(0.22, 0, 0)],
		[0.4, Vector3(0.12, 0, 0)],
		[0.6, Vector3(0.22, 0, 0)],
		[0.8, Vector3(0.36, 0, 0)]
	])

	# 5. BIOMECHANICALLY RIGOROUS HUMAN LEGS:
	# - Thigh forward swing = rotation.x > 0 (towards -Z). Backward push-off = rotation.x < 0.
	# - Knee joint = rotation.x <= 0 AT ALL TIMES! Human knees only bend backward (shin folds to rear).
	# - Foot = dorsiflexion (toes up, heel strike) = rotation.x > 0. Plantarflexion (push-off) = rotation.x < 0.

	# --- LEFT LEG ---
	_add_vec3_track(anim, "Root/Hips/Leg_L:rotation", [
		[0.0, Vector3(0.44, 0.0, 0.02)],  # 0% Heel Strike forward
		[0.10, Vector3(0.26, 0.0, 0.02)], # 12% Loading response
		[0.20, Vector3(0.0, 0.0, 0.02)],  # 25% Mid-stance vertical under body
		[0.30, Vector3(-0.24, 0.0, 0.02)],# 38% Terminal stance extension
		[0.40, Vector3(-0.12, 0.0, 0.02)],# 50% Toe-off: thigh begins driving forward
		[0.50, Vector3(0.22, 0.0, 0.02)], # 62% Mid-swing: thigh drives UP and FORWARD
		[0.65, Vector3(0.42, 0.0, 0.02)], # 81% Terminal swing: thigh reaches forward
		[0.80, Vector3(0.44, 0.0, 0.02)]  # 100% Next contact
	])

	_add_vec3_track(anim, "Root/Hips/Leg_L/Shin_L:rotation", [
		[0.0, Vector3(-0.06, 0, 0)],      # 0% Contact: knee nearly straight reaching forward
		[0.10, Vector3(-0.16, 0, 0)],     # 12% Loading: shock absorption flex backward
		[0.20, Vector3(-0.04, 0, 0)],     # 25% Mid-stance: straight supporting weight
		[0.30, Vector3(-0.38, 0, 0)],     # 38% Push-off: heel leaves floor, knee flexes backward
		[0.40, Vector3(-0.72, 0, 0)],     # 50% Toe-off: knee rapidly flexes backward
		[0.50, Vector3(-0.96, 0, 0)],     # 62% Mid-swing: PEAK BACKWARD FLEXION ~55°! Foot tucked up!
		[0.65, Vector3(-0.22, 0, 0)],     # 81% Terminal swing: knee extends forward
		[0.80, Vector3(-0.06, 0, 0)]      # 100% Next contact
	])

	_add_vec3_track(anim, "Root/Hips/Leg_L/Shin_L/Foot_L:rotation", [
		[0.0, Vector3(0.18, 0, 0)],       # 0% Heel Strike (toes tilted up, heel lands first)
		[0.10, Vector3(0.0, 0, 0)],        # 12% Rolls flat onto floor
		[0.20, Vector3(-0.02, 0, 0)],      # 25% Flat on ground bearing full weight
		[0.30, Vector3(-0.16, 0, 0)],      # 38% Heel rises, pushing off toes
		[0.40, Vector3(-0.10, 0, 0)],      # 50% Leaving floor
		[0.50, Vector3(0.06, 0, 0)],       # 62% Relaxed neutral in flight, clearing carpet!
		[0.65, Vector3(0.14, 0, 0)],       # 81% Presenting heel forward
		[0.80, Vector3(0.18, 0, 0)]        # 100% Next contact
	])

	# --- RIGHT LEG (Mirrored by 0.40s / 50% phase offset) ---
	_add_vec3_track(anim, "Root/Hips/Leg_R:rotation", [
		[0.0, Vector3(-0.12, 0.0, -0.02)],# 0% Toe-off: thigh begins driving forward
		[0.10, Vector3(0.22, 0.0, -0.02)], # 12% Mid-swing: thigh drives UP and FORWARD
		[0.25, Vector3(0.42, 0.0, -0.02)], # 31% Terminal swing: thigh reaches forward
		[0.40, Vector3(0.44, 0.0, -0.02)], # 50% Heel Strike forward
		[0.50, Vector3(0.26, 0.0, -0.02)], # 62% Loading response
		[0.60, Vector3(0.0, 0.0, -0.02)],  # 75% Mid-stance vertical under body
		[0.70, Vector3(-0.24, 0.0, -0.02)],# 88% Terminal stance extension
		[0.80, Vector3(-0.12, 0.0, -0.02)] # 100% Next cycle
	])

	_add_vec3_track(anim, "Root/Hips/Leg_R/Shin_R:rotation", [
		[0.0, Vector3(-0.72, 0, 0)],      # 0% Toe-off: knee rapidly flexes backward
		[0.10, Vector3(-0.96, 0, 0)],     # 12% Mid-swing: PEAK BACKWARD FLEXION ~55°!
		[0.25, Vector3(-0.22, 0, 0)],     # 31% Terminal swing: knee extends forward
		[0.40, Vector3(-0.06, 0, 0)],     # 50% Contact: knee nearly straight reaching forward
		[0.50, Vector3(-0.16, 0, 0)],     # 62% Loading: shock absorption flex backward
		[0.60, Vector3(-0.04, 0, 0)],     # 75% Mid-stance: straight supporting weight
		[0.70, Vector3(-0.38, 0, 0)],     # 88% Push-off: heel leaves floor, knee flexes backward
		[0.80, Vector3(-0.72, 0, 0)]      # 100% Next cycle
	])

	_add_vec3_track(anim, "Root/Hips/Leg_R/Shin_R/Foot_R:rotation", [
		[0.0, Vector3(-0.10, 0, 0)],      # 0% Leaving floor
		[0.10, Vector3(0.06, 0, 0)],       # 12% Relaxed neutral in flight, clearing carpet!
		[0.25, Vector3(0.14, 0, 0)],       # 31% Presenting heel forward
		[0.40, Vector3(0.18, 0, 0)],       # 50% Heel Strike (toes tilted up, heel lands first)
		[0.50, Vector3(0.0, 0, 0)],        # 62% Rolls flat onto floor
		[0.60, Vector3(-0.02, 0, 0)],      # 75% Flat on ground bearing full weight
		[0.70, Vector3(-0.16, 0, 0)],      # 88% Heel rises, pushing off toes
		[0.80, Vector3(-0.10, 0, 0)]       # 100% Next cycle
	])

	return anim

static func _add_vec3_track(anim: Animation, track_path: String, keyframes: Array) -> void:
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, track_path)
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	for k in keyframes:
		anim.track_insert_key(track_idx, k[0], k[1])
