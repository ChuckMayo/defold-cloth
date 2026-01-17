# Parameters Reference

Complete documentation for all cloth animation parameters.

## Shader Uniforms

These are set directly on the sprite using `go.set()`.

### sprite_size (vec4) - REQUIRED

Sprite dimensions in pixels. **You must set this for correct animation.**

| Component | Description | Default |
|-----------|-------------|---------|
| x | Width in pixels | 256 |
| y | Height in pixels | 256 |
| z | Unused | 1 |
| w | Unused | 1 |

```lua
go.set(sprite_url, "sprite_size", vmath.vector4(256, 384, 1, 1))
```

### pivot_offset (vec4)

Defines where the cloth is anchored. Normalized 0-1 coordinates.

| Component | Description | Default |
|-----------|-------------|---------|
| x | Horizontal pivot (0=left, 0.5=center, 1=right) | 0.5 |
| y | Vertical pivot (0=top, 0.5=center, 1=bottom) | 0.0 |
| z | Unused | 0 |
| w | Unused | 0 |

```lua
-- Top-center (default, like a hanging banner)
go.set(sprite_url, "pivot_offset", vmath.vector4(0.5, 0.0, 0, 0))

-- Left edge (like a flag on a pole)
go.set(sprite_url, "pivot_offset", vmath.vector4(0.0, 0.5, 0, 0))
```

### cloth_params (vec4)

Wave animation parameters.

| Component | Description | Default | Range |
|-----------|-------------|---------|-------|
| x | Speed multiplier | 1.0 | 0.1 - 3.0 |
| y | Amplitude X (pixels) | 25.0 | 5.0 - 100.0 |
| z | Unused | 1.0 | - |
| w | Edge influence | 0.2 | 0.0 - 1.0 |

- **Speed**: Higher = faster wave animation
- **Amplitude X**: How far the cloth sways left/right in pixels
- **Edge influence**: Extra sway at left/right edges (0 = none, 1 = double)

```lua
go.set(sprite_url, "cloth_params", vmath.vector4(1.5, 40.0, 1.0, 0.3))
```

### cloth_frag_params (vec4)

Fragment shader edge wobble parameters.

| Component | Description | Default | Range |
|-----------|-------------|---------|-------|
| x | Wobble strength | 1.0 | 0.0 - 3.0 |
| y | Detection radius (pixels) | 3.0 | 1.0 - 10.0 |
| z | Effect height (0-1) | 0.5 | 0.0 - 1.0 |
| w | Unused | 0 | - |

- **Wobble strength**: Intensity of edge shimmer effect
- **Detection radius**: How many pixels to sample for edge detection (higher = softer edges, more GPU cost)
- **Effect height**: What portion of the sprite from the bottom gets the wobble effect (0.5 = bottom 50%)

```lua
go.set(sprite_url, "cloth_frag_params", vmath.vector4(2.0, 4.0, 0.7, 0))
```

### cloth_velocity (vec4)

**Managed by ClothAnimator** - don't set manually unless you have custom physics.

| Component | Description |
|-----------|-------------|
| x | Horizontal velocity/displacement |
| y | Vertical velocity/displacement |
| z | Gust strength (0-1) |
| w | World scale factor |

### cloth_time (vec4)

**Managed by ClothAnimator** - animated automatically.

| Component | Description |
|-----------|-------------|
| x | Animation time (0-1, loops every 3 seconds) |

---

## ClothAnimator Configuration

These are passed to `ClothAnimator.create()` as a config table.

### Spring Physics

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `velocity_scale` | Pixels/frame to normalized velocity | 0.02 | 0.01 - 0.05 |
| `velocity_max` | Maximum displacement magnitude | 0.8 | 0.5 - 2.0 |
| `spring_stiffness` | How strongly cloth returns to rest | 0.03 | 0.01 - 0.1 |
| `spring_damping` | Velocity retention per frame | 0.93 | 0.85 - 0.98 |
| `input_force` | How strongly movement affects cloth | 0.03 | 0.01 - 0.1 |

