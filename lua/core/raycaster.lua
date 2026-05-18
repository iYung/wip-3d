local SW  = 1280
local SH  = 720
local FOV = math.pi / 3  -- 60 degrees

local Raycaster = {}
Raycaster.__index = Raycaster

function Raycaster.new()
    return setmetatable({}, Raycaster)
end

function Raycaster:draw(map, px, py, angle)
    love.graphics.setColor(0.15, 0.15, 0.25, 1)
    love.graphics.rectangle("fill", 0, 0, SW, SH / 2)
    love.graphics.setColor(0.35, 0.3, 0.25, 1)
    love.graphics.rectangle("fill", 0, SH / 2, SW, SH / 2)

    for col = 0, SW - 1 do
        local ray_angle = angle + (col / SW - 0.5) * FOV
        local rdx = math.cos(ray_angle)
        local rdy = math.sin(ray_angle)

        local mx = math.floor(px)
        local my = math.floor(py)

        local ddx = math.abs(rdx) < 1e-10 and 1e10 or math.abs(1 / rdx)
        local ddy = math.abs(rdy) < 1e-10 and 1e10 or math.abs(1 / rdy)

        local sx, sdx, sy, sdy
        if rdx < 0 then sx = -1; sdx = (px - mx)      * ddx
        else             sx =  1; sdx = (mx + 1 - px)  * ddx end
        if rdy < 0 then sy = -1; sdy = (py - my)      * ddy
        else             sy =  1; sdy = (my + 1 - py)  * ddy end

        local hit, side = false, 0
        for _ = 1, 64 do
            if sdx < sdy then sdx = sdx + ddx; mx = mx + sx; side = 0
            else              sdy = sdy + ddy; my = my + sy; side = 1 end
            if map:is_wall(mx, my) then hit = true; break end
        end

        if hit then
            local perp = side == 0 and (sdx - ddx) or (sdy - ddy)
            local h    = math.floor(SH / perp)
            local y1   = math.floor(SH / 2 - h / 2)
            local y2   = math.floor(SH / 2 + h / 2)
            local br   = side == 1 and 0.5 or 0.8
            love.graphics.setColor(br, br * 0.5, br * 0.3, 1)
            love.graphics.line(col, y1, col, y2)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Raycaster
