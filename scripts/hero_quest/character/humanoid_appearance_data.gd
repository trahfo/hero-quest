class_name HumanoidAppearanceData
extends Resource

@export var archetype_id: String = "hero"
@export var archetype_name: String = "Adventurer Hero"

# Head parameters
@export var head_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var head_shape: String = "oval" # "oval", "square", "round", "chiseled"
@export var skin_color: Color = Color(0.92, 0.78, 0.65)
@export var eye_color: Color = Color(0.2, 0.5, 0.8)
@export var hair_style: String = "short_parted" # "short_parted", "helmet", "ponytail", "long_wizard", "bald"
@export var hair_length: float = 1.0
@export var hair_color: Color = Color(0.28, 0.18, 0.1)
@export var facial_hair: String = "none" # "none", "goatee", "full_beard"
@export var beard_color: Color = Color(0.28, 0.18, 0.1)

# Body parameters
@export var torso_scale: Vector3 = Vector3(1.0, 1.0, 1.0) # Width, Height, Depth
@export var shirt_color: Color = Color(0.22, 0.38, 0.65) # Royal blue tunic
@export var armor_trim_color: Color = Color(0.85, 0.72, 0.25) # Gold/brass trim
@export var shoulder_pad_size: float = 0.4 # 0.0 to 1.5

# Limb parameters
@export var arm_thickness: float = 1.0
@export var arm_length: float = 1.0
@export var glove_color: Color = Color(0.32, 0.22, 0.14)
@export var leg_thickness: float = 1.0
@export var leg_length: float = 1.0
@export var pants_color: Color = Color(0.22, 0.24, 0.28)
@export var boots_color: Color = Color(0.18, 0.13, 0.09)

# Equipment
@export var main_hand_weapon: String = "sword" # "sword", "mace", "staff", "none"
@export var off_hand_gear: String = "none" # "shield", "bow", "spellbook", "none"
@export var back_gear: String = "none" # "none", "quiver"

# -------------------------------------------------------------
# ARCHETYPE PRESETS
# -------------------------------------------------------------

static func create_hero() -> HumanoidAppearanceData:
	var data = HumanoidAppearanceData.new()
	data.archetype_id = "hero"
	data.archetype_name = "Adventurer Hero"
	data.head_scale = Vector3(1.0, 1.0, 1.0)
	data.head_shape = "oval"
	data.skin_color = Color(0.92, 0.78, 0.65)
	data.eye_color = Color(0.2, 0.5, 0.8)
	data.hair_style = "short_parted"
	data.hair_length = 1.0
	data.hair_color = Color(0.3, 0.19, 0.1)
	data.facial_hair = "none"

	data.torso_scale = Vector3(1.0, 1.0, 1.0)
	data.shirt_color = Color(0.2, 0.38, 0.68) # Heroic Royal Blue
	data.armor_trim_color = Color(0.9, 0.75, 0.25) # Gold Crest & Buckles
	data.shoulder_pad_size = 0.45

	data.arm_thickness = 1.0
	data.arm_length = 1.0
	data.glove_color = Color(0.35, 0.24, 0.15)
	data.leg_thickness = 1.0
	data.leg_length = 1.0
	data.pants_color = Color(0.24, 0.26, 0.3)
	data.boots_color = Color(0.2, 0.14, 0.09)

	data.main_hand_weapon = "sword"
	data.off_hand_gear = "none"
	data.back_gear = "none"
	return data

