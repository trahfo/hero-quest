class_name HeroInventory
extends RefCounted

const ItemData = preload("res://scripts/hero_quest/item_data.gd")
const HeroStats = preload("res://scripts/hero_quest/hero_stats.gd")

signal inventory_changed
signal item_swapped_to_floor(old_item: ItemData, slot_name: String)

var stats: HeroStats = null

# Equipment slots: main_hand, off_hand, helmet, breast_harness, gauntlet, feet_harness, boots, belt
var equipped: Dictionary = {
	"main_hand": null,
	"off_hand": null,
	"helmet": null,
	"breast_harness": null,
	"gauntlet": null,
	"feet_harness": null,
	"boots": null,
	"belt": null
}

# Belt Pouches: 3 containers totaling 5 fields
# pouch 0: tall (2 fields: 1 large or 2 small)
# pouch 1: tall (2 fields: 1 large or 2 small)
# pouch 2: single (1 field: 1 small)
var belt_pouch_0: Array = [null, null]
var belt_pouch_1: Array = [null, null]
var belt_pouch_2: Array = [null]

# Rucksack: 4x4 grid (16 cells)
var rucksack: Array = [] # 16 cells (null or ItemData)

func _init(hero_stats: HeroStats = null) -> void:
	stats = hero_stats
	rucksack.resize(16)
	rucksack.fill(null)

func is_belt_equipped() -> bool:
	return equipped["belt"] != null

func get_equipped_list() -> Array:
	var list: Array = []
	for slot in equipped.keys():
		if equipped[slot] != null:
			list.append(equipped[slot])
	return list

func can_equip_in_slot(slot_name: String, item: ItemData) -> bool:
	if not equipped.has(slot_name) or item == null:
		return false
	match slot_name:
		"main_hand": return item.slot_type == ItemData.SlotType.MAIN_HAND or item.slot_type == ItemData.SlotType.ANY
		"off_hand": return item.slot_type == ItemData.SlotType.OFF_HAND or item.slot_type == ItemData.SlotType.MAIN_HAND
		"helmet": return item.slot_type == ItemData.SlotType.HELMET
		"breast_harness": return item.slot_type == ItemData.SlotType.BREAST_HARNESS
		"gauntlet": return item.slot_type == ItemData.SlotType.GAUNTLET
		"feet_harness": return item.slot_type == ItemData.SlotType.FEET_HARNESS
		"boots": return item.slot_type == ItemData.SlotType.BOOTS
		"belt": return item.slot_type == ItemData.SlotType.BELT
	return false

func equip(slot_name: String, item: ItemData) -> ItemData:
	if not can_equip_in_slot(slot_name, item):
		return null

	var old_item: ItemData = equipped[slot_name]
	equipped[slot_name] = item

	if stats:
		stats.recalculate(get_equipped_list())

	inventory_changed.emit()
	return old_item # Return previous item if swapped

func unequip(slot_name: String) -> ItemData:
	if not equipped.has(slot_name) or equipped[slot_name] == null:
		return null

	var removed: ItemData = equipped[slot_name]
	equipped[slot_name] = null

	if stats:
		stats.recalculate(get_equipped_list())

	inventory_changed.emit()
	return removed

# --- BELT POUCHES (5 Fields: 2 tall, 1 small) ---

func can_fit_in_belt(item: ItemData) -> bool:
	if not is_belt_equipped() or item == null:
		return false

	if item.is_large():
		# Large (1x2) can only fit in pouch 0 or pouch 1 if both fields are empty
		if belt_pouch_0[0] == null and belt_pouch_0[1] == null:
			return true
		if belt_pouch_1[0] == null and belt_pouch_1[1] == null:
			return true
		return false
	else:
		# Small (1x1) can fit anywhere there is a null
		if belt_pouch_0[0] == null or belt_pouch_0[1] == null: return true
		if belt_pouch_1[0] == null or belt_pouch_1[1] == null: return true
		if belt_pouch_2[0] == null: return true
		return false

