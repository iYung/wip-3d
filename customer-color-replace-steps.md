# Customer Color Replacement via Shader Mask

Goal: replace the single `body_color` tint on customers with a two-channel shader that maps pure red → primary color and pure blue → secondary color. Gives each customer a distinct body and clothing color without needing separate art per character.

Current system recap:
- `customer.png` / `customer_walk.png` are full-color sprites
- `Customer:show(cfg)` sets `sprite.sprites.idle.color` and `sprite.sprites.walk.color` to `cfg.body_color`
- Love2D multiplies every pixel by that tint — one color across the whole image

---

## Step 1 — Repaint the customer sprites as masks

Art task: repaint `assets/customer.png` and `assets/customer_walk.png` so every visible pixel is either:

| Color | Hex | Meaning |
|-------|-----|---------|
| Pure red | `#FF0000` | Primary color region (skin, body) |
| Pure blue | `#0000FF` | Secondary color region (clothing, hair) |
| Transparent | alpha = 0 | Background / cutout |

Rules:
- Use hard edges — no anti-aliasing between color regions, only at the outer silhouette edge against transparency
- The alpha channel carries transparency as normal; the RGB channels carry only color intent
- Anti-aliased silhouette edges will work correctly: a red pixel at 50% alpha renders as `primary_color` at half opacity

---

## Step 2 — Write the color replacement shader

Create `lua/game/shaders/color_replace.lua`:

```lua
local src = [[
    uniform vec4 color_a;
    uniform vec4 color_b;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 px = Texel(tex, tc);
        vec4 result = px.r * color_a + px.b * color_b;
        result.a    = px.a;
        return result;
    }
]]

local shader = love.graphics.newShader(src)

return {
    apply = function(primary, secondary)
        love.graphics.setShader(shader)
        shader:send("color_a", primary)
        shader:send("color_b", secondary)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
```

How the math works:
- Pure red pixel `(1, 0, 0, a)` → `1 * color_a + 0 * color_b` = `color_a` at alpha `a`
- Pure blue pixel `(0, 0, 1, a)` → `0 * color_a + 1 * color_b` = `color_b` at alpha `a`
- Transparent pixel `(*, *, *, 0)` → any color at alpha 0, invisible

---

## Step 3 — Update `Customer` to use the shader

In `customer.lua`:

- Add `local ColorReplace = require("lua/game/shaders/color_replace")`
- Remove `color` assignments on `idle` and `walk` sprites in `Customer.new()` — the shader provides color, not the sprite tint
- Add two color fields in `Customer.new()`:
  ```lua
  self._primary   = {0.85, 0.55, 0.30, 1}  -- default skin
  self._secondary = {0.40, 0.30, 0.20, 1}  -- default clothing
  ```
- In `Customer:show(cfg)`, replace the color assignment block:
  ```lua
  -- before
  local color = cfg.body_color or DEFAULT_COLOR
  self.sprite.sprites.idle.color = color
  self.sprite.sprites.walk.color = color

  -- after
  self._primary   = cfg.body_color     or DEFAULT_PRIMARY
  self._secondary = cfg.clothing_color or DEFAULT_SECONDARY
  ```
- In `Customer:draw()`, wrap `self.sprite:draw()` with the shader:
  ```lua
  ColorReplace.apply(self._primary, self._secondary)
  self.sprite:draw()
  if self.accessory_sprite then self.accessory_sprite:draw() end
  ColorReplace.clear()
  ```

---

## Step 4 — Update `customer_scripts.lua`

Add `clothing_color` to each named character entry. `body_color` stays as the primary color.

| Character | `body_color` (primary) | `clothing_color` (secondary) |
|-----------|------------------------|------------------------------|
| Old Pete | `{0.25, 0.45, 0.80, 1}` | choose a contrasting clothing color |
| Mayor Bloom | TBD | TBD |
| The Collector | TBD | TBD |

Example updated entry:
```lua
{
    id             = "old_pete",
    chapter        = 1,
    accessory      = "flat_cap",
    body_color     = {0.25, 0.45, 0.80, 1},
    clothing_color = {0.15, 0.25, 0.50, 1},
    ...
}
```

Anonymous customers (no script) fall through to `DEFAULT_PRIMARY` / `DEFAULT_SECONDARY` — give them a neutral palette so they read as generic.

---

## Notes

- The shader is compiled once at module load (`love.graphics.newShader` at top-level in `color_replace.lua`), not per frame.
- `ColorReplace.clear()` must always be called after drawing to avoid tainting subsequent draw calls.
- Accessories are drawn inside the shader block so they can share the same color channels if their art uses the same mask convention — or drawn outside if they should be unaffected.
- If a future character needs a third color channel (e.g. hair), green (`#00FF00`) is available as `color_c`.
