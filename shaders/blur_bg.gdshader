shader_type canvas_item;

uniform sampler2D t: hint_screen_texture, filter_linear_mipmap;
uniform float mip_level: hint_range(0.0, 10.0) = 4.0;
uniform float color_mul: hint_range(0.0, 2.0) = 0.6;
uniform float color_add: hint_range(0.0, 1.0) = 0.4;
uniform bool rounded_corner_top_left = true;
uniform bool rounded_corner_top_right = true;
uniform bool rounded_corner_bottom_left = true;
uniform bool rounded_corner_bottom_right = true;
uniform float corner_radius_ratio: hint_range(0.0, 0.5) = 0.08;


void fragment() {
	vec3 sampled = textureLod(t, SCREEN_UV, mip_level).rgb * color_mul + color_add;
	COLOR.rgb *= sampled;

	float aspect_ratio = 1.5; // float(TEXTURE_PIXEL_SIZE.y) / float(TEXTURE_PIXEL_SIZE.x);
	vec2 adj_UV = vec2(UV.x * aspect_ratio, UV.y);

	vec4 image = texture(TEXTURE, UV);
	float dist;

	// Top left corner
	if (rounded_corner_top_left && adj_UV.x < corner_radius_ratio && UV.y < corner_radius_ratio) {
		dist = length(adj_UV - vec2(corner_radius_ratio, corner_radius_ratio));
		if (dist > corner_radius_ratio) {
			COLOR.a = 0.0;
		}
	}
	// Top right corner
	if (rounded_corner_top_right && adj_UV.x > aspect_ratio - corner_radius_ratio && UV.y < corner_radius_ratio) {
		dist = length(adj_UV - vec2(aspect_ratio - corner_radius_ratio, corner_radius_ratio));
		if (dist > corner_radius_ratio) {
			COLOR.a = 0.0;
		}
	}
	// Bottom left corner
	if (rounded_corner_bottom_left && adj_UV.x < corner_radius_ratio && UV.y > 1.0 - corner_radius_ratio) {
		dist = length(adj_UV - vec2(corner_radius_ratio, 1.0 - corner_radius_ratio));
		if (dist > corner_radius_ratio) {
			COLOR.a = 0.0;
		}
	}
	// Bottom right corner
	if (rounded_corner_bottom_right && adj_UV.x > aspect_ratio - corner_radius_ratio && UV.y > 1.0 - corner_radius_ratio) {
		dist = length(adj_UV - vec2(aspect_ratio - corner_radius_ratio, 1.0 - corner_radius_ratio));
		if (dist > corner_radius_ratio) {
			COLOR.a = 0.0;
		}
	}
}
