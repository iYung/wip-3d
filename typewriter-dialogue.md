# Typewriter Dialogue

## Goal

Customer dialog lines reveal character-by-character (typewriter effect). A
background speech bubble box is drawn behind the text and expands in width as
characters appear. Pressing F while text is still typing skips to the full line;
pressing F again advances to the next message (existing behaviour).

## Constants

```lua
local REVEAL_SPEED = 40   -- characters per second
local PAD          = 12   -- px padding inside the bubble box on each axis
local MIN_BOX_W    = 120  -- minimum box width so it doesn't flash tiny
local BOX_COLOR    = {0.08, 0.07, 0.10, 0.88}
local BOX_OUTLINE  = {0.60, 0.55, 0.70, 0.70}
```

## State added to Customer

Three fields, reset whenever a new line begins:

```lua
self.reveal_index = 0    -- characters of current full_text revealed so far
self.reveal_t     = 0    -- accumulated seconds since this line started
self._full_text   = ""   -- cached "Name: message" for the current line
```

Helper (not a method, just inside customer.lua):

```lua
local function full_text(customer)
    local line = customer.messages[customer.msg_index] or ""
    return customer.name .. ": " .. line
end
```

## Step 1 — reset reveal state on new line

In `Customer:show()`, after setting `self.msg_index = 1`:

```lua
self._full_text   = full_text(self)
self.reveal_index = 0
self.reveal_t     = 0
```

In `Customer:advance()`, after incrementing `self.msg_index`:

```lua
if not self.done_talking then
    self._full_text   = full_text(self)
    self.reveal_index = 0
    self.reveal_t     = 0
end
```

## Step 2 — advance reveal in `Customer:update(dt)`

Add at the end of `update`, only when dialog is active
(`self.bubble.visible and not self.done_talking`):

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

In `StoreScene:_handle_interact()`, in the cashier dialog block, before calling
`self._customer:advance()`:

```lua
if self._customer:arrived() then
    -- existing sell check …

    -- typewriter skip: first F completes the line, second advances
    if not self._customer:line_complete() then
        self._customer:skip_reveal()
        return
    end
    self._customer:advance()
    return
end
```

Add two methods to Customer:

```lua
function Customer:line_complete()
    return self.done_talking or self.reveal_index >= #self._full_text
end

function Customer:skip_reveal()
    self.reveal_index = #self._full_text
    self.reveal_t     = #self._full_text / REVEAL_SPEED
end
```

## Step 4 — draw background box + revealed text in `Customer:draw_bubble()`

Replace the plain `love.graphics.print` block:

```lua
else
    local font      = love.graphics.getFont()
    local revealed  = string.sub(self._full_text, 1, self.reveal_index)
    local text_w    = font:getWidth(self._full_text)  -- size box to FULL width so it doesn't shrink
    local text_h    = font:getHeight()
    local box_w     = math.max(MIN_BOX_W, text_w + PAD * 2)
    local box_h     = text_h + PAD * 2
    local box_x     = self.bubble.x + BW / 2 - box_w / 2
    local box_y     = self.bubble.y - box_h - 4  -- sit just above where the sprite bubble would be

    -- filled background
    love.graphics.setColor(BOX_COLOR)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 6, 6)

    -- outline
    love.graphics.setColor(BOX_OUTLINE)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 6, 6)

    -- revealed text
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.print(revealed, box_x + PAD, box_y + PAD)
    love.graphics.setColor(1, 1, 1, 1)
end
```

> **Box sizing note:** the box width is fixed to the full line's width (not the
> revealed portion) so it doesn't jump around. Only the text inside grows.
> If you prefer the box to expand with the text, use `font:getWidth(revealed)`
> instead and accept the resize animation.

## F-label update in `StoreScene:_hud_labels()`

The existing `f_label = "F: NEXT"` covers both the skip and advance cases, so
no label change is needed. Optionally show "F: SKIP" while typing:

```lua
elseif not self._customer:line_complete() then
    f_label = "F: SKIP"
else
    f_label = "F: NEXT"
end
```
