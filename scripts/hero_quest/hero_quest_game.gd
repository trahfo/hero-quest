extends Node3D

@export var player_scene: PackedScene = preload("res://scenes/hero_quest/hero_box.tscn")

@onready var castle_builder: Node3D = $CastleBuilder
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var hud: CanvasLayer = $HeroQuestHUD
@onready var audio_manager: Node = $HeroQuestAudio

const HeroQuestCameraOcclusion = preload("res://scripts/hero_quest/hero_quest_camera_occlusion.gd")

var player: CharacterBody3D
var occlusion_mgr: HeroQuestCameraOcclusion
var cam_distance: float = 24.0
var min_cam_distance: float = 12.0
var max_cam_distance: float = 38.0
var target_zoom: float = 24.0
var target_cam_yaw: float = 45.0

var current_zone_name: String = ""

func _ready() -> void:
	# 1. Spawn Player in Central Hall
	_spawn_player()

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
		player.audio_manager = audio_manager

	# 5. Initial zone update
	_update_zone(true)

func _spawn_player() -> void:
	if not player_scene:
		push_error("HeroBox player scene missing")
		return

	player = player_scene.instantiate()
	add_child(player)
	player.setup(castle_builder, audio_manager, Vector2i(0, 0))

func _process(delta: float) -> void:
	if player:
		# Smooth camera follow
		var target_pos = player.global_position
		camera_pivot.global_position = camera_pivot.global_position.lerp(target_pos, 8.0 * delta)

		# Smooth zoom
		cam_distance = lerpf(cam_distance, target_zoom, 10.0 * delta)
		_update_camera_zoom()

		# Smooth camera rotation around player
		var current_yaw = deg_to_rad(camera_pivot.rotation_degrees.y)
		var target_yaw_rad = deg_to_rad(target_cam_yaw)
		var new_yaw_rad = lerp_angle(current_yaw, target_yaw_rad, 10.0 * delta)
		camera_pivot.rotation_degrees.y = rad_to_deg(new_yaw_rad)

		# Check current zone
		_update_zone(false)

		# Process camera obstruction fading (30% transparency)
		if occlusion_mgr:
			occlusion_mgr.process_occlusion(delta)

func _unhandled_input(event: InputEvent) -> void:
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
