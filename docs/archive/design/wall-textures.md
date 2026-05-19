## Goal

Make the 3D raycaster walls appear taller, and apply the existing `store_wall.png` art asset as a wall texture instead of the current flat-shaded solid color.

## Affected files

- `lua/core/raycaster.lua` — wall height multiplier + textured column draw
- `lua/game/scenes/store_scene.lua` — pass texture table to `raycaster:draw()`

## What changes

**Wall height**
The current projection is `h = SH / perp`. A `WALL_HEIGHT` multiplier (constant, default `1.5`) is introduced: `h = SH * WALL_HEIGHT / perp`. Walls grow taller; the ceiling/floor colored bands shrink proportionally. The floor shader and sprite system are unaffected.

**Textured walls**
`Raycaster:draw()` gains an optional sixth argument `wall_textures`: a table mapping map cell integer values to Love2D image objects (e.g., `{[1] = A.store_wall}`).

When a ray hits a wall cell that has a texture entry:
1. Compute the fractional hit position on the wall face (`hit_x`, 0–1) from the ray position and side.
2. Map `hit_x` to a pixel column index in the texture image.
3. Draw a 1-pixel-wide vertical strip of the texture, scaled to the computed wall height `h`.
4. Apply brightness shading (`br = 0.8` for X-facing, `0.5` for Y-facing) as a color tint.

When no texture entry exists the current solid-color line fallback is kept.

**Quad caching**
`love.graphics.newQuad` allocations are expensive in a 1280-column hot loop. Quads are pre-computed on first use per texture and stored in `self._quad_cache` (texture object → array of quads indexed by texel column). Subsequent frames reuse the cached quads.

`StoreScene:draw()` passes `{[1] = A.store_wall}` to `raycaster:draw()`. All map cells are currently value `1`, so every wall surface gets the store_wall texture.

## What stays the same

- DDA ray loop, z-buffer, sprite billboards, floor shader — no changes.
- Map grid format and cell values — no changes.
- All other scenes and 2D code — unaffected.
- The `hover_tile` parameter position is unchanged; `wall_textures` is appended as a new sixth argument with `nil` default (backward-compatible).

## Open questions

- Should `WALL_HEIGHT` be `1.5` or `2.0`? Starting at `1.5`; easy to tune.
- Should the cashier side of the divider wall (`col 7` of the map) use `cashier_wall.png`? That image has alpha transparency which requires continuing rays past the hit — skipping for this pass, use uniform `store_wall` everywhere.
