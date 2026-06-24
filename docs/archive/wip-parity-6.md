## wip-parity-6 Checklist

Tasks are grouped by dependency. Groups A and B can run fully in parallel with each other.
Within Group B, task B5 (store_scene) depends on B1 (sound.lua), B3 (cooldown_tiers), and B4
(ui.lua) being complete first; all other tasks within Group B are independent.

---

### Group A — Verbatim file copies (no dependencies, fully parallel)

- [x] A1 — `lua/game/data/customer_scripts.lua` — Replace the file entirely by copying
  `../wip/lua/game/data/customer_scripts.lua` verbatim. The wip file has 40 script entries
  (vs 25 in wip-3d): it adds mayor_bloom ch4, mechafrog ch4, dottie ch4, agent_frogsby ch4,
  romeo ch4, glen ch4, chef_brio ch1-4, and wallace ch1-4, and updates many existing dialog
  lines. Copying verbatim is the safest approach because customer trigger counts are calibrated
  against the rebalanced plant economy (A3).

- [x] A2 — `lua/game/data/growth_tiers.lua` — Replace the 3-tier table with the 6-tier table
  from `../wip/lua/game/data/growth_tiers.lua`. The new tiers are:
  ```lua
  { cost = 20,  mult = 1.25 }
  { cost = 50,  mult = 1.60 }
  { cost = 100, mult = 1.95 }
  { cost = 200, mult = 2.30 }
  { cost = 350, mult = 2.65 }
  { cost = 500, mult = 3.00 }
  ```
  Also update `lua/game/assets.lua`: change the heat_lamps loop on line 58 from
  `for lvl = 1, 3` to `for lvl = 1, 6` so lamps 4-6 are attempted via `try_img`.

- [x] A3 — `lua/game/data/plant_data.lua` — Replace the file entirely by copying
  `../wip/lua/game/data/plant_data.lua` verbatim. All six plant costs, sell values, and
  growth cooldowns differ (e.g. Golden Lotus: cost 700 / sell 400 in wip vs 20 / 40 in wip-3d).

- [x] A4 — `lua/game/data/cooldown_tiers.lua` — Add `walk_speed` to each of the three tiers.
  The file currently has no `walk_speed` field. The complete new table is:
  ```lua
  return {
      { cost = 10, cooldown = 3, walk_speed = 100, label = "Customers come faster" },
      { cost = 25, cooldown = 2, walk_speed = 120, label = "Customers come even faster" },
      { cost = 50, cooldown = 0, walk_speed = 150, label = "Customers come even even faster" },
  }
  ```

---

### Group B — Code changes (independent except where noted)

- [x] B1 — `lua/game/sound.lua` — Port the wip sound module additions. The wip Sound module
  lives at `../wip/lua/core/sound.lua`; wip-3d's equivalent is `lua/game/sound.lua`.

  Four changes:

  1. **`playing_intent` field**: In `Sound.load()`, add `playing_intent = autoplay` to each
     music track entry (line 51-58 area). In `Sound.update()`, set `entry.playing_intent =
     false` in the `stop_on_done` branch (after `entry.src:stop()`). In `Sound.play_music()`,
     add `entry.playing_intent = true` after `entry.src:play()`. In `Sound.stop_music()`, add
     `entry.playing_intent = false` after `entry.src:stop()`. In `Sound.fade_music()`, add
     `entry.playing_intent = true` in the "start playing from zero" branch.

  2. **`bg1`–`bg4` tracks**: In `Sound.load()`, add four non-looping background music tracks
     after the existing `"bg"` track block. Use `try`-style loading (skip if file absent).
     File paths use wip-3d's `assets/music/` convention:
     ```lua
     local _bg_names = { "bg1", "bg2", "bg3", "bg4" }
     local _bg_files = {
         "assets/music/background.mp3",
         "assets/music/background2.mp3",
         "assets/music/background3.mp3",
         "assets/music/background4.mp3",
     }
     for i, name in ipairs(_bg_names) do
         if love.filesystem.getInfo(_bg_files[i]) then
             local src = love.audio.newSource(_bg_files[i], "stream")
             src:setLooping(false)
             src:setVolume(0)
             _music_tracks[name] = {
                 src = src, fade_vol = 1, fade_target = 1,
                 fade_rate = 0, stop_on_done = false, playing_intent = false,
             }
         end
     end
     ```
     Also copy `../wip/assets/music/background2.mp3`, `background3.mp3`, `background4.mp3`
     to `assets/music/` (background.mp3 already exists).

  3. **`Sound.play_random_music(names, fade_duration)`**: Add after `Sound.stop_music`. Copy
     verbatim from `../wip/lua/core/sound.lua` lines 141-167.

  4. **`Sound.on_focus(focused)`**: Add after `Sound.play_random_music`. Copy verbatim from
     `../wip/lua/core/sound.lua` lines 175-185.

  5. **Extended `_EVENT_NAMES`**: Add these names to the `_EVENT_NAMES` table so `.wav` files
     are loaded when present: `"dismiss_customer"`, `"dialogue_skip"`, `"dialogue_advance"`,
     `"sell_plant"`, `"discard_plant"`, `"open_shop"`, `"shop_close"`, `"clone_fail"`.

