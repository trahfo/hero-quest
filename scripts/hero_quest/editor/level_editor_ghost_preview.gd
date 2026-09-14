class_name LevelEditorGhostPreview
extends Node3D

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")
const CastlePropFactory = preload("res://scripts/hero_quest/castle_prop_factory.gd")
const CastleDecorationFactory = preload("res://scripts/hero_quest/castle_decoration_factory.gd")
const CastleGraveyardPropFactory = preload("res://scripts/hero_quest/castle_graveyard_prop_factory.gd")
const CastleMeshBuilder = preload("res://scripts/hero_quest/castle_mesh_builder.gd")
const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")
const LevelEditorPlacementPolicy = preload("res://scripts/hero_quest/editor/level_editor_placement_policy.gd")
const CastleDoorBuilder = preload("res://scripts/hero_quest/castle_door_builder.gd")

var preview_node: Node3D = null
var ghost_mat: StandardMaterial3D

var materials: CastleMaterials
var prop_factory: CastlePropFactory
var decor_factory: CastleDecorationFactory
var graveyard_factory: CastleGraveyardPropFactory
var mesh_builder: CastleMeshBuilder
var wall_factory: CastleWallTileFactory
var door_builder: CastleDoorBuilder
var door_config: Dictionary = {}

func _init(p_materials: CastleMaterials, p_builder: Node3D) -> void:
	name = "LevelEditorGhostPreview"
	materials = p_materials
	prop_factory = p_builder.prop_factory if p_builder.prop_factory else CastlePropFactory.new(materials, p_builder.grid_to_world)
	decor_factory = CastleDecorationFactory.new(materials, p_builder.grid_to_world)
	graveyard_factory = CastleGraveyardPropFactory.new(materials)
	mesh_builder = p_builder.mesh_builder if p_builder.mesh_builder else CastleMeshBuilder.new(materials, p_builder.grid_to_world, p_builder.register_tile)
	wall_factory = CastleWallTileFactory.new(materials)
	door_builder = CastleDoorBuilder.new(materials)

	ghost_mat = StandardMaterial3D.new()
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.22)
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost_mat.render_priority = 3

func update_preview_mesh(tool_name: String, item_data: Dictionary) -> void:
	_clear_preview()
	if not LevelEditorPlacementPolicy.should_show_ghost(tool_name):
		return

	preview_node = Node3D.new()
	preview_node.name = "GhostInstance"
	add_child(preview_node)

	match tool_name:
		"wall":
			var m = MeshInstance3D.new()
			var b = BoxMesh.new(); b.size = Vector3(2.0, 4.5, 0.9)
			m.mesh = b; m.position = Vector3(0, 2.25, 0)
			preview_node.add_child(m)
		"window":
			wall_factory.create_window_wall(preview_node, Vector3.ZERO, Vector3(0, 0, 1), 4.5)
		"chest":
			prop_factory.create_treasure_chest(preview_node, Vector3(0, 0.12, 0), 0.0, "Ghost")
		"door", "arch":
			var axis = int(item_data.get("axis", 0))
			var a_type = item_data.get("arch_type", item_data.get("type", "arch_3tile"))
			match a_type:
				"wooden_door_1tile":
					var res = door_builder.build_wooden_door_1tile(preview_node, axis)
					_apply_door_preview_pose(res)
				"wooden_door_2tile":
					var res = door_builder.build_wooden_door_2tile(preview_node, axis)
					_apply_door_preview_pose(res)
				"iron_door_1tile":
					var res = door_builder.build_iron_door_1tile(preview_node, axis)
					_apply_door_preview_pose(res)
				"iron_door_2tile":
					var res = door_builder.build_iron_door_2tile(preview_node, axis)
					_apply_door_preview_pose(res)
				"portcullis_1tile":
					var res = door_builder.build_portcullis(preview_node, 1, axis)
					_apply_door_preview_pose(res)
				"portcullis_2tile":
					var res = door_builder.build_portcullis(preview_node, 2, axis)
					_apply_door_preview_pose(res)
				"arch_spanning_3tiles":
					mesh_builder.build_arch_spanning_3tiles(preview_node, Vector2i.ZERO, axis, "GhostArch")
				"arch_5tile_twin":
					mesh_builder.build_arch_5tile_twin(preview_node, Vector2i.ZERO, axis, "GhostArch")
				"arch_4tile":
					var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
					mesh_builder.build_arch_4tile(preview_node, Vector2i.ZERO, off, axis, "GhostArch")
				_:
					mesh_builder.build_arch_3tile(preview_node, Vector2i.ZERO, axis, "GhostArch")
		"item":
			var m = MeshInstance3D.new()
			var b = BoxMesh.new(); b.size = Vector3(0.35, 0.35, 0.35)
			m.mesh = b; m.position = Vector3(0, 0.25, 0)
			preview_node.add_child(m)
		"prop":
			_spawn_prop_preview(item_data)
		_:
			var m = MeshInstance3D.new()
			var b = BoxMesh.new(); b.size = Vector3(1.0, 1.0, 1.0)
			m.mesh = b; m.position = Vector3(0, 0.5, 0)
			preview_node.add_child(m)

	_apply_ghost_material(preview_node)

func set_door_config(cfg: Dictionary) -> void:
	door_config = cfg

func _apply_door_preview_pose(res: Dictionary) -> void:
	var is_open = door_config.get("is_open", false)
	if not is_open: return
	var is_slide = res.get("is_slide", false)
	var pivots = res.get("pivots", [])
	if is_slide:
		for p in pivots:
			if is_instance_valid(p): p.position.y = 3.2
	elif pivots.size() == 1:
		if is_instance_valid(pivots[0]):
			pivots[0].rotation.y = -PI * 0.5 if res.get("axis", 0) == 0 else PI * 0.5
	elif pivots.size() >= 2:
		if is_instance_valid(pivots[0]): pivots[0].rotation.y = -PI * 0.5
		if is_instance_valid(pivots[1]): pivots[1].rotation.y = PI * 0.5

