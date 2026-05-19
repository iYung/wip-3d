local T = {}

-- Raises an error if `cond` is falsy.
function T.assert(cond, msg)
    if not cond then
        error(msg or "assertion failed", 2)
    end
end

-- Raises if `a ~= b`, including both values in the message.
function T.eq(a, b, msg)
    if a ~= b then
        local detail = string.format("expected %s == %s", tostring(a), tostring(b))
        error(msg and (msg .. ": " .. detail) or detail, 2)
    end
end

-- Raises if math.abs(a - b) > eps.
function T.approx(a, b, eps, msg)
    if math.abs(a - b) > eps then
        local detail = string.format(
            "expected |%s - %s| <= %s, got %s",
            tostring(a), tostring(b), tostring(eps), tostring(math.abs(a - b))
        )
        error(msg and (msg .. ": " .. detail) or detail, 2)
    end
end

-- Raises if calling fn() does NOT throw.
function T.err(fn, msg)
    local ok = pcall(fn)
    if ok then
        error(msg or "expected an error but none was raised", 2)
    end
end

return T
