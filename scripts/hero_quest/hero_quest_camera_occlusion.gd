class_name HeroQuestCameraOcclusion
extends Node

@export var target_alpha: float = 0.3 # 30% transparent so character is always shown

var camera: Camera3D
var player: Node3D
var space_state: PhysicsDirectSpaceState3D

# Key: MeshInstance3D -> Material (original material)
var faded_meshes: Dictionary = {}
# Key: MeshInstance3D -> float (linger timer in seconds)
var mesh_linger: Dictionary = {}

const FADE_LINGER_TIME: float = 0.25

func setup(p_camera: Camera3D, p_player: Node3D) -> void:
	camera = p_camera
	player = p_player

func process_occlusion(delta: float) -> void:
	if not camera or not player or not is_instance_valid(player) or not is_instance_valid(camera):
		return

	if not space_state:
		var world = camera.get_world_3d()
		if world:
			space_state = world.direct_space_state
	if not space_state:
		return

	var cam_pos = camera.global_position
	var p_pos = player.global_position

	# Test points placed strictly on the hero box volume (avoiding air above head)
	var test_points = [
		p_pos + Vector3(0, 0.25, 0),
		p_pos + Vector3(0, 0.55, 0),
		p_pos + Vector3(0, 0.85, 0),
		p_pos + Vector3(-0.3, 0.55, 0),
		p_pos + Vector3(0.3, 0.55, 0)
	]

	var current_occluders: Array[Node] = []
	var player_rid = player.get_rid() if player.has_method("get_rid") else RID()

	for pt in test_points:
		var exclude_rids: Array[RID] = []
		if player_rid.is_valid():
			exclude_rids.append(player_rid)

		for _i in range(8): # Maximum 8 stacked obstacles
			var query = PhysicsRayQueryParameters3D.create(cam_pos, pt)
			query.exclude = exclude_rids
			var hit = space_state.intersect_ray(query)
			if hit.is_empty():
				break

			var col = hit.collider
			var hit_rid: RID = hit.rid
			if hit_rid.is_valid():
				exclude_rids.append(hit_rid)

			if col and col != player and not current_occluders.has(col):
				current_occluders.append(col)

	var active_mesh_instances: Array[MeshInstance3D] = []

	for occluder in current_occluders:
		_gather_and_fade_meshes(occluder, active_mesh_instances)

	# Reset linger time for actively occluding meshes
	for mesh_inst in active_mesh_instances:
		mesh_linger[mesh_inst] = FADE_LINGER_TIME

	# Update linger timers and restore meshes that have cleared occlusion
	var to_restore: Array[MeshInstance3D] = []
	var dead_keys: Array = []
	for mesh_inst in faded_meshes.keys():
		if not is_instance_valid(mesh_inst):
			dead_keys.append(mesh_inst)
			continue
		if not active_mesh_instances.has(mesh_inst):
			var rem = mesh_linger.get(mesh_inst, 0.0) - delta
			if rem <= 0.0:
				to_restore.append(mesh_inst)
			else:
				mesh_linger[mesh_inst] = rem

	for k in dead_keys:
		faded_meshes.erase(k)
		mesh_linger.erase(k)

	for mesh_inst in to_restore:
		_restore_mesh(mesh_inst)

func _gather_and_fade_meshes(node: Node, active_list: Array[MeshInstance3D]) -> void:
	if not is_instance_valid(node):
		return

	# If this is a pier of an individual arch, check arch parent only (never group barriers)
	var search_nodes = [node]
	if node.get_parent() and "Arch" in node.get_parent().name:
		search_nodes.append(node.get_parent())

	for s_node in search_nodes:
		var meshes = s_node.find_children("*", "MeshInstance3D", true, false)
		if s_node is MeshInstance3D and not meshes.has(s_node):
			meshes.append(s_node)

		for m in meshes:
			var mesh_inst = m as MeshInstance3D
			if not mesh_inst or not is_instance_valid(mesh_inst):
				continue
			active_list.append(mesh_inst)
			if not faded_meshes.has(mesh_inst):
				_fade_mesh(mesh_inst)

func _fade_mesh(mesh_inst: MeshInstance3D) -> void:
	var orig_mat = mesh_inst.material_override
	if not orig_mat and mesh_inst.mesh:
		orig_mat = mesh_inst.mesh.material

	faded_meshes[mesh_inst] = orig_mat
	mesh_linger[mesh_inst] = FADE_LINGER_TIME

	if orig_mat and orig_mat is StandardMaterial3D:
		var fade_mat = orig_mat.duplicate() as StandardMaterial3D
		fade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fade_mat.albedo_color.a = target_alpha
		mesh_inst.material_override = fade_mat
	else:
		var fade_mat = StandardMaterial3D.new()
		fade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fade_mat.albedo_color = Color(0.2, 0.2, 0.25, target_alpha)
		mesh_inst.material_override = fade_mat

func _restore_mesh(mesh_inst: MeshInstance3D) -> void:
	if is_instance_valid(mesh_inst):
		var orig_mat = faded_meshes.get(mesh_inst, null)
		mesh_inst.material_override = orig_mat
	faded_meshes.erase(mesh_inst)
	mesh_linger.erase(mesh_inst)

func cleanup() -> void:
	for mesh_inst in faded_meshes.keys():
		_restore_mesh(mesh_inst)
	faded_meshes.clear()
	mesh_linger.clear()