func _spawn_prop_preview(data: Dictionary) -> void:
	var p_type = data.get("type", "")
	match p_type:
		"bush":
			decor_factory.create_bush(preview_node, Vector3.ZERO)
		"flower_patch":
			decor_factory.create_flower_patch(preview_node, Vector3.ZERO)
		"fountain":
			decor_factory.create_fountain(preview_node, Vector3.ZERO)
		"chimney":
			decor_factory.create_chimney_fireplace(preview_node, Vector3.ZERO, 0.0)
		"table":
			prop_factory.create_table(preview_node, Vector3.ZERO, Vector3(1.8, 1.0, 1.8), null)
			if data.get("has_chair", false):
				prop_factory.furniture.create_chair(preview_node, Vector3(0, 0, 0.7), 0.0)
		"chair":
			prop_factory.create_chair(preview_node, Vector3.ZERO, 0.0)
		"pew":
			prop_factory.create_bench_2tile(preview_node, Vector3.ZERO, data.get("with_back", true), 0.0)
		"cupboard":
			prop_factory.create_cupboard(preview_node, Vector3.ZERO, 0.0)
		"drawer":
			prop_factory.create_drawer(preview_node, Vector3.ZERO, 0.0)
		"bookshelf":
			prop_factory.create_bookshelf(preview_node, Vector3.ZERO, 0.0)
		"arms_shelf":
			prop_factory.create_arms_shelf(preview_node, Vector3.ZERO, 0.0)
		"torch":
			prop_factory.create_torch(preview_node, Vector3(0, 2.2, 0), Vector3(0, 0, 1))
		"painting":
			decor_factory.create_painting(preview_node, Vector3(0, 2.0, 0), Vector3(0, 0, 1), data.get("index", 0))
		"brazier":
			prop_factory.create_brazier(preview_node, Vector3.ZERO)
		"candelabra":
			prop_factory.create_candelabra(preview_node, Vector3.ZERO)
		"anvil":
			prop_factory.create_anvil(preview_node, Vector3.ZERO)
		"water_trough":
			prop_factory.create_water_trough(preview_node, Vector3.ZERO)
		"grindstone":
			prop_factory.create_grindstone(preview_node, Vector3.ZERO)
		"hay_bale":
			prop_factory.create_hay_bale(preview_node, Vector3.ZERO)
		"gravestone":
			graveyard_factory.create_gravestone(preview_node, Vector3.ZERO, 0.0, "", data.get("style", 0))
		"skeleton":
			graveyard_factory.create_skeleton(preview_node, Vector3.ZERO, 0.0)
		"ancient_tree":
			graveyard_factory.create_cemetery_tree(preview_node, Vector3.ZERO)
		"torch_on_stick":
			graveyard_factory.create_torch_on_stick(preview_node, Vector3.ZERO)
		"cemetery_fence":
			graveyard_factory.create_cemetery_fence(preview_node, Vector3.ZERO, 2.0, false)
		"iron_fence":
			decor_factory.create_iron_fence(preview_node, Vector3.ZERO, 2.0)
		"altar":
			prop_factory.create_table(preview_node, Vector3.ZERO, Vector3(2.6, 1.2, 1.6), materials.mat_wall_trim)
		"pillar":
			mesh_builder.create_pillar(preview_node, Vector3.ZERO, data.get("height", 4.5))
		"golden_cross":
			var p1 = MeshInstance3D.new(); var b1 = BoxMesh.new(); b1.size = Vector3(0.2, 1.4, 0.2); p1.mesh = b1; p1.position = Vector3(0, 0.7, 0); preview_node.add_child(p1)
			var p2 = MeshInstance3D.new(); var b2 = BoxMesh.new(); b2.size = Vector3(0.8, 0.2, 0.2); b2.material = materials.mat_gold; p2.mesh = b2; p2.position = Vector3(0, 1.0, 0); preview_node.add_child(p2)
		"carpet":
			var c = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = Vector3(2.0, 0.02, 2.0); c.mesh = b; c.position = Vector3(0, 0.01, 0); preview_node.add_child(c)
		"lower_wall":
			var m = MeshInstance3D.new()
			var b = BoxMesh.new(); b.size = Vector3(2.0, 1.8, 0.9); m.mesh = b; m.position = Vector3(0, 0.9, 0)
			preview_node.add_child(m)
		"stone_pillar":
			graveyard_factory.create_stone_pillar(preview_node, Vector3.ZERO)
		_:
			var m = MeshInstance3D.new()
			var b = BoxMesh.new(); b.size = Vector3(0.8, 0.8, 0.8)
			m.mesh = b; m.position = Vector3(0, 0.4, 0)
			preview_node.add_child(m)

func _apply_ghost_material(node: Node) -> void:
	if node is CollisionShape3D or node is CollisionObject3D:
		if node is CollisionShape3D:
			node.disabled = true
	if node is Light3D:
		node.visible = false
	if node is MeshInstance3D:
		node.material_override = ghost_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		_apply_ghost_material(child)

func set_preview_transform(pos: Vector3, rot_y: float) -> void:
	if preview_node:
		preview_node.global_position = pos
		preview_node.rotation.y = rot_y

func set_preview_visible(p_visible: bool) -> void:
	visible = p_visible

func _clear_preview() -> void:
	if preview_node and is_instance_valid(preview_node):
		preview_node.queue_free()
		preview_node = null
