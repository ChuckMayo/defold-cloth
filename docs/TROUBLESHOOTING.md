# Troubleshooting

Common issues and solutions for cloth animation.

## Sprite Not Animating

### Symptom
The sprite displays but doesn't move at all.

### Solutions

1. **Check sprite_size is set**
   ```lua
   go.set(sprite_url, "sprite_size", vmath.vector4(width, height, 1, 1))
   ```
   The shader needs to know the sprite dimensions to calculate height-based effects.

2. **Verify cloth material is assigned**
   Make sure your sprite component uses `/cloth/materials/cloth.material`.

3. **Confirm animator is updating**
   ```lua
   function update(self, dt)
       self.cloth:update(dt, go.get_world_position())  -- Must call every frame
   end
   ```

4. **Check for errors in console**
   Look for shader compilation errors or Lua errors.

---

## Animation Looks Wrong / Distorted

### Symptom
The cloth animates but looks stretched, squished, or moves in unexpected ways.

### Solutions

1. **sprite_size doesn't match actual sprite**
   The `sprite_size` uniform must match your sprite's actual pixel dimensions:
   ```lua
   -- If your sprite is 256x384 pixels:
   go.set(sprite_url, "sprite_size", vmath.vector4(256, 384, 1, 1))
   ```

2. **pivot_offset is wrong**
   For a banner hanging from the top:
   ```lua
   go.set(sprite_url, "pivot_offset", vmath.vector4(0.5, 0.0, 0, 0))
   ```
   For a flag attached on the left:
   ```lua
   go.set(sprite_url, "pivot_offset", vmath.vector4(0.0, 0.5, 0, 0))
   ```

3. **Sprite is scaled**
   If your sprite is scaled, pass the scale to update:
   ```lua
   local scale = go.get_world_scale()
   self.cloth:update(dt, go.get_world_position(), scale.x)
   ```

---

## Edge Wobble Not Visible

### Symptom
The main sway animation works but edge shimmer effect isn't showing.

### Solutions

1. **Sprite has no transparent edges**
   The edge detection relies on alpha differences. Make sure your sprite has:
   - Semi-transparent edges
   - Alpha gradients on tassels/fringe
   - Not all fully opaque

2. **effect_height is too low**
   ```lua
   go.set(sprite_url, "cloth_frag_params", vmath.vector4(1.0, 3.0, 0.7, 0))
   -- z=0.7 means bottom 70% gets the effect
   ```

3. **wobble_strength is too low**
   ```lua
   go.set(sprite_url, "cloth_frag_params", vmath.vector4(2.0, 3.0, 0.5, 0))
   -- x=2.0 for stronger wobble
   ```

---

## No Gusts Happening

### Symptom
Cloth sways but never gets stronger bursts of movement.

### Solutions

1. **Wait longer**
   Random gusts occur every 4-8 seconds by default.

2. **Manually trigger to test**
   ```lua
   self.cloth:trigger_gust(1.0)
   ```

3. **Check gusts are enabled**
   ```lua
   self.cloth:set_gusts_enabled(true)
   ```

4. **Using cape preset?**
   The cape preset disables random gusts. Use banner preset or custom config:
   ```lua
   self.cloth = ClothAnimator.create(sprite_url, {
       gust_min_interval = 4.0,
       gust_max_interval = 8.0,
   })
   ```

---

## Velocity Response Not Working

### Symptom
Cloth doesn't trail behind when the object moves.

### Solutions

1. **Position not changing**
   The animator detects movement by comparing positions between frames. Make sure the object is actually moving:
   ```lua
   -- This WILL trigger velocity response
   go.set_position(new_pos)

   -- This will NOT (animator doesn't know about animation targets)
   go.animate(go.get_id(), "position", ...)
   ```

2. **Using animated position**
   If you're animating position with `go.animate()`, you may need to manually track velocity or accept that the spring physics won't react to animation.

3. **input_force too low**
   ```lua
   self.cloth = ClothAnimator.create(sprite_url, {
       input_force = 0.06,  -- More responsive
   })
   ```

---

## Z-Fighting / Clipping Issues

### Symptom
The cloth clips through other objects or flickers.

### Solutions

1. **Adjust Z position**
   Move your cloth sprite slightly forward (higher Z):
   ```lua
   local pos = go.get_position()
   pos.z = pos.z + 0.1
   go.set_position(pos)
   ```

2. **Reduce amplitude**
   Large amplitudes can cause the cloth to clip through nearby objects:
   ```lua
   go.set(sprite_url, "cloth_params", vmath.vector4(1.0, 15.0, 1.0, 0.1))
   -- y=15.0 for smaller sway
   ```

---

## Performance Issues

### Symptom
Frame rate drops with many cloth objects.

### Solutions

1. **Reduce detection_radius**
   Fewer texture samples per pixel:
   ```lua
   go.set(sprite_url, "cloth_frag_params", vmath.vector4(1.0, 1.0, 0.5, 0))
   -- y=1.0 instead of 3.0
   ```

2. **Disable fragment effects**
   Set effect_height to 0:
   ```lua
   go.set(sprite_url, "cloth_frag_params", vmath.vector4(0, 0, 0, 0))
   ```

3. **Use fewer animators**
   Each ClothAnimator has timer overhead. For distant/small cloth, consider skipping the animator and just letting the shader's idle animation play.

---

## Black Screen / Shader Errors

### Symptom
Sprite doesn't render at all, or entire screen is black.

### Solutions

1. **Check Defold version**
   The shaders use GLSL 140. Make sure you're using Defold 1.4.0 or later.

2. **Check platform**
   The shaders should work on:
   - macOS (OpenGL)
   - Windows (OpenGL/Vulkan)
   - iOS (Metal)
   - Android (OpenGL ES / Vulkan)
   - HTML5 (WebGL 2)

3. **Look for shader compilation errors**
   Check the console output when the game starts.

4. **Test with built-in material**
   Temporarily switch to Defold's built-in sprite material to verify the sprite itself works.

---

## Still Having Issues?

1. Check the example project to see working implementations
2. Compare your setup with the integration guide
3. Open an issue on GitHub with:
   - Defold version
   - Platform (macOS, Windows, iOS, etc.)
   - Console output
   - Minimal reproduction steps
