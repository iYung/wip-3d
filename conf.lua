local function is_test_mode()
    if arg then
        for _, v in ipairs(arg) do
            if v == "--test" then return true end
        end
    end
    return false
end

function love.conf(t)
    t.window.width    = 1280
    t.window.height   = 720
    t.window.title    = "plant game"
    t.window.resizable = true

    if is_test_mode() then
        t.window                = false
        t.modules.graphics      = false
        t.modules.window        = false
        t.modules.audio         = false
        t.modules.sound         = false
    end
end
