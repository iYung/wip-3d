math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")

-- ---------------------------------------------------------------------------
-- Navigation helpers
-- ---------------------------------------------------------------------------

local function nav_to(ctx, tx, ty, elapsed)
    local p = ctx.scene.player3d
    p.angle = math.atan2(ty - p.y, tx - p.x)
    ctx.move_input:hold("forward")
    while true do
        local dx = tx - p.x
        local dy = ty - p.y
        if math.sqrt(dx * dx + dy * dy) < 0.3 then break end
        runner.tick(ctx, 1, 1/60)
        elapsed = elapsed + 1/60
    end
    ctx.move_input:release("forward")
    return elapsed
end

local function face_slot(ctx, slot_px, elapsed)
    -- If in the cashier room (y < 4.0), walk straight south through the
    -- passage at x=6.0 first.  A direct diagonal from the cashier would
    -- cross the separator at a wall column and get stuck.
    local p = ctx.scene.player3d
    if p.y < 4.0 then
        elapsed = nav_to(ctx, 6.0, 5.5, elapsed)
    end
    -- Stand one row south of slot row 1 (y=5.5) so the look-ray hits at t≈0.5.
    elapsed = nav_to(ctx, slot_px, 5.5, elapsed)
    if p.y < 5.5 then p.y = 5.5 end
    p.angle = -math.pi / 2
    return elapsed
end

local function nav_to_cashier(ctx, elapsed)
    -- Passage at cols 5-6 (x=5..7), cashier room at y<4.
    return nav_to(ctx, 6.0, 2.5, elapsed)
end

local function sell_plant(ctx, plant_type, elapsed)
    while true do
        elapsed = runner.fast_forward_until(ctx, function()
            return ctx.sm.current._customer:arrived()
        end, elapsed)

        if ctx.sm.current._customer.plant_type ~= plant_type then
            ctx.input:press("pick_up_down")
            runner.tick(ctx, 1, 1/60)
            elapsed = elapsed + 1/60
        else
            -- advance through all non-final messages
            while not ctx.sm.current._customer:on_last_message() do
                elapsed = runner.fast_forward_until(ctx, function()
                    return ctx.sm.current._customer:line_complete()
                end, elapsed)
                ctx.input:press("interact")
                runner.tick(ctx, 1, 1/60)
                elapsed = elapsed + 1/60
            end
            -- final press completes the sale
            ctx.input:press("interact")
            runner.tick(ctx, 1, 1/60)
            elapsed = elapsed + 1/60
            -- drain any post-sale after_messages before returning
            while ctx.sm.current._customer.state == "talking_after" do
                elapsed = runner.fast_forward_until(ctx, function()
                    return ctx.sm.current._customer:line_complete()
                end, elapsed)
                ctx.input:press("interact")
                runner.tick(ctx, 1, 1/60)
                elapsed = elapsed + 1/60
            end
            return elapsed
        end
    end
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.currency = 10

-- Slot 4 starts empty; seed it with a grass plant before the loop
ctx.gs.store:all_slots()[4].item = Plant.new(1)

local elapsed = 0

-- ---------------------------------------------------------------------------
-- 3x grass sale loop
-- ---------------------------------------------------------------------------

for _ = 1, 3 do
    -- Pick up watering can from slot 1 (world x=2.5)
    elapsed = face_slot(ctx, 2.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- Walk to plant slot 4 (world x=5.5)
    elapsed = face_slot(ctx, 5.5, elapsed)

    -- Water: wait for ready (stage 1 → 2)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.gs.store:all_slots()[4].item and ctx.gs.store:all_slots()[4].item.ready
    end, elapsed)
    ctx.input:press("interact")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- Water: wait for ready (stage 2 → 3)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.gs.store:all_slots()[4].item and ctx.gs.store:all_slots()[4].item.ready
    end, elapsed)
    ctx.input:press("interact")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- Return watering can to slot 1
    elapsed = face_slot(ctx, 2.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- Pick up plant from slot 4
    elapsed = face_slot(ctx, 5.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- Walk to cashier and sell
    elapsed = nav_to_cashier(ctx, elapsed)
    elapsed = sell_plant(ctx, 1, elapsed)

    -- Reseed slot 4 with a fresh grass plant
    ctx.gs.store:all_slots()[4].item = Plant.new(1)
end

assert(ctx.gs.currency >= 20,
    "currency should be >= 20 after 3 grass sales, got " .. tostring(ctx.gs.currency))

-- ---------------------------------------------------------------------------
-- Golden Lotus purchase via PC Store (slot 3, world x=9.5)
-- ---------------------------------------------------------------------------

-- Face the PC Store (slot 3, world x=4.5)
elapsed = face_slot(ctx, 4.5, elapsed)

-- Open BuyScene
ctx.input:press("interact")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Navigate to catalogue index 6 (Golden Lotus) — 5 presses of move_right
for _ = 1, 5 do
    ctx.input:press("move_right")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60
end

-- Buy Golden Lotus (switches back to StoreScene with plant in hand)
ctx.input:press("interact")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- ---------------------------------------------------------------------------
-- Water and sell the Golden Lotus
-- ---------------------------------------------------------------------------

-- Put Golden Lotus in slot 4 (clear the reseeded grass plant first)
ctx.gs.store:all_slots()[4].item = nil
elapsed = face_slot(ctx, 5.5, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Pick up watering can from slot 1
elapsed = face_slot(ctx, 2.5, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Walk to plant slot 4
elapsed = face_slot(ctx, 5.5, elapsed)

-- Water: wait for ready (stage 1 → 2)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.gs.store:all_slots()[4].item and ctx.gs.store:all_slots()[4].item.ready
end, elapsed)
ctx.input:press("interact")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Water: wait for ready (stage 2 → 3)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.gs.store:all_slots()[4].item and ctx.gs.store:all_slots()[4].item.ready
end, elapsed)
ctx.input:press("interact")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Return watering can to slot 1
elapsed = face_slot(ctx, 2.5, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Pick up Golden Lotus from slot 4
elapsed = face_slot(ctx, 5.5, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx, 1, 1/60)
elapsed = elapsed + 1/60

-- Walk to cashier and sell
elapsed = nav_to_cashier(ctx, elapsed)
elapsed = sell_plant(ctx, 6, elapsed)

assert(ctx.gs.currency > 10, "currency should have increased from sales")
print(string.format("Golden Lotus sold in %.1f simulated seconds", elapsed))
print("PASS: golden lotus timing")
