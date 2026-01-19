# defold-cloth

A shader-driven 2D cloth simulation for [Defold](https://defold.com) game engine. Add realistic wind and movement effects to banners, flags, capes, curtains, and other fabric elements without physics overhead.

![Cloth Animation Demo](https://via.placeholder.com/600x200?text=Demo+GIF+coming+soon)

## Features

- **Vertex-based cloth sway** - Multi-frequency sine waves create organic movement
- **Height-based influence** - Anchor point stays fixed, free end moves naturally
- **Velocity response** - Cloth trails opposite to movement direction with spring physics
- **Random wind gusts** - Configurable timing and intensity for ambient animation
- **Rest gusts** - Automatic gust triggered when cloth settles after movement
- **Edge shimmer** - Fragment-level UV distortion for tassel and fabric edge effects
- **Mesh support** - Higher vertex count meshes for smoother cloth deformation
- **Orientation modes** - Vertical (banners, capes) and horizontal (flags)
- **GLSL 140 compatible** - Works on iOS, macOS, Windows, Linux, Android, and HTML5

## Quick Start

### 1. Add Dependency

Add to your `game.project` dependencies:

```
https://github.com/ChuckMayo/defold-cloth/archive/refs/tags/v1.0.0.zip
```

### 2. Choose Your Approach

**Sprite-based** (simpler, 4 vertices):
- Set sprite **Material** to `/cloth/materials/cloth_sprite.material`

**Mesh-based** (smoother, customizable vertex count):
- Use `/cloth/materials/cloth_mesh.material` with a mesh component
- Generate the mesh grid at runtime with `MeshGenerator`

### 3. Create Animator in Script

**Sprite example:**

```lua
local ClothAnimator = require('cloth.cloth_animator')

function init(self)
    local sprite_url = msg.url("#sprite")
    self.cloth = ClothAnimator.create_banner(sprite_url, {
        sprite_width = 256,
        sprite_height = 384,
    })
end

function update(self, dt)
    self.cloth:update(dt, go.get_world_position())
end

function final(self)
    self.cloth:destroy()
end
```

**Mesh example:**

```lua
local ClothAnimator = require('cloth.cloth_animator')
local MeshGenerator = require('cloth.mesh_generator')

function init(self)
    local mesh_url = msg.url('#mesh')

    -- Create a 10x8 grid mesh (more vertices = smoother deformation)
    MeshGenerator.setup_mesh(mesh_url, 10, 8, 384, 192)

    self.cloth = ClothAnimator.create_flag(mesh_url, {
        sprite_width = 384,
        sprite_height = 192,
    })
end

function update(self, dt)
    self.cloth:update(dt, go.get_position())
end

function final(self)
    self.cloth:destroy()
end
```

### 4. Using Presets

```lua
-- Vertical banner (top-anchored, gentle sway)
self.cloth = ClothAnimator.create_banner(sprite_url, config)

-- Horizontal flag (side-anchored, dramatic wave)
self.cloth = ClothAnimator.create_flag(mesh_url, config)

-- Character cape (responsive to movement)
self.cloth = ClothAnimator.create_cape(sprite_url, config)

-- Stage curtain (large, slow, dramatic)
self.cloth = ClothAnimator.create_curtain(sprite_url, config)
```

## Configuration

### Custom Configuration

```lua
local cloth = ClothAnimator.create(sprite_url, {
    -- Sprite dimensions (required for correct animation)
    sprite_width = 256,
    sprite_height = 384,

    -- Spring physics
    spring_stiffness = 0.05,    -- Higher = snappier return to rest
    spring_damping = 0.90,      -- Higher = more friction
    input_force = 0.04,         -- Higher = more responsive to movement
    velocity_max = 1.0,         -- Maximum displacement magnitude

    -- Orientation: 0 = vertical (banners), 1 = horizontal (flags)
    orientation = 0.0,

    -- Gusts
    gust_min_interval = 3.0,    -- Minimum seconds between gusts
    gust_max_interval = 6.0,    -- Maximum seconds between gusts
    rest_gust_enabled = true,   -- Trigger gust when settling

    -- Fragment shader (edge shimmer)
    frag_wobble_strength = 1.0,
    frag_detection_radius = 3.0,
    frag_effect_height = 0.5,
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

-- Update fragment shader parameters
cloth:set_frag_params(wobble_strength, detection_radius, effect_height)

-- Update sprite dimensions (if sprite size changes)
cloth:set_sprite_size(width, height, pivot_offset_x, pivot_offset_y)

-- Adjust gravity params for horizontal cloth
cloth:set_gravity_params(sag_multiplier, contract_multiplier)
```

## Examples

Run the included example project to see demos of:

- **Banner** - Draggable vertical banner with velocity response
- **Flag** - Sprite-based horizontal flag
- **Flag Mesh** - Mesh-based flag with smoother wave animation
- **Cape** - Sprite-based cape following movement
- **Cape Mesh** - Mesh-based cape with more detailed deformation

## Documentation

- [Integration Guide](docs/INTEGRATION.md) - Detailed setup instructions
- [Parameters Reference](docs/PARAMETERS.md) - Complete parameter documentation
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## How It Works

### Vertex Shader
1. Calculates position-based influence (anchor point fixed, free end moves)
2. Applies multi-frequency sine waves for organic sway
3. Adds velocity-based displacement (cloth trails opposite to movement)
4. Modulates effects by gust strength

### Fragment Shader
1. Detects edges via alpha neighbor sampling
2. Applies UV distortion to detected edges
3. Scales effect by position (more wobble at free end)

### Lua Animator
1. Tracks position changes via spring physics
2. Schedules random wind gusts
3. Triggers rest gusts when settling after movement

### Mesh Generator
1. Creates grid buffer with configurable resolution
2. Sets up position, UV, and normal streams
3. Assigns buffer to mesh component at runtime

## Performance

- **Vertex shader**: Minimal cost per vertex
- **Fragment shader**: 5 texture samples per pixel for edge detection
- **Lua overhead**: Simple vector math per frame per animator

For many cloth elements, consider:
- Using sprite-based approach (4 vertices) for distant/small cloth
- Reducing mesh grid resolution where detail isn't needed
- Setting `frag_effect_height` to 0 to disable fragment effects

## License

MIT License - free for commercial and personal use.
