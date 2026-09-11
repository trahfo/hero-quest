class_name CastleWallTileFactory
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

const CastleBrickScatterer = preload("res://scripts/hero_quest/castle_brick_scatterer.gd")

const WALL_THICKNESS: float = 0.9
const TILE_SIZE: float = 2.0

var materials: CastleMaterials
var scatterer: CastleBrickScatterer

func _init(p_materials: CastleMaterials) -> void:
	materials = p_materials
	scatterer = CastleBrickScatterer.new(p_materials)

func create_straight_wall_x(parent: Node3D, pos: Vector3, height: float = 4.5) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(TILE_SIZE, height, WALL_THICKNESS)
	col.shape = shape
	body.add_child(col)

	var plinth_h = 0.45
	var cornice_h = 0.35
	var body_h = height - plinth_h - cornice_h
	var body_center_y = -height * 0.5 + plinth_h + body_h * 0.5

	_add_box(body, Vector3(TILE_SIZE, plinth_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, -height * 0.5 + plinth_h * 0.5, 0))
	_add_box(body, Vector3(TILE_SIZE, body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(0, body_center_y, 0))
	_add_box(body, Vector3(TILE_SIZE, cornice_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, height * 0.5 - cornice_h * 0.5, 0))

	# Procedural non-overlapping relief ashlar blocks on front (+Z) and back (-Z)
	var seed_val = int(pos.x * 73856093) ^ int(pos.z * 19349663)
	scatterer.scatter_wall_x(body, TILE_SIZE, WALL_THICKNESS, body_h, body_center_y, seed_val)

	parent.add_child(body)
	return body

func create_straight_wall_z(parent: Node3D, pos: Vector3, height: float = 4.5) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(WALL_THICKNESS, height, TILE_SIZE)
	col.shape = shape
	body.add_child(col)

	var plinth_h = 0.45
	var cornice_h = 0.35
	var body_h = height - plinth_h - cornice_h
	var body_center_y = -height * 0.5 + plinth_h + body_h * 0.5

	_add_box(body, Vector3(WALL_THICKNESS, plinth_h, TILE_SIZE), materials.mat_wall_trim, Vector3(0, -height * 0.5 + plinth_h * 0.5, 0))
	_add_box(body, Vector3(WALL_THICKNESS, body_h, TILE_SIZE), materials.mat_wall_stone, Vector3(0, body_center_y, 0))
	_add_box(body, Vector3(WALL_THICKNESS, cornice_h, TILE_SIZE), materials.mat_wall_trim, Vector3(0, height * 0.5 - cornice_h * 0.5, 0))

	# Procedural non-overlapping relief ashlar blocks on right (+X) and left (-X)
	var seed_val = int(pos.x * 73856093) ^ int(pos.z * 19349663)
	scatterer.scatter_wall_z(body, TILE_SIZE, WALL_THICKNESS, body_h, body_center_y, seed_val)

	parent.add_child(body)
	return body

func create_modular_wall(parent: Node3D, pos: Vector3, has_left: bool, has_right: bool, has_up: bool, has_down: bool, height: float = 4.5) -> StaticBody3D:
	if has_left and has_right and not has_up and not has_down:
		return create_straight_wall_x(parent, pos, height)
	if has_up and has_down and not has_left and not has_right:
		return create_straight_wall_z(parent, pos, height)

	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)

	var plinth_h = 0.45
	var cornice_h = 0.35
	var body_h = height - plinth_h - cornice_h

	# Central Pillar
	var col_main = CollisionShape3D.new()
	var shape_main = BoxShape3D.new()
	shape_main.size = Vector3(WALL_THICKNESS, height, WALL_THICKNESS)
	col_main.shape = shape_main
	body.add_child(col_main)

	_add_box(body, Vector3(WALL_THICKNESS, plinth_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, -height * 0.5 + plinth_h * 0.5, 0))
	_add_box(body, Vector3(WALL_THICKNESS, body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(0, -height * 0.5 + plinth_h + body_h * 0.5, 0))
	_add_box(body, Vector3(WALL_THICKNESS, cornice_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, height * 0.5 - cornice_h * 0.5, 0))

	var arm_len = (TILE_SIZE - WALL_THICKNESS) * 0.5 # 0.55m
	var arm_offset = WALL_THICKNESS * 0.5 + arm_len * 0.5 # 0.725m

	if has_left:
		_add_arm_x(body, -arm_offset, arm_len, plinth_h, body_h, cornice_h, height)
	if has_right:
		_add_arm_x(body, arm_offset, arm_len, plinth_h, body_h, cornice_h, height)
	if has_up:
		_add_arm_z(body, -arm_offset, arm_len, plinth_h, body_h, cornice_h, height)
	if has_down:
		_add_arm_z(body, arm_offset, arm_len, plinth_h, body_h, cornice_h, height)

	# Quoins on exterior corner if exactly two perpendicular connections
	var num_conns = int(has_left) + int(has_right) + int(has_up) + int(has_down)
	if num_conns == 2 and ((has_left or has_right) and (has_up or has_down)):
		var q_dir_x = 1 if has_left else -1
		var q_dir_z = 1 if has_up else -1
		var q_x = q_dir_x * (WALL_THICKNESS * 0.5 + 0.02)
		var q_z = q_dir_z * (WALL_THICKNESS * 0.5 + 0.02)
		_add_box(body, Vector3(0.25, 0.35, 0.25), materials.mat_wall_trim, Vector3(q_x, -0.6, q_z))
		_add_box(body, Vector3(0.25, 0.35, 0.25), materials.mat_wall_trim, Vector3(q_x, 0.4, q_z))

	parent.add_child(body)
	return body

func _add_arm_x(body: StaticBody3D, x_pos: float, len_x: float, plinth_h: float, body_h: float, cornice_h: float, height: float) -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(len_x, height, WALL_THICKNESS)
	col.shape = shape
	col.position = Vector3(x_pos, 0, 0)
	body.add_child(col)

	_add_box(body, Vector3(len_x, plinth_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(x_pos, -height * 0.5 + plinth_h * 0.5, 0))
	_add_box(body, Vector3(len_x, body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(x_pos, -height * 0.5 + plinth_h + body_h * 0.5, 0))
	_add_box(body, Vector3(len_x, cornice_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(x_pos, height * 0.5 - cornice_h * 0.5, 0))

func _add_arm_z(body: StaticBody3D, z_pos: float, len_z: float, plinth_h: float, body_h: float, cornice_h: float, height: float) -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(WALL_THICKNESS, height, len_z)
	col.shape = shape
	col.position = Vector3(0, 0, z_pos)
	body.add_child(col)

	_add_box(body, Vector3(WALL_THICKNESS, plinth_h, len_z), materials.mat_wall_trim, Vector3(0, -height * 0.5 + plinth_h * 0.5, z_pos))
	_add_box(body, Vector3(WALL_THICKNESS, body_h, len_z), materials.mat_wall_stone, Vector3(0, -height * 0.5 + plinth_h + body_h * 0.5, z_pos))
	_add_box(body, Vector3(WALL_THICKNESS, cornice_h, len_z), materials.mat_wall_trim, Vector3(0, height * 0.5 - cornice_h * 0.5, z_pos))

func create_window_wall(parent: Node3D, pos: Vector3, wall_normal: Vector3, height: float = 4.5) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)
	var angle = atan2(wall_normal.x, wall_normal.z)
	body.rotation.y = angle

	var plinth_h = 0.45
	var cornice_h = 0.35
	var sill_h = 1.25 # Lower wall under window
	var lintel_h = 0.85 # Upper wall over window
	var window_opening_w = 1.0
	var jamb_w = (TILE_SIZE - window_opening_w) * 0.5 # 0.5m each side
	var jamb_body_h = height - plinth_h - cornice_h
	var lintel_body_h = lintel_h - cornice_h

	# Single unified base plinth across entire tile width (zero z-fighting)
	_add_box(body, Vector3(TILE_SIZE, plinth_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, -height * 0.5 + plinth_h * 0.5, 0))

	# Single unified top coping cornice across entire tile width (zero z-fighting)
	_add_box(body, Vector3(TILE_SIZE, cornice_h, WALL_THICKNESS), materials.mat_wall_trim, Vector3(0, height * 0.5 - cornice_h * 0.5, 0))

	# Left Jamb Pillar Body
	_add_box(body, Vector3(jamb_w, jamb_body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(-0.75, -height * 0.5 + plinth_h + jamb_body_h * 0.5, 0))

	# Right Jamb Pillar Body
	_add_box(body, Vector3(jamb_w, jamb_body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(0.75, -height * 0.5 + plinth_h + jamb_body_h * 0.5, 0))

	# Bottom Wall Sill Body (strictly sits between plinth and window sill shelf)
	var sill_body_h = sill_h - plinth_h
	_add_box(body, Vector3(window_opening_w, sill_body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(0, -height * 0.5 + plinth_h + sill_body_h * 0.5, 0))
	# Chamfered stone windowsill ledge protruding slightly into room
	_add_box(body, Vector3(window_opening_w + 0.1, 0.1, WALL_THICKNESS + 0.1), materials.mat_wall_trim, Vector3(0, -height * 0.5 + sill_h, 0.03))

	# Top Lintel Body (strictly sits below top cornice, zero overlap!)
	_add_box(body, Vector3(window_opening_w, lintel_body_h, WALL_THICKNESS), materials.mat_wall_stone, Vector3(0, height * 0.5 - cornice_h - lintel_body_h * 0.5, 0))

	# Corner Reveals for the Window Embrasure (Angled / stepped inner corners)
	_add_box(body, Vector3(0.16, 2.0, 0.22), materials.mat_wall_trim, Vector3(-0.42, 0.1, 0.28))
	_add_box(body, Vector3(0.16, 2.0, 0.22), materials.mat_wall_trim, Vector3(0.42, 0.1, 0.28))

	# Window Frame in opening
	_add_box(body, Vector3(0.92, 1.8, 0.18), materials.mat_wall_trim, Vector3(0, 0.05, 0))
	# Pointed Arch Top (contained within opening, no lintel overlap)
	var arch_top = MeshInstance3D.new()
	var at_mesh = PrismMesh.new()
	at_mesh.size = Vector3(0.92, 0.45, 0.18)
	at_mesh.material = materials.mat_wall_trim
	arch_top.mesh = at_mesh
	arch_top.position = Vector3(0, 1.18, 0)
	body.add_child(arch_top)

	# Stained Glass
	_add_box(body, Vector3(0.72, 1.6, 0.06), materials.mat_window_glass, Vector3(0, 0.1, 0.02))

	# Iron Mullion Cross
	_add_box(body, Vector3(0.06, 1.6, 0.08), materials.mat_iron, Vector3(0, 0.1, 0.03))
	_add_box(body, Vector3(0.72, 0.06, 0.08), materials.mat_iron, Vector3(0, 0.35, 0.03))

	# Cathedral Stained Glass Glow
	var light = OmniLight3D.new()
	light.light_color = Color(0.7, 0.85, 1.0)
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.position = Vector3(0, 0.3, 0.45)
	body.add_child(light)

	# Colliders
	var col_left = CollisionShape3D.new()
	var shape_l = BoxShape3D.new()
	shape_l.size = Vector3(jamb_w, height, WALL_THICKNESS)
	col_left.shape = shape_l
	col_left.position = Vector3(-0.75, 0, 0)
	body.add_child(col_left)

	var col_right = CollisionShape3D.new()
	var shape_r = BoxShape3D.new()
	shape_r.size = Vector3(jamb_w, height, WALL_THICKNESS)
	col_right.shape = shape_r
	col_right.position = Vector3(0.75, 0, 0)
	body.add_child(col_right)

	var col_sill = CollisionShape3D.new()
	var shape_s = BoxShape3D.new()
	shape_s.size = Vector3(window_opening_w, sill_h, WALL_THICKNESS)
	col_sill.shape = shape_s
	col_sill.position = Vector3(0, -height * 0.5 + sill_h * 0.5, 0)
	body.add_child(col_sill)

	parent.add_child(body)
	return body

func _add_box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3) -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	inst.mesh = mesh
	inst.position = pos
	parent.add_child(inst)
	return inst