- [x] B2 — `lua/core/input.lua` and `lua/game/input.lua` — Replace `lua/core/input.lua`
  entirely by copying `../wip/lua/core/input.lua` verbatim. That file adds:
  - `_PAD_LABELS` and `_PAD_ICON_KEYS` tables at the top
  - `self._mode = "keyboard"` and `self._joystick = nil` fields in `Input.new`
  - Gamepad polling block in `Input:update()` (reads left stick + d-pad + A/Y/B buttons, sets
    `self._mode = "gamepad"` when any gamepad input fires)
  - `Input:key_for(action)` method
  - `Input:icon_key_for(action)` method

  Then in `lua/game/input.lua`, add `cancel = {"i"}` to the key map. Current file is missing
  this action; wip's `../wip/lua/game/input.lua` binds it to `{"i"}`. The full updated map:
  ```lua
  return Input.new({
      move_up      = {"up", "w"},
      move_down    = {"down", "s"},
      move_left    = {"left", "a"},
      move_right   = {"right", "d"},
      pick_up_down = {"e"},
      interact     = {"f"},
      menu_confirm = {"return", "space", "f"},
      cancel       = {"i"},
  })
  ```

- [x] B3 — `lua/game/assets.lua` — Add three gamepad button icon assets and coin asset.

  1. After the `A.wall_pattern` block and before `A.accessories`, add:
     ```lua
     A.coin  = img("assets/coin.png")
     A.btn_a = img("assets/btn_a.png")
     A.btn_b = img("assets/btn_b.png")
     A.btn_y = img("assets/btn_y.png")
     ```
     These use `img()` (required), matching how wip loads them (wip uses `assets/images/`;
     wip-3d uses `assets/` — keep the `assets/` prefix, no `images/` subdir).

  2. Copy the four source image files from wip's `assets/images/` to wip-3d's `assets/`:
     - `../wip/assets/images/coin.png`     → `assets/coin.png`
     - `../wip/assets/images/btn_a.png`    → `assets/btn_a.png`
     - `../wip/assets/images/btn_b.png`    → `assets/btn_b.png`
     - `../wip/assets/images/btn_y.png`    → `assets/btn_y.png`

- [x] B4 — `lua/game/ui.lua` (new file) and `lua/game/customer.lua` — Create
  `lua/game/ui.lua` by copying `../wip/lua/game/ui.lua` verbatim, then change the asset
  path for `A.coin` inside it: wip uses `require("lua/game/assets")` which already uses
  `assets/images/coin.png`; wip-3d's assets module will expose `A.coin` via `assets/coin.png`
  (done in B3), so no path change is needed in ui.lua itself — it just calls `A.coin`.

  Then in `lua/game/customer.lua`: remove the local `draw9` function (lines 23-41) and add
  `local UI = require("lua/game/ui")` to the top requires. Replace every call to the local
  `draw9(...)` in `customer.lua` with `UI.draw9(...)`. (Search for all `draw9(` calls in the
  file.)

- [x] B5 — `lua/game/scenes/store_scene.lua` — Three changes. **Depends on B1 (sound.lua
  bg1-bg4), B3 (cooldown_tiers walk_speed), and B4 (UI module) being complete.**

  **a) Background music rotation**: In `StoreScene.new`, add after `self._initialized = false`:
  ```lua
  self._bg_list  = {"bg1", "bg2", "bg3", "bg4"}
  self._bg_index = math.random(4)
  ```
  In `StoreScene:on_enter()`, add music start logic after `if not self._initialized then` block
  (after the `_setup_store` block):
  ```lua
  local _bg_playing = false
  for _, name in ipairs(self._bg_list) do
      if Sound.is_music_playing(name) then _bg_playing = true; break end
  end
  if not _bg_playing then
      Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
  end
  ```
  In `StoreScene:update(dt)`, add the rotation check at the end of the update body (after
  the existing store/player/customer update logic, before the end of the function):
  ```lua
  if not Sound.is_music_playing(self._bg_list[self._bg_index]) then
      self._bg_index = (self._bg_index % #self._bg_list) + 1
      Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
  end
  ```
  Also update the `Sound` require at line 16 — currently `require("lua/game/sound")` — which
  is correct for wip-3d (no change needed there; `is_music_playing` and `fade_music` already
  exist in `lua/game/sound.lua` after B1).

  **b) Customer walk speed**: Add a local helper after `spawn_cooldown` (near line 88):
  ```lua
  local function customer_walk_speed(gs)
      if gs.cooldown_level == 0 then return 80 end
      return COOLDOWN_TIERS[gs.cooldown_level].walk_speed
  end
  ```
  Then in `StoreScene:update`, in both places where a customer is spawned via
  `self._customer:show(cfg)`, add `cfg.walk_speed = customer_walk_speed(gs)` before the
  `show` call. (There are two spawn sites in the update function, at the `cd == 0` branch
  and the `_spawn_timer:update(dt)` branch.)

  **c) UI module for HUD**: Add `local UI = require("lua/game/ui")` to the requires at the
  top of the file (after the existing requires). In `StoreScene:_draw_hud()`, replace the
  plain-text currency display (`love.graphics.print("$" .. gs.currency, 10, 10)`) with:
  ```lua
  UI.draw_currency_bubble(gs.currency, 10, 10, love.graphics.getFont())
  ```
  Replace the plain-text context label block (the `local labels = {}` ... `for _, label in
  ipairs(labels)` block at the bottom of `_draw_hud`) with the `UI.draw_hud_box` call and
  the icon-aware label render loop from `../wip/lua/game/scenes/store_scene.lua` lines
  579-607.

