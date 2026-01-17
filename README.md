# defold-cloth

A cloth/fabric animation system for [Defold](https://defold.com) game engine. Add realistic wind and movement effects to banners, flags, capes, curtains, and other fabric elements.

![Cloth Animation Demo](https://via.placeholder.com/600x200?text=Add+your+demo+gif+here)

## Features

- **Vertex-based cloth sway** - Multi-frequency sine waves create organic movement
- **Height-based influence** - Top portion anchored, bottom portion free (like a hanging banner)
- **Velocity response** - Cloth trails opposite to movement direction with spring physics
- **Random wind gusts** - Configurable timing and intensity for ambient animation
- **Rest gusts** - Automatic gust triggered when cloth settles after movement
- **Edge shimmer** - Fragment-level UV distortion for tassel and fabric edge effects
- **GLSL 140 compatible** - Works on iOS, macOS, Windows, Linux, Android, and HTML5

## Quick Start

### 1. Add Dependency

Add to your `game.project` dependencies:

```
https://github.com/YOUR_USERNAME/defold-cloth/archive/refs/tags/v1.0.0.zip
```

### 2. Assign Material to Sprite

In your sprite component:
- Set **Material** to `/cloth/materials/cloth.material`
- Set **sprite_size** uniform to match your sprite dimensions (pixels)

### 3. Create Animator in Script

```lua
local ClothAnimator = require('cloth.cloth_animator')

function init(self)
    local sprite_url = msg.url("#sprite")

    -- Set sprite dimensions (critical for correct animation)
    go.set(sprite_url, "sprite_size", vmath.vector4(256, 384, 1, 1))

    -- Create animator
    self.cloth = ClothAnimator.create(sprite_url)
end

function update(self, dt)
    -- Update each frame with current position
    self.cloth:update(dt, go.get_world_position())
end

function final(self)
    -- Clean up
    self.cloth:destroy()
end
```

### 4. Using Presets

For common use cases, use the built-in presets:

```lua
-- Vertical banner (top-anchored, gentle sway)
self.cloth = ClothAnimator.create_banner(sprite_url)

-- Horizontal flag (side-anchored, stiffer)
self.cloth = ClothAnimator.create_flag(sprite_url)

-- Character cape (responsive to movement, no random gusts)
self.cloth = ClothAnimator.create_cape(sprite_url)

-- Stage curtain (large, slow, dramatic)
self.cloth = ClothAnimator.create_curtain(sprite_url)
```

## Configuration

### Custom Configuration

```lua
local cloth = ClothAnimator.create(sprite_url, {
    -- Spring physics
    spring_stiffness = 0.05,    -- Higher = snappier return to rest
    spring_damping = 0.90,      -- Lower = more friction
    input_force = 0.04,         -- Higher = more responsive to movement
    velocity_max = 1.0,         -- Maximum displacement magnitude

    -- Gusts
    gust_min_interval = 3.0,    -- Minimum seconds between gusts
    gust_max_interval = 6.0,    -- Maximum seconds between gusts
    rest_gust_enabled = true,   -- Trigger gust when settling
})
```

### Runtime Adjustments

```lua
-- Trigger a manual gust
cloth:trigger_gust(0.8)  -- intensity 0-1

-- Disable random gusts
cloth:set_gusts_enabled(false)

-- Adjust physics
cloth:set_spring(0.08, 0.88)  -- stiffness, damping
```

### Shader Parameters

Set these on the sprite directly:

```lua
-- Wave animation parameters
go.set(sprite_url, "cloth_params", vmath.vector4(
    1.0,    -- speed: wave animation speed multiplier
    25.0,   -- amplitude_x: horizontal sway in pixels
    1.0,    -- (unused)
    0.2     -- edge_influence: extra sway at edges
))

-- Fragment wobble parameters
go.set(sprite_url, "cloth_frag_params", vmath.vector4(
    1.0,    -- wobble_strength: edge shimmer intensity
    3.0,    -- detection_radius: edge detection in pixels
    0.5     -- effect_height: bottom portion that wobbles (0-1)
))
```

## Examples

Run the included example project to see demos of:
- **Banner** - Draggable vertical banner with velocity response
- **Flag** - Auto-waving horizontal flag
- **Cape** - Click-to-move cape following character movement

## Documentation

- [Integration Guide](docs/INTEGRATION.md) - Detailed setup instructions
- [Parameters Reference](docs/PARAMETERS.md) - Complete parameter documentation
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## How It Works

### Vertex Shader
1. Calculates height-based influence (top 40% anchored, bottom 60% moves)
2. Applies multi-frequency sine waves for organic left-right sway
3. Adds velocity-based displacement (cloth trails opposite to movement)
4. Modulates all effects by gust strength (0.25 idle, 1.0 during gust)

### Fragment Shader
1. Detects edges via alpha neighbor sampling
2. Applies UV distortion to detected edges
3. Scales effect by height (more wobble at bottom)

### Lua Animator
1. Tracks position changes via spring physics
2. Schedules random wind gusts
3. Triggers rest gusts when settling after movement

## Performance

- **Vertex shader**: Minimal cost (only 4 vertices per sprite)
- **Fragment shader**: 5 texture samples per pixel for edge detection
- **Lua overhead**: Simple vector math per frame per animator

For many cloth sprites, consider:
- Reducing `detection_radius` for less texture sampling
- Setting `effect_height` to 0 to disable fragment effects entirely
- Using a simpler material without edge wobble

## License

MIT License - free for commercial and personal use.

## Credits

Original shader and animation system by [Once Upon a Galaxy](https://onceuponagalaxy.com).
