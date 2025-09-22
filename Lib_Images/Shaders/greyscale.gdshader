shader_type canvas_item;
render_mode blend_mix;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(grey), col.a);
}