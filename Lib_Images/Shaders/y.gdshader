shader_type canvas_item;
render_mode blend_mix;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

	float y = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;

    COLOR = vec4(y, y, y, col.a);
}
