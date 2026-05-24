math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local Grafter    = require("lua/game/items/grafter")

-- Store: 5 cols x 2 rows = 10 slots (row-major). Setup fills slots 1-3 with tools.
-- World layout (GRID_ORIGIN_X=2.5, GRID_SPACING_X=1.0, GRID_ORIGIN_Y=4.5, row spacing=-1.0):
--   row 1: slot 1 (px=2.5), slot 2 (px=3.5), slot 3 (px=4.5), slot 4 (px=5.5), slot 5 (px=6.5)
--   row 2: slot 6 (px=2.5), …
--
-- Positioning player3d at (slot.px, 5.5) facing north (angle=-pi/2) aims the look-ray
-- directly at the row-1 tile above, putting that slot in _last_active_slot.

local function slots(ctx)
    return ctx.gs.store:all_slots()
end

-- Position player at the slot's column, one row south, facing north.
-- The scene's ray-cast then sets _last_active_slot to that slot on the next update.
local function face_and_interact(ctx, slot_index)
    local slot = slots(ctx)[slot_index]
    ctx.scene.player3d.x     = slot.px
    ctx.scene.player3d.y     = 5.5
    ctx.scene.player3d.angle = -math.pi / 2
    ctx.input:press("interact")
    runner.tick(ctx, 1)
end

-- ── Test 1: grafter rejects stage-2 plant ────────────────────────────────────
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local plant = Plant.new(1)
    plant.stage = 2
    slots(ctx)[4].item = plant

    face_and_interact(ctx, 4)

    for i = 5, #slots(ctx) do
        assert(slots(ctx)[i].item == nil,
            "slot " .. i .. " should be empty after stage-2 reject")
    end
    assert(slots(ctx)[4].item == plant, "source slot should still hold original plant")
    assert(plant.stage == 2, "source plant stage should still be 2")
    assert(g.bubble.visible == false, "bubble should not show after stage-2 reject")
    print("PASS: grafter: rejects stage-2 plant")
end

-- ── Test 2: source plant resets to stage 1 after successful clone ─────────────
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local plant = Plant.new(1)
    plant.stage = 3
    slots(ctx)[4].item = plant

    face_and_interact(ctx, 4)

    local source = slots(ctx)[4].item
    assert(source ~= nil, "source slot should still have a plant")
    assert(source.stage == 1,
        "source plant should reset to stage 1, got " .. tostring(source.stage))
    assert(source.ready == false, "source plant should not be ready after reset")
    print("PASS: grafter: source plant resets to stage 1 after clone")
end

-- ── Test 3: cloned plant has correct type ─────────────────────────────────────
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local plant = Plant.new(2)
    plant.stage = 3
    slots(ctx)[4].item = plant

    face_and_interact(ctx, 4)

    local clone = slots(ctx)[5].item
    assert(clone ~= nil, "clone should appear in slot 5")
    assert(clone.plant_type == 2,
        "cloned plant should be type 2, got " .. tostring(clone and clone.plant_type))
    print("PASS: grafter: cloned plant has correct type")
end

-- ── Test 4: clone auto-places into nearest empty slot ─────────────────────────
-- Source in slot 4. Slots 1-3 have tools. Nearest empty slot = 5 (distance 1).
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local plant = Plant.new(1)
    plant.stage = 3
    slots(ctx)[4].item = plant

    face_and_interact(ctx, 4)

    assert(slots(ctx)[5].item ~= nil, "clone should appear in slot 5 (nearest empty)")
    assert(slots(ctx)[5].item.plant_type == 1, "clone should have plant_type 1")
    for i = 6, #slots(ctx) do
        assert(slots(ctx)[i].item == nil, "slot " .. i .. " should remain empty")
    end
    assert(ctx.gs.player.held_item == g, "grafter should stay in player's hand")
    print("PASS: grafter: clone auto-places into nearest empty slot")
end

-- ── Test 5: no empty slot → bubble visible, source untouched ──────────────────
-- Fill slots 4-10 so every slot is occupied.
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local source = Plant.new(1)
    source.stage = 3
    slots(ctx)[4].item = source
    for i = 5, #slots(ctx) do
        slots(ctx)[i].item = Plant.new(1)
    end

    face_and_interact(ctx, 4)

    assert(g.bubble.visible == true, "bubble should be visible when no empty slot exists")
    assert(slots(ctx)[4].item == source, "source slot should still hold original plant")
    assert(source.stage == 3,
        "source plant should still be stage 3, got " .. tostring(source.stage))
    print("PASS: grafter: no empty slot → bubble visible, source untouched")
end

-- ── Test 6: bubble timer expires and hides bubble ─────────────────────────────
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local source = Plant.new(1)
    source.stage = 3
    slots(ctx)[4].item = source
    for i = 5, #slots(ctx) do
        slots(ctx)[i].item = Plant.new(1)
    end

    face_and_interact(ctx, 4)
    assert(g.bubble.visible == true, "bubble should be visible immediately after no-space trigger")

    -- Advance 2 s; bubble timer is 1.5 s so it should have expired
    runner.tick(ctx, 2, 1.0)

    assert(g.bubble.visible == false, "bubble should hide after 1.5 s timer expires")
    print("PASS: grafter: bubble hides after 1.5 s timer expires")
end

-- ── Test 7: tie-breaking — lower flat index preferred ─────────────────────────
-- Source in slot 5 (row 1, col 5, px=6.5). Slots 1-3 are tools; slot 4 is empty; slot 6 is empty.
-- Both slots 4 and 6 are at flat-array distance 1 from slot 5. Lower index (4) should win.
do
    local ctx = runner.setup()
    local g   = Grafter.new()
    ctx.gs.player.held_item = g

    local plant = Plant.new(1)
    plant.stage = 3
    slots(ctx)[5].item = plant
    -- Fill slots 7-10 so only 4 and 6 compete at distance 1
    for i = 7, #slots(ctx) do
        slots(ctx)[i].item = Plant.new(1)
    end

    face_and_interact(ctx, 5)

    assert(slots(ctx)[4].item ~= nil,
        "clone should land in slot 4 (lower-index tie-breaker), got nil")
    assert(slots(ctx)[4].item.plant_type == 1, "clone in slot 4 should have plant_type 1")
    assert(slots(ctx)[6].item == nil, "slot 6 should remain empty (tie went to slot 4)")
    print("PASS: grafter: tie-breaking prefers lower flat index")
end

print("ALL TESTS PASSED")
