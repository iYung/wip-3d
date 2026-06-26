## Goal

Adjust the plant "ready to water" bubble: move it lower on screen so it sits closer to the plant sprite, and make it slightly larger so it's more visible.

## Affected files

- `lua/game/items/plant.lua` — bubble sprite size and draw position

## What changes

1. **Bubble size** — increase from `6 * U` (120 px) to `7 * U` (140 px) in `Plant.new`.
2. **Bubble position** — in `Plant:draw_bubble`, shift the y-offset downward. Currently `active.y - self.bubble.height - 10`; change the trailing offset so the bubble overlaps the top of the plant slightly rather than floating well above it. Proposed: `active.y - self.bubble.height + 20`.

No asset regeneration needed — `plant_bubble.png` is a solid rect and LÖVE scales it at draw time via the sprite's width/height.

## What stays the same

- The bubble is still shown/hidden by the cooldown timer (no timing changes).
- Sound (`plant_ready`) is unchanged.
- All other bubble types (customer, heart, grafter) are unchanged.

## Open questions

None — user confirmed "lower" means move the bubble's position down on screen.
