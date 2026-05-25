# wip → wip-3d Parity Gap

Features that exist in `wip` (2D) but are missing or diverged in `wip-3d`.
Last audited: 2026-05-22.

---

## Summary

| # | Feature | Type | Priority |
|---|---------|------|----------|
| 1 | Grafter auto-spawn | Behavior | High |
| 2 | Held item ticks while carried | Behavior | High |
| 3 | UTF-8 safe typewriter | Bug fix | High |
| 4 | CRT shader on buy scene | Visual | Medium |
| 5 | Sway shader on slot items | Visual | Low |
| 6 | Wall pattern shader | Visual | N/A (arch diff) |
| 7 | Accessory PNG assets | Assets | Medium |
| 8 | `expand_slot.png` asset | Assets | Low |

---

## Detailed Descriptions

### 1. Grafter Auto-Spawn

**Status:** Done — ported to wip-3d.

In `wip`, the grafter was redesigned (grafter-auto-spawn feature) to automatically place the clone into the nearest empty slot when `F` is pressed. If no slot is empty it shows a "no space" bubble for 1.5 seconds. The player never needs to manually carry and place the clone.

`wip-3d` still uses the old approach: grafting loads a `plant` into `self.loaded_plant`, and the player must then walk to an empty slot and press `E` to place it.

