# Slot Highlight Image

Replace the white rectangle drawn over the active slot with a custom `slot_highlight.png` image. The image should be made at slot size (200×200) with a transparent background — whatever you paint on it is exactly what will appear.

---

## Step 1 — Add the asset

**File:** `lua/game/assets.lua`

Add a load line alongside the other slot assets:
```lua
A.slot_highlight = img("assets/slot_highlight.png")
```

Place it after `A.slot = img("assets/slot.png")` (around line 37).

---

## Step 2 — Draw the image instead of the rectangle

**File:** `lua/game/slot.lua` — inside `Slot:draw()` (around line 40)

Replace the existing rectangle block:
```lua
-- remove:
if self.highlighted then
    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.rectangle("fill", self.x, self.y, self.slot_width, SLOT_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
end

-- add:
if self.highlighted and A.slot_highlight then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        A.slot_highlight,
        self.x, self.y,
        0,
        self.slot_width / A.slot_highlight:getWidth(),
        SLOT_HEIGHT     / A.slot_highlight:getHeight()
    )
end
```

The image is scaled to fit the slot exactly, so you can author it at any resolution.

---

## Asset spec

| Property | Value |
|---|---|
| File | `assets/slot_highlight.png` |
| Recommended size | 200×200 px (matches slot dimensions) |
| Background | Transparent |
| Blend | Drawn after the slot background, before the item |
