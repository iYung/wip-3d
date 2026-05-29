# Customer Walk Animation

## Goal

Customers currently teleport into the cashier zone. They should walk in from the left wall of the cashier room and walk back out the same way — matching the 2D behaviour in `../wip`.

## Affected files

- `lua/game/scenes/store_scene.lua` — only file that changes

## What changes

### 3D position tracking (store_scene)

`store_scene` currently draws the customer billboard at a hardcoded `(CASHIER_POS_X, CASHIER_POS_Y)`. Replace that with a tracked `_cust_3d_x` that animates during walk-in and walk-out. `CASHIER_POS_Y` stays fixed.

- **Entry point**: `CASHIER_ENTRY_X = 1.5` (just inside the left wall, x=1)
- **Stand position**: `CASHIER_POS_X = 6.0` (unchanged)
- **Walk speed**: `CUST_WALK_SPEED = 2.5` grid units/s → 5 units takes ~2 s

### Animation state (_cust_anim)

Replace the snap hack (lines 225–232 that force `walking_in → waiting` and `walking_out → idle` in one frame) with a `_cust_anim` string: `"in"`, `"out"`, or `nil`.

| _cust_anim | meaning |
|---|---|
| `"in"` | walking from left wall to stand position |
| `"out"` | walking back to left wall |
| `nil` | not animating |

### Walk frame animation

While `_cust_anim ~= nil`, the billboard image alternates between `A.customer` (idle pose) and `A.customer_walk` at 0.15 s intervals, matching the timer cadence from `customer.lua`. Frame state: `_cust_walk_timer`, `_cust_walk_frame` (bool).

### Preventing customer.lua auto-transitions

`customer.lua` drives state transitions by comparing `self.x` against `target_x` / `exit_x`. The current constructor call `Customer.new(0, -1, 0)` puts target and exit so close together that walking_in → waiting and walking_out → idle both complete in < 1 frame, which is what the snap hack was compensating for.

Change the call to `Customer.new(100, -1000, 0)`. With SPEED=80 px/s, `customer.lua` now takes ~14 s to reach either boundary — far longer than any walk animation — so it never auto-transitions. `store_scene` manually sets `state`, `bubble.visible`, `sprite.visible` at animation completion:

- Walk-in done → `state = "waiting"`, `bubble.visible = true`
- Walk-out done → `state = "idle"`, `sprite.visible = false`, `bubble.visible = false`, `heart_bubble.visible = false`

### Update loop ordering (store_scene:update)

1. **Detect walking_out** before calling `customer:update()` — `serve()` / `dismiss()` were called at the end of the previous frame's input handling; checking at the top of update catches the transition cleanly.
2. Call `customer:update(dt)` — handles typewriter reveal; x movement is harmless.
3. **Advance `_cust_3d_x`** and toggle walk frame if `_cust_anim ~= nil`.
4. Apply manual state overrides when animation completes.
5. **Spawn timer** — guard with `not customer:active() and not _cust_anim`.

### Guards on existing cashier logic

Anywhere the code currently checks `customer:arrived()` for interaction or the player-in-cashier condition, add `and not self._cust_anim` — the player should not be able to interact while the customer is walking in or out.

Affected call sites:
- `_handle_pick_up_down` — cashier branch
- `_handle_interact` — cashier branch
- `_hud_labels` — `in_cash` label condition
- Billboard draw — gate on `customer:active() or self._cust_anim ~= nil`

### Dialog draw

`_draw_customer_dialog` already guards on `bubble.visible`, which is false during walk-in (state = `"walking_in"`, bubble never set). No change needed there.

## What stays the same

- `customer.lua` — no changes; state machine, typewriter, serve/dismiss logic all unchanged
- `CASHIER_POS_Y`, `CASHIER_POS_X` (stand position), `CASHIER_THRESH`
- All cashier interaction logic (sell, dismiss, advance dialog)
- Spawn timer interval (3–6 s random)
- Billboard color replace shader (setup/teardown callbacks unchanged)
- All other scenes and game systems

## Open questions

None.
