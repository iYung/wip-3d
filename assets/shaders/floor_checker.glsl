extern float player_x;
extern float player_y;
extern float player_angle;
extern float hover_x;
extern float hover_y;

const float SW       = 1280.0;
const float SH       = 720.0;
const float HALF_TAN = 0.57735026919; // tan(pi/6), matching FOV = pi/3

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float row_dist = (SH * 0.5) / (sc.y - SH * 0.5);

    float dir_x   = cos(player_angle);
    float dir_y   = sin(player_angle);
    float plane_x = -dir_y * HALF_TAN;
    float plane_y =  dir_x * HALF_TAN;
    float cam_x   = 2.0 * sc.x / SW - 1.0;

    float wx = player_x + row_dist * (dir_x + plane_x * cam_x);
    float wy = player_y + row_dist * (dir_y + plane_y * cam_x);

    float tile_x = floor(wx);
    float tile_y = floor(wy);
    bool is_hover = (tile_x == hover_x && tile_y == hover_y);
    bool checker  = mod(tile_x + tile_y, 2.0) < 1.0;

    vec3 col = is_hover  ? vec3(0.75, 0.70, 0.45)
             : checker   ? vec3(0.42, 0.37, 0.30)
             :              vec3(0.28, 0.24, 0.18);
    return vec4(col, 1.0);
}
