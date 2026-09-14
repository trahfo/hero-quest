class_name LevelEditorToolHandler
extends RefCounted

const TILE_SIZE: float = 2.0
const LevelEditorWallAutoTiler = preload("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
const LevelEditorGrid = preload("res://scripts/hero_quest/editor/level_editor_grid.gd")
const LevelEditorHistory = preload("res://scripts/hero_quest/editor/level_editor_history.gd")
const LevelEditorModel = preload("res://scripts/hero_quest/editor/level_editor_model.gd")
const LevelEditorGhostPreview = preload("res://scripts/hero_quest/editor/level_editor_ghost_preview.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")

signal tool_action_performed(desc: String)
signal tool_warning(msg: String)

var camera: Camera3D
var grid: LevelEditorGrid
var history: LevelEditorHistory
var model: LevelEditorModel
var ghost_preview: LevelEditorGhostPreview
var room_manager: RefCounted = null

var active_tool: String = "floor"
var selected_item_data: Dictionary = { "mat": "stone", "type": 1 }
var chest_config: Dictionary = {"relic_name": "Gold Relic", "gold": 100, "is_trapped": false, "rot_y": 0.0}
var placement_rot_y: float = 0.0
var hovered_cell: Vector2i = Vector2i.ZERO
var is_dragging: bool = false
var drag_start_cell: Vector2i = Vector2i.ZERO
var _last_preview_axis: int = -1

func _init(p_cam: Camera3D, p_grid: LevelEditorGrid, p_hist: LevelEditorHistory, p_model: LevelEditorModel, p_ghost: LevelEditorGhostPreview = null) -> void:
	camera = p_cam; grid = p_grid; history = p_hist; model = p_model; ghost_preview = p_ghost

func has_selection() -> bool:
	return active_tool != "none" and active_tool != ""

func clear_selection() -> void:
	active_tool = "none"; selected_item_data = {}
	if ghost_preview: ghost_preview.set_preview_visible(false)
	if grid: grid.hide_cursor()

func set_tool(tool_name: String, item_data: Dictionary = {}) -> void:
	active_tool = tool_name
	if not item_data.is_empty(): selected_item_data = item_data
	if is_dragging:
		is_dragging = false
		grid.hide_cursor()
	_update_ghost_mesh()

func _update_ghost_mesh() -> void:
	if not ghost_preview:
		return
	if active_tool in ["erase", "none", "", "room"]:
		ghost_preview.set_preview_visible(false)
	else:
		ghost_preview.set_preview_visible(true)
		ghost_preview.update_preview_mesh(active_tool, selected_item_data)
	_update_ghost_transform()

func update_mouse_position(screen_pos: Vector2) -> void:
	if not camera:
		return
	var origin = camera.project_ray_origin(screen_pos)
	var normal = camera.project_ray_normal(screen_pos)

	var hit_cell: Vector2i = Vector2i.ZERO
	var found_hit: bool = false

	# 1. Physics raycast for clicking high objects (walls, pillars, tall furniture)
	var world_3d = camera.get_world_3d()
	if world_3d:
		var space_state = world_3d.direct_space_state
		if space_state:
			var query = PhysicsRayQueryParameters3D.create(origin, origin + normal * 1000.0)
			var result = space_state.intersect_ray(query)
			if not result.is_empty():
				var hit_pos: Vector3 = result.position
				var hit_norm: Vector3 = result.normal
				var sample_pos = hit_pos - hit_norm * 0.15
				hit_cell = Vector2i(roundi(sample_pos.x / TILE_SIZE), roundi(sample_pos.z / TILE_SIZE))
				found_hit = true

	# 2. Fall back to ground plane (y = 0.0)
	if not found_hit:
		var ground = Plane(Vector3.UP, 0.0)
		var hit = ground.intersects_ray(origin, normal)
		if hit == null:
			return
		hit_cell = Vector2i(roundi(hit.x / TILE_SIZE), roundi(hit.z / TILE_SIZE))

	hovered_cell = hit_cell
	_update_cursor_visuals()
	_update_ghost_transform()

func _update_cursor_visuals() -> void:
	if not is_instance_valid(grid):
		return
	if active_tool in ["none", ""]:
		grid.hide_cursor()
		return

	if not is_dragging:
		var col = Color(0.9, 0.2, 0.2, 0.4) if active_tool == "erase" else Color(0.2, 0.8, 1.0, 0.35)
		if active_tool == "room" and room_manager:
			col = room_manager.get_room_color(room_manager.active_room_name)
		grid.show_single_cell(hovered_cell, col)
		return

	if active_tool == "floor" or active_tool == "erase":
		var cells = LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
		var col = Color(0.9, 0.2, 0.2, 0.4) if active_tool == "erase" else Color(0.2, 0.9, 0.4, 0.4)
		grid.show_selection_span(cells, col)
	elif active_tool == "wall":
		var cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell)
		grid.show_selection_span(cells, Color(0.3, 0.7, 1.0, 0.5))
	elif active_tool == "room":
		var is_brush = (room_manager and room_manager.paint_mode == "brush")
		var cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell) if is_brush else LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
		var col = room_manager.get_room_color(room_manager.active_room_name) if room_manager else Color(0.2, 0.6, 1.0, 0.5)
		grid.show_selection_span(cells, col)

