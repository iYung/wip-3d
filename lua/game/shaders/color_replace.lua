local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/color_replace.glsl")

return {
    apply = function(primary, secondary)
        love.graphics.setShader(shader)
        shader:send("color_a", primary)
        shader:send("color_b", secondary)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
