shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D other_image;
uniform float kernel_size = 4.0;

void fragment() {
    vec4 col1 = texture(TEXTURE, UV);
    vec4 col2 = texture(other_image, UV);
    
    if (col2.r == 0.0) {
        COLOR = col1;
    } else {
        vec2 ps = TEXTURE_PIXEL_SIZE;
        vec4 sum = vec4(0.0);
        float count = 0.0;

	    float radius = floor(kernel_size / 2.0);
	
        for (float y = -radius; y <= radius; y += 1.0) {
            for (float x = -radius; x <= radius; x += 1.0) {
                vec2 offset = vec2(x, y) * ps;
                vec2 sample_uv = UV + offset;
                
                if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && 
                    sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
                    sum += texture(TEXTURE, sample_uv);
                    count += 1.0;
                }
            }
        }
        
        if (count > 0.0) {
            COLOR = sum / count;
        } else {
            COLOR = texture(TEXTURE, UV);
        }
    }
}