class_name LevelEditorRoomManager
extends RefCounted

const TILE_SIZE: float = 2.0

signal rooms_updated
signal active_room_changed(new_name: String)

var builder: Node3D
var model: RefCounted
var history: RefCounted

var active_room_name: String = "The Great Hall"
var paint_mode: String = "brush" # "brush", "box", "erase"
var is_walls_only: bool = false
var hidden_nodes: Array[Node3D] = []

var overlay_root: Node3D
var overlay_instances: Dictionary = {} # Vector2i -> MeshInstance3D

var palette_colors: Array[Color] = [
	Color(0.2, 0.45, 0.95, 0.45), # Royal Blue
	Color(0.15, 0.75, 0.35, 0.45), # Emerald Green
	Color(0.9, 0.25, 0.25, 0.45), # Crimson Red
	Color(0.68, 0.28, 0.88, 0.45), # Amethyst Purple
	Color(0.95, 0.72, 0.15, 0.45), # Amber Gold
	Color(0.12, 0.8, 0.8, 0.45), # Teal Cyan
	Color(0.95, 0.45, 0.2, 0.45), # Coral Orange
	Color(0.92, 0.38, 0.62, 0.45), # Rose Pink
	Color(0.38, 0.28, 0.85, 0.45), # Indigo
	Color(0.65, 0.85, 0.22, 0.45) # Lime
]
var room_colors: Dictionary = {}

func _init(p_builder: Node3D, p_model: RefCounted, p_history: RefCounted) -> void:
	builder = p_builder
	model = p_model
	history = p_history

	overlay_root = Node3D.new()
	overlay_root.name = "EditorRoomOverlays"
	overlay_root.visible = false
	builder.add_child(overlay_root)

	_init_room_colors()

func _init_room_colors() -> void:
	var summary = get_room_summary()
	for i in range(summary.size()):
		var r_name = summary[i]["name"]
		if not room_colors.has(r_name):
			room_colors[r_name] = palette_colors[i % palette_colors.size()]

func get_room_color(r_name: String) -> Color:
	if not room_colors.has(r_name):
		var next_idx = room_colors.size() % palette_colors.size()
		room_colors[r_name] = palette_colors[next_idx]
	return room_colors[r_name]

func cycle_room_color(r_name: String) -> Color:
	var cur = get_room_color(r_name)
	var cur_idx = palette_colors.find(cur)
	var next_idx = (cur_idx + 1) % palette_colors.size() if cur_idx >= 0 else 0
	room_colors[r_name] = palette_colors[next_idx]
	refresh_overlays()
	rooms_updated.emit()
	return room_colors[r_name]

func set_active_room(r_name: String) -> void:
	active_room_name = r_name
	get_room_color(r_name) # Ensure color allocated
	active_room_changed.emit(active_room_name)

func is_wall_node(node: Node) -> bool:
	if not (node is Node3D):
		return false
	var n = node.name.to_lower()
	if "wall" in n or "tower" in n or "arch" in n or "portal" in n or "gate" in n or "pier" in n or "window" in n:
		return true
	if node is StaticBody3D:
		for c in node.get_children():
			if c is CollisionShape3D and c.shape is BoxShape3D:
				if c.shape.size.y >= 2.0:
					return true
	return false

func set_walls_only_visible(active: bool) -> void:
	is_walls_only = active
	if active:
		hidden_nodes.clear()
		for child in builder.get_children():
			if child == overlay_root:
				continue
			_filter_visibility_recursive(child)
		overlay_root.visible = true
		refresh_overlays()
	else:
		for n in hidden_nodes:
			if is_instance_valid(n):
				n.visible = true
		hidden_nodes.clear()
		overlay_root.visible = false

func _filter_visibility_recursive(node: Node) -> void:
	if is_wall_node(node):
		node.visible = true
		return
	if node is MeshInstance3D or node is Light3D or node is Area3D:
		if node.visible:
			node.visible = false
			hidden_nodes.append(node)
		return
	var is_leaf_object = false
	if node is StaticBody3D or node.get_child_count() == 0:
		is_leaf_object = true
	elif not ("room" in node.name.to_lower() or "hall" in node.name.to_lower() or "corridor" in node.name.to_lower() or "custom" in node.name.to_lower() or "ground" in node.name.to_lower()):
		is_leaf_object = true

	if is_leaf_object and not is_wall_node(node):
		if node.visible:
			node.visible = false
			hidden_nodes.append(node)
		return

	for c in node.get_children():
		_filter_visibility_recursive(c)