static func create_guard() -> HumanoidAppearanceData:
	var data = HumanoidAppearanceData.new()
	data.archetype_id = "guard"
	data.archetype_name = "Heavy Iron Knight"
	data.head_scale = Vector3(1.08, 1.04, 1.08)
	data.head_shape = "chiseled"
	data.skin_color = Color(0.86, 0.72, 0.6)
	data.eye_color = Color(0.3, 0.4, 0.35)
	data.hair_style = "helmet"
	data.hair_length = 0.8
	data.hair_color = Color(0.2, 0.2, 0.2)
	data.facial_hair = "goatee"
	data.beard_color = Color(0.2, 0.2, 0.2)

	# Stout, broad, heavy armor
	data.torso_scale = Vector3(1.24, 1.04, 1.18)
	data.shirt_color = Color(0.62, 0.65, 0.7) # Polished Iron Breastplate
	data.armor_trim_color = Color(0.85, 0.68, 0.2) # Brass Edging
	data.shoulder_pad_size = 1.0

	data.arm_thickness = 1.25
	data.arm_length = 1.02
	data.glove_color = Color(0.55, 0.58, 0.62) # Steel Gauntlets
	data.leg_thickness = 1.25
	data.leg_length = 1.0
	data.pants_color = Color(0.32, 0.33, 0.36) # Chainmail Legs
	data.boots_color = Color(0.48, 0.5, 0.54) # Steel Sabatons

	data.main_hand_weapon = "mace"
	data.off_hand_gear = "none"
	data.back_gear = "none"
	return data

static func create_ranger() -> HumanoidAppearanceData:
	var data = HumanoidAppearanceData.new()
	data.archetype_id = "ranger"
	data.archetype_name = "Elven Scout / Ranger"
	data.head_scale = Vector3(0.94, 1.0, 0.94)
	data.head_shape = "oval"
	data.skin_color = Color(0.88, 0.74, 0.6)
	data.eye_color = Color(0.2, 0.65, 0.35)
	data.hair_style = "ponytail"
	data.hair_length = 1.4
	data.hair_color = Color(0.7, 0.32, 0.12) # Auburn / Ginger
	data.facial_hair = "none"

	# Nimble, slender hunter
	data.torso_scale = Vector3(0.92, 1.0, 0.9)
	data.shirt_color = Color(0.18, 0.42, 0.24) # Forest Camo Green
	data.armor_trim_color = Color(0.48, 0.35, 0.18) # Oiled Leather Straps
	data.shoulder_pad_size = 0.25

	data.arm_thickness = 0.88
	data.arm_length = 1.0
	data.glove_color = Color(0.38, 0.26, 0.16) # Leather Archery Bracers
	data.leg_thickness = 0.9
	data.leg_length = 1.04
	data.pants_color = Color(0.36, 0.28, 0.2) # Deerskin Trousers
	data.boots_color = Color(0.25, 0.18, 0.12)

	data.main_hand_weapon = "none"
	data.off_hand_gear = "bow"
	data.back_gear = "quiver"
	return data

static func create_wizard() -> HumanoidAppearanceData:
	var data = HumanoidAppearanceData.new()
	data.archetype_id = "wizard"
	data.archetype_name = "Grand Arcanist / Wizard"
	data.head_scale = Vector3(0.96, 1.05, 0.96)
	data.head_shape = "chiseled"
	data.skin_color = Color(0.9, 0.82, 0.76)
	data.eye_color = Color(0.65, 0.35, 0.95) # Mystic Violet
	data.hair_style = "long_wizard"
	data.hair_length = 1.8
	data.hair_color = Color(0.92, 0.94, 0.96) # Silver White
	data.facial_hair = "full_beard"
	data.beard_color = Color(0.92, 0.94, 0.96)

	# Tall, scholarly robes
	data.torso_scale = Vector3(0.95, 1.08, 0.95)
	data.shirt_color = Color(0.42, 0.14, 0.48) # Royal Mystic Purple Robe
	data.armor_trim_color = Color(0.95, 0.8, 0.3) # Golden Astrological Runes
	data.shoulder_pad_size = 0.5 # Robe mantle

	data.arm_thickness = 0.86
	data.arm_length = 1.02
	data.glove_color = Color(0.35, 0.12, 0.4)
	data.leg_thickness = 0.88
	data.leg_length = 1.0
	data.pants_color = Color(0.22, 0.1, 0.26)
	data.boots_color = Color(0.18, 0.12, 0.16)

	data.main_hand_weapon = "staff"
	data.off_hand_gear = "spellbook"
	data.back_gear = "none"
	return data
