class_name LevelEditorGrid
extends Node3D

const TILE_SIZE: float = 2.0

var grid_mesh_instance: MeshInstance3D
var cursor_box: MeshInstance3D
var cursor_mat: StandardMaterial3D

func _init() -> void:
	name = "LevelEditorGrid"
	_create_grid_mesh()
	_create_cursor_box()

func _create_grid_mesh() -> void:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(240.0, 240.0)

	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec4 line_color : source_color = vec4(0.85, 0.9, 1.0, 0.35);
uniform float tile_size = 2.0;
uniform float line_thickness = 0.04;
uniform float dot_spacing = 0.25;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz;
	vec2 f = abs(fract(coord / tile_size) - 0.5) * tile_size;

	bool on_line_x = f.y < line_thickness;
	bool on_line_z = f.x < line_thickness;

	if (!on_line_x && !on_line_z) {
		discard;
	}

	float dot_val_x = on_line_x ? step(0.5, fract(coord.x / dot_spacing)) : 0.0;
	float dot_val_y = on_line_z ? step(0.5, fract(coord.y / dot_spacing)) : 0.0;

	if (dot_val_x < 0.5 && dot_val_y < 0.5) {
		discard;
	}

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a;
}
"""
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	shader_mat.render_priority = 1

	grid_mesh_instance = MeshInstance3D.new()
	grid_mesh_instance.mesh = plane_mesh
	grid_mesh_instance.material_override = shader_mat
	grid_mesh_instance.position = Vector3(0.0, 0.02, 0.0)
	add_child(grid_mesh_instance)

func _create_cursor_box() -> void:
	cursor_box = MeshInstance3D.new()
	cursor_mat = StandardMaterial3D.new()
	cursor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cursor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.35)
	cursor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cursor_mat.render_priority = 2

	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(TILE_SIZE - 0.08, 0.05, TILE_SIZE - 0.08)
	b_mesh.material = cursor_mat
	cursor_box.mesh = b_mesh
	cursor_box.position = Vector3(0.0, 0.035, 0.0)
	cursor_box.visible = false
	add_child(cursor_box)

func _ensure_cursor_box() -> void:
	if not is_instance_valid(cursor_box) or not cursor_box.is_inside_tree():
		_create_cursor_box()

func show_single_cell(cell: Vector2i, color: Color = Color(0.2, 0.8, 1.0, 0.35)) -> void:
	_ensure_cursor_box()
	cursor_box.visible = true
	cursor_mat.albedo_color = color
	var b_mesh = cursor_box.mesh as BoxMesh
	if b_mesh:
		b_mesh.size = Vector3(TILE_SIZE - 0.08, 0.05, TILE_SIZE - 0.08)
	cursor_box.position = Vector3(cell.x * TILE_SIZE, 0.035, cell.y * TILE_SIZE)

func show_selection_span(cells: Array[Vector2i], color: Color = Color(0.2, 0.9, 0.4, 0.4)) -> void:
	_ensure_cursor_box()
	if cells.is_empty():
		cursor_box.visible = false
		return

	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_z = cells[0].y
	var max_z = cells[0].y
	for c in cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y)
		max_z = maxi(max_z, c.y)

	var count_x = max_x - min_x + 1
	var count_z = max_z - min_z + 1
	var center_x = (min_x + max_x) * 0.5 * TILE_SIZE
	var center_z = (min_z + max_z) * 0.5 * TILE_SIZE

	cursor_box.visible = true
	cursor_mat.albedo_color = color
	var b_mesh = cursor_box.mesh as BoxMesh
	if b_mesh:
		b_mesh.size = Vector3(count_x * TILE_SIZE - 0.08, 0.05, count_z * TILE_SIZE - 0.08)
	cursor_box.position = Vector3(center_x, 0.035, center_z)

func hide_cursor() -> void:
	_ensure_cursor_box()
	cursor_box.visible = false
