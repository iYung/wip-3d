# Hover Dead Zone Fix Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — Change `HOVER_MIN_T` from `1.0` to `0.5` (line ~82). Change `PLAYER_START_X` from `6.0` to `5.5` (line ~78). Update the comment on `PLAYER_START_X` to say "store centre x" instead of "passage centre x".

- [x] Task B — `tests/test_hover_distance.lua` — Rewrite to verify `HOVER_MIN_T = 0.5`. Replace the current Test 1 (slot at t=0.7 should NOT hover) with a test where t=0.4 (position player at `slot.py + 0.9`) should NOT hover (0.4 < 0.5). Replace Test 2 (slot at t=1.0 should hover) with a test where t=0.5 (position player at `slot.py + 1.0`) should hover (0.5 >= 0.5). Update all comments and the header to reference the new threshold.

- [x] Task C — `tests/test_golden_lotus.lua` — Update the comment in `face_slot` that says "so the look-ray hits at t=1.0 (HOVER_MIN_T)" to instead say "look-ray hits at t=1.0 (above HOVER_MIN_T=0.5)" — no navigation logic changes needed since y=6.0 still works.
