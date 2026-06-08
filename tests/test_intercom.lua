math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local BuyScene   = require("lua/game/scenes/buy_scene")
local Intercom   = require("lua/game/items/intercom")

-- CATALOGUE indices (wip-3d order):
-- 1-6: plant types, 7: Watering Can, 8: Grafter, 9: Expand Slot,
-- 10: Sneakers, 11: Heat Lamps, 12: Marketing, 13: Intercom, 14: Water Drone
local INTERCOM_IDX = 13

local function make_buy(ctx)
    return BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
end

-- Test: buy intercom deducts $50
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.currency == 50,
        "currency should be 50 after buying Intercom ($50), got " .. tostring(ctx.gs.currency))
    print("PASS: intercom: buy deducts $50")
end

-- Test: buy intercom gives Intercom in player hand
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.player.held_item ~= nil,
        "player should hold something after buying Intercom")
    assert(ctx.gs.player.held_item.name == "Intercom",
        "held item should be 'Intercom', got " .. tostring(ctx.gs.player.held_item and ctx.gs.player.held_item.name))
    print("PASS: intercom: buy gives Intercom in hand")
end

-- Test: cannot buy intercom with insufficient currency
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 49
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.currency == 49,
        "currency should be unchanged when broke, got " .. tostring(ctx.gs.currency))
    assert(ctx.gs.player.held_item == nil,
        "player should not receive Intercom when broke")
    print("PASS: intercom: cannot buy with insufficient currency")
end

-- Test: bubble hidden with nil getter
do
    local ic = Intercom.new(nil)
    ic:update(0)
    assert(ic.bubble.visible == false, "bubble should be hidden when no getter")
    print("PASS: intercom: bubble hidden with nil getter")
end

-- Test: bubble hidden when customer bubble not visible
do
    local customer = { bubble = { visible = false }, done_talking = true,
                       state = "waiting", plant_type = 1 }
    local ic = Intercom.new(function() return customer end)
    ic:update(0)
    assert(ic.bubble.visible == false, "bubble should be hidden when customer bubble not visible")
    print("PASS: intercom: bubble hidden when customer bubble not visible")
end

-- Test: bubble shown when customer is in display state
do
    local customer = { bubble = { visible = true }, done_talking = true,
                       state = "waiting", plant_type = 2 }
    local ic = Intercom.new(function() return customer end)
    ic:update(0)
    assert(ic.bubble.visible == true, "bubble should be visible in display state")
    print("PASS: intercom: bubble shown in customer display state")
end

-- Test: bubble hidden when customer is in talking_after state
do
    local customer = { bubble = { visible = true }, done_talking = true,
                       state = "talking_after", plant_type = 1 }
    local ic = Intercom.new(function() return customer end)
    ic:update(0)
    assert(ic.bubble.visible == false, "bubble should be hidden during talking_after")
    print("PASS: intercom: bubble hidden during talking_after")
end

-- Test: bubble hidden when customer has not finished talking
do
    local customer = { bubble = { visible = true }, done_talking = false,
                       state = "waiting", plant_type = 1 }
    local ic = Intercom.new(function() return customer end)
    ic:update(0)
    assert(ic.bubble.visible == false, "bubble should be hidden while customer still talking")
    print("PASS: intercom: bubble hidden while customer still talking")
end

print("ALL TESTS PASSED")
