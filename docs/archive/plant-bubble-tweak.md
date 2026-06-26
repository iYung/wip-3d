## Plant Bubble Tweak Checklist

- [x] Task A — `lua/game/items/plant.lua` — Change bubble sprite size from `6 * U` to `7 * U` (both width and height) in `Plant.new`, and shift the y draw position in `Plant:draw_bubble` from `active.y - self.bubble.height - 10` to `active.y - self.bubble.height + 20`
