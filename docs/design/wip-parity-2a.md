# wip → wip-3d Parity Gap 2a

Sound, accessories, and speech bubble wrapping.
Last audited: 2026-06-02. Follows `docs/archive/wip-parity.md`.

---

## Goal

Three independent, self-contained ports from wip:
1. Sound system — all player-action audio
2. Accessory assets + script wiring — correct accessories on existing characters
3. Speech bubble text wrapping — prevent dialog overflow

---

## Affected files

| # | File | Change |
|---|------|--------|
| 1 | `lua/game/sound.lua` | New — copy from wip verbatim |
| 1 | `lua/headless/stubs.lua` | Add `love.audio` stub |
| 1 | `main.lua` | Add `Sound.load()` in `love.load`; add `sound` require |
| 1 | `lua/game/scenes/store_scene.lua` | Add `Sound.play()` calls |
| 1 | `lua/game/scenes/buy_scene.lua` | Add `Sound.play()` calls |
| 1 | `lua/game/scenes/start_scene.lua` | Add `Sound.play()` calls |
| 1 | `lua/game/items/plant.lua` | Emit `plant_ready`; return bool from `:water()` |
| 1 | `lua/game/items/watering_can.lua` | Play `water_plant` when `:water()` returns true |
| 1 | `lua/game/items/grafter.lua` | Play `clone_success` / `clone_fail` |
| 1 | `assets/sounds/` (17 wav files) | Copy from `wip/assets/sounds/` |
| 2 | `assets/accessories/secretary_glasses.png` | Copy from `wip/assets/secretary_glasses.png` |
| 2 | `assets/accessories/shades.png` | Copy from `wip/assets/shades.png` |
| 2 | `assets/accessories/clown.png` | Copy from `wip/assets/clown.png` |
| 2 | `assets/accessories/monocle.png` | Copy from `wip/assets/monocle.png` |
| 2 | `lua/game/data/customer_scripts.lua` | Add `accessory` field to Mayor Bloom, The Collector, Dottie, Mira |
| 3 | `lua/game/customer.lua` | Add `MAX_BOX_W` + `font:getWrap` bubble sizing |

---

## What changes

### 1. Sound system

**Port `lua/game/sound.lua` verbatim from wip.** The module loads 17 `.wav` files at startup and plays them on demand via `Sound.play(name)`. Both functions early-return when `love.audio` is nil (headless safety).

Sound event names:
`pick_up`, `put_down`, `sell_plant`, `dismiss_customer`, `dialogue_advance`, `dialogue_skip`, `discard_plant`, `open_shop`, `water_plant`, `plant_ready`, `clone_success`, `clone_fail`, `shop_navigate`, `shop_buy`, `shop_close`, `menu_navigate`, `menu_confirm`

**`lua/headless/stubs.lua`** — add `love.audio` stub matching wip's version (newSource returns a clonable stub, play is a no-op).

**`main.lua`** — add `local Sound = require("lua/game/sound")` and call `Sound.load()` inside `love.load` (after the `GameState.new()` line).

**`lua/game/items/plant.lua`** — `Plant:water()` must return `true` after advancing a stage and `false` on early-return guards; add `Sound.play("plant_ready")` when `self.ready = true`.

**`lua/game/items/watering_can.lua`** — call `Sound.play("water_plant")` when `slot.item:water()` returns `true`.

**`lua/game/items/grafter.lua`** — call `Sound.play("clone_success")` after placing the clone; `Sound.play("clone_fail")` in the no-slot branch.

**`lua/game/scenes/store_scene.lua`** — add calls matching wip:
- `_handle_pick_up_down`: `pick_up` after picking up, `put_down` after putting down, `dismiss_customer` after `customer:dismiss()`
- `_handle_interact`: `discard_plant` after garbage-bin discard, `sell_plant` after `customer:serve()`, `dialogue_skip` after `skip_reveal()`, `dialogue_advance` after `customer:advance()`, `open_shop` when pc_store triggers a scene switch

**`lua/game/scenes/buy_scene.lua`** — add calls matching wip: `shop_navigate` on A/D, `shop_close` on E, `shop_buy` on successful buy.

**`lua/game/scenes/start_scene.lua`** — add calls matching wip: `menu_navigate` on up/down, `menu_confirm` at start of `_confirm`.

**`assets/sounds/`** — copy all 17 wav files from `wip/assets/sounds/`.

### 2. Accessory assets + script wiring

wip-3d's `customer_scripts.lua` currently only assigns `accessory = "flat_cap"` to Old Pete. The other characters go without accessories, but wip assigns distinct ones to each.

**Copy these files from `wip/assets/` → `wip-3d/assets/accessories/`:**
- `secretary_glasses.png`
- `shades.png`
- `clown.png`
- `monocle.png` (needed now for Dottie; also required for Sage in parity-2b)

**Update `lua/game/data/customer_scripts.lua`** to add `accessory` fields matching wip:
- Mayor Bloom (both chapters): `accessory = "secretary_glasses"`
- The Collector (both chapters): `accessory = "shades"`
- Dottie (all 3 chapters): `accessory = "clown"`
- Mira (chapter 1): `accessory = "hair_bow"` (file already exists)

### 3. Speech bubble text wrapping

wip's `customer.lua` dynamically sizes the speech bubble using `font:getWrap`. Long lines wrap instead of overflowing the screen. wip-3d's version uses a fixed bubble size.

**`lua/game/customer.lua`** — port the wrapping approach from wip verbatim:
- Add `MAX_BOX_W = 18 * U` constant near `MIN_BOX_W`
- In the bubble draw/layout code, replace fixed sizing with `font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)` to compute wrapped lines and derive `box_w` and `box_h`
- Same wrap applied to the `revealed` substring for typewriter reveal

---

## What stays the same

- Customer walk animation and state machine
- All 3D raycaster rendering
- Buy scene carousel logic (only sound calls added)
- All items and slot logic (only minor returns/calls added to plant.lua and watering_can.lua)

---

## Open questions

None — all answers are in wip source.
