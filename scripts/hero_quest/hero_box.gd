extends CharacterBody3D

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

signal interaction_triggered(message: String)
signal nearby_interactable_changed(text: String)

@export var step_duration: float = 0.16 # Time to hop from one square tile to the next

var castle_builder: Node = null
var audio_manager: Node = null

var current_tile: Vector2i = Vector2i.ZERO
var target_tile: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var move_progress: float = 0.0
var move_start_pos: Vector3 = Vector3.ZERO
var move_target_pos: Vector3 = Vector3.ZERO

@onready var visuals: Node3D = $Visuals
@onready var lantern_light: OmniLight3D = $LanternLight
@onready var tile_cursor: Node3D = $TileCursor

var nearby_interactable_node: Node3D = null
var nearby_interactable_comp: HeroQuestInteractable = null
var nearby_interactable: Node3D:
	get: return nearby_interactable_node

func _ready() -> void:
	add_to_group("player")
	if castle_builder:
		global_position = castle_builder.grid_to_world(current_tile)
	else:
		global_position = Vector3(0, 0, 0)
	visuals.position = Vector3(0, 0.5, 0)

func setup(builder: Node, audio: Node, start_tile: Vector2i = Vector2i.ZERO) -> void:
	castle_builder = builder
	audio_manager = audio
	current_tile = start_tile
	target_tile = start_tile
	if castle_builder:
		global_position = castle_builder.grid_to_world(current_tile)
	visuals.position = Vector3(0, 0.5, 0)
	_check_interaction_proximity()

func _physics_process(delta: float) -> void:
	if is_moving:
		_process_tile_movement(delta)
	else:
		_poll_tile_input()

func _process_tile_movement(delta: float) -> void:
	move_progress += delta / step_duration
	var t = clampf(move_progress, 0.0, 1.0)

	var ease_t = 0.5 - 0.5 * cos(t * PI)
	global_position.x = lerpf(move_start_pos.x, move_target_pos.x, ease_t)
	global_position.z = lerpf(move_start_pos.z, move_target_pos.z, ease_t)

	visuals.position.y = 0.5 + sin(t * PI) * 0.22

	if t >= 1.0:
		global_position = move_target_pos
		visuals.position.y = 0.5
		visuals.rotation.z = 0.0
		current_tile = target_tile
		is_moving = false
		_check_interaction_proximity()

func _poll_tile_input() -> void:
	var move_dir = Vector2i.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		move_dir = Vector2i(0, -1) # North
	elif Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		move_dir = Vector2i(0, 1)  # South
	elif Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		move_dir = Vector2i(-1, 0) # West
	elif Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		move_dir = Vector2i(1, 0)  # East

	if move_dir != Vector2i.ZERO:
		_try_step_to_tile(current_tile + move_dir, move_dir)

var facing_dir: Vector2i = Vector2i(0, -1)

func _try_step_to_tile(next_tile: Vector2i, dir: Vector2i) -> void:
	facing_dir = dir
	var angle = atan2(dir.x, dir.y)
	visuals.rotation.y = angle

	if not castle_builder or not castle_builder.is_tile_walkable(next_tile):
		_bump_feedback(dir)
		_check_interaction_proximity()
		return

	is_moving = true
	move_progress = 0.0
	target_tile = next_tile
	move_start_pos = global_position
	move_target_pos = castle_builder.grid_to_world(next_tile)

	if audio_manager and audio_manager.has_method("play_footstep"):
		audio_manager.play_footstep()

func _bump_feedback(dir: Vector2i) -> void:
	var tween = create_tween()
	var nudge = Vector3(dir.x * 0.12, 0, dir.y * 0.12)
	tween.tween_property(visuals, "position", Vector3(0, 0.5, 0) + nudge, 0.04)
	tween.tween_property(visuals, "position", Vector3(0, 0.5, 0), 0.08)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE)):
		_try_interact()

