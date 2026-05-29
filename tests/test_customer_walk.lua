-- Constants mirrored from store_scene.lua
local CASHIER_ENTRY_X = 1.5
local CASHIER_POS_X   = 6.0
local CUST_WALK_SPEED = 2.5

-- Walk-in/out each take (6.0-1.5)/2.5 = 1.8 s = 108 frames at 60 fps.
-- Use 150-frame blocks so tests are not sensitive to off-by-one fractions.
local WALK_FRAMES = 150

local function show_customer(scene)
    scene._customer:show({ plant_type = 1, messages = {} })
    scene._cust_3d_x       = CASHIER_ENTRY_X
    scene._cust_anim       = "in"
    scene._cust_walk_timer = 0
    scene._cust_walk_frame = false
end

-- Test 1: Walk-in animation starts at the left-wall entry position.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    assert(scene._cust_anim == "in",
        "expected _cust_anim='in' at walk-in start")
    assert(math.abs(scene._cust_3d_x - CASHIER_ENTRY_X) < 0.01,
        "expected _cust_3d_x=" .. CASHIER_ENTRY_X .. " at walk-in start, got " .. scene._cust_3d_x)
    assert(not scene._customer:arrived(),
        "customer should not be arrived at walk-in start")
    print("PASS: walk-in starts at entry position")
end

-- Test 2: _cust_3d_x advances rightward during walk-in.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    runner.tick(ctx, 30)   -- 0.5 s — partway through the 1.8 s walk

    assert(scene._cust_anim == "in",
        "animation should still be running at 0.5 s")
    assert(scene._cust_3d_x > CASHIER_ENTRY_X,
        "customer should have moved right from entry, got " .. scene._cust_3d_x)
    assert(scene._cust_3d_x < CASHIER_POS_X,
        "customer should not have reached stand position yet, got " .. scene._cust_3d_x)
    print("PASS: walk-in advances customer position")
end

-- Test 3: Walk-in completes — animation nil, arrived, at stand position.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    runner.tick(ctx, WALK_FRAMES)

    assert(scene._cust_anim == nil,
        "animation should be nil after walk-in, got " .. tostring(scene._cust_anim))
    assert(scene._customer:arrived(),
        "customer should be arrived after walk-in")
    assert(math.abs(scene._cust_3d_x - CASHIER_POS_X) < 0.01,
        "customer should be at stand position " .. CASHIER_POS_X .. ", got " .. scene._cust_3d_x)
    print("PASS: walk-in completes at stand position")
end

-- Test 4: Cashier HUD labels suppressed while _cust_anim is active.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    scene.player3d.y = 3.5   -- inside cashier zone (CASHIER_THRESH = 4.0)
    runner.tick(ctx, 1)

    local labels = scene:_hud_labels()
    assert(labels.e == nil,
        "E label should be nil during walk-in, got " .. tostring(labels.e))
    assert(labels.f == nil,
        "F label should be nil during walk-in, got " .. tostring(labels.f))
    print("PASS: HUD labels suppressed during walk-in")
end

-- Test 5: Walk-out starts the frame after dismiss() is called.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    runner.tick(ctx, WALK_FRAMES)   -- complete walk-in
    assert(scene._customer:arrived(), "setup: customer should be arrived")

    scene._customer:dismiss()
    runner.tick(ctx, 1)   -- detection runs at top of next update

    assert(scene._cust_anim == "out",
        "expected _cust_anim='out' after dismiss, got " .. tostring(scene._cust_anim))
    print("PASS: walk-out starts after dismiss")
end

-- Test 6: Walk-out completes — customer idle, _cust_3d_x back at entry.
do
    local ctx   = runner.setup()
    local scene = ctx.scene
    show_customer(scene)

    runner.tick(ctx, WALK_FRAMES)   -- complete walk-in
    scene._customer:dismiss()
    runner.tick(ctx, WALK_FRAMES)   -- complete walk-out

    assert(not scene._customer:active(),
        "customer should be idle after walk-out")
    assert(scene._cust_anim == nil,
        "animation should be nil after walk-out, got " .. tostring(scene._cust_anim))
    assert(math.abs(scene._cust_3d_x - CASHIER_ENTRY_X) < 0.01,
        "customer should be back at entry position " .. CASHIER_ENTRY_X .. ", got " .. scene._cust_3d_x)
    print("PASS: walk-out completes at entry position")
end

print("ALL TESTS PASSED")
