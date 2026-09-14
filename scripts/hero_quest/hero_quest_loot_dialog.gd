class_name HeroQuestLootDialog
extends Control

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const HeroQuestCharacterSheet = preload("res://scripts/hero_quest/hero_quest_character_sheet.gd")

signal loot_taken(item: ItemData)
signal loot_dropped_to_floor(item: ItemData, pos: Vector3)
signal closed

var current_item: ItemData = null
var source_pos: Vector3 = Vector3.ZERO
var character_sheet: HeroQuestCharacterSheet = null

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var item_icon_label: Label = $Panel/Margin/VBox/ItemCard/HBox/IconBox/IconLabel
@onready var item_name_label: Label = $Panel/Margin/VBox/ItemCard/HBox/InfoBox/NameLabel
@onready var slot_badge_label: Label = $Panel/Margin/VBox/ItemCard/HBox/InfoBox/SlotBadge
@onready var stats_diff_label: Label = $Panel/Margin/VBox/StatsDiffBox/StatsDiffLabel
@onready var desc_label: Label = $Panel/Margin/VBox/DescLabel
@onready var equip_button: Button = $Panel/Margin/VBox/ButtonHBox/EquipButton
@onready var rucksack_button: Button = $Panel/Margin/VBox/ButtonHBox/RucksackButton
@onready var drop_button: Button = $Panel/Margin/VBox/ButtonHBox/DropButton
@onready var close_button: Button = $Panel/Margin/VBox/ButtonHBox/CloseButton

func _ready() -> void:
	if equip_button: equip_button.pressed.connect(_on_equip_pressed)
	if rucksack_button: rucksack_button.pressed.connect(_on_rucksack_pressed)
	if drop_button: drop_button.pressed.connect(_on_drop_pressed)
	if close_button: close_button.pressed.connect(_on_close_pressed)

func open_dialog(item: ItemData, drop_pos: Vector3, sheet: HeroQuestCharacterSheet) -> void:
	current_item = item
	source_pos = drop_pos
	character_sheet = sheet
	visible = true

	if not current_item:
		return

	if item_name_label:
		item_name_label.text = current_item.name
		item_name_label.modulate = current_item.rarity_color

	if item_icon_label:
		item_icon_label.text = current_item.icon_symbol

	if slot_badge_label:
		slot_badge_label.text = "Type: %s (%s)" % [current_item.get_slot_name(), "Large 1x2" if current_item.is_large() else "Small 1x1"]

	if desc_label:
		desc_label.text = current_item.description

	_update_stats_comparison()

func _update_stats_comparison() -> void:
	if not stats_diff_label or not current_item: return

	var text = "✨ " + current_item.get_stat_summary()

	if character_sheet and character_sheet.inventory:
		var slot_to_check = _get_target_slot_for_item(current_item)
		if slot_to_check != "":
			var current_equipped = character_sheet.inventory.equipped.get(slot_to_check)
			if current_equipped:
				var diff_parts: Array[String] = []
				var atk_diff = current_item.attack_strength - current_equipped.attack_strength
				var arm_diff = current_item.armor - current_equipped.armor
				if atk_diff > 0:
					diff_parts.append("+%d Attack vs equipped %s!" % [atk_diff, current_equipped.name])
				elif atk_diff < 0:
					diff_parts.append("%d Attack vs equipped %s" % [atk_diff, current_equipped.name])
				if arm_diff > 0:
					diff_parts.append("+%d Defend vs equipped %s!" % [arm_diff, current_equipped.name])
				elif arm_diff < 0:
					diff_parts.append("%d Defend vs equipped %s" % [arm_diff, current_equipped.name])

				if not diff_parts.is_empty():
					text += "\n⚔️ " + ", ".join(diff_parts)

	stats_diff_label.text = text

func _get_target_slot_for_item(item: ItemData) -> String:
	match item.slot_type:
		ItemData.SlotType.MAIN_HAND: return "main_hand"
		ItemData.SlotType.OFF_HAND: return "off_hand"
		ItemData.SlotType.HELMET: return "helmet"
		ItemData.SlotType.BREAST_HARNESS: return "breast_harness"
		ItemData.SlotType.GAUNTLET: return "gauntlet"
		ItemData.SlotType.FEET_HARNESS: return "feet_harness"
		ItemData.SlotType.BOOTS: return "boots"
		ItemData.SlotType.BELT: return "belt"
	return ""

func _on_equip_pressed() -> void:
	if not current_item or not character_sheet: return
	var target_slot = _get_target_slot_for_item(current_item)

	if target_slot != "":
		character_sheet.handle_item_dropped(current_item, target_slot)
	else:
		character_sheet.handle_item_dropped(current_item)

	loot_taken.emit(current_item)
	close_dialog()

func _on_rucksack_pressed() -> void:
	if not current_item or not character_sheet: return
	if character_sheet.inventory.add_to_first_rucksack_slot(current_item):
		loot_taken.emit(current_item)
	else:
		loot_dropped_to_floor.emit(current_item, source_pos)
	close_dialog()

func _on_drop_pressed() -> void:
	if current_item:
		loot_dropped_to_floor.emit(current_item, source_pos)
	close_dialog()

func _on_close_pressed() -> void:
	if current_item:
		loot_dropped_to_floor.emit(current_item, source_pos)
	close_dialog()

func close_dialog() -> void:
	visible = false
	current_item = null
	closed.emit()
