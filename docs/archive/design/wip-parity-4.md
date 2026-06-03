## Goal

Bring `wip-3d` to full parity with `../wip` for the four features merged into wip since parity-3: start-screen sub-logo, talking_after HUD labels, scene fade transition, and the Marketing (customer cooldown) upgrade. All four are pure game-logic or 2D-overlay features with no raycaster dependency.

---

## Affected files

| File | Gap |
|------|-----|
| `lua/game/scenes/start_scene.lua` | Missing sub-logo image and tagline text; `BTN_Y0` not shifted |
| `assets/sub_logo.png` | New asset — sub-logo below main title |
| `lua/game/scenes/store_scene.lua` | `_hud_labels()` skips F-label during `talking_after`; no Marketing spawn logic |
| `lua/core/scene_manager.lua` | No fade-to-black transition between scenes |
| `lua/game/config.lua` | Missing `LOGICAL_W` and `LOGICAL_H` constants |
| `lua/game/game_state.lua` | Missing `cooldown_level` field |
| `lua/game/data/cooldown_tiers.lua` | New file — 3 Marketing upgrade tiers |
| `lua/game/assets.lua` | Missing `A.ads` table for Marketing preview icons |
| `lua/game/scenes/buy_scene.lua` | Missing Marketing catalogue entry, purchase and draw logic |
| `tests/test_scene_manager.lua` | New test — copy from wip |
| `tests/test_shop.lua` | New test — Marketing upgrade cases |
| `tests/test_start_scene.lua` | New test — copy from wip |

---

## What changes

### 1 — Start screen sub-logo + tagline (`start_scene.lua`, `assets/sub_logo.png`)

wip's `on_enter()` loads `sub_logo.png` into `self._img_sub_logo` and a 16px mono font into `self._font_tagline`. The `draw()` positions sub_logo immediately below the main logo (y = logo_y + logo_height + 8, horizontally centered), then draws the tagline string `"grows plants with increasing speed and quantity for profit"` centred over the sub_logo with a 1px black drop shadow (offset `+1` in x). `BTN_Y0` shifts from 290 → 360 to make room.

Copy `assets/sub_logo.png` from `../wip/assets/sub_logo.png`.

### 2 — HUD labels during talking_after (`store_scene.lua`)

`_hud_labels()` currently falls through to `self._customer:arrived()` (which returns true only for `"waiting"` state), so no F-label shows during `talking_after`. Add an explicit guard at the top of the F-label block: when `in_cash` and `self._customer.state == "talking_after"`, show `"F: SKIP"` if the line is still revealing or `"F: CONTINUE"` when complete. The existing `arrived()` branch follows as `elseif`.

`in_cash` in wip-3d is the 3D-adapted equivalent of wip's `player.x < 0` check (`p.y <= CASHIER_THRESH and not self._cust_anim`), so the new guard uses `in_cash` rather than duplicating the coordinate logic.

### 3 — Fade-to-black scene transition (`scene_manager.lua`, `config.lua`)

Copy wip's `scene_manager.lua` fade implementation:
- `_prev`, `_fade_state` (`"idle"/"out"/"in"`), `_fade_alpha` added to state
- First `switch()` (current is nil) is immediate, no fade
- Subsequent `switch()`: call new scene's `on_enter()` immediately, hold old scene in `_prev`, start `"out"` fade
- `update()`: advance `_fade_alpha` by `dt / FADE_DURATION` (0.3 s); when fully black call `_prev:on_exit()` and clear `_prev`, flip to `"in"`; when fully clear go `"idle"`
- `draw()`: during `"out"` draw `_prev`, otherwise draw `current`; overlay black rectangle at `_fade_alpha` opacity

Add `LOGICAL_W = 1280` and `LOGICAL_H = 720` to `config.lua`; scene_manager requires config to draw the overlay rectangle.

### 4 — Marketing upgrade — customer cooldown (`cooldown_tiers.lua`, `game_state.lua`, `assets.lua`, `buy_scene.lua`, `store_scene.lua`)

