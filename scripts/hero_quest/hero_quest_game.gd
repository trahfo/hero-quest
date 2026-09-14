extends Node3D

@export var player_scene: PackedScene = preload("res://scenes/hero_quest/hero_box.tscn")

@onready var castle_builder: Node3D = $CastleBuilder
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var hud: CanvasLayer = $HeroQuestHUD
@onready var audio_manager: Node = $HeroQuestAudio

const HeroQuestCameraOcclusion = preload("res://scripts/hero_quest/hero_quest_camera_occlusion.gd")
const LevelEditorClass = preload("res://scripts/hero_quest/editor/level_editor.gd")
const MiniGameManagerClass = preload("res://scripts/hero_quest/mini_game_manager.gd")
const HeroQuestMiniGameDialogClass = preload("res://scripts/hero_quest/mini_game_dialog.gd")

var player: CharacterBody3D
var occlusion_mgr: HeroQuestCameraOcclusion
var level_editor: LevelEditorClass
var mini_game_dialog: HeroQuestMiniGameDialogClass
var cam_distance: float = 24.0
var min_cam_distance: float = 12.0
var max_cam_distance: float = 38.0
var target_zoom: float = 24.0
var target_cam_yaw: float = 45.0

static var selected_level_path: String = "res://data/levels/first_level.json"
static var pending_level_name: String = ""
static var start_in_edit_mode: bool = false

var current_zone_name: String = ""

func _ready() -> void:
	var return_state = MiniGameManagerClass.consume_return_state()
	var spawn_tile = Vector2i(0, 0)
	if return_state.get("has_state", false):
		selected_level_path = return_state.get("level_path", "res://data/levels/first_level.json")
		spawn_tile = return_state.get("player_tile", Vector2i(0, 0))

	if castle_builder:
		if FileAccess.file_exists(selected_level_path):
			castle_builder.load_from_level_file(selected_level_path)
		else:
			castle_builder.init_new_level(pending_level_name if pending_level_name != "" else "New Castle Realm")

	# 1. Spawn Player in Central Hall or restored tile
	_spawn_player(spawn_tile)

	# 2. Setup Camera isometric view
	camera_pivot.rotation_degrees = Vector3(-38.0, target_cam_yaw, 0.0)
	_update_camera_zoom()

	# 3. Setup Camera Occlusion Fading (30% transparency for character obstruction)
	occlusion_mgr = HeroQuestCameraOcclusion.new()
	add_child(occlusion_mgr)
	occlusion_mgr.setup(camera, player)

	# 4. Connect HUD and Player signals
	if player:
		player.interaction_triggered.connect(_on_player_interaction)
		player.nearby_interactable_changed.connect(_on_player_prompt_changed)
		if player.has_signal("open_mini_game_dialog_requested"):
			player.open_mini_game_dialog_requested.connect(_on_open_mini_game_dialog)
		player.audio_manager = audio_manager
		if hud and hud.has_method("setup_player_ui"):
			hud.setup_player_ui(player)

	# 5. Initialize Mini-Game Dialog & Level Editor
	_init_mini_game_dialog()
	_init_level_editor()

	# 6. Initial zone update
	_update_zone(true)

	if hud:
		if return_state.get("has_state", false):
			hud.show_notice("Returned to Castle from %s!" % return_state.get("last_game_id", "mini-game").to_upper())
		else:
			var display_name = pending_level_name if pending_level_name != "" else selected_level_path.get_file().get_basename().capitalize()
			hud.show_notice("Hero Quest: %s\nPress [TAB] for Level Editor · [1-4] Character Archetypes" % display_name)

func _init_level_editor() -> void:
	level_editor = LevelEditorClass.new()
	add_child(level_editor)
	level_editor.setup(self, castle_builder, camera, camera_pivot, selected_level_path, pending_level_name)
	level_editor.status_message.connect(func(msg): if hud: hud.show_notice(msg))
	level_editor.editor_toggled.connect(_on_editor_toggled)

	if start_in_edit_mode:
		start_in_edit_mode = false
		level_editor.toggle_editor()

