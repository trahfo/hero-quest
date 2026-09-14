class_name LevelEditorEraser
extends RefCounted

const LevelEditorWallAutoTiler = preload("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")

var model: RefCounted # LevelEditorModel
var builder: Node3D

func _init(p_model: RefCounted, p_builder: Node3D) -> void:
	model = p_model
	builder = p_builder

func is_floor_node(node: Node) -> bool:
	if not (node is Node3D) or not is_instance_valid(node): return false
	if node is MeshInstance3D and node.position.y < 0.0: return true
	if node is StaticBody3D and node.position.y < 0.2:
		for c in node.get_children():
			if (c is CollisionShape3D or c is MeshInstance3D) and c.position.y > 0.05: return false
		return true
	return false

func is_wall_node(node: Node) -> bool:
	if not (node is Node3D) or not is_instance_valid(node): return false
	var n_name = node.name
	if n_name.contains("Wall") or n_name.contains("Window") or n_name.contains("Barrier") or n_name.contains("Tower"):
		return true
	if node is StaticBody3D:
		for c in node.get_children():
			if c is CollisionShape3D and c.shape is BoxShape3D and c.shape.size.y >= 2.0:
				return true
	return false

func free_object_nodes_at_cell(cell: Vector2i, keep_floor: bool = true, keep_wall: bool = false) -> void:
	if model.cell_data.has(cell):
		var remaining: Array[Node3D] = []
		for node in model.cell_data[cell].get("nodes", []):
			if is_instance_valid(node):
				if (keep_floor and is_floor_node(node)) or (keep_wall and is_wall_node(node)):
					remaining.append(node)
				else:
					if builder and node in builder.interactive_chests: builder.interactive_chests.erase(node)
					node.queue_free()
		model.cell_data[cell]["nodes"] = remaining

	if builder:
		var target_global = builder.to_global(builder.grid_to_world(cell))
		find_and_free_spatial_nodes(builder, target_global, keep_floor, keep_wall)

func find_and_free_spatial_nodes(parent: Node, target_global: Vector3, keep_floor: bool, keep_wall: bool = false) -> void:
	if not is_instance_valid(parent): return
	if parent == builder:
		for room in builder.get_children():
			if room is Node3D and is_instance_valid(room) and not room.name.begins_with("LevelEditor") and room.name != "EditorGrid":
				find_and_free_spatial_nodes(room, target_global, keep_floor, keep_wall)
		return

	for child in parent.get_children():
		if not (child is Node3D) or not is_instance_valid(child) or child.name.begins_with("LevelEditor"): continue
		var dist = Vector2(child.global_position.x - target_global.x, child.global_position.z - target_global.z).length()
		var is_arch_node = (child.name.contains("Arch") or child.name.contains("Portal") or child.name.contains("Door") or child.name.contains("Pier") or child.name.contains("Spanning") or child.name.contains("Gate"))
		var max_dist = 5.0 if is_arch_node else 0.65
		if dist < max_dist:
			if keep_floor and is_floor_node(child): continue
			if keep_wall and is_wall_node(child): continue
			if builder and child in builder.interactive_chests: builder.interactive_chests.erase(child)
			child.queue_free()
		elif child.get_child_count() > 0 and not (child is MeshInstance3D) and not (child is StaticBody3D):
			find_and_free_spatial_nodes(child, target_global, keep_floor, keep_wall)

func erase_floor_only(cell: Vector2i) -> bool:
	if not (builder and builder.grid.has(cell)) and not model.cell_data.has(cell):
		return false
	erase_cell(cell)
	return true

func erase_wall_only(cell: Vector2i) -> bool:
	if not model.is_wall_at(cell): return false
	if model.cell_data.has(cell) and model.cell_data[cell].get("wall") != null:
		model.cell_data[cell]["wall"] = null
	free_object_nodes_at_cell(cell, true)
	model.set_floor(cell, "stone", 1, true)
	return true

func erase_window_only(cell: Vector2i) -> bool:
	var is_custom_win = model.cell_data.has(cell) and model.cell_data[cell].get("wall") != null and model.cell_data[cell]["wall"].get("type") == "window"
	var is_grid_wall = builder and builder.grid.has(cell) and builder.grid[cell].get("type") == 6
	if not is_custom_win and not is_grid_wall: return false
	if model.cell_data.has(cell) and model.cell_data[cell].get("wall") != null:
		model.cell_data[cell]["wall"] = null
	free_object_nodes_at_cell(cell, true)
	model.set_floor(cell, "stone", 1, true)
	return true

func erase_arch_or_door_structure(cell: Vector2i) -> bool:
	var target_node: Node3D = null
	if builder and builder.grid.has(cell) and is_instance_valid(builder.grid[cell].get("prop")):
		target_node = builder.grid[cell]["prop"] as Node3D
	elif model.cell_data.has(cell):
		for n in model.cell_data[cell].get("nodes", []):
			if is_instance_valid(n):
				target_node = n
				break

	if is_instance_valid(target_node):
		if builder:
			for c in builder.grid.keys():
				if builder.grid[c].get("prop") == target_node or (builder.grid[c].get("type") == 6 and (c - cell).length() <= 3.5):
					builder.grid[c]["prop"] = null
					builder.grid[c]["walkable"] = true
					if builder.grid[c].get("type") == 6:
						builder.grid[c]["type"] = 1
					if model.cell_data.has(c):
						model.cell_data[c]["prop"] = null
						model.cell_data[c]["wall"] = null
						model.cell_data[c]["nodes"].erase(target_node)
		target_node.queue_free()

	if model.cell_data.has(cell):
		model.cell_data[cell]["prop"] = null
		model.cell_data[cell]["wall"] = null

	if builder and builder.grid.has(cell):
		builder.grid[cell]["prop"] = null
		builder.grid[cell]["walkable"] = true
		if builder.grid[cell].get("type") == 6:
			builder.grid[cell]["type"] = 1

	free_object_nodes_at_cell(cell, true)
	return true