func _get_effective_placement_params(cell: Vector2i) -> Dictionary:
	var p_type = selected_item_data.get("type", "")
	var is_arch = active_tool in ["door", "arch"] or selected_item_data.get("is_arch", false)
	var has_same: bool = false
	var ep: Dictionary = {}

	if model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		ep = model.cell_data[cell]["prop"]
		var ep_type = ep.get("type", "")
		if is_arch:
			has_same = ep.get("is_arch", false) or ep_type.begins_with("arch") or ep_type == "door"
		else:
			has_same = (str(ep_type) == str(p_type))
	elif active_tool == "chest" and model.cell_data.has(cell) and model.cell_data[cell].get("prop") != null:
		if model.cell_data[cell]["prop"].get("type") == "treasure_chest":
			has_same = true
			ep = model.cell_data[cell]["prop"]

	if is_arch:
		var base_axis = int(selected_item_data.get("axis", 0))
		if has_same:
			var next_axis = (int(ep.get("axis", base_axis)) + 1) % 2
			return { "has_same": true, "axis": next_axis, "rot_y": 0.0 }
		return { "has_same": false, "axis": base_axis, "rot_y": 0.0 }

	if p_type in ["torch", "painting"]:
		var w_info = _detect_wall_face(cell)
		var base_norm = w_info["norm"]
		if has_same:
			var cur_n = CastleLevelData.arr_to_vec3(ep.get("norm", [base_norm.x, base_norm.y, base_norm.z]))
			var next_n = Vector3(cur_n.z, 0, -cur_n.x)
			return { "has_same": true, "wall_cell": w_info["wall_cell"], "norm": next_n, "rot_y": atan2(next_n.x, next_n.z) }
		return { "has_same": false, "wall_cell": w_info["wall_cell"], "norm": base_norm, "rot_y": atan2(base_norm.x, base_norm.z) }

	var base_rot = placement_rot_y
	if has_same:
		var next_rot = fmod(float(ep.get("rot_y", base_rot)) + PI * 0.5, TAU)
		return { "has_same": true, "rot_y": next_rot }
	return { "has_same": false, "rot_y": base_rot }

func _update_ghost_transform() -> void:
	if not is_instance_valid(ghost_preview) or not ghost_preview.visible or active_tool in ["none", ""]:
		return
	var params = _get_effective_placement_params(hovered_cell)
	var base_pos = model.builder.grid_to_world(hovered_cell)
	var rot_y = params.get("rot_y", 0.0)

	if active_tool in ["door", "arch"]:
		var axis = int(params.get("axis", 0))
		if axis != _last_preview_axis:
			_last_preview_axis = axis
			var copy_data = selected_item_data.duplicate()
			copy_data["axis"] = axis
			ghost_preview.update_preview_mesh(active_tool, copy_data)
	elif selected_item_data.get("type", "") in ["torch", "painting"]:
		var norm = params["norm"]
		var elev = 2.2 if selected_item_data.get("type") == "torch" else 2.0
		base_pos = model.builder.grid_to_world(params["wall_cell"]) + norm * 0.46 + Vector3(0, elev, 0)

	ghost_preview.set_preview_transform(base_pos, rot_y)

