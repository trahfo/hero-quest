class_name HeroQuestInteractable
extends Node

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const ItemDatabase = preload("res://scripts/hero_quest/item_database.gd")

signal interacted(notice: String)
signal loot_opened(item_data: ItemData, world_pos: Vector3, source_node: Node3D)
signal mini_game_triggered(game_id: String, source_node: Node3D)

enum InteractType {
	CHEST,
	ANVIL,
	BELL,
	ALTAR,
	INSPECT,
	ITEM,
	CUSTOM
}

@export var interact_type: InteractType = InteractType.CUSTOM
@export var loot_name: String = "Ancient Relic"
@export var custom_prompt: String = "Press [E] or [SPACE] to interact"
@export var is_opened: bool = false
@export var mini_game_id: String = ""
var item_data: ItemData = null

func get_prompt_text() -> String:
	match interact_type:
		InteractType.CHEST:
			var effective_mini = _get_effective_mini_game()
			if is_opened:
				if effective_mini != "":
					return "Press [E] to examine Arcade Relic"
				return "Chest (Opened)"
			return "Press [E] or [SPACE] to open Treasure Chest"
		InteractType.ANVIL:
			return "Press [E] or [SPACE] to strike Forge Anvil"
		InteractType.BELL:
			return "Press [E] or [SPACE] to ring Chapel Bell"
		InteractType.ALTAR:
			return "Press [E] or [SPACE] to pray at Holy Altar"
		InteractType.INSPECT:
			return custom_prompt
		_:
			return custom_prompt

func interact(actor: Node3D, audio_manager: Node = null) -> String:
	var notice = ""
	var parent = get_parent() as Node3D

	match interact_type:
		InteractType.CHEST:
			var effective_mini = _get_effective_mini_game()
			if not is_opened:
				is_opened = true
				if parent and parent.has_meta("is_opened"):
					parent.set_meta("is_opened", true)
				if parent:
					var lid = parent.get_node_or_null("ChestLid")
					if lid:
						var tween = parent.create_tween()
						tween.tween_property(lid, "rotation:x", -PI * 0.45, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if audio_manager and audio_manager.has_method("play_chest"):
					audio_manager.play_chest()
				if effective_mini != "":
					mini_game_triggered.emit(effective_mini, parent)
					if actor and actor.has_method("on_mini_game_triggered"):
						actor.on_mini_game_triggered(effective_mini, parent)
					notice = "✨ Easter Egg Discovered: " + loot_name + "! ✨"
				else:
					if not item_data:
						item_data = ItemDatabase.get_item_by_name(loot_name)
					var pos = parent.global_position if parent else Vector3.ZERO
					loot_opened.emit(item_data, pos, parent)
					if actor and actor.has_method("on_loot_opened"):
						actor.on_loot_opened(item_data, pos, parent)
					notice = "Discovered: " + loot_name + "!"
			else:
				if effective_mini != "":
					mini_game_triggered.emit(effective_mini, parent)
					if actor and actor.has_method("on_mini_game_triggered"):
						actor.on_mini_game_triggered(effective_mini, parent)
					notice = "Examining Easter Egg: " + loot_name
				else:
					notice = "The chest is already empty."

		InteractType.ITEM:
			if not item_data:
				item_data = ItemDatabase.get_item_by_name(loot_name)
			var pos = parent.global_position if parent else Vector3.ZERO
			loot_opened.emit(item_data, pos, parent)
			if actor and actor.has_method("on_loot_opened"):
				actor.on_loot_opened(item_data, pos, parent)
			notice = "Inspecting: " + loot_name

		InteractType.ANVIL:
			if audio_manager and audio_manager.has_method("play_anvil"):
				audio_manager.play_anvil()
			if actor and actor.get_node_or_null("Visuals"):
				var vis = actor.get_node("Visuals")
				var tween = actor.create_tween()
				tween.tween_property(vis, "scale", Vector3(1.2, 0.8, 1.2), 0.08)
				tween.tween_property(vis, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
			notice = "Struck the Master Anvil! Iron sparks fly!"

		InteractType.BELL:
			if audio_manager and audio_manager.has_method("play_chapel_bell"):
				audio_manager.play_chapel_bell()
			if parent:
				var tween = parent.create_tween()
				tween.tween_property(parent, "rotation:z", 0.35, 0.15)
				tween.tween_property(parent, "rotation:z", -0.3, 0.2)
				tween.tween_property(parent, "rotation:z", 0.0, 0.3)
			notice = "Tolled the Holy Chapel Bell! Divine echoes resound."

		InteractType.ALTAR:
			if audio_manager and audio_manager.has_method("play_chapel_bell"):
				audio_manager.play_chapel_bell()
			notice = "Prayed at the Altar. Blessed with courage and light."

		InteractType.INSPECT:
			notice = custom_prompt

		_:
			notice = "Interacted."

	interacted.emit(notice)
	return notice

func _get_effective_mini_game() -> String:
	if mini_game_id != "":
		return mini_game_id
	var parent = get_parent() as Node3D
	if parent and parent.has_meta("mini_game_id"):
		return str(parent.get_meta("mini_game_id"))
	return ""
