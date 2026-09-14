class_name LevelEditorWallAutoTiler
extends RefCounted

const CastleWallTileFactory = preload("res://scripts/hero_quest/castle_wall_tile_factory.gd")

static func get_line_cells(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dx = end.x - start.x
	var dz = end.y - start.y
	if abs(dx) >= abs(dz):
		var step_x = 1 if dx >= 0 else -1
		for x in range(start.x, end.x + step_x, step_x):
			cells.append(Vector2i(x, start.y))
	else:
		var step_z = 1 if dz >= 0 else -1
		for z in range(start.y, end.y + step_z, step_z):
			cells.append(Vector2i(start.x, z))
	return cells

static func get_rect_cells(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_x = mini(start.x, end.x)
	var max_x = maxi(start.x, end.x)
	var min_z = mini(start.y, end.y)
	var max_z = maxi(start.y, end.y)
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			cells.append(Vector2i(x, z))
	return cells

static func get_wall_connections(cell: Vector2i, is_wall_fn: Callable) -> Dictionary:
	var left = is_wall_fn.call(Vector2i(cell.x - 1, cell.y))
	var right = is_wall_fn.call(Vector2i(cell.x + 1, cell.y))
	var up = is_wall_fn.call(Vector2i(cell.x, cell.y - 1))
	var down = is_wall_fn.call(Vector2i(cell.x, cell.y + 1))
	var count = (1 if left else 0) + (1 if right else 0) + (1 if up else 0) + (1 if down else 0)
	var has_x = left or right
	var has_z = up or down
	var is_corner = has_x and has_z and count == 2
	var is_t = count == 3
	var is_cross = count == 4
	var is_straight_x = left and right and not has_z
	var is_straight_z = up and down and not has_x

	return {
		"left": left,
		"right": right,
		"up": up,
		"down": down,
		"count": count,
		"has_x": has_x,
		"has_z": has_z,
		"is_corner": is_corner,
		"is_t": is_t,
		"is_cross": is_cross,
		"is_straight_x": is_straight_x,
		"is_straight_z": is_straight_z
	}

static func get_affected_neighborhood(cells: Array[Vector2i], is_wall_fn: Callable) -> Array[Vector2i]:
	var affected_set: Dictionary = {}
	var orthogonal_offsets = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

	for cell in cells:
		affected_set[cell] = true
		for off in orthogonal_offsets:
			var n = cell + off
			if is_wall_fn.call(n):
				affected_set[n] = true

	var res: Array[Vector2i] = []
	for c in affected_set.keys():
		res.append(c)
	return res

static func validate_window_placement(cell: Vector2i, is_wall_fn: Callable, is_door_or_arch_fn: Callable, custom_norm: Vector3 = Vector3.ZERO) -> Dictionary:
	if is_door_or_arch_fn.call(cell):
		return {
			"valid": false,
			"reason": "Windows may not be placed on door frames or arches.",
			"norm": Vector3.FORWARD
		}

	var conn = get_wall_connections(cell, is_wall_fn)
	if conn["is_corner"] or (conn["has_x"] and conn["has_z"]):
		return {
			"valid": false,
			"reason": "Windows may not be placed in corners.",
			"norm": Vector3.FORWARD
		}

	var norm = custom_norm
	if norm == Vector3.ZERO:
		if conn["has_x"]:
			norm = Vector3(0, 0, 1) # Faces South
		elif conn["has_z"]:
			norm = Vector3(1, 0, 0) # Faces East
		else:
			norm = Vector3(0, 0, 1)

	return {
		"valid": true,
		"reason": "",
		"norm": norm
	}
