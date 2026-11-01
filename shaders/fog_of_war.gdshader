shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D fow_texture : repeat_disable, filter_linear;

uniform vec2 grid_origin = vec2(-50.0, -50.0);
uniform vec2 grid_size = vec2(100.0, 100.0);
uniform float explored_dimness : hint_range(0.0, 1.0) = 0.22;
uniform vec4 unexplored_color : source_color = vec4(0.012, 0.015, 0.025, 1.0);
uniform vec4 explored_tint : source_color = vec4(0.42, 0.48, 0.62, 1.0);
uniform bool fog_enabled = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 screen_col = texture(screen_texture, SCREEN_UV).rgb;

	if (!fog_enabled) {
		ALBEDO = screen_col;
	} else {
		float depth = texture(depth_texture, SCREEN_UV).x;
		if (depth >= 0.99999) {
			ALBEDO = screen_col * 0.15;
		} else {
			vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
			vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
			view.xyz /= view.w;
			vec4 world = INV_VIEW_MATRIX * vec4(view.xyz, 1.0);

			// Map world XZ to FoW texture UV
			vec2 fow_uv = (world.xz - grid_origin) / grid_size;

			if (fow_uv.x < 0.0 || fow_uv.x > 1.0 || fow_uv.y < 0.0 || fow_uv.y > 1.0) {
				ALBEDO = unexplored_color.rgb;
			} else {
				vec4 fow_val = texture(fow_texture, fow_uv);
				float visible_factor = clamp(fow_val.r, 0.0, 1.0);
				float explored_factor = clamp(fow_val.g, 0.0, 1.0);

				// Feathered smooth transition from pitch black unexplored to explored memory
				float explored_blend = smoothstep(0.01, 0.35, explored_factor);
				vec3 memory_col = screen_col * explored_tint.rgb * explored_dimness;
				vec3 base_col = mix(unexplored_color.rgb, memory_col, explored_blend);

				// Ultra-soft, multi-tile continuous gradient transition into full sight
				float visible_blend = smoothstep(0.0, 1.0, visible_factor);
				vec3 final_col = mix(base_col, screen_col, visible_blend);
				ALBEDO = final_col;
			}
		}
	}
}
