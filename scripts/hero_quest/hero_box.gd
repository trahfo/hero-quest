extends CharacterBody3D

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")
const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const ItemDatabase = preload("res://scripts/hero_quest/item_database.gd")
const HeroStats = preload("res://scripts/hero_quest/hero_stats.gd")
const HeroInventory = preload("res://scripts/hero_quest/hero_inventory.gd")
const HeroQuestFloorItem = preload("res://scripts/hero_quest/hero_quest_floor_item.gd")
const HumanoidVisuals = preload("res://scripts/hero_quest/character/humanoid_visuals.gd")
const HumanoidAppearanceData = preload("res://scripts/hero_quest/character/humanoid_appearance_data.gd")

signal interaction_triggered(message: String)
signal nearby_interactable_changed(text: String)
signal open_loot_dialog_requested(item: ItemData, pos: Vector3)
signal open_mini_game_dialog_requested(game_id: String, source_node: Node3D)
signal toggle_character_sheet_requested

@export var step_duration: float = 0.28 # Brisk smooth tile walking stride

var castle_builder: Node = null
var audio_manager: Node = null
var stats: HeroStats = null
var inventory: HeroInventory = null
var floor_items: Array = []
var active_loot_source_node: Node3D = null

var current_tile: Vector2i = Vector2i.ZERO
var target_tile: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var move_progress: float = 0.0
var move_start_pos: Vector3 = Vector3.ZERO
var move_target_pos: Vector3 = Vector3.ZERO

@onready var visuals: Node3D = $Visuals
@onready var lantern_light: OmniLight3D = $LanternLight

var camera_pivot: Node3D = null
var humanoid_visuals: HumanoidVisuals = null
var target_facing_angle: float = 0.0
var current_archetype_index: int = 1

var nearby_interactable_node: Node3D = null
var nearby_interactable_comp: HeroQuestInteractable = null
var nearby_interactable: Node3D:
	get: return nearby_interactable_node if is_instance_valid(nearby_interactable_node) else null

func _ready() -> void:
	add_to_group("player")
	if castle_builder:
		global_position = castle_builder.grid_to_world(current_tile)
	else:
		position = Vector3(0, 0, 0)
	visuals.position = Vector3(0, 0, 0)
	_ensure_humanoid_visuals()

func setup(builder: Node, audio: Node, start_tile: Vector2i = Vector2i.ZERO) -> void:
	castle_builder = builder
	audio_manager = audio
	current_tile = start_tile
	target_tile = start_tile
	_init_components()
	if castle_builder:
		global_position = castle_builder.grid_to_world(current_tile)
	visuals.position = Vector3(0, 0, 0)
	_ensure_humanoid_visuals()
	_check_interaction_proximity()

func _ensure_humanoid_visuals() -> void:
	if humanoid_visuals and is_instance_valid(humanoid_visuals):
		return
	for child in visuals.get_children():
		child.queue_free()
	humanoid_visuals = HumanoidVisuals.new()
	visuals.add_child(humanoid_visuals)
	humanoid_visuals.apply_appearance(HumanoidAppearanceData.create_hero())

func _init_components() -> void:
	if not stats:
		stats = HeroStats.new()
	if not inventory:
		inventory = HeroInventory.new(stats)
		_setup_starter_gear()

func _setup_starter_gear() -> void:
	var belt = ItemDatabase.create_item("leather_belt")
	var sword = ItemDatabase.create_item("rusted_shortsword")
	var potion = ItemDatabase.create_item("healing_potion")
	inventory.equip("belt", belt)
	inventory.equip("main_hand", sword)
	inventory.add_to_belt(potion)

func _physics_process(delta: float) -> void:
	# Smoothly rotate character toward target facing angle
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_facing_angle, 16.0 * delta)

	if is_moving:
		_process_tile_movement(delta)
	else:
		_poll_tile_input()

static func rotate_dir_by_camera(dir: Vector2i, cam_yaw: float) -> Vector2i:
	var k = posmod(roundi((45.0 - cam_yaw) / 90.0), 4)
	match k:
		1: return Vector2i(-dir.y, dir.x)
		2: return Vector2i(-dir.x, -dir.y)
		3: return Vector2i(dir.y, -dir.x)
		_: return dir

func _get_input_dir() -> Vector2i:
	var move_dir = Vector2i.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		move_dir = Vector2i(0, -1) # Base North (-Z)
	elif Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		move_dir = Vector2i(0, 1)  # Base South (+Z)
	elif Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		move_dir = Vector2i(-1, 0) # Base West (-X)
	elif Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		move_dir = Vector2i(1, 0)  # Base East (+X)

	if move_dir != Vector2i.ZERO:
		var yaw = 45.0
		if camera_pivot and is_instance_valid(camera_pivot):
			yaw = camera_pivot.rotation_degrees.y
		elif get_viewport() and get_viewport().get_camera_3d() and is_instance_valid(get_viewport().get_camera_3d().get_parent()):
			yaw = get_viewport().get_camera_3d().get_parent().rotation_degrees.y
		move_dir = rotate_dir_by_camera(move_dir, yaw)

	return move_dir

