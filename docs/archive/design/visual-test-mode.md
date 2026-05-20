## Goal

Add `--visual tests/foo.lua` mode: runs a test file with a real window and real graphics, driven by `HeadlessInput`. Frame-by-frame rendering is achieved via a coroutine — `runner.tick()` yields once per logical game frame so `love.draw()` fires between every tick. Tests run unchanged in both `--headless` and `--visual`.

## Affected files

| File | Action |
|---|---|
| `main.lua` | Detect `--visual`, set up coroutine-driven love.load/update/draw callbacks |
| `lua/headless/runner.lua` | Store current ctx in `runner._visual_ctx` on each `setup()`; yield inside `tick()` when called from a coroutine |

## What changes

### main.lua

A new parse block at the top detects `--visual` + optional test-file path from `arg` (same pattern as `--headless`). When visual mode is active:

- No stubs are loaded — `love.graphics` is real.
- `love.load()`: calls `love.graphics.setDefaultFilter`, creates the 1280×720 canvas, sets `_G.runner = runner`, and wraps `dofile(test_file)` in a coroutine (`test_co`).
- `love.update(dt)`: resumes `test_co` once. If the coroutine is dead after the resume and `ok` is true → `print("PASS"); love.event.quit(0)`. If dead and `ok` is false → `print("FAIL: " .. err); love.event.quit(1)`.
- `love.draw()`: reads `runner._visual_ctx`. If non-nil, renders through the same canvas/scale pipeline as normal `love .` mode — `setCanvas`, `clear`, `ctx.sm:draw()`, blit with letterbox scale.
- `love.keypressed`: escape quits, same as normal mode.
- `return` at the bottom of the visual block so normal `love.load` etc. are not defined.

The `--headless` and normal paths are unchanged.

### lua/headless/runner.lua

Two additions, both backward-compatible:

1. **`runner._visual_ctx`** — `runner.setup()` assigns `runner._visual_ctx = ctx` before returning. This gives `love.draw()` a reference to whichever ctx was set up most recently (important when a test file calls `runner.setup()` multiple times). In headless mode this field is simply never read.

2. **Coroutine yield in `runner.tick()`** — at the end of each iteration of the `for _ = 1, n` loop, if `coroutine.running()` is non-nil (i.e., we are inside a coroutine), call `coroutine.yield()`. This suspends the test coroutine, returns control to `love.update`, and allows `love.draw()` to render the frame before the next tick resumes. In headless mode `coroutine.running()` is nil so the yield never fires.

## What stays the same

- `conf.lua` — no changes; window/graphics modules are already enabled by default, and visual mode does not suppress them.
- `lua/headless/stubs.lua` — not loaded in visual mode.
- `lua/headless/input.lua` — used as-is; `HeadlessInput` works identically in both modes.
- All test files — no changes needed; `runner.setup()` and `runner.tick()` have the same signatures.
- Normal `love .` path — unchanged.

## Open questions

None.
