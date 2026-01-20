#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;

out vec4 frag_color;

// Hash function for noise
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = dot(hash22(i), f);
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) + 0.5;
}

float fbmNoise(vec2 p, float scroll_speed, float orientation) {
    float value = 0.0;
    float amplitude = 0.5;

    float scroll_primary = sin(scroll_speed * 6.283) * 0.5 + sin(scroll_speed * 12.566) * 0.25;
    float scroll_secondary = sin(scroll_speed * 6.283 + 1.57) * 0.3 + sin(scroll_speed * 18.849) * 0.15;

    vec2 scroll = mix(
        vec2(scroll_primary, scroll_secondary * 0.3),
        vec2(scroll_secondary * 0.3, scroll_primary)
    , orientation);

    value += amplitude * valueNoise(p + scroll);
    p *= 2.0; amplitude *= 0.5;
    value += amplitude * valueNoise(p + scroll * 1.5);

    return value;
}

void main()
{
    // Noise parameters
    float noise_intensity = var_noise.x;
    float noise_scroll_speed = var_noise.y;
    float noise_scale = var_noise.z;
    float noise_gust_influence = var_noise.w;
    float orientation = var_params.z;

    // Noise time
    float noise_time = var_time * noise_scroll_speed;

    // Stretch UV for rigid rows/columns (same as cloth.fp)
    vec2 noise_uv = var_uv * noise_scale * mix(
        vec2(1.0, 0.12),   // Vertical cloth: horizontal rows
        vec2(0.12, 1.0)    // Horizontal cloth: vertical columns
    , orientation);

    // Calculate noise
    float noise_value = fbmNoise(noise_uv, noise_time, orientation);

    // Apply gust influence
    float noise_gust_factor = mix(1.0, var_gust, noise_gust_influence);
    float final_noise = (noise_value - 0.5) * noise_intensity * noise_gust_factor;

    // Visualize as colored bands
    vec3 color;

    // Base noise visualization (blue-green gradient)
    float normalized = noise_value;
    color = mix(vec3(0.1, 0.2, 0.4), vec3(0.2, 0.8, 0.6), normalized);

    // Add intensity visualization overlay
    float intensity_vis = abs(final_noise) * 0.5;
    color += vec3(intensity_vis * 0.5, intensity_vis * 0.3, 0.0);

    // Show scroll direction with subtle lines
    if (orientation > 0.5) {
        // Vertical columns for flags
        float col_line = smoothstep(0.02, 0.0, abs(fract(var_uv.x * 8.0) - 0.5) - 0.48);
        color += vec3(0.1) * col_line;
    } else {
        // Horizontal rows for banners
        float row_line = smoothstep(0.02, 0.0, abs(fract(var_uv.y * 8.0) - 0.5) - 0.48);
        color += vec3(0.1) * row_line;
    }

    // Label area
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.3, 0.6, 0.5), min(border, 1.0));

    frag_color = vec4(color, 1.0);
}
