local Slot = require("lua/game/slot")

-- Grid layout constants (world units)
local GRID_ORIGIN_X  =  2.00
local GRID_SPACING_X =  0.80
local GRID_ORIGIN_Y  =  4.50
local GRID_SPACING_Y = -1.30  -- negative = rows go northward (decreasing y)
local MAX_ROWS       =  3

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

-- Add the next slot in row-major order (col cycles, then row increases)
function Store:grow()
    local idx      = #self._slots         -- 0-based next index
    local next_col = (idx % self._cols) + 1
    local next_row = math.floor(idx / self._cols) + 1

    if next_row > MAX_ROWS then return end

    if not self._grid[next_row] then self._grid[next_row] = {} end

    local px   = GRID_ORIGIN_X + (next_col - 1) * GRID_SPACING_X
    local py   = GRID_ORIGIN_Y + (next_row  - 1) * GRID_SPACING_Y
    local slot = Slot.new(next_col, next_row, px, py)
    self._grid[next_row][next_col]   = slot
    self._slots[#self._slots + 1]    = slot
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
