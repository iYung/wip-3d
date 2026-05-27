# Love2D Game Architecture

---

## Core Classes

Reusable engine-level classes with no game-specific knowledge.

---

### Sprite

A single drawable unit at a world position.

**Properties**
- `x`, `y` — world position (top-left)
- `width`, `height` — dimensions in pixels
- `scale_x`, `scale_y` — scale factors (default `1`)
- `visible` — bool, skips draw if false
- `color` — tint `{r, g, b, a}` (defaults to white `{1,1,1,1}`)
- `image` — Love2D image object; if nil, draws a filled rectangle instead
- `shader` — optional Love2D shader applied during `draw()`, reset after

**Methods**
- `new(x, y, w, h)` — constructor
- `draw()` — if `image` is set, scales it to fill `width × height` exactly; otherwise draws a filled rectangle at those dimensions; applies `color` as a tint in both cases
- `update(dt)` — no-op hook

**Notes**
- Color tinting works identically for images and rectangles; a white image tinted `{r,g,b,1}` looks the same as a rectangle drawn in that color
- Handles the Love2D transform push/pop internally; color is reset to `{1,1,1,1}` after each draw

---

### SpriteSet

A named collection of Sprites with one active at a time.

**Properties**
- `sprites` — table of `name -> Sprite`
- `current` — name of the active sprite
- `x`, `y` — world position; forwarded to the active sprite every `draw()`
- `visible` — if false, nothing draws

**Methods**
- `new()` — constructor
- `add(name, sprite)` — register a sprite under a name
- `set(name)` — switch the active sprite
- `_active()` — returns the current Sprite
- `draw()` — copies `x`/`y` to the active sprite, then calls `sprite:draw()`
- `update(dt)` — delegates to the current active sprite

**Notes**
- Implements the same `draw()` / `update(dt)` interface as Sprite, so it is a drop-in anywhere a Sprite is expected
- `color`, `scale_x`, `scale_y` are per-sprite properties, not SpriteSet-level; set them directly on each Sprite after `add()`

---

### Drawer

Manages and renders all registered drawables each frame.

**Properties**
- `layers` — ordered list of `{sprite, priority}` entries

**Methods**
- `add(sprite, priority)` — register a drawable; lower priority = drawn first (behind)
- `draw()` — called once per `love.draw()`; iterates layers in priority order, calls `sprite:draw()` on each
- `clear()` — remove all entries

**Notes**
- Sorting happens on `add()`, not every frame
- Any object with a `draw()` method can be registered, not just Sprites

---

### Camera

Controls the viewport — what portion of the world is visible.

**Properties**
- `x`, `y` — world position the camera is centered on
- `zoom` — scale factor (default: `1.0`)

**Methods**
- `new(x, y)` — constructor
- `attach()` — push camera transform onto the Love2D transform stack (call before drawing)
- `detach()` — pop camera transform (call after drawing)
- `to_world(sx, sy)` — convert screen coordinates to world coordinates
- `to_screen(wx, wy)` — convert world coordinates to screen coordinates
- `follow(target, lerp)` — smoothly track `target.x/y`; `lerp` 0 = instant, 1 = no movement

**StoreScene camera rules (applied after `follow()` each frame)**
- `camera.y` is locked to `CAMERA_Y = 440` (no vertical follow)
- `camera.x` is clamped so neither screen edge overruns the world: left bound = `-ZONE_WIDTH + 640`, right bound = `store:width() - 640`; ensures the cashier zone far-left and store far-right are never exposed

---

### Scene

Pure lifecycle base class. No rendering state.

**Methods**
- `new()` — constructor
- `update(dt)` / `draw()` / `on_enter()` / `on_exit()` — no-op stubs, override in subclasses

Subclass `Scene2D` or `Scene3D` rather than this directly.

---

### Scene2D

Inherits `Scene`. Owns a `Drawer` and a `Camera`. All current game scenes extend this.

**Properties**
- `drawer` — Drawer instance for this scene
- `camera` — Camera instance for this scene

**Methods**
- `new()` — constructor; creates `self.drawer` and `self.camera`
- `draw()` — wraps `drawer:draw()` inside `camera:attach()`/`camera:detach()`
- `on_exit()` — calls `drawer:clear()`

Call `Scene2D.draw(self)` and `Scene2D.on_exit(self)` from overrides to keep default behaviour.

---

### Scene3D

Inherits `Scene`. Owns a `Raycaster` for first-person 3D rendering.

