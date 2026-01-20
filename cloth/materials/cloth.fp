#version 140

in vec2 var_texcoord0;
in vec2 var_localuv;         // Normalized sprite-local UV (0-1), independent of atlas
in float var_cloth_time;
in vec4 var_cloth_params;
in float var_gust_strength;
in vec2 var_cloth_velocity;  // x=horizontal displacement, y=vertical displacement

uniform sampler2D texture_sampler;

uniform cloth_fp
{
    vec4 cloth_frag_params;  // x=edge_wobble_strength, y=edge_detection_radius, z=effect_start_height (0-1), w=unused
    vec4 cloth_noise_params;  // x=intensity, y=scroll_speed, z=scale, w=gust_influence
};

out vec4 frag_color;

// Procedural noise functions for scrolling texture effect
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
    // Velocity magnitude for dynamic effects
    float vel_magnitude = length(var_cloth_velocity);
    float vel_boost = min(vel_magnitude * 3.0, 1.0);  // 0-1 range for velocity influence

    // Edge detection: sample alpha at neighboring pixels (radius increases with velocity)
    float base_pixel_size = cloth_frag_params.y / 512.0;
    float pixel_size = base_pixel_size * (1.0 + vel_boost * 0.5);  // Up to 1.5x radius when dragging

    // Sample alpha at current and neighboring positions
    float alpha_center = texture(texture_sampler, var_texcoord0.xy).a;
    float alpha_left   = texture(texture_sampler, var_texcoord0.xy + vec2(-pixel_size, 0.0)).a;
    float alpha_right  = texture(texture_sampler, var_texcoord0.xy + vec2( pixel_size, 0.0)).a;
    float alpha_up     = texture(texture_sampler, var_texcoord0.xy + vec2(0.0,  pixel_size)).a;
    float alpha_down   = texture(texture_sampler, var_texcoord0.xy + vec2(0.0, -pixel_size)).a;

    // Calculate edge factor: high where alpha differs from neighbors
    float alpha_diff = abs(alpha_center - alpha_left) + abs(alpha_center - alpha_right)
                     + abs(alpha_center - alpha_up) + abs(alpha_center - alpha_down);
    float edge_factor = clamp(alpha_diff * 2.0, 0.0, 1.0);

    // Also boost effect for semi-transparent pixels (tassels often have alpha < 1)
    float transparency_boost = 1.0 - alpha_center;
    edge_factor = max(edge_factor, transparency_boost * 0.5);

    // Height influence (more wobble at bottom, with configurable cutoff)
    // effect_height: z = how much of banner from BOTTOM gets effect
    // z=0.3 → bottom 30%, z=0.7 → bottom 70%, z=1.0 → entire banner
    float effect_height = cloth_frag_params.z;
    // var_localuv.y: 0 at top (attachment), 1 at bottom (tassels)
    // Effect where localuv.y > (1 - effect_height)
    float height_threshold = 1.0 - effect_height;
    float height_factor = 0.0;
    if (var_localuv.y > height_threshold) {
        // Linear ramp: 0 at threshold, 1 at bottom
        height_factor = (var_localuv.y - height_threshold) / (effect_height + 0.001);
    }

    // Gust-modulated wave amplitude (0.25 baseline, up to 1.0 during gust)
    float wave_multiplier = 0.25 + var_gust_strength * 0.75;

    // Velocity extends wobble effect higher up the banner
    float vel_height_boost = min(vel_magnitude * 3.0, 0.75);  // Up to 0.75 additional height
    height_factor = min(height_factor + vel_height_boost, 1.0);

    // UV distortion wave for shimmer (uses local UV so pattern stays fixed during movement)
    // All frequencies are multiples of 2π (6.283) so they complete full cycles when time loops 0→1

    // X-axis wobble (side-to-side shimmer) - multiple frequencies for organic motion
    float wobble_x = sin(var_cloth_time * 25.132 + var_localuv.y * 6.283 + 0.5) * 0.35
                   + sin(var_cloth_time * 12.566 + var_localuv.x * 6.283) * 0.35
                   + sin(var_cloth_time * 37.699 + var_localuv.y * 12.566 + var_localuv.x * 3.0) * 0.2
                   + sin(var_cloth_time * 6.283 + var_localuv.y * 3.0) * 0.1;  // Slow base wave

    // Y-axis wobble (vertical ripple/flutter) - offset phase for organic movement
    float wobble_y = sin(var_cloth_time * 18.849 + var_localuv.x * 6.283 + 1.57) * 0.4
                   + sin(var_cloth_time * 31.415 + var_localuv.y * 12.566) * 0.3
                   + sin(var_cloth_time * 50.265 + var_localuv.x * 18.849) * 0.2
                   + sin(var_cloth_time * 9.424 + var_localuv.x * 4.0 + 0.8) * 0.1;  // Slow secondary

    // Base wobble strength - MUCH stronger now (was /512, now /128)
    float wobble_strength = cloth_frag_params.x / 128.0 * wave_multiplier;

    // Apply wobble across entire cloth, not just edges
    // Edge factor boosts wobble at edges, but there's a base level everywhere
    float base_wobble = 0.3;  // 30% wobble applies everywhere
    float wobble_factor = base_wobble + (1.0 - base_wobble) * edge_factor;

    // Height still matters - more wobble toward free end
    float final_wobble = wobble_strength * wobble_factor * (0.3 + 0.7 * height_factor);

    // Scrolling noise effect
    float noise_intensity = cloth_noise_params.x;
    float noise_scroll_speed = cloth_noise_params.y;
    float noise_scale = cloth_noise_params.z;
    float noise_gust_influence = cloth_noise_params.w;

    float noise_gust_factor = mix(1.0, var_gust_strength, noise_gust_influence);
    float noise_time = var_cloth_time * noise_scroll_speed;
    float orientation = var_cloth_params.z;

    // Stretch noise UV to create rigid rows/columns instead of clouds
    // orientation=0 (vertical cloth/banner): horizontal rows -> compress X, full Y
    // orientation=1 (horizontal cloth/flag): vertical columns -> full X, compress Y
    vec2 noise_uv = var_localuv * noise_scale * mix(
        vec2(0.12, 1.0),   // Vertical cloth (banner): thin X, full Y -> horizontal rows
        vec2(1.0, 0.12)    // Horizontal cloth (flag): full X, thin Y -> vertical columns
    , orientation);

    float noise_value = fbmNoise(noise_uv, noise_time, orientation);

    float noise_offset = (noise_value - 0.5) * noise_intensity * noise_gust_factor * height_factor;

    // Apply noise in wave direction only:
    // orientation=0 (banner): horizontal rows -> displace X
    // orientation=1 (flag): vertical columns -> displace Y
    vec2 noise_disp = mix(
        vec2(noise_offset * 0.015, 0.0),   // Banner: X displacement
        vec2(0.0, noise_offset * 0.015)    // Flag: Y displacement
    , orientation);

    vec2 distorted_uv = var_texcoord0.xy;
    distorted_uv.x += wobble_x * final_wobble + noise_disp.x;
    distorted_uv.y += wobble_y * final_wobble * 0.7 + noise_disp.y;  // Y wobble at 70% of X intensity

    frag_color = texture(texture_sampler, distorted_uv);

    // Reduce alpha fighting - discard low-alpha fragments
    if (frag_color.a < 0.01) {
        discard;
    }
}
