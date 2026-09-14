class_name LevelEditorPlacementPolicy
extends RefCounted

const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")
const LevelEditorWallAutoTiler = preload("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")

# Registry for custom exception rules: rule_id -> Callable(cell, tool_name, item_data, model) -> bool
static var _custom_rules: Dictionary = {}

static func register_exception_rule(rule_id: String, check_fn: Callable) -> void:
	_custom_rules[rule_id] = check_fn

static func unregister_exception_rule(rule_id: String) -> void:
	_custom_rules.erase(rule_id)

static func clear_exception_rules() -> void:
	_custom_rules.clear()

static func should_show_ghost(tool_name: String) -> bool:
	return not (tool_name in ["floor", "erase", "room", "none", ""])

static func is_same_tile(cell: Vector2i, tool_name: String, item_data: Dictionary, model) -> bool:
	if not model or not model.cell_data.has(cell):
		return false

	var c_info = model.cell_data[cell]
	var p_type = item_data.get("type", "")
	var is_arch = tool_name in ["door", "arch"] or item_data.get("is_arch", false)

	if tool_name == "wall":
		return model.is_wall_at(cell) and c_info.get("wall") != null and c_info["wall"].get("type") == "modular"

	if tool_name == "window":
		return c_info.get("wall") != null and c_info["wall"].get("type") == "window"

	if is_arch:
		var ep = c_info.get("prop")
		if ep == null: return false
		var ep_type = str(ep.get("type", ""))
		return ep.get("is_arch", false) or ep_type.begins_with("arch") or "door" in ep_type or "portcullis" in ep_type

	if tool_name == "chest":
		var ep = c_info.get("prop")
		return ep != null and ep.get("type") == "treasure_chest"

	if tool_name == "prop":
		var ep = c_info.get("prop")
		if ep == null: return false
		return str(ep.get("type", "")) == str(p_type)

	return false

static func is_rotation_suppressed(cell: Vector2i, tool_name: String, item_data: Dictionary, model) -> bool:
	# 1. Custom registered exception rules
	for rule_id in _custom_rules.keys():
		var fn = _custom_rules[rule_id]
		if fn is Callable and fn.call(cell, tool_name, item_data, model):
			return true

	# 2. Built-in exception: Walls connected to other walls on all 4 sides (4-way cross junction)
	if tool_name == "wall" and model and model.is_wall_at(cell):
		var conn = LevelEditorWallAutoTiler.get_wall_connections(cell, model.is_wall_at)
		if conn.get("count", 0) == 4:
			return true

	return false

static func detect_wall_face(cell: Vector2i, model, default_rot_y: float) -> Dictionary:
	if model and model.is_wall_at(cell):
		for off in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if not model.is_wall_at(cell + off):
				return { "wall_cell": cell, "norm": Vector3(off.x, 0, off.y) }
		return { "wall_cell": cell, "norm": Vector3(0, 0, 1) }

	var wall_offsets = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	if model:
		for off in wall_offsets:
			if model.is_wall_at(cell + off):
				return { "wall_cell": cell + off, "norm": Vector3(-off.x, 0, -off.y) }

	var approx_norm = Vector3(sin(default_rot_y), 0, cos(default_rot_y)).snapped(Vector3.ONE)
	return { "wall_cell": cell, "norm": approx_norm if approx_norm != Vector3.ZERO else Vector3(0, 0, 1) }

