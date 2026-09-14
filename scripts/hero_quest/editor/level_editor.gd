class_name LevelEditor
extends Node3D

const LevelEditorGrid = preload("res://scripts/hero_quest/editor/level_editor_grid.gd")
const LevelEditorModel = preload("res://scripts/hero_quest/editor/level_editor_model.gd")
const LevelEditorHistory = preload("res://scripts/hero_quest/editor/level_editor_history.gd")
const LevelEditorToolHandler = preload("res://scripts/hero_quest/editor/level_editor_tool_handler.gd")
const LevelEditorGhostPreview = preload("res://scripts/hero_quest/editor/level_editor_ghost_preview.gd")
const LevelEditorUI = preload("res://scripts/hero_quest/editor/level_editor_ui.gd")
const LevelEditorRoomManager = preload("res://scripts/hero_quest/editor/level_editor_room_manager.gd")
const LevelEditorRoomPanel = preload("res://scripts/hero_quest/editor/level_editor_room_panel.gd")

signal editor_toggled(active: bool)
signal level_saved(path: String)
signal status_message(msg: String)

var game_root: Node3D
var builder: Node3D
var camera: Camera3D
var camera_pivot: Node3D

var grid: LevelEditorGrid
var ghost_preview: LevelEditorGhostPreview
var model: LevelEditorModel
var history: LevelEditorHistory
var tool_handler: LevelEditorToolHandler
var ui: LevelEditorUI
var room_manager: LevelEditorRoomManager
var room_panel: LevelEditorRoomPanel

var is_active: bool = false
var active_file_path: String = "res://data/levels/first_level.json"

# Middle-click panning state
var is_panning: bool = false
var pan_last_mouse: Vector2 = Vector2.ZERO

var active_level_name: String = ""

func setup(p_game: Node3D, p_builder: Node3D, p_camera: Camera3D, p_pivot: Node3D, p_file_path: String = "res://data/levels/first_level.json", p_level_name: String = "") -> void:
	game_root = p_game
	builder = p_builder
	camera = p_camera
	camera_pivot = p_pivot
	active_file_path = p_file_path
	active_level_name = p_level_name

	_init_subsystems()

func _init_subsystems() -> void:
	model = LevelEditorModel.new(builder, active_file_path, active_level_name)
	history = LevelEditorHistory.new(Callable(model, "apply_cell_states"), 50)

	grid = LevelEditorGrid.new()
	grid.visible = false
	add_child(grid)

	ghost_preview = LevelEditorGhostPreview.new(model.materials, builder)
	ghost_preview.visible = false
	add_child(ghost_preview)

	tool_handler = LevelEditorToolHandler.new(camera, grid, history, model, ghost_preview)
	tool_handler.tool_action_performed.connect(_on_tool_action)
	tool_handler.tool_warning.connect(_on_tool_warning)

	ui = LevelEditorUI.new()
	ui.visible = false
	game_root.add_child(ui)

	room_manager = LevelEditorRoomManager.new(builder, model, history)
	tool_handler.room_manager = room_manager

	room_panel = LevelEditorRoomPanel.new(room_manager)
	ui.set_room_panel(room_panel)
	ui.set_level_name(model.get_level_name())
	ui.level_name_changed.connect(func(n): model.set_level_name(n))

	ui.tool_selected.connect(_on_ui_tool_selected)
	ui.undo_pressed.connect(undo)
	ui.redo_pressed.connect(redo)
	ui.save_pressed.connect(save_level)
	ui.exit_pressed.connect(toggle_editor)
	ui.chest_config_changed.connect(_on_chest_config_changed)
	history.history_changed.connect(ui.update_history_counts)

func toggle_editor() -> bool:
	is_active = not is_active
	grid.visible = is_active
	ui.visible = is_active
	if ghost_preview:
		ghost_preview.visible = is_active

	if is_active:
		ui.set_level_name(model.get_level_name())
		status_message.emit("Level Editor Active. Press TAB to Save & Exit.")
		ui.set_status_notice("Level Editor Active. Drag floors/walls or select a tool.")
	else:
		if room_manager:
			room_manager.set_walls_only_visible(false)
		save_level()
		status_message.emit("Level saved to %s. Returning to gameplay." % active_file_path)

	editor_toggled.emit(is_active)
	return is_active

