local GameState    = require("lua/game/game_state")
local HeadlessInput = require("lua/headless/input")
local SceneManager = require("lua/core/scene_manager")
local StoreScene   = require("lua/game/scenes/store_scene")

local runner = {}

function runner.setup(scene_factory)
    local gs          = GameState.new()
    local scene_input = HeadlessInput.new()
    local sm          = SceneManager.new()

    local scene
    if scene_factory then
        scene = scene_factory(gs, scene_input, sm)
    else
        scene = StoreScene.new(gs, scene_input, sm)
    end

    sm:switch(scene)  -- triggers scene:on_enter(), which creates scene.player3d

    local move_input
    if scene.player3d then
        move_input = HeadlessInput.new()
        scene.player3d.input = move_input
    end

    local ctx = { gs = gs, input = scene_input, move_input = move_input, sm = sm, scene = scene }
    runner._visual_ctx = ctx
    return ctx
end

function runner.tick(ctx, n, dt)
    n  = n  or 1
    dt = dt or (1 / 60)
    for _ = 1, n do
        ctx.input:update()
        ctx.sm:update(dt)
        if coroutine.running() then coroutine.yield() end
    end
end

function runner.run(test_file)
    _G.runner = runner
    local ok, err = pcall(dofile, test_file)
    if ok then
        print("PASS")
        love.event.quit(0)
    else
        print("FAIL: " .. tostring(err))
        love.event.quit(1)
    end
end

return runner
