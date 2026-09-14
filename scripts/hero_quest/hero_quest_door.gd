class_name HeroQuestDoor
extends Node3D

## Controller node for interactive medieval doors and portcullis gates.
## Supports locked/open states, key consumption, animated opening, and grid walkability toggling.

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")

signal door_state_changed(is_open: bool, is_locked: bool)

@export var door_type: String = "wooden_door_1tile"
@export var is_open: bool = false
@export var is_locked: bool = false
@export var required_key: String = "Iron Key"
@export var consumes_key: bool = true
@export var axis: int = 0
@export var occupied_cells: Array[Vector2i] = []

var castle_builder: Node = null
var audio_manager: Node = null
var interactable: HeroQuestInteractable = null
var leaf_pivots: Array[Node3D] = []
var is_slide: bool = false

func setup(p_builder: Node, p_audio: Node, door_info: Dictionary, pivots: Array, slide: bool) -> void:
	castle_builder = p_builder
	audio_manager = p_audio
	leaf_pivots.clear()
	for p in pivots:
		if p is Node3D:
			leaf_pivots.append(p)
	is_slide = slide

	door_type = door_info.get("type", door_type)
	axis = int(door_info.get("axis", axis))
	is_open = bool(door_info.get("is_open", false))
	is_locked = bool(door_info.get("is_locked", false))
	required_key = str(door_info.get("required_key", "Iron Key"))
	consumes_key = bool(door_info.get("consumes_key", true))

	if door_info.has("occupied_cells"):
		occupied_cells = door_info["occupied_cells"]
	elif door_info.has("cell"):
		var c = door_info["cell"]
		var center_cell = c if c is Vector2i else Vector2i(c[0], c[1])
		occupied_cells = [center_cell]
		if "2tile" in door_type:
			var off = Vector2i(1, 0) if axis == 0 else Vector2i(0, 1)
			occupied_cells.append(center_cell + off)

	_setup_interactable()
	set_open(is_open, false)

func _setup_interactable() -> void:
	if interactable and is_instance_valid(interactable):
		return
	interactable = HeroQuestInteractable.new()
	interactable.name = "Interactable"
	interactable.interact_type = HeroQuestInteractable.InteractType.DOOR
	add_child(interactable)

func set_open(open_state: bool, animated: bool = true) -> void:
	is_open = open_state
	_apply_visual_pose(open_state, animated)
	_update_grid_walkability(open_state)
	door_state_changed.emit(is_open, is_locked)

func _apply_visual_pose(open_state: bool, animated: bool) -> void:
	if is_slide:
		var target_y = 3.2 if open_state else 0.0
		for p in leaf_pivots:
			if not is_instance_valid(p): continue
			if animated:
				var tween = create_tween()
				tween.tween_property(p, "position:y", target_y, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				if audio_manager and audio_manager.has_method("play_portcullis"):
					audio_manager.play_portcullis()
			else:
				p.position.y = target_y
	else:
		if leaf_pivots.size() == 1:
			var p = leaf_pivots[0]
			if is_instance_valid(p):
				var target_rot_y = (-PI * 0.5 if axis == 0 else PI * 0.5) if open_state else 0.0
				if animated:
					var tween = create_tween()
					tween.tween_property(p, "rotation:y", target_rot_y, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					_play_hinge_sfx(open_state)
				else:
					p.rotation.y = target_rot_y
		elif leaf_pivots.size() >= 2:
			var left_p = leaf_pivots[0]
			var right_p = leaf_pivots[1]
			var left_rot = (-PI * 0.5) if open_state else 0.0
			var right_rot = (PI * 0.5) if open_state else 0.0
			if animated:
				var tween = create_tween().set_parallel(true)
				if is_instance_valid(left_p):
					tween.tween_property(left_p, "rotation:y", left_rot, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				if is_instance_valid(right_p):
					tween.tween_property(right_p, "rotation:y", right_rot, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_play_hinge_sfx(open_state)
			else:
				if is_instance_valid(left_p): left_p.rotation.y = left_rot
				if is_instance_valid(right_p): right_p.rotation.y = right_rot

func _play_hinge_sfx(open_state: bool) -> void:
	if not audio_manager: return
	if open_state and audio_manager.has_method("play_door_open"):
		audio_manager.play_door_open()
	elif not open_state and audio_manager.has_method("play_door_close"):
		audio_manager.play_door_close()

func _update_grid_walkability(open_state: bool) -> void:
	if not castle_builder or not ("grid" in castle_builder) or not castle_builder.grid:
		return
	for c in occupied_cells:
		if castle_builder.grid.has(c):
			castle_builder.grid[c]["walkable"] = open_state

func get_door_prompt() -> String:
	if is_open:
		return "Press [E] or [SPACE] to close Door"
	if is_locked:
		return "Door is Locked (Requires %s)" % required_key
	return "Press [E] or [SPACE] to open Door"

func on_door_interacted(actor: Node3D, p_audio: Node = null) -> String:
	if p_audio:
		audio_manager = p_audio

	if is_locked:
		var has_key = false
		if actor and "inventory" in actor and actor.inventory:
			has_key = actor.inventory.has_item(required_key)

		if has_key:
			if consumes_key and actor and "inventory" in actor and actor.inventory:
				actor.inventory.consume_item(required_key)
			is_locked = false
			if audio_manager and audio_manager.has_method("play_door_unlock"):
				audio_manager.play_door_unlock()
			set_open(true, true)
			return "Unlocked and opened the door with %s!" % required_key
		else:
			if audio_manager and audio_manager.has_method("play_door_locked"):
				audio_manager.play_door_locked()
			return "The door is locked! You need the %s to open it." % required_key

	if is_open:
		set_open(false, true)
		return "Closed the door."
	else:
		set_open(true, true)
		return "Opened the door."
