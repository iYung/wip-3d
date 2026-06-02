# Progress

## What's Built

All MVP steps are implemented and running. Expand Store, Shop UI, Plant Types, Context HUD, Cashier Zone, Speed Upgrade, Player Walk, Customer System, Sprite Images, Facing Direction, and Customer Scripts (return customers + questlines) features complete.

Completed step files are moved to [`archive/`](archive/).

---

### Core (`lua/core/`)

| File | What it does |
|------|-------------|
| `sprite.lua` | Single drawable unit — draws a PNG image scaled to `width × height` if set, colored rectangle otherwise; `color` always applies as a tint |
| `spriteset.lua` | Named collection of sprites, one active at a time; forwards x/y to active sprite on draw |
| `drawer.lua` | Holds drawables sorted by priority, calls draw() each frame |
| `camera.lua` | Translates world → screen; follow(target, lerp) with 0=instant, 1=no movement |
| `scene.lua` | Base class with drawer + camera; on_enter/on_exit lifecycle |
| `scene_manager.lua` | Swaps scenes, calls on_exit/on_enter, delegates update/draw |

---

### Game (`lua/game/`)

| File | What it does |
|------|-------------|
| `assets.lua` | Loads all PNGs once at startup; require-cached so every file can `require` it cheaply; `sneakers` and `expand_slot` loaded conditionally via `try_img` (art not yet created); all other assets use `img()` and are required to exist |
| `config.lua` | Shared constants — `U`, `SLOT_COST`, `ZONE_WIDTH` (400px cashier zone) |
| `input.lua` | Polls keyboard each frame; A/D or arrows = move, E = pick up/down, F = interact; W/S or up/down = `move_up`/`move_down` (menu nav); Enter/Space/F = `menu_confirm` |
| `game_state.lua` | Holds store, player, currency, `unlocked_plants`, `stage3_counts`, `seen_scripts`, `speed_level`, `growth_level`, `growth_mult`; survives scene switches |
| `player.lua` | Moves left/right into cashier zone; holds one item; 4-variant SpriteSet (idle/walk × no-held/held), each backed by a PNG; `speed` upgradeable via shop; uses `ColorReplace` shader to swap pure-red mask pixels to the current speed tier color on draw |
| `settings_state.lua` | Holds `fullscreen` bool, `sfx_volume`/`music_volume` ints (0–100), and `keybinds` table (6 actions); owns `love.window.setFullscreen`; mutated exclusively by `SettingsMenu` |
| `slot.lua` | One store cell; single `slot.png` background sprite; positions its item every frame |
| `store.lua` | Array of slots; `slot_at(x)`, `grow()`, `draw_bubbles()` for high-priority bubble rendering; `draw_bg(A)` draws wall tiles and window frames using group-of-4 rule |
| `customer.lua` | Cashier zone NPC; white PNG tinted per character via `body_color`; optional `accessory_sprite` (120×120) drawn over the top half, synced to body flip; dialog lines reveal character-by-character (40 chars/s) inside a 9-slice `speech_bubble.png` box; F skips to full line, second F advances; `line_complete()` / `skip_reveal()` methods; state machine: idle → walking_in → waiting → (sale) → talking_after → walking_out; `dismiss()` sends customer away without selling; `after_messages` (from script cfg) play in `talking_after` state after a sale via `advance_after()`, before the heart bubble; `done_after` flag skips directly to walking_out when no after_messages; when waiting, shows a 9-slice speech bubble containing the requested plant's stage-3 image (104×104 inside 12px padding). **`bubble.visible` is a shared gate** — it controls both the text dialog and the plant request bubble. |

### Items (`lua/game/items/`)

| File | What it does |
|------|-------------|
| `item.lua` | Base class for all carriable objects; `carriable = true`, `sellable = true`, `name = "Item"` by default |
| `watering_can.lua` | interact() waters the plant in the active slot; blue PNG |
| `pc_store.lua` | interact() opens BuyScene; blocked if player is holding anything; `sellable = false`; blue-grey PNG |
| `plant.lua` | 6 types, 3 stages each; per-type cooldown from `plant_data`; stage PNGs rendered as-is (no tinting); yellow bubble via `draw_bubble()` |
| `grafter.lua` | Clones a stage-3 plant (resets original to stage 1, stores clone); `unload()` method handles image swap back to empty; orange PNG (empty) / yellow PNG (loaded) |
| `sell_bin.lua` | Sell station; F while holding any sellable item sells it for currency; red PNG |

### Scenes (`lua/game/scenes/`)

