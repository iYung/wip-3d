# Store Hover Dead Zone Fix

## Goal

Fix two related bugs in store_scene.lua that prevent slot highlighting (and therefore
item placement) in the row immediately adjacent to the player and in the two columns
immediately adjacent to the player's start position.

---

## Affected files

- `lua/game/scenes/store_scene.lua` — `HOVER_MIN_T`, `PLAYER_START_X`
- `tests/test_hover_distance.lua` — expected hover behaviour changes
- `tests/test_golden_lotus.lua` — `face_slot` helper positioning may need updating

---

## What changes

### Bug 1: HOVER_MIN_T=1.0 creates an adjacent-row dead zone

`ray_slot_dist` returns the distance `t` at which a ray enters a slot's 1×1 tile.
The selection check is `t >= HOVER_MIN_T`.

With `GRID_SPACING_Y = 1.0`, the near face of any immediately adjacent row is exactly
**0.5 units** from the player's centre (player at tile centre, adjacent tile's nearest
face at ±0.5). So `t = 0.5`.

With `HOVER_MIN_T = 1.0`: `0.5 >= 1.0` → **false** → dead zone.

The player can highlight rows 2+ grid units away (t ≥ 1.5) but not the row directly
in front of or behind them. In a 5-row store this means:

- From row 5 (spawn): row 4 directly ahead is dead; only rows 2–3 are reachable.
- From row 4: row 3 ahead and row 5 behind are both dead; only rows 1–2 reachable.
- Row 4 cannot be highlighted from row 3 or row 5 at all — it is only reachable
  from rows 1–2 looking south, which players do not discover naturally.

**Fix:** Lower `HOVER_MIN_T` from `1.0` to `0.5`.

With `HOVER_MIN_T = 0.5`:
- Own tile (player inside, t = 0): `0 >= 0.5` → false → still blocked. ✓
- Adjacent row (t = 0.5): `0.5 >= 0.5` → true → now selectable. ✓
- All further rows (t = 1.5, 2.5): still selectable. ✓

This was the original value before it was raised in PR hover-tile-min-distance.

### Bug 2: PLAYER_START_X=6.0 spawns the player on a tile boundary

With `GRID_ORIGIN_X = 2.5` and `GRID_SPACING_X = 1.0`, store columns 4 and 5 occupy
tiles `x ∈ [5,6)` and `x ∈ [6,7)`. Their shared boundary is exactly `x = 6.0`.

Spawning at `PLAYER_START_X = 6.0` puts the player on this boundary, so:
- `ray_slot_dist` for col 4 (tile x=5..6) looking west: returns t = 0.
- `ray_slot_dist` for col 5 (tile x=6..7) looking east: returns t = 0.

Both fail `>= HOVER_MIN_T` for any positive threshold. They are still reachable
diagonally (t > 0 via the y-slab), but direct east/west gaze does not work.

The 7-column store spans `x = 2.5` to `x = 8.5`, centre at **x = 5.5**.

**Fix:** Change `PLAYER_START_X` from `6.0` to `5.5`.

- Centers the player on the store grid. ✓
- Player lands in tile x=5..6 (col 4, passage cell PASS_L=5). Still in the passage. ✓
- Collision checks: `is_wall(floor(5.5 ± 0.25), row)` stays within passage cell 5. ✓
- Col 1 near face from x=5.5: t = 5.5 − 3.0 = 2.5 < 3.0 → selectable. ✓
- Col 7 near face from x=5.5: t = 8.0 − 5.5 = 2.5 < 3.0 → selectable. ✓
  (With the old x=6.0, col 1 near face was at t = 3.0 which failed strict `< best_t`.)

`CASHIER_POS_X` stays at `6.0` (customer billboard position is independent).

### test_hover_distance.lua

This test was written to verify `HOVER_MIN_T = 1.0`. With the fix it needs to:
- Change the constant being documented to `0.5`.
- Update Test 1 (position at `slot.py + 1.2`, giving t = 0.7): with `HOVER_MIN_T = 0.5`,
  t = 0.7 **should now hover** (0.7 ≥ 0.5). Update the assertion and description.
- Add or update a test at t = 0.4 (e.g. `slot.py + 0.9`) that should NOT hover.
- Keep a test at t ≥ 0.5 that should hover.

### test_golden_lotus.lua

The `face_slot` helper navigates the player to `y = 6.0` (1.5 rows south of row 1,
giving t = 1.0 for row 1's tile). With `HOVER_MIN_T = 0.5`, t = 0.5 is enough, so
`y = 5.5` (row 2, t = 0.5) would also work.

`y = 6.0` still gives t = 1.0 which passes the new threshold, so **no functional
change is required**. Update the comment from "t=1.0 (HOVER_MIN_T)" to "t=1.0
(well above new HOVER_MIN_T=0.5)".

---

## What stays the same

- `INTERACT_RANGE = 3.0` (maximum selection distance) — unchanged.
- `CASHIER_POS_X = 6.0` (customer billboard) — unchanged.
- `CASHIER_THRESH = 4.0` — unchanged.
- All slot world positions (`GRID_ORIGIN_X/Y`, `GRID_SPACING_X/Y`) — unchanged.
- Map geometry and all other constants — unchanged.
- The selection always picks the **nearest** slot within range (existing loop logic).

---

## Open questions

None. The root cause is the HOVER_MIN_T raise from 0.5 → 1.0 exceeding the
GRID_SPACING_Y/2 = 0.5 threshold that separates "own tile" (t=0) from "adjacent
tile" (t=0.5). Reverting to 0.5 and re-centring the player spawn restores correct
behaviour.
