local Shader = require("lua/core/shader")

local SW  = 1280
local SH  = 720
local FOV         = math.pi / 3  -- 60 degrees
local WALL_HEIGHT = 1.5

local Raycaster = {}
Raycaster.__index = Raycaster

function Raycaster.new()
    local self = setmetatable({}, Raycaster)
    self.z_buffer      = {}
    self._floor_shader = Shader.load("assets/shaders/floor_checker.glsl")
    self._quad_cache   = {}
    return self
end

function Raycaster:_get_tex_quads(tex)
    if self._quad_cache[tex] then return self._quad_cache[tex] end
    local quads  = {}
    local tex_w  = tex:getWidth()
    local tex_h  = tex:getHeight()
    for tx = 0, tex_w - 1 do
        quads[tx] = love.graphics.newQuad(tx, 0, 1, tex_h, tex_w, tex_h)
    end
    self._quad_cache[tex] = quads
    return quads
end

function Raycaster:draw(map, px, py, angle, hover_tile, wall_textures)
    love.graphics.setColor(0.15, 0.15, 0.25, 1)
    love.graphics.rectangle("fill", 0, 0, SW, SH / 2)
    local fs = self._floor_shader
    fs:send("player_x",    px)
    fs:send("player_y",    py)
    fs:send("player_angle", angle)
    fs:send("hover_x", hover_tile and hover_tile.x or -9999.0)
    fs:send("hover_y", hover_tile and hover_tile.y or -9999.0)
    love.graphics.setShader(fs)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, SH / 2, SW, SH / 2)
    love.graphics.setShader()

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
            self.z_buffer[col] = perp
            local h    = math.floor(SH * WALL_HEIGHT / perp)
            local y1   = math.floor(SH / 2 - h / 2)
            local y2   = math.floor(SH / 2 + h / 2)
            local br   = side == 1 and 0.5 or 0.8
            local tex = wall_textures and wall_textures[map:cell(mx, my)]
            if tex then
                local hit_x
                if side == 0 then
                    hit_x = py + perp * rdy
                else
                    hit_x = px + perp * rdx
                end
                hit_x = hit_x - math.floor(hit_x)
                local tex_w = tex:getWidth()
                local tx = math.max(0, math.min(tex_w - 1, math.floor(hit_x * tex_w)))
                local quads = self:_get_tex_quads(tex)
                love.graphics.setColor(br, br, br, 1)
                love.graphics.draw(tex, quads[tx], col, y1, 0, 1, h / tex:getHeight())
            else
                love.graphics.setColor(br, br * 0.5, br * 0.3, 1)
                love.graphics.line(col, y1, col, y2)
            end
        else
            self.z_buffer[col] = math.huge
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- sprites: array of { x, y, image, scale?, voffset?, flip_x?, setup?, teardown? }
--   scale   : billboard size multiplier (default 1.0)
--   voffset : world-unit height above floor (default 0, positive = up)
--   flip_x  : mirror the sprite horizontally (default false)
--   setup   : called before drawing (e.g. apply shader)
--   teardown: called after drawing (e.g. clear shader)
function Raycaster:draw_sprites(sprites, px, py, angle)
    local dir_x   = math.cos(angle)
    local dir_y   = math.sin(angle)
    -- left-perpendicular plane scaled by tan(FOV/2)
    local half_tan = math.tan(FOV / 2)
    local plane_x  = -dir_y * half_tan
    local plane_y  =  dir_x * half_tan
    local inv_det  = 1 / (plane_x * dir_y - dir_x * plane_y)

    -- sort far-to-near
    local sorted = {}
    for _, spr in ipairs(sprites) do
        local dx = spr.x - px
        local dy = spr.y - py
        sorted[#sorted + 1] = { spr = spr, dist2 = dx * dx + dy * dy }
    end
    table.sort(sorted, function(a, b) return a.dist2 > b.dist2 end)

    for _, entry in ipairs(sorted) do
        local spr = entry.spr
        local dx  = spr.x - px
        local dy  = spr.y - py

        local tx = inv_det * ( dir_y * dx - dir_x * dy)
        local tz = inv_det * (-plane_y * dx + plane_x * dy)

        if tz > 0.05 and spr.image then
            local img  = spr.image
            local iw   = img:getWidth()
            local ih   = img:getHeight()
            local sc   = spr.scale or 1.0
            local h    = math.min(SH * 2, math.floor(SH / tz * sc))
            local w    = math.floor(h * iw / ih)
            local sx   = math.floor(SW / 2 * (1 + tx / tz))
            local x0   = sx - w / 2
            local x1   = sx + w / 2

            -- vertical offset for floating sprites (bubbles, etc.)
            local voff      = spr.voffset or 0
            local y_center  = SH / 2 + (WALL_HEIGHT / 2 - sc / 2 - voff) * (SH / tz)
            local y0        = math.floor(y_center - h / 2)

            local clip_y  = math.max(0, y0)
            local clip_bot = math.min(SH, y0 + h)
            local clip_h  = clip_bot - clip_y

            local col_start = math.max(0, math.floor(x0))
            local col_end   = math.min(SW - 1, math.floor(x1) - 1)

            if clip_h > 0 and col_start <= col_end then
                if spr.setup then spr.setup() end

                local run_start = nil
                for col = col_start, col_end do
                    local visible = tz < (self.z_buffer[col] or math.huge)
                    if visible and not run_start then
                        run_start = col
                    elseif not visible and run_start then
                        love.graphics.setScissor(run_start, clip_y, col - run_start, clip_h)
                        love.graphics.setColor(1, 1, 1, 1)
                        if spr.flip_x then
                            love.graphics.draw(img, math.floor(x0) + w, y0, 0, -w / iw, h / ih)
                        else
                            love.graphics.draw(img, math.floor(x0), y0, 0, w / iw, h / ih)
                        end
                        run_start = nil
                    end
                end
                if run_start then
                    local rw = col_end - run_start + 1
                    love.graphics.setScissor(run_start, clip_y, rw, clip_h)
                    love.graphics.setColor(1, 1, 1, 1)
                    if spr.flip_x then
                        love.graphics.draw(img, math.floor(x0) + w, y0, 0, -w / iw, h / ih)
                    else
                        love.graphics.draw(img, math.floor(x0), y0, 0, w / iw, h / ih)
                    end
                end
                love.graphics.setScissor()

                if spr.teardown then spr.teardown() end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Raycaster
