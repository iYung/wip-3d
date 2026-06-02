# wip → wip-3d Parity Gap 2b

Settings menu, post-sale dialogue, and Sage tutorial character.
Last audited: 2026-06-02. Do parity-2a first.

---

## Goal

Three features from wip, one with a dependency:
1. Settings menu + SettingsState — pause overlay with volume, fullscreen, keybinds
2. Post-sale dialogue (`talking_after`) — lines after a sale before the heart bubble
3. Sage tutorial character — 4-chapter arc (depends on #2)

---

## Affected files

| # | File | Change |
|---|------|--------|
| 1 | `lua/game/settings_state.lua` | New — copy from wip verbatim |
| 1 | `lua/game/scenes/settings_menu.lua` | New — copy from wip verbatim |
| 1 | `lua/game/input.lua` | Add `move_up`, `move_down`, `menu_confirm` actions |
| 1 | `main.lua` | Load SettingsState + SettingsMenu; wire Escape; pass settings callback to StartScene |
| 1 | `lua/game/scenes/start_scene.lua` | Accept `open_settings` callback; use `move_up`/`move_down`/`menu_confirm`; add Settings button |
| 1 | `lua/game/scenes/store_scene.lua` | Add `self.esc_opens_settings = true` |
| 1 | `lua/game/scenes/buy_scene.lua` | Add `self.esc_opens_settings = true` |
| 1 | `assets/menu_btn.png` | Copy from `wip/assets/menu_btn.png` |
| 1 | `assets/menu_btn_selected.png` | Copy from `wip/assets/menu_btn_selected.png` |
| 1 | `assets/settings_background.png` | Copy from `wip/assets/settings_background.png` |
| 2 | `lua/game/customer.lua` | Add `after_messages`, `talking_after` state, `advance_after()` |
| 2 | `lua/game/scenes/store_scene.lua` | Handle `talking_after` F-key advancement |
| 3 | `lua/game/data/customer_scripts.lua` | Add Sage 4-chapter arc (copy from wip) |
| 3 | `assets/accessories/monocle.png` | Already copied in parity-2a |

---

## What changes

### 1. Settings menu + SettingsState

**Port `lua/game/settings_state.lua` verbatim from wip.** Holds `fullscreen` bool, `sfx_volume`/`music_volume` ints (0–100), and `keybinds` table (6 actions). Owns the `love.window.setFullscreen` call.

**Port `lua/game/scenes/settings_menu.lua` verbatim from wip.** Pause overlay — 6 buttons: Fullscreen/Window, SFX Volume, Music Volume, Keybinds, Exit Settings, Leave Game. Pure view — delegates all mutations to SettingsState. Loads `assets/menu_btn.png`, `assets/menu_btn_selected.png`, `assets/settings_background.png` directly (not via `A.`).

**`lua/game/input.lua`** — add three missing actions to match wip:
```lua
move_up      = {"up", "w"},
move_down    = {"down", "s"},
menu_confirm = {"return", "space", "f"},
```

**`main.lua`** — port wip's `love.load`, `love.update`, `love.draw`, `love.keypressed` to add:
- `local SettingsMenu  = require("lua/game/scenes/settings_menu")`
- `local SettingsState = require("lua/game/settings_state")`
- Construct `ss = SettingsState.new()` and `settings_menu = SettingsMenu.new(ss, input)` in `love.load`
- Pass `function() settings_menu:open(true) end` to `StartScene.new` as `open_settings` callback
- `love.update`: gate `scene_manager:update` behind `not settings_menu.is_open`; call `settings_menu:update` when open
- `love.draw`: call `settings_menu:draw()` when open
- `love.keypressed`: delegate to `settings_menu:keypressed`; toggle open/close on Escape when `scene.esc_opens_settings`

**`lua/game/scenes/start_scene.lua`** — port wip's version:
- Accept 4th arg `open_settings` callback
- Swap hardcoded key checks for `input:pressed("move_up")`, `move_down`, `menu_confirm`
- Add Settings button (4th item) that calls `open_settings()`

**`lua/game/scenes/store_scene.lua`** and **`buy_scene.lua`** — add `self.esc_opens_settings = true` in their constructors so `main.lua` knows to intercept Escape.

**Assets to copy from wip:**
- `assets/menu_btn.png`
- `assets/menu_btn_selected.png`
- `assets/settings_background.png`

### 2. Post-sale dialogue (`talking_after`)

wip's `customer.lua` has a `talking_after` state that plays `after_messages` lines (from the script config) after a sale, before the heart bubble and walk-out.

**`lua/game/customer.lua`** — port from wip:

New fields in `Customer.new`:
```lua
self.after_messages  = cfg.after_messages or {}
self.after_msg_index = 1
self.done_after      = #(cfg.after_messages or {}) == 0
```

New method `Customer:advance_after()` — advances through `after_messages`; sets `self.done_after = true` when exhausted (port verbatim from wip lines ~181–195).

In `Customer:serve()` — after the sale, if `not self.done_after`, transition to `talking_after` state and set `_full_text = after_messages[1]` instead of immediately walking out.

In `Customer:update(dt)` — handle `talking_after` the same as `waiting` for typewriter reveal.

In `Customer:draw()` — show the speech bubble when `state == "talking_after"` and `bubble.visible` (same gate as `waiting`).

**`lua/game/scenes/store_scene.lua`** — in the cashier zone F-key handler, when customer state is `talking_after`: call `skip_reveal()` if not `line_complete()`, else call `customer:advance_after()`. Port the exact branching from wip.

### 3. Sage tutorial character

**Depends on #2** (post-sale dialogue) — Sage's chapters use `after_messages`.

**`lua/game/data/customer_scripts.lua`** — copy Sage's 4-chapter arc verbatim from wip (lines ~210–282 of wip's version). Sage is a tutorial mentor with `count = 0` trigger (guaranteed early appearance), `accessory = "monocle"`, and after_messages teaching core mechanics.

`assets/accessories/monocle.png` — already copied in parity-2a.

---

## What stays the same

- Customer walk animation and 3D raycaster rendering
- All existing scripted characters and their dialog
- Buy scene carousel UI (no changes in this batch)
- Sound calls (added in parity-2a)

---

## Open questions

None — all answers are in wip source.
