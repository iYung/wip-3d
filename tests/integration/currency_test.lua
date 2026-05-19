-- Integration test: currency / store wiring
-- Stubs must be installed before any game module is loaded.
require("lua/test/love_stubs")

local GameState    = require("lua/game/game_state")
local StoreScene   = require("lua/game/scenes/store_scene")
local HeadlessInput = require("lua/test/headless_input")
local Plant        = require("lua/game/items/plant")
local T            = require("lua/test/t")

-- ── Minimal scene-manager stub ────────────────────────────────────────────────
local sm = { switch = function() end }

-- ── Construct real game objects ───────────────────────────────────────────────
local gs    = GameState.new()
local input = HeadlessInput.new()
local scene = StoreScene.new(gs, input, sm)

-- Initialise scene (sets up map, player3d, slots, etc.)
scene:on_enter()

-- ── Test 1: initial currency ──────────────────────────────────────────────────
-- GameState always starts with 1000 currency; proves bootstrap wiring is clean.
T.eq(gs.currency, 1000, "initial currency")

-- ── Test 2: initial slot count ────────────────────────────────────────────────
-- GameState creates a 5×2 grid = 10 slots.
local slots = gs.store:all_slots()
T.eq(#slots, 10, "initial slot count")

-- ── Test 3: plant growth via store:update ─────────────────────────────────────
-- Place a stage-1 Grass plant (plant_type 1, cooldown = 1 s) in slot 4
-- (slots 1-3 are taken by WateringCan, GarbageBin, PCStore after on_enter).
local plant = Plant.new(1)
slots[4].item = plant

T.eq(plant.stage, 1,     "plant starts at stage 1")
T.eq(plant.ready, false, "plant not ready before cooldown")

-- Drive the store forward by more than the cooldown interval.
-- StoreScene:update multiplies dt by gs.growth_mult (default 1.0).
local cooldown_secs = plant._cooldown.interval
scene:update(cooldown_secs + 0.1)

T.eq(plant.ready, true, "plant ready after cooldown via scene update")

-- ── Test 4: currency unchanged (no sale was simulated) ────────────────────────
-- Confirms update() does not mutate currency without an actual sale interaction.
T.eq(gs.currency, 1000, "currency unchanged after simple update")
