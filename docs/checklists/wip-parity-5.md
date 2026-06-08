## wip-parity-5 Checklist

Tasks A–H are independent and can run in parallel.
Tasks I–L can run in parallel with each other after A–H complete.
Tasks M–N run last (M depends on C+I+J; N depends on J+L).

---

- [x] Task A — `lua/game/data/customer_scripts.lua` — Copy file verbatim from `../wip/lua/game/data/customer_scripts.lua`; this replaces the 283-line wip-3d file with the 517-line wip version, adding Romeo ch1-3, Glen ch1-3, Frogsby ch3, Mechafrog ch3, Mayor Bloom 3-chapter rebranding arc, Dottie rebranded as circus clown, `voice_pitch` on all entries, `no_dismiss = true` on sage ch1, and rebalanced triggers throughout

- [x] Task B — `lua/game/data/speed_tiers.lua` — Copy file verbatim from `../wip/lua/game/data/speed_tiers.lua`; this expands from 3 tiers to 6 tiers and adds a `secondary` shoe color per tier; tier[0] base color changes from white `{1,1,1,1}` to pale sky blue `{0.5, 0.75, 1.0, 1}`

- [x] Task C — `lua/game/player.lua` — (1) Rename `set_speed_level(level, color)` to `set_speed_color(color, secondary)` — drop the unused `level` param, store `self._speed_secondary = secondary`; (2) add `self._speed_secondary = nil` in `Player.new` after `self._speed_color = SPEED_TIERS[0].color`; (3) in `draw`, change `ColorReplace.apply(self._speed_color)` to `ColorReplace.apply(self._speed_color, self._speed_secondary)`

- [x] Task D — `lua/game/game_state.lua` — Add `self.has_drone = false` in `GameState.new()` on the line after `self.cooldown_level = 0`

- [x] Task E — `conf.lua` — Change `t.window.title` from `"plant game"` to `"Frobert Grows Plants With Increasing Speed and Quantity For Profit"`

- [x] Task F — `lua/game/scenes/settings_menu.lua` — In the draw loop that renders button labels, change the label for item index 6 ("Leave Game") to render as `"Main Menu"` when `not self._opaque` (opened in-game) and `"Leave Game"` when `self._opaque` (opened from start screen); specifically find where `ITEMS[i]` is drawn and replace with `(i == 6 and not self._opaque) and "Main Menu" or ITEMS[i]`

