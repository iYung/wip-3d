# CRT Shader on Buy Scene

## Goal

Port the CRT post-processing effect from `wip` to `wip-3d`'s buy scene. The buy scene should render through a canvas and then apply the CRT shader (barrel distortion, chromatic aberration, scanlines, vignette) when drawing that canvas to screen — exactly matching `wip`.

## Affected files

- `lua/game/shaders/crt.lua` — new file (copy from wip)
- `assets/shaders/crt.glsl` — new file (copy from wip)
- `lua/game/scenes/buy_scene.lua` — add canvas init + CRT wrap in draw

## What changes

1. **New shader files** — `lua/game/shaders/crt.lua` and `assets/shaders/crt.glsl` are copied verbatim from `wip`. The `crt.lua` wrapper uses `lua/core/shader` which already exists in wip-3d.

2. **Canvas init** — In `BuyScene.new`, add:
   ```lua
   self.canvas = love.graphics.newCanvas(1280, 720)
   ```

3. **Draw wrapping** — In `BuyScene:draw()`, save the current canvas, redirect all rendering to `self.canvas`, restore, then draw the canvas through the CRT shader:
   ```lua
   local prev_canvas = love.graphics.getCanvas()
   love.graphics.setCanvas(self.canvas)
   -- ... existing draw body ...
   love.graphics.setCanvas(prev_canvas)
   CRT.apply()
   love.graphics.draw(self.canvas, 0, 0)
   CRT.clear()
   ```

## What stays the same

- All existing draw logic inside `BuyScene:draw()` is unchanged — it just runs inside the canvas redirect.
- `update`, `on_enter`, `on_exit`, `_confirm` — untouched.
- All other scenes — unaffected.
- The `lua/core/shader.lua` helper is reused as-is.

## Open questions

None — the wip implementation is a direct copy/wire-up with no ambiguity.
