## Fix Sprite Float Checklist

- [x] Task A — `lua/core/raycaster.lua` — Replace the `y_center` formula at line ~146 in `draw_sprites`. Change `local y_center = SH / 2 - voff * (SH / tz)` to `local y_center = SH / 2 + (WALL_HEIGHT / 2 - sc / 2 - voff) * (SH / tz)`. This re-anchors the sprite so a scale=1 sprite with `voffset=0` has its bottom sitting exactly on the floor instead of floating 0.25 world-units above it. `WALL_HEIGHT` (1.5) is already defined at the top of the function.

- [x] Task B — `lua/game/scenes/store_scene.lua` — Update the item bubble `voffset` in `StoreScene:draw` at line ~363. Change `voffset = 0.65` to `voffset = 1.3`. Under the new formula semantics, `voffset` is now world-units above the floor rather than above the horizon; 1.3 places the bubble's bottom at ~1.075 world-units, just above a scale=1 item top and within the 1.5-unit wall height.