static func get_effective_placement(cell: Vector2i, tool_name: String, item_data: Dictionary, model, base_rot_y: float) -> Dictionary:
	var has_same = is_same_tile(cell, tool_name, item_data, model)
	var is_arch = tool_name in ["door", "arch"] or item_data.get("is_arch", false)
	var p_type = item_data.get("type", "")

	if has_same and is_rotation_suppressed(cell, tool_name, item_data, model):
		# Rotation suppressed by exception (e.g. 4-way cross wall)
		if tool_name == "wall":
			var cur_w = model.cell_data[cell].get("wall", {})
			var cur_orient = int(cur_w.get("orientation", 0))
			var cur_rot = float(cur_w.get("rot_y", 0.0))
			return { "has_same": true, "is_exception": true, "rot_y": cur_rot, "orientation": cur_orient }
		var ep = model.cell_data[cell].get("prop", {})
		return {
			"has_same": true,
			"is_exception": true,
			"rot_y": float(ep.get("rot_y", base_rot_y)),
			"axis": int(ep.get("axis", 0))
		}

	# 1. Walls
	if tool_name == "wall":
		var default_orient = 0 if absf(sin(base_rot_y)) < 0.5 else 1
		var default_rot = PI * 0.5 if default_orient == 1 else 0.0
		if has_same:
			var cur_w = model.cell_data[cell].get("wall", {})
			var cur_orient = int(cur_w.get("orientation", default_orient))
			var next_orient = (cur_orient + 1) % 2
			var next_rot = PI * 0.5 if next_orient == 1 else 0.0
			return { "has_same": true, "is_exception": false, "rot_y": next_rot, "orientation": next_orient }
		return { "has_same": false, "is_exception": false, "rot_y": default_rot, "orientation": default_orient }

	# 2. Windows
	if tool_name == "window":
		var check = LevelEditorWallAutoTiler.validate_window_placement(cell, model.is_wall_at, model.is_door_or_arch_at)
		var base_norm = check.get("norm", Vector3.FORWARD)
		if has_same:
			var cur_w = model.cell_data[cell].get("wall", {})
			var cur_n = CastleLevelData.arr_to_vec3(cur_w.get("norm", [base_norm.x, base_norm.y, base_norm.z]))
			var next_n = Vector3(cur_n.z, 0, -cur_n.x)
			return { "has_same": true, "is_exception": false, "norm": next_n, "rot_y": atan2(next_n.x, next_n.z) }
		return { "has_same": false, "is_exception": false, "norm": base_norm, "rot_y": atan2(base_norm.x, base_norm.z) }

	# 3. Doors & Arches
	if is_arch:
		var base_axis = int(item_data.get("axis", 0))
		if has_same:
			var ep = model.cell_data[cell].get("prop", {})
			var cur_axis = int(ep.get("axis", base_axis))
			var next_axis = (cur_axis + 1) % 2
			var next_rot = PI * 0.5 if next_axis == 1 else 0.0
			return { "has_same": true, "is_exception": false, "axis": next_axis, "rot_y": next_rot }
		var init_rot = PI * 0.5 if base_axis == 1 else 0.0
		return { "has_same": false, "is_exception": false, "axis": base_axis, "rot_y": init_rot }

	# 3. Wall Decors (Torches, Paintings)
	if p_type in ["torch", "painting"]:
		var w_info = detect_wall_face(cell, model, base_rot_y)
		var base_norm = w_info["norm"]
		if has_same:
			var ep = model.cell_data[cell].get("prop", {})
			var cur_n = CastleLevelData.arr_to_vec3(ep.get("norm", [base_norm.x, base_norm.y, base_norm.z]))
			var next_n = Vector3(cur_n.z, 0, -cur_n.x)
			return { "has_same": true, "is_exception": false, "wall_cell": w_info["wall_cell"], "norm": next_n, "rot_y": atan2(next_n.x, next_n.z) }
		return { "has_same": false, "is_exception": false, "wall_cell": w_info["wall_cell"], "norm": base_norm, "rot_y": atan2(base_norm.x, base_norm.z) }

	# 4. Standard Props & Chests
	if has_same:
		var ep = model.cell_data[cell].get("prop", {})
		var cur_rot = float(ep.get("rot_y", base_rot_y))
		var next_rot = fmod(cur_rot + PI * 0.5, TAU)
		return { "has_same": true, "is_exception": false, "rot_y": next_rot }

	return { "has_same": false, "is_exception": false, "rot_y": base_rot_y }
