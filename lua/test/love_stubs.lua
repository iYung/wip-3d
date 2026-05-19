-- love_stubs.lua
-- Installs stub implementations of every Love2D API touched at require/construct
-- time so game modules can be safely loaded without a GPU or window.
-- Call once via require("lua/test/love_stubs") before any game module is loaded.
-- Returns nothing.

love = love or {}

-- ── love.filesystem ──────────────────────────────────────────────────────────

love.filesystem = love.filesystem or {}

-- Treat all optional files as absent.
love.filesystem.getInfo = function(path)
    return nil
end

-- ── love.keyboard ─────────────────────────────────────────────────────────────

love.keyboard = love.keyboard or {}

love.keyboard.isDown = function(key)
    return false
end

-- ── love.graphics ─────────────────────────────────────────────────────────────

love.graphics = love.graphics or {}

-- Construction stubs (called at require/construct time) ---------------------

love.graphics.newImage = function(path)
    return {
        getWidth  = function() return 1 end,
        getHeight = function() return 1 end,
    }
end

love.graphics.newShader = function(src)
    return {
        send       = function() end,
        hasUniform = function() return false end,
    }
end

love.graphics.newFont = function(...)
    return {
        getHeight = function() return 12 end,
        getWidth  = function(self, str) return 8 end,
    }
end

love.graphics.newCanvas = function(w, h)
    return {
        setFilter = function() end,
    }
end

-- Draw no-ops (so tests that accidentally call draw don't crash) -----------

love.graphics.setColor        = function() end
love.graphics.rectangle       = function() end
love.graphics.draw            = function() end
love.graphics.setShader       = function() end
love.graphics.setCanvas       = function() end
love.graphics.clear           = function() end
love.graphics.print           = function() end
love.graphics.setFont         = function() end
love.graphics.line            = function() end
love.graphics.setLineWidth    = function() end
love.graphics.push            = function() end
love.graphics.pop             = function() end
love.graphics.translate       = function() end
love.graphics.scale           = function() end
love.graphics.setDefaultFilter = function() end
