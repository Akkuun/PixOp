shader_type canvas_item;
render_mode blend_mix;

uniform float alphas[3];
uniform float betas[3];

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;

	vec3 col = texture(TEXTURE, UV).rgb;

	for (int i = 0; i < 3; i++) {
		col[i] = clamp( round(alphas[i] + (col[i]*255.0 * betas[i])), 0.0, 255.0)/255.0;
	}

	COLOR = vec4(col, 1.0);
}