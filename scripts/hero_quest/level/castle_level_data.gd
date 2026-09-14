class_name CastleLevelData
extends RefCounted

const CastleMaterials = preload("res://scripts/hero_quest/castle_materials.gd")

static func vec3_to_arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

static func arr_to_vec3(a: Array) -> Vector3:
	if a.size() < 3:
		return Vector3.ZERO
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

static func vec2i_to_arr(v: Vector2i) -> Array:
	return [v.x, v.y]

static func arr_to_vec2i(a: Array) -> Vector2i:
	if a.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(a[0]), int(a[1]))

static func color_to_arr(c: Color) -> Array:
	return [snappedf(c.r, 0.01), snappedf(c.g, 0.01), snappedf(c.b, 0.01), snappedf(c.a, 0.01)]

static func arr_to_color(a: Array) -> Color:
	if a.size() < 3:
		return Color.WHITE
	var alpha = float(a[3]) if a.size() >= 4 else 1.0
	return Color(float(a[0]), float(a[1]), float(a[2]), alpha)

static func mat_to_name(mat: Material, materials: CastleMaterials) -> String:
	if mat == null:
		return "stone"
	if mat == materials.mat_floor_stone: return "stone"
	if mat == materials.mat_floor_stone_alt: return "stone_alt"
	if mat == materials.mat_floor_chapel: return "chapel"
	if mat == materials.mat_floor_wood: return "wood"
	if mat == materials.mat_floor_bridge: return "bridge"
	if mat == materials.mat_floor_courtyard: return "courtyard"
	if mat == materials.mat_floor_garden_green: return "garden_green"
	if mat == materials.mat_floor_graveyard_dirt: return "graveyard_dirt"
	if mat == materials.mat_wall_stone: return "wall_stone"
	if mat == materials.mat_wall_trim: return "wall_trim"
	if mat == materials.mat_wood_dark: return "wood_dark"
	if mat == materials.mat_wood_light: return "wood_light"
	if mat == materials.mat_iron: return "iron"
	if mat == materials.mat_gold: return "gold"
	if mat == materials.mat_torch_glow: return "torch_glow"
	if mat == materials.mat_ember: return "ember"
	if mat == materials.mat_water_chasm: return "water_chasm"
	if mat == materials.mat_hay: return "hay"
	if mat == materials.mat_cloth_red: return "cloth_red"
	if mat == materials.mat_gravestone: return "gravestone"
	return "stone"

static func name_to_mat(m_name: String, materials: CastleMaterials) -> StandardMaterial3D:
	match m_name:
		"stone": return materials.mat_floor_stone
		"stone_alt": return materials.mat_floor_stone_alt
		"chapel": return materials.mat_floor_chapel
		"wood": return materials.mat_floor_wood
		"bridge": return materials.mat_floor_bridge
		"courtyard": return materials.mat_floor_stone
		"garden_green": return materials.mat_floor_garden_green
		"graveyard_dirt": return materials.mat_floor_graveyard_dirt
		"wall_stone": return materials.mat_wall_stone
		"wall_trim": return materials.mat_wall_trim
		"wood_dark": return materials.mat_wood_dark
		"wood_light": return materials.mat_wood_light
		"iron": return materials.mat_iron
		"gold": return materials.mat_gold
		"torch_glow": return materials.mat_torch_glow
		"ember": return materials.mat_ember
		"water_chasm": return materials.mat_water_chasm
		"hay": return materials.mat_hay
		"cloth_red": return materials.mat_cloth_red
		"gravestone": return materials.mat_gravestone
		_: return materials.mat_floor_stone
