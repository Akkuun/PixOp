shader_type canvas_item;
render_mode blend_mix;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

	if (UV.x < 0.5 && UV.y < 0.5) {
		// Y
		vec2 uv_scaled = UV * 2.0;
		vec4 col_scaled = texture(TEXTURE, uv_scaled);
		float y = 0.299 * col_scaled.r + 0.587 * col_scaled.g + 0.114 * col_scaled.b;
		COLOR = vec4(y, y, y, col_scaled.a);
	} else if (UV.x >= 0.5 && UV.y < 0.5) {
		// Cb
		vec2 uv_scaled = vec2((UV.x - 0.5) * 2.0, UV.y * 2.0);
		vec4 col_scaled = texture(TEXTURE, uv_scaled);
		float cb = -0.168736 * col_scaled.r - 0.331264 * col_scaled.g + 0.5 * col_scaled.b + 0.5;
		COLOR = vec4(cb, cb, cb, col_scaled.a);
	} else if (UV.x < 0.5 && UV.y >= 0.5) {
		// Cr
		vec2 uv_scaled = vec2(UV.x * 2.0, (UV.y - 0.5) * 2.0);
		vec4 col_scaled = texture(TEXTURE, uv_scaled);
		float cr = 0.5 * col_scaled.r - 0.460525 * col_scaled.g - 0.081475 * col_scaled.b + 0.5;
		COLOR = vec4(cr, cr, cr, col_scaled.a);
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, 0.0);
	}
}
