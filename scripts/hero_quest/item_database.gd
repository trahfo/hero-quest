class_name ItemDatabase
extends RefCounted

const ItemData = preload("res://scripts/hero_quest/item_data.gd")

static func create_item(id: String) -> ItemData:
	var item = ItemData.new()
	item.id = id

	match id:
		# --- WEAPONS ---
		"rusted_shortsword":
			item.name = "Rusted Shortsword"
			item.slot_type = ItemData.SlotType.MAIN_HAND
			item.size = Vector2i(1, 2)
			item.attack_strength = 1
			item.icon_symbol = "🗡️"
			item.description = "A notched iron blade carried by novice squires. Grants +1 Attack Combat Die."
			item.rarity_color = Color(0.7, 0.7, 0.7)

		"mastercrafted_steel_blade":
			item.name = "Mastercrafted Steel Blade"
			item.slot_type = ItemData.SlotType.MAIN_HAND
			item.size = Vector2i(1, 2)
			item.attack_strength = 3
			item.icon_symbol = "⚔️"
			item.description = "A razor-sharp royal blade forged from folded steel. Grants +3 Attack Combat Dice."
			item.rarity_color = Color(1.0, 0.85, 0.3)

		"battle_axe":
			item.name = "Broad Battle Axe"
			item.slot_type = ItemData.SlotType.MAIN_HAND
			item.size = Vector2i(1, 2)
			item.attack_strength = 4
			item.icon_symbol = "🪓"
			item.description = "A fearsome double-bitted weapon that cleaves armor. Grants +4 Attack Combat Dice."
			item.rarity_color = Color(0.9, 0.4, 0.2)

		"shadow_dagger":
			item.name = "Dagger of Shadows"
			item.slot_type = ItemData.SlotType.MAIN_HAND
			item.size = Vector2i(1, 1) # Small weapon that can fit in belt!
			item.attack_strength = 1
			item.icon_symbol = "🗡️"
			item.description = "A light, balanced throwing or thrusting dagger. Fits into small belt pouches."
			item.rarity_color = Color(0.6, 0.7, 0.85)

		# --- SHIELD / OFF HAND ---
		"knight_shield":
			item.name = "Knight Commander's Shield"
			item.slot_type = ItemData.SlotType.OFF_HAND
			item.size = Vector2i(1, 2)
			item.armor = 2
			item.icon_symbol = "🛡️"
			item.description = "A heavy heraldic heater shield bearing the kingdom's crest. Grants +2 Defend Dice."
			item.rarity_color = Color(0.4, 0.7, 1.0)

		# --- ARMOR SET ---
		"iron_helmet":
			item.name = "Iron Helmet"
			item.slot_type = ItemData.SlotType.HELMET
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.icon_symbol = "🪖"
			item.description = "A sturdy riveted iron bascinet. Protects the head and grants +1 Defend Die."
			item.rarity_color = Color(0.75, 0.75, 0.8)

		"breastplate":
			item.name = "Knight's Breast Harness"
			item.slot_type = ItemData.SlotType.BREAST_HARNESS
			item.size = Vector2i(1, 2)
			item.armor = 2
			item.icon_symbol = "🥋"
			item.description = "A solid steel cuirass that turns aside enemy blows. Grants +2 Defend Dice."
			item.rarity_color = Color(0.8, 0.85, 0.95)

		"gauntlet":
			item.name = "Steel Gauntlets"
			item.slot_type = ItemData.SlotType.GAUNTLET
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.icon_symbol = "🧤"
			item.description = "Articulated steel finger and wrist plates. Grants +1 Defend Die."
			item.rarity_color = Color(0.75, 0.75, 0.8)

		"greaves":
			item.name = "Steel Feet Harness"
			item.slot_type = ItemData.SlotType.FEET_HARNESS
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.icon_symbol = "🦿"
			item.description = "Fluted steel greaves safeguarding knees and shins. Grants +1 Defend Die."
			item.rarity_color = Color(0.75, 0.75, 0.8)

		"swift_boots":
			item.name = "Rider's Swift Boots"
			item.slot_type = ItemData.SlotType.BOOTS
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.speed_bonus = 0.05
			item.icon_symbol = "👢"
			item.description = "Supple leather cavalry boots enchanted with swiftness. Grants +1 Defend Die and Agility."
			item.rarity_color = Color(0.3, 0.85, 0.5)

		# --- BELTS ---
		"leather_belt":
			item.name = "Adventurer's Leather Belt"
			item.slot_type = ItemData.SlotType.BELT
			item.size = Vector2i(1, 1)
			item.icon_symbol = "🎗️"
			item.description = "Sturdy oiled leather belt. Enables 5 quick-access belt pouches (2 tall, 1 small)."
			item.rarity_color = Color(0.8, 0.6, 0.3)

		"war_belt":
			item.name = "Knight's War Belt"
			item.slot_type = ItemData.SlotType.BELT
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.icon_symbol = "🎗️"
			item.description = "Reinforced studded war belt. Grants +1 Defend Die and unlocks 5 belt pouches."
			item.rarity_color = Color(1.0, 0.8, 0.2)

		# --- RELICS & CONSUMABLES ---
		"healing_potion":
			item.name = "Elixir of Life"
			item.slot_type = ItemData.SlotType.ANY
			item.size = Vector2i(1, 1)
			item.heal_amount = 4
			item.icon_symbol = "🧪"
			item.description = "A glowing ruby potion brewed with restorative herbs. Restores 4 Body Points (HP)."
			item.rarity_color = Color(1.0, 0.3, 0.3)

		"gold_relic":
			item.name = "Gold Relic of the King"
			item.slot_type = ItemData.SlotType.ANY
			item.size = Vector2i(1, 1)
			item.armor = 1
			item.mind_points = 2
			item.icon_symbol = "👑"
			item.description = "An ancient gilded royal relic. Inspires the soul with +2 Mind Points and +1 Defend Die."
			item.rarity_color = Color(1.0, 0.85, 0.1)

		"holy_chalice":
			item.name = "Holy Chalice of Light"
			item.slot_type = ItemData.SlotType.ANY
			item.size = Vector2i(1, 1)
			item.max_hp = 3
			item.heal_amount = 8
			item.mind_points = 1
			item.icon_symbol = "🏆"
			item.description = "Blessed sacrament chalice. Permanently grants +3 Max HP, +1 Mind Point, and heals."
			item.rarity_color = Color(1.0, 0.9, 0.4)

		"arcade_relic_pacman":
			item.name = "Arcane Arcade Relic: Pac-Man 3D"
			item.slot_type = ItemData.SlotType.ANY
			item.size = Vector2i(1, 1)
			item.mind_points = 2
			item.icon_symbol = "🟡"
			item.description = "A humming arcane cube inscribed with neon maze runes. Grants +2 Mind Points and opens an easter egg portal to the Pac-Man labyrinth."
			item.rarity_color = Color(1.0, 0.85, 0.2)

		_:
			item.name = id.replace("_", " ").capitalize()
			item.description = "An intriguing treasure found within the castle."

	return item

static func get_item_by_name(name_str: String) -> ItemData:
	var lower = name_str.to_lower()
	if "steel blade" in lower or "blade" in lower or "sword" in lower:
		return create_item("mastercrafted_steel_blade")
	elif "boots" in lower or "rider" in lower:
		return create_item("swift_boots")
	elif "shield" in lower:
		return create_item("knight_shield")
	elif "chalice" in lower or "holy" in lower:
		return create_item("holy_chalice")
	elif "gold relic" in lower or "king" in lower or "relic" in lower:
		return create_item("gold_relic")
	elif "helmet" in lower or "helm" in lower:
		return create_item("iron_helmet")
	elif "breast" in lower or "plate" in lower or "cuirass" in lower:
		return create_item("breastplate")
	elif "gauntlet" in lower:
		return create_item("gauntlet")
	elif "feet" in lower or "greaves" in lower:
		return create_item("greaves")
	elif "belt" in lower:
		return create_item("leather_belt")
	elif "potion" in lower or "elixir" in lower:
		return create_item("healing_potion")
	else:
		return create_item("gold_relic")
