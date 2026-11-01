shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Ghost-like see-through look for geometry that hides the hero:
// semi-transparent body + bright box-edge outline + fresnel rim so the object never looks "gone".

uniform vec4 albedo_color : source_color = vec4(0.5, 0.5, 0.55, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform float fade : hint_range(0.0, 1.0) = 1.0;           // 0 = original look, 1 = fully ghosted
uniform float target_alpha : hint_range(0.0, 1.0) = 0.2;
uniform vec4 edge_color : source_color = vec4(0.62, 0.78, 1.0, 1.0);
uniform float edge_width = 0.03;                            // metres in mesh-local space
uniform float edge_strength = 0.3;
uniform float rim_strength = 0.12;

uniform vec3 aabb_min = vec3(-0.5);
uniform vec3 aabb_max = vec3(0.5);

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	vec3 base = albedo_color.rgb * tex.rgb;

	// Edge mask: a fragment lies on a box edge when it hugs the AABB boundary on >= 2 axes.
	vec3 d_min = v_local - aabb_min;
	vec3 d_max = aabb_max - v_local;
	vec3 d = min(d_min, d_max);
	vec3 near_face = 1.0 - smoothstep(edge_width * 0.5, edge_width, d);
	vec3 span = aabb_max - aabb_min;
	// Ignore degenerate (flat) axes so thin slabs still outline correctly.
	near_face *= step(edge_width * 1.5, span);
	float edge = clamp(near_face.x * near_face.y + near_face.y * near_face.z + near_face.x * near_face.z, 0.0, 1.0);

	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	float outline = clamp(edge + fres * rim_strength, 0.0, 1.0);

	ALBEDO = mix(base, edge_color.rgb, outline * fade);
	EMISSION = edge_color.rgb * outline * edge_strength * fade;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	float ghost_alpha = mix(1.0, target_alpha, fade);
	ALPHA = clamp(mix(ghost_alpha, 1.0, outline * fade * 0.1), 0.0, 1.0);
}
