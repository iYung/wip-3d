do
    local headless, test_file = false, nil
    for _, v in ipairs(arg or {}) do
        if v == "--headless" then
            headless = true
        elseif headless and test_file == nil and v:sub(1, 1) ~= "-" then
            test_file = v
        end
    end
    if headless then
        require("lua/headless/stubs")
        require("lua/headless/runner").run(test_file)
        return
    end
end

do
    local visual, test_file = false, nil
    for _, v in ipairs(arg or {}) do
        if v == "--visual" then
            visual = true
        elseif visual and test_file == nil and v:sub(1, 1) ~= "-" then
            test_file = v
        end
    end
    if visual then
        local LOGICAL_W, LOGICAL_H = 1280, 720
        local canvas
        local runner
        local test_co
        local last_err

        function love.load()
            love.graphics.setDefaultFilter("nearest", "nearest")
            canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
            canvas:setFilter("nearest", "nearest")
            runner = require("lua/headless/runner")
            _G.runner = runner
            test_co = coroutine.create(function()
                dofile(test_file)
            end)
        end

        function love.update(dt)
            if test_co and coroutine.status(test_co) ~= "dead" then
                local ok, err = coroutine.resume(test_co)
                if not ok then
                    last_err = err
                end
            end
            if test_co and coroutine.status(test_co) == "dead" then
                if last_err then
                    print("FAIL: " .. tostring(last_err))
                    love.event.quit(1)
                else
                    print("PASS")
                    love.event.quit(0)
                end
                test_co = nil
            end
        end

        function love.draw()
            local ctx = runner and runner._visual_ctx
            if ctx then
                love.graphics.setCanvas(canvas)
                love.graphics.clear(0.08, 0.08, 0.12)
                ctx.sm:draw()
                love.graphics.setCanvas()

                local sw, sh = love.graphics.getDimensions()
                local scale  = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
                local ox     = (sw - LOGICAL_W * scale) / 2
                local oy     = (sh - LOGICAL_H * scale) / 2
                love.graphics.draw(canvas, ox, oy, 0, scale, scale)
            end
        end

        function love.keypressed(key)
            if key == "escape" then love.event.quit() end
        end

        return
    end
end

love.graphics.setDefaultFilter("nearest", "nearest")

local SceneManager = require("lua/core/scene_manager")
local StartScene   = require("lua/game/scenes/start_scene")
local GameState    = require("lua/game/game_state")
local input        = require("lua/game/input")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas

local scene_manager

function love.load()
    canvas       = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")
    local gs     = GameState.new()
    scene_manager = SceneManager.new()
    scene_manager:switch(StartScene.new(gs, input, scene_manager))
end

function love.update(dt)
    input:update()
    scene_manager:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.08, 0.12)
    scene_manager:draw()
    love.graphics.setCanvas()

    local sw, sh  = love.graphics.getDimensions()
    local scale   = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox      = (sw - LOGICAL_W * scale) / 2
    local oy      = (sh - LOGICAL_H * scale) / 2
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
