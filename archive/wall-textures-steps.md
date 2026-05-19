## Wall Textures Checklist

- [x] Task A — `lua/core/raycaster.lua` — Add `WALL_HEIGHT = 1.5` constant near the top (after `FOV`). Change the wall height projection from `math.floor(SH / perp)` to `math.floor(SH * WALL_HEIGHT / perp)`.

- [x] Task B — `lua/core/raycaster.lua` — Add `self._quad_cache = {}` to `Raycaster.new()`. Add a `Raycaster:_get_tex_quads(tex)` helper that builds and caches a table of `love.graphics.newQuad(tx, 0, 1, tex_h, tex_w, tex_h)` for each pixel column `tx = 0..tex_w-1`, keyed on the texture object.

- [x] Task C — `lua/core/raycaster.lua` — Extend `Raycaster:draw()` to accept a sixth `wall_textures` argument (nil-safe). Inside the `if hit then` block, after computing `h`, `y1`, `y2`, and `br`: look up `wall_textures and wall_textures[map:cell(mx, my)]`. If a texture is found, compute `hit_x` (the fractional 0–1 position along the wall face using `px + perp*rdx` or `py + perp*rdy` depending on `side`, then `fract`), clamp `tx = math.max(0, math.min(tex_w-1, math.floor(hit_x * tex_w)))`, call `self:_get_tex_quads(tex)`, then `love.graphics.setColor(br, br, br, 1)` and `love.graphics.draw(tex, quads[tx], col, y1, 0, 1, h / tex:getHeight())`. Keep the existing solid-color `line` as the fallback when no texture.

- [x] Task D — `lua/game/scenes/store_scene.lua` — In `StoreScene:draw()`, update the `self.raycaster:draw(...)` call to pass `{[1] = A.store_wall}` as the sixth argument.
