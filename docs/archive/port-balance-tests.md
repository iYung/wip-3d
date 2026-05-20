## Port Balance Tests Checklist

- [x] Task A — `lua/headless/runner.lua` — Add `runner.fast_forward_until(ctx, condition_fn, elapsed, cap)` at the bottom of the file (before `return runner`). Signature and body must match the design doc exactly: 1-second ticks via `runner.tick(ctx, 1, 1.0)`, optional `cap` defaulting to 600, `error()` on cap exceeded, returns updated `elapsed`. No other changes to this file.

- [x] Task B — `tests/test_balance.lua` — Create this new file as a 3D port of `/root/wip/tests/test_balance.lua`. **Depends on Task A** (uses `runner.fast_forward_until`). Details:
  - Set `math.randomseed(42)` at the top.
  - Require `runner`, `StoreScene`, and `Plant` using the wip-3d paths.
  - Define `nav_to(ctx, tx, ty, elapsed)`: instantly set `ctx.scene.player3d.angle = math.atan2(ty - p.y, tx - p.x)`, hold `ctx.move_input:hold("forward")`, tick at 1/60 until distance to `(tx, ty)` < 0.3, release `ctx.move_input:release("forward")`, return `elapsed`.
  - Define `face_slot(ctx, slot_px, elapsed)`: call `nav_to(ctx, slot_px, 5.5, elapsed)`, then set `ctx.scene.player3d.angle = -math.pi / 2`, return `elapsed`.
  - Define `nav_to_cashier(ctx, elapsed)`: call `nav_to(ctx, 8.5, 3.5, elapsed)`.
  - Define `sell_plant(ctx, plant_type, elapsed)`: identical logic to the 2D original but use `runner.fast_forward_until(ctx, ...)` (module-level, not local) and `runner.tick(ctx, 1, 1/60)`.
  - Access slot 4 via `ctx.gs.store:all_slots()[4].item = Plant.new(...)` (not `ctx.gs.store.slots[4]`).
  - Replace every `walk_to` call with the appropriate `face_slot` / `nav_to` / `nav_to_cashier` call using the 3D world coordinates from the design doc (watering can x=2.5, plant slot x=5.5, cashier at 8.5,3.5).
  - Use `runner.tick(ctx, 1, 1/60)` everywhere (not `runner.tick(ctx.input, ctx.sm, ...)`).
  - Implement Tests 1 (progression pace), 2 (gold-per-minute), 4 (growth multiplier), and 5 (speed upgrade ROI) with all print statements matching the 2D originals. No assertions — this file is a benchmark only.
  - Test 5 sets `ctx5.gs.player.speed = speeds[tier_idx]` using the same pixel values `{[0]=220, [1]=320, [2]=480, [3]=720}`.

- [x] Task C — `tests/test_golden_lotus.lua` — Create this new file as a 3D port of `/root/wip/tests/test_golden_lotus.lua`. **Depends on Task A** (uses `runner.fast_forward_until`). Details:
  - Set `math.randomseed(42)` at the top.
  - Require `runner` and `StoreScene` using the wip-3d paths.
  - Define `nav_to`, `face_slot`, `nav_to_cashier`, and `sell_plant` with the same implementations as in Task B.
  - Set up `ctx` with `ctx.gs.currency = 10` (default slot layout: slot 4 at world x=5.5 already has a grass plant from `all_slots()[4]`).
  - Replace the 3-iteration grass-sale loop: each iteration uses `face_slot(ctx, 4.5, elapsed)` to face the PC Store, presses `ctx.input:press("interact")` twice (open BuyScene, immediately back — matching the 2D "open and close" pattern before walking to slot 4), then `face_slot(ctx, 5.5, elapsed)` to pick up the watering can from slot 1 at world x=2.5 (adjust coordinates per design doc geometry), waters twice waiting for `ready` each time, returns watering can, picks up plant from slot 4, navigates to cashier via `nav_to_cashier`, calls `sell_plant(ctx, 1, elapsed)`.
  - After the 3 grass sales: `assert(ctx.gs.currency >= 20, ...)`.
  - Golden Lotus purchase: `face_slot(ctx, 4.5, elapsed)` to face the PC Store, press `ctx.input:press("interact")` to open `BuyScene`, press `ctx.input:press("move_right")` 5 times (one per tick at 1/60), press `ctx.input:press("interact")` to buy (catalogue index 6 = Golden Lotus, unchanged from 2D).
  - Water and sell the Golden Lotus plant using the same nav helpers.
  - `assert(ctx.gs.currency > 10, ...)` and print timing + `"PASS: golden lotus timing"`.
  - Use `runner.fast_forward_until(ctx, ...)` (module-level) and `runner.tick(ctx, 1, 1/60)` throughout.
  - Access slots via `ctx.gs.store:all_slots()[n]`.

Tasks B and C are independent of each other and can run in parallel once Task A is complete.