**Tips:**
- Higher `spring_stiffness` = snappier return to rest
- Lower `spring_damping` = more friction (faster settling)
- Higher `input_force` = more responsive to movement

### Random Gusts

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `gust_min_interval` | Minimum seconds between gusts | 4.0 | 1.0 - 20.0 |
| `gust_max_interval` | Maximum seconds between gusts | 8.0 | 2.0 - 30.0 |
| `gust_fade_in` | Fade-in duration (seconds) | 1.0 | 0.1 - 3.0 |
| `gust_hold` | Hold at full strength (seconds) | 0.5 | 0.0 - 2.0 |
| `gust_fade_out` | Fade-out duration (seconds) | 2.0 | 0.5 - 5.0 |

### Rest Gusts

Triggered when cloth settles after being moved.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rest_gust_enabled` | Enable rest gusts | true |
| `active_threshold` | Displacement above this = "active" | 0.15 |
| `rest_threshold` | Displacement below this triggers gust | 0.05 |
| `rest_gust_fade_in` | Faster fade-in for rest gusts | 0.35 |
| `rest_gust_min_intensity` | Minimum intensity | 0.1 |
| `rest_gust_max_intensity` | Maximum intensity | 1.0 |
| `rest_gust_vel_scale` | Peak velocity to intensity multiplier | 2.0 |

### Animation Timing

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wave_loop_duration` | Wave animation loop duration (seconds) | 3.0 |

---

## Presets

Built-in configurations for common use cases.

### Banner Preset

Top-anchored vertical banner with gentle sway.

```lua
ClothAnimator.create_banner(sprite_url)
-- Equivalent to:
ClothAnimator.create(sprite_url, {
    spring_stiffness = 0.03,
    spring_damping = 0.93,
    input_force = 0.03,
})
```

### Flag Preset

Side-anchored horizontal flag, stiffer response.

```lua
ClothAnimator.create_flag(sprite_url)
-- Equivalent to:
ClothAnimator.create(sprite_url, {
    spring_stiffness = 0.05,
    spring_damping = 0.90,
    input_force = 0.04,
})
```

### Cape Preset

Character cape, responsive to movement, no random gusts.

```lua
ClothAnimator.create_cape(sprite_url)
-- Equivalent to:
ClothAnimator.create(sprite_url, {
    spring_stiffness = 0.04,
    spring_damping = 0.88,
    input_force = 0.05,
    velocity_max = 1.0,
    rest_gust_enabled = false,
    gust_min_interval = 999999,  -- Effectively disabled
})
```

### Curtain Preset

Large curtain, slow and dramatic.

```lua
ClothAnimator.create_curtain(sprite_url)
-- Equivalent to:
ClothAnimator.create(sprite_url, {
    spring_stiffness = 0.02,
    spring_damping = 0.95,
    input_force = 0.02,
    gust_min_interval = 6.0,
    gust_max_interval = 12.0,
    gust_fade_in = 2.0,
    gust_fade_out = 4.0,
})
```

---

## Runtime Methods

### trigger_gust(intensity, fade_in)

Manually trigger a wind gust.

```lua
cloth:trigger_gust()          -- Full intensity, default fade-in
cloth:trigger_gust(0.5)       -- Half intensity
cloth:trigger_gust(1.0, 0.2)  -- Full intensity, fast fade-in
```

### set_gusts_enabled(enabled)

Enable or disable random gusts.

```lua
cloth:set_gusts_enabled(false)  -- Disable random gusts
cloth:set_gusts_enabled(true)   -- Re-enable
```

### set_spring(stiffness, damping)

Adjust spring physics at runtime.

```lua
cloth:set_spring(0.08, 0.85)  -- Snappier, more friction
```

### set_input_force(force)

Adjust movement responsiveness.

```lua
cloth:set_input_force(0.06)  -- More responsive
```

### get_config()

Get current configuration.

```lua
local config = cloth:get_config()
print(config.spring_stiffness)
```
