## wip-parity-2b Checklist

Tasks are grouped into dependency waves. Within each wave, tasks are independent and can run in parallel.

---

### Wave 1 — No dependencies (run in parallel)

- [x] Task A — `assets/` — Copy `menu_btn.png`, `menu_btn_selected.png`, and `settings_background.png` from `/root/wip/assets/` into `/root/wip-3d/assets/`. Three files, verbatim copy.

- [x] Task B — `lua/game/settings_state.lua` — Port verbatim from `/root/wip/lua/game/settings_state.lua`. This is a new file. Holds `fullscreen` bool, `sfx_volume`/`music_volume` ints (0–100), and `keybinds` table; owns the `love.window.setFullscreen` call.

- [x] Task C — `lua/game/scenes/settings_menu.lua` — Port verbatim from `/root/wip/lua/game/scenes/settings_menu.lua`. This is a new file. Pause overlay with 6 buttons. Loads assets directly (not via `A.`).

- [x] Task D — `lua/game/input.lua` — Add three missing actions to the Input.new call: `move_up = {"up", "w"}`, `move_down = {"down", "s"}`, `menu_confirm = {"return", "space", "f"}`. The existing file is only 8 lines — add the three entries alongside the existing four.

- [x] Task G — `lua/game/scenes/store_scene.lua`, `lua/game/scenes/buy_scene.lua` — In each scene's constructor (`StoreScene.new` and `BuyScene.new`), add `self.esc_opens_settings = true` so `main.lua` knows to intercept Escape. Check wip scenes for the exact placement.

- [x] Task H — `lua/game/customer.lua` — Port `talking_after` support from `/root/wip/lua/game/customer.lua`:
  1. In `Customer.new`, add: `self.after_messages = cfg.after_messages or {}`, `self.after_msg_index = 1`, `self.done_after = #(cfg.after_messages or {}) == 0`.
  2. Add new method `Customer:advance_after()` — port verbatim from wip (lines ~181–195): advances `after_msg_index` through `after_messages`; sets `self.done_after = true` when exhausted.
  3. In `Customer:serve()` — after the sale, if `not self.done_after`, transition `self.state = "talking_after"` and set `self._full_text = self.after_messages[1]` instead of immediately walking out.
  4. In `Customer:update(dt)` — handle `talking_after` typewriter reveal the same as `waiting`.
  5. In `Customer:draw()` — show speech bubble when `state == "talking_after"` and `bubble.visible` (same gate as `waiting`).

---

### Wave 2 — Run after Wave 1 completes (E needs D, I and J need H; E, I, J can be parallel)

- [x] Task E — `lua/game/scenes/start_scene.lua` — Port wip's version (needs Task D's new input actions):
  1. Accept a 4th constructor arg `open_settings` (a callback function); store as `self.open_settings`.
  2. Replace hardcoded `love.keyboard.isDown` checks in `update` with `self.input:pressed("move_up")`, `self.input:pressed("move_down")`, `self.input:pressed("menu_confirm")` (edge-triggered, no `_prev_*` booleans needed).
  3. Add `"Settings"` as the 4th entry in `ITEMS`.
  4. In `_confirm()`, when `self.selected == 4`, call `self.open_settings()`.
  5. Update the `selected == 3` (Exit) branch to remain correct (it was index 3 before; it stays 3 since Settings is inserted after it — check wip's start_scene for the final layout).

- [x] Task I — `lua/game/scenes/store_scene.lua` — Wire `talking_after` F-key advancement in `_handle_interact()` (needs Task H's `advance_after()`). In the cashier zone block inside `_handle_interact`, add a branch: when `self._customer.state == "talking_after"`, call `self._customer:skip_reveal()` if `not self._customer:line_complete()`, else call `self._customer:advance_after()`. Port the exact branching from wip lines ~277–290.

- [x] Task J — `lua/game/data/customer_scripts.lua` — Append Sage's 4-chapter arc before the closing `}` of the return table. Copy verbatim from `/root/wip/lua/game/data/customer_scripts.lua` lines 210–282 (the four entries with `id = "sage"`, chapters 1–4, `accessory = "monocle"`, `after_messages`). The `monocle.png` asset is already in place.

---

### Wave 3 — Run after Wave 2 completes (needs B, C, E)

- [x] Task F — `main.lua` — Wire SettingsState and SettingsMenu (needs Tasks B, C, E). Port from `/root/wip/main.lua` lines ~31–160:
  1. Add `require` for `lua/game/scenes/settings_menu` and `lua/game/settings_state` at the top.
  2. Declare `local settings_menu` at module scope.
  3. In `love.load`: construct `local ss = SettingsState.new()`, construct `settings_menu = SettingsMenu.new(ss, input)`, pass `function() settings_menu:open(true) end` as the 4th arg to `StartScene.new`.
  4. In `love.update`: gate `scene_manager:update(dt)` behind `not settings_menu.is_open`; call `settings_menu:update(dt)` when open.
  5. In `love.draw`: call `settings_menu:draw()` when `settings_menu.is_open` (after drawing the canvas to screen).
  6. In `love.keypressed`: delegate to `settings_menu:keypressed(key)` first (return if it returns true); then handle Escape — if `scene_manager.current.esc_opens_settings`, toggle open/close on the settings menu; else keep existing `love.event.quit()` fallback.
