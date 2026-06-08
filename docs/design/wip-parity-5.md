## Goal

Bring `wip-3d` to parity with `../wip` for the features shipped since parity-4. Eleven concrete gaps identified by diffing every changed file. Save/Load deferred to its own design doc. Asset path reorganization (`assets/` → `assets/images/`) skipped — wip-3d maintains its own convention and the churn is not worth it.

---

## Affected files

| File | Gap |
|------|-----|
| `lua/game/data/customer_scripts.lua` | Missing ~234 lines: Romeo ch1-3, Glen ch1-3, Frogsby ch3, Mechafrog ch3; Mayor Bloom rebranded 3-chapter arc; Dottie rebranded as circus clown; `voice_pitch` on all entries; `no_dismiss = true` on sage ch1; rebalanced triggers throughout |
| `lua/game/data/speed_tiers.lua` | 3 tiers → 6 tiers; adds `secondary` shoe color per tier; tier[0] base color changed from white to pale sky blue |
| `lua/game/player.lua` | `set_speed_level(level, color)` → `set_speed_color(color, secondary)`; secondary stored and forwarded to `ColorReplace.apply` |
| `lua/game/scenes/buy_scene.lua` | Speed purchase updated for `set_speed_color`; Intercom entry added; Water Drone entry added |
| `lua/game/items/intercom.lua` | New file — Intercom tool ($50); shows customer's plant request bubble above itself from anywhere in the store |
| `lua/game/water_drone.lua` | New file — Water Drone ($10 one-time); background autonomous watering (3D adaptation: pure logic, no sprite) |
| `lua/game/game_state.lua` | Add `has_drone = false` field |
| `lua/game/scenes/store_scene.lua` | `no_dismiss` guard on E/F-dismiss; initial spawn timer 0.1 s for new game; garbage bin discard locked to outside cashier zone; Water Drone wired when `has_drone = true` |
| `lua/game/sound.lua` | Add `play_animalese(pitch)` function; replace single-track music with multi-track system (menu + bg with crossfade) |
| `lua/game/customer.lua` | Call `Sound.play_animalese(self._voice_pitch)` each time reveal advances |
| `lua/game/scenes/start_scene.lua` | Play menu music on enter |
| `lua/game/scenes/settings_menu.lua` | Seventh button label: "Leave Game" when opaque (start screen), "Main Menu" when not opaque (in-game) |
| `conf.lua` | Update window title |
| `assets/intercom.png` | Copy from `../wip/assets/images/intercom.png` |
| `assets/sounds/animalese.wav` | Copy from `../wip/assets/sounds/animalese.wav` |
| `assets/music/menu.wav` | Copy from `../wip/assets/music/menu.wav` |

---

## What changes

### 1 — customer_scripts.lua — copy verbatim from wip

wip's file is 517 lines; wip-3d's is 283. Copy verbatim. Changes bundled in the copy:

- **New characters**: Romeo ch1-3 (hopeless romantic), Glen ch1-3 (podcast believer)
- **Extended arcs**: Frogsby ch3, Mechafrog ch3
- **Mayor Bloom rework**: 3-chapter rebranding campaign arc (was 2 chapters); moved to rose trigger count 10/20/30
- **Dottie rework**: rebranded as circus clown job arc
- **`voice_pitch` field** on every entry (used by animalese system, ignored harmlessly until animalese is wired)
- **`no_dismiss = true`** on sage ch1 so the tutorial character can't be dismissed
- **Rebalanced triggers**: tulip thresholds spaced, Mira/Mayor Bloom rose triggers adjusted, Dottie switched to tulip→daisy pull

### 2 — speed_tiers.lua — expand to 6 tiers

Copy from wip. Tier table grows from [0-3] to [0-6]:

```
[0] = { color = {0.5, 0.75, 1.0, 1} }                                 -- pale sky blue base
[1] = { cost =  15, speed =  320, color = {...}, secondary = {...} }
[2] = { cost =  30, speed =  450, color = {...}, secondary = {...} }
[3] = { cost =  55, speed =  590, color = {...}, secondary = {...} }
[4] = { cost = 100, speed =  720, color = {...}, secondary = {...} }
[5] = { cost = 200, speed =  960, color = {...}, secondary = {...} }
[6] = { cost = 360, speed = 1200, color = {...}, secondary = {...} }
```

### 3 — player.lua — secondary shoe color

Rename `set_speed_level(level, color)` → `set_speed_color(color, secondary)`. Store `self._speed_secondary = secondary`. Change `ColorReplace.apply(self._speed_color)` to `ColorReplace.apply(self._speed_color, self._speed_secondary)`.

### 4 — buy_scene.lua — Intercom + Water Drone entries + speed fix

- Fix speed purchase: `gs.player:set_speed_level(gs.speed_level, tier.color)` → `gs.player:set_speed_color(tier.color, tier.secondary)`
- Add Intercom entry (label "Intercom", description "See the plant order\nfrom anywhere.", cost $50, kind `"tool_intercom"`, image `A.intercom`)
- Add Water Drone entry (label "Water Drone", description "Auto-waters ready plants.", cost $10, kind `"drone"`, image `A.water_drone`)
- Handle `"drone"` kind: check `gs.has_drone`; if already owned show sold-out; otherwise deduct cost, set `gs.has_drone = true`, switch back to store
- Handle `"tool_intercom"` kind: give player the Intercom item (same pattern as grafter), switch to store
- Add `A.water_drone` and `A.intercom` try_img loads to assets.lua

### 5 — intercom.lua — new item