func _process_tile_movement(delta: float) -> void:
	move_progress += delta / step_duration
	var t = clampf(move_progress, 0.0, 1.0)

	var next_queued_dir = _get_input_dir()
	var can_continue = (next_queued_dir == facing_dir) and castle_builder and castle_builder.is_tile_walkable(target_tile + facing_dir)

	# When chaining steps across multiple tiles, maintain uniform linear speed (walk walk walk as one)
	# Only ease out to a stop when arriving at the final destination tile.
	var interp_t = t if can_continue else sin(t * PI * 0.5)

	global_position.x = lerpf(move_start_pos.x, move_target_pos.x, interp_t)
	global_position.z = lerpf(move_start_pos.z, move_target_pos.z, interp_t)
	visuals.position = Vector3.ZERO

	var speed_ratio = 0.8 / (step_duration * 2.0)
	if humanoid_visuals:
		humanoid_visuals.set_moving(true, speed_ratio)

	if t >= 1.0:
		global_position = move_target_pos
		current_tile = target_tile
		_check_interaction_proximity()

		if can_continue:
			# Seamlessly continue into next tile with zero stop/hitch!
			move_progress -= 1.0
			target_tile = current_tile + facing_dir
			move_start_pos = global_position
			move_target_pos = castle_builder.grid_to_world(target_tile)
			if audio_manager and audio_manager.has_method("play_footstep"):
				audio_manager.play_footstep()
		else:
			is_moving = false
			_poll_tile_input()

func _poll_tile_input() -> void:
	var move_dir = _get_input_dir()
	if move_dir != Vector2i.ZERO:
		_try_step_to_tile(current_tile + move_dir, move_dir)
	elif not is_moving:
		if humanoid_visuals:
			humanoid_visuals.set_moving(false)

var facing_dir: Vector2i = Vector2i(0, -1)

func _try_step_to_tile(next_tile: Vector2i, dir: Vector2i) -> void:
	facing_dir = dir
	target_facing_angle = atan2(-dir.x, -dir.y)

	if not castle_builder or not castle_builder.is_tile_walkable(next_tile):
		_bump_feedback(dir)
		_check_interaction_proximity()
		return

	is_moving = true
	move_progress = 0.0
	target_tile = next_tile
	move_start_pos = global_position
	move_target_pos = castle_builder.grid_to_world(next_tile)

	var speed_ratio = 0.8 / (step_duration * 2.0)
	if humanoid_visuals:
		humanoid_visuals.set_moving(true, speed_ratio)

	if audio_manager and audio_manager.has_method("play_footstep"):
		audio_manager.play_footstep()

func _bump_feedback(dir: Vector2i) -> void:
	var tween = create_tween()
	var nudge = Vector3(dir.x * 0.08, 0, dir.y * 0.08)
	tween.tween_property(visuals, "position", nudge, 0.04)
	tween.tween_property(visuals, "position", Vector3.ZERO, 0.08)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE)):
		_try_interact()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_C or event.keycode == KEY_I):
		toggle_character_sheet_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_switch_archetype(1)
		elif event.keycode == KEY_2:
			_switch_archetype(2)
		elif event.keycode == KEY_3:
			_switch_archetype(3)
		elif event.keycode == KEY_4:
			_switch_archetype(4)

func _switch_archetype(idx: int) -> void:
	current_archetype_index = idx
	var data: HumanoidAppearanceData
	match idx:
		1: data = HumanoidAppearanceData.create_hero()
		2: data = HumanoidAppearanceData.create_guard()
		3: data = HumanoidAppearanceData.create_ranger()
		4: data = HumanoidAppearanceData.create_wizard()
		_: data = HumanoidAppearanceData.create_hero()

	if humanoid_visuals:
		humanoid_visuals.apply_appearance(data)

func refresh_nearby_interactable() -> void:
	nearby_interactable_node = null
	nearby_interactable_comp = null
	_check_interaction_proximity()

func _get_prop_at_cell(cell: Vector2i) -> Node3D:
	if not castle_builder or not is_instance_valid(castle_builder) or not ("grid" in castle_builder) or not castle_builder.grid.has(cell):
		return null
	var prop = castle_builder.grid[cell].get("prop", null)
	if is_instance_valid(prop):
		return prop
	for item in floor_items:
		if is_instance_valid(item) and castle_builder.world_to_grid(item.global_position) == cell:
			return item
	for chest in castle_builder.interactive_chests:
		if is_instance_valid(chest) and castle_builder.world_to_grid(chest.global_position) == cell:
			return chest
	if is_instance_valid(castle_builder.interactive_anvil):
		if castle_builder.world_to_grid(castle_builder.interactive_anvil.global_position) == cell:
			return castle_builder.interactive_anvil
	if is_instance_valid(castle_builder.interactive_bell):
		if castle_builder.world_to_grid(castle_builder.interactive_bell.global_position) == cell:
			return castle_builder.interactive_bell
	if is_instance_valid(castle_builder.interactive_altar):
		if castle_builder.world_to_grid(castle_builder.interactive_altar.global_position) == cell:
			return castle_builder.interactive_altar
	return null

