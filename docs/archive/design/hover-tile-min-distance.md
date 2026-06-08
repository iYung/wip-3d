# Design: Hover Tile Minimum Distance

## Goal

The hovered tile highlights too close to the player. Increase the minimum ray distance so the nearest hoverable tile is pushed back from 0.5 to 1.0 grid units.

## Affected files

- `lua/game/scenes/store_scene.lua` — `HOVER_MIN_T` constant (line 79)

## What changes

- `HOVER_MIN_T` increases from `0.5` to `1.0`
- Tiles between 0.5 and 1.0 grid units from the player will no longer highlight; the nearest selectable tile will be 1.0 units ahead

## What stays the same

- `INTERACT_RANGE` (3.0) is unchanged — max hover distance is the same
- All raycasting logic, floor shader, and hover detection logic are unchanged
- Visual highlight color and behavior are unchanged

## Open questions

None — user confirmed 1.0 grid units.
