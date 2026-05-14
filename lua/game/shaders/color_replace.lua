local src = [[
    uniform vec4 color_a;
    uniform vec4 color_b;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 px     = Texel(tex, tc);
        vec4 result = px.r * color_a + px.b * color_b;
        result.a    = px.a;
        return result;
    }
]]

local shader = love.graphics.newShader(src)

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
