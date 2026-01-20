#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in float var_enabled;
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

    // Billow parameters
    float billow_amplitude = var_billow.x;
    float billow_phase_offset = var_billow.y * 6.283;
    float billow_cycles = max(1.0, floor(var_billow.z + 0.5));

    // Phase varies across X like the actual cloth
    float phase = var_uv.x * 6.283;
    float z_phase = phase + billow_phase_offset;

    // Primary Z wave (blue): sin(time * 6.283 * billow_cycles + z_phase) * 0.7
    float z_primary = sin(var_time * 6.283 * billow_cycles + z_phase) * 0.7;
    float z_primary_y = 0.5 + z_primary * 0.35;

    // Secondary Z wave (purple): sin(time * 6.283 * (billow_cycles + 1) + z_phase * 1.3) * 0.3
    float z_secondary = sin(var_time * 6.283 * (billow_cycles + 1.0) + z_phase * 1.3) * 0.3;
    float z_secondary_y = 0.5 + z_secondary * 0.35;

    // Combined Z wave (white)
    float z_combined = z_primary + z_secondary;
    float z_combined_y = 0.5 + z_combined * 0.35;

    // Gust-modulated amplitude (0.25 baseline + 0.75 * gust)
    float wave_mult = 0.25 + var_gust * 0.75;
    float z_modulated = z_combined * wave_mult;
    float z_modulated_y = 0.5 + z_modulated * 0.35;

    // Draw curves
    vec3 color = bg;

    // Primary Z wave - blue
    float primary_line = draw_curve(var_uv.y, z_primary_y, 0.015);
    color = mix(color, vec3(0.3, 0.5, 1.0), primary_line * 0.7);

    // Secondary Z wave - purple
    float secondary_line = draw_curve(var_uv.y, z_secondary_y, 0.012);
    color = mix(color, vec3(0.7, 0.3, 0.9), secondary_line * 0.6);

    // Combined Z wave - bright cyan/white (on top)
    float combined_line = draw_curve(var_uv.y, z_combined_y, 0.018);
    color = mix(color, vec3(0.6, 0.95, 1.0), combined_line);

    // Modulated wave - green dashed
    float modulated_line = draw_curve(var_uv.y, z_modulated_y, 0.012);
    float dash = step(0.5, fract(var_uv.x * 20.0));
    color = mix(color, vec3(0.3, 1.0, 0.5), modulated_line * dash * 0.8);

    // Current time marker
    float time_x = fract(var_time);
    float time_marker = smoothstep(0.008, 0.002, abs(var_uv.x - time_x));
    color = mix(color, vec3(1.0, 0.4, 0.2), time_marker * 0.9);

    // Show billow_cycles value indicator (vertical bars at cycle boundaries)
    for (float i = 1.0; i < 8.0; i += 1.0) {
        if (i < billow_cycles) {
            float cycle_x = i / billow_cycles;
            float cycle_marker = smoothstep(0.006, 0.002, abs(var_uv.x - cycle_x));
            color = mix(color, vec3(0.4, 0.4, 0.5), cycle_marker * 0.5);
        }
    }

    // Label area at top
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.4, 0.5, 0.7), min(border, 1.0));

    // Grey out when disabled
    if (var_enabled < 0.5) {
        float grey = dot(color, vec3(0.299, 0.587, 0.114));
        color = vec3(grey) * 0.4;
    }

    frag_color = vec4(color, 1.0);
}
