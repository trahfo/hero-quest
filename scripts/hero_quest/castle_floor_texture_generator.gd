class_name CastleFloorTextureGenerator
extends RefCounted

## Procedural PBR floor texture and normal map generator.
## Eliminates physical tile gaps while providing subtle, tactile tile boundary
## delineation through outer mortar seams, interior surface grain, and beveled edge normal maps.

const TEX_SIZE: int = 128

func apply_floor_textures(materials: CastleMaterials) -> void:
	var stone_tex = _create_stone_texture()
	var stone_norm = _create_stone_normal_map()

	var chapel_tex = _create_chapel_texture()
	var wood_tex = _create_wood_texture()
	var wood_norm = _create_wood_normal_map()

	# Stone Floors (dungeon slate & alternate checker)
	_configure_mat(materials.mat_floor_stone, stone_tex, stone_norm, 1.0)
	_configure_mat(materials.mat_floor_stone_alt, stone_tex, stone_norm, 1.0)

	# Chapel Floor (ornate gothic diamond inlay)
	_configure_mat(materials.mat_floor_chapel, chapel_tex, stone_norm, 1.2)

	# Stables Timber & Bridge Wood
	_configure_mat(materials.mat_floor_wood, wood_tex, wood_norm, 0.9)
	_configure_mat(materials.mat_floor_bridge, wood_tex, wood_norm, 0.9)

	# Courtyard / Garden Green & Graveyard Soil
	_configure_mat(materials.mat_floor_garden_green, stone_tex, stone_norm, 0.8)
	_configure_mat(materials.mat_floor_graveyard_dirt, stone_tex, stone_norm, 0.7)

func _configure_mat(mat: StandardMaterial3D, albedo_tex: ImageTexture, norm_tex: ImageTexture, norm_scale: float) -> void:
	if not mat:
		return
	mat.albedo_texture = albedo_tex
	mat.normal_enabled = true
	mat.normal_texture = norm_tex
	mat.normal_scale = norm_scale
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)

## Generates a subtle greyscale flagstone tile texture with perimeter mortar seams.
func _create_stone_texture() -> ImageTexture:
	var img = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var max_idx = TEX_SIZE - 1

	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var edge_dist = min(min(x, max_idx - x), min(y, max_idx - y))
			var val: float

			if edge_dist <= 2:
				# Outer recessed mortar seam (45% darker)
				val = 0.52 + float(edge_dist) * 0.04
			elif edge_dist <= 6:
				# Subtle beveled shoulder transition
				var t = float(edge_dist - 2) / 4.0
				val = lerpf(0.60, 0.96, t)
			else:
				# Interior flagstone body with subtle grain
				var grain = (sin(x * 0.38) + cos(y * 0.44)) * 0.025 + (sin((x + y) * 0.75)) * 0.015
				val = clampf(0.96 + grain, 0.90, 1.02)

			img.set_pixel(x, y, Color(val, val, val, 1.0))

	return ImageTexture.create_from_image(img)

## Generates a tangent-space normal map with rounded bevels along all 4 perimeter edges.
func _create_stone_normal_map(bevel_px: int = 6, bevel_strength: float = 0.55) -> ImageTexture:
	var img = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var max_idx = TEX_SIZE - 1

	for y in range(TEX_SIZE):
		var d_top = y
		var d_bottom = max_idx - y

		for x in range(TEX_SIZE):
			var d_left = x
			var d_right = max_idx - x

			var nx: float = 0.0
			var ny: float = 0.0

			if d_left < bevel_px:
				nx -= (1.0 - float(d_left) / float(bevel_px)) * bevel_strength
			elif d_right < bevel_px:
				nx += (1.0 - float(d_right) / float(bevel_px)) * bevel_strength

			if d_top < bevel_px:
				ny -= (1.0 - float(d_top) / float(bevel_px)) * bevel_strength
			elif d_bottom < bevel_px:
				ny += (1.0 - float(d_bottom) / float(bevel_px)) * bevel_strength

			var n = Vector3(nx, ny, 1.0).normalized()
			var r = n.x * 0.5 + 0.5
			var g = n.y * 0.5 + 0.5
			var b = n.z * 0.5 + 0.5

			img.set_pixel(x, y, Color(r, g, b, 1.0))

	return ImageTexture.create_from_image(img)

