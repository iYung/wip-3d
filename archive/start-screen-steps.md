# Start Screen Steps

Goal: show a title screen with New Game / Continue / Exit buttons before the game starts.

---

## Step 1 — Create StartScene

- [x] Create `lua/game/scenes/start_scene.lua`
- [x] Extend `Scene` (same pattern as `StoreScene` / `BuyScene`)
- [x] Accept `game_state`, `input`, and `scene_manager` in `StartScene.new()`

```lua
local Scene = require("lua/core/scene")
local StartScene = setmetatable({}, { __index = Scene })
StartScene.__index = StartScene

function StartScene.new(game_state, input, scene_manager)
    local self = Scene.new()
    setmetatable(self, StartScene)
    self.game_state    = game_state
    self.input         = input
    self.scene_manager = scene_manager
    return self
end
```

---

## Step 2 — Draw the Title Screen

- [x] In `StartScene:on_enter()` set up any Sprite/text drawables needed
- [x] In `StartScene:draw()` draw directly with `love.graphics` (no camera transform needed — screen-space UI)
  - Title text centered at roughly (640, 260)
  - Prompt text (e.g. `"Press any key"`) centered at roughly (640, 460)
- [x] The Scene base `draw()` calls `camera:attach/detach` around `drawer:draw()` — override it entirely if you only need 2D screen text, or call `super` first and layer text on top

```lua
function StartScene:draw()
    -- skip camera for a pure screen-space title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PLANT STORE", 0, 260, 1280, "center")
    love.graphics.printf("Press any key to start", 0, 460, 1280, "center")
end
```

---

## Step 3 — Handle Input and Transition

- [x] In `StartScene:update(dt)`, check `input:pressed("interact")` or `love.keyboard.isDown` for any key
- [x] On press, construct `StoreScene` and call `scene_manager:switch(store_scene)`

```lua
local StoreScene = require("lua/game/scenes/store_scene")

function StartScene:update(dt)
    -- any of the four mapped actions advances past the title
    if self.input:pressed("interact")
    or self.input:pressed("pick_up_down")
    or self.input:pressed("move_left")
    or self.input:pressed("move_right") then
        local store_scene = StoreScene.new(self.game_state, self.input, self.scene_manager)
        self.scene_manager:switch(store_scene)
    end
end
```

Alternatively, catch raw keypresses via `love.keypressed` in `main.lua` and forward them, but using the existing `Input` module keeps things consistent.

---

## Step 4 — Wire Up in main.lua

- [x] Require `StartScene` at the top of `main.lua`
- [x] In `love.load()`, create `StartScene` and pass it to `scene_manager:switch()` instead of `StoreScene`
- [x] `StoreScene` is no longer constructed in `love.load()`; `StartScene` constructs it on transition

```lua
-- main.lua (love.load diff)
local StartScene = require("lua/game/scenes/start_scene")

function love.load()
    canvas        = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")
    local gs      = GameState.new()
    scene_manager = SceneManager.new()
    local start   = StartScene.new(gs, input, scene_manager)
    scene_manager:switch(start)
end
```

---

## Step 5 — Verify

- [x] Launch the game — title screen appears, store does not load yet
- [x] Press a mapped key — transitions to StoreScene with no errors
- [x] `GameState` is the same instance across both scenes (constructed once in `love.load`)
- [x] `escape` still quits from either scene