- [x] B6 — `lua/game/scenes/buy_scene.lua` — Five changes, each independently applied.

  **a) Cancel key**: In `BuyScene:update`, change `input:pressed("pick_up_down")` (line 126)
  to `input:pressed("cancel")`. Remove the `Sound.play("shop_close")` call on line 127 (wip
  does not play a sound on cancel). The block becomes:
  ```lua
  elseif input:pressed("cancel") then
      self.scene_manager:switch(self.store_scene)
  end
  ```

  **b) Catalogue order**: Move the Intercom entry (currently position 8 in `CATALOGUE`, the
  `label = "Intercom"` block at lines 67-73) to immediately after the Grafter entry (currently
  position 2). The resulting order is: plants (1-6), Watering Can, Grafter, Intercom, Expand
  Slot, Sneakers, Heat Lamps, Marketing, Water Drone.

  **c) Price display with coin icon**: Add `local UI = require("lua/game/ui")` to the
  requires at the top. In `BuyScene:draw()`, replace the price render block (lines 357-364)
  with the coin-icon render from `../wip/lua/game/scenes/buy_scene.lua` lines 356-374:
  - When `display_cost == "---"`: print the text centered as before
  - Otherwise: draw `A.coin` scaled to font height, then print the number to its right, both
    centered as a unit. The `display_cost` values are already plain numbers (no `$` prefix) —
    remove the `"$" ..` prefix from all `display_cost = "$" .. ...` assignments in `draw()`.

  **d) HUD overlay**: In `BuyScene:draw()`, after `CRT.clear()` (currently last draw call),
  add the currency bubble and key-hint box using `UI.draw_currency_bubble` and
  `UI.draw_hud_box`. Copy the block from `../wip/lua/game/scenes/buy_scene.lua` lines
  399-440 verbatim (adjusts key labels to use `self.input:key_for()` and `icon_key_for()`).
  Remove the old plain-text currency line (`love.graphics.print("Currency: " .. currency,
  56, 44)`) and the old hints block at lines 382-388 in the current draw function.

  **e) ColorReplace secondary color**: In `BuyScene:draw()`, in the `speed_boost` preview
  branch, change `ColorReplace.apply(next_tier.color)` to
  `ColorReplace.apply(next_tier.color, next_tier.secondary)` (line 310 area).

