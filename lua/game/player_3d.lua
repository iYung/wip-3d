local Input = require("lua/core/input")

local MOVE_SPEED = 3.0   -- grid units per second
local TURN_SPEED = 2.5   -- radians per second

local Player3D = {}
Player3D.__index = Player3D

function Player3D.new(x, y, angle)
    local self  = setmetatable({}, Player3D)
    self.x      = x
    self.y      = y
    self.angle  = angle or 0
    self.input  = Input.new({
        forward  = { "w", "up" },
        backward = { "s", "down" },
        left     = { "a", "left" },
        right    = { "d", "right" },
    })
    return self
end

function Player3D:update(dt)
    self.input:update()
    if self.input:is_down("left")     then self.angle = self.angle - TURN_SPEED * dt end
    if self.input:is_down("right")    then self.angle = self.angle + TURN_SPEED * dt end
    if self.input:is_down("forward")  then
        self.x = self.x + math.cos(self.angle) * MOVE_SPEED * dt
        self.y = self.y + math.sin(self.angle) * MOVE_SPEED * dt
    end
    if self.input:is_down("backward") then
        self.x = self.x - math.cos(self.angle) * MOVE_SPEED * dt
        self.y = self.y - math.sin(self.angle) * MOVE_SPEED * dt
    end
end

return Player3D
