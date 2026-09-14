class_name CastleMaterials
extends RefCounted

const CastleFloorTextureGenerator = preload("res://scripts/hero_quest/castle_floor_texture_generator.gd")

var walls_transparent: bool = false

var mat_floor_stone: StandardMaterial3D
var mat_floor_stone_alt: StandardMaterial3D
var mat_floor_chapel: StandardMaterial3D
var mat_floor_wood: StandardMaterial3D
var mat_floor_bridge: StandardMaterial3D
var mat_wall_stone: StandardMaterial3D
var mat_wall_trim: StandardMaterial3D
var mat_wood_dark: StandardMaterial3D
var mat_wood_light: StandardMaterial3D
var mat_iron: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_torch_glow: StandardMaterial3D
var mat_ember: StandardMaterial3D
var mat_water_chasm: StandardMaterial3D
var mat_hay: StandardMaterial3D
var mat_cloth_red: StandardMaterial3D
var mat_floor_garden_green: StandardMaterial3D
var mat_fountain_water: StandardMaterial3D
var mat_plant_leaf: StandardMaterial3D
var mat_flower_red: StandardMaterial3D
var mat_flower_yellow: StandardMaterial3D
var mat_flower_purple: StandardMaterial3D
var mat_fire_flame: StandardMaterial3D
var mat_canvas_art: StandardMaterial3D
var mat_frame_gold: StandardMaterial3D
var mat_window_glass: StandardMaterial3D
var mat_floor_graveyard_dirt: StandardMaterial3D
var mat_gravestone: StandardMaterial3D
var mat_bone: StandardMaterial3D

func _init() -> void:
	# Floor Slate / Cobble
	mat_floor_stone = StandardMaterial3D.new()
	mat_floor_stone.albedo_color = Color(0.20, 0.22, 0.26)
	mat_floor_stone.roughness = 0.85

	mat_floor_stone_alt = StandardMaterial3D.new()
	mat_floor_stone_alt.albedo_color = Color(0.17, 0.19, 0.23)
	mat_floor_stone_alt.roughness = 0.88

	# Chapel patterned tiles
	mat_floor_chapel = StandardMaterial3D.new()
	mat_floor_chapel.albedo_color = Color(0.26, 0.20, 0.28)
	mat_floor_chapel.roughness = 0.65

	# Stables light timber planks
	mat_floor_wood = StandardMaterial3D.new()
	mat_floor_wood.albedo_color = Color(0.35, 0.25, 0.16)
	mat_floor_wood.roughness = 0.8

	# Bridge weathered timber / stone
	mat_floor_bridge = StandardMaterial3D.new()
	mat_floor_bridge.albedo_color = Color(0.30, 0.22, 0.16)
	mat_floor_bridge.roughness = 0.85

	# Walls dark medieval castle masonry
	mat_wall_stone = StandardMaterial3D.new()
	mat_wall_stone.albedo_color = Color(0.14, 0.15, 0.18)
	mat_wall_stone.roughness = 0.9

	# Wall Trim / Pillars
	mat_wall_trim = StandardMaterial3D.new()
	mat_wall_trim.albedo_color = Color(0.24, 0.26, 0.30)
	mat_wall_trim.roughness = 0.75

	# Dark aged oak wood
	mat_wood_dark = StandardMaterial3D.new()
	mat_wood_dark.albedo_color = Color(0.25, 0.16, 0.10)
	mat_wood_dark.roughness = 0.7

	# Light wood (planks, stables)
	mat_wood_light = StandardMaterial3D.new()
	mat_wood_light.albedo_color = Color(0.42, 0.30, 0.18)
	mat_wood_light.roughness = 0.75

	# Blackened forged iron
	mat_iron = StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.18, 0.19, 0.21)
	mat_iron.metallic = 0.88
	mat_iron.roughness = 0.35

	# Relic Gold
	mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.95, 0.78, 0.20)
	mat_gold.metallic = 0.92
	mat_gold.roughness = 0.22

	# Torch flame glow
	mat_torch_glow = StandardMaterial3D.new()
	mat_torch_glow.albedo_color = Color(1.0, 0.6, 0.15)
	mat_torch_glow.emission_enabled = true
	mat_torch_glow.emission = Color(1.0, 0.55, 0.1)
	mat_torch_glow.emission_energy_multiplier = 4.0

	# Forge embers
	mat_ember = StandardMaterial3D.new()
	mat_ember.albedo_color = Color(1.0, 0.25, 0.05)
	mat_ember.emission_enabled = true
	mat_ember.emission = Color(1.0, 0.25, 0.02)
	mat_ember.emission_energy_multiplier = 3.5

	# Chasm bottom (bottomless abyss / dark waters)
	mat_water_chasm = StandardMaterial3D.new()
	mat_water_chasm.albedo_color = Color(0.02, 0.04, 0.08)
	mat_water_chasm.roughness = 0.2

	# Hay / straw
	mat_hay = StandardMaterial3D.new()
	mat_hay.albedo_color = Color(0.65, 0.55, 0.25)
	mat_hay.roughness = 0.95

	# Royal carpet cloth
	mat_cloth_red = StandardMaterial3D.new()
	mat_cloth_red.albedo_color = Color(0.55, 0.10, 0.12)
	mat_cloth_red.roughness = 0.8

	# Indoor Garden Green Floor
	mat_floor_garden_green = StandardMaterial3D.new()
	mat_floor_garden_green.albedo_color = Color(0.18, 0.28, 0.19)
	mat_floor_garden_green.roughness = 0.7

	# Fountain Water
	mat_fountain_water = StandardMaterial3D.new()
	mat_fountain_water.albedo_color = Color(0.12, 0.45, 0.65, 0.85)
	mat_fountain_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_fountain_water.roughness = 0.1
	mat_fountain_water.metallic = 0.15

	# Botanical Foliage & Flowers
	mat_plant_leaf = StandardMaterial3D.new()
	mat_plant_leaf.albedo_color = Color(0.14, 0.38, 0.12)
	mat_plant_leaf.roughness = 0.75

	mat_flower_red = StandardMaterial3D.new()
	mat_flower_red.albedo_color = Color(0.85, 0.15, 0.20)
	mat_flower_red.roughness = 0.6

	mat_flower_yellow = StandardMaterial3D.new()
	mat_flower_yellow.albedo_color = Color(0.92, 0.82, 0.15)
	mat_flower_yellow.roughness = 0.6

	mat_flower_purple = StandardMaterial3D.new()
	mat_flower_purple.albedo_color = Color(0.55, 0.20, 0.75)
	mat_flower_purple.roughness = 0.6

	# Animated Fireplace Flame
	mat_fire_flame = StandardMaterial3D.new()
	mat_fire_flame.albedo_color = Color(1.0, 0.5, 0.08)
	mat_fire_flame.emission_enabled = true
	mat_fire_flame.emission = Color(1.0, 0.45, 0.05)
	mat_fire_flame.emission_energy_multiplier = 4.5

	# Framed Canvas Painting & Gilt Frame
	mat_canvas_art = StandardMaterial3D.new()
	mat_canvas_art.albedo_color = Color(0.40, 0.32, 0.24)
	mat_canvas_art.roughness = 0.9

	mat_frame_gold = StandardMaterial3D.new()
	mat_frame_gold.albedo_color = Color(0.78, 0.62, 0.22)
	mat_frame_gold.metallic = 0.7
	mat_frame_gold.roughness = 0.35

	# Gothic Window Stained Glass
	mat_window_glass = StandardMaterial3D.new()
	mat_window_glass.albedo_color = Color(0.25, 0.45, 0.65, 0.75)
	mat_window_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_window_glass.emission_enabled = true
	mat_window_glass.emission = Color(0.35, 0.55, 0.75)
	mat_window_glass.emission_energy_multiplier = 1.8

	# Damp graveyard soil
	mat_floor_graveyard_dirt = StandardMaterial3D.new()
	mat_floor_graveyard_dirt.albedo_color = Color(0.12, 0.11, 0.10)
	mat_floor_graveyard_dirt.roughness = 0.95

	# Weathered cemetery gravestone slate/granite
	mat_gravestone = StandardMaterial3D.new()
	mat_gravestone.albedo_color = Color(0.28, 0.30, 0.32)
	mat_gravestone.roughness = 0.82

	# Bleached aged skeleton bone
	mat_bone = StandardMaterial3D.new()
	mat_bone.albedo_color = Color(0.86, 0.83, 0.74)
	mat_bone.roughness = 0.7

	_setup_brick_wall_texture()
	_setup_floor_textures()

