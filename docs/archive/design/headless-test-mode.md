# Headless Test Mode

## Goal

Allow game logic to be tested programmatically without a window or GPU. Tests run under Love2D with graphics/window/audio disabled, invoked via `LOVE_TEST=1 love .`. Supports both unit tests (isolated classes) and integration tests (scene-level update loops).

## Affected files

- `conf.lua` — disable window and graphics modules when `LOVE_TEST=1`
- `main.lua` — override `love.run` in test mode to run the test suite instead of the game loop
- `lua/core/shader.lua` — guard against missing `love.graphics` module
- `lua/test/love_stubs.lua` *(new)* — stub implementations of Love2D APIs used at require/construct time
- `lua/test/headless_input.lua` *(new)* — Input-compatible class driven by `set_down`/`press` calls instead of keyboard polling
- `lua/test/runner.lua` *(new)* — discovers, runs, and reports test files; exits with 0/1
- `lua/test/t.lua` *(new)* — minimal assertion library (`assert`, `eq`, `approx`, `err`)
- `tests/unit/` *(new dir)* — unit test files for Plant, Store, Customer, etc.
- `tests/integration/` *(new dir)* — integration test files that drive a StoreScene update loop

## What changes

### Invocation

```
love . --test
```

Both `conf.lua` and `main.lua` scan the global `arg` table (available in Love2D before either file runs) for the `"--test"` flag via a small helper:

```lua
local function is_test_mode()
    for _, v in ipairs(arg or {}) do
        if v == "--test" then return true end
    end
    return false
end
```

### conf.lua

When `--test` is present:

```lua
t.window = false          -- no window created
t.modules.graphics = false
t.modules.window   = false
t.modules.audio    = false
t.modules.sound    = false
```

### Love stubs (`lua/test/love_stubs.lua`)

Installed by `main.lua` **before any game module is required**. Provides:

- `love.graphics.newImage(path)` → `{getWidth=→1, getHeight=→1}` mock
- `love.graphics.newShader(src)` → mock shader with `.send()`, `.hasUniform()` no-ops
- `love.graphics.newFont(...)` → mock font with `.getHeight()→12`, `.getWidth()→8`
- `love.graphics.newCanvas(...)` → mock canvas with `.setFilter()` no-op
- `love.filesystem.getInfo(path)` → `nil` (treats all optional assets as absent)
- `love.keyboard.isDown(key)` → `false` (HeadlessInput installs its own version over this)

`lua/core/shader.lua` and `lua/game/assets.lua` are the two modules that touch `love.graphics` at load time — the stubs make them safe to require in headless mode.

### HeadlessInput (`lua/test/headless_input.lua`)

Implements the same interface as `lua/core/input.lua`:

```lua
input:update()
input:is_down(action)  → bool
input:pressed(action)  → bool
```

Driven by:

```lua
input:set_down(action, bool)   -- hold/release an action
input:press(action)            -- queue a single-frame press (cleared by next update())
```

Replaces the `lua/game/input.lua` singleton in tests — integration tests construct their own HeadlessInput and pass it where the real input object would go.

### Test runner (`lua/test/runner.lua`)

- Scans `tests/unit/` and `tests/integration/` for `*_test.lua` files
- For each file: `pcall(require, path)` — a file that errors (including assertion failures) counts as failed
- Prints `PASS` / `FAIL` per test, with the error message on failure
- After all tests: prints a summary line
- Calls `love.event.quit(exit_code)` — 0 if all passed, 1 if any failed

### Assertion library (`lua/test/t.lua`)

```lua
T.assert(cond, msg)           -- fails if cond is falsy
T.eq(a, b, msg)               -- fails if a ~= b
T.approx(a, b, eps, msg)      -- fails if math.abs(a-b) > eps
T.err(fn, msg)                -- fails if fn() does NOT throw
```

Failures raise an error string (not `love.event.quit`) so the runner can catch them with `pcall`.

### Example unit test

```lua
-- tests/unit/plant_test.lua
local Plant = require("lua/game/items/plant")
local T     = require("lua/test/t")

local p = Plant.new(1)
T.eq(p.stage, 1, "starts at stage 1")
T.eq(p.ready, false, "not ready immediately")
p:update(p.cooldown + 0.01)
T.eq(p.ready, true, "ready after cooldown")
p:water()
T.eq(p.stage, 2, "advances to stage 2 after watering")
```

### Example integration test

```lua
-- tests/integration/currency_test.lua
local GameState      = require("lua/game/game_state")
local StoreScene     = require("lua/game/scenes/store_scene")
local HeadlessInput  = require("lua/test/headless_input")
local T              = require("lua/test/t")

local gs     = GameState.new()
local input  = HeadlessInput.new()
local sm     = { switch = function() end }  -- minimal scene manager stub
local scene  = StoreScene.new(gs, input, sm)

-- ... drive update loop, trigger a sale, assert currency increased
```

Integration tests call `scene:update(dt)` directly; they never call `scene:draw()`, avoiding all rendering code paths.

## What stays the same

- All game source files (`lua/game/`, `lua/core/`) are **not modified** — no `if headless then` guards inside game logic
- The normal `love .` path is completely unchanged — stubs are only installed when `LOVE_TEST=1`
- Test files live entirely in `tests/` and `lua/test/`; game modules require no knowledge of the test harness

## Open questions

None — scope confirmed by user: Love2D headless runner, unit + integration tests.
