## Menu Button Parity Checklist

- [x] Task 1 — `lua/game/input.lua`, `lua/game/scenes/start_scene.lua` — Remove `menu_confirm = {"return", "space", "f"}` from the input map; change `start_scene.lua:61` from `input:pressed("menu_confirm")` to `input:pressed("interact")`

- [x] Task 2 — `lua/game/settings_state.lua` — Add `cancel = "i"` to the initial `self.keybinds` table (line 11) so the keybinds screen shows the default binding instead of "UNBOUND"

- [x] Task 3 — `lua/game/scenes/settings_menu.lua` — Replace line 306 (`self._input._map = self._state:key_map()`) with a loop that only updates the entries present in `settings_state.keybinds`, preserving all other entries in `input._map` (arrow keys, multi-key defaults, etc.)

- [x] Task 4 — `lua/game/scenes/store_scene.lua` — Replace hardcoded `"E: …"` and `"F: …"` labels in `_hud_labels()` with dynamic labels using `self.input:key_for("pick_up_down")` and `self.input:key_for("interact")`; return icon-bearing table entries `{ icon = key, text = ": …" }` when `self.input:icon_key_for()` returns a value (matching the pattern in `buy_scene.lua`)
