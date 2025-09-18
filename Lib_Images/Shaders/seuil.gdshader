shader_type canvas_item;
render_mode blend_mix;

uniform int n_colors = 2;
uniform vec4 colors[8];

void sort_array(inout float arr[8], int size) {
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (arr[j] > arr[j+1]) {
                float tmp = arr[j];
                arr[j] = arr[j+1];
                arr[j+1] = tmp;
            }
        }
    }
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float r_values[8];
    float g_values[8];
    float b_values[8];
    for (int i = 0; i < n_colors; i++) {
        r_values[i] = colors[i].r;
        g_values[i] = colors[i].g;
        b_values[i] = colors[i].b;
    }
    for (int i = n_colors; i < 8; i++) {
        r_values[i] = 2.0;
        g_values[i] = 2.0;
        b_values[i] = 2.0;
    }
    sort_array(r_values, n_colors);
    sort_array(g_values, n_colors);
    sort_array(b_values, n_colors);

    float r = col.r;
    float g = col.g;
    float b = col.b;

    int i = 0;
    for (; i < n_colors; i++) {
        if (r < r_values[i]) {
            break;
        }
    }
    if (i == 0) {
        r = 0.0;
    } else if (i == n_colors) {
        r = 1.0;
    } else {
        r = r_values[i];
    }

    i = 0;
    for (; i < n_colors; i++) {
        if (g < g_values[i]) {
            break;
        }
    }
    if (i == 0) {
        g = 0.0;
    } else if (i == n_colors) {
        g = 1.0;
    } else {
        g = g_values[i];
    }

    i = 0;
    for (; i < n_colors; i++) {
        if (b < b_values[i]) {
            break;
        }
    }
    if (i == 0) {
        b = 0.0;
    } else if (i == n_colors) {
        b = 1.0;
    } else {
        b = b_values[i];
    }
    COLOR = vec4(r, g, b, 1.0);
}
