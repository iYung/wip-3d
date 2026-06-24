## Goal

Bring `wip-3d` to parity with `../wip` for features shipped since parity-5. Seven concrete gaps identified by diffing every Lua file. Save/Load remains deferred. Asset path convention (`assets/` not `assets/images/`) intentionally kept as-is.

---

## Affected files

| File | Gap |
|------|-----|
| `lua/game/data/customer_scripts.lua` | Missing mayor_bloom ch4; chef_brio ch1-4; wallace ch1-4; mechafrog ch4; dottie ch4; agent_frogsby ch4; romeo ch4; glen ch4; revised dialog lines throughout; updated trigger counts |
| `lua/game/data/growth_tiers.lua` | 3 tiers → 6 tiers; tier 4-6 added with higher costs and multipliers |
| `lua/game/assets.lua` | `grafter_loaded.png` and `grafter_no_space_bubble.png` use `img()` (required) instead of `try_img()` (optional) |
| `lua/game/scenes/buy_scene.lua` | Missing: coin icon in price display; `cancel` key action instead of `pick_up_down` to close shop; intercom moved earlier in catalogue (position 4 after Grafter); display_cost without `$` prefix; currency bubble via `UI.draw_currency_bubble`; key hints via `UI.draw_hud_box` |
| `lua/game/scenes/store_scene.lua` | Missing: background music rotation (4 bg tracks cycling); autosave on every sell; customer walk speed scaling with cooldown tier; `Sound.play` calls for many new named events |
| `lua/game/scenes/settings_menu.lua` | Missing: "Save Game" button (5th item); `cancel` keybind in action list; `on_save`/`on_leave` callback pattern; gamepad navigation |
| `lua/game/sound.lua` | Missing: `Sound.play_random_music(names, fade_duration)`; `Sound.on_focus(focused)` (resume music on window refocus); 4 background music tracks (bg1-bg4); `playing_intent` tracking per track; `is_music_playing()` function |
| `lua/core/input.lua` | Missing: gamepad/joystick support; `key_for(action)` method; `icon_key_for(action)` method; `_mode` and `_joystick` fields; `cancel` action |
| `lua/game/input.lua` | `cancel` action missing from key map |
| `lua/game/data/plant_data.lua` | All costs, sell values, and cooldowns differ from wip's rebalanced values |
| `lua/game/data/cooldown_tiers.lua` | `walk_speed` field missing from each tier |

---

## What changes

### 1 — customer_scripts.lua — chapter 4s and two new characters

wip has 40 script entries (10 characters × 4 chapters, minus 2-chapter characters); wip-3d has 25. Copy verbatim from wip.

Missing content:
- **mayor_bloom ch4** — wins the election, asks for a Golden Lotus to decorate the mayor's office; `trigger = { plant_type = 6, count = 3 }`; `accessory = "secretary_glasses"`
- **mechafrog ch4** — 4th chapter for the existing mechafrog arc
- **dottie ch4** — 4th chapter for the existing dottie arc
- **agent_frogsby ch4** — 4th chapter for the existing frogsby arc
- **romeo ch4** — 4th chapter for the existing romeo arc
- **glen ch4** — 4th chapter for the existing glen arc
- **chef_brio ch1-4** — new character: chef, 4-chapter arc
- **wallace ch1-4** — new character: new 4-chapter arc (only ch1-3 stub in wip; ch4 present)
- **Updated dialog lines** — many existing chapter 1-3 lines differ; copy verbatim from wip

The simplest approach: copy the entire file from wip verbatim.

### 2 — growth_tiers.lua — expand to 6 tiers

wip has 6 tiers, wip-3d has 3. Copy verbatim from wip.

wip tiers:
```
{ cost = 20,  mult = 1.25 }
{ cost = 50,  mult = 1.60 }
{ cost = 100, mult = 1.95 }
{ cost = 200, mult = 2.30 }
{ cost = 350, mult = 2.65 }
{ cost = 500, mult = 3.00 }
```

Also: `assets.lua` loads `heat_lamps[1..3]` only. Expand to `heat_lamps[1..6]` to match wip (but the image files `heat_lamp_4.png` through `heat_lamp_6.png` are optional via `try_img`; copy the wip loop `for lvl = 1, 6`).

