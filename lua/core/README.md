# lua/core

Engine-level classes with no game-specific knowledge. Safe to reuse across projects.

---

## Sprite

A colored rectangle (or image) at a world position.

| Property | Type | Notes |
|----------|------|-------|
| `x`, `y` | number | World position (top-left) |
| `width`, `height` | number | Dimensions in pixels |
| `scale_x`, `scale_y` | number | Scale factors |
| `visible` | bool | Skips draw when false |
| `color` | `{r,g,b,a}` | Tint; defaults to white |
| `image` | Love2D image | Draws a rectangle if nil |
| `shader` | Love2D shader | Applied only during `draw()`, then cleared |

`Sprite.new(x, y, w, h)` — `draw()` — `update(dt)` (no-op hook)

---

## SpriteSet

A named collection of Sprites with one active at a time.

- `SpriteSet.new()`
- `add(name, sprite)` — register a sprite
- `set(name)` — switch the active sprite; forwards `x`/`y` to it on every `draw()`
- `draw()` / `update(dt)` — delegate to the active sprite
- `_active()` — returns the current Sprite

Implements the same `draw()`/`update(dt)` interface as Sprite, so it's a drop-in anywhere a sprite is expected.

---

## Drawer

Renders all registered drawables each frame in priority order.

- `Drawer.new()`
- `add(sprite, priority)` — lower priority = drawn first (behind); sorted on add
- `draw()` — calls `sprite:draw()` on each entry in order
- `clear()` — removes all entries

Any object with a `draw()` method can be registered, not just Sprites.

---

## Camera

Controls what part of the world is visible. Logical resolution: **1280 × 720**.

- `Camera.new(x, y)`
- `attach()` / `detach()` — push/pop the camera transform around a draw call
- `follow(target, lerp)` — smooth-track `target.x/y`; `lerp` 0 = instant, 1 = no movement
- `to_world(sx, sy)` / `to_screen(wx, wy)` — coordinate conversion
- `zoom` — scale factor (default `1.0`)

---

## Scene

A self-contained game state. Owns a Drawer and a Camera.

- `Scene.new()` — creates `self.drawer` and `self.camera`
- `update(dt)` / `draw()` — override in subclasses
- `on_enter()` — called when this scene becomes active
- `on_exit()` — calls `drawer:clear()` by default

`draw()` wraps `drawer:draw()` inside `camera:attach()`/`camera:detach()`.

---

## SceneManager

Holds the active scene and drives the game loop.

- `SceneManager.new()`
- `switch(scene)` — calls `on_exit()` on the old scene, `on_enter()` on the new one
- `update(dt)` / `draw()` — delegate to `current`