- [x] Task G — Assets — Copy four files from `../wip`:
  - `../wip/assets/images/intercom.png` → `assets/intercom.png`
  - `../wip/assets/sounds/animalese.wav` → `assets/sounds/animalese.wav`
  - `../wip/assets/sounds/fail.wav` → `assets/sounds/fail.wav`
  - `../wip/assets/music/menu.wav` → `assets/music/menu.wav` (create `assets/music/` dir if it doesn't exist)

- [x] Task H — `lua/game/sound.lua` + `main.lua` — Replace `lua/game/sound.lua` with the wip version (copy verbatim from `../wip/lua/game/sound.lua`) **except** keep the background music path as `"assets/music/background.ogg"` instead of `"background.mp3"` (wip-3d uses .ogg); then in `main.lua` add `Sound.update(dt)` as the first call inside `love.update(dt)` (before the `settings_menu:update(dt)` call)

---

- [x] Task I — `lua/game/items/intercom.lua` — Create new file by copying verbatim from `../wip/lua/game/items/intercom.lua`; no 3D adaptation needed — the item uses its `_customer_getter` callback which store_scene will provide (same pattern as the grafter's store callback)

- [x] Task J — `lua/game/water_drone.lua` — Create new file implementing background autonomous watering (3D adaptation — no sprite, no drawer entry). Module interface: `WaterDrone.new(store, game_state)` returns an object with one method `update(dt)`. Each `update` call: scan all slots in `store:all_slots()` for a plant item where `plant.ready == true`; pick the first one found; call `plant:water(store)` (which advances the stage and resets ready); if the plant's new stage is 3, increment `game_state.stage3_counts[plant.plant_type]` (init to 0 if nil). No delay between waterings needed. Require `lua/game/items/plant` only if needed to type-check `slot.item.plant_type` — or just check `slot.item and slot.item.plant_type and slot.item.ready`. Here is the full implementation:

  ```lua
  local WaterDrone = {}
  WaterDrone.__index = WaterDrone

  function WaterDrone.new(store, game_state)
      local self = setmetatable({}, WaterDrone)
      self._store      = store
      self._game_state = game_state
      return self
  end

  function WaterDrone:update(_dt)
      for _, slot in ipairs(self._store:all_slots()) do
          local item = slot.item
          if item and item.plant_type and item.ready then
              item:water(self._store)
              if item.stage == 3 then
                  local pt = item.plant_type
                  self._game_state.stage3_counts[pt] = (self._game_state.stage3_counts[pt] or 0) + 1
              end
              return
          end
      end
  end

  return WaterDrone
  ```

- [x] Task K — `lua/game/customer.lua` — (1) In `Customer.new`, add `self._voice_pitch = cfg.voice_pitch or 1.0` alongside the other cfg fields; (2) in the typewriter update block (where `self.reveal_index` advances), capture `local prev_index = self.reveal_index` before the increment, then after it add `if self.reveal_index > prev_index then Sound.play_animalese(self._voice_pitch) end`; (3) add `local Sound = require("lua/game/sound")` at the top if not already present

- [x] Task L — `lua/game/scenes/start_scene.lua` — (1) In `StartScene:on_enter`, add `Sound.crossfade("bg", "menu", 2.0)` (this fades out the bg track and fades in the menu track; `Sound.crossfade` is defined in the updated sound.lua — check if it exists before calling, or just call it; it is a no-op when tracks are absent); (2) in the New Game confirm branch (where it calls `StoreScene.new(...)`), pass `true` as the fourth argument: `StoreScene.new(self.game_state, self.input, self.scene_manager, true)`; the Continue branch passes no fourth arg (or `false`)

  Note: `Sound.crossfade` isn't yet in wip's sound.lua — instead use `Sound.fade_music("bg", 0, 2.0)` and `Sound.fade_music("menu", 1, 2.0)` which are the wip equivalents.

---

- [x] Task M — `lua/game/assets.lua` + `lua/game/scenes/buy_scene.lua` — Two files, one task (tightly coupled):

  **assets.lua**: Add near the bottom with the other `try_img` calls:
  ```lua
  A.intercom   = try_img("assets/intercom.png")
  A.water_drone = try_img("assets/water_drone.png")
  ```

  **buy_scene.lua**:
  1. Add `local Intercom = require("lua/game/items/intercom")` at the top with other item requires
  2. After the Heat Lamps catalogue entry, append two new entries:
     ```lua
     CATALOGUE[#CATALOGUE + 1] = {
         label       = "Intercom",
         description = "See the plant order\nfrom anywhere.",
         cost        = 50,
         kind        = "tool_intercom",
         image       = A.intercom,
     }
     CATALOGUE[#CATALOGUE + 1] = {
         label       = "Water Drone",
         description = "Auto-waters ready plants.",
         cost        = 10,
         kind        = "drone",
         image       = A.water_drone,
     }
     ```
  3. In `_confirm()`, fix the speed purchase line: change `gs.player:set_speed_level(gs.speed_level, tier.color)` to `gs.player:set_speed_color(tier.color, tier.secondary)`
  4. In `_confirm()`, add insufficient-funds sounds: where `gs.currency < tier.cost then return` (speed), and similar guards for growth/cooldown, add `Sound.play("fail")` before the `return`; same for the general `gs.currency < ent.cost` check at the bottom
  5. In `_confirm()`, add two new kind handlers before the final `gs.currency < ent.cost` check:
     ```lua
     if ent.kind == "drone" then
         if gs.has_drone then return end
         if gs.currency < ent.cost then Sound.play("fail"); return end
         gs.currency  = gs.currency - ent.cost
         gs.has_drone = true
         Sound.play("shop_buy")
         self.scene_manager:switch(self.store_scene)
         return
     end
     if ent.kind == "tool_intercom" then
         if gs.currency < ent.cost then Sound.play("fail"); return end
         gs.currency = gs.currency - ent.cost
         local scene = self.store_scene
         gs.player.held_item = Intercom.new(function() return scene._customer end)
         Sound.play("shop_buy")
         self.scene_manager:switch(self.store_scene)
         return
     end
     ```
  6. In `draw()`, add sold-out display handling for `"drone"` kind: when `gs.has_drone`, show `display_cost = "---"` and `display_desc = "Already installed."` and `can_buy = false`

- [x] Task N — `lua/game/scenes/store_scene.lua` — Four changes:

  **a) Accept is_new_game param**: Change `StoreScene.new(gs, input, sm)` signature to `StoreScene.new(gs, input, sm, is_new_game)`. Change `self._spawn_timer = Timer.new(spawn_cooldown(gs))` to `self._spawn_timer = Timer.new(is_new_game and 0.1 or spawn_cooldown(gs))`

  **b) no_dismiss guard on E-dismiss** (line ~318): Change:
  ```lua
  if self._customer:arrived() and not self._cust_anim then
  ```
  to:
  ```lua
  if self._customer:arrived() and not self._cust_anim
     and not (self._active_script and self._active_script.no_dismiss) then
  ```

  **c) Garbage bin cashier zone guard** (line ~394): Change the garbage-bin discard block condition from:
  ```lua
  if player.held_item
     and player.held_item.sellable ~= false
     and slot and slot.item and slot.item.is_garbage_bin then
  ```
  to:
  ```lua
  if p.y > CASHIER_THRESH
     and player.held_item
     and player.held_item.sellable ~= false
     and slot and slot.item and slot.item.is_garbage_bin then
  ```
  (`p` is already the `player3d` local; `CASHIER_THRESH = 4.0`)

  **d) Wire water drone**: Add `local WaterDrone = require("lua/game/water_drone")` at the top. In `StoreScene:new` (after the spawn timer setup), add:
  ```lua
  self._water_drone = gs.has_drone and WaterDrone.new(gs.store, gs) or nil
  ```
  In `StoreScene:update(dt)`, near the top (after `local gs = self.game_state`), add:
  ```lua
  if self._water_drone then self._water_drone:update(dt) end
  ```