### 3 — assets.lua — grafter images promoted from try_img to img

wip promotes two assets to required (`img()`):
- `A.grafter_loaded` = `img("assets/images/grafter_loaded.png")` → in wip-3d: `img("assets/grafter_loaded.png")` — already present in wip-3d but via `img()`, so this is already correct. **No change needed** for these two.

wip also removes `A.coin` from `assets.lua`. wip-3d doesn't have `A.coin` at all. The buy_scene in wip uses a coin icon in price rendering; wip-3d doesn't use it. Skip adding `A.coin` unless buy_scene coin rendering is also ported (see gap 4).

### 4 — buy_scene.lua — price display, cancel key, catalogue order, HUD

Four sub-gaps:

**a) Catalogue order** — wip puts Intercom at position 4 (right after Grafter), before Expand Slot. wip-3d puts it at position 8 (after Marketing, before Water Drone). Reorder to match wip.

**b) Cancel key** — wip closes the shop with `input:pressed("cancel")` (bound to `"i"`). wip-3d uses `input:pressed("pick_up_down")` (bound to `"e"`). Change wip-3d to `input:pressed("cancel")` once the `cancel` action is added to `lua/game/input.lua` (Gap 9).

**c) Price display** — wip renders prices with a coin icon sprite (`A.coin`) next to the number, in green/red depending on affordability. wip-3d renders the price as plain text with a `$` prefix and no coin icon. Port the coin-icon price render from wip. This requires adding `A.coin = img("assets/images/coin.png")` to `assets.lua` (note: wip uses `assets/images/coin.png`; copy the file to `assets/coin.png` for wip-3d's path convention).

**d) HUD overlay** — wip uses `UI.draw_currency_bubble` (coin icon + number in a 9-slice bubble) and `UI.draw_hud_box` (keybind hints in a 9-slice box) on top of the buy_scene canvas. wip-3d uses plain text. Port to use `UI.draw_currency_bubble` and `UI.draw_hud_box` once the `UI` module is added (Gap 10).

**e) ColorReplace in preview** — wip passes `next_tier.secondary` to `ColorReplace.apply` when previewing the speed tier shoe color; wip-3d passes only `next_tier.color`. Fix: change `ColorReplace.apply(next_tier.color)` to `ColorReplace.apply(next_tier.color, next_tier.secondary)`.

### 5 — store_scene.lua — background music rotation + autosave + customer walk speed

**a) Background music rotation** — wip plays one of four background tracks (`bg1`-`bg4`) chosen at random on `on_enter`, then rotates to the next when the current track finishes:

```lua
self._bg_list  = {"bg1", "bg2", "bg3", "bg4"}
self._bg_index = math.random(4)
-- In on_enter:
Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
-- In update(), when current track stops:
if not Sound.is_music_playing(self._bg_list[self._bg_index]) then
    self._bg_index = (self._bg_index % #self._bg_list) + 1
    Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
end
```

wip-3d has only a single `"bg"` track. Expand `sound.lua` to load `bg1-bg4` (see Gap 6) and add this rotation logic to `store_scene.lua`.

**b) Autosave on sell** — wip calls `_autosave(gs)` (writes `Save.write(GameState.to_save(gs))`) each time a sale completes. Save/Load remains deferred, so autosave can be added as a stub call or left for the Save/Load doc. **Defer** this sub-gap.

**c) Customer walk speed from cooldown tier** — wip scales customer walk speed with the Marketing upgrade tier:

```lua
local function customer_walk_speed(gs)
    if gs.cooldown_level == 0 then return 80 end
    return COOLDOWN_TIERS[gs.cooldown_level].walk_speed
end
```

wip-3d uses a hardcoded `SPEED = 80` in `customer.lua`. To match wip, add `walk_speed` to each tier in `cooldown_tiers.lua` (Gap 8) and pass `walk_speed` in the customer config from `store_scene.lua` when spawning.

**d) Sound event names** — wip-3d `store_scene.lua` calls several sound events that wip does not have in its manifest (`dismiss_customer`, `dialogue_skip`, `dialogue_advance`, `sell_plant`, `discard_plant`, `open_shop`). Add these names to `sound.lua`'s `_EVENT_NAMES` list so they are loaded if the asset files exist (see Gap 6).

