-- Test 1: North wall blocks the player
-- Player starts at y=8.5 facing north. 200 ticks of forward movement
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
-- Route: walk north 20 ticks from y=8.5 to reach the passage rows (y≈5.5),
-- turn right ~38 ticks to face east, then walk east 90 ticks through the
-- passage. The separator wall has openings only in the two southernmost slot
-- rows (y=5..7 for the initial 5-row store), so the player must reach that
-- band before moving east.
do
    local ctx = runner.setup()
    local p   = ctx.scene.player3d

    ctx.move_input:hold("forward")   -- north (angle = -pi/2)
    runner.tick(ctx, 20)
    ctx.move_input:release("forward")

    assert(p.y < 7.0,
        "expected player to reach passage row (y < 7.0), got y=" .. p.y)

    ctx.move_input:hold("right")     -- turn toward east
    runner.tick(ctx, 38)
    ctx.move_input:release("right")

    ctx.move_input:hold("forward")   -- east
    runner.tick(ctx, 90)
    ctx.move_input:release("forward")

    assert(p.x >= 9.0,
        "expected player to reach cashier room (x >= 9.0), got x=" .. p.x)
    assert(ctx.scene._last_active_slot == nil,
        "expected no active slot in cashier room")
    print("PASS: player navigates to cashier room via passage")
end

print("ALL TESTS PASSED")