func _get_prop_at_cell(cell: Vector2i) -> Node3D:
	if not castle_builder or not castle_builder.grid.has(cell):
		return null
	var prop = castle_builder.grid[cell].get("prop", null)
	if not prop:
		for chest in castle_builder.interactive_chests:
			if is_instance_valid(chest) and castle_builder.world_to_grid(chest.global_position) == cell:
				return chest
		if castle_builder.interactive_anvil and is_instance_valid(castle_builder.interactive_anvil):
			if castle_builder.world_to_grid(castle_builder.interactive_anvil.global_position) == cell:
				return castle_builder.interactive_anvil
		if castle_builder.interactive_bell and is_instance_valid(castle_builder.interactive_bell):
			if castle_builder.world_to_grid(castle_builder.interactive_bell.global_position) == cell:
				return castle_builder.interactive_bell
		if castle_builder.interactive_altar and is_instance_valid(castle_builder.interactive_altar):
			if castle_builder.world_to_grid(castle_builder.interactive_altar.global_position) == cell:
				return castle_builder.interactive_altar
	return prop

func _check_interaction_proximity() -> void:
	if not castle_builder:
		return

	var found_node: Node3D = null
	var found_comp: HeroQuestInteractable = null

	# 1. Directly facing cell has highest priority
	var facing_cell = current_tile + facing_dir
	var facing_prop = _get_prop_at_cell(facing_cell)
	if facing_prop and is_instance_valid(facing_prop):
		var comp = facing_prop.get_node_or_null("Interactable") as HeroQuestInteractable
		if not comp:
			comp = _create_fallback_interactable(facing_prop)
		if comp:
			found_node = facing_prop
			found_comp = comp

	# 2. If nothing directly facing, search adjacent cells for actionable interactables
	if not found_node:
		var check_offsets = [
			Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i.ZERO
		]
		for offset in check_offsets:
			var check_cell = current_tile + offset
			var prop = _get_prop_at_cell(check_cell)
			if prop and is_instance_valid(prop):
				var comp = prop.get_node_or_null("Interactable") as HeroQuestInteractable
				if not comp and (prop.has_meta("is_chest") or prop.name in ["BlacksmithAnvil", "ChapelBell", "AltarTable"]):
					comp = _create_fallback_interactable(prop)
				if comp and comp.interact_type != HeroQuestInteractable.InteractType.INSPECT:
					found_node = prop
					found_comp = comp
					break

	if found_node != nearby_interactable_node:
		nearby_interactable_node = found_node
		nearby_interactable_comp = found_comp
		var prompt = nearby_interactable_comp.get_prompt_text() if nearby_interactable_comp else ""
		nearby_interactable_changed.emit(prompt)

func _create_fallback_interactable(prop: Node3D) -> HeroQuestInteractable:
	var comp = HeroQuestInteractable.new()
	comp.name = "Interactable"
	if prop.has_meta("is_chest"):
		comp.interact_type = HeroQuestInteractable.InteractType.CHEST
		comp.loot_name = prop.get_meta("loot_name") if prop.has_meta("loot_name") else "Treasure"
		comp.is_opened = prop.get_meta("is_opened") if prop.has_meta("is_opened") else false
	elif prop.name == "BlacksmithAnvil":
		comp.interact_type = HeroQuestInteractable.InteractType.ANVIL
	elif prop.name == "ChapelBell":
		comp.interact_type = HeroQuestInteractable.InteractType.BELL
	elif prop.name == "AltarTable":
		comp.interact_type = HeroQuestInteractable.InteractType.ALTAR
	else:
		comp.interact_type = HeroQuestInteractable.InteractType.INSPECT
		var clean_name = prop.name.replace("@", "")
		comp.custom_prompt = prop.get_meta("prop_name", clean_name)
	prop.add_child(comp)
	return comp

func _try_interact() -> void:
	if not nearby_interactable_comp:
		return

	var notice = nearby_interactable_comp.interact(self, audio_manager)
	interaction_triggered.emit(notice)
	nearby_interactable_changed.emit(nearby_interactable_comp.get_prompt_text())
