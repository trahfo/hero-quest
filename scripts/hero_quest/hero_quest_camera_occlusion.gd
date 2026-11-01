class_name HeroQuestCameraOcclusion
extends Node

## Ghosts geometry between camera and hero: ~40% alpha body + glowing box edges so the
## object is clearly still there. Ray queries only run when the camera/hero actually moved
## (stable state => no per-frame toggling), meshes are cached per collider, and fades are
## animated with a short linger so grazing rays can't make walls/doors blink.

const OcclusionMaterial = preload("res://scripts/hero_quest/hero_quest_occlusion_material.gd")

@export var target_alpha: float = 0.2 # ~20% opaque: very translucent, edges keep it readable

var camera: Camera3D
var player: Node3D
var space_state: PhysicsDirectSpaceState3D

# MeshInstance3D -> original material_override (may be null)
var faded_meshes: Dictionary = {}
# MeshInstance3D -> remaining linger time in seconds
var mesh_linger: Dictionary = {}
# MeshInstance3D -> current ghost amount 0..1 (animated)
var mesh_fade: Dictionary = {}
# MeshInstance3D -> ShaderMaterial (reused across fades; never re-created per frame)
var _ghost_materials: Dictionary = {}
# Collider Node -> Array[MeshInstance3D]
var _mesh_cache: Dictionary = {}

var _active_meshes: Dictionary = {}
var _last_cam_pos: Vector3 = Vector3(INF, INF, INF)
var _last_player_pos: Vector3 = Vector3(INF, INF, INF)

const FADE_LINGER_TIME: float = 0.25
const FADE_IN_TIME: float = 0.16
const FADE_OUT_TIME: float = 0.22
const MOVE_EPSILON_SQ: float = 0.0004 # 2 cm

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
	var moved = cam_pos.distance_squared_to(_last_cam_pos) > MOVE_EPSILON_SQ \
		or p_pos.distance_squared_to(_last_player_pos) > MOVE_EPSILON_SQ
	if moved:
		_last_cam_pos = cam_pos
		_last_player_pos = p_pos
		_refresh_active_occluders(cam_pos, p_pos)

	_advance_fades(delta)

func _refresh_active_occluders(cam_pos: Vector3, p_pos: Vector3) -> void:
	# Test points placed strictly on the hero box volume (avoiding air above head)
	var test_points = [
		p_pos + Vector3(0, 0.25, 0),
		p_pos + Vector3(0, 0.55, 0),
		p_pos + Vector3(0, 0.85, 0),
		p_pos + Vector3(-0.3, 0.55, 0),
		p_pos + Vector3(0.3, 0.55, 0)
	]
	var player_rid = player.get_rid() if player.has_method("get_rid") else RID()
	var occluders: Array[Node] = []

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
			if col and col != player and not occluders.has(col):
				occluders.append(col)

	_active_meshes.clear()
	for occluder in occluders:
		for m in _meshes_for_collider(occluder):
			_active_meshes[m] = true
			if not faded_meshes.has(m):
				_fade_mesh(m)

func _advance_fades(delta: float) -> void:
	var finished: Array = []
	for m in faded_meshes.keys():
		if not is_instance_valid(m):
			finished.append(m)
			continue
		var amount: float = mesh_fade.get(m, 0.0)
		if _active_meshes.has(m):
			mesh_linger[m] = FADE_LINGER_TIME
			amount = minf(1.0, amount + delta / FADE_IN_TIME)
		else:
			var rem: float = mesh_linger.get(m, 0.0) - delta
			mesh_linger[m] = rem
			if rem <= 0.0:
				amount = maxf(0.0, amount - delta / FADE_OUT_TIME)
		mesh_fade[m] = amount
		var mat = _ghost_materials.get(m) as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fade", amount)
		if amount <= 0.0 and not _active_meshes.has(m) and mesh_linger.get(m, 0.0) <= 0.0:
			finished.append(m)

	for m in finished:
		_restore_mesh(m)

func _meshes_for_collider(node: Node) -> Array:
	if not is_instance_valid(node):
		return []
	if _mesh_cache.has(node):
		var cached: Array = _mesh_cache[node]
		var all_valid = true
		for m in cached:
			if not is_instance_valid(m):
				all_valid = false
				break
		if all_valid:
			return cached

	# If this is a pier of an individual arch, include the arch parent (never group barriers)
	var search_nodes = [node]
	if node.get_parent() and "Arch" in node.get_parent().name:
		search_nodes.append(node.get_parent())

	var result: Array = []
	for s_node in search_nodes:
		var meshes = s_node.find_children("*", "MeshInstance3D", true, false)
		if s_node is MeshInstance3D and not meshes.has(s_node):
			meshes.append(s_node)
		for m in meshes:
			if m is MeshInstance3D and is_instance_valid(m) and not result.has(m):
				result.append(m)
	_mesh_cache[node] = result
	return result

func _fade_mesh(mesh_inst: MeshInstance3D) -> void:
	if faded_meshes.has(mesh_inst):
		mesh_linger[mesh_inst] = FADE_LINGER_TIME # already ghosted: never capture our own ghost as "original"
		return
	var orig_override: Material = mesh_inst.material_override
	faded_meshes[mesh_inst] = orig_override
	mesh_linger[mesh_inst] = FADE_LINGER_TIME
	mesh_fade[mesh_inst] = mesh_fade.get(mesh_inst, 0.0)

	var ghost: ShaderMaterial = _ghost_materials.get(mesh_inst)
	if ghost == null:
		var source: Material = orig_override
		if not source:
			source = mesh_inst.get_active_material(0)
		ghost = OcclusionMaterial.create_for(mesh_inst, source, target_alpha)
		_ghost_materials[mesh_inst] = ghost
	ghost.set_shader_parameter("target_alpha", target_alpha)
	mesh_inst.material_override = ghost

func _restore_mesh(mesh_inst) -> void: # untyped: the key may already be freed
	if is_instance_valid(mesh_inst):
		var orig_mat = faded_meshes.get(mesh_inst, null)
		if orig_mat == null or is_instance_valid(orig_mat):
			mesh_inst.material_override = orig_mat
	faded_meshes.erase(mesh_inst)
	mesh_linger.erase(mesh_inst)
	mesh_fade.erase(mesh_inst)
	_active_meshes.erase(mesh_inst)
	if not is_instance_valid(mesh_inst):
		_ghost_materials.erase(mesh_inst)

func cleanup() -> void:
	for mesh_inst in faded_meshes.keys():
		_restore_mesh(mesh_inst)
	faded_meshes.clear()
	mesh_linger.clear()
	mesh_fade.clear()
	_ghost_materials.clear()
	_mesh_cache.clear()
	_active_meshes.clear()
	_last_cam_pos = Vector3(INF, INF, INF)
	_last_player_pos = Vector3(INF, INF, INF)