Copy `../wip/lua/game/items/intercom.lua`. The item shows the customer's plant request bubble (mirrored from customer's bubble) above itself. The 3D `_wire_intercom` callback is `function() return store_scene._customer end` — same pattern as 2D; store_scene passes itself via the buy_scene constructor already.

Copy `assets/intercom.png` from `../wip/assets/images/intercom.png`.

### 6 — water_drone.lua — background autonomous watering (3D adaptation)

wip's 2D drone has a sprite that flies to plant slots by pixel x-coordinate. In wip-3d there is no world-space camera for a visible drone sprite.

**3D adaptation**: implement the drone as a pure background module — no sprite, no drawer entry. `WaterDrone.new(store, game_state)` returns an object with `update(dt)`. Each tick it scans all slots for `plant.ready == true`, picks the first one, and waters it (calls `plant:water(store)` plus increments `game_state.stage3_counts[plant_type]` when stage reaches 3, matching what player watering does). Wire it in `store_scene.lua` after the player is set up, conditional on `gs.has_drone`.

Water drone is intentionally simple: no delay between waterings, no animation. If balance is needed, add a fixed inter-water delay in a follow-up.

### 7 — game_state.lua — has_drone field

Add `self.has_drone = false` in `GameState.new()` after the other boolean fields.

### 8 — store_scene.lua — three fixes

**a) no_dismiss guard**

Before the E-dismiss block and the F-advance-to-dismiss block, gate with `not (self._active_script and self._active_script.no_dismiss)`. Matches wip's pattern exactly.

**b) Initial spawn timer for new game**

wip detects new-vs-loaded game via a `_from_save` flag set when `GameState.from_save` is used. Since Save/Load is deferred, use a simpler approach: `StoreScene.new` accepts an optional `is_new_game` boolean from `start_scene.lua`. Initial spawn timer is `is_new_game and 0.1 or spawn_cooldown(gs)`. StartScene passes `true` when the player starts a new game, `false` or nil when continuing.

**c) Garbage bin cashier zone guard**

wip guards discard with `player.x >= 0` (outside cashier zone). wip-3d uses y-position: the cashier zone is `player_3d.y <= CASHIER_THRESH` (CASHIER_THRESH = 4.0). Add guard: discard interaction is only triggered when `player_3d.y > CASHIER_THRESH`.

### 9 — sound.lua — animalese + multi-track music

**Animalese**: add `_animalese_src` and `_animalese_last_t` module vars. In `Sound.init`, load `assets/sounds/animalese.wav` as a static source if the file exists. Add:

```lua
function Sound.play_animalese(pitch)
    if not _animalese_src then return end
    local now = love.timer.getTime()
    if now - _animalese_last_t < 0.05 then return end  -- 50ms cooldown
    _animalese_last_t = now
    _animalese_src:stop()
    _animalese_src:setPitch(pitch or 1.0)
    _animalese_src:play()
end
```

**Multi-track music**: replace `_music` single-source with `_music_tracks` table, each entry having `{ src, fade_vol, fade_target, fade_rate, stop_on_done }`. In `Sound.update(dt)` (add a new exported function), advance each track's fade and set volume accordingly. Expose `Sound.fade_to(track_name, target_vol, rate)`. Load two tracks in `Sound.init`:
- `"menu"` from `assets/music/menu.wav` (stream, looping, starts playing)
- `"bg"` from `assets/music/background.mp3` (stream, looping, starts silent and stopped)

Add `Sound.crossfade(from, to, rate)` that fades `from` down and `to` up at the given rate, stopping `from` when vol reaches 0.

**Remove** now-unused sound events: `dialogue_skip`, `dialogue_advance`, `dismiss_customer`, `discard_plant`, `open_shop`, `shop_close` (wip removed these). Add `"fail"` event (used for insufficient funds and clone fail, replacing the separate `"clone_fail"` call in buy_scene; grafter can stay as-is).

Copy `assets/sounds/animalese.wav` and `assets/music/menu.wav` from `../wip`.

### 10 — customer.lua — animalese on typewriter advance

In the typewriter update block, capture `prev_index = self.reveal_index` before incrementing. After incrementing, if `self.reveal_index > prev_index`, call `Sound.play_animalese(self._voice_pitch)`. The `_voice_pitch` field comes from the script config (added in Gap 1); default to `1.0`.

### 11 — start_scene.lua — play menu music

In `StartScene:on_enter`, call `Sound.crossfade("bg", "menu", 2.0)` (fade out bg, fade in menu at rate 2 vol/s). This matches wip's behavior where the start screen plays the menu track.

### 12 — settings_menu.lua — Main Menu relabel

In wip the 7th button shows "Main Menu" when the menu is opened in-game (not opaque). wip-3d currently always shows "Leave Game". Change the label to:

```lua
(i == 6 and not self._opaque) and "Main Menu" or ITEMS[i]
```

(wip-3d has 6 items vs wip's 7; index 6 is "Leave Game".)

### 13 — conf.lua — window title

Update `t.window.title` to `"Frobert Grows Plants With Increasing Speed and Quantity For Profit"`.

---

## What stays the same

- All 3D rendering, raycasting, `scene_3d.lua`, `player_3d.lua`, `map.lua` — untouched
- `headless/runner.lua` and `headless/input.lua` — already adapted for 3D
- `settings_state.lua` — identical; no changes needed
- `store.lua`, `slot.lua` — no changes needed
- `buy_scene.lua` scene rendering and CRT pipeline — unchanged
- Save/Load — deferred to own doc
- Asset path convention (`assets/` not `assets/images/`) — intentionally kept as-is
- Icon — minor; left for Save/Load doc or a cleanup pass

---

## Open questions

None — all scoping decisions resolved before writing.
