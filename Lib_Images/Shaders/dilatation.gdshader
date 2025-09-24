shader_type canvas_item;
render_mode blend_mix;

uniform float kernel_size = 4.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
	
    vec2 ps = TEXTURE_PIXEL_SIZE;
    vec4 min_col = texture(TEXTURE, UV);
    // TODO FIX
    min_col = min(min_col, texture(TEXTURE, UV + vec2(0.0, -kernel_size) * ps));
    min_col = min(min_col, texture(TEXTURE, UV + vec2(0.0, kernel_size) * ps));
    min_col = min(min_col, texture(TEXTURE, UV + vec2(-kernel_size, 0.0) * ps));
    min_col = min(min_col, texture(TEXTURE, UV + vec2(kernel_size, 0.0) * ps));

    COLOR = min_col;
}
