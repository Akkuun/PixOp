shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D cb;
uniform sampler2D cr;

void fragment() {
    vec4 y_col = texture(TEXTURE, UV);
	vec4 cb_col = texture(cb, UV);
	vec4 cr_col = texture(cr, UV);
    
	vec4 color;
	
	color.r = y_col.r + 1.402 * (cr_col.r - 0.5);
	color.g = y_col.r - 0.344136 * (cb_col.r - 0.5) - 0.714136 * (cr_col.r - 0.5);
	color.b = y_col.r + 1.772 * (cb_col.r - 0.5);
	color.a = y_col.a;

	COLOR = color;
}