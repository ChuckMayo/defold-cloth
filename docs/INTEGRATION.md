# Integration Guide

This guide covers how to add cloth animation to your Defold project.

## Prerequisites

- Defold 1.4.0 or later
- A sprite you want to animate as cloth

## Step 1: Add the Dependency

Open your `game.project` file and add the cloth library URL to your dependencies:

```ini
[project]
dependencies#0 = https://github.com/YOUR_USERNAME/defold-cloth/archive/refs/tags/v1.0.0.zip
```

After saving, select **Project > Fetch Libraries** from the menu.

## Step 2: Prepare Your Sprite

### Sprite Requirements

Your sprite should be designed with cloth animation in mind:

1. **Transparent edges** - The edge shimmer effect works best with semi-transparent edges (like tassels)
2. **Vertical orientation** - The shader assumes top = anchored, bottom = free
3. **Know your dimensions** - You'll need the exact pixel width and height

### Assign the Cloth Material

In your game object's sprite component:

1. Click on the **Material** field
2. Select `/cloth/materials/cloth.material`

## Step 3: Set Required Uniforms

The cloth material requires you to set the sprite dimensions. This is critical for correct animation.

### In Your Script (Recommended)

```lua
function init(self)
    local sprite_url = msg.url("#sprite")

    -- REQUIRED: Set sprite dimensions in pixels
    go.set(sprite_url, "sprite_size", vmath.vector4(256, 384, 1, 1))

    -- OPTIONAL: Set pivot position (default is top-center)
    -- x: 0.0 = left edge, 0.5 = center, 1.0 = right edge
    -- y: 0.0 = top edge, 0.5 = center, 1.0 = bottom edge
    go.set(sprite_url, "pivot_offset", vmath.vector4(0.5, 0.0, 0, 0))
end
```

### In the Collection (Alternative)

You can also set these values in the collection editor:

1. Select the game object instance
2. In Properties, find **component_properties**
3. Add overrides for `sprite_size` and `pivot_offset`

## Step 4: Create the Animator

The `ClothAnimator` module handles the physics simulation and gust system.

```lua
local ClothAnimator = require('cloth.cloth_animator')

function init(self)
    local sprite_url = msg.url("#sprite")

    -- Set dimensions first
    go.set(sprite_url, "sprite_size", vmath.vector4(256, 384, 1, 1))

    -- Create animator (basic)
    self.cloth = ClothAnimator.create(sprite_url)

    -- OR: Create with a preset
    self.cloth = ClothAnimator.create_banner(sprite_url)

    -- OR: Create with custom config
    self.cloth = ClothAnimator.create(sprite_url, {
        spring_stiffness = 0.05,
        gust_min_interval = 2.0,
    })
end
```

## Step 5: Update Every Frame

The animator needs to track position changes to create velocity-based cloth response.

```lua
function update(self, dt)
    if self.cloth then
        -- Basic: just pass position
        self.cloth:update(dt, go.get_world_position())

        -- With scale (for scaled sprites)
        local scale = go.get_world_scale()
        self.cloth:update(dt, go.get_world_position(), scale.x)
    end
end
```

## Step 6: Clean Up

Always destroy the animator when the game object is destroyed:

```lua
function final(self)
    if self.cloth then
        self.cloth:destroy()
        self.cloth = nil
    end
end
```

## Complete Example

```lua
local ClothAnimator = require('cloth.cloth_animator')

local SPRITE_WIDTH = 256
local SPRITE_HEIGHT = 384

function init(self)
    local sprite_url = msg.url("#sprite")

    -- Configure shader
    go.set(sprite_url, "sprite_size", vmath.vector4(SPRITE_WIDTH, SPRITE_HEIGHT, 1, 1))
    go.set(sprite_url, "pivot_offset", vmath.vector4(0.5, 0.0, 0, 0))

    -- Create animator
    self.cloth = ClothAnimator.create_banner(sprite_url)
end

function update(self, dt)
    if self.cloth then
        self.cloth:update(dt, go.get_world_position())
    end
end

function final(self)
    if self.cloth then
        self.cloth:destroy()
        self.cloth = nil
    end
end
```

## Advanced: Multiple Cloth Objects

If you have many cloth objects, manage them efficiently:

```lua
function init(self)
    self.cloth_animators = {}
end

function add_cloth(self, sprite_url, width, height)
    go.set(sprite_url, "sprite_size", vmath.vector4(width, height, 1, 1))
    local animator = ClothAnimator.create(sprite_url)
    table.insert(self.cloth_animators, {
        animator = animator,
        go_id = go.get_id()
    })
end

function update(self, dt)
    for _, item in ipairs(self.cloth_animators) do
        local pos = go.get_world_position(item.go_id)
        item.animator:update(dt, pos)
    end
end

function final(self)
    for _, item in ipairs(self.cloth_animators) do
        item.animator:destroy()
    end
    self.cloth_animators = {}
end
```

## Next Steps

- See [Parameters Reference](PARAMETERS.md) for all configuration options
- See [Troubleshooting](TROUBLESHOOTING.md) if animation doesn't look right