func _check_interaction_proximity() -> void:
	if not castle_builder or not is_instance_valid(castle_builder):
		return

	if not is_instance_valid(nearby_interactable_node):
		nearby_interactable_node = null
	if not is_instance_valid(nearby_interactable_comp):
		nearby_interactable_comp = null

	var found_node: Node3D = null
	var found_comp: HeroQuestInteractable = null

	# 1. Directly facing cell has highest priority
	var facing_cell = current_tile + facing_dir
	var facing_prop = _get_prop_at_cell(facing_cell)
	if is_instance_valid(facing_prop):
		var comp = _find_interactable(facing_prop)
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
			if is_instance_valid(prop):
				var comp = _find_interactable(prop)
				if not comp and (prop.has_meta("is_chest") or prop.name in ["BlacksmithAnvil", "ChapelBell", "AltarTable"]):
					comp = _create_fallback_interactable(prop)
				if comp and comp.interact_type != HeroQuestInteractable.InteractType.INSPECT:
					found_node = prop
					found_comp = comp
					break

	if not is_instance_valid(found_node):
		found_node = null
		found_comp = null

	var prev_node = nearby_interactable_node if is_instance_valid(nearby_interactable_node) else null

	if found_node != prev_node:
		nearby_interactable_node = found_node
		nearby_interactable_comp = found_comp
		var prompt = nearby_interactable_comp.get_prompt_text() if is_instance_valid(nearby_interactable_comp) else ""
		nearby_interactable_changed.emit(prompt)


func _find_interactable(prop: Node3D) -> HeroQuestInteractable:
	if not is_instance_valid(prop): return null
	var comp = prop.get_node_or_null("Interactable") as HeroQuestInteractable
	if comp and is_instance_valid(comp): return comp
	var door_ctrl = prop.get_node_or_null("DoorController")
	if is_instance_valid(door_ctrl):
		comp = door_ctrl.get_node_or_null("Interactable") as HeroQuestInteractable
		if comp and is_instance_valid(comp): return comp
	for child in prop.get_children():
		if child is HeroQuestInteractable and is_instance_valid(child): return child
		if child is HeroQuestDoor and is_instance_valid(child):
			var door_comp = child.get_node_or_null("Interactable") as HeroQuestInteractable
			if door_comp and is_instance_valid(door_comp): return door_comp
	return null

func _create_fallback_interactable(prop: Node3D) -> HeroQuestInteractable:
	if not is_instance_valid(prop): return null
	var comp = HeroQuestInteractable.new()
	comp.name = "Interactable"
	if prop.has_meta("is_chest"):
		comp.interact_type = HeroQuestInteractable.InteractType.CHEST
		comp.loot_name = prop.get_meta("loot_name") if prop.has_meta("loot_name") else "Treasure"
		comp.is_opened = prop.get_meta("is_opened") if prop.has_meta("is_opened") else false
		if prop.has_meta("mini_game_id"):
			comp.mini_game_id = str(prop.get_meta("mini_game_id"))
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
		if prop.has_meta("mini_game_id"):
			comp.mini_game_id = str(prop.get_meta("mini_game_id"))
	prop.add_child(comp)
	return comp

func _try_interact() -> void:
	if not is_instance_valid(nearby_interactable_comp):
		nearby_interactable_comp = null
		nearby_interactable_node = null
		return

	var notice = nearby_interactable_comp.interact(self, audio_manager)
	interaction_triggered.emit(notice)
	var prompt = nearby_interactable_comp.get_prompt_text() if is_instance_valid(nearby_interactable_comp) else ""
	nearby_interactable_changed.emit(prompt)

func on_mini_game_triggered(game_id: String, source_node: Node3D = null) -> void:
	active_loot_source_node = source_node
	open_mini_game_dialog_requested.emit(game_id, source_node)

func on_loot_opened(item: ItemData, pos: Vector3, source_node: Node3D = null) -> void:
	active_loot_source_node = source_node
	open_loot_dialog_requested.emit(item, pos)

func on_loot_collected(item: ItemData) -> void:
	if is_instance_valid(active_loot_source_node):
		if active_loot_source_node is HeroQuestFloorItem:
			floor_items.erase(active_loot_source_node)
			active_loot_source_node.queue_free()
	active_loot_source_node = null
	var valid_floor_items: Array = []
	for fi in floor_items:
		if is_instance_valid(fi):
			valid_floor_items.append(fi)
	floor_items = valid_floor_items
	_check_interaction_proximity()

func drop_item_to_world(item: ItemData, drop_pos: Vector3 = Vector3.ZERO) -> HeroQuestFloorItem:
	if not item: return null
	var floor_item = HeroQuestFloorItem.new()
	var pos = drop_pos
	if pos == Vector3.ZERO:
		pos = global_position
	pos.y = 0.15
	if castle_builder:
		castle_builder.add_child(floor_item)
	elif get_parent():
		get_parent().add_child(floor_item)
	else:
		add_child(floor_item)

	floor_item.setup(item, pos)
	floor_items.append(floor_item)
	_check_interaction_proximity()
	return floor_item
