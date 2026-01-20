#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in float var_enabled;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;

out vec4 frag_color;

void main()
{
    // Influence calculation from cloth_mesh.vp
    float orientation = var_params.z;
    float edge_influence = var_params.w;

    // Simulate local UV across the cloth surface
    vec2 local_uv = var_uv;

    // Distance from anchor (same logic as vertex shader)
    // Vertical: anchor at top (v=1), so distance = 1 - v
    // Horizontal: anchor at left (u=0), so distance = u
    float distance_from_anchor = mix(1.0 - local_uv.y, local_uv.x, orientation);

    // Cross axis for edge influence
    float cross_axis = mix(local_uv.x, local_uv.y, orientation);

    // Distance-based influence
    float distance_factor = distance_from_anchor;

    // Edge influence - stronger at edges perpendicular to anchor
    float edge_factor = abs(cross_axis - 0.5) * 2.0;

    // Combined influence
    float influence = distance_factor * (1.0 + edge_factor * edge_influence);

    // Clamp for visualization
    influence = clamp(influence, 0.0, 1.5);

    // Color mapping: dark blue (low) -> cyan -> yellow -> white (high)
    vec3 color;
    if (influence < 0.33) {
        float t = influence / 0.33;
        color = mix(vec3(0.05, 0.1, 0.2), vec3(0.1, 0.4, 0.6), t);
    } else if (influence < 0.66) {
        float t = (influence - 0.33) / 0.33;
        color = mix(vec3(0.1, 0.4, 0.6), vec3(0.3, 0.8, 0.7), t);
    } else if (influence < 1.0) {
        float t = (influence - 0.66) / 0.34;
        color = mix(vec3(0.3, 0.8, 0.7), vec3(1.0, 0.9, 0.4), t);
    } else {
        float t = min((influence - 1.0) / 0.5, 1.0);
        color = mix(vec3(1.0, 0.9, 0.4), vec3(1.0, 1.0, 1.0), t);
    }

    // Add contour lines
    float contour = fract(influence * 5.0);
    float contour_line = smoothstep(0.05, 0.0, contour) + smoothstep(0.95, 1.0, contour);
    color = mix(color, color * 0.7, contour_line * 0.5);

    // Show anchor line
    if (orientation > 0.5) {
        // Horizontal: anchor at left
        float anchor_line = smoothstep(0.02, 0.01, var_uv.x);
        color = mix(color, vec3(1.0, 0.3, 0.2), anchor_line);
    } else {
        // Vertical: anchor at top
        float anchor_line = smoothstep(0.02, 0.01, 1.0 - var_uv.y);
        color = mix(color, vec3(1.0, 0.3, 0.2), anchor_line);
    }

    // Label area
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.5, 0.6, 0.4), min(border, 1.0));

    frag_color = vec4(color, 1.0);
}
