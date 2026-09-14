class_name CastleMeshBuilder
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

const TILE_SIZE: float = 2.0

var materials: CastleMaterials
var grid_to_world_fn: Callable
var register_tile_fn: Callable
var floor_cells: Dictionary = {}

func _init(p_materials: CastleMaterials, p_grid_to_world: Callable, p_register_tile: Callable) -> void:
	materials = p_materials
	grid_to_world_fn = p_grid_to_world
	register_tile_fn = p_register_tile

func clear_cache() -> void:
	floor_cells.clear()

func create_square_tile_mesh(parent: Node3D, cell: Vector2i, mat: Material) -> StaticBody3D:
	floor_cells[cell] = true
	var body = StaticBody3D.new()
	body.position = grid_to_world_fn.call(cell)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(TILE_SIZE, 0.3, TILE_SIZE)
	col.shape = shape
	col.position = Vector3(0, -0.15, 0)
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(TILE_SIZE - 0.08, 0.28, TILE_SIZE - 0.08)
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0, -0.14, 0)
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body

func create_wall_segment(parent: Node3D, cell: Vector2i, height: float = 4.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = grid_to_world_fn.call(cell) + Vector3(0, height * 0.5, 0)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(TILE_SIZE, height, TILE_SIZE)
	col.shape = shape
	body.add_child(col)

	var plinth_h = 0.45
	var cornice_h = 0.35
	var wall_body_h = height - plinth_h - cornice_h

	# Base plinth trim (sits strictly from bottom y=0 to y=plinth_h)
	var plinth = MeshInstance3D.new()
	var plinth_mesh = BoxMesh.new()
	plinth_mesh.size = Vector3(TILE_SIZE, plinth_h, TILE_SIZE)
	plinth_mesh.material = materials.mat_wall_trim
	plinth.mesh = plinth_mesh
	plinth.position = Vector3(0, -height * 0.5 + plinth_h * 0.5, 0)
	body.add_child(plinth)

	# Main wall block (sits strictly between plinth and cornice, zero Z-fighting)
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(TILE_SIZE, wall_body_h, TILE_SIZE)
	box_mesh.material = materials.mat_wall_stone
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0, -height * 0.5 + plinth_h + wall_body_h * 0.5, 0)
	body.add_child(mesh_inst)

	# Top coping cornice (sits strictly on top of wall body)
	var cornice = MeshInstance3D.new()
	var cornice_mesh = BoxMesh.new()
	cornice_mesh.size = Vector3(TILE_SIZE, cornice_h, TILE_SIZE)
	cornice_mesh.material = materials.mat_wall_trim
	cornice.mesh = cornice_mesh
	cornice.position = Vector3(0, height * 0.5 - cornice_h * 0.5, 0)
	body.add_child(cornice)

	# Alternating ashlar stone relief blocks on side faces (strictly on middle body)
	var relief1 = MeshInstance3D.new()
	var r1_mesh = BoxMesh.new()
	r1_mesh.size = Vector3(0.55, 0.32, 0.08)
	r1_mesh.material = materials.mat_wall_trim
	relief1.mesh = r1_mesh
	relief1.position = Vector3(-0.35, -0.2, TILE_SIZE * 0.5 + 0.02)
	body.add_child(relief1)

	var relief2 = MeshInstance3D.new()
	var r2_mesh = BoxMesh.new()
	r2_mesh.size = Vector3(0.08, 0.32, 0.5)
	r2_mesh.material = materials.mat_wall_trim
	relief2.mesh = r2_mesh
	relief2.position = Vector3(TILE_SIZE * 0.5 + 0.02, 0.5, 0.2)
	body.add_child(relief2)

	parent.add_child(body)
	return body

