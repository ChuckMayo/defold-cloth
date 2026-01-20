#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;

out vec4 frag_color;

float draw_curve(float y_pos, float curve_value, float thickness) {
    float dist = abs(y_pos - curve_value);
    return smoothstep(thickness, thickness * 0.3, dist);
}

void main()
{
    vec3 bg = vec3(0.08, 0.10, 0.12);

    // Grid
    float grid_x = smoothstep(0.02, 0.0, abs(fract(var_uv.x * 4.0) - 0.5) - 0.48);
    float grid_y = smoothstep(0.02, 0.0, abs(fract(var_uv.y * 4.0) - 0.5) - 0.48);
    bg += vec3(0.05) * max(grid_x, grid_y);

    // Center line
    float center_line = smoothstep(0.008, 0.002, abs(var_uv.y - 0.5));
    bg += vec3(0.15) * center_line;

    // Local UV simulation (var_uv.x = localuv.x, var_uv.y = localuv.y for visualization)
    float local_x = var_uv.x;
    float local_y = var_uv.x;  // Use x as proxy for position variation

    // X-axis wobble from cloth.fp (multi-frequency)
    float wobble_x = sin(var_time * 25.132 + local_y * 6.283 + 0.5) * 0.35
                   + sin(var_time * 12.566 + local_x * 6.283) * 0.35
                   + sin(var_time * 37.699 + local_y * 12.566 + local_x * 3.0) * 0.2
                   + sin(var_time * 6.283 + local_y * 3.0) * 0.1;

    // Y-axis wobble from cloth.fp
    float wobble_y = sin(var_time * 18.849 + local_x * 6.283 + 1.57) * 0.4
                   + sin(var_time * 31.415 + local_y * 12.566) * 0.3
                   + sin(var_time * 50.265 + local_x * 18.849) * 0.2
                   + sin(var_time * 9.424 + local_x * 4.0 + 0.8) * 0.1;

    // Scale to display range
    float wobble_x_y = 0.5 + wobble_x * 0.25;
    float wobble_y_y = 0.5 + wobble_y * 0.25;

    // Draw curves
    vec3 color = bg;

    // X wobble - orange/red
    float x_line = draw_curve(var_uv.y, wobble_x_y, 0.018);
    color = mix(color, vec3(1.0, 0.5, 0.2), x_line);

    // Y wobble - teal
    float y_line = draw_curve(var_uv.y, wobble_y_y, 0.015);
    color = mix(color, vec3(0.2, 0.8, 0.7), y_line * 0.9);

    // Time marker
    float time_x = fract(var_time);
    float time_marker = smoothstep(0.008, 0.002, abs(var_uv.x - time_x));
    color = mix(color, vec3(1.0, 0.4, 0.2), time_marker * 0.9);

    // Label area
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.6, 0.4, 0.3), min(border, 1.0));

    frag_color = vec4(color, 1.0);
}
