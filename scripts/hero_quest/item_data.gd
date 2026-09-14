class_name ItemData
extends Resource

enum SlotType {
	MAIN_HAND,
	OFF_HAND,
	HELMET,
	BREAST_HARNESS,
	GAUNTLET,
	FEET_HARNESS,
	BOOTS,
	BELT,
	ANY # Potions, relics, scrolls, general items
}

@export var id: String = ""
@export var name: String = "Unknown Item"
@export var slot_type: SlotType = SlotType.ANY
@export var size: Vector2i = Vector2i(1, 1) # (1, 1) = small, (1, 2) = tall/large
@export var attack_strength: int = 0
@export var armor: int = 0
@export var max_hp: int = 0
@export var mind_points: int = 0
@export var speed_bonus: float = 0.0
@export var heal_amount: int = 0
@export var icon_symbol: String = "📦"
@export var description: String = ""
@export var rarity_color: Color = Color(0.9, 0.75, 0.3, 1.0)

func is_large() -> bool:
	return size.y > 1 or size.x > 1

func get_slot_name() -> String:
	match slot_type:
		SlotType.MAIN_HAND: return "Main Hand"
		SlotType.OFF_HAND: return "Off Hand"
		SlotType.HELMET: return "Helmet"
		SlotType.BREAST_HARNESS: return "Breast Harness"
		SlotType.GAUNTLET: return "Gauntlet"
		SlotType.FEET_HARNESS: return "Feet Harness"
		SlotType.BOOTS: return "Boots"
		SlotType.BELT: return "Belt"
		_: return "Inventory / Consumable"

func get_stat_summary() -> String:
	var parts: Array[String] = []
	if attack_strength > 0:
		parts.append("+%d Attack Dice ⚔️" % attack_strength)
	if armor > 0:
		parts.append("+%d Defend Dice 🛡️" % armor)
	if max_hp > 0:
		parts.append("+%d Max HP ❤️" % max_hp)
	if heal_amount > 0:
		parts.append("Restores %d HP 🧪" % heal_amount)
	if mind_points > 0:
		parts.append("+%d Mind Points 🧠" % mind_points)
	if speed_bonus > 0.0:
		parts.append("+Swiftness 🥾")
	if parts.is_empty():
		return "Special Artifact"
	return ", ".join(parts)
