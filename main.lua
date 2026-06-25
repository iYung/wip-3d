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
                local chunk, err = loadfile(test_file)
                if not chunk then error(err) end
                chunk()
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
local SettingsMenu  = require("lua/game/scenes/settings_menu")
local SettingsState = require("lua/game/settings_state")
local Sound        = require("lua/game/sound")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas

local scene_manager
local settings_menu
local _prev_start = false

function love.load()
    canvas       = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")
    local gs     = GameState.new()
    scene_manager = SceneManager.new()
    local ss = SettingsState.new()
    settings_menu = SettingsMenu.new(ss, input, nil, nil)
    scene_manager:switch(StartScene.new(gs, input, scene_manager, function() settings_menu:open(true) end))
    Sound.load()
    love.mouse.setVisible(false)
end

function love.update(dt)
    Sound.update(dt)
    -- Track Start every frame so _prev_start is accurate whether menu is open or not.
    local joy = input._joystick
    local start_down = joy ~= nil and joy:isConnected() and joy:isGamepadDown("start")
    if settings_menu and settings_menu.is_open then
        settings_menu:update(dt)
    else
        input:update()
        -- Poll Start button to open settings (event-based love.gamepadpressed
        -- may not fire on all controllers for the Start/menu button).
        if start_down and not _prev_start then
            if scene_manager and scene_manager.current and scene_manager.current.esc_opens_settings then
                settings_menu:open()
            end
        end
        scene_manager:update(dt)
    end
    _prev_start = start_down
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.08, 0.12)
    scene_manager:draw()
    if settings_menu and settings_menu.is_open then
        settings_menu:draw()
    end
    love.graphics.setCanvas()

    local sw, sh  = love.graphics.getDimensions()
    local scale   = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox      = (sw - LOGICAL_W * scale) / 2
    local oy      = (sh - LOGICAL_H * scale) / 2
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function love.keypressed(key)
    input._mode = "keyboard"
    if settings_menu and settings_menu.is_open then
        if settings_menu:keypressed(key) then return end
    end
    if key == "escape" then
        if settings_menu and scene_manager and scene_manager.current and scene_manager.current.esc_opens_settings then
            if settings_menu.is_open then
                settings_menu:close()
            else
                settings_menu:open()
            end
        elseif not (settings_menu and settings_menu.is_open) then
            love.event.quit()
        end
    end
end

function love.gamepadpressed(joystick, button)
    input._joystick = joystick
    input._mode = "gamepad"
    -- Mark Start as already-seen so the polling check in love.update doesn't
    -- fire on the same frame as this event and undo what we do here.
    if button == "start" then _prev_start = true end
    if settings_menu and settings_menu.is_open then
        settings_menu:gamepadpressed(button)
        return
    end
    if button == "start" then
        if settings_menu and scene_manager and scene_manager.current and scene_manager.current.esc_opens_settings then
            settings_menu:open()
        end
    end
end

function love.joystickadded(joystick)
    if joystick:isGamepad() and input._joystick == nil then
        input._joystick = joystick
    end
end

function love.joystickremoved(joystick)
    if joystick == input._joystick then
        input._joystick = nil
        for _, j in ipairs(love.joystick.getJoysticks()) do
            if j:isGamepad() and j:isConnected() then
                input._joystick = j
                break
            end
        end
    end
end

function love.focus(focused)
    Sound.on_focus(focused)
end
