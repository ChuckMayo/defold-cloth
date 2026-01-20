# defold-cloth

An experiment in shader-driven 2D cloth simulation for [Defold](https://defold.com).

This project explores how far you can push cloth-like animation using only shaders and simple Lua spring physics—no skeletal animation, no physics engine, no per-vertex CPU simulation. Just math on the GPU.

![Cloth Animation Demo](https://via.placeholder.com/600x200?text=Demo+GIF+coming+soon)

## Why Shader-Only?

Traditional cloth simulation typically involves:
- Skeletal rigs with weighted vertices
- Physics engines calculating forces per-vertex
- CPU-bound constraint solving

This approach asks: *what if we fake it entirely in the shader?* The vertex shader displaces vertices using sine waves, spring physics values, and time. The fragment shader adds edge shimmer effects. The Lua layer just tracks velocity and schedules wind gusts.

The result won't fool anyone looking for realistic cloth physics, but it's surprisingly effective for 2D game aesthetics—banners, flags, capes—and it's cheap enough to run hundreds of instances.

## Features

- **Vertex displacement** via multi-frequency sine waves
- **Velocity response** so cloth trails behind movement
- **Wind gusts** that fade in and out
- **Edge shimmer** via fragment shader UV distortion
- **Sprite and mesh modes** (4 vertices vs custom grid)
- **Horizontal and vertical** orientation support

## Examples

The project includes interactive demos:

1. **Banner** - Draggable vertical banner showing velocity response
2. **Flag** - Horizontal flag with wave animation and gravity sag
3. **Cape** - Movement-responsive cape (sprite vs mesh comparison)
4. **Stress Test** - Many flags to explore performance limits

## Quick Start

Add to your `game.project` dependencies:
```
https://github.com/ChuckMayo/defold-cloth/archive/refs/tags/v1.0.0.zip
```

Basic usage:
```lua
local ClothAnimator = require('cloth.cloth_animator')

function init(self)
    self.cloth = ClothAnimator.create_banner(msg.url("#sprite"), {
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

See the [docs](docs/) folder for detailed parameter reference.

## How It Works

**Vertex Shader**: Calculates a height-based influence factor (anchor stays fixed, free end moves). Applies sine waves at multiple frequencies for organic sway, plus velocity-based displacement so cloth trails behind movement.

**Fragment Shader**: Samples neighboring pixels to detect edges (via alpha), then distorts UVs along detected edges for a shimmering tassel effect.

**Lua Animator**: Tracks position delta each frame using spring physics. Schedules random wind gusts. Triggers a "rest gust" when cloth settles after movement.

## Limitations

This is an approximation, not a simulation:
- Cloth doesn't collide with anything
- No self-intersection handling
- Movement is deterministic (same inputs = same output)
- Won't look right for complex 3D cloth scenarios

It works well for stylized 2D games where "feels like cloth" matters more than physical accuracy.

## Performance

The stress test example spawns many flags to help you find your limits.

The main costs:
- **Vertex shader**: Cheap per-vertex math
- **Fragment shader**: 5 texture samples for edge detection (can disable)
- **Lua**: One spring calculation per animator per frame

## License

MIT - use it however you want.