**Properties**
- `raycaster` — Raycaster instance for this scene

**Methods**
- `new()` — constructor; creates `self.raycaster`

Subclass provides a `Map` and player position; call `self.raycaster:draw(map, px, py, angle)` in `draw()`.

---

### Map

A 2D grid of integer cells used by the raycaster.

**Methods**
- `Map.new(grid)` — `grid` is a 1-indexed table of rows; `0` = empty, non-zero = wall
- `is_wall(x, y)` — true if the cell is non-zero
- `cell(x, y)` — raw cell value (0 if out of bounds)
- `width()` / `height()` — grid dimensions

---

### Raycaster

DDA-based first-person column renderer. Draws ceiling, floor, and walls each frame.

**Constants**
- `WALL_HEIGHT = 1.5` — multiplier applied to the projected wall height (`h = SH * WALL_HEIGHT / perp`); increase to make walls taller relative to the viewport

**Internal state**
- `_quad_cache` — table keyed by Love2D image object; each entry is an array of pre-built `newQuad` objects (one per pixel column of the texture), populated on first use and reused every subsequent frame to avoid per-frame allocations in the column loop

**Methods**
- `Raycaster.new()`
- `draw(map, px, py, angle [, hover_tile [, wall_textures]])` — `px`/`py` in grid units (float), `angle` in radians. `hover_tile` (optional) is a `{x, y}` grid cell passed to the floor shader for checkerboard highlighting. `wall_textures` (optional) is a table mapping map cell integer values to Love2D image objects (e.g. `{[1] = A.store_wall}`); when a ray hits a wall cell whose value has an entry, a textured vertical strip is drawn (brightness-tinted by face side) instead of the solid-color fallback line.

X-facing walls are drawn brighter (`br = 0.8`) than Y-facing walls (`br = 0.5`) for depth contrast. Renders at 1280 × 720. Resets `love.graphics` colour to white after drawing.

---

### SceneManager

Holds the active scene and delegates the game loop to it.

**Properties**
- `current` — the active Scene

**Methods**
- `switch(scene)` — calls `current:on_exit()`, swaps, calls `scene:on_enter()`
- `update(dt)` — delegates to `current:update(dt)`
- `draw()` — delegates to `current:draw()`

---

## Frame Loop

```
love.update(dt)
  scene_manager:update(dt)

love.draw()
  scene_manager:draw()
    -- internally: camera:attach() → drawer:draw() → camera:detach()
```

---

## Game Classes

Game-specific classes that implement the plant store logic.

---

### Assets

Loads every PNG once at startup and returns a shared table. All other modules `require` this module directly; Love2D's module cache ensures images are only loaded once.

**Location:** `lua/game/assets.lua`

**Contents**
- `player_idle`, `player_walk`, `player_idle_held`, `player_walk_held` — player state images (120×240)
- `customer`, `customer_bubble` — customer body and plant-request bubble (120×240, 120×120)
- `plant_N[stage]` — plant images indexed as `A["plant_N"][stage]` for types 1–6, stages 1–3 (120×120 each)
- `plant_bubble` — watering-ready indicator shown above plants (60×60)
- `watering_can`, `grafter_empty`, `grafter_loaded`, `garbage_bin`, `pc_store` — item images (120×120)
- `slot` — slot background image (120×200)
- `cashier_wall` — cashier zone wall with transparent window cutout (400×800)
- `store_wall` — repeating store wall tile (200×720); one slot wide
- `store_window` — store window frame with transparent cutout (400×720); two slots wide
- `slot_highlight` — overlay drawn on the active slot (120×200)
- `store_bg_far`, `store_bg_mid`, `store_bg_near` — parallax background layers tiled across the full world width (cashier zone + store); currently alias `shop_bg_far/mid/near`
- `speech_bubble` — 9-slice speech bubble image (96×72, margins top=12 right=12 bottom=24 left=12)
- `speech_bubble_tail` — tail graphic drawn below the speech bubble
- `sneakers`, `expand_slot` — buy-scene preview images; loaded conditionally via `try_img` (art not yet created; fall back to grey rectangle in preview)
- `accessories` — table of lazily-loaded accessory images, keyed by name

**Methods**
- `load_accessory(name)` — loads `assets/accessories/<name>.png` on first call and caches the result; returns `false` (not nil) on a missing file so the cache entry is set and the disk is not re-checked

---

### Input

Maps Love2D key events to the four game actions. Game logic calls Input, never Love2D directly.

