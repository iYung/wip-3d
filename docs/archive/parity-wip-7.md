## Parity Wip 7 Checklist

- [x] Task 1 — `lua/game/data/customer_scripts.lua` — Replace the 517-line file verbatim with the 871-line version from `../wip/lua/game/data/customer_scripts.lua`. This adds chef_brio ch1-4, dj_frogga ch1-2, wallace ch1-3, mayor_bloom ch4, mechafrog ch4, dottie ch4, agent_frogsby ch4, sage ch5, romeo ch4, glen ch4, and updates existing dialogue and trigger conditions (The Collector accessory `"anon"`, mayor_bloom ch1 trigger, etc.).

- [x] Task 2 — `lua/game/data/plant_data.lua` — Replace verbatim with `../wip/lua/game/data/plant_data.lua`. Updates all 6 plant sell prices, costs, cooldowns, and descriptions to match the rebalanced late-game economy (e.g. Grass: sell $3/cost $0, Rose: sell $20/cost $20, Golden Lotus: sell $400/cost $700 with cooldowns {30,60}).

- [x] Task 3 — `lua/game/data/growth_tiers.lua` — Replace verbatim with `../wip/lua/game/data/growth_tiers.lua`. Expands from 3 tiers to 6: `{ {cost=20,mult=1.25}, {cost=50,mult=1.60}, {cost=100,mult=1.95}, {cost=200,mult=2.30}, {cost=350,mult=2.65}, {cost=500,mult=3.00} }`.

- [x] Task 4 — `lua/game/game_state.lua` — In `GameState.new()`, add `self.play_time = 0` and `self.first_idol_at = nil` after `self.has_drone = false`. These fields are required by `store_scene`, `buy_scene`, and `win_scene`.

- [x] Task 5 — `lua/game/items/golden_idol.lua` — Create new file. The 3D version uses `self.sprite = { image = A.golden_idol }` (plain table, no `Sprite.new`) since `item_image()` in `store_scene` reads `.image` directly. No `U` import needed. Full content:
    ```lua
    local Item = require("lua/game/items/item")
    local A    = require("lua/game/assets")

    local GoldenIdol = setmetatable({}, { __index = Item })
    GoldenIdol.__index = GoldenIdol

    function GoldenIdol.new()
        local self             = Item.new()
        setmetatable(self, GoldenIdol)
        self.sprite            = { image = A.golden_idol }
        self.carriable         = true
        self.name              = "Golden Idol"
        self.win_scene_factory = nil
        return self
    end

    function GoldenIdol:interact(player, store, scene_manager)
        if self.win_scene_factory then
            scene_manager:switch(self.win_scene_factory())
        end
    end

    return GoldenIdol
    ```

- [x] Task 6 — `assets/golden_idol.png`, `assets/win_scene.png`, `assets/coin.png` — Copy from `../wip/assets/images/golden_idol.png`, `../wip/assets/images/win_scene.png`, `../wip/assets/images/coin.png` into `assets/` (wip-3d stores images flat in `assets/`, not in `assets/images/`).

- [x] Task 7 — `assets/shaders/win_bg.glsl` + `lua/game/shaders/win_bg.lua` — wip-3d has no `win_bg.glsl` in `assets/shaders/` and no `lua/game/shaders/win_bg.lua`. Copy `../wip/assets/shaders/win_bg.glsl` to `assets/shaders/win_bg.glsl` and copy `../wip/lua/game/shaders/win_bg.lua` to `lua/game/shaders/win_bg.lua` verbatim. The shader uses `../wip/lua/core/shader.lua`-style loading; confirm `lua/core/shader.lua` exists in wip-3d (it does — used by other shaders).

