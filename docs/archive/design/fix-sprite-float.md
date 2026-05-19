## Goal

Fix items (plant slots) and the customer billboard appearing to float above the floor in the first-person 3D store scene. Every sprite with `voffset=0` currently hovers 0.25 world-units above the floor because the vertical-center formula anchors sprites at the eye-level horizon rather than at the floor.

## Affected files

- `lua/core/raycaster.lua` — `draw_sprites` function, line ~146: the `y_center` formula
- `lua/game/scenes/store_scene.lua` — sprite table construction in `StoreScene:draw`, lines ~349–379: item bubble `voffset` value

## What changes

### 1. `lua/core/raycaster.lua` — fix the `y_center` formula

**Current formula (line ~146):**
```lua
local y_center = SH / 2 - voff * (SH / tz)
```
This centers every sprite at the horizon (`SH/2`), so a scale=1 sprite with `voffset=0` has its bottom at `SH/2 + 0.5 * SH/tz`. The actual floor in screen space at distance `tz` is at `SH/2 + (WALL_HEIGHT/2) * (SH/tz)` = `SH/2 + 0.75 * SH/tz`. The result is a 0.25 world-unit gap between the sprite bottom and the floor.

**New formula:**
```lua
local y_center = SH / 2 + (WALL_HEIGHT / 2 - sc / 2 - voff) * (SH / tz)
```
This re-anchors the default (`voffset=0`) so a scale=1 sprite's bottom lands exactly on the floor. The term `WALL_HEIGHT / 2 - sc / 2` shifts the center down by half the sprite's world-unit height relative to eye level.

`voffset` semantics change from "world-units above the horizon" to "world-units above the floor." A value of 0 means grounded; positive values lift the sprite toward and above the player's eye.

`WALL_HEIGHT` is already defined at the top of `draw_sprites` (value `1.5`). The formula uses the same constant so sprite and wall geometry stay consistent.

### 2. `lua/game/scenes/store_scene.lua` — update item bubble `voffset`

**Current value:** `voffset = 0.65` (old semantics: 0.65 world-units above the horizon, i.e., about 1.4 world-units above the floor)

**New value:** `voffset = 1.3` (new semantics: 1.3 world-units above the floor)

Reasoning: a scale=1 item spans 0 to 1.0 world-units in height. The item bubble (scale=0.45) has a half-height of 0.225 world-units, so its bottom at `voffset=1.3` sits at `1.3 - 0.225 = 1.075` world-units — just above the item's top and comfortably within the 1.5-world-unit wall height.

No change is needed to item or customer `voffset` entries because they have none (default 0), and the new formula already grounds them correctly.

## What stays the same

- Wall rendering logic in `draw_sprites` and the floor/ceiling renderer — those are not touched.
- The `WALL_HEIGHT` constant (1.5) and player implicit eye height (0.75).
- Sprite sorting, occlusion culling, and column-by-column rendering logic.
- All sprite `scale` values and the customer sprite setup/teardown callbacks.
- Item bubble `scale = 0.45` — only `voffset` changes.
- Any other scenes or sprite definitions that do not specify a `voffset` (they will benefit automatically from the grounding fix).

## Open questions

1. **Sprite scale vs. world-unit height**: The formula assumes `sc` (scale) equals the sprite's world-unit height. If any sprite intentionally uses a scale != its intended world height, the grounding will be off for that sprite alone. Verify that all current `scale` values reflect true world-unit heights.
2. **Ceiling clearance**: A tall sprite or a bubble with a large `voffset` could poke above the wall tops. After the fix, confirm that the customer and all item bubbles stay within the visible wall band at the camera distances used in the store scene.
3. **Look-angle / pitch compensation**: If vertical look-offset (camera pitch) is ever added to the engine, `SH/2` will shift and the `y_center` formula will need a corresponding pitch term. No action required now, but keep it in mind.
