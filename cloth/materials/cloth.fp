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
};

out vec4 frag_color;

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

    // UV distortion wave for side-to-side shimmer (uses local UV so pattern stays fixed during movement)
    // All frequencies are multiples of 2π (6.283) so they complete full cycles when time loops 0→1
    float wobble_x = sin(var_cloth_time * 25.132 + var_localuv.y * 6.283 + 0.5) * 0.4
                   + sin(var_cloth_time * 12.566 + var_localuv.x * 6.283) * 0.6;

    // Apply UV distortion scaled by edge factor, height, gust strength, and strength parameter
    float wobble_strength = cloth_frag_params.x / 512.0 * wave_multiplier;  // Convert to UV space
    vec2 distorted_uv = var_texcoord0.xy;
    distorted_uv.x += wobble_x * wobble_strength * edge_factor * height_factor;

    frag_color = texture(texture_sampler, distorted_uv);

    // Reduce alpha fighting - discard low-alpha fragments
    if (frag_color.a < 0.01) {
        discard;
    }
}
