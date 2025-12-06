shader_type canvas_item;

uniform sampler2D t: hint_screen_texture, filter_linear_mipmap;
uniform float mip_level: hint_range(0.0, 10.0) = 4.0;
uniform float color_mul: hint_range(0.0, 2.0) = 0.6;
uniform float color_add: hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec3 sampled = textureLod(t, SCREEN_UV, mip_level).rgb * color_mul + color_add;
    COLOR.rgb *= sampled;
}
