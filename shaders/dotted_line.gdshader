shader_type canvas_item;
render_mode unshaded;          // Line keeps its flat colour – no lighting
uniform vec4 line_color : source_color = vec4(1.0);
uniform float frequency = 10.0; // Controls the number of dots


void fragment() {
    /* In a Line2D the engine automatically maps UV.x to the distance
       from the line’s start **in pixels**.  That lets us build a
       repeating pattern without extra maths.                         */

    float cycle = mod(UV.x, frequency * 2.0);   // one “on” + one “off”
    if (cycle < frequency) {                    // first half of cycle
        COLOR = line_color;
    } else {                                    // second half = gap
        discard;                                // pure transparency
    }
}
