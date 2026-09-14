class_name HumanoidVisuals
extends Node3D

const HumanoidAppearanceData = preload("res://scripts/hero_quest/character/humanoid_appearance_data.gd")
const HumanoidMeshBuilder = preload("res://scripts/hero_quest/character/humanoid_mesh_builder.gd")
const HumanoidAnimator = preload("res://scripts/hero_quest/character/humanoid_animator.gd")

var mesh_builder: HumanoidMeshBuilder = HumanoidMeshBuilder.new()
var current_appearance: HumanoidAppearanceData = null

# Rig Joint Nodes (Preserved permanently for AnimationPlayer tracks)
var root_node: Node3D
var hips_node: Node3D
var chest_node: Node3D
var head_node: Node3D
var arm_l_node: Node3D
var forearm_l_node: Node3D
var hand_l_node: Node3D
var arm_r_node: Node3D
var forearm_r_node: Node3D
var hand_r_node: Node3D
var leg_l_node: Node3D
var shin_l_node: Node3D
var foot_l_node: Node3D
var leg_r_node: Node3D
var shin_r_node: Node3D
var foot_r_node: Node3D

# Visual Attachment Containers
var hips_visuals: Node3D
var head_visuals: Node3D
var chest_visuals: Node3D
var arm_l_visuals: Node3D
var forearm_l_visuals: Node3D
var hand_l_visuals: Node3D
var arm_r_visuals: Node3D
var forearm_r_visuals: Node3D
var hand_r_visuals: Node3D
var leg_l_visuals: Node3D
var shin_l_visuals: Node3D
var foot_l_visuals: Node3D
var leg_r_visuals: Node3D
var shin_r_visuals: Node3D
var foot_r_visuals: Node3D

var anim_player: AnimationPlayer
var is_currently_walking: bool = false

func _ready() -> void:
	if not root_node:
		_build_rig_hierarchy()
		_setup_animation_player()
	if not current_appearance:
		apply_appearance(HumanoidAppearanceData.create_hero())

