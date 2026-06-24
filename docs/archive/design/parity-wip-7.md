## Goal

Bring `wip-3d` to parity with `../wip` for features shipped since parity-5/6. Eleven behavioral gaps identified by diffing every changed file. Save/Load and the 4-track background music system are deferred — the 3D repo has a single looping background track which works fine and the infrastructure diff is large.

---

## Affected files

| File | Gap |
|------|-----|
| `lua/game/data/customer_scripts.lua` | 871 lines in wip vs 517 in wip-3d; 16 missing entries across 6 characters; Mayor Bloom ch4, mechafrog ch4, dottie ch4, agent_frogsby ch4, sage ch5, romeo ch4, glen ch4, chef_brio ch1-4, dj_frogga ch1-2, wallace ch1-3; updated dialogue text on existing entries |
| `lua/game/data/plant_data.lua` | Rebalanced sell prices, costs, and cooldowns for all 6 plant types |
| `lua/game/data/growth_tiers.lua` | 1 tier → 4 tiers in wip |
| `lua/game/scenes/store_scene.lua` | Missing: `_last_script_id` tracking to prevent same character appearing twice in a row |
| `lua/game/scenes/settings_menu.lua` | Missing: hide "Leave Game" item when settings opened from start screen (opaque mode) |
| `lua/game/items/golden_idol.lua` | New file — purchasable Golden Idol item that triggers WinScene |
| `lua/game/scenes/win_scene.lua` | New file — win/credits scene showing play time to first idol purchase |
| `lua/game/scenes/buy_scene.lua` | Golden Idol shop entry; play_time tracking; `first_idol_at` recording; display_cost shows raw number (wip uses `"$"` prefix); coin icon layout for price display |
| `lua/game/game_state.lua` | Missing: `play_time = 0`, `first_idol_at = nil` fields |
| `lua/game/items/pc_store.lua` | Name field: wip uses `"Laptop"`, wip-3d uses `"PC Store"` |
| `lua/game/items/grafter.lua` | Clone-fail sound: wip uses `"fail"`, wip-3d uses `"clone_fail"` |
| `lua/game/customer.lua` | Typewriter rendering: wip uses full-text wrap points with byte-offset tracking to avoid word-wrap flicker; wip-3d uses simpler `getWrap(revealed)` |
| `main.lua` | Missing `love.mouse.setVisible(false)` call; missing `love.focus` handler to resume music after alt-tab |
| `lua/game/assets.lua` | Missing: `A.golden_idol`, `A.win_scene`, `A.coin`; heat_lamps array hardcoded to 3 levels (wip has 6); missing `A.btn_a/b/y`, `A.dpad_*` gamepad icon assets |
| `assets/` | Missing image files: `golden_idol.png`, `win_scene.png`, `coin.png`; missing accessories: `anon.png`, `chef_fit.png`, `neckbeard.png` |

---

## What changes

### 1 — customer_scripts.lua — copy verbatim from wip (871 lines)

wip's file is 871 lines vs wip-3d's 517. Copy verbatim. The wip-3d file was previously copied from a 517-line snapshot; wip has since added new characters and extended arcs.

**New/extended entries missing in wip-3d:**

| Character | Missing chapters |
|-----------|-----------------|
| mayor_bloom | ch4 (Golden Lotus arc — "Mayor Bloom to you now!") |
| mechafrog | ch4 (Head Gardener promotion arc) |
| dottie | ch4 (circus clown ch4 arc) |
| agent_frogsby | ch4 (Agent Frogsby ch4 arc) |
| sage (Sir Moneyton) | ch5 (shoe speed hint arc, triggers at rose count 5) |
| romeo | ch4 (romeo ch4 arc) |
| glen | ch4 (glen ch4 arc) |
| chef_brio | ch1-4 (entire 4-chapter chef arc — completely absent in wip-3d) |
| dj_frogga | ch1-2 (entire 2-chapter DJ arc — completely absent in wip-3d) |
| wallace | ch1-3 (entire 3-chapter arc — completely absent in wip-3d) |

Also updates:
- Mayor Bloom ch1-3 dialogue updated (more campaign-focused, PR agent lines added)
- The Collector ch1-2: accessory changed from `"shades"` to `"anon"`, trigger count adjusted, dialogue updated
- mayor_bloom ch1 trigger changed from `{ plant_type = 3, count = 20 }` to `{ plant_type = 5, count = 4 }`
- Various other trigger tuning (Mira, Wallace) matching wip

