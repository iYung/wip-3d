# Dynamic Store Map

## Goal

Start the store at 7 × 5 = 35 slots. Each Expand purchase adds one full row of 7
slots, growing the store southward with no row cap. The 3D map walls always surround
the current slot grid exactly.

---

## Affected files

- `lua/game/game_state.lua`
- `lua/game/store.lua`
- `lua/game/scenes/store_scene.lua`
- `lua/game/scenes/buy_scene.lua`

---

## What changes

### game_state.lua

- `INIT_COLS`: `5` → `7`
- `INIT_ROWS`: `2` → `5`

---

### store.lua

**`grow()`**: add one full row (`self._cols` = 7 slots) instead of one slot. New row
number = `active_rows() + 1`. Loop cols 1–7, compute world positions, append to
`_slots` and `_grid`.

**`Store:active_rows()`** (new): `math.ceil(#self._slots / self._cols)`.

**`MAX_ROWS`**: removed. No cap.

**`GRID_SPACING_Y`**: `−1.0` → `+1.0` (rows now grow southward — row 1 is the
northern-most, each new row is added further south).

**`GRID_ORIGIN_Y`**: `4.5` → `2.5` (row 1 anchored just inside the north wall).

With these two changes the initial 5 rows land at y = 2.5, 3.5, 4.5, 5.5, 6.5
(same world positions as before for rows 1–3; rows 4–5 are new further south).

---

### store_scene.lua

**Map width**: 14 cols (1 left wall + 7 store + 1 separator + 4 cashier + 1 right
wall). Slot cols at Lua 2–8 (x = 2.5 – 8.5). Separator at Lua col 9 (x = 9–10).
Cashier at Lua cols 10–13. Right wall at Lua col 14.

**Map height**: dynamic, rebuilt whenever `active_rows` changes.

Structure for N active rows:

```
MAP row 1        top wall
MAP rows 2–N+1   slot rows 1–N (northward to southward)
MAP row N+2      aisle row 1
MAP row N+3      aisle row 2   ← player stands here
MAP row N+4      south wall
```

Total: N + 4 rows.

**Passage** (separator col open): MAP rows N and N+1 — the two southernmost (front)
slot rows. All other rows have the separator wall.

**Player position** (updated in `on_enter()` whenever rows change):

```
front_row_y  = GRID_ORIGIN_Y + (N − 1) × GRID_SPACING_Y  = N + 1.5
player_y     = front_row_y + 2.0                          = N + 3.5
```

For initial N = 5: `player_y = 8.5`.

**`CASHIER_POS_Y`** (updated alongside player): `front_row_y` — customer billboard
aligns with the front slot row.

**Constants that change:**

| Constant | Old | New |
|---|---|---|
| `CASHIER_THRESH` | `7.0` | `9.0` |
| `CASHIER_POS_X` | `9.5` | `11.5` |
| `PLAYER_START_X` | `3.5` | `5.5` (center of 7-wide store) |
| `PLAYER_START_Y` | `6.5` | computed: `N + 3.5` = `8.5` on init |
| `CASHIER_POS_Y` | `3.5` | computed: `N + 1.5` = `6.5` on init |

`CASHIER_POS_Y` and `player3d.y` are updated in `on_enter()` after every expand.

---

### buy_scene.lua

Update Expand Slot description: `"Adds one new slot to the\nright end of the store."`
→ `"Adds a new row of 7 slots\nto the front of the store."`.

---

## What stays the same

- `GRID_ORIGIN_X = 2.5`, `GRID_SPACING_X = 1.0`
- `COLLISION_M`, `INTERACT_RANGE`, `HOVER_MIN_T`
- `_setup_store()` item placement (slots 1–3 get watering can, bin, PC store)
- Customer, cashier zone interaction logic
- All other scenes
