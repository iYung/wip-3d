## Goal

Add a headless test mode to wip-3d, mirroring the structure already used in `../wip`. Running `love . -- --headless tests/test_basics.lua` should execute a test file without a window, print PASS/FAIL, and exit with code 0 or 1.

## Affected files

| File | Action |
|---|---|
| `conf.lua` | Disable window/graphics/audio/etc. when `--headless` is in args |
| `main.lua` | Detect `--headless`, load stubs, call `runner.run(test_file)`, early-return |
| `lua/headless/stubs.lua` | No-op stubs for `love.graphics`, `love.keyboard`, `love.filesystem` — 3D-specific additions vs wip |
| `lua/headless/input.lua` | Scriptable HeadlessInput (press/hold/release) — identical API to wip |
| `lua/headless/runner.lua` | setup()/tick()/run() — adapted for the dual-input structure of wip-3d |
| `tests/test_basics.lua` | First test suite (initial state, movement, currency) |

## What changes

### conf.lua
Parse `--headless` from `arg` and disable all non-logic modules (window, graphics, audio, sound, joystick, touch, video) when found. Mirrors wip's conf.lua exactly.

### main.lua
At the top, parse `--headless` + optional test-file path from `arg`. When headless: `require("lua/headless/stubs")`, then `require("lua/headless/runner").run(test_file)`, then `return`. Non-headless path is unchanged.

### lua/headless/stubs.lua
Mirrors wip's stubs but adds 3D-specific graphics calls. Key additions over wip:

- `graphics_stub.newShader` — returns a shader-stub table with a no-op `send` method (the catch-all `new*` factory returns the image-stub which lacks `send`; this explicit override is required because both `Raycaster` and `ColorReplace` call `shader:send()`).
- `graphics_stub.newQuad` — returns `{}` (used by raycaster's per-column texture slicing; no behaviour needed in tests).
- `graphics_stub.line` — noop (raycaster untextured wall fallback).
- `graphics_stub.setScissor` — noop (raycaster sprite clipping).

All other graphics calls already covered by wip's catch-all or explicit noop list.

### lua/headless/input.lua
Identical to wip's `HeadlessInput`. Implements `press(action)`, `hold(action)`, `release(action)`, `update()`, `is_down(action)`, `pressed(action)`. Used for both scene-level actions and Player3D movement.

### lua/headless/runner.lua

**Dual-input structure.**  
`StoreScene` takes a scene-level input (E / F / pick_up_down) passed in at construction. `Player3D` creates its own internal `Input` object for WASD movement; that internal input is replaced with a `HeadlessInput` after the scene's `on_enter()` runs (which is where `_setup_store()` creates the Player3D).

`setup(scene_factory)`:
1. Create `gs`, `scene_input = HeadlessInput.new()`, `sm`.
2. Create scene via `scene_factory(gs, scene_input, sm)` or default to `StoreScene.new(...)`.
3. Call `sm:switch(scene)` — this triggers `on_enter()` → `_setup_store()` → Player3D is created.
4. If `scene.player3d` exists, create `move_input = HeadlessInput.new()` and install it as `scene.player3d.input`.
5. Return `{ gs, input=scene_input, move_input=move_input, sm, scene }`.

`tick(ctx, n, dt)`:
- Calls `ctx.input:update()` then `ctx.sm:update(dt)` for each of `n` frames.
- `ctx.move_input:update()` is **not** called here — `Player3D:update()` already calls `self.input:update()` internally, so movement presses/holds set before `tick()` are consumed at the right time.

`run(test_file)`:
- Identical to wip's runner.run: `_G.runner = runner`, pcall dofile, print PASS/FAIL, `love.event.quit(0 or 1)`.

### tests/test_basics.lua
Four tests mirroring wip:
1. **Initial state** — currency == 1000, speed_level == 0, growth_level == 0.
2. **Player moves forward** — hold "forward" on move_input, tick 30 frames, assert player3d position changed.
3. **Player turns** — hold "right" on move_input, tick 30 frames, assert angle increased.
4. **Currency unchanged by movement** — move around, assert currency still 1000.

## What stays the same

- `lua/core/input.lua` — unchanged; Player3D uses it in normal mode, HeadlessInput replaces it only under the headless runner.
- All scene, game-state, store, and item logic — untouched.
- Normal `love.load` / `love.update` / `love.draw` path in `main.lua` — unchanged.

## Open questions

None — the wip precedent answers all structural questions.
