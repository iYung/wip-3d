-- Test 1: Initial state
do
    local ctx = runner.setup()
    assert(ctx.gs.currency == 1000, "expected currency == 1000, got " .. tostring(ctx.gs.currency))
    assert(ctx.gs.speed_level == 0, "expected speed_level == 0, got " .. tostring(ctx.gs.speed_level))
    assert(ctx.gs.growth_level == 0, "expected growth_level == 0, got " .. tostring(ctx.gs.growth_level))
    print("PASS: initial state")
end

-- Test 2: Player moves forward
do
    local ctx = runner.setup()
    local start_x = ctx.scene.player3d.x
    local start_y = ctx.scene.player3d.y
    ctx.move_input:hold("forward")
    runner.tick(ctx, 30)
    assert(
        start_x ~= ctx.scene.player3d.x or start_y ~= ctx.scene.player3d.y,
        "expected player position to change after holding forward"
    )
    print("PASS: player moves forward")
end

-- Test 3: Player turns right
do
    local ctx = runner.setup()
    local start_angle = ctx.scene.player3d.angle
    ctx.move_input:hold("right")
    runner.tick(ctx, 30)
    assert(
        ctx.scene.player3d.angle > start_angle,
        "expected angle to increase after holding right, start=" .. tostring(start_angle) ..
        " end=" .. tostring(ctx.scene.player3d.angle)
    )
    print("PASS: player turns right")
end

-- Test 4: Currency unchanged by movement
do
    local ctx = runner.setup()
    ctx.move_input:hold("forward")
    runner.tick(ctx, 60)
    assert(ctx.gs.currency == 1000, "expected currency == 1000 after movement, got " .. tostring(ctx.gs.currency))
    print("PASS: currency unchanged by movement")
end

print("ALL TESTS PASSED")
