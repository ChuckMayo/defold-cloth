#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;

out vec4 frag_color;

// Draw a curve line with anti-aliasing
float draw_curve(float y_pos, float curve_value, float thickness) {
    float dist = abs(y_pos - curve_value);
    return smoothstep(thickness, thickness * 0.3, dist);
}

void main()
{
    // Background: dark with subtle grid
    vec3 bg = vec3(0.08, 0.10, 0.12);

    // Grid lines
    float grid_x = smoothstep(0.02, 0.0, abs(fract(var_uv.x * 4.0) - 0.5) - 0.48);
    float grid_y = smoothstep(0.02, 0.0, abs(fract(var_uv.y * 4.0) - 0.5) - 0.48);
    bg += vec3(0.05) * max(grid_x, grid_y);

    // Center line (y = 0.5)
    float center_line = smoothstep(0.008, 0.002, abs(var_uv.y - 0.5));
    bg += vec3(0.15) * center_line;

    // Map UV.x to time range [0, 1] representing one full wave cycle
    // Phase varies across X to show wave propagation
    float phase = var_uv.x * 6.283;

    // Primary wave (cyan): sin(time * 6.283 + phase) * 0.6
    float primary = sin(var_time * 6.283 + phase) * 0.6;
    float primary_y = 0.5 + primary * 0.35;  // Scale to fit in panel

    // Harmonic wave (magenta): sin(time * 12.566 + phase * 1.5) * 0.4
    float harmonic = sin(var_time * 12.566 + phase * 1.5) * 0.4;
    float harmonic_y = 0.5 + harmonic * 0.35;

    // Combined wave (white/yellow): weighted sum
    float combined = primary + harmonic;
    float combined_y = 0.5 + combined * 0.35;

    // Wave amplitude modulated by gust (0.25 baseline + 0.75 * gust)
    float wave_mult = 0.25 + var_gust * 0.75;
    float modulated = combined * wave_mult;
    float modulated_y = 0.5 + modulated * 0.35;

    // Draw curves
    vec3 color = bg;

    // Primary wave - cyan
    float primary_line = draw_curve(var_uv.y, primary_y, 0.015);
    color = mix(color, vec3(0.2, 0.7, 0.9), primary_line * 0.7);

    // Harmonic wave - magenta
    float harmonic_line = draw_curve(var_uv.y, harmonic_y, 0.012);
    color = mix(color, vec3(0.9, 0.3, 0.7), harmonic_line * 0.6);

    // Combined wave - bright yellow/white (on top)
    float combined_line = draw_curve(var_uv.y, combined_y, 0.018);
    color = mix(color, vec3(1.0, 0.95, 0.4), combined_line);

    // Modulated wave (after gust) - green, dashed appearance
    float modulated_line = draw_curve(var_uv.y, modulated_y, 0.012);
    float dash = step(0.5, fract(var_uv.x * 20.0));
    color = mix(color, vec3(0.3, 1.0, 0.5), modulated_line * dash * 0.8);

    // Current time marker - vertical line showing current phase
    float time_x = fract(var_time);  // Time position in [0,1] range
    float time_marker = smoothstep(0.008, 0.002, abs(var_uv.x - time_x));
    color = mix(color, vec3(1.0, 0.4, 0.2), time_marker * 0.9);

    // Label area at top
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.3, 0.5, 0.6), min(border, 1.0));

    frag_color = vec4(color, 1.0);
}