func _build_rig_hierarchy() -> void:
	root_node = Node3D.new()
	root_node.name = "Root"
	add_child(root_node)

	# Pelvis / Hips (pivot at y = 1.02m)
	hips_node = Node3D.new()
	hips_node.name = "Hips"
	hips_node.position = Vector3(0, 1.02, 0)
	root_node.add_child(hips_node)

	hips_visuals = Node3D.new()
	hips_visuals.name = "Visuals"
	hips_node.add_child(hips_visuals)

	# Spine / Chest (pivot at y = 0.26m above hips)
	chest_node = Node3D.new()
	chest_node.name = "Chest"
	chest_node.position = Vector3(0, 0.26, 0)
	hips_node.add_child(chest_node)

	chest_visuals = Node3D.new()
	chest_visuals.name = "Visuals"
	chest_node.add_child(chest_visuals)

	# Head (pivot at y = 0.35m above chest)
	head_node = Node3D.new()
	head_node.name = "Head"
	head_node.position = Vector3(0, 0.35, 0)
	chest_node.add_child(head_node)

	head_visuals = Node3D.new()
	head_visuals.name = "Visuals"
	head_node.add_child(head_visuals)

	# Left Arm
	arm_l_node = Node3D.new()
	arm_l_node.name = "Arm_L"
	arm_l_node.position = Vector3(-0.30, 0.16, 0)
	chest_node.add_child(arm_l_node)

	arm_l_visuals = Node3D.new()
	arm_l_visuals.name = "Visuals"
	arm_l_node.add_child(arm_l_visuals)

	forearm_l_node = Node3D.new()
	forearm_l_node.name = "Forearm_L"
	forearm_l_node.position = Vector3(0, -0.30, 0)
	arm_l_node.add_child(forearm_l_node)

	forearm_l_visuals = Node3D.new()
	forearm_l_visuals.name = "Visuals"
	forearm_l_node.add_child(forearm_l_visuals)

	hand_l_node = Node3D.new()
	hand_l_node.name = "Hand_L"
	hand_l_node.position = Vector3(0, -0.26, 0)
	forearm_l_node.add_child(hand_l_node)

	hand_l_visuals = Node3D.new()
	hand_l_visuals.name = "Visuals"
	hand_l_node.add_child(hand_l_visuals)

	# Right Arm
	arm_r_node = Node3D.new()
	arm_r_node.name = "Arm_R"
	arm_r_node.position = Vector3(0.30, 0.16, 0)
	chest_node.add_child(arm_r_node)

	arm_r_visuals = Node3D.new()
	arm_r_visuals.name = "Visuals"
	arm_r_node.add_child(arm_r_visuals)

	forearm_r_node = Node3D.new()
	forearm_r_node.name = "Forearm_R"
	forearm_r_node.position = Vector3(0, -0.30, 0)
	arm_r_node.add_child(forearm_r_node)

	forearm_r_visuals = Node3D.new()
	forearm_r_visuals.name = "Visuals"
	forearm_r_node.add_child(forearm_r_visuals)

	hand_r_node = Node3D.new()
	hand_r_node.name = "Hand_R"
	hand_r_node.position = Vector3(0, -0.26, 0)
	forearm_r_node.add_child(hand_r_node)

	hand_r_visuals = Node3D.new()
	hand_r_visuals.name = "Visuals"
	hand_r_node.add_child(hand_r_visuals)

	# Left Leg
	leg_l_node = Node3D.new()
	leg_l_node.name = "Leg_L"
	leg_l_node.position = Vector3(-0.13, -0.06, 0)
	hips_node.add_child(leg_l_node)

	leg_l_visuals = Node3D.new()
	leg_l_visuals.name = "Visuals"
	leg_l_node.add_child(leg_l_visuals)

	shin_l_node = Node3D.new()
	shin_l_node.name = "Shin_L"
	shin_l_node.position = Vector3(0, -0.44, 0)
	leg_l_node.add_child(shin_l_node)

	shin_l_visuals = Node3D.new()
	shin_l_visuals.name = "Visuals"
	shin_l_node.add_child(shin_l_visuals)

	foot_l_node = Node3D.new()
	foot_l_node.name = "Foot_L"
	foot_l_node.position = Vector3(0, -0.42, 0)
	shin_l_node.add_child(foot_l_node)

	foot_l_visuals = Node3D.new()
	foot_l_visuals.name = "Visuals"
	foot_l_node.add_child(foot_l_visuals)

	# Right Leg
	leg_r_node = Node3D.new()
	leg_r_node.name = "Leg_R"
	leg_r_node.position = Vector3(0.13, -0.06, 0)
	hips_node.add_child(leg_r_node)

	leg_r_visuals = Node3D.new()
	leg_r_visuals.name = "Visuals"
	leg_r_node.add_child(leg_r_visuals)

	shin_r_node = Node3D.new()
	shin_r_node.name = "Shin_R"
	shin_r_node.position = Vector3(0, -0.44, 0)
	leg_r_node.add_child(shin_r_node)

	shin_r_visuals = Node3D.new()
	shin_r_visuals.name = "Visuals"
	shin_r_node.add_child(shin_r_visuals)

	foot_r_node = Node3D.new()
	foot_r_node.name = "Foot_R"
	foot_r_node.position = Vector3(0, -0.42, 0)
	shin_r_node.add_child(foot_r_node)

	foot_r_visuals = Node3D.new()
	foot_r_visuals.name = "Visuals"
	foot_r_node.add_child(foot_r_visuals)

func _setup_animation_player() -> void:
	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	var lib = HumanoidAnimator.create_animation_library()
	anim_player.add_animation_library("", lib)

	# Buttery smooth cross-fades
	anim_player.set_blend_time("idle", "walk", 0.16)
	anim_player.set_blend_time("walk", "idle", 0.2)

	add_child(anim_player)
	anim_player.play("idle")

