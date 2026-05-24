# CRT Shader Buy Scene Checklist

- [x] Task A — `assets/shaders/crt.glsl` — copy file verbatim from `/root/wip/assets/shaders/crt.glsl` to `/root/wip-3d/assets/shaders/crt.glsl`
- [x] Task B — `lua/game/shaders/crt.lua` — copy file verbatim from `/root/wip/lua/game/shaders/crt.lua` to `/root/wip-3d/lua/game/shaders/crt.lua`
- [x] Task C — `lua/game/scenes/buy_scene.lua` — add `local CRT = require("lua/game/shaders/crt")` at the top with the other requires; add `self.canvas = love.graphics.newCanvas(1280, 720)` in `BuyScene.new`; wrap the entire body of `BuyScene:draw()` by saving/restoring the canvas via `love.graphics.getCanvas()`/`setCanvas`, then draw `self.canvas` through `CRT.apply()`/`CRT.clear()`
