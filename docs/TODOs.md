# TODO
Things in here are listed in order of priority. We should complete them one at a time, and then update this document as needed so it is accurate.

*No active TODOs - all work complete*

# DONE
Move things here once they are complete and checked in

## Enhanced: Flag vertex displacement dramatically increased for collapse effect
**Problem**: Flag mesh only sagged slightly downward when it should collapse completely (except anchor side).

**Root Cause**: The gravity sag multiplier in `cloth_mesh.vp` was too conservative (30.0).

**Fix**: Increased gravity sag multiplier from 30.0 to 120.0 for dramatic collapse effect when gust strength is low.

**Files Modified**:
- `/cloth/materials/cloth_mesh.vp` - Increased gravity sag multiplier

## Enhanced: Cape vertex displacement for more dramatic draping
**Problem**: Cape felt too rigid when dragged and when gusting.

**Root Causes**:
1. Velocity amplitude was too low (125.0)
2. Cape preset had gusts disabled
3. Spring damping was too high, reducing movement
4. Wave amplitude in material was conservative

**Fixes**:
1. Increased velocity amplitude from 125 to 200 in `cloth_mesh.vp`
2. Updated cape preset: enabled gusts, reduced damping (0.88→0.85), increased input_force (0.05→0.08)
3. Increased wave amplitude in material from 25 to 40, edge influence from 0.2 to 0.3

**Files Modified**:
- `/cloth/materials/cloth_mesh.vp` - Increased velocity amplitude
- `/cloth/materials/cloth_mesh.material` - Increased wave amplitude and edge influence
- `/cloth/cloth_animator.lua` - Updated cape preset with more responsive settings

## Fixed: Mesh animation direction and enhanced cloth effects
**Problems**:
1. Mesh cape animation moved top more than bottom (inverted)
2. Mesh vertex distortion too subtle
3. Fragment shader edge wobble too subtle

**Root Causes & Fixes**:

1. **Cape animation inverted**: After V-coordinate flip in mesh generator, `local_uv.y=1` at top. Fixed by using `1.0 - local_uv.y` for distance calculation in mesh shader.

2. **Vertex distortion too subtle**:
   - Removed distance threshold (was 0.4, now starts from anchor)
   - Changed from quadratic to linear falloff for more visible movement
   - Added gravity sag for horizontal flags when gust is low

3. **Fragment wobble too subtle**:
   - Increased wobble strength 4x (divide by 128 instead of 512)
   - Added more wave frequencies for richer organic motion
   - Added 30% base wobble across entire cloth, not just edges
   - Y-axis wobble increased from 50% to 70% of X intensity

**Files Modified**:
- `/cloth/materials/cloth_mesh.vp` - Fixed distance calculation, added gravity sag
- `/cloth/materials/cloth.fp` - Enhanced wobble strength and frequencies

## Added: Multi-page UI for examples
**Goal**: Organize examples into separate pages with navigation for better demonstration.

**Implementation**:
- Created 3 pages: Banner, Cape, Flag
- Page 1 (Banner): Basic sprite cloth example
- Page 2 (Cape): Sprite vs mesh comparison (4 vertices vs 48 vertices)
- Page 3 (Flag): Horizontal orientation with sprite and mesh examples

**Files Added**:
- `/example/ui/navigation.gui` - GUI with title, description, arrows, page indicator
- `/example/ui/navigation.gui_script` - Handles navigation input and page switching

**Files Modified**:
- `/example/main.go` - Added navigation GUI component
- `/example/main.script` - Added page switching message handler (show_page)
- `/example/main.collection` - Repositioned objects for page layouts

**Navigation**:
- Left/right arrows to navigate pages
- Page indicator shows current page (1/3, 2/3, 3/3)
- Title and description update per page
- Objects show/hide based on current page

## Fixed: Cape mesh upside down and flag mesh resource conflict
**Problems**:
1. Cape mesh rendered upside down
2. Flag mesh failed with "resource already registered at path" error

**Root Causes**:
1. UV V-coordinates were not flipped for OpenGL convention (v=0 at bottom, v=1 at top)
2. MeshGenerator used a hardcoded resource path, causing conflicts when multiple meshes are created

**Fixes**:
1. Flipped V coordinates in mesh generator: `v = 1.0 - row / (rows - 1)`
2. Added resource counter to generate unique paths: `/cloth_mesh_buffer_N.bufferc`

## Added: Mesh-based cloth examples for cape and flag
**Goal**: Replace sprites with meshes having more vertices for complex movement (billowing cape, collapsing flag).

