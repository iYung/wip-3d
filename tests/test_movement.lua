-- Test 1: North wall blocks the player
-- Player starts at y=6.5 facing north. 200 ticks of forward movement
-- would travel far without collision, but the north wall sits at y=1
-- so the player stops around y≈2.25.
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
-- Player starts at (10.0, 6.5) facing north. Walk north to y≈3.5 (passage
-- fixed at slot rows 1-2 for any n), turn left to face west, walk west through
-- the separator opening into the cashier (x <= 6.0).
do
    local ctx = runner.setup()
    local p   = ctx.scene.player3d

    ctx.move_input:hold("forward")   -- north toward passage (rows 1-2, y≈2.5-3.5)
    runner.tick(ctx, 60)
    ctx.move_input:release("forward")

    ctx.move_input:hold("left")      -- turn toward west (angle = -pi/2 → -pi)
    runner.tick(ctx, 38)
    ctx.move_input:release("left")

    ctx.move_input:hold("forward")   -- west through separator
    runner.tick(ctx, 100)
    ctx.move_input:release("forward")

    assert(p.x <= 6.0,
        "expected player to reach cashier room (x <= 6.0), got x=" .. p.x)
    assert(ctx.scene._last_active_slot == nil,
        "expected no active slot in cashier room")
    print("PASS: player navigates to cashier room via passage")
end

print("ALL TESTS PASSED")
