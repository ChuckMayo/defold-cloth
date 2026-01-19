# Cloth Shader Debug Status

## Status: ALL TODOs COMPLETE ✓

## Completed

### TODO #11: Cape vertex displacement for dramatic draping - ENHANCED
**Problem**: Cape felt too rigid when dragged and when gusting.

**Fixes**:
1. Increased velocity amplitude in mesh shader (125→200)
2. Updated cape preset: enabled gusts, reduced damping (0.88→0.85), increased input_force (0.05→0.08)
3. Increased material wave amplitude (25→40) and edge influence (0.2→0.3)

### TODO #10: Flag vertex displacement dramatically increased - ENHANCED
**Problem**: Flag only sagged slightly when it should collapse completely (except anchor side).

**Fix**: Increased gravity sag multiplier from 30 to 120 in `cloth_mesh.vp` for dramatic collapse effect.

### TODO #9: Mesh animation direction and enhanced cloth effects - FIXED

**Fixes**:
1. Fixed mesh cape animation (was moving top instead of bottom) - corrected UV distance calculation
2. Removed distance threshold for more dramatic vertex displacement
3. Added gravity sag for horizontal flags when gust is low
4. Enhanced fragment wobble: 4x stronger, more frequencies, 30% base wobble across cloth

### TODO #8: Multi-page UI - COMPLETE

**Implementation**:
- Created navigation GUI with arrows, title, description, page indicator
- 3 pages: Banner (sprite), Cape (sprite + mesh), Flag (sprite + mesh horizontal)
- Objects show/hide based on current page

### TODO #7: Cape mesh upside down and flag mesh resource conflict - FIXED

**Fixes**:
1. Flipped UV V-coordinates in MeshGenerator for OpenGL convention
2. Added resource counter for unique buffer paths per mesh instance

### TODO #6: Add flag pole - COMPLETE

**Implementation**: Added pole sprite component to flag.go using scaled banner texture positioned to left of flag.

### TODO #5: Add edge wobble along Y axis - COMPLETE

**Implementation**: Enhanced fragment shader with Y-axis wobble at 50% intensity of X-axis wobble. Uses offset phase for organic movement.

### TODO #4: Replace cape/flag with meshes - COMPLETE

**Implementation**:
- Created `MeshGenerator` module for runtime grid mesh generation
- Created mesh-compatible vertex shader and material
- Added `cape_mesh` (6x8 grid) and `flag_mesh` (10x5 grid) examples
- Mesh examples added to main.collection

### TODO #3: Z-fighting with overlapping sprites - FIXED

**Root Cause**: Not a shader issue. Defold's default render script uses orthographic projection with near=-1, far=1 z-clipping planes. The original example had z values outside this range (cape at z=3.0 was clipped entirely).

**Fix**: Updated example collection to use z values within valid range (0.1, 0.2, 0.3).

**Note**: Users should keep z values between -1 and 1, or create a custom render script for wider z-range.

### TODO #1: Banner/cape shrink-expand when dragged - FIXED

**Root Cause**: Depth push calculation mixing displaced xy with modified z caused projection artifacts.

**Fix**: Removed depth push entirely: `gl_Position = displaced_clip;`

### TODO #2: Flag orientation (hung from left instead of top) - FIXED

**Solution**: Added `orientation` parameter to shader and ClothAnimator:
- `orientation = 0.0` → Vertical (hung from top) - for banners, capes
- `orientation = 1.0` → Horizontal (hung from left) - for flags

**Changes**:
- `cloth.vp`: Added orientation-aware displacement logic using `mix()` to swap axes
- `cloth_sprite.material`: Default `cloth_params.z = 0.0` (vertical)
- `cloth_animator.lua`: Added `orientation` config option, flag preset uses `orientation = 1.0`

## Files Modified
- `/cloth/materials/cloth.vp` - Removed depth push, added orientation support
- `/cloth/materials/cloth_sprite.material` - Set default orientation to 0 (vertical)
- `/cloth/cloth_animator.lua` - Added orientation config, updated flag preset
