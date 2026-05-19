-- Test 1: North wall blocks the player
-- Player starts at y=6.5 facing north. 200 ticks of forward movement
-- (10 seconds) would travel ~10 grid units without collision, but the
-- north wall sits at y=1 so the player should stop around y≈1.3.
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

-- Test 2: Player navigates through the passage into the cashier room
-- Route: walk north 60 ticks to y≈3.5 (passage row), turn right ~38 ticks
-- to face east, then walk east 90 ticks through the passage.
-- The divider wall has openings only at y=3–4, so the player must hit that
-- row first; walking east from the starting y=6.5 would be blocked.
do
    local ctx = runner.setup()
    local p   = ctx.scene.player3d

    ctx.move_input:hold("forward")   -- north (angle = -pi/2)
    runner.tick(ctx, 60)
    ctx.move_input:release("forward")

    assert(p.y < 4.5,
        "expected player to reach passage row (y < 4.5), got y=" .. p.y)

    ctx.move_input:hold("right")     -- turn toward east
    runner.tick(ctx, 38)
    ctx.move_input:release("right")

    ctx.move_input:hold("forward")   -- east
    runner.tick(ctx, 90)
    ctx.move_input:release("forward")

    assert(p.x >= 7.0,
        "expected player to reach cashier room (x >= 7.0), got x=" .. p.x)
    assert(ctx.scene._last_active_slot == nil,
        "expected no active slot in cashier room")
    print("PASS: player navigates to cashier room via passage")
end

print("ALL TESTS PASSED")