func _detect_wall_face(cell: Vector2i) -> Dictionary:
	if model.is_wall_at(cell):
		for off in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if not model.is_wall_at(cell + off):
				return { "wall_cell": cell, "norm": Vector3(off.x, 0, off.y) }
		return { "wall_cell": cell, "norm": Vector3(0, 0, 1) }

	var wall_offsets = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for off in wall_offsets:
		if model.is_wall_at(cell + off):
			return { "wall_cell": cell + off, "norm": Vector3(-off.x, 0, -off.y) }

	var angle = placement_rot_y
	var approx_norm = Vector3(sin(angle), 0, cos(angle)).snapped(Vector3.ONE)
	return { "wall_cell": cell, "norm": approx_norm if approx_norm != Vector3.ZERO else Vector3(0, 0, 1) }

func on_mouse_button(event: InputEventMouseButton) -> void:
	update_mouse_position(event.position)
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_finish_drag()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_apply_right_click_delete()

func _start_drag() -> void:
	if active_tool in ["none", ""]:
		return
	is_dragging = true
	drag_start_cell = hovered_cell
	_update_cursor_visuals()

func _finish_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false

	match active_tool:
		"floor":
			_apply_floor_drag()
		"wall":
			_apply_wall_drag()
		"window":
			_apply_window_click()
		"chest":
			_apply_chest_click()
		"door", "arch":
			_apply_arch_click()
		"prop":
			_apply_prop_click()
		"erase":
			_apply_erase_drag()
		"room":
			_apply_room_drag()

	grid.show_single_cell(hovered_cell)
	_update_ghost_transform()

func _apply_room_drag() -> void:
	if not room_manager: return
	var is_brush = (room_manager.paint_mode == "brush")
	var cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell) if is_brush else LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	if room_manager.paint_mode == "erase":
		room_manager.erase_cells(cells)
		tool_action_performed.emit("Erased room assignment from %d tiles" % cells.size())
	else:
		room_manager.paint_cells(cells, room_manager.active_room_name)
		tool_action_performed.emit("Painted room '%s' (%d tiles)" % [room_manager.active_room_name, cells.size()])

func _apply_floor_drag() -> void:
	var cells = LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	var before_state = model.capture_cell_states(cells)
	var mat_name = selected_item_data.get("mat", "stone")
	var t_type = int(selected_item_data.get("type", 1))
	var walkable = bool(selected_item_data.get("walkable", true))

	var placed_count = 0
	for c in cells:
		if cells.size() > 1 and model.is_wall_at(c):
			continue
		model.set_floor(c, mat_name, t_type, walkable)
		placed_count += 1

	var after_state = model.capture_cell_states(cells)
	history.record_action("Place Floor (%d tiles)" % placed_count, before_state, after_state)
	tool_action_performed.emit("Placed floor across %d tiles" % placed_count)

func _apply_wall_drag() -> void:
	var line_cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell)
	var affected_cells = LevelEditorWallAutoTiler.get_affected_neighborhood(line_cells, model.is_wall_at)
	var before_state = model.capture_cell_states(affected_cells)

	model.set_walls_batch(line_cells)

	var after_state = model.capture_cell_states(affected_cells)
	history.record_action("Place Walls (%d tiles)" % line_cells.size(), before_state, after_state)
	tool_action_performed.emit("Placed walls across %d tiles" % line_cells.size())

