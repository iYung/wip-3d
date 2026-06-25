math.randomseed(42)

local runner = require("lua/headless/runner")

-- Verifies HOVER_MIN_T = 0.5 in store_scene.lua.
-- Slot 4 world position: px=5.5, py=4.5. Tile spans y=[4,5].
-- Player facing north (angle=-pi/2): dx=0, dy=-1.
-- Ray enters tile at t = (py_player - tile_hi) = (py_player - 5).
-- At py_player=5.4 → t=0.4 (below threshold, should NOT hover).
-- At py_player=5.5 → t=0.5 (exactly at threshold, should hover).

local function slots(ctx) return ctx.gs.store:all_slots() end

local function position_player(ctx, px, py)
    ctx.scene.player3d.x     = px
    ctx.scene.player3d.y     = py
    ctx.scene.player3d.angle = -math.pi / 2
    runner.tick(ctx, 1)
end

-- ── Test 1: t=0.4 → tile not hovered (below HOVER_MIN_T=0.5) ────────────────
do
    local ctx  = runner.setup()
    local slot = slots(ctx)[4]  -- row 1, col 4, px=5.5, py=4.5
    position_player(ctx, slot.px, slot.py + 0.9)  -- t = 0.4
    assert(ctx.scene._last_active_slot == nil,
        "slot at t=0.4 should not be hovered (below HOVER_MIN_T=0.5)")
    print("PASS: hover_distance: tile at t=0.4 is not hovered")
end

-- ── Test 2: t=0.5 → tile hovered (exactly at threshold) ──────────────────────
do
    local ctx  = runner.setup()
    local slot = slots(ctx)[4]
    position_player(ctx, slot.px, slot.py + 1.0)  -- t = 0.5
    assert(ctx.scene._last_active_slot == slot,
        "slot at t=0.5 should be hovered (at HOVER_MIN_T=0.5 boundary)")
    print("PASS: hover_distance: tile at t=0.5 is hovered")
end

print("ALL TESTS PASSED")
