local Slot = require("lua/game/slot")

local Store = {}
Store.__index = Store

function Store.new(initial_count, slot_width)
    local self       = setmetatable({}, Store)
    self.slot_width  = slot_width or 120
    self.slots       = {}
    for i = 1, initial_count do
        self.slots[i] = Slot.new(i, self.slot_width)
    end
    return self
end

function Store:width()
    return #self.slots * self.slot_width
end

function Store:grow()
    local idx = #self.slots + 1
    self.slots[idx] = Slot.new(idx, self.slot_width)
end

function Store:slot_at(x)
    local idx = math.floor(x / self.slot_width) + 1
    idx = math.max(1, math.min(#self.slots, idx))
    return self.slots[idx]
end

function Store:update(dt)
    for _, slot in ipairs(self.slots) do
        slot:update(dt)
    end
end

function Store:draw()
    for _, slot in ipairs(self.slots) do
        slot:draw()
    end
end

return Store