func _setup_floor_textures() -> void:
	var gen = CastleFloorTextureGenerator.new()
	gen.apply_floor_textures(self)

func set_walls_transparent(transparent: bool, alpha: float = 0.28) -> void:
	if walls_transparent == transparent:
		return
	walls_transparent = transparent
	if transparent:
		mat_wall_stone.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_wall_stone.albedo_color.a = alpha
		mat_wall_stone.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat_wall_trim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_wall_trim.albedo_color.a = clampf(alpha * 1.25, 0.0, 1.0)
		mat_wall_trim.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	else:
		mat_wall_stone.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat_wall_stone.albedo_color.a = 1.0
		mat_wall_stone.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		mat_wall_trim.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat_wall_trim.albedo_color.a = 1.0
		mat_wall_trim.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY

func _setup_brick_wall_texture() -> void:
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var brick_h = 16
	var brick_w = 32
	var mortar_c = Color(0.10, 0.10, 0.12)
	var base_c = Color(0.18, 0.19, 0.22)
	for y in range(128):
		var row = y / brick_h
		var row_offset = (row % 2) * (brick_w / 2)
		var is_mortar_y = (y % brick_h) < 2
		for x in range(128):
			var shifted_x = (x + row_offset) % 128
			var is_mortar_x = (shifted_x % brick_w) < 2
			if is_mortar_y or is_mortar_x:
				img.set_pixel(x, y, mortar_c)
			else:
				var noise_val = (sin(x * 0.4) + cos(y * 0.5)) * 0.03
				var col = base_c + Color(noise_val, noise_val, noise_val)
				img.set_pixel(x, y, col)
	var tex = ImageTexture.create_from_image(img)
	mat_wall_stone.albedo_texture = tex
	mat_wall_stone.uv1_scale = Vector3(2.0, 2.0, 2.0)
