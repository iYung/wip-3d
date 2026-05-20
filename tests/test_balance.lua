math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")

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
        -- Re-aim each tick so collision doesn't push us off course
        p.angle = math.atan2(ty - p.y, tx - p.x)
    end
    ctx.move_input:release("forward")
    return elapsed
end

local function face_slot(ctx, slot_px, elapsed)
    elapsed = nav_to(ctx, slot_px, 5.5, elapsed)
    local p = ctx.scene.player3d
    if p.y < 5.5 then p.y = 5.5 end
    p.angle = -math.pi / 2
    return elapsed
end

local function nav_to_cashier(ctx, elapsed)
    return nav_to(ctx, 8.5, 3.5, elapsed)
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
            return elapsed
        end
    end
end

-- Test 1: Progression pace
-- Single context, currency=0, grass only, grass plant in slot 4 from the start.
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.currency        = 0
ctx.gs.unlocked_plants = { [1] = true }
ctx.gs.store:all_slots()[4].item = Plant.new(1)

local elapsed = 0

-- Slot world positions (GRID_ORIGIN_X=2.5, GRID_SPACING_X=1.0):
-- slot 1: x=2.5  (watering can)
-- slot 2: x=3.5  (garbage bin)
-- slot 3: x=4.5  (PC store)
-- slot 4: x=5.5  (our grass plant)
-- Cashier room: x=8.5, y=3.5

-- Target costs in order (plant unlock cost → when player can first afford it)
local targets = {
    { name = "cactus",       cost = 3  },
    { name = "rose",         cost = 6  },
    { name = "tulip",        cost = 10 },
    { name = "daisy",        cost = 15 },
    { name = "golden lotus", cost = 20 },
}

local results  = {}
local next_idx = 1