**Actions**
- `move_left`
- `move_right`
- `pick_up_down`
- `interact`

**Methods**
- `update()` — called each frame, samples key state
- `is_down(action)` — true while the key is held
- `pressed(action)` — true only on the frame the key was pressed

---

### GameState

Shared state passed between scenes. Survives scene switches.

**Properties**
- `store` — the Store instance
- `player` — the Player instance
- `currency` — player's current funds
- `speed_level` — current speed upgrade tier (0 = base)
- `growth_level` — current Heat Lamps upgrade tier (0 = base)
- `growth_mult` — float derived from `growth_level`; multiplied into `dt` passed to the store each frame (1.0 = no change)
- `unlocked_plants` — set `{ [plant_type] = true }`; Grass (`[1]`) pre-populated; updated on plant purchase
- `stage3_counts` — `{ [plant_type] = n }`; incremented each time that plant type reaches stage 3
- `seen_scripts` — set `{ ["id:chapter"] = true }`; e.g. `"old_pete:1"`; prevents a scripted chapter from firing twice

---

### Player

The player character. Moves left/right into the cashier zone, holds at most one item.

**Properties**
- `x` — world position (can go negative into cashier zone)
- `held_item` — the Item currently held, or `nil`
- `speed` — movement speed in px/s; defaults to 220, increased by speed upgrades
- `sprite` — SpriteSet with four variants: `idle`, `walk`, `idle_held`, `walk_held`; each backed by a PNG image
- `_speed_color` — `{r,g,b,a}` replacement color for the current speed tier; defaults to `{1,1,1,1}` (white) at base level

**Methods**
- `new(x)` — constructor
- `set_speed_level(level, color)` — stores `color` as `_speed_color`; called by BuyScene after a speed purchase
- `update(dt, input, store)` — handle movement and animation frame switching
- `active_slot(store)` — returns the slot the player is standing over
- `draw()` — applies `ColorReplace` with `_speed_color` as primary (no secondary); draws sprite; clears shader; then draws held item above the player

---

### Item

Base class for all carriable/interactable objects in the store.

**Properties**
- `sprite` — Sprite or SpriteSet
- `carriable` — bool
- `sellable` — bool (false for PC Store)
- `name` — display string

**Methods**
- `new()` — constructor
- `interact(player, store, scene_manager)` — called when player presses Interact
- `draw()` — delegates to sprite

**Subclasses**
- `WateringCan` — interact waters the plant in the player's active slot
- `Grafter` — clones a stage-3 plant; has `unload()` to reset to empty state
- `PCStore` — interact switches to BuyScene; only works when placed in a slot
- `GarbageBin` — discard station; F while holding any sellable item discards it (or unloads a grafter clone)
- `Plant` — has stage and cooldown timer; not directly usable as a tool

---

### Plant

An Item subclass. Tracks growth state via a cooldown timer.

**Properties**
- `plant_type` — integer 1–6
- `stage` — integer 1–3 (baby, growing, done)
- `cooldown` — seconds remaining until ready for water
- `ready` — bool, true when `cooldown <= 0`
- `sprite` — SpriteSet keyed by stage (`"1"` / `"2"` / `"3"`); each frame backed by a PNG image, tinted by the plant's stage color from `plant_data`
- `bubble` — Sprite (60×60) shown above the plant when ready; tinted yellow

**Methods**
- `update(dt)` — count down `cooldown`; flips `ready` and `bubble.visible` when it hits zero
- `water()` — if `ready`, advance stage, reset cooldown, hide bubble; otherwise no-op
- `draw()` — renders `sprite`
- `draw_bubble()` — if `bubble.visible`, positions and draws the bubble above the plant

---

### Grafter

An Item subclass. Clones a stage-3 plant.

**Properties**
- `loaded_plant` — a Plant instance stored inside, or `nil`
- `sprite` — single Sprite; image swaps between `grafter_empty` (orange) and `grafter_loaded` (yellow) PNGs

**Methods**
- `interact(player, store, scene_manager)` — if player is holding grafter and active slot has a stage-3 plant: resets the plant to stage 1, stores a clone; swaps to `grafter_loaded` image
- `unload()` — sets `loaded_plant = nil`, swaps back to `grafter_empty` image; called by StoreScene when the clone is placed or sold
- `draw()` — draws grafter sprite; if loaded, also draws the stored plant sprite above it

---

### Slot

One cell in the store. Holds at most one item.

