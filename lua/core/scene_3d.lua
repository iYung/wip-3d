local Scene      = require("lua/core/scene")
local Raycaster  = require("lua/core/raycaster")

local Scene3D = setmetatable({}, { __index = Scene })
Scene3D.__index = Scene3D

function Scene3D.new()
    local self = setmetatable(Scene.new(), Scene3D)
    self.raycaster = Raycaster.new()
    return self
end

return Scene3D
