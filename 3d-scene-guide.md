# Adding a 3D Scene

This project now includes a DDA raycaster engine alongside the existing 2D store. Use this guide to wire up a first-person 3D scene.

---

## How the engine layers fit together

```
Scene              ← pure lifecycle base (update / draw / on_enter / on_exit stubs)
├── Scene2D        ← adds self.drawer + self.camera   (all current game scenes)
└── Scene3D        ← adds self.raycaster              (new 3D scenes go here)
```

`Scene3D` is a drop-in replacement for `Scene2D` as a base class. The SceneManager treats them identically — `switch()` calls `on_exit` / `on_enter` the same way.

---

## Step 1 — Define a map grid

```lua
local MAP_GRID = {
    { 1,1,1,1,1,1,1 },
    { 1,0,0,0,0,0,1 },
    { 1,0,1,0,1,0,1 },
    { 1,0,0,0,0,0,1 },
    { 1,1,1,1,1,1,1 },
}
```

- `1` = solid wall, `0` = open floor
- Any non-zero integer is a wall (useful for future texture ids)
- Grid is 1-indexed. Position `(1.5, 1.5)` is the center of the top-left open cell

---

## Step 2 — Create the scene file

`lua/game/scenes/my_3d_scene.lua`:

```lua
local Scene3D  = require("lua/core/scene_3d")
local Map      = require("lua/core/map")
local Player3D = require("lua/game/player_3d")

local MAP_GRID = {
    { 1,1,1,1,1,1,1,1 },
    { 1,0,0,0,0,0,0,1 },
    { 1,0,1,1,0,0,0,1 },
    { 1,0,0,0,0,1,0,1 },
    { 1,0,0,0,0,0,0,1 },
    { 1,1,1,1,1,1,1,1 },
}

local My3DScene = setmetatable({}, { __index = Scene3D })
My3DScene.__index = My3DScene

function My3DScene.new()
    return setmetatable(Scene3D.new(), My3DScene)
end

function My3DScene:on_enter()
    self.map    = Map.new(MAP_GRID)
    self.player = Player3D.new(2.5, 2.5, 0)
end

function My3DScene:update(dt)
    self.player:update(dt)
end

function My3DScene:draw()
    self.raycaster:draw(self.map, self.player.x, self.player.y, self.player.angle)
    -- HUD drawn here is screen-space (no camera transform in 3D mode)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(
        string.format("pos (%.1f, %.1f)  angle %.2f", self.player.x, self.player.y, self.player.angle),
        16, 16
    )
end

return My3DScene
```

---

## Step 3 — Switch to the scene

From any existing scene (e.g. triggered from StartScene or StoreScene):

```lua
local My3DScene = require("lua/game/scenes/my_3d_scene")
self.scene_manager:switch(My3DScene.new())
```

---

## Player3D controls

`lua/game/player_3d.lua` — its own internal `Input` instance, independent of the shared 2D game input.

| Key | Action |
|-----|--------|
| W / Up | Move forward |
| S / Down | Move backward |
| A / Left | Turn left |
| D / Right | Turn right |

Speed constants at the top of the file:

```lua
local MOVE_SPEED = 3.0   -- grid units per second
local TURN_SPEED = 2.5   -- radians per second
```

Swap `Player3D` for your own controller if you need collision detection, mouse-look, or a minimap cursor.

---

## Coordinate system

| Value | Meaning |
|-------|---------|
| `(mx, my)` | Integer grid cell — column `mx`, row `my`, both 1-indexed |
| `(px, py)` | Float world position — `(1.5, 1.5)` = center of cell `(1,1)` |
| `angle = 0` | Facing right (+x) |
| `angle = π/2` | Facing down (+y), matching Love2D screen axes |

The raycaster does not do collision — `Player3D` moves freely through walls. Add collision in your scene's `update()` by clamping `player.x`/`player.y` against `self.map:is_wall()` before or after calling `player:update(dt)`.

---

## Mixing 2D and 3D in one frame

You can draw a 2D overlay on top of the 3D view. The raycaster writes directly to the screen; anything drawn after it in `draw()` appears on top:

```lua
function My3DScene:draw()
    -- 3D world
    self.raycaster:draw(self.map, self.player.x, self.player.y, self.player.angle)

    -- 2D overlay (crosshair, minimap, etc.)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("fill", 638, 358, 4, 4)  -- crosshair dot
end
```

There is no Camera transform active during 3D rendering, so all post-raycaster draws are in screen space (0,0 = top-left).

---

## Extending the raycaster

`lua/core/raycaster.lua` is intentionally minimal. Common extensions:

| Feature | Where to add it |
|---------|----------------|
| Wall textures | `Raycaster:draw()` — map `cell()` value to a texture, sample the column |
| Floor / ceiling textures | Replace the solid-rect background with a per-pixel floor-cast loop |
| Sprite billboards | Post-process pass after the wall loop; sort by distance, clip against depth buffer |
| Collision | `Player3D:update()` or your scene's `update()` — check `map:is_wall()` at the new position before applying movement |
| Mouse-look | Replace the A/D turn logic with `love.mousemoved` delta in your scene |