func _apply_window_click() -> void:
	var check = LevelEditorWallAutoTiler.validate_window_placement(hovered_cell, model.is_wall_at, model.is_door_or_arch_at)
	if not check["valid"]:
		tool_warning.emit(check["reason"])
		return

	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)
	model.set_window(hovered_cell, check["norm"])
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Window", before_state, after_state)
	tool_action_performed.emit("Placed window wall at %s" % str(hovered_cell))

func _apply_chest_click() -> void:
	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)
	var params = _get_effective_placement_params(hovered_cell)
	var rot = params["rot_y"]

	var chest_data = {
		"type": "treasure_chest",
		"relic_name": chest_config.get("relic_name", "Gold Relic"),
		"gold": chest_config.get("gold", 100),
		"is_trapped": chest_config.get("is_trapped", false),
		"rot_y": rot
	}
	model.spawn_custom_prop(hovered_cell, chest_data)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Chest", before_state, after_state)
	tool_action_performed.emit("Placed treasure chest at %s (Rot: %d°)" % [str(hovered_cell), int(round(rad_to_deg(rot)))])

func _apply_arch_click() -> void:
	var arch_type = selected_item_data.get("arch_type", "arch_3tile")
	var params = _get_effective_placement_params(hovered_cell)
	var axis = int(params["axis"])

	var pier_span = 2 if (arch_type == "arch_spanning_3tiles" or arch_type == "arch_5tile_twin") else 1
	var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var affected: Array[Vector2i] = [hovered_cell, hovered_cell - off * pier_span, hovered_cell + off * pier_span]
	var before_state = model.capture_cell_states(affected)

	var arch_data = {
		"type": arch_type,
		"name": selected_item_data.get("name", "CustomArch"),
		"axis": axis,
		"is_arch": true
	}
	model.spawn_custom_prop(hovered_cell, arch_data)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Door/Arch", before_state, after_state)
	tool_action_performed.emit("Placed %s at %s (Axis: %s)" % [arch_type, str(hovered_cell), "X" if axis == 0 else "Z"])

func _apply_prop_click() -> void:
	var p_type = selected_item_data.get("type", "prop")
	var params = _get_effective_placement_params(hovered_cell)
	var target_cell = hovered_cell
	var prop_data = selected_item_data.duplicate(true)

	if p_type in ["torch", "painting"]:
		target_cell = params["wall_cell"]
		prop_data["norm"] = CastleLevelData.vec3_to_arr(params["norm"])
		prop_data["rot_y"] = params["rot_y"]
	else:
		prop_data["rot_y"] = params["rot_y"]

	var affected = [target_cell]
	var before_state = model.capture_cell_states(affected)
	model.spawn_custom_prop(target_cell, prop_data)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place %s" % p_type, before_state, after_state)
	tool_action_performed.emit("Placed %s at %s" % [p_type, str(target_cell)])

func _apply_right_click_delete() -> void:
	if active_tool == "room" and room_manager:
		room_manager.erase_cells([hovered_cell])
		tool_action_performed.emit("Unassigned room from tile %s" % str(hovered_cell))
		return

	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)

	var deleted_obj = model.erase_object_at_cell(hovered_cell)
	if deleted_obj:
		var after_state = model.capture_cell_states(affected)
		history.record_action("Delete Object", before_state, after_state)
		tool_action_performed.emit("Deleted object at %s" % str(hovered_cell))
	else:
		model.erase_cell(hovered_cell)
		var after_state = model.capture_cell_states(affected)
		history.record_action("Delete Floor", before_state, after_state)
		tool_action_performed.emit("Deleted floor tile at %s" % str(hovered_cell))

func _apply_erase_drag() -> void:
	var cells = LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	var affected = LevelEditorWallAutoTiler.get_affected_neighborhood(cells, model.is_wall_at)
	var before_state = model.capture_cell_states(affected)

	for c in cells:
		model.erase_cell(c)
	for c in affected:
		if c not in cells and model.is_wall_at(c):
			model.set_wall(c)

	var after_state = model.capture_cell_states(affected)
	history.record_action("Erase (%d tiles)" % cells.size(), before_state, after_state)
	tool_action_performed.emit("Erased %d tiles" % cells.size())
