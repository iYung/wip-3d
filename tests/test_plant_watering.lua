local Plant = require("lua/game/items/plant")

-- Plant:water() return values are the contract watering_can depends on.

-- ── Test 1: water() returns false when plant is not ready ─────────────────────
do
    local p = Plant.new(1)
    p.stage = 1
    p.ready = false
    local result = p:water()
    assert(result == false,
        "water() should return false when plant is not ready, got " .. tostring(result))
    assert(p.stage == 1, "stage should be unchanged")
    print("PASS: plant: water() returns false when not ready")
end

-- ── Test 2: water() returns false when plant is already stage 3 ───────────────
do
    local p = Plant.new(1)
    p.stage = 3
    p.ready = true
    local result = p:water()
    assert(result == false,
        "water() should return false when stage >= 3, got " .. tostring(result))
    assert(p.stage == 3, "stage should be unchanged")
    print("PASS: plant: water() returns false when stage 3")
end

-- ── Test 3: water() returns true and advances stage ───────────────────────────
do
    local p = Plant.new(1)
    p.stage = 1
    p.ready = true
    local result = p:water()
    assert(result == true,
        "water() should return true after advancing stage, got " .. tostring(result))
    assert(p.stage == 2, "stage should advance to 2, got " .. tostring(p.stage))
    assert(p.ready == false, "plant should not be ready after watering")
    print("PASS: plant: water() returns true and advances stage")
end

-- ── Test 4: water() returns true advancing from stage 2 to stage 3 ───────────
do
    local p = Plant.new(1)
    p.stage = 2
    p.ready = true
    local result = p:water()
    assert(result == true,
        "water() should return true advancing stage 2→3, got " .. tostring(result))
    assert(p.stage == 3, "stage should advance to 3, got " .. tostring(p.stage))
    print("PASS: plant: water() returns true advancing stage 2 to 3")
end

print("ALL TESTS PASSED")
