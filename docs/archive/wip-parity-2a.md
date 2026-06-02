## Wip Parity 2a Checklist

Wave 1 tasks are independent and can run in parallel.
Wave 2 tasks each edit a different file but all require `lua/game/sound.lua` (Task 1) to exist first — run after all of Wave 1 completes.

### Wave 1

- [x] Task 1 — `lua/game/sound.lua` (new file) — Create this file by copying `wip/lua/game/sound.lua` verbatim. This is the central sound module; all other sound tasks depend on it existing.

- [x] Task 2 — `assets/sounds/` (new directory + 17 files) — Create the directory and copy all 17 wav files from `wip/assets/sounds/` into `wip-3d/assets/sounds/`. Files: `pick_up.wav`, `put_down.wav`, `sell_plant.wav`, `dismiss_customer.wav`, `dialogue_advance.wav`, `dialogue_skip.wav`, `discard_plant.wav`, `open_shop.wav`, `water_plant.wav`, `plant_ready.wav`, `clone_success.wav`, `clone_fail.wav`, `shop_navigate.wav`, `shop_buy.wav`, `shop_close.wav`, `menu_navigate.wav`, `menu_confirm.wav`.

- [x] Task 3 — `assets/accessories/` (4 image files) — Copy four accessory images from `wip/assets/` into `wip-3d/assets/accessories/`: `secretary_glasses.png`, `shades.png`, `clown.png`, `monocle.png`.

- [x] Task 4 — `lua/game/data/customer_scripts.lua` — Add `accessory` fields to the four characters that are missing them. Mayor Bloom (both chapters): `accessory = "secretary_glasses"`. The Collector (both chapters): `accessory = "shades"`. Dottie (all 3 chapters): `accessory = "clown"`. Mira (chapter 1): `accessory = "hair_bow"`. Old Pete already has `accessory = "flat_cap"` on all chapters — do not change it.

- [x] Task 5 — `lua/game/customer.lua` — Port speech bubble text wrapping from wip. Add `local MAX_BOX_W = 18 * U` near the existing `MIN_BOX_W` constant. In `Customer:draw_bubble()`, replace the fixed-size text bubble logic (currently: `local text_w = font:getWidth(self._full_text); local box_w = math.max(MIN_BOX_W, text_w + PAD * 2); local box_h = text_h + PAD * 2; love.graphics.print(revealed, ...)`) with the wrapped version from wip: call `font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` to get `lines`, measure the widest line to derive `box_w = math.min(MAX_BOX_W, math.max(MIN_BOX_W, widest + PAD * 2))`, set `box_h = text_h * #lines + PAD * 2`, then call `font:getWrap(revealed, MAX_BOX_W - PAD * 2)` for `revealed_lines` and print each line with `love.graphics.print(line, box_x + PAD, box_y + BUBBLE_MARGIN.top / 2 + PAD / 2 + (i-1) * text_h)`.

### Wave 2 (run after Wave 1 is complete)

- [x] Task 6 — `main.lua` — Add sound module init. Add `local Sound = require("lua/game/sound")` with the other requires at the top of the normal game path (below the `--visual` block, around line 91). Inside `love.load`, add `Sound.load()` immediately after `local gs = GameState.new()`.

- [x] Task 7 — `lua/game/items/plant.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top with the other requires. In `Plant:update()`, add `Sound.play("plant_ready")` immediately after `self.ready = true` (inside the `if self._cooldown:update(dt)` block). In `Plant:water()`, change both early-return guards (`if not self.ready then return end` and `if self.stage >= 3 then return end`) to `return false`, and add `return true` at the end of the function after setting the new cooldown.

- [x] Task 8 — `lua/game/items/watering_can.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top. In `WateringCan:interact()`, change `slot.item:water()` to capture the return: `if slot.item:water() then Sound.play("water_plant") end`.

- [x] Task 9 — `lua/game/items/grafter.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top. In `Grafter:interact()`, after `best_slot.item = Plant.new(plant.plant_type)` add `Sound.play("clone_success")`. In the `else` branch (no empty slot), after setting `self.bubble.visible = true` and `self._bubble_timer = 1.5`, add `Sound.play("clone_fail")`.

- [x] Task 10 — `lua/game/scenes/store_scene.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top with the other requires. In `_handle_pick_up_down`: after `self._customer:dismiss()` add `Sound.play("dismiss_customer")`; after `slot.item = player.held_item; player.held_item = nil` add `Sound.play("put_down")`; after `player.held_item = slot.item; slot.item = nil` add `Sound.play("pick_up")`. In `_handle_interact`: after `self._customer:serve()` add `Sound.play("sell_plant")`; after `self._customer:skip_reveal()` add `Sound.play("dialogue_skip")`; after `self._customer:advance()` (the dialog-advance call in the cashier zone) add `Sound.play("dialogue_advance")`; after the garbage-bin discard `player.held_item = nil` add `Sound.play("discard_plant")`; before `item:interact(...)` add `if item.buy_scene_factory then Sound.play("open_shop") end`.

- [x] Task 11 — `lua/game/scenes/buy_scene.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top. In `BuyScene:update()`: after `self.selected = ((self.selected - 2) % n) + 1` (move_left) add `Sound.play("shop_navigate")`; after `self.selected = (self.selected % n) + 1` (move_right) add `Sound.play("shop_navigate")`; before `self.scene_manager:switch(self.store_scene)` in the pick_up_down branch add `Sound.play("shop_close")`. In `BuyScene:_confirm()`: in the speed_boost branch, after deducting currency and setting values, add `Sound.play("shop_buy")` before `return`; same for growth_boost branch; for each of the `plant`, `tool_watering_can`, `tool_grafter`, `expand` kinds, add `Sound.play("shop_buy")` after the purchase succeeds (before `self.scene_manager:switch` or after `gs.store:grow()`).

- [x] Task 12 — `lua/game/scenes/start_scene.lua` — Add Sound integration. Add `local Sound = require("lua/game/sound")` at the top. In `StartScene:update()`: inside the `if up and not self._prev_up` block, after updating `self.selected`, add `Sound.play("menu_navigate")`; same inside the `if down and not self._prev_down` block. In `StartScene:_confirm()`, add `Sound.play("menu_confirm")` as the very first line of the function body.
