-- Simulation: starting from $10, how long to work up to and sell a Golden Lotus?
--
-- Uses real Plant objects and PLANT_DATA cooldowns. Customer spawns are modelled
-- via the same random logic as _next_customer_cfg: random 3-6s intervals, plant
-- type drawn uniformly from unlocked_plants.
--
-- Fixed seed 42 for reproducibility. Run with: love . --test
require("lua/test/love_stubs")

local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")
local T          = require("lua/test/t")

math.randomseed(42)

-- ── Constants ────────────────────────────────────────────────────────────────

local STARTING_GOLD   = 10
local NUM_SLOTS       = 7        -- slots 4-10 in the real store
local GOLDEN_LOTUS_TYPE = 6
local DEADLOCK_LIMIT  = 9999     -- safety: max iterations before aborting

local function plant_sell_value(plant)
    if plant.stage ~= 3 then return 1 end
    local pd = PLANT_DATA[plant.plant_type]
    return pd and pd.sell or 5
end

local function fmt_time(t)
    return string.format("%7.2fs", t)
end

-- ── Simulation state ─────────────────────────────────────────────────────────

local currency       = STARTING_GOLD
local time           = 0.0
local slots          = {}           -- array of Plant or nil, length NUM_SLOTS
local unlocked       = {}           -- plant_type → true
local pending_sales  = {}           -- stage-3 plants waiting for a customer
local customer_timer = nil          -- seconds until next customer arrives
local sold_lotus     = false
local iters          = 0

for i = 1, NUM_SLOTS do slots[i] = nil end

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function best_affordable()
    local best = nil
    for i = #PLANT_DATA, 1, -1 do
        local pd = PLANT_DATA[i]
        if pd.cost <= currency then
            best = i
            break
        end
    end
    return best
end

local function fill_slots()
    for i = 1, NUM_SLOTS do
        if slots[i] == nil then
            local pt = best_affordable()
            if pt then
                currency = currency - PLANT_DATA[pt].cost
                slots[i] = Plant.new(pt)
                unlocked[pt] = true
                print(string.format("[t=%s]  BUY  %-16s $%-4d→ $%d  (slot %d)",
                    fmt_time(time), PLANT_DATA[pt].name,
                    PLANT_DATA[pt].cost, currency, i + 3))
            end
        end
    end
end

local function next_event_dt()
    local dt = math.huge

    -- next plant cooldown
    for _, plant in ipairs(slots) do
        if plant and plant.stage < 3 and not plant.ready then
            local rem = plant._cooldown.interval - plant._cooldown._t
            if rem > 0 and rem < dt then dt = rem end
        end
    end

    -- customer arrival
    if customer_timer and customer_timer > 0 then
        if customer_timer < dt then dt = customer_timer end
    end

    return dt
end

local function advance(dt)
    time = time + dt
    for _, plant in ipairs(slots) do
        if plant then plant:update(dt) end
    end
    if customer_timer then
        customer_timer = customer_timer - dt
    end
end

local function water_ready()
    for _, plant in ipairs(slots) do
        if plant and plant.ready and plant.stage < 3 then
            plant:water()
        end
    end
end

local function harvest_stage3()
    for i, plant in ipairs(slots) do
        if plant and plant.stage == 3 then
            pending_sales[#pending_sales + 1] = plant
            slots[i] = nil
            print(string.format("[t=%s]  HARV %-16s stage 3",
                fmt_time(time), PLANT_DATA[plant.plant_type].name))
            if customer_timer == nil then
                customer_timer = math.random(3, 6)
            end
        end
    end
end

local function try_customer()
    if not customer_timer or customer_timer > 0 then return end

    -- pick random plant type from unlocked
    local keys = {}
    for pt in pairs(unlocked) do keys[#keys + 1] = pt end
    local wanted = keys[math.random(#keys)]

    -- find matching pending sale
    local sold_idx = nil
    for i, plant in ipairs(pending_sales) do
        if plant.plant_type == wanted then
            sold_idx = i
            break
        end
    end

    if sold_idx then
        local plant = pending_sales[sold_idx]
        table.remove(pending_sales, sold_idx)
        local value = plant_sell_value(plant)
        currency = currency + value
        print(string.format("[t=%s]  SELL %-16s +$%-3d→ $%d",
            fmt_time(time), PLANT_DATA[plant.plant_type].name,
            value, currency))
        if plant.plant_type == GOLDEN_LOTUS_TYPE then
            sold_lotus = true
        end
    else
        print(string.format("[t=%s]  CUST wanted %-16s (no match, next customer soon)",
            fmt_time(time), PLANT_DATA[wanted].name))
    end

    -- always schedule next customer regardless of match
    customer_timer = math.random(3, 6)
end

-- ── Main loop ────────────────────────────────────────────────────────────────

print(string.format("\nStarting gold: $%d\n", STARTING_GOLD))

while not sold_lotus do
    iters = iters + 1
    T.assert(iters < DEADLOCK_LIMIT, "simulation deadlocked")

    fill_slots()

    local dt = next_event_dt()
    if dt == math.huge then
        -- nothing in slots, nothing pending — should not happen after fill
        T.assert(false, "no event to advance to (logic error)")
    end

    advance(dt)
    water_ready()
    harvest_stage3()
    try_customer()
end

print(string.format("\nTotal simulated time: %.2fs", time))
print(string.format("Final currency: $%d", currency))

-- ── Assertions ───────────────────────────────────────────────────────────────

T.assert(sold_lotus,     "Golden Lotus was sold")
T.assert(time > 0,       "non-zero time elapsed")
T.assert(currency >= 40, "currency reflects at least one Golden Lotus sale")