func exit_without_saving() -> bool:
	if room_manager:
		room_manager.set_walls_only_visible(false)
	if model:
		model.discard_unsaved_changes()
	is_active = false
	grid.visible = false
	ui.visible = false
	if ghost_preview:
		ghost_preview.visible = false
	status_message.emit("Level Editor closed without saving.")
	editor_toggled.emit(false)
	return false

func handle_escape() -> void:
	if tool_handler and tool_handler.has_selection():
		var was_room = (tool_handler.active_tool == "room")
		tool_handler.clear_selection()
		if room_manager and was_room:
			room_manager.set_walls_only_visible(false)
		if ui:
			ui.clear_selection_highlight()
			ui.set_status_notice("Deselected item. (ESC: Exit without save | TAB: Save & Exit)")
	else:
		exit_without_saving()

func save_level() -> bool:
	if not model:
		return false
	var ok = model.save_to_json(active_file_path)
	if ok:
		level_saved.emit(active_file_path)
		ui.set_status_notice("Level saved successfully to %s" % active_file_path)
	return ok

func undo() -> void:
	if history and history.can_undo():
		var desc = history.undo()
		ui.set_status_notice("Undo: %s" % desc)

func redo() -> void:
	if history and history.can_redo():
		var desc = history.redo()
		ui.set_status_notice("Redo: %s" % desc)

func _on_ui_tool_selected(tool_name: String, data: Dictionary) -> void:
	if tool_handler:
		tool_handler.set_tool(tool_name, data)
	if room_manager:
		room_manager.set_walls_only_visible(tool_name == "room")

func _on_chest_config_changed(cfg: Dictionary) -> void:
	if tool_handler:
		tool_handler.chest_config = cfg

func _on_tool_action(desc: String) -> void:
	if ui:
		ui.set_status_notice(desc)

func _on_tool_warning(msg: String) -> void:
	if ui:
		ui.set_status_notice("⚠ Warning: %s" % msg)

func handle_input(event: InputEvent) -> bool:
	if not is_active:
		return false

	if event is InputEventMouseMotion:
		if is_panning and camera_pivot:
			var delta = event.position - pan_last_mouse
			pan_last_mouse = event.position
			var yaw_rad = deg_to_rad(camera_pivot.rotation_degrees.y)
			var fwd = Vector3(-sin(yaw_rad), 0, -cos(yaw_rad))
			var right = Vector3(cos(yaw_rad), 0, -sin(yaw_rad))
			var move = (-right * delta.x + fwd * delta.y) * 0.05
			camera_pivot.global_position += move
			return true
		tool_handler.update_mouse_position(event.position)
		return false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			pan_last_mouse = event.position
			return true
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			tool_handler.on_mouse_button(event)
			return true

	if event is InputEventKey and event.pressed:
		var cmd_or_ctrl = event.ctrl_pressed or event.meta_pressed
		if cmd_or_ctrl and event.keycode == KEY_Z:
			if event.shift_pressed:
				redo()
			else:
				undo()
			return true
		elif cmd_or_ctrl and event.keycode == KEY_Y:
			redo()
			return true
		elif event.keycode == KEY_R and not cmd_or_ctrl:
			tool_handler.placement_rot_y = fmod(tool_handler.placement_rot_y + PI * 0.5, TAU)
			tool_handler._update_ghost_transform()
			ui.set_status_notice("Placement Rotation: %d°" % int(round(rad_to_deg(tool_handler.placement_rot_y))))
			return true
		elif event.keycode == KEY_ESCAPE:
			handle_escape()
			return true

	return false

func process_editor_pan(delta: float) -> void:
	if not is_active or not camera_pivot:
		return

	var pan_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): pan_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): pan_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): pan_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): pan_dir.x += 1.0

	if pan_dir != Vector2.ZERO:
		pan_dir = pan_dir.normalized()
		var yaw_rad = deg_to_rad(camera_pivot.rotation_degrees.y)
		var fwd = Vector3(-sin(yaw_rad), 0, -cos(yaw_rad))
		var right = Vector3(cos(yaw_rad), 0, -sin(yaw_rad))
		var move = (right * pan_dir.x + fwd * -pan_dir.y) * 24.0 * delta
		camera_pivot.global_position += move
