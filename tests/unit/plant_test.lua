-- Plant unit tests
-- Stubs must be installed before any game module is loaded.
require("lua/test/love_stubs")

local Plant = require("lua/game/items/plant")
local T     = require("lua/test/t")

-- Construct a stage-1 Grass plant (plant_type 1, cooldown = 1 second).
local p = Plant.new(1)

-- 1. stage starts at 1
T.eq(p.stage, 1, "initial stage")

-- 2. ready starts as false
T.eq(p.ready, false, "initial ready")

-- 3. After enough dt the cooldown fires and ready becomes true.
--    p._cooldown.interval is 1 for plant_type 1; pass slightly more than that.
p:update(p._cooldown.interval + 0.01)
T.eq(p.ready, true, "ready after cooldown")

-- 4. Watering advances stage to 2.
p:water()
T.eq(p.stage, 2, "stage after water")
