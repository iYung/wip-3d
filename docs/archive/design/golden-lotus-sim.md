# Golden Lotus Economy Simulation

## Goal

Write a headless integration test that simulates the full economic loop of starting
with $10 gold and working up to buying and selling a Golden Lotus. The test measures
the total in-game time elapsed and prints a step-by-step log, so the team can reason
about early-game pacing.

## Affected files

- `tests/integration/golden_lotus_sim_test.lua` *(new)* — the simulation test
- `lua/test/runner.lua` — add new test path to `TEST_PATHS`

## What changes

### Simulation parameters (encoded at top of test file)

| Parameter | Value |
|---|---|
| Starting currency | $10 |
| Plant slots | 7 (slots 4–10; slots 1–3 are occupied by tools in the real store) |
| Strategy | Greedy — each fill-pass buys the most expensive affordable plant per slot |
| Customer spawn | Random 3–6 s, via `math.random(3, 6)` |
| Customer plant request | Random pick from `gs.unlocked_plants` (same logic as `_next_customer_cfg`) |
| Random seed | Fixed (`math.randomseed(42)`) for reproducibility |
| Growth multiplier | 1.0 (no upgrades) |

### Simulation loop (event-driven, no fixed dt)

The test does **not** use `StoreScene` (too much input/movement complexity). Instead it
drives `Plant` objects and the customer logic directly:

```
time = 0
slots = array of 7 nils
unlocked_plants = {}
pending_sales = {}   -- stage-3 plants waiting for a customer
customer_timer = nil -- countdown until next customer spawns, or nil

loop:
  1. FILL — for each empty slot:
       best = most expensive plant whose cost <= gs.currency
       if best: create Plant.new(best), deduct cost, unlock type
  
  2. NEXT EVENT — compute dt = min of:
       · remaining cooldown for any stage < 3 plant
       · customer_timer (if set)
     if no event can happen: break with error (deadlock)
  
  3. ADVANCE — time += dt
       for each slot plant: plant:update(dt)
       if customer_timer: customer_timer -= dt
  
  4. WATER — for each plant where plant.ready and plant.stage < 3:
       plant:water()
  
  5. STAGE-3 HARVEST — for each slot where plant.stage == 3:
       move plant to pending_sales, clear slot
       if customer_timer == nil: customer_timer = math.random(3, 6)
  
  6. CUSTOMER ARRIVES — if customer_timer <= 0:
       pick random plant type from unlocked_plants
       find first matching pending_sale
       if match:
         gs.currency += plant_sell_value(sale)
         log the sale with current time
         if sale.plant_type == 6: set sold_lotus = true
       customer_timer = math.random(3, 6)  -- always schedule next customer
  
  7. END — if sold_lotus: break
```

### Output (printed to stdout by the test)

```
[t=  0.00s]  BUY  Tulip           $10  →  $0    (slot 4)
[t= 11.00s]  HARV Tulip           stage 3         (slot 4)
[t= 14.00s]  SELL Tulip           +$20 → $20      (customer arrived)
[t= 14.00s]  BUY  Golden Lotus    $20  →  $0    (slot 4)
[t= 19.00s]  HARV Golden Lotus    stage 3         (slot 4)
[t= 24.50s]  SELL Golden Lotus    +$40 → $40      (customer arrived)

Total time: 24.50s
```
(Exact numbers will vary with seed; above is illustrative.)

### Assertions

```lua
T.assert(sold_lotus, "Golden Lotus was sold")
T.assert(total_time > 0, "non-zero time elapsed")
T.assert(gs.currency >= 40, "currency reflects the sale")
```

The test is intentionally not strict about *how long* it takes — the point is to
*measure* it, not enforce a budget. The log output is the deliverable.

## What stays the same

- All game source files are unmodified — the simulation reuses `Plant`, `PLANT_DATA`,
  `GameState`, and `plant_sell_value` logic copied inline (since it's a private
  function in `store_scene.lua`).
- The real `StoreScene`, `Customer`, and `HeadlessInput` are not involved.
- The normal `love .` game path is unchanged.

## Open questions

None — user confirmed: all 7 slots, real customer simulation, greedy strategy.
