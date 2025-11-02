shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D other_image;

void fragment() {
    vec3 col1 = texture(TEXTURE, UV).rgb;
    vec3 col2 = texture(other_image, UV).rgb;
    
    COLOR = vec4(abs(col1 - col2), 1.0);
}