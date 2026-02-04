#version 140

in vec2 var_uv;
in float var_time;
in float var_gust;
in float var_enabled;
in vec4 var_billow;
in vec4 var_noise;
in vec4 var_params;
in vec4 var_noise_texture;

uniform sampler2D noise_texture;

out vec4 frag_color;

// Hash function for noise
const float NOISE_TILE_PERIOD = 8.0;  // Noise tiles every 8 units for seamless looping

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Wrap integer coordinates for seamless tiling
    vec2 i00 = mod(i, NOISE_TILE_PERIOD);
    vec2 i10 = mod(i + vec2(1.0, 0.0), NOISE_TILE_PERIOD);
    vec2 i01 = mod(i + vec2(0.0, 1.0), NOISE_TILE_PERIOD);
    vec2 i11 = mod(i + vec2(1.0, 1.0), NOISE_TILE_PERIOD);

    float a = dot(hash22(i00), f);
    float b = dot(hash22(i10), f - vec2(1.0, 0.0));
    float c = dot(hash22(i01), f - vec2(0.0, 1.0));
    float d = dot(hash22(i11), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) + 0.5;
}

float fbmNoise(vec2 p, float scroll_speed, float orientation) {
    float value = 0.0;
    float amplitude = 0.5;

    // Seamless looping: fract() cycles 0-1, multiply by tile period for full loop
    float scroll_amount = fract(scroll_speed) * NOISE_TILE_PERIOD;

    // Orientation controls scroll direction:
    // orientation=0 (banner/vertical): scroll up (+Y direction, bottom to top)
    // orientation=1 (flag/horizontal): scroll left (-X direction, right to left)
    vec2 scroll = mix(
        vec2(0.0, scroll_amount),    // Banner: scroll +Y (bottom to top)
        vec2(-scroll_amount, 0.0)    // Flag: scroll -X (right to left)
    , orientation);

    value += amplitude * valueNoise(p + scroll);
    p *= 2.0; amplitude *= 0.5;
    value += amplitude * valueNoise(p + scroll * 2.0);  // 2.0 ensures both octaves loop together

    return value;
}

void main()
{
    // Noise parameters (procedural)
    float noise_intensity = var_noise.x;
    float noise_scroll_speed = var_noise.y;
    float noise_scale = var_noise.z;
    float noise_gust_influence = var_noise.w;
    float orientation = var_params.z;

    // Texture noise parameters
    float tex_influence = var_noise_texture.x;
    float tex_scroll_speed = var_noise_texture.y;
    float tex_scale = var_noise_texture.z;

    // Noise time
    float noise_time = var_time * noise_scroll_speed;

    // Stretch UV for rigid rows/columns (same as cloth.fp)
    vec2 noise_uv = var_uv * noise_scale * mix(
        vec2(0.12, 1.0),   // Vertical cloth (banner): thin X, full Y -> horizontal rows
        vec2(1.0, 0.12)    // Horizontal cloth (flag): full X, thin Y -> vertical columns
    , orientation);

    // Calculate procedural noise
    float procedural_noise = fbmNoise(noise_uv, noise_time, orientation);

    // Calculate texture noise with orientation-aware UVs
    vec2 tex_noise_uv = mix(
        var_uv,
        vec2(var_uv.y, var_uv.x)
    , orientation) * tex_scale;

    // Scroll texture noise along the "flow" direction (away from anchor)
    // After UV swap for flag, tex_noise_uv.y maps to screen-X (horizontal position)
    // Banner: scroll +Y (downward visual), Flag: scroll -Y (rightward visual)
    float tex_scroll_offset = var_time * tex_scroll_speed;
    tex_noise_uv.y += mix(tex_scroll_offset, -tex_scroll_offset, orientation);

    float texture_noise_value = texture(noise_texture, tex_noise_uv).r;

    // Blend between procedural and texture noise
    float noise_value = mix(procedural_noise, texture_noise_value, tex_influence);

    // Apply gust influence
    float noise_gust_factor = mix(1.0, var_gust, noise_gust_influence);
    float final_noise = (noise_value - 0.5) * noise_intensity * noise_gust_factor;

    // Visualize as colored bands
    vec3 color;

    // Base noise visualization - different colors for texture vs procedural
    float normalized = noise_value;
    if (tex_influence > 0.5) {
        // Texture mode: purple-orange gradient
        color = mix(vec3(0.3, 0.1, 0.4), vec3(0.9, 0.6, 0.3), normalized);
    } else {
        // Procedural mode: blue-green gradient
        color = mix(vec3(0.1, 0.2, 0.4), vec3(0.2, 0.8, 0.6), normalized);
    }

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

    // Label area with mode indicator
    if (var_uv.y > 0.92) {
        color = vec3(0.15, 0.17, 0.20);

        // Mode indicator in top-right corner
        if (var_uv.x > 0.75 && var_uv.y > 0.92) {
            // Show TEX (orange) or SIN (blue) based on influence
            if (tex_influence > 0.5) {
                color = vec3(0.9, 0.5, 0.2);  // Orange for texture
            } else {
                color = vec3(0.2, 0.5, 0.8);  // Blue for procedural sine
            }
        }
    }

    // Border
    float border = step(var_uv.x, 0.01) + step(0.99, var_uv.x) +
                   step(var_uv.y, 0.01) + step(0.99, var_uv.y);
    color = mix(color, vec3(0.3, 0.6, 0.5), min(border, 1.0));

    // Grey out when disabled
    if (var_enabled < 0.5) {
        float grey = dot(color, vec3(0.299, 0.587, 0.114));
        color = vec3(grey) * 0.4;
    }

    frag_color = vec4(color, 1.0);
}
