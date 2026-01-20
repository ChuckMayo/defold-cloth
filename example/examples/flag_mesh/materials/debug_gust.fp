#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;

out vec4 frag_color;

void main()
{
    vec3 bg = vec3(0.08, 0.10, 0.12);

    // Grid
    float grid_x = smoothstep(0.02, 0.0, abs(fract(var_uv.x * 10.0) - 0.5) - 0.48);
    float grid_y = smoothstep(0.02, 0.0, abs(fract(var_uv.y * 4.0) - 0.5) - 0.48);
    bg += vec3(0.04) * max(grid_x, grid_y);

    vec3 color = bg;

    // Gust envelope visualization
    // Show current gust strength as a filled bar from bottom
    float gust_height = var_gust * 0.8 + 0.1;  // Scale to 10%-90% of panel height

    // Filled area below gust level
    if (var_uv.y < gust_height) {
        // Gradient from blue (low) to orange (high)
        float intensity = var_uv.y / gust_height;
        vec3 low_color = vec3(0.2, 0.4, 0.8);
        vec3 high_color = vec3(1.0, 0.6, 0.2);
        color = mix(low_color, high_color, intensity * var_gust);

        // Add some texture
        float stripe = sin(var_uv.y * 60.0 + var_time * 3.0) * 0.5 + 0.5;
        color *= 0.8 + stripe * 0.2;
    }

    // Gust level line
    float gust_line = smoothstep(0.015, 0.005, abs(var_uv.y - gust_height));
    color = mix(color, vec3(1.0, 0.9, 0.3), gust_line);

    // Wave multiplier indicator (0.25 baseline + 0.75 * gust)
    float wave_mult = 0.25 + var_gust * 0.75;
    float wave_mult_y = wave_mult * 0.8 + 0.1;
    float wave_mult_line = smoothstep(0.012, 0.004, abs(var_uv.y - wave_mult_y));
    float dash = step(0.5, fract(var_uv.x * 15.0));
    color = mix(color, vec3(0.3, 1.0, 0.5), wave_mult_line * dash);

    // Baseline indicator at 0.25
    float baseline_y = 0.25 * 0.8 + 0.1;
    float baseline_line = smoothstep(0.008, 0.003, abs(var_uv.y - baseline_y));
    color = mix(color, vec3(0.5, 0.5, 0.6), baseline_line * 0.7);

    // Current time marker (shows position in gust cycle conceptually)
    float time_x = fract(var_time * 0.5);  // Slower time for envelope visualization
    float time_marker = smoothstep(0.008, 0.002, abs(var_uv.x - time_x));
    color = mix(color, vec3(1.0, 0.4, 0.2), time_marker * 0.7);

    // Value labels area on right
    if (var_uv.x > 0.85) {
        color *= 0.7;
        // Show tick marks for 0, 0.25, 0.5, 0.75, 1.0
        for (float v = 0.0; v <= 1.0; v += 0.25) {
            float tick_y = v * 0.8 + 0.1;
            float tick = smoothstep(0.006, 0.002, abs(var_uv.y - tick_y));
            color = mix(color, vec3(0.7), tick);
        }
    }

    // Label area
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.6, 0.5, 0.3), min(border, 1.0));

    frag_color = vec4(color, 1.0);
}
