shader_type canvas_item;
render_mode blend_mix;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    COLOR = vec4(1.0 - col.r, 1.0 - col.g, 1.0 - col.b, col.a);
}
