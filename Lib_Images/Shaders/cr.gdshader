shader_type canvas_item;
render_mode blend_mix;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

	float cr = 0.5 * col.r - 0.41869 * col.g - 0.08131 * col.b + 0.5;

    COLOR = vec4(cr, cr, cr, col.a);
}
