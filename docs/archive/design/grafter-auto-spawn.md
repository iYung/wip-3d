# Grafter Auto-Spawn — Design Doc

## Goal

Port the grafter auto-spawn behavior from `wip` (2D) to `wip-3d` (3D). When the player presses `F` while holding the grafter over a stage-3 plant, the clone is automatically placed into the nearest empty slot. If no empty slot exists, a "no space" bubble appears for 1.5 seconds. The player no longer manually carries and places the clone.

## Affected files

- `lua/game/items/grafter.lua` — full rewrite
- `lua/game/assets.lua` — add `A.grafter_no_space_bubble`
- `assets/grafter_no_space_bubble.png` — copy from wip
- `lua/game/player.lua` — add `held_item:update(dt)` call
- `lua/game/scenes/store_scene.lua` — remove loaded-grafter branches, simplify garbage discard

## What changes

### `lua/game/items/grafter.lua`
- Remove `self.loaded_plant` and `Grafter:unload()`
- Add `self.bubble` (Sprite), `self._bubble_timer` (number) to `Grafter.new()`
- Add `Grafter:update(dt)` — ticks down `_bubble_timer`, hides bubble when it expires
- Rewrite `Grafter:interact()` — finds nearest empty slot in `store:all_slots()` by flat-array index distance from the player's current slot; places clone directly or shows no-space bubble
- Add `Grafter:draw_bubble()` — positions and draws bubble above sprite
- Simplify `Grafter:draw()` — remove loaded-plant rendering

**Nearest-slot adaptation:** wip uses `slot.index` (linear). wip-3d slots have no `index` field; instead use the position in `store:all_slots()` flat array (row-major) as a proxy. This preserves the same proximity semantics for single-row stores and is a reasonable approximation for multi-row.

### `lua/game/assets.lua`
- Add `A.grafter_no_space_bubble = img("assets/grafter_no_space_bubble.png")` alongside the other grafter entries
- Remove `A.grafter_loaded` (no longer needed once grafter never holds a plant)

Wait — `A.grafter_loaded` is still referenced in the old grafter. After the rewrite, `grafter.lua` no longer references `A.grafter_loaded`. Leave it in `assets.lua` for now; removal is a separate cleanup.

Actually: just add `A.grafter_no_space_bubble`. Do not remove `A.grafter_loaded` — unused asset references are harmless and out of scope.

### `assets/grafter_no_space_bubble.png`
- Copy binary from `/root/wip/assets/grafter_no_space_bubble.png`

### `lua/game/player.lua`
- At the end of `Player:update(dt, input, store)`, add:
  ```lua
  if self.held_item and self.held_item.update then
      self.held_item:update(dt)
  end
  ```

### `lua/game/scenes/store_scene.lua`
Three targeted removals/simplifications:

1. **`_handle_pick_up_down`** — remove the entire "loaded grafter + empty slot → place clone" block (currently lines 225–230).

2. **`_handle_interact` garbage-bin discard** — replace `if held.loaded_plant then held:unload() else player.held_item = nil end` with simply `player.held_item = nil`.

3. **`_hud_labels` E-label** — remove the `"E: PLACE CLONE"` branch (`held.loaded_plant` check).

4. **`_hud_labels` F-label** — remove `and not held.loaded_plant` from the Grafter CLONE condition (always true now, clean it up).

## What stays the same

- `Grafter:interact` still checks `player.held_item ~= self`, `slot.item.plant_type`, and `slot.item.stage < 3` before acting
- Plant reset logic (stage → 1, cooldown reset, bubble hide, sprite set "1") is unchanged
- Grafter is still carriable; pick-up / put-down behavior unchanged
- `A.grafter_empty` still used; `A.grafter_loaded` left in assets (unused but harmless)
- All other HUD labels unaffected

## Open questions

None — wip implementation is the authoritative reference. The only adaptation (flat-array index for nearest-slot) is noted above.
