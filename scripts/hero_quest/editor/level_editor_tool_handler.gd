class_name LevelEditorToolHandler
extends RefCounted

const TILE_SIZE: float = 2.0
const LevelEditorWallAutoTiler = preload("res://scripts/hero_quest/editor/level_editor_wall_autotiler.gd")
const LevelEditorGrid = preload("res://scripts/hero_quest/editor/level_editor_grid.gd")
const LevelEditorHistory = preload("res://scripts/hero_quest/editor/level_editor_history.gd")
const LevelEditorModel = preload("res://scripts/hero_quest/editor/level_editor_model.gd")
const LevelEditorGhostPreview = preload("res://scripts/hero_quest/editor/level_editor_ghost_preview.gd")
const LevelEditorPlacementPolicy = preload("res://scripts/hero_quest/editor/level_editor_placement_policy.gd")
const CastleLevelData = preload("res://scripts/hero_quest/level/castle_level_data.gd")

signal tool_action_performed(desc: String)
signal tool_warning(msg: String)
signal tile_hovered(summary: String)

var camera: Camera3D
var grid: LevelEditorGrid
var history: LevelEditorHistory
var model: LevelEditorModel
var ghost_preview: LevelEditorGhostPreview
var room_manager: RefCounted = null

var active_tool: String = "floor"
var selected_item_data: Dictionary = { "mat": "stone", "type": 1 }
var chest_config: Dictionary = {"relic_name": "Gold Relic", "gold": 100, "is_trapped": false, "rot_y": 0.0}
var door_config: Dictionary = {"is_open": false, "is_locked": false, "required_key": "Iron Key", "consumes_key": true}
var placement_rot_y: float = 0.0
var hovered_cell: Vector2i = Vector2i.ZERO
var is_dragging: bool = false
var drag_start_cell: Vector2i = Vector2i.ZERO
var _last_preview_axis: int = -1
var _has_hovered_once: bool = false

func _init(p_cam: Camera3D, p_grid: LevelEditorGrid, p_hist: LevelEditorHistory, p_model: LevelEditorModel, p_ghost: LevelEditorGhostPreview = null) -> void:
	camera = p_cam; grid = p_grid; history = p_hist; model = p_model; ghost_preview = p_ghost

func has_selection() -> bool:
	return active_tool != "none" and active_tool != ""

func clear_selection() -> void:
	active_tool = "none"; selected_item_data = {}
	if ghost_preview: ghost_preview.set_preview_visible(false)
	if grid: grid.hide_cursor()
	if model and model.materials: model.materials.set_walls_transparent(false)

func set_tool(tool_name: String, item_data: Dictionary = {}) -> void:
	active_tool = tool_name
	selected_item_data = item_data.duplicate(true)
	placement_rot_y = 0.0
	_last_preview_axis = -1

	if model and model.materials:
		model.materials.set_walls_transparent(active_tool == "floor")

	_update_ghost_mesh()
	_update_cursor_visuals()

func _update_ghost_mesh() -> void:
	if not ghost_preview: return
	var show_ghost = LevelEditorPlacementPolicy.should_show_ghost(active_tool)
	ghost_preview.set_preview_visible(show_ghost)
	if show_ghost:
		ghost_preview.update_preview_mesh(active_tool, selected_item_data)
	_update_ghost_transform()