**New file** `lua/game/data/cooldown_tiers.lua` — copy verbatim from wip:
```lua
return {
    { cost = 10, cooldown = 3, label = "Customers come faster" },
    { cost = 25, cooldown = 2, label = "Customers come even faster" },
    { cost = 50, cooldown = 0, label = "Customers come even even faster" },
}
```

**`game_state.lua`**: add `self.cooldown_level = 0` alongside `speed_level` and `growth_level`.

**`assets.lua`**: add `A.ads = {}` with a `try_img` loop for `assets/ads_1.png` through `ads_3.png` (graceful-disable; no ad PNGs in repo yet).

**`buy_scene.lua`**: append Marketing entry to CATALOGUE (`kind = "customer_cooldown"`, label `"Marketing"`, description `"More customers, faster!"`). Add purchase branch in `_confirm()`: guard on `cooldown_level >= #COOLDOWN_TIERS` and insufficient currency; deduct `tier.cost`, increment `cooldown_level`. Add display branch in `draw()`: shows current tier cost + label, or `"---"` / `"Max ads reached."` when maxed. Preview shows `A.ads[cooldown_level + 1]` icon if present.

**`store_scene.lua`**: add local `spawn_cooldown(gs)` returning `COOLDOWN_TIERS[gs.cooldown_level].cooldown` when level > 0, else 4. Update spawn block:
- `_spawn_timer` initialized with `spawn_cooldown(gs)` instead of `math.random(3, 6)`
- Inside the `not active and not _cust_anim` guard: if `spawn_cooldown == 0`, spawn immediately each frame when a script is available; otherwise fall through to the existing timer path (reset to `spawn_cooldown(gs)` instead of `math.random(3, 6)`)

---

## What stays the same

- All 3D rendering, raycasting, `store_scene.lua` 3D movement, map, player
- `customer.lua`, `customer_scripts.lua` — no changes
- `sound.lua`, `settings_state.lua`, `settings_menu.lua` — no changes
- `assets.lua` other than the `A.ads` addition
- All existing tests — no changes

---

## Tests to add

| File | Source | Notes |
|------|--------|-------|
| `tests/test_scene_manager.lua` | Copy verbatim from wip | Tests fade state machine; no LOVE graphics calls |
| `tests/test_start_scene.lua` | Copy verbatim from wip | Navigation-only; `on_enter()` never called in test |
| `tests/test_shop.lua` | Copy marketing section from wip | `buy.selected = 12` is correct for both repos (same catalogue order) |

### Test safety notes

**test_scene_manager.lua**: Uses mock scenes with no-op `update`/`draw`. Calls `sm:update(dt)` with large dt values (1.0) to complete fades in one tick. No loops that can hang.

**test_shop.lua**: `runner.setup()` switches to StoreScene as a first-load (immediate, no fade). Test then creates a `BuyScene` directly and calls `_confirm()` without using `runner.tick()`. Purchasing a plant calls `sm:switch(store_scene)` which triggers a self-switch (StoreScene → same StoreScene); this starts a fade that never progresses since no `runner.tick()` calls follow — harmless. Marketing `_confirm()` does not switch scenes at all.

`make_buy` must pass `ctx.sm.current` as the 4th arg (matches wip):
```lua
local function make_buy(ctx)
    return BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
end
```

**test_start_scene.lua**: Creates `StartScene` instances via `new()`. In wip-3d, `new()` guards the pattern load behind `love.filesystem.getInfo` (returns nil in headless → skipped). No hang.

**Existing test_golden_lotus.lua with fade transition**: After BuyScene confirms and switches back to StoreScene, `StoreScene:on_enter()` is called a second time. The `_initialized` guard prevents `_setup_store()` from running again, so customer state, spawn timer, and player are preserved. The fade (0.3s) completes within the `face_slot` navigation ticks that follow. No hang.

---

## Open questions

None.
