-- Test 1: North wall blocks the player
-- Player starts at (6.0, 8.5) facing north. 200 ticks of forward movement
-- would overshoot, but the north wall (row 1, y=1..2) stops the player
-- at y≈1.25 (COLLISION_M=0.25 from the wall face).
do
    local ctx = runner.setup()
    local p   = ctx.scene.player3d

    ctx.move_input:hold("forward")
    runner.tick(ctx, 200)
    ctx.move_input:release("forward")

    assert(p.y < 3.0,
        "expected player to move north significantly, got y=" .. p.y)
    assert(p.y > 1.0,
        "player passed through north wall, got y=" .. p.y)
    print("PASS: north wall blocks player")
end

-- Test 2: Player navigates through the passage into the cashier room.
-- Player starts at (6.0, 8.5) facing north (toward separator at row 3).
-- Passage is at cols 5-6 (x=5..7); player at x=6.0 is aligned with it.
-- Walking straight north passes through the passage into the cashier room.
do
    local ctx = runner.setup()
    local p   = ctx.scene.player3d

    ctx.move_input:hold("forward")   -- straight north through passage
    runner.tick(ctx, 100)
    ctx.move_input:release("forward")

    assert(p.y < 4.0,
        "expected player to reach cashier zone (y < 4.0), got y=" .. p.y)
    assert(ctx.scene._last_active_slot == nil,
        "expected no active slot in cashier room")
    print("PASS: player navigates to cashier room via passage")
end

print("ALL TESTS PASSED")
