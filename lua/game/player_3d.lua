local Input = require("lua/core/input")

local MOVE_SPEED = 3.0   -- grid units per second
local TURN_SPEED = 2.5   -- radians per second

local Player3D = {}
Player3D.__index = Player3D

-- shared_input: the global Input object (joystick-aware); if nil, a private one is created.
-- When shared, uses move_up/move_down/move_left/move_right action names.
function Player3D.new(x, y, angle, shared_input)
    local self        = setmetatable({}, Player3D)
    self.x            = x
    self.y            = y
    self.angle        = angle or 0
    self._shared_input = shared_input ~= nil
    self.input        = shared_input or Input.new({
        forward  = { "w", "up" },
        backward = { "s", "down" },
        left     = { "a", "left" },
        right    = { "d", "right" },
    })
    return self
end

function Player3D:update(dt)
    local fwd, bwd, lft, rgt
    if self._shared_input then
        -- Shared global input: update is called by main.lua; just read state.
        fwd = self.input:is_down("move_up")
        bwd = self.input:is_down("move_down")
        lft = self.input:is_down("move_left")
        rgt = self.input:is_down("move_right")
    else
        self.input:update()
        fwd = self.input:is_down("forward")
        bwd = self.input:is_down("backward")
        lft = self.input:is_down("left")
        rgt = self.input:is_down("right")
    end
    if lft then self.angle = self.angle - TURN_SPEED * dt end
    if rgt then self.angle = self.angle + TURN_SPEED * dt end
    local spd = self.move_speed or MOVE_SPEED
    if fwd then
        self.x = self.x + math.cos(self.angle) * spd * dt
        self.y = self.y + math.sin(self.angle) * spd * dt
    end
    if bwd then
        self.x = self.x - math.cos(self.angle) * spd * dt
        self.y = self.y - math.sin(self.angle) * spd * dt
    end
end

return Player3D