**Implementation**:
- Created `MeshGenerator` module (`cloth/mesh_generator.lua`) for runtime grid mesh generation
- Created mesh vertex shader (`cloth/materials/cloth_mesh.vp`) compatible with mesh components
- Created mesh material (`cloth/materials/cloth_mesh.material`)
- Added `cape_mesh` and `flag_mesh` example game objects
- Grid mesh configurations: cape 6x8 vertices, flag 10x5 vertices

**Files Added**:
- `/cloth/mesh_generator.lua` - Runtime mesh buffer generator
- `/cloth/materials/cloth_mesh.vp` - Mesh-compatible vertex shader
- `/cloth/materials/cloth_mesh.material` - Mesh material definition
- `/cloth/meshes/placeholder.buffer` - Placeholder buffer for mesh initialization
- `/example/examples/cape_mesh/` - Cape mesh example
- `/example/examples/flag_mesh/` - Flag mesh example

**Note**: Mesh examples use single texture files instead of atlas for simpler UV mapping.

## Added: Y-axis edge wobble movement
**Goal**: Add vertical edge wobble movement to all examples.

**Implementation**: Enhanced fragment shader (`cloth/materials/cloth.fp`) with Y-axis wobble:
- Added `wobble_y` calculation with offset phase for organic movement
- Applied Y-axis UV distortion at 50% intensity of X-axis wobble
- Wobble scales with edge factor, height factor, and gust strength

## Added: Flag pole
**Goal**: Add a flag pole to the left side of the flag.

**Implementation**: Added pole sprite component to `flag.go`:
- Uses banner texture scaled to thin pole shape (0.03 x 1.5)
- Positioned to left of flag at x=-200, y=100
- Placed behind flag (z=-0.1) using standard sprite material

**Note**: For production, replace with a dedicated pole asset.

## Fixed: Z-fighting with overlapping sprites
**Problem**: Sprites z-fight if they overlap. Setting different z positions caused only the banner to render.

**Root Cause**: Defold's default render script uses orthographic projection with near/far planes of -1 to 1. The original z values were:
- banner: z=1.0 (at far plane edge)
- flag: z=-1.0 (at near plane edge)
- cape: z=3.0 (outside far plane - clipped entirely!)

**Fix**: Updated example collection to use z values within valid range:
- banner: z=0.1
- flag: z=0.2
- cape: z=0.3

**Note for users**: Keep z values between -1 and 1 when using Defold's default render script. For extended z-range, create a custom render script with wider near/far planes.

## Fixed: Banner/cape shrink-expand when dragged
**Problem**: Dragging banner or cape caused rapid shrink/expand visual artifacts.

**Root Cause**: The depth push calculation was mixing displaced xy coordinates with modified z, causing projection inconsistencies.

**Fix**: Removed depth push entirely - now using `gl_Position = displaced_clip;`

## Fixed: Flag orientation (hung from left side)
**Problem**: Flag animated as if hung from top, but should be hung from left side.

**Solution**: Added `orientation` parameter:
- `orientation = 0.0` → Vertical (hung from top) - banners, capes
- `orientation = 1.0` → Horizontal (hung from left) - flags

**Changes**:
- Shader uses `mix()` to swap axes based on orientation
- Flag preset in ClothAnimator now uses `orientation = 1.0`
- Banner/cape are unaffected (use default `orientation = 0.0`)

## Fixed: Vertex displacement and edge distortion scale
**Problem**: Flag idle gusting wasn't visible, cape and banner idle wasn't visible, dragging caused flash/shrink-expand.

**Root Causes Found**:
1. Shader assumed TOP-CENTER pivot but Defold uses CENTER pivot by default
2. `local_uv.y` calculation didn't use `pivot_offset.y`, causing wrong height values
3. With wrong height, `influence` factor was 0 → no displacement
4. Depth push multipliers (4.0, 0.3) were too aggressive, causing visual artifacts

**Fixes Applied**:
- Updated `cloth.vp` to use `pivot_offset.y` in local_uv.y calculation
- Updated `cloth_sprite.material` default pivot_offset to (0.5, 0.5) for CENTER pivot
- Updated `cloth_animator.lua` to support `pivot_offset_x` and `pivot_offset_y`
- Reduced depth push multipliers from (4.0, 0.3) to (0.1, 0.05)
- Fixed example scripts bounds checking for CENTER pivot

## Fixed: Scripts feed in sprite size at runtime
**Problem**: Sprite size was baked into material, couldn't use same material for different sprite sizes.

**Solution**: Already implemented! ClothAnimator accepts `sprite_width`, `sprite_height`, `pivot_offset_x`, `pivot_offset_y` via config, and sets uniforms dynamically. Examples already pass correct sizes:
- Banner: 256x384
- Flag: 384x192
- Cape: 256x320

# NOT DOING
Move things here if we have decided against doing them