func update_mouse_position(screen_pos: Vector2) -> void:
	if not is_instance_valid(camera):
		return

	var origin = camera.project_ray_origin(screen_pos)
	var normal = camera.project_ray_normal(screen_pos)

	var hit_cell: Vector2i
	var found_hit = false

	# 1. 3D Raycast to hit walls or props
	var space_state = camera.get_world_3d().direct_space_state
	if space_state:
		var query = PhysicsRayQueryParameters3D.create(origin, origin + normal * 200.0)
		query.collision_mask = 1 | 2 # static bodies & props
		var result = space_state.intersect_ray(query)
		if result and result.size() > 0:
			var hit = result.position
			var collider = result.get("collider") as Node
			var target_prop_node: Node3D = null
			if collider:
				var curr: Node = collider
				while curr and model and curr != model.builder and curr != model.custom_room_node and not curr.name.begins_with("LevelEditor"):
					if curr is Node3D and (curr.name.contains("Arch") or curr.name.contains("Portal") or curr.name.contains("Door") or curr.name.contains("Pier") or curr.name.contains("Spanning") or curr.name.contains("Gate")):
						target_prop_node = curr as Node3D
						break
					curr = curr.get_parent()

			if target_prop_node and model and model.builder:
				var found_cell: Vector2i = Vector2i(9999, 9999)
				for c in model.builder.grid.keys():
					if model.builder.grid[c].get("prop") == target_prop_node or model.builder.grid[c].get("prop") == target_prop_node.get_parent():
						found_cell = c
						break
				if found_cell != Vector2i(9999, 9999):
					hit_cell = found_cell
					found_hit = true
				else:
					var g_pos = target_prop_node.global_position
					hit_cell = Vector2i(roundi(g_pos.x / TILE_SIZE), roundi(g_pos.z / TILE_SIZE))
					found_hit = true

			if not found_hit and hit.y > 0.3:
				var sample_pos = result.position - result.normal * 0.15
				hit_cell = Vector2i(roundi(sample_pos.x / TILE_SIZE), roundi(sample_pos.z / TILE_SIZE))
				found_hit = true

	# 2. Fall back to ground plane (y = 0.0)
	if not found_hit:
		var ground = Plane(Vector3.UP, 0.0)
		var hit = ground.intersects_ray(origin, normal)
		if hit == null:
			return
		hit_cell = Vector2i(roundi(hit.x / TILE_SIZE), roundi(hit.z / TILE_SIZE))

	var prev_cell = hovered_cell
	hovered_cell = hit_cell
	_update_cursor_visuals()
	_update_ghost_transform()

	if hovered_cell != prev_cell or not _has_hovered_once:
		_has_hovered_once = true
		if model:
			tile_hovered.emit(model.get_tile_summary_string(hovered_cell))

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
	return LevelEditorPlacementPolicy.get_effective_placement(cell, active_tool, selected_item_data, model, placement_rot_y)

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
	return LevelEditorPlacementPolicy.detect_wall_face(cell, model, placement_rot_y)

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
	if not is_dragging: return
	is_dragging = false
	match active_tool:
		"floor": _apply_floor_drag()
		"wall": _apply_wall_drag()
		"window": _apply_window_click()
		"chest": _apply_chest_click()
		"item": _apply_item_click()
		"door", "arch": _apply_arch_click()
		"prop": _apply_prop_click()
		"erase": _apply_erase_drag()
		"room": _apply_room_drag()
	grid.show_single_cell(hovered_cell)
	_update_ghost_transform()
	if model: tile_hovered.emit(model.get_tile_summary_string(hovered_cell))

func _apply_room_drag() -> void:
	if not room_manager: return
	var is_brush = (room_manager.paint_mode == "brush")
	var cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell) if is_brush else LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	if room_manager.paint_mode == "erase": room_manager.erase_cells(cells)
	else: room_manager.assign_cells(cells)

func _apply_floor_drag() -> void:
	var cells = LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	var affected = LevelEditorWallAutoTiler.get_affected_neighborhood(cells, model.is_wall_at)
	var before_state = model.capture_cell_states(affected)
	var mat_name = selected_item_data.get("mat", "stone")
	var tile_type = int(selected_item_data.get("type", 1))
	var walkable = bool(selected_item_data.get("walkable", true))
	for c in cells: model.set_floor(c, mat_name, tile_type, walkable)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Floor (%d tiles)" % cells.size(), before_state, after_state)
	tool_action_performed.emit("Placed floor (%d tiles)" % cells.size())

func _apply_wall_drag() -> void:
	var cells = LevelEditorWallAutoTiler.get_line_cells(drag_start_cell, hovered_cell)
	var affected = LevelEditorWallAutoTiler.get_affected_neighborhood(cells, model.is_wall_at)
	var before_state = model.capture_cell_states(affected)

	var params = _get_effective_placement_params(hovered_cell)
	var orient = int(params.get("orientation", -1))
	model.set_walls_batch(cells, orient)

	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Walls (%d tiles)" % cells.size(), before_state, after_state)
	tool_action_performed.emit("Placed wall (%d tiles)" % cells.size())

func _apply_window_click() -> void:
	var params = _get_effective_placement_params(hovered_cell)
	var check = LevelEditorWallAutoTiler.validate_window_placement(hovered_cell, model.is_wall_at, model.is_door_or_arch_at, params.get("norm", Vector3.ZERO))
	if not check["valid"]:
		tool_warning.emit(check["reason"])
		return

	var affected = LevelEditorWallAutoTiler.get_affected_neighborhood([hovered_cell], model.is_wall_at)
	var before_state = model.capture_cell_states(affected)
	model.set_window(hovered_cell, params.get("norm", check["norm"]))
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Window Wall", before_state, after_state)
	tool_action_performed.emit("Placed window wall at %s" % str(hovered_cell))