New accessories referenced (chef_brio uses `"chef_fit"`, wallace uses `"neckbeard"`, the_collector uses `"anon"`) — corresponding `.png` files must also be copied.

### 2 — plant_data.lua — rebalanced economy

Copy verbatim from `../wip/lua/game/data/plant_data.lua`. The prices in wip-3d were an earlier unbalanced version; wip has since tuned them for the late-game economy (golden idol requires $4000):

| Plant | wip sell | wip-3d sell | wip cost | wip-3d cost |
|-------|----------|-------------|----------|-------------|
| Grass | $3 | $5 | $0 | $1 |
| Cactus | $8 | — (same) | $5 | $3 |
| Rose | $20 | $13 | $20 | $6 |
| Tulip | $50 | $20 | $75 | $10 |
| Daisy | $200 | $28 | $300 | $15 |
| Golden Lotus | $400 | $40 | $700 | $20 |

Cooldowns also differ: wip has longer cooldowns for higher-tier plants (e.g. Daisy: `{15, 45}` vs `{3, 5}`).

### 3 — growth_tiers.lua — expand to 4 tiers

wip has 4 growth tiers, wip-3d has only 1. Copy verbatim from `../wip/lua/game/data/growth_tiers.lua`:

```lua
return {
    { cost = 100, mult = 1.95 },
    { cost = 200, mult = 2.30 },
    { cost = 350, mult = 2.65 },
    { cost = 500, mult = 3.00 },
}
```

### 4 — store_scene.lua — prevent same character twice in a row

wip's `_next_customer_cfg` tracks `self._last_script_id` and excludes the last-seen character from the `pool` of qualified scripts. If only that character qualifies, it falls through to a generic customer.

wip-3d's `_next_customer_cfg` picks randomly from all qualified scripts with no deduplication.

**Change**: In `StoreScene.new`, add `self._last_script_id = nil`. In `_next_customer_cfg`, after building `qualified`, build a filtered `pool` excluding `script.id == self._last_script_id`. If `#pool > 0` pick from pool; otherwise fall through. On pick, set `self._last_script_id = script.id`. On dismiss (or when active script key cleared), set `self._last_script_id = nil`.

### 5 — settings_menu.lua — hide "Leave Game" on start screen

wip's `_visible_items` function excludes item 7 ("Leave Game") when `opaque == true` (settings opened from the start screen). wip-3d always shows all 6 items and only renames item 6 to "Main Menu" in-game.

**Change**: When `self._opaque == true`, skip drawing/selecting item 6 ("Leave Game"). Since wip-3d has 6 items (no "Save Game"), the mapping is: hide item 6 when opaque. The navigation should skip item 6 when opaque (so the last selectable item is item 5 "Exit Settings").

### 6 — golden_idol.lua — new item

Create `lua/game/items/golden_idol.lua`. Copy from `../wip/lua/game/items/golden_idol.lua` and adapt for 3D: the 2D version uses `Sprite` and references `U` (pixel units); the 3D version needs only a flat sprite reference for the billboard renderer.

The item's key field is `self.win_scene_factory = nil` (set by `store_scene._wire_golden_idol`). Its `interact` method calls `scene_manager:switch(self.win_scene_factory())` when the factory is set.

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

Copy `assets/golden_idol.png` from `../wip/assets/images/golden_idol.png`.

### 7 — win_scene.lua — new scene

Create `lua/game/scenes/win_scene.lua`. The win scene shows a full-screen victory image with a text box displaying play time to first idol purchase. Pressing cancel returns to the store.

