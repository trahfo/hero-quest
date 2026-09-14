class_name HeroQuestCharacterSheet
extends Control

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const HeroInventory = preload("res://scripts/hero_quest/hero_inventory.gd")
const HeroStats = preload("res://scripts/hero_quest/hero_stats.gd")

signal item_dropped_to_floor(item: ItemData)
signal item_swapped(old_item: ItemData, new_item: ItemData, slot: String)
signal closed

var inventory: HeroInventory = null
var stats: HeroStats = null

# Equipment slot UI nodes
var slot_buttons: Dictionary = {}

# Belt UI nodes
var belt_panel: PanelContainer = null
var belt_locked_label: Label = null
var belt_slots_ui: Array = []

# Rucksack UI nodes (16 cells)
var rucksack_cells: Array = []

# Stat display labels
var label_hp: Label = null
var label_mind: Label = null
var label_attack: Label = null
var label_armor: Label = null
var label_speed: Label = null

func setup(hero_inv: HeroInventory, hero_stats: HeroStats) -> void:
	inventory = hero_inv
	stats = hero_stats

	if inventory:
		inventory.inventory_changed.connect(refresh_ui)
	if stats:
		stats.stats_changed.connect(_on_stats_changed)

	_bind_ui_nodes()
	refresh_ui()

func _bind_ui_nodes() -> void:
	label_hp = get_node_or_null("Margin/HBox/StatsCol/StatsPanel/VBox/HPValue")
	label_mind = get_node_or_null("Margin/HBox/StatsCol/StatsPanel/VBox/MindValue")
	label_attack = get_node_or_null("Margin/HBox/StatsCol/StatsPanel/VBox/AttackValue")
	label_armor = get_node_or_null("Margin/HBox/StatsCol/StatsPanel/VBox/ArmorValue")

	slot_buttons = {
		"helmet": get_node_or_null("Margin/HBox/DollCol/DollGrid/HelmetSlot"),
		"breast_harness": get_node_or_null("Margin/HBox/DollCol/DollGrid/BreastSlot"),
		"gauntlet": get_node_or_null("Margin/HBox/DollCol/DollGrid/GauntletSlot"),
		"feet_harness": get_node_or_null("Margin/HBox/DollCol/DollGrid/FeetSlot"),
		"boots": get_node_or_null("Margin/HBox/DollCol/DollGrid/BootsSlot"),
		"main_hand": get_node_or_null("Margin/HBox/DollCol/DollGrid/MainHandSlot"),
		"off_hand": get_node_or_null("Margin/HBox/DollCol/DollGrid/OffHandSlot"),
		"belt": get_node_or_null("Margin/HBox/DollCol/DollGrid/BeltSlot")
	}

	for slot_name in slot_buttons.keys():
		var btn = slot_buttons[slot_name]
		if btn:
			btn.pressed.connect(_on_slot_clicked.bind(slot_name))

	belt_panel = get_node_or_null("Margin/HBox/DollCol/BeltSection")
	belt_locked_label = get_node_or_null("Margin/HBox/DollCol/BeltSection/LockedLabel")

	belt_slots_ui = [
		get_node_or_null("Margin/HBox/DollCol/BeltSection/HBox/BeltSlot1"),
		get_node_or_null("Margin/HBox/DollCol/BeltSection/HBox/BeltSlot2"),
		get_node_or_null("Margin/HBox/DollCol/BeltSection/HBox/BeltSlot3")
	]

	var rucksack_grid = get_node_or_null("Margin/HBox/RucksackCol/RucksackGrid")
	rucksack_cells.clear()
	if rucksack_grid:
		for child in rucksack_grid.get_children():
			rucksack_cells.append(child)

	var close_btn = get_node_or_null("Margin/HBox/RucksackCol/CloseButton")
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

	var drop_zone = get_node_or_null("Margin/HBox/RucksackCol/FloorDropZone")
	if drop_zone:
		drop_zone.gui_input.connect(_on_floor_drop_gui_input)

func refresh_ui() -> void:
	if not inventory or not stats:
		return

	# 1. Update stats
	_update_stats_display(stats.get_stats_dict())

	# 2. Update equipment slots
	for slot_name in slot_buttons.keys():
		var btn = slot_buttons[slot_name] as Button
		if not btn: continue
		var item: ItemData = inventory.equipped.get(slot_name, null)
		if item:
			btn.text = "%s\n%s" % [item.icon_symbol, item.name]
			btn.tooltip_text = "%s\n%s\n%s" % [item.name, item.get_stat_summary(), item.description]
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			btn.text = _get_default_slot_text(slot_name)
			btn.tooltip_text = "Empty %s Slot" % slot_name.capitalize()
			btn.modulate = Color(0.7, 0.7, 0.7, 0.8)

	# 3. Update Belt Section
	var has_belt = inventory.is_belt_equipped()
	if belt_locked_label:
		belt_locked_label.visible = not has_belt
	for b_ui in belt_slots_ui:
		if b_ui:
			b_ui.visible = has_belt

	if has_belt:
		_refresh_belt_slots()

	# 4. Update Rucksack
	_refresh_rucksack_slots()

