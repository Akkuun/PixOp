shader_type canvas_item;
render_mode blend_mix;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

	float cb = -0.168736 * col.r - 0.331264 * col.g + 0.5 * col.b + 0.5;

    COLOR = vec4(cb, cb, cb, col.a);
}
