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
    -- Use move_up/down/left/right so core/input.lua's gamepad poll matches.
    -- store_scene syncs input._joystick from the global input each frame.
    self.input  = Input.new({
        move_up    = { "w", "up" },
        move_down  = { "s", "down" },
        move_left  = { "a", "left" },
        move_right = { "d", "right" },
    })
    return self
end

function Player3D:update(dt)
    self.input:update()
    if self.input:is_down("move_left")  then self.angle = self.angle - TURN_SPEED * dt end
    if self.input:is_down("move_right") then self.angle = self.angle + TURN_SPEED * dt end
    local spd = self.move_speed or MOVE_SPEED
    if self.input:is_down("move_up") then
        self.x = self.x + math.cos(self.angle) * spd * dt
        self.y = self.y + math.sin(self.angle) * spd * dt
    end
    if self.input:is_down("move_down") then
        self.x = self.x - math.cos(self.angle) * spd * dt
        self.y = self.y - math.sin(self.angle) * spd * dt
    end
end

return Player3D
