## Grafter Auto-Spawn Checklist

- [x] **Asset file** — `assets/grafter_no_space_bubble.png` — copy binary from `/root/wip/assets/grafter_no_space_bubble.png` into `/root/wip-3d/assets/`

- [x] **Asset registration** — `lua/game/assets.lua` — add `A.grafter_no_space_bubble = img("assets/grafter_no_space_bubble.png")` after the `A.grafter_loaded` line (line 33)

- [x] **Held-item ticks** — `lua/game/player.lua` — at the end of `Player:update(dt, input, store)` (before the closing `end` at line 92), add:
  ```lua
  if self.held_item and self.held_item.update then
      self.held_item:update(dt)
  end
  ```

- [x] **Grafter rewrite** — `lua/game/items/grafter.lua` — replace entire file with auto-spawn implementation: remove `self.loaded_plant` and `Grafter:unload()`; add `self.bubble`, `self._bubble_timer` to `new()`; add `Grafter:update(dt)` timer tick; rewrite `Grafter:interact()` to find nearest empty slot via flat-array index in `store:all_slots()` and place clone directly (or show bubble for 1.5 s); add `Grafter:draw_bubble()`; simplify `Grafter:draw()` to just draw `self.sprite`

- [x] **Store scene cleanup** — `lua/game/scenes/store_scene.lua` — four changes:
  1. `_handle_pick_up_down`: remove the "loaded grafter + empty slot → place clone" block (lines 225–230)
  2. `_handle_interact` garbage-bin discard: replace `if held.loaded_plant then held:unload() else player.held_item = nil end` with `player.held_item = nil`
  3. `_hud_labels` E-label: remove the `held.loaded_plant` / `"E: PLACE CLONE"` branch (lines 482–483)
  4. `_hud_labels` F-label Grafter condition: remove `and not held.loaded_plant` (line 507)
