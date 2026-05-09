# Expand Store Steps

Goal: the PC shop sells two things — a plant and a slot expansion. The player spends currency on either. Buying an expansion calls `store:grow()` and a new slot appears at the right end. A sell bin station lets the player sell stage-3 plants for currency.

---

## Mechanic Summary

| Action | Result |
|--------|--------|
| Open shop (F on PC) | BuyScene opens; two options: Plant / Expand Slot |
| A / D in shop | Move cursor between options |
| F on Plant | Deduct `PLANT_COST`, plant goes into player's hand, return to store |
| F on Expand Slot | Deduct `SLOT_COST`, one new slot added at right end, return to store |
| E anywhere in shop | Cancel, return to store |
| F when insufficient funds | Nothing (option shown greyed out) |
| Hold stage-3 plant + E on sell bin slot | Plant sold for `SELL_VALUE`, currency increases, hand emptied |
| Hold non-stage-3 item + E on sell bin slot | Nothing |

---

## Step 1 — Currency

- [ ] Add `PLANT_COST = 5`, `SLOT_COST = 10`, and `SELL_VALUE = 5` to `lua/game/config.lua`
- [ ] Set `self.currency = 20` in `GameState.new()` (starting funds)
- [ ] In `StoreScene:draw()` add a HUD line: `"Currency: " .. gs.currency`

---

## Step 2 — Buy Scene Menu

- [ ] Add `self.selected = 1` to `BuyScene.new()` (1 = Plant, 2 = Expand Slot)
- [ ] In `BuyScene:update(dt)`:
  - `move_left` pressed → `self.selected = 1`
  - `move_right` pressed → `self.selected = 2`
  - `interact` pressed → call `self:_confirm()`, then switch back to store scene
  - `pick_up_down` pressed → switch back to store scene (cancel, unchanged)
- [ ] Replace `_buy_plant()` with `_confirm()`:
  - If `selected == 1` and `currency >= PLANT_COST`: deduct cost, give plant to player
  - If `selected == 2` and `currency >= SLOT_COST`: deduct cost, call `store:grow()`
  - Otherwise: do nothing (no scene switch)
- [ ] In `BuyScene:draw()`:
  - Show both options side by side (or stacked); highlight the selected one
  - Show price next to each; grey it out if player can't afford it
  - Show current currency

---

## Step 3 — Sell Bin

- [ ] Create `lua/game/items/sell_bin.lua`
  - `carriable = false`
  - Sprite: red (e.g. `{0.9, 0.2, 0.2, 1}`)
  - No `interact()` needed — sale is triggered from `_handle_pick_up_down`
- [ ] In `StoreScene:_handle_pick_up_down()`, before the normal placement path:
  - If player is holding a plant at `stage == 3` AND target slot has a SellBin:
    - Add `SELL_VALUE` to `game_state.currency`
    - Set `player.held_item = nil`
    - Return early
- [ ] Require `SellBin` in `store_scene.lua`
- [ ] Place `SellBin.new()` in slot 2 in `StoreScene:_setup_store()`

---

## Step 4 — End-to-End Test

- [ ] Open shop with 20 currency — both options visible and priced
- [ ] Select Plant (A), buy with F — plant in hand, currency drops by 5
- [ ] Grow plant to stage 3, walk to sell bin, press E — currency goes up by 5, hand emptied
- [ ] Open shop again, select Expand (D), buy with F — new slot appears at right end, currency drops by 10
- [ ] Walk into the new slot, place a plant — confirms slot is live
- [ ] Try selling a non-stage-3 plant at sell bin — nothing happens
- [ ] Drain currency to 0, confirm neither buy option fires
- [ ] Press E in shop — returns to store with no change
