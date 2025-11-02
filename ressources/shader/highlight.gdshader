shader_type canvas_item;

uniform sampler2D target_tex : source_color;
uniform float progress = 0.0;

void fragment() {
    vec4 current = texture(TEXTURE, UV);
    vec4 target = texture(target_tex, UV);
    float t = clamp(progress, 0.0, 1.0);
    COLOR = mix(current, target, t);
}
