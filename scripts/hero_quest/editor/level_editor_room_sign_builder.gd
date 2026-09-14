class_name LevelEditorRoomSignBuilder
extends RefCounted

const TILE_SIZE: float = 2.0

static func calculate_room_center_cell(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	for c in cells:
		sum_x += float(c.x)
		sum_y += float(c.y)
	var avg = Vector2(sum_x / float(cells.size()), sum_y / float(cells.size()))

	# Snap to nearest actual cell within the room to prevent signs inside holes/gaps
	var best_cell: Vector2i = cells[0]
	var best_dist_sq: float = INF
	for c in cells:
		var d = avg.distance_squared_to(Vector2(c.x, c.y))
		if d < best_dist_sq:
			best_dist_sq = d
			best_cell = c
	return best_cell

static func create_room_sign(r_name: String, world_pos: Vector3, color: Color, is_active: bool = false) -> Node3D:
	var sign_root = Node3D.new()
	sign_root.name = "RoomSign_%s" % r_name.validate_node_name()
	sign_root.position = world_pos

	# 1. Wooden Ground Post (floor y=0 to y=1.6m)
	var post_mesh = BoxMesh.new()
	post_mesh.size = Vector3(0.12, 1.6, 0.12)
	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.22, 0.15, 0.09)
	post_mat.roughness = 0.85

	var post_inst = MeshInstance3D.new()
	post_inst.name = "Post"
	post_inst.mesh = post_mesh
	post_inst.material_override = post_mat
	post_inst.position = Vector3(0.0, 0.8, 0.0)
	sign_root.add_child(post_inst)

	# 2. Hanging Crossbeam Bracket
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(0.5, 0.08, 0.14)
	var beam_inst = MeshInstance3D.new()
	beam_inst.name = "Bracket"
	beam_inst.mesh = beam_mesh
	beam_inst.material_override = post_mat
	beam_inst.position = Vector3(0.0, 1.56, 0.0)
	sign_root.add_child(beam_inst)

	# 3. Signboard Pivot (billboarded with Label3D so text and board face camera upright)
	var placard_pivot = Node3D.new()
	placard_pivot.name = "PlacardPivot"
	placard_pivot.position = Vector3(0.0, 1.82, 0.0)
	sign_root.add_child(placard_pivot)

	# 4. Signboard Backing Placard
	var board_width = clampf(float(r_name.length()) * 0.10 + 0.55, 1.3, 3.2)
	var board_mesh = BoxMesh.new()
	board_mesh.size = Vector3(board_width, 0.52, 0.06)

	var board_mat = StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.14, 0.10, 0.08, 0.95)
	board_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	board_mat.roughness = 0.7
	board_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	board_mat.render_priority = 3

	var board_inst = MeshInstance3D.new()
	board_inst.name = "Board"
	board_inst.mesh = board_mesh
	board_inst.material_override = board_mat
	placard_pivot.add_child(board_inst)

	# 5. Colored Border Trim Frame
	var trim_mesh = BoxMesh.new()
	trim_mesh.size = Vector3(board_width + 0.06, 0.56, 0.04)
	var trim_mat = StandardMaterial3D.new()
	trim_mat.albedo_color = color
	trim_mat.emission_enabled = is_active
	trim_mat.emission = color * 0.5 if is_active else Color.BLACK
	trim_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	trim_mat.render_priority = 2

	var trim_inst = MeshInstance3D.new()
	trim_inst.name = "Trim"
	trim_inst.mesh = trim_mesh
	trim_inst.material_override = trim_mat
	placard_pivot.add_child(trim_inst)

	# 6. Room Name Label3D
	var label = Label3D.new()
	label.name = "Label"
	label.text = r_name
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.pixel_size = 0.0055
	label.font_size = 28
	label.outline_size = 7
	label.outline_modulate = Color(0.06, 0.04, 0.02, 1.0)
	label.modulate = Color(1.0, 0.92, 0.35) if is_active else Color(0.96, 0.94, 0.9)
	label.render_priority = 4
	label.no_depth_test = false
	label.position = Vector3(0.0, 0.0, 0.04)
	placard_pivot.add_child(label)

	return sign_root
