local Slot = require("lua/game/slot")

-- Grid layout constants (world units) — 1x1 to match raycaster map cells
local GRID_ORIGIN_X  =  7.5
local GRID_SPACING_X =  1.0
local GRID_ORIGIN_Y  =  2.5
local GRID_SPACING_Y =  1.0   -- positive = rows grow southward (increasing y)

local Store = {}
Store.__index = Store

function Store.new(init_cols, init_rows)
    local self        = setmetatable({}, Store)
    self._cols        = init_cols
    self._init_rows   = init_rows
    self._slots       = {}  -- flat array in row-major order
    self._grid        = {}  -- _grid[row][col]

    for row = 1, init_rows do
        self._grid[row] = {}
        for col = 1, init_cols do
            local px   = GRID_ORIGIN_X + (col - 1) * GRID_SPACING_X
            local py   = GRID_ORIGIN_Y + (row - 1) * GRID_SPACING_Y
            local slot = Slot.new(col, row, px, py)
            self._grid[row][col]     = slot
            self._slots[#self._slots + 1] = slot
        end
    end

    return self
end

-- Return the number of fully-populated rows currently in the store
function Store:active_rows()
    return math.ceil(#self._slots / self._cols)
end

-- Add one full row of self._cols slots to the front (south) of the store
function Store:grow()
    local next_row = self:active_rows() + 1

    self._grid[next_row] = {}
    for col = 1, self._cols do
        local px   = GRID_ORIGIN_X + (col      - 1) * GRID_SPACING_X
        local py   = GRID_ORIGIN_Y + (next_row - 1) * GRID_SPACING_Y
        local slot = Slot.new(col, next_row, px, py)
        self._grid[next_row][col]        = slot
        self._slots[#self._slots + 1]    = slot
    end
end

-- Return the flat array of all slots
function Store:all_slots()
    return self._slots
end

-- Return the nearest slot within max_dist, or nil
function Store:slot_near(px, py, max_dist)
    local best, best_d2 = nil, max_dist * max_dist
    for _, slot in ipairs(self._slots) do
        local dx = slot.px - px
        local dy = slot.py - py
        local d2 = dx * dx + dy * dy
        if d2 < best_d2 then
            best_d2 = d2
            best    = slot
        end
    end
    return best
end

function Store:update(dt)
    for _, slot in ipairs(self._slots) do
        slot:update(dt)
    end
end

return Store
