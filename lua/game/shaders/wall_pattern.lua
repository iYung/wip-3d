local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/wall_pattern.glsl")

-- In 3D, tile_size is set to the pattern dimensions so the full pattern
-- maps to exactly one wall tile (UV 0–1 maps to the full pattern width).
return {
    apply = function(pattern_img, _wall_img)
        local pw, ph = pattern_img:getDimensions()
        shader:send("pattern_tex",  pattern_img)
        shader:send("pattern_size", {pw, ph})
        shader:send("world_origin", {0, 0})
        shader:send("tile_size",    {pw, ph})
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
