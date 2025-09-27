shader_type canvas_item;
uniform vec4 color : source_color = vec4(1.0);
uniform float diameter = 1.0; // Circle Diameter

void fragment() {
  vec2 pos = UV - vec2(0.5);
  float outer_radius = diameter / 2.0;
  float inside_circle = step(length(pos), outer_radius);

  COLOR = vec4(color.rgb, inside_circle * color.a);
}