func create_arch_pier(parent: Node3D, cell: Vector2i, height: float = 3.6, extend_dir: Vector2i = Vector2i.ZERO) -> StaticBody3D:
	if not floor_cells.has(cell):
		create_square_tile_mesh(parent, cell, materials.mat_floor_stone)

	if register_tile_fn.is_valid():
		register_tile_fn.call(cell, 6, false, "Arch Pier") # 6 = TileType.WALL

	var body = StaticBody3D.new()
	body.position = grid_to_world_fn.call(cell) + Vector3(0, height * 0.5, 0)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(TILE_SIZE, height, TILE_SIZE)
	col.shape = shape
	body.add_child(col)

	var ext_x = absi(extend_dir.x)
	var ext_z = absi(extend_dir.y)

	var base_size_x = 1.2 + (0.4 if ext_x else 0.0)
	var base_size_z = 1.2 + (0.4 if ext_z else 0.0)
	var base_offset_x = extend_dir.x * 0.2
	var base_offset_z = extend_dir.y * 0.2

	var shaft_size_x = 0.9 + (0.55 if ext_x else 0.0)
	var shaft_size_z = 0.9 + (0.55 if ext_z else 0.0)
	var shaft_offset_x = extend_dir.x * 0.275
	var shaft_offset_z = extend_dir.y * 0.275

	var cap_size_x = 1.15 + (0.425 if ext_x else 0.0)
	var cap_size_z = 1.15 + (0.425 if ext_z else 0.0)
	var cap_offset_x = extend_dir.x * 0.2125
	var cap_offset_z = extend_dir.y * 0.2125

	# Plinth Base (widened seamlessly if extending to wall)
	var base = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(base_size_x, 0.45, base_size_z)
	b_box.material = materials.mat_wall_stone
	base.mesh = b_box
	base.position = Vector3(base_offset_x, -height * 0.5 + 0.225, base_offset_z)
	body.add_child(base)

	# Column Shaft (single wider column piece, zero separate objects)
	var shaft = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(shaft_size_x, height - 0.9, shaft_size_z)
	s_box.material = materials.mat_wall_trim
	shaft.mesh = s_box
	shaft.position = Vector3(shaft_offset_x, 0, shaft_offset_z)
	body.add_child(shaft)

	# Capital (widened seamlessly if extending to wall)
	var cap = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(cap_size_x, 0.45, cap_size_z)
	c_box.material = materials.mat_wall_stone
	cap.mesh = c_box
	cap.position = Vector3(cap_offset_x, height * 0.5 - 0.225, cap_offset_z)
	body.add_child(cap)

	parent.add_child(body)
	return body

func create_curved_arch_mesh(parent: Node3D, center_pos: Vector3, span: float, spring_height: float, axis: int, thickness: float = 0.8) -> Node3D:
	var arch = Node3D.new()
	arch.position = center_pos
	parent.add_child(arch)

	var radius = span * 0.5
	var segments = 32 # At least 32 segments/dots for true round arch shape
	var seg_angle = PI / float(segments)
	var seg_len = 2.0 * radius * sin(seg_angle * 0.5) * 1.08

	for i in range(segments):
		var mid_a = (i + 0.5) * seg_angle
		var stone = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()

		if axis == 0: # ArchAxis.ALONG_X
			b_mesh.size = Vector3(seg_len, 0.38, thickness)
			stone.mesh = b_mesh
			stone.material_override = materials.mat_wall_trim
			var px = -cos(mid_a) * radius
			var py = spring_height + sin(mid_a) * (radius * 0.88)
			stone.position = Vector3(px, py, 0)
			stone.rotation.z = mid_a - PI * 0.5
		else: # ALONG_Z
			b_mesh.size = Vector3(thickness, 0.38, seg_len)
			stone.mesh = b_mesh
			stone.material_override = materials.mat_wall_trim
			var pz = -cos(mid_a) * radius
			var py = spring_height + sin(mid_a) * (radius * 0.88)
			stone.position = Vector3(0, py, pz)
			stone.rotation.x = -(mid_a - PI * 0.5)

		arch.add_child(stone)

	# Draw smooth contour lines with 32 segments along inner & outer edges
	_draw_arch_moulding_lines(arch, radius, spring_height, axis, thickness)

	# Keystone at the top apex
	var keystone = MeshInstance3D.new()
	var k_box = BoxMesh.new()
	if axis == 0:
		k_box.size = Vector3(0.45, 0.55, thickness + 0.12)
	else:
		k_box.size = Vector3(thickness + 0.12, 0.55, 0.45)
	keystone.position = Vector3(0, spring_height + radius * 0.88 + 0.05, 0)
	k_box.material = materials.mat_wall_stone
	keystone.mesh = k_box
	arch.add_child(keystone)

	return arch

func _draw_arch_moulding_lines(arch: Node3D, radius: float, spring_height: float, axis: int, thickness: float) -> void:
	var num_dots = 32
	var inner_r = radius - 0.18
	var outer_r = radius + 0.18
	var half_t = thickness * 0.5 + 0.01

	for side in [-half_t, half_t]:
		for r in [inner_r, outer_r]:
			var line_mesh = ImmediateMesh.new()
			line_mesh.clear_surfaces()
			line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, materials.mat_wall_trim)
			for d in range(num_dots + 1):
				var a = float(d) / float(num_dots) * PI
				var py = spring_height + sin(a) * (r * 0.88)
				var px_or_z = -cos(a) * r
				if axis == 0:
					line_mesh.surface_add_vertex(Vector3(px_or_z, py, side))
				else:
					line_mesh.surface_add_vertex(Vector3(side, py, px_or_z))
			line_mesh.surface_end()

			var line_inst = MeshInstance3D.new()
			line_inst.mesh = line_mesh
			arch.add_child(line_inst)

