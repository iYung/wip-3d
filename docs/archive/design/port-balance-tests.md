## Goal

Port `/root/wip/tests/test_balance.lua` and `/root/wip/tests/test_golden_lotus.lua` into
`/root/wip-3d/tests/` so they run correctly under `love . --headless tests/<file>.lua`.

The 2D originals drive 1D pixel-position navigation and call a runner API that does not
exist in wip-3d. The 3D port must replace both with angle-based 3D navigation while
keeping the game-logic assertions and balance numbers meaningful.

---

## Affected files

| File | Change |
|------|--------|
| `lua/headless/runner.lua` | Add `runner.fast_forward_until(ctx, condition_fn, elapsed, cap)` |
| `tests/test_balance.lua` | New file — port of wip version |
| `tests/test_golden_lotus.lua` | New file — port of wip version |

No other source files change.

---

## What changes

### 1. `runner.fast_forward_until` added to `lua/headless/runner.lua`

The old 2D runner exposed this as a module function; wip-3d's runner does not.

Signature (matching the 2D version's semantics):

```lua
function runner.fast_forward_until(ctx, condition_fn, elapsed, cap)
    cap = cap or 600
    local iters = 0
    while not condition_fn() do
        if iters >= cap then
            error("fast_forward_until: condition not met after " .. cap .. " simulated seconds")
        end
        runner.tick(ctx, 1, 1.0)   -- ctx is the whole context table (wip-3d convention)
        elapsed = elapsed + 1.0
        iters   = iters + 1
    end
    return elapsed
end
```

Note: wip-3d's `runner.tick(ctx, n, dt)` takes the whole context object, not `(input, sm, n, dt)`.

### 2. Store slot accessor

The 2D tests wrote `ctx.gs.store.slots[n]` directly; wip-3d's `Store` keeps `_slots` private.
Every slot assignment becomes:

```lua
local slots = ctx.gs.store:all_slots()
slots[4].item = Plant.new(1)
```

### 3. Navigation helpers (replacing `walk_to`)

The 2D `walk_to(ctx, target_x, elapsed)` moved the player left/right along a 1D axis using
`move_left`/`move_right` on `ctx.input`.  In 3D, lateral movement is gone; the player is a
3D entity driven by `ctx.move_input` (`forward`/`backward`/`left`/`right`).

**Map geometry that enables simple helpers:**

- All row-1 slot world positions: y = 4.5 (watering can at x=2.5, garbage bin 3.5, PC store 4.5, plant 5.5)
- All row-2 slot world positions: y = 3.5
- Divider wall sits at grid column 7 (world x ≈ 6–7); the passage through it is open at
  floor(y) = 3 and floor(y) = 4, i.e. world y ∈ [3.0, 5.0)
- Both slot rows (y=4.5 and y=3.5) lie inside the passage band — walking east from any
  slot position passes through the divider without a detour
- Cashier threshold: `player3d.x >= 7.0`

**`nav_to(ctx, tx, ty, elapsed)` helper:**

```
1. Instantly set player3d.angle = atan2(ty - p.y, tx - p.x)
2. Hold ctx.move_input:hold("forward")
3. Tick at 1/60 until distance to (tx, ty) < 0.3 grid units
4. Release ctx.move_input:release("forward")
5. Return elapsed
```

Instant angle-setting (rather than simulating turn frames) mirrors 2D semantics — the
player "faces" the destination and then walks. Walk time is fully preserved, which is
essential for test 5 (Speed Upgrade ROI).

**`face_slot(ctx, slot_px)` helper** (used before interact/pick_up_down):

- Navigates to `(slot_px, 5.5)` via `nav_to` — standing 1 unit south of the slot row
- Sets `player3d.angle = -math.pi / 2` (north, toward the slot row)

After positioning, the ray cast inside `store_scene:update` will hit the slot tile at
distance ≈ 1.0 (within `INTERACT_RANGE = 3.0`, above `HOVER_MIN_T = 0.5`), making
`_last_active_slot` non-nil. This happens in the same tick as the input press because
`store_scene:update` runs: (1) player move, (2) ray cast, (3) input handling — all in one
frame.

**`nav_to_cashier(ctx, elapsed)`:**

```
nav_to(ctx, 8.5, 3.5, elapsed)   -- puts player in cashier room (x >= 7.0)
```

No facing required for cashier interactions — `_handle_interact` and `_handle_pick_up_down`
check `player3d.x >= CASHIER_THRESH` only, not slot hover.

### 4. `runner.tick` call signature

2D tests called `runner.tick(ctx.input, ctx.sm, 1, 1/60)`.
3D tests call `runner.tick(ctx, 1, 1/60)`.

### 5. `ctx.gs.player.speed` in test 5 (Speed Upgrade ROI)

The test sets `ctx5.gs.player.speed = speeds[tier_idx]` using the same 2D pixel values
(220, 320, 480, 720). This is correct: `store_scene:update` syncs the 3D move speed as
`gs.player.speed / 220 * 3.0`, so the ratio is preserved and speed differences are
faithfully modelled.

### 6. Buy-scene navigation in `test_golden_lotus`

The 2D test walked to x=500 (PCStore), pressed `interact` to open the shop, then pressed
`move_right` 5 times to reach Golden Lotus (catalogue index 6), then pressed `interact` to
buy.

In 3D: `face_slot(ctx, 4.5)` to face the PC Store at (4.5, 4.5), press `interact` to
open `BuyScene`, then press `move_right` 5 times on `ctx.input` (which `BuyScene` reads),
then press `interact` to buy. The catalogue order is unchanged.

---

## What stays the same

- All game-logic assertions are identical: `ctx.gs.currency >= 20` after 3 grass sales,
  `ctx.gs.currency > 10` after golden lotus sale, all balance print statements.
- `ctx.sm.current._customer` is still the `Customer` object on the current `StoreScene`.
- `fast_forward_until` semantics: 1-second ticks, cap defaults to 600s.
- `sell_plant(ctx, plant_type, elapsed)` helper logic is unchanged (waits for customer
  arrival, dismisses wrong-plant customers, advances dialog, completes sale).
- Plant data, sell values, cooldowns, growth multiplier, and all balance constants are
  unchanged between 2D and 3D.
- The customer state machine is unchanged; `walking_in` and `walking_out` are snapped
  immediately in 3D so `_customer:arrived()` becomes true within one tick of spawning.
- `test_balance.lua` is a benchmark (no assertions, only prints); balance numbers will
  differ slightly from 2D due to 3D navigation geometry but the relative ordering and
  ROI structure must hold.

---

## Open questions

None. All design decisions are resolved from the codebase:

- Navigation approach: instant-angle + real walk time (preserves speed ROI signal).
- Slot accessor: `:all_slots()` already exists.
- Cashier routing: slot rows y=4.5 and y=3.5 lie in the open-passage band — no detour needed.
- Interaction timing: ray cast runs before input handling in the same `update()` frame.
