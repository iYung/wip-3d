# Customer Walk Fixes

## Goal

Two bugs in the customer walk animation:

1. The customer does not face the direction they are walking — they walk out backwards.
2. The walk speed is too fast (1.8 s end-to-end at 2.5 grid/s).

## Affected files

- `lua/core/raycaster.lua` — add `flip_x` support to sprite draw
- `lua/game/scenes/store_scene.lua` — pass `flip_x` when walking out; reduce walk speed constant

## What changes

### 1. Sprite horizontal flip (`raycaster.lua`)

`draw_sprites` accepts sprite tables with optional `flip_x` (boolean). When true, the sprite is drawn mirrored around its center column.

Current draw call (unflipped):
```lua
love.graphics.draw(img, math.floor(x0), y0, 0, w / iw, h / ih)
```

Flipped version (negate x-scale, shift origin to right edge):
```lua
love.graphics.draw(img, math.floor(x0) + w, y0, 0, -w / iw, h / ih)
```

Both runs (the mid-loop run and the tail run) need the same conditional.

### 2. Customer billboard `flip_x` flag (`store_scene.lua`)

When building the customer sprite table in `draw()`, add:

```lua
flip_x = (self._cust_anim == "out"),
```

The default sprite faces right (toward the stand position). Walking in (moving right) = no flip. Walking out (moving left) = flip.

### 3. Walk speed (`store_scene.lua`)

Lower `CUST_WALK_SPEED` from `2.5` to `1.0`. The 4.5-unit walk now takes ~4.5 s each way.

The test file mirrors this constant — `tests/test_customer_walk.lua` defines `CUST_WALK_SPEED = 2.5` locally. Update it to `1.0` and recalculate `WALK_FRAMES` accordingly:
- New walk time: 4.5 / 1.0 = 4.5 s
- At 60 fps: 270 frames
- Test uses 300-frame blocks (was 150) to stay insensitive to fractions.

## What stays the same

- All cashier interaction logic, spawn timer, dialog, HUD labels
- `CASHIER_ENTRY_X`, `CASHIER_POS_X`, `CASHIER_POS_Y`
- `CUST_WALK_FRAME_T` (frame toggle interval stays 0.15 s)
- All other sprites — the `flip_x` field defaults to absent/nil (no flip)
- `customer.lua` — untouched

## Open questions

None.
