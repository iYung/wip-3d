local Customer        = require("lua/game/customer")
local customer_scripts = require("lua/game/data/customer_scripts")

local function make_customer()
    return Customer.new(-3.0, -3.0, 0)
end

-- Test 1: serve() with no after_messages → straight to walking_out
do
    local c = make_customer()
    c:show({ plant_type = 1, messages = {"Hello"} })
    c:advance()   -- exhaust messages
    c:serve()

    assert(c.state == "walking_out",
        "expected walking_out with no after_messages, got " .. c.state)
    assert(c.heart_bubble.visible,
        "expected heart_bubble visible after serve with no after_messages")
    print("PASS: serve() with no after_messages transitions to walking_out")
end

-- Test 2: serve() with after_messages → talking_after, bubble visible
do
    local c = make_customer()
    c:show({ plant_type = 1, messages = {"Hello"}, after_messages = {"Bye!", "See you!"} })
    c:advance()
    c:serve()

    assert(c.state == "talking_after",
        "expected talking_after after serve(), got " .. c.state)
    assert(c.bubble.visible,
        "expected bubble visible in talking_after state")
    assert(c._full_text == "Bye!",
        "expected first after_message as _full_text, got " .. tostring(c._full_text))
    print("PASS: serve() with after_messages transitions to talking_after")
end

-- Test 3: line_complete() in talking_after only checks reveal_index
do
    local c = make_customer()
    c:show({ plant_type = 1, messages = {}, after_messages = {"Hi"} })
    c:serve()

    assert(c.state == "talking_after",
        "setup: expected talking_after")
    assert(not c:line_complete(),
        "line should not be complete at reveal_index=0")
    c:skip_reveal()
    assert(c:line_complete(),
        "line should be complete after skip_reveal")
    print("PASS: line_complete() works correctly in talking_after state")
end

-- Test 4: advance_after() advances through messages, then walking_out
do
    local c = make_customer()
    c:show({ plant_type = 1, messages = {}, after_messages = {"Line 1", "Line 2"} })
    c:serve()

    assert(c.state == "talking_after", "setup: expected talking_after")
    c:skip_reveal()
    c:advance_after()   -- exhaust line 1, advance to line 2

    assert(c.state == "talking_after",
        "expected still talking_after after first advance, got " .. c.state)
    assert(c._full_text == "Line 2",
        "expected _full_text='Line 2', got " .. tostring(c._full_text))

    c:skip_reveal()
    c:advance_after()   -- exhaust line 2, finish

    assert(c.state == "walking_out",
        "expected walking_out after all after_messages exhausted, got " .. c.state)
    assert(c.done_after,
        "expected done_after=true after all messages exhausted")
    assert(c.heart_bubble.visible,
        "expected heart_bubble visible after post-sale dialogue completes")
    print("PASS: advance_after() advances messages and transitions to walking_out")
end

-- Test 5: advance_after() with incomplete reveal skips (does not advance)
do
    local c = make_customer()
    c:show({ plant_type = 1, messages = {}, after_messages = {"Hello world"} })
    c:serve()

    assert(not c:line_complete(), "setup: line should not be complete yet")
    local before_index = c.after_msg_index
    c:advance_after()   -- should skip_reveal, not advance

    assert(c.after_msg_index == before_index,
        "after_msg_index should not advance when reveal incomplete")
    assert(c.reveal_index == #c._full_text,
        "expected reveal_index at end after advance_after skips reveal")
    assert(c.state == "talking_after",
        "state should remain talking_after, got " .. c.state)
    print("PASS: advance_after() skips reveal when line not complete")
end

-- Test 6: done_after initialised correctly based on after_messages presence
do
    local c1 = make_customer()
    c1:show({ plant_type = 1, messages = {} })
    assert(c1.done_after,
        "expected done_after=true when no after_messages given")

    local c2 = make_customer()
    c2:show({ plant_type = 1, messages = {}, after_messages = {"Something"} })
    assert(not c2.done_after,
        "expected done_after=false when after_messages present")
    print("PASS: done_after initialised correctly from cfg")
end

-- Test 7: Sage entries exist in customer_scripts (4 chapters, all with after_messages)
do
    local sage_entries = {}
    for _, entry in ipairs(customer_scripts) do
        if entry.id == "sage" then
            sage_entries[#sage_entries + 1] = entry
        end
    end

    assert(#sage_entries == 4,
        "expected 4 Sage chapters, got " .. #sage_entries)
    for i, entry in ipairs(sage_entries) do
        assert(entry.chapter == i,
            "expected Sage chapter=" .. i .. ", got " .. tostring(entry.chapter))
        assert(entry.accessory == "monocle",
            "expected Sage accessory='monocle', got " .. tostring(entry.accessory))
        assert(entry.after_messages and #entry.after_messages > 0,
            "expected Sage chapter " .. i .. " to have after_messages")
    end
    assert(sage_entries[1].trigger.count == 0,
        "expected Sage chapter 1 trigger count=0 (guaranteed early), got " .. tostring(sage_entries[1].trigger.count))
    print("PASS: Sage 4-chapter arc present in customer_scripts with correct structure")
end

-- Test 8: make_full_text returns raw message, no name prefix
do
    local c = make_customer()
    c:show({ plant_type = 1, name = "Pete", messages = {"Hello there"} })

    assert(c._full_text == "Hello there",
        "expected _full_text='Hello there' (no name prefix), got " .. tostring(c._full_text))
    assert(not c._full_text:find("Pete"),
        "expected no name prefix in _full_text, got " .. tostring(c._full_text))
    print("PASS: make_full_text returns raw message without name prefix")
end

-- Test 9: all non-Sage customer_scripts entries have after_messages
do
    local NON_SAGE_IDS = { "old_pete", "mayor_bloom", "the_collector", "mira", "dottie" }
    local id_set = {}
    for _, id in ipairs(NON_SAGE_IDS) do id_set[id] = true end

    local missing = {}
    for i, entry in ipairs(customer_scripts) do
        if id_set[entry.id] then
            if not (entry.after_messages and #entry.after_messages > 0) then
                missing[#missing + 1] = entry.id .. "[" .. i .. "]"
            end
        end
    end

    assert(#missing == 0,
        "entries missing after_messages: " .. table.concat(missing, ", "))
    print("PASS: all non-Sage customer_scripts entries have after_messages")
end

print("ALL TESTS PASSED")
