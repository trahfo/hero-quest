class_name HeroQuestInteractableResolver
extends RefCounted

## Locates (or lazily creates) the HeroQuestInteractable component of a world prop.

const HeroQuestInteractable = preload("res://scripts/hero_quest/hero_quest_interactable.gd")
const HeroQuestDoor = preload("res://scripts/hero_quest/hero_quest_door.gd")

static func find_interactable(prop: Node3D) -> HeroQuestInteractable:
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

static func create_fallback_interactable(prop: Node3D) -> HeroQuestInteractable:
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
