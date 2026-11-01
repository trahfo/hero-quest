class_name HeroQuestFogRenderer
extends Node

## Manages the 2D Fog of War texture and the full-screen spatial post-process shroud.
## High-performance differential stamping and bilinear hardware interpolation.

const FOW_SHADER = preload("res://shaders/fog_of_war.gdshader")

var post_process_mesh: MeshInstance3D
var shader_mat: ShaderMaterial
var fow_image: Image
var fow_texture: ImageTexture

# 1 texel == 1 grid cell. Bilinear sampling in the shader feathers cell borders.
var texture_width: int = 64
var texture_height: int = 64
var tile_size: float = 2.0
var min_cell: Vector2i = Vector2i(-32, -32)

var world_min: Vector2 = Vector2(-65.0, -65.0)
var world_max: Vector2 = Vector2(65.0, 65.0)
var world_size: Vector2 = Vector2(130.0, 130.0)

var is_fog_enabled: bool = true

# Differential tracking to avoid full image clearing loops
var prev_visible_cells: Array[Vector2i] = []
var stamped_explored: Dictionary = {}
var _dirty: bool = false

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
	_dirty = false

	if shader_mat:
		shader_mat.set_shader_parameter("fow_texture", fow_texture)
		shader_mat.set_shader_parameter("grid_origin", world_min)
		shader_mat.set_shader_parameter("grid_size", world_size)

## Sizes the texture to the grid bounds (+ margin). Rebuilds only when the bounds change;
## stamped state is re-applied from the explored/visible sets on the next update_fog_map().
func update_bounds_from_grid(grid_cells: Array, p_tile_size: float = 2.0) -> void:
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
	var new_min = Vector2i(min_c.x - margin_tiles, min_c.y - margin_tiles)
	var new_w = max_c.x - min_c.x + 1 + margin_tiles * 2
	var new_h = max_c.y - min_c.y + 1 + margin_tiles * 2
	if new_min == min_cell and new_w == texture_width and new_h == texture_height and is_equal_approx(p_tile_size, tile_size):
		return

	tile_size = p_tile_size
	min_cell = new_min
	texture_width = new_w
	texture_height = new_h
	# Texel i covers world [(min_cell + i - 0.5) * tile, (min_cell + i + 0.5) * tile]
	world_min = (Vector2(min_cell) - Vector2(0.5, 0.5)) * tile_size
	world_size = Vector2(texture_width, texture_height) * tile_size
	world_max = world_min + world_size
	_init_texture()

## World XZ -> texel of the grid cell containing it (used by tests and tools).
func cell_to_pixel(cell: Vector2i) -> Vector2i:
	return cell - min_cell

func _in_bounds(px: Vector2i) -> bool:
	return px.x >= 0 and px.x < texture_width and px.y >= 0 and px.y < texture_height

## Differential update: only touches cells that changed; uploads once, only when dirty.
func update_fog_map(visible_cells: Dictionary, explored_cells: Dictionary, _tile_size: float = 2.0) -> void:
	if not fow_image:
		return

	# 1. Clear previous visible cells (R channel -> 0.0)
	for cell in prev_visible_cells:
		if not visible_cells.has(cell):
			_set_channel(cell, 0, 0.0)
	prev_visible_cells.clear()

	# 2. Stamp new explored cells (G channel -> 1.0) only once per cell
	for cell in explored_cells.keys():
		if not stamped_explored.has(cell):
			stamped_explored[cell] = true
			_set_channel(cell, 1, 1.0)

	# 3. Stamp currently visible cells (R channel -> intensity)
	for cell in visible_cells.keys():
		_set_channel(cell, 0, float(visible_cells[cell]))
		prev_visible_cells.append(cell)

	if _dirty:
		fow_texture.update(fow_image)
		_dirty = false

func _set_channel(cell: Vector2i, channel: int, value: float) -> void:
	var px = cell_to_pixel(cell)
	if not _in_bounds(px):
		return
	var cur = fow_image.get_pixelv(px)
	if channel == 0:
		if is_equal_approx(cur.r, value):
			return
		cur.r = value
	else:
		if is_equal_approx(cur.g, value):
			return
		cur.g = value
	cur.b = 0.0
	cur.a = 1.0
	fow_image.set_pixelv(px, cur)
	_dirty = true

func set_enabled(active: bool) -> void:
	is_fog_enabled = active
	if shader_mat:
		shader_mat.set_shader_parameter("fog_enabled", is_fog_enabled)

func reveal_all() -> void:
	if not fow_image:
		return
	fow_image.fill(Color(1.0, 1.0, 0.0, 1.0))
	fow_texture.update(fow_image)
	_dirty = false