- [x] Task 8 — `lua/game/scenes/win_scene.lua` — Create new file adapted from `../wip/lua/game/scenes/win_scene.lua`. Differences from wip: replace `require("lua/core/scene")` with `require("lua/core/scene_2d")` (wip-3d's 2D scene base), replace `Fonts.new(22)` with `love.graphics.newFont(22)`, replace `UI.draw9(...)` with the inline `draw9` function already defined in `customer.lua`, replace image path `"assets/images/start_pattern.png"` with `"assets/start_pattern.png"`, replace `config.LOGICAL_W/H` with literals `1280` and `720`. Keep `WinBg`, `A.win_scene`, `A.speech_bubble`, `gs.first_idol_at`, and `self.input:icon_key_for("cancel")` logic intact — these all exist in wip-3d.

- [x] Task 9 — `lua/game/scenes/store_scene.lua` — Three changes:
    **(a) _last_script_id tracking**: In `StoreScene.new`, add `self._last_script_id = nil`. In `_next_customer_cfg`, after building `qualified`, add a `pool` filter excluding `script.id == self._last_script_id`; pick from `pool` if non-empty (set `self._last_script_id = script.id`), else fall through to generic. In `_handle_interact` where `self._active_script_key = nil` is set after a sale (line ~389), also add `self._last_script_id = nil`.
    **(b) play_time tracking**: At the top of `StoreScene:update(dt)`, after `local gs = self.game_state`, add `gs.play_time = gs.play_time + dt`.
    **(c) Wire Golden Idol**: Add `local WinScene = require("lua/game/scenes/win_scene")` and `local GoldenIdol = require("lua/game/items/golden_idol")` at the top of the file. In `_setup_store`, create `self._win_scene = WinScene.new(gs, self.input, self.scene_manager, self)` and `self._win_scene_factory = function() return self._win_scene end`. Add `self:_wire_golden_idol()` call in `on_enter`. Add `_wire_golden_idol` method that sets `win_scene_factory` on any slot item or held item named `"Golden Idol"` (mirroring wip's `store_scene.lua` lines 242-252, but using `gs.store:all_slots()` which is already the pattern in wip-3d).

- [x] Task 10 — `lua/game/scenes/buy_scene.lua` — Three changes:
    **(a) Golden Idol catalogue entry**: After the Water Drone entry, append `CATALOGUE[#CATALOGUE + 1] = { label = "Golden Idol", description = "A shiny golden idol.\nPurely decorative.", cost = 4000, kind = "golden_idol", image = A.golden_idol }`. Add `local GoldenIdol = require("lua/game/items/golden_idol")` at the top.
    **(b) play_time tracking**: In `BuyScene:update(dt)`, add `self.game_state.play_time = self.game_state.play_time + dt` at the top of the method.
    **(c) golden_idol purchase handler**: In `BuyScene:_confirm()`, add a new branch for `kind == "golden_idol"` (inside the final `gs.currency < ent.cost` guard block, after the `expand` branch): deduct cost, set `gs.first_idol_at = gs.first_idol_at or gs.play_time`, set `gs.player.held_item = GoldenIdol.new()`, play `"shop_buy"`, switch to store scene.

- [x] Task 11 — `lua/game/scenes/settings_menu.lua` — Hide "Leave Game" (item 6) when `self._opaque == true`. In `update`: change `self.selected = ((self.selected - 2) % #ITEMS) + 1` to wrap within 5 items when opaque (`local count = self._opaque and 5 or #ITEMS`). In `draw`: wrap the item 6 draw call in `if not self._opaque then ... end`. In `_confirm`: guard the `elseif self.selected == 6 then love.event.quit()` with `if not self._opaque then`. The goal is that when settings are opened from the start screen, the last navigable/visible item is item 5 ("Exit Settings").

- [x] Task 12 — `lua/game/items/pc_store.lua` — Change `self.name = "PC Store"` to `self.name = "Laptop"` in `PCStore.new`.

- [x] Task 13 — `lua/game/items/grafter.lua` — Change `Sound.play("clone_fail")` to `Sound.play("fail")` at line 89. The `clone_fail.wav` asset can remain; it just won't be triggered.

- [x] Task 14 — `lua/game/customer.lua` — In `Customer:draw_bubble()` in the `else` branch (dialog text rendering, ~line 335-367), replace the `local _, revealed_lines = font:getWrap(revealed, ...)` + loop with the wip approach: wrap the full text once (`local _, lines = font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` — already computed above for box sizing), then build `rendered_lines` by walking `lines` with a `remaining = idx` byte counter (trimming each line, taking `math.min(remaining, #trimmed)` chars, decrementing by `#line` including trailing space). Render `rendered_lines` instead of `revealed_lines`. The reference implementation is at `../wip/lua/game/customer.lua` lines 316-331.

- [x] Task 15 — `lua/game/assets.lua` — Three changes:
    **(a) New images**: Add `A.golden_idol = img("assets/golden_idol.png")`, `A.win_scene = img("assets/win_scene.png")`, `A.coin = img("assets/coin.png")` after the existing item images block.
    **(b) Heat lamps**: Change `for lvl = 1, 3 do` to `for lvl = 1, 6 do` in the heat_lamps loop (line 58).
    **(c) Gamepad icons**: Add `A.btn_a`, `A.btn_b`, `A.btn_y`, `A.dpad_up`, `A.dpad_down`, `A.dpad_left`, `A.dpad_right` using `try_img("assets/...")` (these may not exist on all platforms so use `try_img` like other optional assets).

- [x] Task 16 — `assets/heat_lamp_4.png`, `assets/heat_lamp_5.png`, `assets/heat_lamp_6.png` — Copy from `../wip/assets/images/heat_lamp_4.png`, `heat_lamp_5.png`, `heat_lamp_6.png` into `assets/`.

- [x] Task 17 — `assets/btn_a.png`, `assets/btn_b.png`, `assets/btn_y.png`, `assets/dpad_up.png`, `assets/dpad_down.png`, `assets/dpad_left.png`, `assets/dpad_right.png` — Copy from `../wip/assets/images/` into `assets/`.

- [x] Task 18 — `assets/accessories/anon.png`, `assets/accessories/chef_fit.png`, `assets/accessories/neckbeard.png` — Copy from `../wip/assets/images/anon.png`, `../wip/assets/images/chef_fit.png`, `../wip/assets/images/neckbeard.png` into `assets/accessories/`. (wip stores accessories flat in `assets/images/`, wip-3d stores them in `assets/accessories/`.)

- [x] Task 19 — `main.lua` + `lua/game/sound.lua` — Three changes:
    **(a) Hide OS cursor**: In `love.load()` in `main.lua`, add `love.mouse.setVisible(false)` after `Sound.load()`.
    **(b) Focus handler**: Append to `main.lua` (after `love.keypressed`):
    ```lua
    function love.focus(focused)
        Sound.on_focus(focused)
    end
    ```
    **(c) Sound.on_focus**: Add `playing_intent` field to each music track entry in `Sound.load()` (`playing_intent = true` for the menu track which starts playing, `playing_intent = false` for the bg track which starts stopped). In `Sound.fade_music`, set `entry.playing_intent = (target_vol > 0)`. In `Sound.stop_music`, set `entry.playing_intent = false`. Add new function to `sound.lua`:
    ```lua
    function Sound.on_focus(focused)
        if not love.audio then return end
        if focused then
            for _, entry in pairs(_music_tracks) do
                if entry.playing_intent == true and not entry.src:isPlaying() then
                    entry.src:setVolume(entry.fade_vol * _music_volume)
                    entry.src:play()
                end
            end
        end
    end
    ```