- [x] B7 — `lua/game/scenes/settings_menu.lua` — Port wip's settings menu additions. The wip
  source is `../wip/lua/game/scenes/settings_menu.lua`.

  **a) Save Game button and `on_save`/`on_leave` callbacks**: Change `SettingsMenu.new` to
  accept two optional extra parameters: `on_save` and `on_leave`. Store them as
  `self._on_save = on_save` and `self._on_leave = on_leave`. Add `"Save Game"` as item 5 in
  the `ITEMS` table (between `"Keybinds"` and `"Exit Settings"`). The new table is:
  ```lua
  local ITEMS = { "Fullscreen / Window", "SFX Volume", "Music Volume", "Keybinds",
                  "Save Game", "Exit Settings", "Leave Game" }
  ```
  In `SettingsMenu:_confirm()`, renumber: item 5 calls `self._on_save()` if present; item 6
  closes settings; item 7 calls `self._on_leave()` or `love.event.quit()`. Copy the confirm
  logic from wip lines 272-302 verbatim. Also add `self._saved = false` to `SettingsMenu:open`
  and show `"Saved!"` label for item 5 when `self._saved` is true in `draw()`.

  **b) `cancel` action in `_ACTION_LIST`**: Add `"cancel"` / `"Cancel"` to `_ACTION_LIST` and
  `_ACTION_LABELS`:
  ```lua
  local _ACTION_LIST   = {"move_up","move_down","move_left","move_right","pick_up_down","interact","cancel"}
  local _ACTION_LABELS = {"move up","move down","move left","move right","pick up/down","interact","cancel"}
  ```
  Update `_sub_btn_y0` in `SettingsMenu.new`: change `#_ACTION_LIST * BTN_GAP` (currently
  hardcoded around 6 actions) — since `_sub_btn_y0` uses `#_ACTION_LIST`, the formula
  `H / 2 - #_ACTION_LIST * BTN_GAP / 2 - BTN_H / 2` will auto-adjust when the list grows.

  **c) `_visible_items` filtering**: Add the `_visible_items` helper function at the top of the
  file (after `_ACTION_LABELS`). Copy from wip lines 6-14:
  ```lua
  local function _visible_items(opaque, mode)
      local result = {}
      for i = 1, #ITEMS do
          if not (opaque and i == 5) and not (mode == "gamepad" and i == 4) then
              result[#result + 1] = i
          end
      end
      return result
  end
  ```
  In `SettingsMenu:update`, replace the plain `up/down` navigation using `#ITEMS` with the
  filtered-list navigation from wip lines 221-239. In `SettingsMenu:draw`, replace the
  `for i = 1, #ITEMS` loop with the `vis = _visible_items(...)` loop from wip lines 430-467.
  Add the `_btn_y0` recalculation inside draw (wip line 431):
  `local btn_y0 = H / 2 - (#vis - 1) * BTN_GAP / 2 - BTN_H / 2`.

  **d) `_joy_nav` helper and gamepad navigation**: Add the `_joy_nav(input)` local function
  above `SettingsMenu` (copy from wip lines 32-46). In `SettingsMenu:open`, after the
  keyboard snapshot block, add the joystick snapshot lines from wip lines 119-128. In
  `SettingsMenu:update` (both the main-screen block and the keybinds sub-screen block),
  OR each boolean flag with the matching `_joy_nav` result; add `escape` detection for the
  gamepad Start button. Add `self._shake_row = nil` and `self._shake_timer = 0` to
  `SettingsMenu.new`. Copy `SettingsMenu:gamepadpressed(button)` from wip lines 334-349.

  **e) Shake feedback on duplicate key**: In `SettingsMenu.new`, add `self._shake_row = nil`
  and `self._shake_timer = 0`. In `SettingsMenu:update`, add the shake timer decrement block
  from wip lines 141-144. In `SettingsMenu:keypressed`, before calling
  `self._state:set_keybind`, check for duplicate keys; if found, set `_shake_row` and
  `_shake_timer = 0.5` and return true without saving (wip lines 321-327). In
  `SettingsMenu:draw` (keybinds sub-screen), add the shake offset and red tint per row from
  wip lines 372-393. Also copy the split label-bar / value-bar layout for the keybinds rows
  from wip lines 376-393 (uses `LABEL_SX`, `VAL_SX`, `LABEL_W`, `VAL_W`, `BAR_GAP`
  constants — add those at the top of the file from wip lines 55-61).

- [x] B8 — `main.lua` — Add four Love2D callbacks for gamepad and focus support.
  Add the following functions after `love.keypressed` (currently at line 142):

  1. `love.gamepadpressed(joystick, button)` — sets `input._joystick`, `input._mode =
     "gamepad"`, tracks `_prev_start`, forwards to `settings_menu:gamepadpressed(button)`,
     and opens settings on Start button. Copy from `../wip/main.lua` lines 219-234.

  2. `love.joystickadded(joystick)` — sets `input._joystick` when first gamepad connects.
     Copy from `../wip/main.lua` lines 236-240.

  3. `love.joystickremoved(joystick)` — clears `input._joystick` and picks a replacement if
     available. Copy from `../wip/main.lua` lines 242-251.

  4. `love.focus(focused)` — calls `Sound.on_focus(focused)`. Copy from `../wip/main.lua`
     line 264-266.

  Also add `local _prev_start = false` module-level variable near the top (after
  `local settings_menu`), and update `love.update` to poll the Start button each frame (the
  block from `../wip/main.lua` lines 161-178 that checks `start_down and not _prev_start`).
  Update `love.keypressed` to set `input._mode = "keyboard"` on the first line (wip line 204).
  Update `settings_menu = SettingsMenu.new(ss, input)` in `love.load` to pass stub callbacks:
  `settings_menu = SettingsMenu.new(ss, input, nil, nil)` — the real callbacks can be wired
  in the Save/Load doc; for now nil is fine since `_on_save` and `_on_leave` are both
  optional (guarded by `if self._on_save then`).
