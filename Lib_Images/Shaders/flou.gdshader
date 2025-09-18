shader_type canvas_item;
render_mode blend_mix;

uniform float kernel_size = 4.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE;

	col += texture(TEXTURE, UV + vec2(0.0, -kernel_size) * ps);
	col += texture(TEXTURE, UV + vec2(0.0, kernel_size) * ps);
	col += texture(TEXTURE, UV + vec2(-kernel_size, 0.0) * ps);
	col += texture(TEXTURE, UV + vec2(kernel_size, 0.0) * ps);
	col /= 5.0;

	COLOR = col;
}