The 3D adaptation:
- Use `Scene3D.new()` or the plain `Scene.new()` base (no 3D rendering needed — it's a 2D overlay)
- The `_wire_golden_idol` + `WinScene` factory pattern from wip can be ported directly
- The scene needs: `A.win_scene` image, `A.speech_bubble`, fonts, `gs.first_idol_at`
- Replace `UI.draw9` with the inline `draw9` function (same as `customer.lua` already does in wip-3d)
- Replace `Fonts.new(22)` with `love.graphics.newFont(22)`
- The `WinBg` shader reference — copy `../wip/lua/game/shaders/win_bg.lua` if it doesn't exist in wip-3d, otherwise use as-is
- Icon hints (`cancel_icon`) use `self.input:icon_key_for("cancel")` — same API exists in wip-3d

Copy `assets/win_scene.png` from `../wip/assets/images/win_scene.png`.

### 8 — buy_scene.lua — Golden Idol entry + play_time tracking + price display

Three changes:

**a) Golden Idol catalogue entry**: Add after the Water Drone entry:
```lua
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Golden Idol",
    description = "A shiny golden idol.\nPurely decorative.",
    cost        = 4000,
    kind        = "golden_idol",
    image       = A.golden_idol,
}
```

**b) play_time tracking**: In `BuyScene:update(dt)`, add `self.game_state.play_time = self.game_state.play_time + dt`. This counts time spent in the shop toward the first-idol timer.

**c) `_confirm()` handler for `"golden_idol"` kind**: After the plant handler block:
```lua
elseif kind == "golden_idol" then
    gs.first_idol_at = gs.first_idol_at or gs.play_time
    gs.player.held_item = GoldenIdol.new()
    Sound.play("shop_buy")
    self.scene_manager:switch(self.store_scene)
```

Add `local GoldenIdol = require("lua/game/items/golden_idol")` at the top.

**d) Price display format**: wip shows `"$"..cost` (e.g. `"$15"`) while wip-3d shows the raw number. Change `display_cost = "$" .. tier.cost` for speed/growth/cooldown tiers, and `display_cost = "$" .. ent.cost` for catalogue entries, to match wip. (Note: the `"---"` sold-out display stays as-is.)

### 9 — game_state.lua — play_time and first_idol_at fields

In `GameState.new()`, add two fields after `self.has_drone = false`:
```lua
self.play_time     = 0
self.first_idol_at = nil
```

### 10 — store_scene.lua — wire Golden Idol and track play_time

**a) Wire Golden Idol**: Add `local WinScene = require("lua/game/scenes/win_scene")` and `local GoldenIdol = require("lua/game/items/golden_idol")` at the top. Add `self:_wire_golden_idol()` call in `on_enter`. Add the `_wire_golden_idol` method:

```lua
function StoreScene:_wire_golden_idol()
    local gs = self.game_state
    local self_ref = self
    if not self._win_scene then
        self._win_scene = WinScene.new(gs, self.input, self.scene_manager, self)
    end
    local function win_factory() return self_ref._win_scene end
    self._win_scene_factory = win_factory
    for _, slot in ipairs(gs.store:all_slots()) do
        if slot.item and slot.item.name == "Golden Idol" then
            slot.item.win_scene_factory = win_factory
        end
    end
    if gs.player.held_item and gs.player.held_item.name == "Golden Idol" then
        gs.player.held_item.win_scene_factory = win_factory
    end
end
```

**b) play_time tracking**: In `StoreScene:update(dt)`, add `gs.play_time = gs.play_time + dt` near the top (after `local gs = self.game_state`).

### 11 — items/pc_store.lua — rename to "Laptop"

In `PCStore.new`, change `self.name = "PC Store"` to `self.name = "Laptop"`. This matches wip; the name is used by save/load item serialization which wip-3d will eventually need.

### 12 — items/grafter.lua — change clone-fail sound to "fail"

Change `Sound.play("clone_fail")` to `Sound.play("fail")`. wip removed the separate `clone_fail` event and uses the generic `fail` sound. The `clone_fail.wav` file exists in wip-3d's assets and can stay (it just won't be triggered).

### 13 — customer.lua — typewriter word-wrap fix

wip improved the typewriter text rendering to avoid word-wrap flicker. The wip approach: wrap the **full** text to get the stable line list, then walk those lines with a byte-offset counter to find how many characters of each line are revealed.

wip-3d uses the simpler approach: `font:getWrap(revealed, MAX_BOX_W)` which can cause the last partial word to jump between lines as it fills in.

Replace the revealed-lines block in `Customer:draw()`. Use the wip approach:
1. `local _, lines = font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` (wrap full text)
2. Walk `lines` with a `remaining = idx` counter; for each line take `math.min(remaining, #trimmed)` chars, decrement by `#line` (including trailing space for word-wrap accounting)
3. Render `rendered_lines` instead of `revealed_lines`

