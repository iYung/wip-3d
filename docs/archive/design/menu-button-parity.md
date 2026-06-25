# Menu Button Parity

## Goal

Menus must display the button that actually triggers their action — respecting both the
current input mode (keyboard vs. gamepad) and any custom keybinds the player has set.
Currently several menus show hardcoded key labels that diverge from the input system.

## Affected files

- `lua/core/input.lua` — gamepad map, `_PAD_LABELS`, `_PAD_ICON_KEYS`
- `lua/game/input.lua` — remove `menu_confirm` action
- `lua/game/scenes/start_scene.lua` — replace `menu_confirm` with `interact`
- `lua/game/scenes/store_scene.lua` — `_hud_labels()` hardcodes "E:" and "F:"
- `lua/game/settings_state.lua` — missing `cancel = "i"` default; `key_map()` drops entries
- `lua/game/scenes/settings_menu.lua` — line 306 overwrites entire `input._map`

## What changes

### 1. Remove `menu_confirm`; start scene uses `interact`

`lua/game/input.lua` currently has a `menu_confirm = {"return", "space", "f"}` action that
the start scene exclusively uses.  It has no gamepad mapping.

- Delete the `menu_confirm` entry from `lua/game/input.lua`.
- Change `start_scene.lua` to check `input:pressed("interact")` instead.
- The `interact` action is already mapped to gamepad A in `core/input.lua`, so the start
  menu will immediately work on a controller.

### 2. Add `cancel` to `settings_state` defaults

`settings_state.lua` line 11 initialises keybinds without `cancel`, so the keybinds
screen always shows "UNBOUND" for cancel even though the game binds it to `"i"` via
`lua/game/input.lua`.

- Add `cancel = "i"` to the initial keybinds table in `settings_state.lua`.

### 3. Fix `settings_menu.lua` key-map update to preserve non-rebindable entries

Line 306: `self._input._map = self._state:key_map()` replaces the entire map after a
rebind.  `settings_state.key_map()` only knows about the seven rebindable actions, so:
- Multi-key defaults (arrow keys for movement) are lost.
- `interact` loses its fallback keys.

Fix: instead of replacing `_map`, iterate `settings_state.keybinds` and update only
those actions in the existing `input._map`.  Non-rebindable entries (`menu_confirm` is
being removed; `cancel` will now be in settings_state) are preserved untouched.

### 4. Store scene HUD uses `input:key_for()` / `input:icon_key_for()`

`store_scene._hud_labels()` returns hardcoded string-literal labels (`"E: PICK UP"`,
`"F: WATER"`, etc.).  These never reflect custom keybinds or gamepad mode.

- Pass `self.input` into `_hud_labels()` (or access it via `self.input` — it's already
  on the object).
- Replace every `"E: …"` with `(input:key_for("pick_up_down") or "e"):upper() .. ": …"`.
- Replace every `"F: …"` with `(input:key_for("interact") or "f"):upper() .. ": …"`.
- For gamepad mode `_hud_labels()` should return icon-bearing table entries (matching the
  pattern already used in `buy_scene.lua`) when `input:icon_key_for()` returns a value.
  `_draw_hud()` already delegates to `UI.draw_hud_box` which handles the icon table format.

## What stays the same

- `core/input.lua` gamepad map for `interact`, `pick_up_down`, `cancel`.
- `_PAD_LABELS` and `_PAD_ICON_KEYS` — no new entries needed once `menu_confirm` is gone.
- `buy_scene.lua` and `win_scene.lua` — already use `key_for()` / `icon_key_for()` correctly.
- `settings_menu.lua` navigation logic — hardcodes its own input polling intentionally
  (it is the screen where keybinds are being edited; it cannot rely on the map it is
  editing).
- `_ACTION_LIST` / `_ACTION_LABELS` in `settings_menu.lua` — no change; `cancel` was
  already listed and will now correctly show its default value.

## Open questions

None — unify `menu_confirm` → `interact` is confirmed.
