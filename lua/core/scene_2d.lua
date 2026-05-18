local Scene  = require("lua/core/scene")
local Drawer = require("lua/core/drawer")
local Camera = require("lua/core/camera")

local Scene2D = setmetatable({}, { __index = Scene })
Scene2D.__index = Scene2D

function Scene2D.new()
    local self  = setmetatable(Scene.new(), Scene2D)
    self.drawer = Drawer.new()
    self.camera = Camera.new()
    return self
end

function Scene2D:draw()
    self.camera:attach()
    self.drawer:draw()
    self.camera:detach()
end

function Scene2D:on_exit()
    self.drawer:clear()
end

return Scene2D
