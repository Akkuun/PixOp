shader_type canvas_item;
uniform float time;
uniform vec4 base_color : source_color = vec4(0.1, 0.1, 0.15, 1.0); 

void fragment() { 
	vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
	float wave = sin(uv.x * 10.0 + time * 0.5) * 0.02; 
	float light = 0.5 + wave; COLOR = base_color * light; 
	}
	