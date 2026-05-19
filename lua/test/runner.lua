-- runner.lua
-- Runs all known test modules and reports results.
-- Call runner.run() from love.run in headless/test mode.

local runner = {}

-- Explicit list of test module paths (relative to project root).
-- Add new test files here as they are created.
local TEST_PATHS = {
    "tests/unit/plant_test",
    "tests/integration/currency_test",
    "tests/integration/golden_lotus_sim_test",
}

function runner.run()
    local passed = 0
    local failed = 0

    for _, path in ipairs(TEST_PATHS) do
        -- Derive a short display name from the path.
        local name = path:match("[^/]+$") or path

        local ok, err = pcall(require, path)
        if ok then
            passed = passed + 1
            print("PASS " .. name)
        else
            failed = failed + 1
            -- Normalise the error to a single-line string.
            local msg = tostring(err):gsub("\n", " ")
            print("FAIL " .. name .. ": " .. msg)
        end
    end

    local total = passed + failed
    print(passed .. "/" .. total .. " passed")

    if failed == 0 then
        love.event.quit(0)
    else
        love.event.quit(1)
    end
end

return runner