**Files affected:**
- `lua/game/items/grafter.lua` — needs full rewrite to auto-spawn logic
- `lua/game/assets.lua` — missing `A.grafter_no_space_bubble`
- `lua/game/player.lua` — `Player:update` must call `held_item:update(dt)` (see #2)
- `lua/game/scenes/store_scene.lua` — remove loaded-grafter `E: PLACE CLONE` HUD branch; simplify garbage-bin discard to always `player.held_item = nil`

**Missing asset:** `assets/grafter_no_space_bubble.png`

---

### 2. Held Item Ticks While Carried

**Status:** Done — `Player:update` now calls `held_item:update(dt)`.

`wip` added this at the bottom of `Player:update(dt, input, store)`:

```lua
if self.held_item and self.held_item.update then
    self.held_item:update(dt)
end
```

Without this, any carriable item with time-based state (e.g. the grafter's no-space bubble timer) freezes while held. Required by #1.

**Files affected:**
- `lua/game/player.lua` — add held-item update call at end of `Player:update`

---

### 3. UTF-8 Safe Typewriter

**Status:** Done — ported to wip-3d.

`wip`'s `customer.lua` clamps `reveal_index` to a valid UTF-8 character boundary before passing it to `string.sub`, preventing corrupted output mid-reveal on any multi-byte character in dialog text.

wip-3d `customer.lua:270` does a plain `string.sub(self._full_text, 1, self.reveal_index)` with no boundary check.

**wip fix (lines 270–281 of wip's customer.lua):**
```lua
local idx = self.reveal_index
while idx > 0 and (string.byte(self._full_text, idx) or 0) >= 0x80
              and (string.byte(self._full_text, idx) or 0) <  0xC0 do
    idx = idx - 1
end
if (string.byte(self._full_text, idx) or 0) >= 0xC0 then
    idx = idx - 1
end
local revealed = string.sub(self._full_text, 1, idx)
```

**Files affected:**
- `lua/game/customer.lua` — replace raw `string.sub` with UTF-8 safe version

---

### 4. CRT Shader on Buy Scene

**Status:** Done — ported to wip-3d.

`wip` renders the entire buy scene to a `love.graphics.Canvas`, then draws that canvas through `lua/game/shaders/crt.lua` which applies:
- Barrel distortion
- Chromatic aberration
- Scanlines
- Vignette

`wip-3d`'s `buy_scene.lua` uses `require("lua/core/scene_2d")` instead of `require("lua/core/scene")`, skips the canvas setup, and calls no CRT shader.

**Files missing from wip-3d:**
- `lua/game/shaders/crt.lua`
- `assets/shaders/crt.glsl`

**Files affected to update:**
- `lua/game/scenes/buy_scene.lua` — add canvas init, wrap draw in canvas + CRT apply/clear

---

### 5. Sway Shader on Slot Items

**Status:** Missing — wip-3d billboards don't sway.

`wip` applies a sway shader to any slot item where `item.ready ~= true` (i.e. still growing). This is done in `Slot:draw(sway_time)` using constants:
```
ITEM_SWAY_AMPLITUDE = 0.012
ITEM_SWAY_SPEED     = 2.5
```

`wip-3d` renders items as flat raycaster billboards; the sway shader files don't exist in the repo. Sway on parallax background layers (also from wip) is not applicable since 3D has no parallax.

**Files missing from wip-3d:**
- `lua/game/shaders/sway.lua`
- `assets/shaders/sway.glsl`

**Adaptation note:** Billboard items are drawn via `raycaster:draw_sprites`. To apply sway here would require passing shader state into the raycaster draw path, which is a non-trivial change. May be deferred or implemented differently for 3D.

---

### 6. Wall Pattern Shader

**Status:** Intentional architecture difference — probably N/A.

`wip` tiles `assets/wall_pattern.png` over the store and cashier wall images using a GLSL shader that detects red pixels in the wall sprite and replaces them with the tiled pattern.

`wip-3d` renders walls via the raycaster using `A.store_wall` as a column texture. Wall appearance is controlled by the raycaster's texture mapping, not a 2D shader.

**Files missing from wip-3d (informational only):**
- `lua/game/shaders/wall_pattern.lua`
- `assets/shaders/wall_pattern.glsl`
- `assets/wall_pattern.png`

**Recommendation:** Skip unless a pattern effect is desired on raycaster wall columns (would require a different approach).

---

### 7. Accessory PNG Assets

**Status:** Missing assets — code path is already present.

`wip` ships 6 accessories under `assets/accessories/`. `wip-3d` only has `flat_cap.png`. The `customer.lua` code for loading and rendering accessories is **identical** in both repos; missing files silently return `false` from `A.load_accessory()`, so customers with those accessories just render without them.

**Missing from `wip-3d/assets/accessories/`:**
- `chain_of_office.png`
- `flower_pin.png`
- `hair_bow.png`
- `straw_hat.png`
- `wide_brim_hat.png`

**Fix:** Copy from `wip/assets/accessories/`.

---

### 8. `expand_slot.png` Asset

**Status:** Missing asset — referenced via `try_img` so silently nil.

Both repos' `buy_scene.lua` use `A.expand_slot` as the image for the "expand slot" shop item. The file exists in `wip/assets/` but not in `wip-3d/assets/`. The `try_img` wrapper suppresses the error, but the expand-slot button renders without an image in wip-3d.

**Fix:** Copy `assets/expand_slot.png` from `wip`.

---

## Checklist

### Behavior

- [x] **Grafter auto-spawn** — rewrite `lua/game/items/grafter.lua`: remove `loaded_plant`/`unload()`, add auto-place-to-nearest-slot logic, add `self.bubble` + `_bubble_timer`, add `Grafter:update(dt)`, add `Grafter:draw_bubble()`
- [x] **Grafter auto-spawn** — add `A.grafter_no_space_bubble` to `lua/game/assets.lua`, add asset file `assets/grafter_no_space_bubble.png`
- [x] **Grafter auto-spawn** — update `lua/game/scenes/store_scene.lua`: remove `"E: PLACE CLONE"` HUD branch from `_hud_labels`, remove loaded-grafter branch from `_handle_pick_up_down`, simplify garbage-bin discard in `_handle_interact`
- [x] **Held item ticks** — add `held_item:update(dt)` call at end of `Player:update` in `lua/game/player.lua`
- [x] **UTF-8 typewriter** — replace raw `string.sub` with UTF-8 safe version in `lua/game/customer.lua`

### Visual / Shaders

- [x] **CRT shader** — copy `lua/game/shaders/crt.lua` and `assets/shaders/crt.glsl` from wip
- [x] **CRT shader** — add canvas init + CRT apply/clear to `lua/game/scenes/buy_scene.lua`
- [ ] **Sway shader** — copy `lua/game/shaders/sway.lua` and `assets/shaders/sway.glsl` from wip (prerequisite for billboard sway if desired)

### Assets

- [ ] **Accessories** — copy `chain_of_office.png`, `flower_pin.png`, `hair_bow.png`, `straw_hat.png`, `wide_brim_hat.png` into `wip-3d/assets/accessories/`
- [ ] **expand_slot.png** — copy `assets/expand_slot.png` from wip
