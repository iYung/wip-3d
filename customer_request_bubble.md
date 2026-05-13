# Customer Request: Plant Image in Speech Bubble

Show a speech bubble containing the requested plant image above the customer while they are waiting. Uses the existing `speech_bubble.png` / `speech_bubble_tail.png` assets and the `draw9()` helper already in `customer.lua`.

---

## Step 1 — Add state fields to Customer

**File:** `lua/game/customer.lua` — inside `Customer.new()`, after the existing bubble sprites (around line 76)

Add two fields: a flag to show the plant bubble, and the current plant type to draw:
```lua
self.show_plant_bubble = false
self.request_plant_type = 1
```

You do not need a new Sprite object — the plant image will be drawn procedurally in `draw_bubble()`, the same way the text dialog is drawn.

---

## Step 2 — Set fields in Customer:show()

**File:** `lua/game/customer.lua` — inside `Customer:show()` (around line 96)

Replace the tint line:
```lua
-- remove:
self.bubble.color = PLANT_DATA[self.plant_type].colors[3]

-- add:
self.request_plant_type = self.plant_type
self.show_plant_bubble  = false   -- hidden until customer arrives
```

---

## Step 3 — Reveal the bubble when customer arrives

**File:** `lua/game/customer.lua` — inside `Customer:update()`, in the `"walking_in"` branch (around line 182)

When the customer stops walking, show the plant bubble instead of the old colored bubble:
```lua
self.x              = self.target_x
self.state          = "waiting"
self.show_plant_bubble = true     -- <-- add this
self.bubble.visible = false       -- keep old bubble hidden
```

Hide it again when leaving. In the `"walking_out"` branch (around line 188):
```lua
self.show_plant_bubble = false
```

Also hide it in `Customer:serve()` and `Customer:dismiss()`:
```lua
self.show_plant_bubble = false
```

---

## Step 4 — Draw the speech bubble with plant image

**File:** `lua/game/customer.lua` — inside `Customer:draw_bubble()` (line 237)

Add a new block at the top of `draw_bubble()`, before the existing text-bubble block:

```lua
if self.show_plant_bubble and A.speech_bubble and A.speech_bubble_tail then
    local PAD      = 12          -- space between bubble edge and plant image
    local IMG_SIZE = 80          -- plant image drawn at this pixel size
    local BOX_W    = IMG_SIZE + PAD * 2
    local BOX_H    = IMG_SIZE + PAD * 2
    local TAIL_H   = 24

    -- anchor above the customer sprite
    local box_x = self.x - BOX_W / 2
    local box_y = self.sprite.y - BOX_H - TAIL_H - 4

    -- 9-slice bubble frame
    love.graphics.setColor(1, 1, 1, 1)
    draw9(A.speech_bubble, box_x, box_y, BOX_W, BOX_H, BUBBLE_MARGIN)

    -- tail centered below the box
    local tw = A.speech_bubble_tail:getWidth()
    love.graphics.draw(
        A.speech_bubble_tail,
        box_x + BOX_W / 2 - tw / 2,
        box_y + BOX_H - 10
    )

    -- plant image centered inside the box
    local img = A["plant_" .. self.request_plant_type][3]
    local iw, ih = img:getDimensions()
    local sx = IMG_SIZE / iw
    local sy = IMG_SIZE / ih
    love.graphics.draw(
        img,
        box_x + PAD,
        box_y + PAD,
        0, sx, sy
    )

    love.graphics.setColor(1, 1, 1, 1)
end
```

`draw9` and `BUBBLE_MARGIN` are already defined at the top of `customer.lua` — no new imports needed.

---

## Step 5 — Remove the old customer_bubble tint path

**File:** `lua/game/customer.lua` — in `Customer:draw_bubble()` (around line 242)

The `done_talking` branch currently draws `self.bubble` (the tinted `customer_bubble.png`). That block is now replaced by the plant-bubble drawn in Step 4. Remove or guard it so it no longer draws:
```lua
-- remove this block (or delete it entirely):
if self.done_talking then
    self.bubble:draw()
end
```

If you still want `customer_bubble.png` for another purpose (e.g. a fallback), keep it behind a different flag. Otherwise it is safe to delete.

---

## Constants to tune

All three sizing constants live at the top of the new block in `draw_bubble()` — adjust them to match your art:

| Constant | Default | Effect |
|---|---|---|
| `PAD` | `12` | Space between bubble border and plant image |
| `IMG_SIZE` | `80` | Plant image rendered size in pixels |
| `TAIL_H` | `24` | Gap reserved for the tail below the box |

`BUBBLE_MARGIN` is shared with the text dialog and defined at the top of `customer.lua` (line 17).

---

## Asset checklist

No new assets needed. All of these already exist:
- `assets/speech_bubble.png` — 9-slice frame (loaded as `A.speech_bubble`)
- `assets/speech_bubble_tail.png` — tail pointer (loaded as `A.speech_bubble_tail`)
- `assets/plant_N_3.png` — stage-3 plant images (loaded as `A["plant_N"][3]`)
