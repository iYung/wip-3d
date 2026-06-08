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

-- Test: draw_bubble is a no-op when _customer_getter is nil (no crash)
do
    local ic = Intercom.new(nil)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic.sprite.width = 120
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble no-ops with nil getter")
end

-- Test: draw_bubble is a no-op when customer bubble not visible
do
    local customer = {
        bubble       = { visible = false },
        done_talking = true,
        state        = "waiting",
        plant_type   = 1,
    }
    local ic = Intercom.new(function() return customer end)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic.sprite.width = 120
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble no-ops when customer bubble not visible")
end

-- Test: draw_bubble does not crash when customer is in display state
do
    local customer = {
        bubble       = { visible = true },
        done_talking = true,
        state        = "waiting",
        plant_type   = 1,
    }
    local ic = Intercom.new(function() return customer end)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic.sprite.width = 120
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble runs without error in display state")
end

print("ALL TESTS PASSED")
