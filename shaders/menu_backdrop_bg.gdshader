shader_type canvas_item;

uniform sampler2D t: hint_screen_texture, filter_linear_mipmap;
uniform float mip_level: hint_range(0.0, 10.0) = 4.0;
uniform float color_mul: hint_range(0.0, 2.0) = 0.6;
uniform float color_add: hint_range(0.0, 1.0) = 0.4;
uniform bool rounded_corner_top_left = true;
uniform bool rounded_corner_top_right = true;
uniform bool rounded_corner_bottom_left = true;
uniform bool rounded_corner_bottom_right = true;
uniform float corner_radius: hint_range(0.0, 0.5) = 0.08;


void fragment() {
	vec2 delta;
	float dist;
	vec2 size;
	vec2 scale;
	vec2 scaled_corner;
	vec3 sampled;

	// Frosted glass effect
	sampled = textureLod(t, SCREEN_UV, mip_level).rgb * color_mul + color_add;
	COLOR.rgb *= sampled;

	// Prepare for the rounded corners
	size = vec2(1.0 / SCREEN_PIXEL_SIZE.x, 1.0 / SCREEN_PIXEL_SIZE.y);
	scale = vec2(
		1.0,
		mix(size.x/size.y, 1.0, 0.5)
	);
	scaled_corner = scale * corner_radius;
	// scaled_corner = scale * corner_radius;

	// Top left corner
	if (rounded_corner_top_left && UV.x < scaled_corner.x && UV.y < scaled_corner.y) {
		delta = vec2(scaled_corner.x - UV.x, scaled_corner.y - UV.y);
		dist = length(delta / scaled_corner);
		if (dist > 1.0) {
			COLOR.a = 0.0;
		}
	}
	// Top right corner
	if (rounded_corner_top_right && UV.x > 1.0 - scaled_corner.x && UV.y < scaled_corner.y) {
		delta = vec2(UV.x - (1.0 - scaled_corner.x), scaled_corner.y - UV.y);
		dist = length(delta / scaled_corner);
		if (dist > 1.0) {
			COLOR.a = 0.0;
		}
	}
	// Bottom left corner
	if (rounded_corner_bottom_left && UV.x < scaled_corner.x && UV.y > 1.0 - scaled_corner.y) {
		delta = vec2(scaled_corner.x - UV.x, UV.y - (1.0 - scaled_corner.y));
		dist = length(delta / scaled_corner);
		if (dist > 1.0) {
			COLOR.a = 0.0;
		}
	}
	// Bottom right corner
	if (rounded_corner_bottom_right && UV.x > 1.0 - scaled_corner.x && UV.y > 1.0 - scaled_corner.y) {
		delta = vec2(UV.x - (1.0 - scaled_corner.x), UV.y - (1.0 - scaled_corner.y));
		dist = length(delta / scaled_corner);
		if (dist > 1.0) {
			COLOR.a = 0.0;
		}
	}
}
