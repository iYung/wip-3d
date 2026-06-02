## Customer Walk Fixes Checklist

- [x] Task A — `lua/core/raycaster.lua` — Add `flip_x` support to `draw_sprites`: in both draw calls inside the column-loop, check `spr.flip_x`; if true, draw with `math.floor(x0) + w` as origin and `-w / iw` as x-scale instead of `math.floor(x0)` and `w / iw`.

- [x] Task B — `lua/game/scenes/store_scene.lua` — Pass `flip_x = (self._cust_anim == "out")` in the customer billboard sprite table built inside `draw()`. Lower `CUST_WALK_SPEED` from `2.5` to `1.0`.

- [x] Task C — `tests/test_customer_walk.lua` — Update the mirrored `CUST_WALK_SPEED` constant from `2.5` to `1.0` and change `WALK_FRAMES` from `150` to `300` to match the new walk duration.
