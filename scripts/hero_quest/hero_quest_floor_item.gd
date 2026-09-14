class_name HeroQuestFloorItem
extends Node3D

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

signal picked_up(item: ItemData)

@export var item_data: ItemData = null

var float_timer: float = 0.0
var base_y: float = 0.15
var interactable: HeroQuestInteractable = null
var crystal_node: Node3D = null

func setup(data: ItemData, pos: Vector3) -> void:
	item_data = data
	global_position = Vector3(pos.x, base_y, pos.z)
	_build_visuals()
	_setup_interactable()

func _build_visuals() -> void:
	# 1. Base pedestal ring
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.4
	cyl.height = 0.06
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.18, 0.15)
	base_mat.roughness = 0.8
	base_mesh.mesh = cyl
	base_mesh.position = Vector3(0, 0.03, 0)
	add_child(base_mesh)

	# 2. Golden rim marker
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.36
	torus.outer_radius = 0.42
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.8, 0.25)
	gold_mat.metallic = 0.8
	ring.mesh = torus
	ring.position = Vector3(0, 0.05, 0)
	add_child(ring)

	# 3. Floating glowing icon/relic crystal
	crystal_node = Node3D.new()
	crystal_node.position = Vector3(0, 0.35, 0)
	add_child(crystal_node)

	var crystal_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.28, 0.28, 0.28)
	var glow_mat = StandardMaterial3D.new()
	var color = item_data.rarity_color if item_data else Color(1.0, 0.85, 0.3)
	glow_mat.albedo_color = color
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 2.0
	crystal_mesh.mesh = box
	crystal_mesh.rotation = Vector3(0.785, 0.785, 0)
	crystal_node.add_child(crystal_mesh)

	# 4. Subtle beacon light
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.6
	light.omni_range = 2.5
	light.position = Vector3(0, 0.45, 0)
	add_child(light)

func _setup_interactable() -> void:
	interactable = HeroQuestInteractable.new()
	interactable.name = "Interactable"
	interactable.interact_type = HeroQuestInteractable.InteractType.ITEM
	var item_name = item_data.name if item_data else "Dropped Item"
	interactable.loot_name = item_name
	interactable.item_data = item_data
	interactable.custom_prompt = "Press [E] or [SPACE] to pick up " + item_name
	add_child(interactable)

func _process(delta: float) -> void:
	float_timer += delta * 2.5
	if crystal_node:
		crystal_node.position.y = 0.35 + sin(float_timer) * 0.06
		crystal_node.rotation.y += delta * 1.5

func collect() -> ItemData:
	var item = item_data
	picked_up.emit(item)
	queue_free()
	return item