### 6 — sound.lua — bg1-bg4 tracks + is_music_playing + on_focus + play_random_music

wip's `Sound` module has:
- **4 background tracks**: `bg1`-`bg4`, each a non-looping `.mp3`. Currently wip-3d only has `"bg"` as a single non-looping track.
- **`Sound.is_music_playing(name)`** — returns `entry.src:isPlaying()` for a named track; used by the rotation logic in store_scene.
- **`Sound.play_random_music(names, fade_duration)`** — filter to existing tracks, stop any playing, pick one at random, fade it in. Used by wip but not currently by wip-3d; add for completeness.
- **`Sound.on_focus(focused)`** — when the window regains focus, restores any tracks whose `playing_intent` was true; called from `love.focus`. wip-3d has no `love.focus` handler.
- **`playing_intent` field** per track — tracks whether a track was intentionally playing so `on_focus` can restore it.
- **Extended `_EVENT_NAMES`** — add the additional sound event names called from store_scene and buy_scene: `"dismiss_customer"`, `"dialogue_skip"`, `"dialogue_advance"`, `"sell_plant"`, `"discard_plant"`, `"open_shop"`, `"shop_close"`, `"clone_fail"`.

Copy `assets/music/background.mp3` variants 2-4 from `../wip` if they exist. The `Sound.load()` function should try to load each; missing files are silently skipped (already the pattern for optional assets).

### 7 — settings_menu.lua — Save Game button + cancel keybind + gamepad

**a) Save Game button** — wip has 7 items; wip-3d has 6. wip adds "Save Game" as item 5 (between "Keybinds" and "Exit Settings"). The save button calls `self._on_save()` if provided. Since Save/Load is deferred, add the button with a no-op `_on_save` for now, and wire the real save in the Save/Load doc.

**b) `cancel` keybind in action list** — wip's `_ACTION_LIST` has 7 entries including `"cancel"` / label `"Cancel"`. wip-3d has 6. Add `"cancel"` once the input module gains the action (Gap 9).

**c) Shake feedback on duplicate key** — wip shakes a row red for 0.5 s if a duplicate key is assigned during keybind capture. wip-3d just accepts duplicates silently. Add `_shake_row` / `_shake_timer` and the shake render logic.

**d) Gamepad navigation** — wip's `SettingsMenu:update` and `SettingsMenu.new` include joystick polling via `_joy_nav()` and a `gamepadpressed(button)` handler for the Start button. wip-3d has no gamepad support here. Add gamepad nav (defer to same task as core input gamepad — Gap 9).

**e) `on_save`/`on_leave` callbacks** — wip takes two extra constructor args `on_save, on_leave` that are called when Save Game / Leave Game is activated. wip-3d takes none. Add these optional callbacks; leave them nil until Save/Load is implemented.

**f) `_visible_items` filtering** — wip hides "Save Game" when the menu is opened opaque (no save to do from start screen) and hides "Keybinds" in gamepad mode. wip-3d always shows all items. Add this filtering.

### 8 — cooldown_tiers.lua — walk_speed field

wip's three cooldown tiers have a `walk_speed` field:
```
{ cost = 10, cooldown = 3, walk_speed = 100, label = "..." }
{ cost = 25, cooldown = 2, walk_speed = 120, label = "..." }
{ cost = 50, cooldown = 0, walk_speed = 150, label = "..." }
```

wip-3d is missing `walk_speed`. Add it to all three tiers to match wip. This unblocks the customer walk speed scaling in store_scene (Gap 5c).

### 9 — core/input.lua and game/input.lua — gamepad + cancel + key_for + icon_key_for

**core/input.lua** — wip adds:
- Joystick/gamepad polling in `Input:update()` (reads left stick + d-pad + face buttons, maps to standard actions)
- `self._mode = "keyboard"` | `"gamepad"` switching when any gamepad axis/button fires
- `self._joystick` field
- `Input:key_for(action)` — returns the primary key string for an action (or pad label in gamepad mode)
- `Input:icon_key_for(action)` — returns a gamepad icon asset key (`"btn_a"`, `"btn_y"`, `"btn_b"`) in gamepad mode, nil otherwise
- Gamepad action map: `interact = A button`, `pick_up_down = Y button`, `cancel = B button`