func erase_door_only(cell: Vector2i) -> bool:
	var has_door = false
	if model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		var p_info = model.cell_data[cell]["prop"]
		var p_type = p_info.get("type", "")
		var arch_t = p_info.get("arch_type", "")
		if p_type == "door" or "door" in arch_t or "portcullis" in arch_t:
			has_door = true
	if builder and builder.grid.has(cell) and is_instance_valid(builder.grid[cell].get("prop")):
		has_door = true
	if not has_door: return false
	return erase_arch_or_door_structure(cell)

func erase_arch_only(cell: Vector2i) -> bool:
	var has_arch = false
	if model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		var p_info = model.cell_data[cell]["prop"]
		var is_arch = p_info.get("is_arch", false) or p_info.get("type", "").begins_with("arch") or p_info.get("arch_type", "").begins_with("arch")
		var arch_t = p_info.get("arch_type", "")
		if is_arch and not ("door" in arch_t or "portcullis" in arch_t):
			has_arch = true
	if builder and builder.grid.has(cell) and is_instance_valid(builder.grid[cell].get("prop")):
		has_arch = true
	if not has_arch: return false
	return erase_arch_or_door_structure(cell)

func erase_chest_only(cell: Vector2i) -> bool:
	var had_chest = false
	if model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		if model.cell_data[cell]["prop"].get("type") == "chest":
			model.cell_data[cell]["prop"] = null
			had_chest = true
	if builder:
		for ch in builder.interactive_chests:
			if is_instance_valid(ch) and builder.world_to_grid(ch.global_position) == cell:
				had_chest = true
				break
	if not had_chest: return false
	model.erased_props[cell] = true
	free_object_nodes_at_cell(cell, true)
	if builder and builder.grid.has(cell):
		builder.grid[cell]["walkable"] = true
		builder.grid[cell]["prop"] = null
	return true

func erase_item_only(cell: Vector2i) -> bool:
	if not model.cell_data.has(cell) or model.cell_data[cell].get("prop") == null: return false
	var p_type = model.cell_data[cell]["prop"].get("type", "")
	if not (p_type == "item" or p_type.begins_with("item")): return false
	model.cell_data[cell]["prop"] = null
	model.erased_props[cell] = true
	free_object_nodes_at_cell(cell, true)
	if builder and builder.grid.has(cell):
		builder.grid[cell]["walkable"] = true
		builder.grid[cell]["prop"] = null
	return true

func erase_prop_only(cell: Vector2i) -> bool:
	if not model.cell_data.has(cell) or model.cell_data[cell].get("prop") == null: return false
	var p_info = model.cell_data[cell]["prop"]
	var p_type = p_info.get("type", "")
	var arch_t = p_info.get("arch_type", "")
	var is_arch = p_info.get("is_arch", false) or p_type.begins_with("arch") or arch_t.begins_with("arch") or p_type == "door" or "door" in arch_t or "portcullis" in arch_t
	if is_arch or p_type in ["chest", "item"]: return false
	var had_wall = model.is_wall_at(cell)
	model.cell_data[cell]["prop"] = null
	model.erased_props[cell] = true
	free_object_nodes_at_cell(cell, true, had_wall)
	if builder and builder.grid.has(cell):
		builder.grid[cell]["walkable"] = not had_wall
		builder.grid[cell]["prop"] = null
	return true

func erase_unselected_fallback(cell: Vector2i) -> bool:
	if model.has_object_at_cell(cell):
		erase_object_at_cell(cell)
		return true
	if (builder and builder.grid.has(cell)) or model.cell_data.has(cell):
		erase_cell(cell)
		return true
	return false

func erase_object_at_cell(cell: Vector2i) -> bool:
	var had_prop = false
	var had_wall = model.is_wall_at(cell)
	if model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		had_prop = true; model.cell_data[cell]["prop"] = null
	elif builder and builder.grid.has(cell):
		if builder.grid[cell].get("prop") != null:
			had_prop = true; builder.grid[cell]["prop"] = null
		elif not builder.grid[cell].get("walkable", true) and not had_wall:
			had_prop = true
		else:
			for ch in builder.interactive_chests:
				if is_instance_valid(ch) and builder.world_to_grid(ch.global_position) == cell:
					had_prop = true; break

	if had_prop:
		model.erased_props[cell] = true
		free_object_nodes_at_cell(cell, true, had_wall)
		if not had_wall and builder and builder.grid.has(cell):
			builder.grid[cell]["walkable"] = true
			builder.grid[cell]["prop"] = null
		return true

	if had_wall:
		if model.cell_data.has(cell) and model.cell_data[cell].get("wall") != null:
			model.cell_data[cell]["wall"] = null
		free_object_nodes_at_cell(cell, true, false)
		model.set_floor(cell, "stone", 1, true)
		return true

	return false

func erase_cell(cell: Vector2i) -> void:
	var was_wall = model.is_wall_at(cell)
	free_object_nodes_at_cell(cell, false)
	model.cell_data.erase(cell)
	model.erased_props.erase(cell)
	model.erased_cells[cell] = true
	if builder: builder.grid.erase(cell)
	if was_wall:
		var affected = LevelEditorWallAutoTiler.get_affected_neighborhood([cell], model.is_wall_at)
		for n in affected:
			if n != cell and model.is_wall_at(n):
				model.set_wall(n)
