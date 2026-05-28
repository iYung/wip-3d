-- Test 1: Store initialises at 7 cols x 5 rows = 35 slots
do
    local ctx   = runner.setup()
    local store = ctx.gs.store

    assert(#store:all_slots() == 35,
        "expected 35 initial slots, got " .. #store:all_slots())
    assert(store:active_rows() == 5,
        "expected 5 initial rows, got " .. store:active_rows())
    print("PASS: store starts 7x5 (35 slots)")
end

-- Test 2: grow() adds exactly one full row (7 slots)
do
    local ctx   = runner.setup()
    local store = ctx.gs.store
    local before = #store:all_slots()

    store:grow()

    local added = #store:all_slots() - before
    assert(added == 7,
        "expected grow() to add 7 slots, got " .. added)
    assert(store:active_rows() == 6,
        "expected 6 rows after grow(), got " .. store:active_rows())
    print("PASS: grow() adds one full row of 7 slots")
end

-- Test 3: grow() is idempotent when called multiple times — each call adds
-- exactly one row regardless of how many have already been added
do
    local ctx   = runner.setup()
    local store = ctx.gs.store

    store:grow()
    store:grow()

    assert(store:active_rows() == 7,
        "expected 7 rows after two grows, got " .. store:active_rows())
    assert(#store:all_slots() == 49,
        "expected 49 slots after two grows, got " .. #store:all_slots())
    print("PASS: two grows produce 7 rows / 49 slots")
end

-- Test 4: New row slots have correct world positions
-- Row 6 (first expanded row) should be at y = 4.5 + 5*1.0 = 9.5
do
    local ctx   = runner.setup()
    local store = ctx.gs.store
    local before_count = #store:all_slots()

    store:grow()

    local new_slots = {}
    for i = before_count + 1, #store:all_slots() do
        new_slots[#new_slots + 1] = store:all_slots()[i]
    end

    assert(#new_slots == 7, "expected 7 new slots")
    for _, slot in ipairs(new_slots) do
        assert(math.abs(slot.py - 9.5) < 0.001,
            "expected new slot py=9.5, got " .. slot.py)
    end
    print("PASS: grown row has correct y position (9.5)")
end

print("ALL TESTS PASSED")