## Generates an ornate gothic patterned tile for chapel floors.
func _create_chapel_texture() -> ImageTexture:
	var img = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var max_idx = TEX_SIZE - 1
	var center = float(TEX_SIZE) * 0.5

	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var edge_dist = min(min(x, max_idx - x), min(y, max_idx - y))
			var val: float

			if edge_dist <= 2:
				val = 0.50 # Outer border seam
			elif edge_dist >= 8 and edge_dist <= 10:
				val = 1.15 # Inset ornamental frame highlight
			else:
				var m_dist = absf(float(x) - center) + absf(float(y) - center)
				if m_dist < 34.0:
					# Inner decorative diamond field
					var d_rim = absf(m_dist - 34.0)
					if d_rim <= 2.0:
						val = 0.65 # Diamond border groove
					else:
						val = 1.06 # Diamond center stone
				else:
					var noise = (sin(x * 0.3) + cos(y * 0.3)) * 0.02
					val = 0.95 + noise

			img.set_pixel(x, y, Color(val, val, val, 1.0))

	return ImageTexture.create_from_image(img)

## Generates longitudinal timber planks with border framing and horizontal plank grooves.
func _create_wood_texture() -> ImageTexture:
	var img = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var max_idx = TEX_SIZE - 1

	for y in range(TEX_SIZE):
		var plank_idx = y / 32
		var y_in_plank = y % 32
		var plank_seam = y_in_plank <= 1 or y_in_plank >= 31

		for x in range(TEX_SIZE):
			var edge_dist = min(min(x, max_idx - x), min(y, max_idx - y))
			var val: float

			if edge_dist <= 2:
				val = 0.45 # Perimeter tile seam
			elif plank_seam:
				val = 0.55 # Horizontal plank groove
			else:
				# Wood plank grain along X
				var grain = sin(float(x) * 0.22 + sin(float(y) * 0.12) * 3.5) * 0.035
				var row_tint = (plank_idx % 2) * 0.03 - 0.015
				val = clampf(0.96 + grain + row_tint, 0.88, 1.05)

			img.set_pixel(x, y, Color(val, val, val, 1.0))

	return ImageTexture.create_from_image(img)

## Generates normal map for timber planks with border bevels and horizontal plank grooves.
func _create_wood_normal_map(bevel_px: int = 5, bevel_strength: float = 0.50) -> ImageTexture:
	var img = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var max_idx = TEX_SIZE - 1

	for y in range(TEX_SIZE):
		var d_top = y
		var d_bottom = max_idx - y
		var y_in_plank = y % 32

		for x in range(TEX_SIZE):
			var d_left = x
			var d_right = max_idx - x

			var nx: float = 0.0
			var ny: float = 0.0

			# Outer edge bevels
			if d_left < bevel_px:
				nx -= (1.0 - float(d_left) / float(bevel_px)) * bevel_strength
			elif d_right < bevel_px:
				nx += (1.0 - float(d_right) / float(bevel_px)) * bevel_strength

			if d_top < bevel_px:
				ny -= (1.0 - float(d_top) / float(bevel_px)) * bevel_strength
			elif d_bottom < bevel_px:
				ny += (1.0 - float(d_bottom) / float(bevel_px)) * bevel_strength

			# Plank grooves normal tilt along Y
			if y_in_plank < 3:
				ny -= (1.0 - float(y_in_plank) / 3.0) * 0.35
			elif y_in_plank > 28:
				ny += (float(y_in_plank - 28) / 3.0) * 0.35

			var n = Vector3(nx, ny, 1.0).normalized()
			var r = n.x * 0.5 + 0.5
			var g = n.y * 0.5 + 0.5
			var b = n.z * 0.5 + 0.5

			img.set_pixel(x, y, Color(r, g, b, 1.0))

	return ImageTexture.create_from_image(img)