| File | What it does |
|------|-------------|
| `start_scene.lua` | Title screen with New Game / Continue / Settings / Exit buttons; uses `input:pressed("move_up"/"move_down"/"menu_confirm")` for navigation; accepts `open_settings` callback (4th constructor arg) called when Settings selected; New Game and Continue both enter StoreScene |
| `store_scene.lua` | Main loop — player moves, camera follows on x then clamps to world bounds, pick up/interact handled here; cashier zone logic (F skips reveal → advances → sells → talking_after → advances after_messages → walks out; E dismisses); `esc_opens_settings = true` so main.lua intercepts Escape for the settings menu; unified parallax tiles `store_bg_*` across full world width |
| `buy_scene.lua` | Carousel UI — 10 items (6 plants + Watering Can + Grafter + Expand Slot + Heat Lamps); A/D cycle, F buy, E cancel; `esc_opens_settings = true` |
| `settings_menu.lua` | Pause overlay — 6 buttons: Fullscreen/Window, SFX Volume, Music Volume, Keybinds, Exit Settings, Leave Game; keybinds sub-screen captures a single key press; loads assets directly (not via `A.`); delegates all mutations to `SettingsState` |

### Data (`lua/game/data/`)

| File | What it does |
|------|-------------|
| `plant_data.lua` | Per-type name, buy cost, sell value, and cooldowns for all 6 plant types |
| `customer_scripts.lua` | Array of scripted customer chapters; each has `id`, `chapter`, `trigger` (plant_type + stage-3 count), name, body color, optional `accessory`, requested plant, `messages`, and optional `after_messages` (post-sale dialog); same `id` = same character across visits; chapter N requires all prior chapters seen; includes Sage — 4-chapter tutorial arc (`id="sage"`, `accessory="monocle"`, `trigger.count=0` chapter 1 guarantees early appearance) |

### Assets (`assets/`)

PNG files for all sprites — player variants, plants (18 total: 6 types × 3 stages, rendered without tinting), items, UI elements, backgrounds, and speech bubbles.

`assets/accessories/` — accessory PNGs for named customers (120×120, transparent background). Loaded lazily by `A.load_accessory(name)`; missing files are cached as `false` so no disk re-check occurs. Currently contains `flat_cap.png` (Old Pete).

---

## Key Numbers

| Thing | Value |
|-------|-------|
| Base unit `U` | 20px |
| Slot size | 6U × 10U (120×200) |
| Player size | 6U × 12U (120×240) |
| All items | 6U × 6U (120×120) |
| Customer bubble | 6U × 6U (120×120) — matches plant sprite size |
| Plant bubble | 3U × 3U (60×60) |
| Initial slots | 10 |
| Player speed | 220 px/s (base); upgradeable |
| Camera lerp | 0.85 (smooth follow on x, locked y) |
| Cashier zone width | 20U (400px), at x = -400 to 0 |
| Customer walk speed | 80 px/s |
| Customer spawn interval | 3–6s |

---

## Controls

| Key | Action |
|-----|--------|
| A / ← | Move left |
| D / → | Move right |
| E | Pick up / put down (in cashier zone: dismiss customer) |
| F | Interact (water, open shop) |
| Escape | Open/close Settings menu (in-game); Quit (from start screen) |

---

## Full Loop

**Growing:**
1. Walk to slot 3 (PC) with empty hands → F to open shop
2. F to buy → plant appears in your hand
3. E over an empty slot → place plant
4. Walk to slot 1 → E to pick up watering can
5. Walk back to plant slot → wait for bubble
6. F → waters plant, bubble disappears, stage advances
7. Repeat for stage 2
8. Stage 3 = done, no more bubble

**Selling to a customer:**
1. Customer walks in from the left; if scripted, dialog begins
2. F to advance through their messages
3. Once done talking (or immediately if no dialog), a speech bubble with the plant image appears
4. Pick up the matching stage-3 plant
5. Walk into cashier zone (x < 0) → F to sell for 2× value

**Return customers / questlines:**
- Each time a plant type reaches stage 3, `stage3_counts[pt]` increments
- When a customer spawns, all script chapters whose trigger is met and whose prior chapters have been seen become eligible
- One eligible chapter is picked at random and marked seen (`seen_scripts["id:chapter"]`)
- Characters return across multiple visits as their thresholds are hit, carrying dialog continuity

---

## Up Next

See open questions in `game-design.md`.

### Recently completed

- **Settings menu + SettingsState** — `SettingsState` holds fullscreen, SFX/music volume, and keybinds; `SettingsMenu` is a pause overlay with 6 buttons (Fullscreen, SFX Volume, Music Volume, Keybinds, Exit Settings, Leave Game) and a key-capture sub-screen; wired in `main.lua` — Escape toggles it in any scene with `esc_opens_settings = true`; start screen gains a Settings button (4th menu item) and switches from hardcoded `love.keyboard.isDown` to `input:pressed()` for navigation

- **Post-sale dialogue (`talking_after`)** — customers can now deliver `after_messages` lines after a sale, before the heart bubble and walk-out; `Customer:serve()` transitions to `talking_after` when `after_messages` present; `advance_after()` cycles lines then exits to `walking_out`; F-key handling in `store_scene` routes to `advance_after()` in this state