func _on_editor_toggled(active: bool) -> void:
	if player:
		player.set_physics_process(not active)
		player.set_process_unhandled_input(not active)
	if hud:
		hud.visible = not active
	if not active:
		_update_zone(true)

func _spawn_player(start_tile: Vector2i = Vector2i(0, 0)) -> void:
	if not player_scene:
		push_error("HeroBox player scene missing")
		return

	player = player_scene.instantiate()
	add_child(player)
	player.camera_pivot = camera_pivot
	player.setup(castle_builder, audio_manager, start_tile)

func _init_mini_game_dialog() -> void:
	mini_game_dialog = HeroQuestMiniGameDialogClass.new()
	add_child(mini_game_dialog)
	mini_game_dialog.play_requested.connect(_on_mini_game_play_requested)

func _on_open_mini_game_dialog(game_id: String, _source_node: Node3D = null) -> void:
	if mini_game_dialog:
		mini_game_dialog.show_dialog(game_id)

func _on_mini_game_play_requested(game_id: String) -> void:
	var tile = player.current_tile if player else Vector2i.ZERO
	MiniGameManagerClass.launch_mini_game(get_tree(), game_id, tile, selected_level_path)

func _process(delta: float) -> void:
	if level_editor and level_editor.is_active:
		level_editor.process_editor_pan(delta)
	elif player:
		# Smooth camera follow
		var target_pos = player.global_position
		camera_pivot.global_position = camera_pivot.global_position.lerp(target_pos, 8.0 * delta)

	# Smooth zoom
	cam_distance = lerpf(cam_distance, target_zoom, 10.0 * delta)
	_update_camera_zoom()

	# Smooth camera rotation around target
	var current_yaw = deg_to_rad(camera_pivot.rotation_degrees.y)
	var target_yaw_rad = deg_to_rad(target_cam_yaw)
	var new_yaw_rad = lerp_angle(current_yaw, target_yaw_rad, 10.0 * delta)
	camera_pivot.rotation_degrees.y = rad_to_deg(new_yaw_rad)

	# Check current zone
	if not (level_editor and level_editor.is_active):
		_update_zone(false)

	# Process camera obstruction fading (30% transparency)
	if occlusion_mgr:
		occlusion_mgr.process_occlusion(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			if level_editor:
				level_editor.toggle_editor()
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_ESCAPE:
			if level_editor and level_editor.is_active:
				level_editor.handle_escape()
				get_viewport().set_input_as_handled()
				return

func _unhandled_input(event: InputEvent) -> void:
	if level_editor and level_editor.is_active:
		if level_editor.handle_input(event):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clampf(target_zoom - 3.0, min_cam_distance, max_cam_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clampf(target_zoom + 3.0, min_cam_distance, max_cam_distance)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			target_zoom = clampf(target_zoom - 3.0, min_cam_distance, max_cam_distance)
		elif event.keycode == KEY_E and not player.nearby_interactable:
			target_zoom = clampf(target_zoom + 3.0, min_cam_distance, max_cam_distance)
		elif event.keycode == KEY_R:
			target_cam_yaw -= 90.0

func _update_camera_zoom() -> void:
	if camera:
		camera.position = Vector3(0, 0, cam_distance)

func _update_zone(force: bool) -> void:
	if not castle_builder or not player:
		return

	var zone = castle_builder.get_zone_at_position(player.global_position)
	if zone != current_zone_name or force:
		current_zone_name = zone
		if hud:
			hud.update_location(current_zone_name)

func _on_player_interaction(msg: String) -> void:
	if hud:
		hud.show_notice(msg)

func _on_player_prompt_changed(prompt: String) -> void:
	if hud:
		hud.show_prompt(prompt)