Copy `lua/core/input.lua` from wip verbatim.

**game/input.lua** — add the `cancel` action bound to `{"i"}` to match wip's defaults.

**assets.lua** — add `A.btn_a`, `A.btn_b`, `A.btn_y` as `img(...)` loads (required). Copy `btn_a.png`, `btn_b.png`, `btn_y.png` from `../wip/assets/images/` to `assets/`.

**main.lua** — add `love.gamepadpressed`, `love.joystickadded`, `love.joystickremoved`, `love.focus` handlers to match wip.

### 10 — ui.lua — new module (extracted from wip)

wip has `lua/game/ui.lua` with two shared drawing functions used by `store_scene`, `buy_scene`, and `customer`:
- `UI.draw9(img, x, y, w, h, m)` — 9-slice draw helper
- `UI.draw_hud_box(labels, font, margin)` — draws a 9-slice box around HUD labels (bottom-left)
- `UI.draw_currency_bubble(currency, x, y, font)` — draws coin icon + number in a 9-slice bubble

wip-3d inlines the `draw9` function in `customer.lua`. Create `lua/game/ui.lua` by copying from wip. Replace the inline `draw9` in `customer.lua` with `UI.draw9`. Wire `UI.draw_currency_bubble` and `UI.draw_hud_box` into `buy_scene.lua` and `store_scene.lua` where appropriate.

Also requires adding `A.coin` to `assets.lua` and copying `assets/images/coin.png` → `assets/coin.png`.

### 11 — plant_data.lua — rebalanced economy values

wip has substantially different costs, sell values, and cooldowns for all 6 plant types:

| Plant | wip cost | wip sell | wip cooldowns | wip-3d cost | wip-3d sell | wip-3d cooldowns |
|-------|----------|----------|---------------|-------------|-------------|------------------|
| Fern  | 0 | 3 | 3, 4 | 1 | 5 | 1, 1 |
| Tulip | 5 | 8 | 6, 6 | 3 | 8 | 8, 12 |
| Rose  | 20 | 20 | 10, 10 | 6 | 13 | 6, 9 |
| Orchid | 75 | 50 | 10, 30 | 10 | 20 | 4, 7 |
| Daisy | 300 | 200 | 15, 45 | 15 | 28 | 3, 5 |
| Golden Lotus | 700 | 400 | 30, 60 | 20 | 40 | 2, 3 |

Copy `lua/game/data/plant_data.lua` verbatim from wip.

---

## What stays the same

- All 3D rendering, raycasting, `scene_3d.lua`, `player_3d.lua`, `map.lua`, `raycaster.lua` — untouched
- `headless/runner.lua`, `headless/input.lua`, `headless/stubs.lua` — unchanged
- `settings_state.lua` — identical; no changes needed
- `store.lua`, `slot.lua` — no changes needed
- `player.lua`, `player_3d.lua` — no changes needed
- CRT shader pipeline in `buy_scene.lua` — unchanged
- Water Drone logic — unchanged
- `scene_manager.lua` fade transition — unchanged
- Asset path convention (`assets/` not `assets/images/`) — intentionally kept as-is
- Save/Load — deferred to own doc

---

## Open questions

1. **Plant economy**: wip's values are considerably higher (Golden Lotus sells for $400 vs $40 in wip-3d). wip-3d's starting currency is $1000 vs $0 in wip. Should we copy wip's economy exactly, or keep wip-3d's faster/cheaper tuning? The safest call is to copy wip verbatim so customer script triggers remain calibrated correctly.

2. **Gamepad support (Gap 9)**: wip has full joystick support. wip-3d is keyboard-only. This is a non-trivial addition that touches `core/input.lua`, `settings_menu.lua`, `main.lua`, and requires three button-icon assets. Should it be included in this parity pass or tracked separately?

3. **ui.lua (Gap 10)**: Adding the `UI` module requires copying `coin.png` and wiring it into buy_scene. The visual impact (coin icon in price display, 9-slice currency bubble in store HUD) is cosmetic but visible. Include in this pass or defer?

4. **Save Game button in settings (Gap 7a)**: Adding the button but leaving it as a stub is low value until Save/Load lands. Should this be added now as a visible disabled button, or deferred entirely to the Save/Load doc?