func apply_appearance(data: HumanoidAppearanceData) -> void:
	current_appearance = data
	if not root_node:
		_build_rig_hierarchy()
		_setup_animation_player()

	# Clear ONLY the visual mesh containers, leaving rig joints intact!
	_clear_children(hips_visuals)
	_clear_children(head_visuals)
	_clear_children(chest_visuals)
	_clear_children(arm_l_visuals)
	_clear_children(forearm_l_visuals)
	_clear_children(hand_l_visuals)
	_clear_children(arm_r_visuals)
	_clear_children(forearm_r_visuals)
	_clear_children(hand_r_visuals)
	_clear_children(leg_l_visuals)
	_clear_children(shin_l_visuals)
	_clear_children(foot_l_visuals)
	_clear_children(leg_r_visuals)
	_clear_children(shin_r_visuals)
	_clear_children(foot_r_visuals)

	# 1. HIPS & WAIST (SOLID ANATOMICAL PELVIS)
	hips_visuals.add_child(mesh_builder.build_hips_mesh(data.pants_color, data.armor_trim_color))

	# 2. HEAD & BEAUTIFUL FACE
	head_node.scale = data.head_scale
	head_visuals.add_child(mesh_builder.build_head_mesh(data.head_shape, data.skin_color))
	head_visuals.add_child(mesh_builder.build_eyes(data.eye_color))
	head_visuals.add_child(mesh_builder.build_hair(data.hair_style, data.hair_color, data.hair_length))
	head_visuals.add_child(mesh_builder.build_facial_hair(data.facial_hair, data.beard_color))

	# 3. TORSO & BACK GEAR
	chest_node.scale = data.torso_scale
	chest_visuals.add_child(mesh_builder.build_torso_mesh(data.shirt_color, data.armor_trim_color))
	if data.back_gear != "none":
		chest_visuals.add_child(mesh_builder.build_back_gear(data.back_gear))

	# 4. LIMBS SCALING
	var a_scale = Vector3(data.arm_thickness, data.arm_length, data.arm_thickness)
	arm_l_node.scale = a_scale
	arm_r_node.scale = a_scale

	var l_scale = Vector3(data.leg_thickness, data.leg_length, data.leg_thickness)
	leg_l_node.scale = l_scale
	leg_r_node.scale = l_scale

	# 5. ARM & HAND MESHES
	arm_l_visuals.add_child(mesh_builder.build_arm_mesh(data.shirt_color, true))
	forearm_l_visuals.add_child(mesh_builder.build_arm_mesh(data.glove_color, false))
	hand_l_visuals.add_child(mesh_builder.build_hand_mesh(data.glove_color))

	arm_r_visuals.add_child(mesh_builder.build_arm_mesh(data.shirt_color, true))
	forearm_r_visuals.add_child(mesh_builder.build_arm_mesh(data.glove_color, false))
	hand_r_visuals.add_child(mesh_builder.build_hand_mesh(data.glove_color))

	# 6. LEG & FOOT MESHES (ANATOMICAL THIGHS, SHINS, BOOTS)
	leg_l_visuals.add_child(mesh_builder.build_thigh_mesh(data.pants_color))
	shin_l_visuals.add_child(mesh_builder.build_shin_mesh(data.pants_color, data.boots_color))
	foot_l_visuals.add_child(mesh_builder.build_foot_mesh(data.boots_color))

	leg_r_visuals.add_child(mesh_builder.build_thigh_mesh(data.pants_color))
	shin_r_visuals.add_child(mesh_builder.build_shin_mesh(data.pants_color, data.boots_color))
	foot_r_visuals.add_child(mesh_builder.build_foot_mesh(data.boots_color))

	# 7. WEAPONS / SOCKETS
	if data.main_hand_weapon != "none":
		hand_r_visuals.add_child(mesh_builder.build_weapon(data.main_hand_weapon))
	if data.off_hand_gear != "none":
		hand_l_visuals.add_child(mesh_builder.build_off_hand(data.off_hand_gear))

func _clear_children(parent: Node3D) -> void:
	for child in parent.get_children():
		child.queue_free()

func set_moving(is_moving: bool, speed_ratio: float = 1.0) -> void:
	if not anim_player:
		return
	if is_moving and not is_currently_walking:
		is_currently_walking = true
		anim_player.play("walk")
	elif not is_moving and is_currently_walking:
		is_currently_walking = false
		anim_player.play("idle")

	if is_currently_walking:
		anim_player.speed_scale = clampf(speed_ratio, 0.6, 2.5)
	else:
		anim_player.speed_scale = 1.0