**Properties**
- `index` — position in the store array
- `x`, `y` — world position
- `item` — the Item in this slot, or `nil`
- `bg` — Sprite backed by `slot.png` (120×200)

**Methods**
- `new(index, slot_width)` — constructor
- `update(dt)` — delegates to item; positions item sprite within the slot
- `draw()` — draws slot background, then item if present

---

### Store

The 2D grid of slots (cols × rows). Handles layout and growth.

**Properties**
- `_slots` — flat ordered array of all Slot objects (row-major)
- `_grid` — `_grid[row][col]` table for direct cell access
- `_cols` — fixed number of columns (7)

**Methods**
- `new(init_cols, init_rows)` — constructor; populates `init_cols × init_rows` slots
- `grow()` — add one full row of `_cols` new slots to the south end
- `active_rows()` — returns the current row count (`math.ceil(#slots / _cols)`)
- `all_slots()` — returns the flat slot array
- `slot_near(px, py, max_dist)` — returns the nearest slot within `max_dist`, or nil
- `update(dt)` — delegates to all slots/items

---

### Customer

NPC that appears in the cashier zone and requests a specific plant.

**Properties**
- `state` — `"idle"` | `"walking_in"` | `"waiting"` | `"walking_out"`
- `plant_type` — integer type of requested plant
- `name` — display name shown in dialog (default `"Customer"`)
- `messages` — ordered array of dialog strings; empty = skip straight to plant bubble
- `msg_index` — index of the current message
- `done_talking` — bool; true once all messages have been advanced through
- `_full_text` — `"Name: message"` string for the current line; rebuilt on each `show()` / `advance()`
- `reveal_index` — number of characters currently visible (typewriter progress)
- `reveal_t` — accumulated time driving the reveal; reset with each new line
- `x`, `y` — world position
- `speed` — 80 px/s
- `sprite` — Sprite (120×240) backed by `customer.png` (white); `color` set per customer as a tint — default orange, scripted customers get a unique body color
- `bubble` — Sprite used as a visibility gate and position reference; `bubble.visible` controls whether the dialog/plant-request UI is shown; not drawn directly
- `accessory_sprite` — Sprite (120×120) drawn over the top half of the body; nil for anonymous customers or when the accessory file is missing

**Methods**
- `new(target_x, exit_x, y)` — constructor; `state = "idle"`
- `show(cfg)` — accepts `{ plant_type, messages, name, body_color, accessory }`; places customer at `exit_x` and begins walk-in; `accessory` is a string key passed to `A.load_accessory()`
- `advance()` — increments `msg_index`; sets `done_talking` after the last message; resets `reveal_index`/`reveal_t`/`_full_text` for the new line
- `line_complete()` — returns true if `done_talking` or `reveal_index >= #_full_text`
- `skip_reveal()` — snaps `reveal_index` to the end of the current line instantly
- `on_last_message()` — returns `done_talking`
- `serve()` — begin walking out (called on successful sale)
- `arrived()` — returns `state == "waiting"`
- `active()` — returns `state ~= "idle"`
- `update(dt)` — advances walk-in / walk-out movement; advances typewriter reveal while `bubble.visible` and not `done_talking`; positions sprite, bubble, and accessory sprite
- `draw()` — applies `ColorReplace` with `_primary` and `_secondary`; draws body sprite and accessory sprite; clears shader
- `draw_bubble()` — during dialog: draws 9-slice `speech_bubble` sized to the full line width with `speech_bubble_tail`, then prints the revealed substring on top; once `done_talking`: draws a 9-slice speech bubble containing the stage-3 plant image (80×80 inside 12px padding)

---

## Shaders

### ColorReplace

Replaces pure-red or pure-blue pixels in a sprite with runtime colors. Used by Player and Customer.

**Files**
- `assets/shaders/color_replace.glsl` — GLSL source loaded from disk
- `lua/game/shaders/color_replace.lua` — wrapper; `require`-cached so the shader is compiled once

**GLSL logic**
- Pure red pixel (`r > 0.9, g < 0.1, b < 0.1`) → replaced with `replace_color_a`
- Pure blue pixel (`b > 0.9, r < 0.1, g < 0.1`) → replaced with `replace_color_b`
- All other pixels → pass through unchanged

**API**
- `apply(primary, secondary)` — sends both colors and activates the shader; `secondary` is optional, defaults to `{0,0,0,0}`
- `clear()` — resets to the default Love2D shader

