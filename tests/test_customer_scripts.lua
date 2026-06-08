math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

-- Test: all script entries have a valid voice_pitch field
do
    local scripts = require("lua/game/data/customer_scripts")
    for _, entry in ipairs(scripts) do
        local p = entry.voice_pitch
        assert(type(p) == "number",
            "expected voice_pitch number for " .. entry.id .. " ch" .. entry.chapter .. ", got " .. type(p))
        assert(p > 0,
            "voice_pitch must be positive for " .. entry.id .. " ch" .. entry.chapter)
    end
    print("PASS: scripts: all entries have a valid voice_pitch field")
end

-- Test: sage chapter 1 has no_dismiss = true
do
    local scripts = require("lua/game/data/customer_scripts")
    local sage1
    for _, entry in ipairs(scripts) do
        if entry.id == "sage" and entry.chapter == 1 then
            sage1 = entry
            break
        end
    end
    assert(sage1 ~= nil, "sage chapter 1 entry should exist")
    assert(sage1.no_dismiss == true,
        "sage ch1 should have no_dismiss = true, got " .. tostring(sage1.no_dismiss))
    print("PASS: scripts: sage ch1 has no_dismiss = true")
end

-- Test: show() stores voice_pitch from cfg
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.sm.current._customer:show({
        plant_type = 1, name = "Test",
        messages = { "Hi." },
        voice_pitch = 1.28,
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    assert(ctx.sm.current._customer._voice_pitch == 1.28,
        "expected _voice_pitch 1.28, got " .. tostring(ctx.sm.current._customer._voice_pitch))
    print("PASS: scripts: show() stores voice_pitch from cfg")
end

-- Test: show() defaults voice_pitch to 1.0 when not provided
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.sm.current._customer:show({
        plant_type = 1, name = "Test",
        messages = { "Hi." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    assert(ctx.sm.current._customer._voice_pitch == 1.0,
        "expected _voice_pitch default 1.0, got " .. tostring(ctx.sm.current._customer._voice_pitch))
    print("PASS: scripts: show() defaults _voice_pitch to 1.0 when not in cfg")
end

-- Test: Romeo ch1-3 present in scripts
do
    local scripts = require("lua/game/data/customer_scripts")
    local chapters = {}
    for _, entry in ipairs(scripts) do
        if entry.id == "romeo" then
            chapters[entry.chapter] = true
        end
    end
    assert(chapters[1], "romeo ch1 should be present")
    assert(chapters[2], "romeo ch2 should be present")
    assert(chapters[3], "romeo ch3 should be present")
    print("PASS: scripts: Romeo ch1-3 all present")
end

-- Test: Glen ch1-3 present in scripts
do
    local scripts = require("lua/game/data/customer_scripts")
    local chapters = {}
    for _, entry in ipairs(scripts) do
        if entry.id == "glen" then
            chapters[entry.chapter] = true
        end
    end
    assert(chapters[1], "glen ch1 should be present")
    assert(chapters[2], "glen ch2 should be present")
    assert(chapters[3], "glen ch3 should be present")
    print("PASS: scripts: Glen ch1-3 all present")
end

-- Test: no_dismiss blocks E-dismiss for sage ch1
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    -- Manually set an active_script with no_dismiss = true
    ctx.sm.current._active_script = { no_dismiss = true }
    ctx.sm.current._customer.state = "waiting"
    ctx.sm.current._customer.sprite.visible = true

    local dismissed = false
    local orig_dismiss = ctx.sm.current._customer.dismiss
    ctx.sm.current._customer.dismiss = function(self)
        dismissed = true
        return orig_dismiss(self)
    end

    -- Simulate pressing E in cashier zone (player3d.y <= CASHIER_THRESH)
    ctx.sm.current.player3d.y = 2.5   -- inside cashier zone
    ctx.input:press("pick_up_down")
    ctx.sm.current:_handle_pick_up_down()

    assert(not dismissed,
        "no_dismiss customer should not be dismissed by E")
    print("PASS: scripts: no_dismiss blocks E-dismiss")
end

print("ALL TESTS PASSED")