func _apply_chest_click() -> void:
	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)

	var params = _get_effective_placement_params(hovered_cell)
	var rot = params.get("rot_y", 0.0)

	var chest_data = {
		"type": "chest", "name": selected_item_data.get("name", "TreasureChest"),
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

	var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
	var is_door_prop = ("door" in arch_type or "portcullis" in arch_type)
	var affected: Array[Vector2i] = [hovered_cell]
	if is_door_prop:
		if "2tile" in arch_type: affected.append(hovered_cell + off)
	elif arch_type == "arch_4tile":
		affected.append_array([hovered_cell - off, hovered_cell + off, hovered_cell + off * 2])
	else:
		var pier_span = 2 if (arch_type == "arch_spanning_3tiles" or arch_type == "arch_5tile_twin") else 1
		affected.append_array([hovered_cell - off * pier_span, hovered_cell + off * pier_span])

	var before_state = model.capture_cell_states(affected)
	var arch_data = {
		"type": arch_type, "arch_type": arch_type,
		"name": selected_item_data.get("name", "CustomDoor" if is_door_prop else "CustomArch"),
		"axis": axis, "is_arch": true, "is_door": is_door_prop,
		"is_open": door_config.get("is_open", false),
		"is_locked": door_config.get("is_locked", false),
		"required_key": door_config.get("required_key", "Iron Key"),
		"consumes_key": door_config.get("consumes_key", true)
	}
	model.spawn_custom_prop(hovered_cell, arch_data)
	var neighbor_walls = LevelEditorWallAutoTiler.get_affected_neighborhood(affected, model.is_wall_or_portal_at)
	for nw in neighbor_walls:
		if nw not in affected and model.is_wall_at(nw): model.set_wall(nw)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Door/Arch", before_state, after_state)
	tool_action_performed.emit("Placed %s at %s (Axis: %s)" % [arch_type, str(hovered_cell), "X" if axis == 0 else "Z"])

func _apply_item_click() -> void:
	var item_id = selected_item_data.get("item_id", "iron_key")
	var item_data = {"type": "floor_item", "item_id": item_id, "name": selected_item_data.get("name", "FloorKey")}
	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)
	model.spawn_custom_prop(hovered_cell, item_data)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Place Floor Item", before_state, after_state)
	tool_action_performed.emit("Placed %s at %s" % [item_id, str(hovered_cell)])

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
	var affected = [hovered_cell]
	var before_state = model.capture_cell_states(affected)
	var action_desc = ""
	var update_neighbor_walls = false

	match active_tool:
		"floor": if model.erase_floor_only(hovered_cell): action_desc = "Deleted floor tile at %s" % str(hovered_cell)
		"wall": if model.erase_wall_only(hovered_cell): action_desc = "Deleted wall at %s" % str(hovered_cell); update_neighbor_walls = true
		"window": if model.erase_window_only(hovered_cell): action_desc = "Deleted window wall at %s" % str(hovered_cell); update_neighbor_walls = true
		"door": if model.erase_door_only(hovered_cell): action_desc = "Deleted door at %s" % str(hovered_cell); update_neighbor_walls = true
		"arch": if model.erase_arch_only(hovered_cell): action_desc = "Deleted arch at %s" % str(hovered_cell)
		"chest": if model.erase_chest_only(hovered_cell): action_desc = "Deleted chest at %s" % str(hovered_cell)
		"item": if model.erase_item_only(hovered_cell): action_desc = "Deleted item at %s" % str(hovered_cell)
		"prop": if model.erase_prop_only(hovered_cell): action_desc = "Deleted prop at %s" % str(hovered_cell)
		"room":
			if room_manager:
				room_manager.erase_cells([hovered_cell])
				action_desc = "Unassigned room from tile %s" % str(hovered_cell)
		_: # "none", "", "erase", or unselected fallback
			var had_obj_before = model.has_object_at_cell(hovered_cell)
			if model.erase_unselected_fallback(hovered_cell):
				action_desc = ("Deleted object at %s" % str(hovered_cell)) if had_obj_before else ("Deleted floor tile at %s" % str(hovered_cell))
				update_neighbor_walls = true

	if update_neighbor_walls:
		for nw in LevelEditorWallAutoTiler.get_affected_neighborhood([hovered_cell], model.is_wall_or_portal_at):
			if nw != hovered_cell and model.is_wall_at(nw): model.set_wall(nw)

	if action_desc != "":
		var after_state = model.capture_cell_states(affected)
		history.record_action(action_desc, before_state, after_state)
		tool_action_performed.emit(action_desc)
		if model: tile_hovered.emit(model.get_tile_summary_string(hovered_cell))

func _apply_erase_drag() -> void:
	var cells = LevelEditorWallAutoTiler.get_rect_cells(drag_start_cell, hovered_cell)
	var affected = LevelEditorWallAutoTiler.get_affected_neighborhood(cells, model.is_wall_at)
	var before_state = model.capture_cell_states(affected)
	for c in cells: model.erase_cell(c)
	for c in affected:
		if c not in cells and model.is_wall_at(c): model.set_wall(c)
	var after_state = model.capture_cell_states(affected)
	history.record_action("Erase (%d tiles)" % cells.size(), before_state, after_state)
	tool_action_performed.emit("Erased %d tiles" % cells.size())
