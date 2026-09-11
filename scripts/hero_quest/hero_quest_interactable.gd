class_name HeroQuestInteractable
extends Node

signal interacted(notice: String)

enum InteractType {
	CHEST,
	ANVIL,
	BELL,
	ALTAR,
	INSPECT,
	CUSTOM
}

@export var interact_type: InteractType = InteractType.CUSTOM
@export var loot_name: String = "Ancient Relic"
@export var custom_prompt: String = "Press [E] or [SPACE] to interact"
@export var is_opened: bool = false

func get_prompt_text() -> String:
	match interact_type:
		InteractType.CHEST:
			if is_opened:
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
				notice = "Discovered: " + loot_name + "!"
			else:
				notice = "The chest is already empty."

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
