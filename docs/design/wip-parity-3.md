## Goal

Bring `wip-3d` to full parity with `../wip` for the features that carried over from the 2D engine. Six concrete gaps were identified by diffing every changed file. Wall pattern shader is intentionally excluded (2D-only; raycaster handles wall rendering). Missing 2D-derived tests are deferred.

---

## Affected files

| File | Gap |
|------|-----|
| `lua/game/customer.lua` | Name prefix bug in `make_full_text` |
| `lua/game/data/customer_scripts.lua` | Missing `after_messages` on 10 character entries |
| `lua/game/scenes/settings_menu.lua` | Static bg image instead of alternating pattern animation |
| `lua/game/scenes/start_scene.lua` | Missing `MenuBg` shader integration |
| `lua/game/scenes/buy_scene.lua` | Missing `love.graphics.clear` before canvas draw |
| `lua/game/shaders/menu_bg.lua` | New file — shader wrapper (copy from wip) |
| `assets/shaders/menu_bg.glsl` | New file — GLSL source (copy from wip) |
| `assets/settings_pattern_1.png` | New asset — settings menu animated background frame 1 |
| `assets/settings_pattern_2.png` | New asset — settings menu animated background frame 2 |
| `assets/start_pattern.png` | New asset — start screen scrolling pattern |
| `assets/shades.png` | New accessory asset (used by The Collector) |
| `assets/clown.png` | New accessory asset (used by Dottie) |

---

## What changes

### 1 — Customer name prefix removed (`customer.lua`)
`make_full_text` currently returns `c.name .. ": " .. (c.messages[c.msg_index] or "")`. wip removed the prefix; speech bubbles show only the dialogue line. One-line change at line 43.

### 2 — Customer scripts copied verbatim (`customer_scripts.lua`)
The file is character-for-character identical to wip's except ten entries (Old Pete ×3, Mayor Bloom ×2, The Collector ×2, Mira ×1, Dottie ×3) are missing `after_messages` blocks. Copy `customer_scripts.lua` verbatim from wip rather than patching individual entries.

### 3 — Settings menu animated background (`settings_menu.lua`)
wip-3d loads a single `settings_background.png`. wip loads two images (`settings_pattern_1.png`, `settings_pattern_2.png`) and alternates them every second via a `_bg_timer` / `_bg_frame` counter. Copy the two pattern PNGs from wip and update `settings_menu.lua` to load both images and toggle between them in `update`.

### 4 — Menu background shader on start screen (`start_scene.lua` + new shader files)
wip animates `start_bg.png`'s pure-red pixels with a scrolling tiled pattern using `menu_bg.glsl`. wip-3d's `start_scene.lua` doesn't load the shader at all. Copy:
- `assets/shaders/menu_bg.glsl` from wip
- `lua/game/shaders/menu_bg.lua` from wip
- `assets/start_pattern.png` from wip (graceful disable when absent already handled by the shader wrapper)

Then wire into `start_scene.lua`: require `MenuBg`, track `_time`, apply/clear in draw.

### 5 — buy_scene canvas clear bug (`buy_scene.lua`)
`love.graphics.clear(0, 0, 0, 1)` is called right after `love.graphics.setCanvas(self.canvas)` in wip, ensuring no stale pixels from the prior frame bleed through. wip-3d omits this call. Add it back.

### 6 — Missing accessory assets (`assets/accessories/`)
`shades.png` (used by The Collector ch1+ch2) and `clown.png` (used by Dottie ch1–3) are in `wip/assets/` but not in `wip-3d/assets/accessories/`. Copy them to `assets/accessories/` (wip-3d's convention; `load_accessory` already looks there).

---

## What stays the same

- All 3D rendering, raycasting, `store_scene.lua`, `player_3d.lua`, `map.lua` — untouched
- `headless/runner.lua` and `headless/input.lua` — already adapted for 3D
- `settings_state.lua` — identical; no changes needed
- `sound.lua` — identical; no changes needed
- `assets.lua` — no changes needed (wall_pattern loading skipped; accessories path `assets/accessories/` kept)
- Existing tests — no changes

---

## Open questions

None — wall shader and deferred tests resolved before design was written.
