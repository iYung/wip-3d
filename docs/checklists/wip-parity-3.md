## wip-parity-3 Checklist

- [x] Task A — `lua/game/customer.lua` — Remove the customer name prefix from `make_full_text`: line 43 currently returns `c.name .. ": " .. (c.messages[c.msg_index] or "")`; change it to return `c.messages[c.msg_index] or ""`

- [x] Task B — `lua/game/data/customer_scripts.lua` — Copy file verbatim from `../wip/lua/game/data/customer_scripts.lua`; this adds the missing `after_messages` blocks to all ten non-Sage entries while leaving character names, colors, and messages unchanged

- [x] Task C — `assets/accessories/` — Copy `shades.png` and `clown.png` from `../wip/assets/` into `assets/accessories/`; these accessories are referenced by The Collector and Dottie in customer_scripts but the files are absent

- [x] Task D — `assets/` — Copy `settings_pattern_1.png` and `settings_pattern_2.png` from `../wip/assets/` into `assets/`; needed by the settings menu animation added in Task E

- [x] Task E — `lua/game/scenes/settings_menu.lua` — Replace the single static `_img_bg` with a two-image animated background: load both pattern PNGs into `self._img_bgs = { ..._1, ..._2 }`, add `self._bg_frame = 1` and `self._bg_timer = 0`, advance the timer in `update` (flip frame every 1 s), and draw `self._img_bgs[self._bg_frame]` in place of `self._img_bg` at both draw sites; remove the `settings_background.png` load

- [x] Task F — `assets/shaders/menu_bg.glsl` and `lua/game/shaders/menu_bg.lua` — Copy both files verbatim from `../wip/assets/shaders/menu_bg.glsl` and `../wip/lua/game/shaders/menu_bg.lua`

- [x] Task G — `assets/start_pattern.png` — Copy from `../wip/assets/start_pattern.png`

- [x] Task H — `lua/game/scenes/start_scene.lua` — Wire the MenuBg shader: `require("lua/game/shaders/menu_bg")`, add `self._time = 0` in `new`, increment `self._time` by `dt` in `update`, and in `draw` wrap the `love.graphics.draw(self._img_bg, 0, 0)` call with `MenuBg.apply` / `MenuBg.clear` when `self._img_pattern` is loaded (mirror the graceful-disable guard from wip); also load `start_pattern.png` conditionally with `love.filesystem.getInfo`

- [x] Task I — `lua/game/scenes/buy_scene.lua` — Add `love.graphics.clear(0, 0, 0, 1)` immediately after `love.graphics.setCanvas(self.canvas)` in `draw` to prevent stale pixels from bleeding through the CRT composite