func create_gothic_window(parent: Node3D, pos: Vector3, wall_normal: Vector3) -> Node3D:
	var win = Node3D.new()
	win.position = pos
	var angle = atan2(wall_normal.x, wall_normal.z)
	win.rotation.y = angle

	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(1.3, 2.2, 0.25)
	f_mesh.material = materials.mat_wall_trim
	frame.mesh = f_mesh
	win.add_child(frame)

	var arch_top = MeshInstance3D.new()
	var at_mesh = PrismMesh.new()
	at_mesh.size = Vector3(1.3, 0.7, 0.25)
	at_mesh.material = materials.mat_wall_trim
	arch_top.mesh = at_mesh
	arch_top.position = Vector3(0, 1.35, 0)
	win.add_child(arch_top)

	var glass = MeshInstance3D.new()
	var g_mesh = BoxMesh.new()
	g_mesh.size = Vector3(0.95, 1.8, 0.08)
	g_mesh.material = materials.mat_window_glass
	glass.mesh = g_mesh
	glass.position = Vector3(0, 0, 0.05)
	win.add_child(glass)

	var mullion = MeshInstance3D.new()
	var m_mesh = BoxMesh.new()
	m_mesh.size = Vector3(0.08, 1.8, 0.1)
	m_mesh.material = materials.mat_iron
	mullion.mesh = m_mesh
	mullion.position = Vector3(0, 0, 0.06)
	win.add_child(mullion)

	var light = OmniLight3D.new()
	light.light_color = Color(0.7, 0.85, 1.0)
	light.light_energy = 1.2
	light.omni_range = 5.5
	light.position = Vector3(0, 0.4, 0.3)
	win.add_child(light)

	parent.add_child(win)
	return win

func build_arch_3tile(parent: Node3D, open_cell: Vector2i, axis: int, arch_name: String = "") -> Node3D:
	var offset = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var left_pier = open_cell - offset
	var right_pier = open_cell + offset

	create_arch_pier(parent, left_pier, 3.6, -offset)
	create_arch_pier(parent, right_pier, 3.6, offset)

	var center_world = grid_to_world_fn.call(open_cell)
	var arch = create_curved_arch_mesh(parent, center_world, TILE_SIZE * 2.0, 3.6, axis, 0.9)
	if arch_name != "":
		arch.name = arch_name
	return arch

func build_arch_4tile(parent: Node3D, open_1: Vector2i, open_2: Vector2i, axis: int, arch_name: String = "") -> Node3D:
	var offset = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var left_pier = open_1 - offset
	var right_pier = open_2 + offset

	create_arch_pier(parent, left_pier, 3.6, -offset)
	create_arch_pier(parent, right_pier, 3.6, offset)

	var center_world = (grid_to_world_fn.call(open_1) + grid_to_world_fn.call(open_2)) * 0.5
	var arch = create_curved_arch_mesh(parent, center_world, TILE_SIZE * 3.0, 3.6, axis, 0.9)
	if arch_name != "":
		arch.name = arch_name
	return arch

func build_arch_5tile_twin(parent: Node3D, center_pier_cell: Vector2i, axis: int, arch_name: String = "") -> Node3D:
	var offset = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var left_pier = center_pier_cell - offset * 2
	var left_open = center_pier_cell - offset
	var right_open = center_pier_cell + offset
	var right_pier = center_pier_cell + offset * 2

	create_arch_pier(parent, left_pier, 3.6, -offset)
	create_arch_pier(parent, center_pier_cell, 3.6, Vector2i.ZERO)
	create_arch_pier(parent, right_pier, 3.6, offset)

	var group = Node3D.new()
	if arch_name != "":
		group.name = arch_name
	parent.add_child(group)

	var left_center = grid_to_world_fn.call(left_open)
	create_curved_arch_mesh(group, left_center, TILE_SIZE * 2.0, 3.6, axis, 0.9)

	var right_center = grid_to_world_fn.call(right_open)
	create_curved_arch_mesh(group, right_center, TILE_SIZE * 2.0, 3.6, axis, 0.9)
	return group

func build_arch_spanning_3tiles(parent: Node3D, center_cell: Vector2i, axis: int, arch_name: String) -> Node3D:
	var offset = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var left_pier = center_cell - offset * 2
	var right_pier = center_cell + offset * 2

	create_arch_pier(parent, left_pier, 3.6, -offset)
	create_arch_pier(parent, right_pier, 3.6, offset)

	var center_world = grid_to_world_fn.call(center_cell)
	var arch = create_curved_arch_mesh(parent, center_world, TILE_SIZE * 4.0, 3.6, axis, 0.9)
	arch.name = arch_name
	return arch

func create_pillar(parent: Node3D, pos: Vector3, height: float = 4.0) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.9, height, 0.9)
	col.shape = shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, height, 0.9)
	box_mesh.material = materials.mat_wall_trim
	mesh_inst.mesh = box_mesh
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body
