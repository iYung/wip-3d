math.randomseed(42)
local WaterDrone = require("lua/game/water_drone")

local function make_store(slots)
    return { all_slots = function() return slots end }
end

-- Test: no ready plant — update is a no-op
do
    local item = { plant_type = 1, stage = 1, ready = false,
                   water = function() error("water() called unexpectedly") end }
    local store = make_store({ { item = item } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(gs.stage3_counts[1] == nil,
        "stage3_counts should be nil when no plant is ready")
    print("PASS: water_drone: no ready plant — update is a no-op")
end

-- Test: ready plant is watered on update
do
    local watered = false
    local item = { plant_type = 2, stage = 1, ready = true,
                   water = function(self, _store) watered = true; self.ready = false end }
    local store = make_store({ { item = item } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(watered, "water() should have been called on the ready plant")
    print("PASS: water_drone: ready plant is watered on update")
end

-- Test: stage3_counts incremented when drone waters plant to stage 3
do
    local item = {
        plant_type = 3, stage = 2, ready = true,
        water = function(self, _store)
            self.stage = self.stage + 1
            self.ready = false
        end,
    }
    local store = make_store({ { item = item } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(gs.stage3_counts[3] == 1,
        "stage3_counts[3] should be 1 after watering to stage 3, got " .. tostring(gs.stage3_counts[3]))
    print("PASS: water_drone: increments stage3_counts when watering plant to stage 3")
end

-- Test: stage3_counts NOT incremented for stage 1→2
do
    local item = {
        plant_type = 1, stage = 1, ready = true,
        water = function(self, _store)
            self.stage = self.stage + 1
            self.ready = false
        end,
    }
    local store = make_store({ { item = item } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(gs.stage3_counts[1] == nil,
        "stage3_counts[1] should remain nil for stage 1→2 water")
    print("PASS: water_drone: does not increment stage3_counts for stage 1→2")
end

-- Test: only first ready plant is watered per tick
do
    local water_count = 0
    local function make_ready(pt)
        return { plant_type = pt, ready = true,
                 water = function(self, _s) water_count = water_count + 1; self.ready = false end }
    end
    local store = make_store({ { item = make_ready(1) }, { item = make_ready(2) } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(water_count == 1,
        "only one plant should be watered per tick, got " .. tostring(water_count))
    print("PASS: water_drone: only first ready plant watered per tick")
end

-- Test: slots with no item are skipped
do
    local watered = false
    local item = { plant_type = 1, ready = true,
                   water = function(self, _s) watered = true; self.ready = false end }
    local store = make_store({ { item = nil }, { item = item } })
    local gs    = { stage3_counts = {} }
    local drone = WaterDrone.new(store, gs)
    drone:update(1/60)
    assert(watered, "drone should skip empty slots and water the next ready plant")
    print("PASS: water_drone: skips empty slots")
end

print("ALL TESTS PASSED")
