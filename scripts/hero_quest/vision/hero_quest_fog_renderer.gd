class_name HeroQuestFogRenderer
extends Node

## Manages the 2D Fog of War texture and the full-screen spatial post-process shroud.
## High-performance differential stamping and bilinear hardware interpolation.

const FOW_SHADER = preload("res://shaders/fog_of_war.gdshader")

var post_process_mesh: MeshInstance3D
var shader_mat: ShaderMaterial
var fow_image: Image
var fow_texture: ImageTexture

var texture_width: int = 128
var texture_height: int = 128

var world_min: Vector2 = Vector2(-40.0, -40.0)
var world_max: Vector2 = Vector2(40.0, 40.0)
var world_size: Vector2 = Vector2(80.0, 80.0)

var is_fog_enabled: bool = true

# Differential tracking to avoid full image clearing loops
var prev_visible_cells: Array[Vector2i] = []
var stamped_explored: Dictionary = {}

func setup(camera: Camera3D) -> void:
	_init_shader_quad(camera)
	_init_texture()

func _init_shader_quad(camera: Camera3D) -> void:
	if post_process_mesh and is_instance_valid(post_process_mesh):
		post_process_mesh.queue_free()

	shader_mat = ShaderMaterial.new()
	shader_mat.shader = FOW_SHADER
	shader_mat.set_shader_parameter("explored_dimness", 0.22)
	shader_mat.set_shader_parameter("unexplored_color", Color(0.012, 0.015, 0.025, 1.0))
	shader_mat.set_shader_parameter("explored_tint", Color(0.42, 0.48, 0.62, 1.0))
	shader_mat.set_shader_parameter("fog_enabled", is_fog_enabled)

	var quad = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)

	post_process_mesh = MeshInstance3D.new()
	post_process_mesh.name = "HeroQuestFogShroud"
	post_process_mesh.mesh = quad
	post_process_mesh.material_override = shader_mat
	post_process_mesh.extra_cull_margin = 16384.0
	post_process_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if camera:
		camera.add_child(post_process_mesh)
	else:
		add_child(post_process_mesh)

func _init_texture() -> void:
	fow_image = Image.create(texture_width, texture_height, false, Image.FORMAT_RGBA8)
	fow_image.fill(Color(0, 0, 0, 1)) # Pitch black
	fow_texture = ImageTexture.create_from_image(fow_image)

	stamped_explored.clear()
	prev_visible_cells.clear()

	if shader_mat:
		shader_mat.set_shader_parameter("fow_texture", fow_texture)
		shader_mat.set_shader_parameter("grid_origin", world_min)
		shader_mat.set_shader_parameter("grid_size", world_size)

func update_bounds_from_grid(grid_cells: Array, tile_size: float = 2.0) -> void:
	if grid_cells.is_empty():
		return

	var min_c = Vector2i(999999, 999999)
	var max_c = Vector2i(-999999, -999999)

	for c in grid_cells:
		if c is Vector2i:
			min_c.x = mini(min_c.x, c.x)
			min_c.y = mini(min_c.y, c.y)
			max_c.x = maxi(max_c.x, c.x)
			max_c.y = maxi(max_c.y, c.y)

	var margin_tiles = 4
	world_min = Vector2((min_c.x - margin_tiles) * tile_size, (min_c.y - margin_tiles) * tile_size)
	world_max = Vector2((max_c.x + margin_tiles) * tile_size, (max_c.y + margin_tiles) * tile_size)
	world_size = world_max - world_min

	if shader_mat:
		shader_mat.set_shader_parameter("grid_origin", world_min)
		shader_mat.set_shader_parameter("grid_size", world_size)

## Differential update: Only touches the few dozen cells that actually changed
func update_fog_map(visible_cells: Dictionary, explored_cells: Dictionary, tile_size: float = 2.0) -> void:
	if not fow_image:
		return

	# 1. Clear previous visible cells (R channel -> 0.0)
	for cell in prev_visible_cells:
		if not visible_cells.has(cell):
			_stamp_cell_channel_r(cell, 0.0, tile_size)
	prev_visible_cells.clear()

	# 2. Stamp new explored cells (G channel -> 1.0) only once per cell
	for cell in explored_cells.keys():
		if not stamped_explored.has(cell):
			stamped_explored[cell] = true
			_stamp_cell_channel_g(cell, 1.0, tile_size)

	# 3. Stamp currently visible cells (R channel -> intensity)
	for cell in visible_cells.keys():
		var intensity = float(visible_cells[cell])
		_stamp_cell_channel_r(cell, intensity, tile_size)
		prev_visible_cells.append(cell)

	fow_texture.update(fow_image)

func _stamp_cell_channel_r(cell: Vector2i, intensity: float, tile_size: float) -> void:
	var world_x = cell.x * tile_size
	var world_z = cell.y * tile_size

	var uv_x = (world_x - world_min.x) / world_size.x
	var uv_z = (world_z - world_min.y) / world_size.y

	var center_px = int(uv_x * float(texture_width))
	var center_pz = int(uv_z * float(texture_height))

	var pixel_radius = maxi(1, int((tile_size * 1.0 / world_size.x) * float(texture_width)))

	for dy in range(-pixel_radius, pixel_radius + 1):
		for dx in range(-pixel_radius, pixel_radius + 1):
			var px = center_px + dx
			var py = center_pz + dy
			if px >= 0 and px < texture_width and py >= 0 and py < texture_height:
				var current = fow_image.get_pixel(px, py)
				var new_r = intensity if intensity == 0.0 else maxf(current.r, intensity)
				fow_image.set_pixel(px, py, Color(new_r, current.g, 0.0, 1.0))

func _stamp_cell_channel_g(cell: Vector2i, intensity: float, tile_size: float) -> void:
	var world_x = cell.x * tile_size
	var world_z = cell.y * tile_size

	var uv_x = (world_x - world_min.x) / world_size.x
	var uv_z = (world_z - world_min.y) / world_size.y

	var center_px = int(uv_x * float(texture_width))
	var center_pz = int(uv_z * float(texture_height))

	var pixel_radius = maxi(1, int((tile_size * 1.0 / world_size.x) * float(texture_width)))

	for dy in range(-pixel_radius, pixel_radius + 1):
		for dx in range(-pixel_radius, pixel_radius + 1):
			var px = center_px + dx
			var py = center_pz + dy
			if px >= 0 and px < texture_width and py >= 0 and py < texture_height:
				var current = fow_image.get_pixel(px, py)
				fow_image.set_pixel(px, py, Color(current.r, maxf(current.g, intensity), 0.0, 1.0))

func set_enabled(active: bool) -> void:
	is_fog_enabled = active
	if shader_mat:
		shader_mat.set_shader_parameter("fog_enabled", is_fog_enabled)

func reveal_all() -> void:
	if not fow_image:
		return
	fow_image.fill(Color(1.0, 1.0, 0.0, 1.0))
	fow_texture.update(fow_image)