func refresh_overlays() -> void:
	_clear_overlays()
	if not builder or not builder.grid:
		return
	for cell in builder.grid.keys():
		var z = str(builder.grid[cell].get("zone", ""))
		if z.is_empty() or z in ["Castle Walls", "Perimeter", "Outside the Castle"]:
			continue
		_create_overlay_quad(cell, z)

func _clear_overlays() -> void:
	for inst in overlay_instances.values():
		if is_instance_valid(inst):
			inst.queue_free()
	overlay_instances.clear()

func _create_overlay_quad(cell: Vector2i, r_name: String) -> void:
	var col = get_room_color(r_name)
	var m_inst = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(1.9, 0.02, 1.9)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_inst.mesh = b_mesh
	m_inst.material_override = mat
	m_inst.position = builder.grid_to_world(cell) + Vector3(0.0, 0.025, 0.0)
	overlay_root.add_child(m_inst)
	overlay_instances[cell] = m_inst

func paint_cells(cells: Array[Vector2i], r_name: String) -> void:
	if r_name.is_empty():
		return
	var valid_cells: Array[Vector2i] = []
	for c in cells:
		if not model.is_wall_at(c):
			valid_cells.append(c)
	if valid_cells.is_empty():
		return

	var before = model.capture_cell_states(valid_cells)
	for c in valid_cells:
		if not builder.grid.has(c):
			model.set_floor(c, "stone", 1, true)
			if is_walls_only and model.cell_data.has(c):
				for node in model.cell_data[c].get("nodes", []):
					if is_instance_valid(node) and not is_wall_node(node):
						node.visible = false
						hidden_nodes.append(node)
		model.set_cell_zone(c, r_name)

	var after = model.capture_cell_states(valid_cells)
	history.record_action("Paint Room: %s (%d tiles)" % [r_name, valid_cells.size()], before, after)
	get_room_color(r_name)
	refresh_overlays()
	rooms_updated.emit()

func erase_cells(cells: Array[Vector2i]) -> void:
	var valid_cells: Array[Vector2i] = []
	for c in cells:
		if not model.is_wall_at(c) and builder.grid.has(c):
			valid_cells.append(c)
	if valid_cells.is_empty():
		return

	var before = model.capture_cell_states(valid_cells)
	for c in valid_cells:
		model.set_cell_zone(c, "Custom")
	var after = model.capture_cell_states(valid_cells)
	history.record_action("Erase Room Tiles (%d tiles)" % valid_cells.size(), before, after)
	refresh_overlays()
	rooms_updated.emit()

func rename_room(old_name: String, new_name: String) -> void:
	if old_name.is_empty() or new_name.is_empty() or old_name == new_name:
		return
	var matching_cells: Array[Vector2i] = []
	for c in builder.grid.keys():
		if str(builder.grid[c].get("zone", "")) == old_name:
			matching_cells.append(c)

	var before = model.capture_cell_states(matching_cells)
	for c in matching_cells:
		model.set_cell_zone(c, new_name)
	var after = model.capture_cell_states(matching_cells)
	history.record_action("Rename Room '%s' -> '%s'" % [old_name, new_name], before, after)

	if room_colors.has(old_name):
		room_colors[new_name] = room_colors[old_name]
		room_colors.erase(old_name)
	if active_room_name == old_name:
		set_active_room(new_name)
	refresh_overlays()
	rooms_updated.emit()

func delete_room(r_name: String) -> void:
	var matching_cells: Array[Vector2i] = []
	for c in builder.grid.keys():
		if str(builder.grid[c].get("zone", "")) == r_name:
			matching_cells.append(c)
	if not matching_cells.is_empty():
		erase_cells(matching_cells)
	room_colors.erase(r_name)
	if active_room_name == r_name:
		set_active_room("The Great Hall")
	refresh_overlays()
	rooms_updated.emit()

func get_room_summary() -> Array[Dictionary]:
	var counts: Dictionary = {}
	if builder and builder.grid:
		for c in builder.grid.keys():
			var z = str(builder.grid[c].get("zone", ""))
			if z.is_empty() or z in ["Castle Walls", "Perimeter", "Outside the Castle", "Custom"]:
				continue
			counts[z] = counts.get(z, 0) + 1

	var list: Array[Dictionary] = []
	for r_name in counts.keys():
		list.append({
			"name": r_name,
			"color": get_room_color(r_name),
			"count": counts[r_name]
		})
	list.sort_custom(func(a, b): return a["count"] > b["count"])
	return list
