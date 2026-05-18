local Slot = {}
Slot.__index = Slot

-- px, py: world position in grid units (used for billboard rendering)
function Slot.new(col, row, px, py)
    local self  = setmetatable({}, Slot)
    self.col    = col
    self.row    = row
    self.px     = px
    self.py     = py
    self.item   = nil
    return self
end

function Slot:update(dt)
    if self.item then
        self.item:update(dt)
    end
end

-- draw is a no-op in 3D; items are rendered as billboards by the raycaster
function Slot:draw() end

return Slot