**Usage**
- Player: `apply(speed_tier_color)` — red mask pixels show the current speed tier color
- Customer: `apply(primary, secondary)` — red pixels = body color, blue pixels = secondary (shadow/detail) color

---

## Scenes

### StartScene

The first scene shown on launch. Pure screen-space UI — overrides `draw()` entirely, no camera transform.

**Location:** `lua/game/scenes/start_scene.lua`

**Properties**
- `selected` — index of the highlighted menu item (1 = New Game, 2 = Continue, 3 = Exit)
- `_font_title`, `_font_btn` — Love2D fonts created in `on_enter()`; stored on the scene so they are not recreated every frame
- `_prev_up`, `_prev_down`, `_prev_confirm` — previous-frame key states for edge detection

**Menu items**
- **New Game** — constructs and switches to `StoreScene` (same as Continue for now)
- **Continue** — constructs and switches to `StoreScene`
- **Exit** — calls `love.event.quit()`

**Navigation keys** (handled with raw `love.keyboard.isDown` + edge detection, not via the `Input` module)
- Up / W — move selection up
- Down / S — move selection down
- Enter / Space / F — confirm

**Notes**
- Fonts are saved and restored around `draw()` so the global Love2D font state is unchanged when `StoreScene` draws next frame
- `StoreScene` is `require`d lazily inside `_confirm()`, not at module load time, to avoid a circular load order

---

### StoreScene

The main gameplay scene. First-person 3D (raycaster) with a 14-column map.

**Location:** `lua/game/scenes/store_scene.lua`

**Map layout** (`build_map_grid(n)` where `n` = active store row count)

```
col:  1    2-5       6     7-13      14
     [W] [cashier] [SEP] [store]   [W]
```

- Col 1 / 14 — outer walls (always `1`)
- Cols 2–5 — cashier room (always open, `0`)
- Col 6 — separator wall (`SEP = 6`); open only in the two northernmost slot rows (rows 1 and 2)
- Cols 7–13 — store room (always open, `0`)
- Rows: row 1 = north wall, rows 2…n+1 = slot rows, row n+2 = south wall

**Key constants**

| Constant | Value | Meaning |
|---|---|---|
| `SEP` | `6` | Lua column index of the separator wall |
| `CASHIER_THRESH` | `6.0` | `player.x <= this` → player is in the cashier room |
| `CASHIER_POS_X` | `3.5` | Customer billboard world x |
| `PLAYER_START_X` | `10.0` | Player spawn x (store side) |
| `GRID_ORIGIN_X` | `7.5` | World x of slot (1, 1) — store columns start here |

**Passage (separator opening)**

Fixed at slot rows 1 and 2 (the northernmost rows) regardless of store size. This keeps the entrance to the cashier room at the north end, so the store expands southward without moving the passage.

**Properties**
- `player3d` — `Player3D` instance; x/y in grid units
- `map` — `Map` instance; rebuilt in `on_enter()` whenever `active_rows()` changes
- `_customer` — `Customer` NPC for cashier interactions
- `_last_active_slot` — slot currently targeted by the look-ray (nil when in cashier room)
- `_active_script_key` — key of the current scripted customer visit (nil if anonymous)
- `_script_cooldowns` — table of per-script sale countdown timers for dismissed customers

**Cashier interaction** (triggered when `player.x <= CASHIER_THRESH`)
- E — dismiss customer without sale
- F on last message + holding matching plant → `customer:serve()` + sell

**Slot interaction** (triggered when `player.x > CASHIER_THRESH` and look-ray hits a slot tile)
- E — pick up / put down item in the active slot
- F — interact with active slot's item (water plant, open BuyScene, etc.)

---

## Layer Priorities (Drawer)

| Priority | Content |
|----------|---------|
| (pre-drawer) | Parallax background layers (`store_bg_far/mid/near`) — tiled across full world width (-ZONE_WIDTH → store:width()) with p = 0.05/0.20/0.45; drawn manually before `drawer:draw()` |
| (pre-drawer) | Store wall tiles and window frames (`Store:draw_bg`) — drawn on top of parallax, before drawer |
| 0 | Store (slots, items) |
| 1 | Customer body |
| 2 | Cashier wall (`cashier_wall.png` with transparent window cutout) |
| 2.5 | Cashier floor (tiled `slot.png` across `x = -400` to `0`) |
| 3 | Plant ready bubbles (`Store:draw_bubbles()`) |
| 4 | Player (+ held item) |
| 5 | Customer speech / plant bubble |
