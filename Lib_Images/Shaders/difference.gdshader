shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D other_image;

void fragment() {
    vec4 col1 = texture(TEXTURE, UV);
    vec4 col2 = texture(other_image, UV);
    
    if (distance(col1.rgb, col2.rgb) < 0.001) {
        COLOR = col1;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}