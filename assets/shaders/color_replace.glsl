uniform vec4 color_a;
uniform vec4 color_b;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 px     = Texel(tex, tc);
    vec4 result = px.r * color_a + px.b * color_b;
    result.a    = px.a;
    return result;
}