The exact implementation is in `/root/wip/lua/game/customer.lua` lines 305-342.

### 14 — main.lua — hide OS cursor + focus handler

**a) Hide cursor**: Add `love.mouse.setVisible(false)` in `love.load()`. wip does this unconditionally at startup.

**b) Focus handler**: Add:
```lua
function love.focus(focused)
    Sound.on_focus(focused)
end
```
`Sound.on_focus` is already defined in wip-3d's `sound.lua` (well, not yet — see below).

**c) Sound.on_focus**: Add to `lua/game/sound.lua`:
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
This also requires adding `playing_intent` tracking to music track entries (set to `true` in `fade_music` when volume > 0, `false` in `stop_music`).

### 15 — assets.lua — missing assets

**a) Golden Idol and Win Scene images**:
```lua
A.golden_idol = img("assets/golden_idol.png")
A.win_scene   = img("assets/win_scene.png")
A.coin        = img("assets/coin.png")
```

**b) Heat lamp levels**: Change the heat_lamps loop from `for lvl = 1, 3` to `for lvl = 1, 6` (wip supports 6 heat lamp upgrade levels, wip-3d capped at 3). Copy `heat_lamp_4.png`, `heat_lamp_5.png`, `heat_lamp_6.png` from `../wip/assets/images/`.

**c) Gamepad button icons**: wip uses `A.btn_a`, `A.btn_b`, `A.btn_y`, `A.dpad_up/down/left/right` for HUD hints. wip-3d's assets.lua doesn't load them. Add:
```lua
A.btn_a      = img("assets/btn_a.png")
A.btn_b      = img("assets/btn_b.png")
A.btn_y      = img("assets/btn_y.png")
A.dpad_up    = img("assets/dpad_up.png")
A.dpad_down  = img("assets/dpad_down.png")
A.dpad_left  = img("assets/dpad_left.png")
A.dpad_right = img("assets/dpad_right.png")
```
Copy those PNG files from `../wip/assets/images/`.

### 16 — accessories — new PNG files

Copy these accessory images from `../wip/assets/images/` to `assets/accessories/`:
- `anon.png` — used by The Collector
- `chef_fit.png` — used by Chef Brio
- `neckbeard.png` — used by Wallace

---

## What stays the same

- All 3D rendering, raycasting, `scene_3d.lua`, `player_3d.lua`, `map.lua`, `store.lua`, `slot.lua` — untouched
- `headless/runner.lua` and `headless/input.lua` — no changes needed
- `sound.lua` overall structure — only additive changes (on_focus, playing_intent)
- Multi-track background music: wip has 4 tracks (bg1-bg4, non-looping, random), wip-3d has 1 looping track — deferred; the 3D background music works and the 4-track system requires asset copies of 3 additional music files
- Save/Load — deferred to its own doc
- Customer walk speed via cooldown tiers — 3D uses a fixed `CUST_WALK_SPEED` constant; 2D passes `cfg.walk_speed`; 3D-specific, no port needed
- `cooldown_tiers.lua` `walk_speed` field — 3D ignores it; leave as-is
- `settings_menu.lua` Save Game button — not needed without save/load
- `settings_menu.lua` on_save / on_leave callbacks — not needed without save/load
- HUD hint rendering in `buy_scene.lua` and `store_scene.lua` — already 3D-adapted
- Start scene "Continue" button (save slot) — deferred with save/load
- `win_scene.lua` WinBg shader — check if it exists in wip-3d; if so use it; if not copy from wip

---

## Open questions

1. **WinBg shader**: `/root/wip/lua/game/shaders/win_bg.lua` is referenced by `win_scene.lua`. Does wip-3d already have this shader? It does not appear in the assets list. Copy it from wip or make win_scene skip the shader effect.

2. **Price display format (`"$"` prefix)**: wip-3d currently shows raw numbers (e.g. `"15"`) while wip shows `"$15"`. Changing this is purely cosmetic but aligns the UX. Included in Gap 8d — skip if it causes test breakage.

3. **Settings menu "Leave Game" hide when opaque**: wip-3d currently shows the item and lets it quit the game from the start screen. Whether this behavior is intentional for the 3D version (the game always runs, no "leave to OS" from title screen) is unclear. Included as Gap 5 — can be skipped if intentional.