func _update_stats_display(s: Dictionary) -> void:
	if label_hp:
		label_hp.text = "%d / %d ❤️" % [s.get("current_hp", 8), s.get("max_hp", 8)]
	if label_mind:
		label_mind.text = "%d / %d 🧠" % [s.get("mind_points", 3), s.get("mind_points", 3)]
	if label_attack:
		var dice_text = "🎲".repeat(maxi(1, s.get("attack_strength", 1)))
		label_attack.text = "%d Dice (%s)" % [s.get("attack_strength", 1), dice_text]
	if label_armor:
		var def_text = "🛡️".repeat(maxi(1, s.get("armor", 2)))
		label_armor.text = "%d Dice (%s)" % [s.get("armor", 2), def_text]

func _refresh_belt_slots() -> void:
	if belt_slots_ui.size() > 0 and belt_slots_ui[0]:
		var item0 = inventory.belt_pouch_0[0]
		var item1 = inventory.belt_pouch_0[1]
		if item0 != null and item0 == item1 and item0.is_large():
			belt_slots_ui[0].text = "Tall (2H)\n%s %s" % [item0.icon_symbol, item0.name]
		elif item0 != null or item1 != null:
			var t0 = item0.name if item0 else "Empty"
			var t1 = item1.name if item1 else "Empty"
			belt_slots_ui[0].text = "Slot 1\n• %s\n• %s" % [t0, t1]
		else:
			belt_slots_ui[0].text = "Belt 1 (Tall)\n[Empty]"

	if belt_slots_ui.size() > 1 and belt_slots_ui[1]:
		var item0 = inventory.belt_pouch_1[0]
		var item1 = inventory.belt_pouch_1[1]
		if item0 != null and item0 == item1 and item0.is_large():
			belt_slots_ui[1].text = "Tall (2H)\n%s %s" % [item0.icon_symbol, item0.name]
		elif item0 != null or item1 != null:
			var t0 = item0.name if item0 else "Empty"
			var t1 = item1.name if item1 else "Empty"
			belt_slots_ui[1].text = "Slot 2\n• %s\n• %s" % [t0, t1]
		else:
			belt_slots_ui[1].text = "Belt 2 (Tall)\n[Empty]"

	if belt_slots_ui.size() > 2 and belt_slots_ui[2]:
		var item = inventory.belt_pouch_2[0]
		if item:
			belt_slots_ui[2].text = "Single\n%s %s" % [item.icon_symbol, item.name]
		else:
			belt_slots_ui[2].text = "Belt 3 (1H)\n[Empty]"

func _refresh_rucksack_slots() -> void:
	for i in range(min(rucksack_cells.size(), inventory.rucksack.size())):
		var btn = rucksack_cells[i] as Button
		if not btn: continue
		var item: ItemData = inventory.rucksack[i]
		if item:
			btn.text = item.icon_symbol
			btn.tooltip_text = "%s\n%s" % [item.name, item.get_stat_summary()]
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Rucksack Slot"

func _get_default_slot_text(slot_name: String) -> String:
	match slot_name:
		"helmet": return "🪖\nHelmet"
		"breast_harness": return "🥋\nBreast"
		"gauntlet": return "🧤\nGauntlet"
		"feet_harness": return "🦿\nGreaves"
		"boots": return "👢\nBoots"
		"main_hand": return "⚔️\nMain Hand"
		"off_hand": return "🛡️\nOff Hand"
		"belt": return "🎗️\nBelt"
		_: return "Slot"

func _on_slot_clicked(slot_name: String) -> void:
	if not inventory: return
	var item: ItemData = inventory.equipped.get(slot_name)
	if not item: return

	# Unequip and attempt to place into rucksack, or drop to floor if full
	var unequipped = inventory.unequip(slot_name)
	if unequipped:
		if not inventory.add_to_first_rucksack_slot(unequipped):
			item_dropped_to_floor.emit(unequipped)

func _on_stats_changed(stats_dict: Dictionary) -> void:
	_update_stats_display(stats_dict)

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _on_floor_drop_gui_input(event: InputEvent) -> void:
	pass

# Drag and Drop support
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item") and data.item is ItemData

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data): return
	var item: ItemData = data.item
	handle_item_dropped(item)

func handle_item_dropped(item: ItemData, target_slot: String = "") -> void:
	if not inventory: return

	if target_slot != "":
		var old = inventory.equip(target_slot, item)
		if old:
			item_dropped_to_floor.emit(old)
			item_swapped.emit(old, item, target_slot)
		return

	# Fallback smart equip/stash
	for s in inventory.equipped.keys():
		if inventory.can_equip_in_slot(s, item):
			if inventory.equipped[s] == null:
				inventory.equip(s, item)
				return

	if inventory.can_fit_in_belt(item):
		inventory.add_to_belt(item)
		return

	if inventory.add_to_first_rucksack_slot(item):
		return

	item_dropped_to_floor.emit(item)