-- Keep cycling the water-walk-sell loop until all milestones are recorded.
while next_idx <= #targets do
    -- 1. Pick up watering can from slot 1.
    elapsed = face_slot(ctx, 2.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- 2. Walk to plant, wait for ready, water (stage 1 -> 2).
    elapsed = face_slot(ctx, 5.5, elapsed)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.gs.store:all_slots()[4].item ~= nil and ctx.gs.store:all_slots()[4].item.ready
    end, elapsed)
    ctx.input:press("interact")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- 3. Wait for ready, water again (stage 2 -> 3).
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.gs.store:all_slots()[4].item ~= nil and ctx.gs.store:all_slots()[4].item.ready
    end, elapsed)
    ctx.input:press("interact")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- 4. Put the watering can back in slot 1.
    elapsed = face_slot(ctx, 2.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- 5. Pick up the stage-3 plant from slot 4.
    elapsed = face_slot(ctx, 5.5, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx, 1, 1/60)
    elapsed = elapsed + 1/60

    -- 6. Walk to cashier zone and sell the grass plant.
    elapsed = nav_to_cashier(ctx, elapsed)
    elapsed = sell_plant(ctx, 1, elapsed)

    -- 7. Place a fresh grass plant in slot 4 for the next cycle.
    elapsed = face_slot(ctx, 5.5, elapsed)
    ctx.gs.store:all_slots()[4].item = Plant.new(1)

    -- Record any milestones now reached.
    while next_idx <= #targets and ctx.gs.currency >= targets[next_idx].cost do
        results[next_idx] = elapsed
        next_idx = next_idx + 1
    end
end

print("[balance] progression pace (cold start, grass only):")
for i, t in ipairs(targets) do
    print(string.format("  %-12s first affordable at %5.1f s", t.name, results[i]))
end

-- Test 2: Gold-per-minute per plant
local plant_names = { "Grass", "Cactus", "Rose", "Tulip", "Daisy", "Golden Lotus" }

print("[balance] gold-per-minute per plant (60s window, perfect loop):")
for pt = 1, 6 do
    math.randomseed(42)
    local ctx2 = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx2.gs.currency        = 999999
    ctx2.gs.unlocked_plants = { [pt] = true }
    ctx2.gs.store:all_slots()[4].item = Plant.new(pt)

    local start_currency = ctx2.gs.currency
    local elapsed2 = 0

    while elapsed2 < 60 do
        elapsed2 = face_slot(ctx2, 2.5, elapsed2)
        ctx2.input:press("pick_up_down")
        runner.tick(ctx2, 1, 1/60)
        elapsed2 = elapsed2 + 1/60

        elapsed2 = face_slot(ctx2, 5.5, elapsed2)
        elapsed2 = runner.fast_forward_until(ctx2, function()
            return ctx2.gs.store:all_slots()[4].item ~= nil and ctx2.gs.store:all_slots()[4].item.ready
        end, elapsed2)
        ctx2.input:press("interact")
        runner.tick(ctx2, 1, 1/60)
        elapsed2 = elapsed2 + 1/60

        elapsed2 = runner.fast_forward_until(ctx2, function()
            return ctx2.gs.store:all_slots()[4].item ~= nil and ctx2.gs.store:all_slots()[4].item.ready
        end, elapsed2)
        ctx2.input:press("interact")
        runner.tick(ctx2, 1, 1/60)
        elapsed2 = elapsed2 + 1/60

        elapsed2 = face_slot(ctx2, 2.5, elapsed2)
        ctx2.input:press("pick_up_down")
        runner.tick(ctx2, 1, 1/60)
        elapsed2 = elapsed2 + 1/60

        elapsed2 = face_slot(ctx2, 5.5, elapsed2)
        ctx2.input:press("pick_up_down")
        runner.tick(ctx2, 1, 1/60)
        elapsed2 = elapsed2 + 1/60

        elapsed2 = nav_to_cashier(ctx2, elapsed2)
        elapsed2 = sell_plant(ctx2, pt, elapsed2)

        ctx2.gs.store:all_slots()[4].item = Plant.new(pt)
    end

    local gpm = ctx2.gs.currency - start_currency
    print(string.format("  %-12s $%d/min", plant_names[pt], gpm))
end

-- Test 4: Growth multiplier value
local growth_tiers = {
    { mult = 1.0,  level = 0, cost = 0   },
    { mult = 1.25, level = 1, cost = 20  },
    { mult = 1.60, level = 2, cost = 50  },
    { mult = 2.00, level = 3, cost = 100 },
}

local base_gold_300 = nil

print("[balance] growth multiplier value (300s window, golden lotus):")
for _, tier in ipairs(growth_tiers) do
    math.randomseed(42)
    local ctx4 = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx4.gs.growth_mult     = tier.mult
    ctx4.gs.growth_level    = tier.level
    ctx4.gs.currency        = 999999
    ctx4.gs.unlocked_plants = { [6] = true }
    ctx4.gs.store:all_slots()[4].item = Plant.new(6)

    local start4        = ctx4.gs.currency
    local elapsed4      = 0
    local payback_time4 = nil

    while elapsed4 < 300 do
        elapsed4 = face_slot(ctx4, 2.5, elapsed4)
        ctx4.input:press("pick_up_down")
        runner.tick(ctx4, 1, 1/60)
        elapsed4 = elapsed4 + 1/60

        elapsed4 = face_slot(ctx4, 5.5, elapsed4)
        elapsed4 = runner.fast_forward_until(ctx4, function()
            return ctx4.gs.store:all_slots()[4].item ~= nil and ctx4.gs.store:all_slots()[4].item.ready
        end, elapsed4)
        ctx4.input:press("interact")
        runner.tick(ctx4, 1, 1/60)
        elapsed4 = elapsed4 + 1/60

        elapsed4 = runner.fast_forward_until(ctx4, function()
            return ctx4.gs.store:all_slots()[4].item ~= nil and ctx4.gs.store:all_slots()[4].item.ready
        end, elapsed4)
        ctx4.input:press("interact")
        runner.tick(ctx4, 1, 1/60)
        elapsed4 = elapsed4 + 1/60

        elapsed4 = face_slot(ctx4, 2.5, elapsed4)
        ctx4.input:press("pick_up_down")
        runner.tick(ctx4, 1, 1/60)
        elapsed4 = elapsed4 + 1/60

        elapsed4 = face_slot(ctx4, 5.5, elapsed4)
        ctx4.input:press("pick_up_down")
        runner.tick(ctx4, 1, 1/60)
        elapsed4 = elapsed4 + 1/60

        elapsed4 = nav_to_cashier(ctx4, elapsed4)
        elapsed4 = sell_plant(ctx4, 6, elapsed4)

        ctx4.gs.store:all_slots()[4].item = Plant.new(6)

        if tier.cost > 0 and base_gold_300 ~= nil and payback_time4 == nil then
            local cumulative_extra = (ctx4.gs.currency - start4) - base_gold_300 * (elapsed4 / 300)
            if cumulative_extra >= tier.cost then
                payback_time4 = elapsed4
            end
        end
    end

    local gold_earned = ctx4.gs.currency - start4
    if tier.level == 0 then
        base_gold_300 = gold_earned
    end

    if tier.cost == 0 then
        print(string.format("  level %d (x%.2f, $%d cost): $%d earned in 300s",
            tier.level, tier.mult, tier.cost, gold_earned))
    else
        local pb_str = payback_time4 and string.format("%.0fs", payback_time4) or "never"
        print(string.format("  level %d (x%.2f, $%d cost): $%d earned in 300s, payback=%s",
            tier.level, tier.mult, tier.cost, gold_earned, pb_str))
    end
end

-- Test 5: Speed upgrade ROI
local speeds = { [0] = 220, [1] = 320, [2] = 480, [3] = 720 }
local speed_costs = { [1] = 15, [2] = 40, [3] = 100 }

local base_gold_3600 = nil

print("[balance] speed upgrade ROI (3600s window, golden lotus):")
for tier_idx = 0, 3 do
    math.randomseed(42)
    local ctx5 = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx5.gs.speed_level         = tier_idx
    ctx5.gs.player.speed        = speeds[tier_idx]
    ctx5.gs.currency            = 999999
    ctx5.gs.unlocked_plants     = { [6] = true }
    ctx5.gs.store:all_slots()[4].item = Plant.new(6)

    local start5        = ctx5.gs.currency
    local elapsed5      = 0
    local sales5        = 0
    local payback_time5 = nil

    while elapsed5 < 3600 do
        elapsed5 = face_slot(ctx5, 2.5, elapsed5)
        ctx5.input:press("pick_up_down")
        runner.tick(ctx5, 1, 1/60)
        elapsed5 = elapsed5 + 1/60

        elapsed5 = face_slot(ctx5, 5.5, elapsed5)
        elapsed5 = runner.fast_forward_until(ctx5, function()
            return ctx5.gs.store:all_slots()[4].item ~= nil and ctx5.gs.store:all_slots()[4].item.ready
        end, elapsed5, 500)
        ctx5.input:press("interact")
        runner.tick(ctx5, 1, 1/60)
        elapsed5 = elapsed5 + 1/60

        elapsed5 = runner.fast_forward_until(ctx5, function()
            return ctx5.gs.store:all_slots()[4].item ~= nil and ctx5.gs.store:all_slots()[4].item.ready
        end, elapsed5, 500)
        ctx5.input:press("interact")
        runner.tick(ctx5, 1, 1/60)
        elapsed5 = elapsed5 + 1/60

        elapsed5 = face_slot(ctx5, 2.5, elapsed5)
        ctx5.input:press("pick_up_down")
        runner.tick(ctx5, 1, 1/60)
        elapsed5 = elapsed5 + 1/60

        elapsed5 = face_slot(ctx5, 5.5, elapsed5)
        ctx5.input:press("pick_up_down")
        runner.tick(ctx5, 1, 1/60)
        elapsed5 = elapsed5 + 1/60

        elapsed5 = nav_to_cashier(ctx5, elapsed5)
        local currency_before = ctx5.gs.currency
        elapsed5 = sell_plant(ctx5, 6, elapsed5)
        if ctx5.gs.currency > currency_before then
            sales5 = sales5 + 1
        end

        ctx5.gs.store:all_slots()[4].item = Plant.new(6)

        if tier_idx > 0 and base_gold_3600 ~= nil and payback_time5 == nil then
            local cumulative_extra = (ctx5.gs.currency - start5) - base_gold_3600 * (elapsed5 / 3600)
            if cumulative_extra >= speed_costs[tier_idx] then
                payback_time5 = elapsed5 / 60
            end
        end
    end

    local gold_earned5 = ctx5.gs.currency - start5
    if tier_idx == 0 then
        base_gold_3600 = gold_earned5
    end

    if tier_idx == 0 then
        print(string.format("  tier %d (speed=%d, $%d cost): $%d earned, %d sales in 3600s",
            tier_idx, speeds[tier_idx], 0, gold_earned5, sales5))
    else
        local pb_str = payback_time5 and string.format("%.1f min", payback_time5) or "never"
        print(string.format("  tier %d (speed=%d, $%d cost): $%d earned, %d sales in 3600s, payback=%s",
            tier_idx, speeds[tier_idx], speed_costs[tier_idx], gold_earned5, sales5, pb_str))
    end
end
