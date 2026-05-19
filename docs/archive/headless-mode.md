## Headless Mode Checklist

- [x] Task A — `conf.lua` — Parse `--headless` from `arg` at the top of the file; when found, set `t.modules.window`, `t.modules.graphics`, `t.modules.audio`, `t.modules.sound`, `t.modules.joystick`, `t.modules.touch`, `t.modules.video` all to `false` inside `love.conf`. Mirror wip's conf.lua exactly.

- [x] Task B — `main.lua` — At the very top (before `love.graphics.setDefaultFilter`), parse `--headless` and the test-file path from `arg`. When headless: `require("lua/headless/stubs")`, then `require("lua/headless/runner").run(test_file)`, then `return`. Non-headless path is completely unchanged.

- [x] Task C — `lua/headless/stubs.lua` — Create the file. Install no-op stubs into the `love` global before any game module loads. Include everything from wip's stubs.lua plus 3D-specific additions: explicit `graphics_stub.newShader` that returns a table with a no-op `send` method; `graphics_stub.newQuad` returning `{}`; `graphics_stub.line` noop; `graphics_stub.setScissor` noop. Invalidate the assets cache (`package.loaded["lua/game/assets"] = nil`) as wip does.

- [x] Task D — `lua/headless/input.lua` — Create the file. Implement `HeadlessInput` with `new()`, `press(action)`, `hold(action)`, `release(action)`, `update()`, `is_down(action)`, `pressed(action)`. Identical to wip's HeadlessInput.

- [x] Task E — `lua/headless/runner.lua` — Create the file. Implement `setup(scene_factory)`: creates gs, scene_input (HeadlessInput), sm; calls scene_factory or defaults to StoreScene; calls sm:switch(scene); if scene.player3d exists, creates move_input (HeadlessInput) and assigns it to scene.player3d.input; returns `{ gs=gs, input=scene_input, move_input=move_input, sm=sm, scene=scene }`. Implement `tick(ctx, n, dt)`: loops n times (default 1), calling ctx.input:update() then ctx.sm:update(dt) each iteration (dt defaults to 1/60). Implement `run(test_file)`: sets `_G.runner = runner`, pcall-dofile the test file, prints PASS or FAIL with error, calls love.event.quit(0 or 1).

- [x] Task F — `tests/test_basics.lua` — Create the file with four tests: (1) initial state: currency==1000, speed_level==0, growth_level==0; (2) player moves forward: hold "forward" on ctx.move_input, tick 30 frames, assert player3d position changed; (3) player turns right: hold "right" on ctx.move_input, tick 30 frames, assert angle increased; (4) currency unchanged by movement: move for 60 frames, assert currency still 1000.
