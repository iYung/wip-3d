# Typewriter Dialogue

## Goal

Customer dialog lines reveal character-by-character (typewriter effect). A
speech bubble image is drawn behind the text using 9-slice scaling so corners
and the tail stay crisp while the box stretches to fit. Pressing F while text
is still typing skips to the full line; pressing F again advances (existing
behaviour).

## Asset

| File | Size | Slice margins |
|------|------|---------------|
| `assets/speech_bubble.png` | 96 × 72 | top=12, right=12, bottom=24, left=12 |

The bottom margin is larger to include a downward-pointing tail. The centre of
the image is the stretchable region. Missing file → fall back to no bubble
(text only).

## Constants (top of customer.lua)

```lua
local REVEAL_SPEED  = 40   -- characters per second
local PAD           = 14   -- px between text and bubble edge
local MIN_BOX_W     = 120
local BUBBLE_MARGIN = { top = 12, right = 12, bottom = 24, left = 12 }
```

## Load asset in assets.lua

```lua
local function try_img(path)
    if love.filesystem.getInfo(path) then return love.graphics.newImage(path) end
end
A.speech_bubble = try_img("assets/speech_bubble.png")
```

(`try_img` is already defined in assets.lua above the store_bg lines.)

## 9-slice helper (top of customer.lua)

```lua
local function draw9(img, x, y, w, h, m)
    local iw, ih = img:getDimensions()
    local function q(qx, qy, qw, qh) return love.graphics.newQuad(qx, qy, qw, qh, iw, ih) end
    local cx = iw - m.left - m.right   -- centre source width
    local cy = ih - m.top  - m.bottom  -- centre source height
    local dx = w  - m.left - m.right   -- centre dest width
    local dy = h  - m.top  - m.bottom  -- centre dest height
    local sx = dx / cx
    local sy = dy / cy
    -- corners
    love.graphics.draw(img, q(0,           0,          m.left, m.top),    x,            y)
    love.graphics.draw(img, q(iw-m.right,  0,          m.right, m.top),   x+w-m.right,  y)
    love.graphics.draw(img, q(0,           ih-m.bottom, m.left, m.bottom), x,            y+h-m.bottom)
    love.graphics.draw(img, q(iw-m.right,  ih-m.bottom, m.right, m.bottom), x+w-m.right, y+h-m.bottom)
    -- edges
    love.graphics.draw(img, q(m.left, 0,           cx, m.top),    x+m.left, y,            0, sx, 1)
    love.graphics.draw(img, q(m.left, ih-m.bottom, cx, m.bottom), x+m.left, y+h-m.bottom, 0, sx, 1)
    love.graphics.draw(img, q(0,          m.top, m.left,  cy),  x,           y+m.top, 0, 1, sy)
    love.graphics.draw(img, q(iw-m.right, m.top, m.right, cy),  x+w-m.right, y+m.top, 0, 1, sy)
    -- centre
    love.graphics.draw(img, q(m.left, m.top, cx, cy), x+m.left, y+m.top, 0, sx, sy)
end
```

## State added to Customer

```lua
self.reveal_index = 0
self.reveal_t     = 0
self._full_text   = ""
```

Local helper (not a method):

```lua
local function make_full_text(c)
    return c.name .. ": " .. (c.messages[c.msg_index] or "")
end
```

## Step 1 — reset reveal on new line

In `Customer:show()`, after `self.msg_index = 1`:

```lua
self._full_text   = make_full_text(self)
self.reveal_index = 0
self.reveal_t     = 0
```

In `Customer:advance()`, after incrementing `self.msg_index`:

```lua
if not self.done_talking then
    self._full_text   = make_full_text(self)
    self.reveal_index = 0
    self.reveal_t     = 0
end
```

## Step 2 — advance reveal in Customer:update(dt)

```lua
if self.bubble.visible and not self.done_talking then
    self.reveal_t     = self.reveal_t + dt
    self.reveal_index = math.min(
        #self._full_text,
        math.floor(self.reveal_t * REVEAL_SPEED)
    )
end
```

## Step 3 — skip-to-end on F in StoreScene

Two new methods on Customer:

```lua
function Customer:line_complete()
    return self.done_talking or self.reveal_index >= #self._full_text
end

function Customer:skip_reveal()
    self.reveal_index = #self._full_text
    self.reveal_t     = #self._full_text / REVEAL_SPEED
end
```

In `StoreScene:_handle_interact()`, in the cashier dialog block, before the
existing `self._customer:advance()` call:

```lua
if not self._customer:line_complete() then
    self._customer:skip_reveal()
    return
end
self._customer:advance()
```

## Step 4 — draw bubble + revealed text in Customer:draw_bubble()

Replace the plain `love.graphics.print` block:

```lua
else
    local font     = love.graphics.getFont()
    local revealed = string.sub(self._full_text, 1, self.reveal_index)
    local text_w   = font:getWidth(self._full_text)   -- full width so box doesn't resize
    local text_h   = font:getHeight()
    local box_w    = math.max(MIN_BOX_W, text_w + PAD * 2)
    local box_h    = text_h + PAD * 2
    -- position: centred on bubble sprite, sitting above it (tail points down at customer)
    local box_x    = self.bubble.x + BW / 2 - box_w / 2
    local box_y    = self.bubble.y - box_h - BUBBLE_MARGIN.bottom + 4

    love.graphics.setColor(1, 1, 1, 1)
    if A.speech_bubble then
        draw9(A.speech_bubble, box_x, box_y, box_w, box_h, BUBBLE_MARGIN)
    end
    love.graphics.setColor(0.08, 0.07, 0.10, 0.95)
    love.graphics.print(revealed, box_x + PAD, box_y + BUBBLE_MARGIN.top / 2 + PAD / 2)
    love.graphics.setColor(1, 1, 1, 1)
end
```

## Step 5 — F label in StoreScene:_hud_labels()

```lua
elseif not self._customer:line_complete() then
    f_label = "F: SKIP"
else
    f_label = "F: NEXT"
end
```

## Placeholder asset

Run once to create `assets/speech_bubble.png`:

```python
from PIL import Image, ImageDraw

W, H, M = 96, 72, 12
TAIL = 24   # bottom margin including tail

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# bubble body
d.rounded_rectangle([(0, 0), (W-1, H-TAIL-1)], radius=M, fill=(30, 25, 40, 230), outline=(160, 140, 200, 200), width=2)

# tail triangle (centred, pointing down)
cx = W // 2
ty = H - TAIL  # top of tail = bottom of body
d.polygon([(cx-10, ty), (cx+10, ty), (cx, H-1)], fill=(30, 25, 40, 230))
# outline for tail sides (not the tip edge)
d.line([(cx-10, ty), (cx, H-1)], fill=(160, 140, 200, 200), width=2)
d.line([(cx+10, ty), (cx, H-1)], fill=(160, 140, 200, 200), width=2)

img.save("assets/speech_bubble.png")
```
