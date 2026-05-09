# Coding Notes

## Folder Structure

```
luagame/
├── main.lua
└── lua/
    ├── core/
    │   ├── sprite.lua
    │   ├── spriteset.lua
    │   ├── drawer.lua
    │   ├── camera.lua
    │   ├── scene.lua
    │   └── scene_manager.lua
    └── game/
        ├── input.lua
        ├── game_state.lua
        ├── player.lua
        ├── store.lua
        ├── slot.lua
        ├── item.lua
        ├── watering_can.lua
        ├── grafter.lua
        ├── pc_store.lua
        ├── plant.lua
        ├── scenes/
        │   ├── store_scene.lua
        │   └── buy_scene.lua
        └── data/
            └── plant_cooldowns.lua
```

---

## Lua Class Pattern

All classes follow the same pattern:

```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new(...)
    local self = setmetatable({}, MyClass)
    -- init
    return self
end

return MyClass
```

Inheritance:

```lua
local Base = require("core/sprite")
local Child = setmetatable({}, { __index = Base })
Child.__index = Child

function Child.new(...)
    local self = Base.new(...)
    return setmetatable(self, Child)
end

return Child
```

---

## Conventions

- File and variable names: `snake_case`
- Class names: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- One class per file, filename matches class name in snake_case
- Require paths are relative to project root, no leading `./`

---

## Requiring Files

```lua
local Sprite = require("lua/core/sprite")
local Plant  = require("lua/game/plant")
```

---

## Resolution

Logical resolution: **1280×720**. Everything renders to a canvas at that size. The canvas is then scaled to fit the window while maintaining aspect ratio — letterboxed if the window is larger or a different ratio.

```lua
-- conf.lua
function love.conf(t)
    t.window.width  = 1280
    t.window.height = 720
    t.window.title  = "plant game"
    t.window.resizable = true
end
```

Scaling logic in `main.lua`:

```lua
local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
        scene_manager:draw()
    love.graphics.setCanvas()

    local sw, sh = love.graphics.getDimensions()
    local scale  = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox     = (sw - LOGICAL_W * scale) / 2
    local oy     = (sh - LOGICAL_H * scale) / 2

    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end
```

World coordinates and slot widths should be sized to feel natural at 1280×720.

---

## Data Tables

Game config lives in `game/data/` as plain Lua tables returning a value:

```lua
-- game/data/plant_cooldowns.lua
return {
    [1] = { [1] = 30, [2] = 60, [3] = 90 },
    -- [plant_type] = { [stage] = seconds }
}
```
