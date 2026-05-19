local HeadlessInput = {}
HeadlessInput.__index = HeadlessInput

function HeadlessInput.new()
    local self      = setmetatable({}, HeadlessInput)
    self._down      = {}
    self._pressed   = {}
    self._queued    = {}
    return self
end

-- Processes queued single-frame presses and updates _pressed.
-- Call once per simulated frame before reading is_down / pressed.
function HeadlessInput:update()
    local new_pressed = {}
    for action, _ in pairs(self._queued) do
        new_pressed[action] = true
    end
    self._queued   = {}
    self._pressed  = new_pressed
end

function HeadlessInput:is_down(action)
    return self._down[action] == true
end

function HeadlessInput:pressed(action)
    return self._pressed[action] == true
end

-- Test-driving: hold or release an action.
function HeadlessInput:set_down(action, held)
    self._down[action] = held == true
end

-- Test-driving: queue a single-frame press, cleared by the next update().
function HeadlessInput:press(action)
    self._queued[action] = true
end

return HeadlessInput