- **Sage tutorial character** — 4-chapter arc added to `customer_scripts`: chapter 1 (`trigger.count=0`) guaranteed early; teaches plant variety, the PC, grafting, and upgrades across 4 visits; uses `after_messages` for post-sale tips; `accessory = "monocle"`

- **Horizontal separator with centered, immovable passage** — separator redesigned as an east-west row (row 3) rather than a north-south column; cashier room occupies row 2 (north), store rows begin at row 4 (south); passage is cols 5&6, splitting 8 inner cols as 3 wall + 2 open + 3 wall — permanently centered by construction; store grows by appending rows to the south, which is perpendicular to the separator, so the passage position is structurally immutable and never recalculated; cashier zone check changed from `player.x <= CASHIER_THRESH` to `player.y <= CASHIER_THRESH` (4.0); constants updated: `CASHIER_POS_X=6.0`, `CASHIER_POS_Y=2.5`, `PLAYER_START_X=6.0`, `GRID_ORIGIN_X=2.5`, `GRID_ORIGIN_Y=4.5`

- **Cashier flipped to left side** — store map reorganised so the cashier room occupies the left four columns (cols 2–5) and the store room the right seven columns (cols 7–13), with the separator at col 6; `GRID_ORIGIN_X` shifted from 2.5 → 7.5, `CASHIER_THRESH` 9.0 → 6.0 (comparison flipped to `<=`), `CASHIER_POS_X` 11.5 → 3.5, `PLAYER_START_X` 5.0 → 10.0

- **Player speed sprites** — speed upgrades now apply a GLSL color-replace shader at draw time instead of swapping sprite sets; pure-red pixels in the player PNG are replaced with the tier's color (`speed_tiers.lua` now carries a `color` field per tier); `Player:set_speed_level(level, color)` stores the active color; no extra PNG assets needed

- **Start screen** — `StartScene` with New Game / Continue / Exit buttons; keyboard navigation (up/down/W/S + Enter/Space/F); `main.lua` now opens `StartScene` first; `StoreScene` constructed lazily on confirm; font state saved/restored so store rendering is unaffected

- **Growth upgrade (Heat Lamps)** — purchasable 3-tier upgrade in the PC Store; tiers cost $20/$50/$100 and scale all plant timers by 1.25×/1.60×/2.00× via `gs.growth_mult` multiplied into `dt` in `StoreScene:update`; `SPEED_TIERS` moved from `config.lua` to `data/speed_tiers.lua` alongside new `data/growth_tiers.lua`

- **PC store item images** — Watering Can, Grafter, Expand Slot, Sneakers entries in buy_scene now show PNG previews instead of colored rectangles; Expand Slot and Sneakers fall back to a grey box until `expand_slot.png` / `sneakers.png` are created
- **Remove image fallbacks** — `slot_highlight`, `store_bg_*`, and `speech_bubble*` converted from `try_img` to `img()`; nil-checks removed from slot.lua and customer.lua draw sites; redundant `.color = {1,1,1,1}` assignments removed from player, watering_can, grafter, pc_store, and garbage_bin
- **Slot highlight image** — white rectangle replaced with `slot_highlight.png`
- **Plant images instead of tinting** — plant sprites now render their stage PNGs as-is; tint removed from `plant.lua`; customer request bubble replaced with a 9-slice speech bubble showing the stage-3 plant image; store preview shows stage-3 image; `colors` field no longer used for rendering
- **Customer dismiss** — E dismisses a waiting customer without selling; scripted characters go on a 3-sale cooldown and return (chapter stays unseen until served); `seen_scripts` now written on sale, not on spawn
- **Typewriter dialogue** — customer dialog lines reveal character-by-character at 40 chars/s inside a 9-slice `speech_bubble.png` box; F skips to the full line, a second F advances; HUD label switches between F: SKIP and F: NEXT; graceful fallback to text-only if the bubble asset is missing
- **Slot item centering** — items now centered using `spr.width`/`spr.height` instead of hardcoded offsets
- **Plant bubble while held** — `Player:draw()` calls `draw_bubble()` on the held item so the bubble is visible while carrying a ready plant
- **Garbage bin replaces sell bin** — `GarbageBin` (F: DISCARD) is the active discard station; `sell_bin.lua` removed
- **Store camera bounds** — camera x clamped after follow so neither screen edge overruns the world; active from the start with 6 slots (world 1800px > screen 1280px)
- **Store background walls** — `Store:draw_bg(A)` tiles `store_wall.png` and places `store_window.png` using a group-of-4 rule; parallax layers (`store_bg_*`) tile across full world width (-ZONE_WIDTH → store:width()) as a single unified system covering both the cashier zone and store; parallax factors 0.05/0.20/0.45
- **Initial slots set to 10** (for testing)

## Cut / Not Yet Built

- Win condition or idle loop
- Customer patience timer (customer never leaves until served)
