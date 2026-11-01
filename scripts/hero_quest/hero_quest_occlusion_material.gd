class_name HeroQuestOcclusionMaterial
extends RefCounted

## Builds the ghost "see-through with outline" ShaderMaterial used for geometry
## that hides the hero. One material per mesh (the edge mask needs its local AABB).

const SHADER = preload("res://shaders/occlusion_fade.gdshader")
const RENDER_PRIORITY: int = 50

static func create_for(mesh_inst: MeshInstance3D, source: Material, target_alpha: float) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = SHADER
	# Must draw AFTER the fog-of-war shroud quad (it overwrites every transparent pixel drawn
	# before it, because hint_screen_texture is copied before the transparent pass).
	mat.render_priority = RENDER_PRIORITY
	mat.set_shader_parameter("target_alpha", target_alpha)
	mat.set_shader_parameter("fade", 0.0)

	if mesh_inst.mesh:
		var box = mesh_inst.mesh.get_aabb()
		mat.set_shader_parameter("aabb_min", box.position)
		mat.set_shader_parameter("aabb_max", box.end)

	if source is StandardMaterial3D:
		var std := source as StandardMaterial3D
		var c := std.albedo_color
		mat.set_shader_parameter("albedo_color", Color(c.r, c.g, c.b, 1.0))
		if std.albedo_texture:
			mat.set_shader_parameter("albedo_texture", std.albedo_texture)
		mat.set_shader_parameter("uv1_scale", std.uv1_scale)
		mat.set_shader_parameter("uv1_offset", std.uv1_offset)
		mat.set_shader_parameter("roughness", std.roughness)
		mat.set_shader_parameter("metallic", std.metallic)
	else:
		mat.set_shader_parameter("albedo_color", Color(0.2, 0.2, 0.25, 1.0))
	return mat
