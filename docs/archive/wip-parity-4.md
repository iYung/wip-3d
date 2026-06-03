## wip-parity-4 Checklist

- [x] Task A — `assets/sub_logo.png` — Copy `../wip/assets/sub_logo.png` to `assets/sub_logo.png`

- [x] Task B — `lua/game/scenes/start_scene.lua` — Add sub-logo and tagline to start screen: (1) change `BTN_Y0` from `290` to `360`; (2) in `on_enter()` add `self._font_tagline = love.graphics.newFont(16, "mono")` and `self._img_sub_logo = love.graphics.newImage("assets/sub_logo.png")`; (3) in `draw()` after drawing the main logo, draw `self._img_sub_logo` centred horizontally at `sub_y = logo_y + logo:getHeight() + 8`, then draw the tagline `"grows plants with increasing speed and quantity for profit"` with a 1px black drop shadow (print at `sub_x`, then `sub_x+1`, same y, width = sub_logo width, centered) in white over black

- [x] Task C — `lua/game/scenes/store_scene.lua` — Fix `_hud_labels()` to show F-labels during `talking_after`: in the F-label block (around line 589), add a new first branch `if in_cash and self._customer and self._customer.state == "talking_after" then` that sets `f_label = "F: SKIP"` when `not self._customer:line_complete()` else `f_label = "F: CONTINUE"`; change the existing `if in_cash and self._customer:arrived()` to `elseif`

- [x] Task D — `lua/game/config.lua` — Add `LOGICAL_W = 1280` and `LOGICAL_H = 720` to the returned table (needed by the scene_manager overlay and to match wip's config)

- [x] Task E — `lua/core/scene_manager.lua` — Replace the current immediate-switch implementation with the fade-to-black version copied from `../wip/lua/core/scene_manager.lua`: add `require("lua/game/config")`, `FADE_DURATION = 0.3`, `_prev/_fade_state/_fade_alpha` fields, first-load fast-path in `switch()`, deferred `on_exit()` in `update()`, overlay rectangle in `draw()` using `config.LOGICAL_W`/`LOGICAL_H`

- [x] Task F — `lua/game/data/cooldown_tiers.lua` — Create new file copied verbatim from `../wip/lua/game/data/cooldown_tiers.lua` (3 tiers: cost 10/25/50, cooldown 3/2/0)

- [x] Task G — `lua/game/game_state.lua` — Add `self.cooldown_level = 0` on the line after `self.growth_level = 0`

- [x] Task H — `lua/game/assets.lua` — Add `A.ads = {}` table with a `try_img` loop for `ads_1.png` through `ads_3.png`, copied from `../wip/lua/game/assets.lua` (placed after the `A.heat_lamps` loop)

- [x] Task I — `lua/game/scenes/buy_scene.lua` — Add Marketing upgrade: (1) `require("lua/game/data/cooldown_tiers")` at the top with other tier requires; (2) append Marketing catalogue entry after Heat Lamps (`kind = "customer_cooldown"`, label `"Marketing"`, description `"More customers, faster!"`); (3) add `customer_cooldown` purchase branch in `_confirm()` mirroring the growth_boost pattern; (4) add `customer_cooldown` display branch in `draw()` for cost/desc/maxed text; (5) add `customer_cooldown` icon draw branch in `draw()` using `A.ads[cooldown_level + 1]`

- [x] Task J — `lua/game/scenes/store_scene.lua` — Add Marketing spawn logic: (1) add `require("lua/game/data/cooldown_tiers")` at top; (2) add local `spawn_cooldown(gs)` function before the `StoreScene` table (returns 4 when `cooldown_level == 0`, else `COOLDOWN_TIERS[gs.cooldown_level].cooldown`); (3) in `_setup_store()` change `Timer.new(math.random(3, 6))` to `Timer.new(spawn_cooldown(gs))`; (4) in `update()` spawn block, add `if cd == 0 then` fast-path before the timer check, and change the timer reset from `math.random(3, 6)` to `spawn_cooldown(gs)`

- [x] Task K — `tests/test_scene_manager.lua` — Create new file copied verbatim from `../wip/tests/test_scene_manager.lua`

- [x] Task L — `tests/test_start_scene.lua` — Create new file copied verbatim from `../wip/tests/test_start_scene.lua`

- [x] Task M — `tests/test_shop.lua` — Create new file copied verbatim from `../wip/tests/test_shop.lua`; confirm `make_buy` passes `ctx.sm.current` as 4th arg and `buy.selected = 12` for the Marketing entry