func add_to_belt(item: ItemData) -> bool:
	if not can_fit_in_belt(item):
		return false

	if item.is_large():
		if belt_pouch_0[0] == null and belt_pouch_0[1] == null:
			belt_pouch_0[0] = item
			belt_pouch_0[1] = item
			inventory_changed.emit()
			return true
		elif belt_pouch_1[0] == null and belt_pouch_1[1] == null:
			belt_pouch_1[0] = item
			belt_pouch_1[1] = item
			inventory_changed.emit()
			return true
	else:
		if belt_pouch_0[0] == null:
			belt_pouch_0[0] = item
			inventory_changed.emit()
			return true
		elif belt_pouch_0[1] == null:
			belt_pouch_0[1] = item
			inventory_changed.emit()
			return true
		elif belt_pouch_1[0] == null:
			belt_pouch_1[0] = item
			inventory_changed.emit()
			return true
		elif belt_pouch_1[1] == null:
			belt_pouch_1[1] = item
			inventory_changed.emit()
			return true
		elif belt_pouch_2[0] == null:
			belt_pouch_2[0] = item
			inventory_changed.emit()
			return true
	return false

func remove_from_belt(pouch_idx: int, sub_idx: int = 0) -> ItemData:
	var item: ItemData = null
	if pouch_idx == 0:
		item = belt_pouch_0[sub_idx]
		if item and item.is_large():
			belt_pouch_0[0] = null
			belt_pouch_0[1] = null
		else:
			belt_pouch_0[sub_idx] = null
	elif pouch_idx == 1:
		item = belt_pouch_1[sub_idx]
		if item and item.is_large():
			belt_pouch_1[0] = null
			belt_pouch_1[1] = null
		else:
			belt_pouch_1[sub_idx] = null
	elif pouch_idx == 2:
		item = belt_pouch_2[0]
		belt_pouch_2[0] = null

	if item:
		inventory_changed.emit()
	return item

# --- RUCKSACK (4x4 = 16 Grid) ---

func can_place_in_rucksack(item: ItemData, x: int, y: int) -> bool:
	if x < 0 or x >= 4 or y < 0 or y >= 4:
		return false
	var idx = y * 4 + x
	if rucksack[idx] != null:
		return false
	if item.is_large():
		if y + 1 >= 4:
			return false
		var below_idx = (y + 1) * 4 + x
		if rucksack[below_idx] != null:
			return false
	return true

func place_in_rucksack(item: ItemData, x: int, y: int) -> bool:
	if not can_place_in_rucksack(item, x, y):
		return false
	var idx = y * 4 + x
	rucksack[idx] = item
	if item.is_large():
		rucksack[(y + 1) * 4 + x] = item
	inventory_changed.emit()
	return true

func add_to_first_rucksack_slot(item: ItemData) -> bool:
	for y in range(4):
		for x in range(4):
			if can_place_in_rucksack(item, x, y):
				return place_in_rucksack(item, x, y)
	return false

func remove_from_rucksack(x: int, y: int) -> ItemData:
	if x < 0 or x >= 4 or y < 0 or y >= 4:
		return null
	var idx = y * 4 + x
	var item: ItemData = rucksack[idx]
	if item == null:
		return null

	for i in range(16):
		if rucksack[i] == item:
			rucksack[i] = null

	inventory_changed.emit()
	return item

# --- ITEM LOOKUP & CONSUMPTION (Keys & Quest Items) ---

func _matches_item(item: ItemData, identifier: String) -> bool:
	if not item: return false
	var id_lower = identifier.strip_edges().to_lower()
	if id_lower.is_empty() or id_lower == "key":
		return "key" in item.id.to_lower() or "key" in item.name.to_lower()
	return item.id.to_lower() == id_lower or item.name.to_lower() == id_lower or id_lower in item.name.to_lower()

func has_item(identifier: String) -> bool:
	return get_item(identifier) != null

func get_item(identifier: String) -> ItemData:
	for pouch in [belt_pouch_0, belt_pouch_1, belt_pouch_2]:
		for it in pouch:
			if it is ItemData and _matches_item(it, identifier):
				return it
	for it in rucksack:
		if it is ItemData and _matches_item(it, identifier):
			return it
	return null

func consume_item(identifier: String) -> bool:
	# Check belt pouches first
	for pouch_idx in range(3):
		var pouch = belt_pouch_0 if pouch_idx == 0 else (belt_pouch_1 if pouch_idx == 1 else belt_pouch_2)
		for sub_idx in range(pouch.size()):
			var it = pouch[sub_idx]
			if it is ItemData and _matches_item(it, identifier):
				remove_from_belt(pouch_idx, sub_idx)
				return true
	# Check rucksack
	for y in range(4):
		for x in range(4):
			var it = rucksack[y * 4 + x]
			if it is ItemData and _matches_item(it, identifier):
				remove_from_rucksack(x, y)
				return true
	return false

