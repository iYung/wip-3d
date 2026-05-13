# Customer Dismiss Feature

## Context

- Single `_customer` object in `StoreScene`; states: `idle → walking_in → waiting → walking_out → idle`
- Scripted customers come from `customer_scripts.lua` (named arcs like Old Pete); random customers fill the rest
- `seen_scripts` in `game_state` tracks which script chapters have been shown — used to prevent repeats
- Currently no way to dismiss a customer without selling them a plant

---

## Steps

### 1. Add `Customer:dismiss()` method — `lua/game/customer.lua`

- Mirror `serve()`: set state to `walking_out`, hide bubble, hide heart bubble
- Set a flag `self.dismissed = true` so the caller can check outcome
- Reset `dismissed` to `false` in `show()`

### 2. Track the active script key in StoreScene — `lua/game/scenes/store_scene.lua`

- In `_next_customer_cfg()`, when a scripted customer is selected, store its key (`id .. ":" .. chapter`) in `self._active_script_key`
- For random (non-scripted) customers, set `self._active_script_key = nil`
- **Do not** mark the script as `seen` until the customer is actually served — move the `gs.seen_scripts[key] = true` write from selection time to after `serve()` completes

### 3. Add a scripted-customer cooldown table — `StoreScene`

- Add `self._script_cooldowns = {}` (key → transactions remaining) during `_setup_store()`
- Add `self._sale_count = 0` to track completed sales
- After any successful sale (`serve()` resolves and customer walks out), increment `_sale_count` and decrement all active cooldown values; remove entries that reach 0
- In `_next_customer_cfg()`, skip any script whose key is in `_script_cooldowns`

### 4. On dismiss, start cooldown for scripted customers — `StoreScene`

- After `_customer:dismiss()` is called, check `self._active_script_key`
- If set, add it to `_script_cooldowns` with a transaction count (e.g. `3` — returns after 3 other sales)
- **Do not** write to `gs.seen_scripts` — the chapter remains unseen so it can fire again after cooldown
- Reset `_active_script_key = nil`

### 5. Wire up the dismiss input — `StoreScene:update()`

- Choose an input (e.g. a dedicated key or the same interact button with no matching plant)
- Trigger condition: player is in the cashier zone (`player.x < 0`) and `_customer:arrived()`
- On dismiss input: call `_customer:dismiss()`, run cooldown logic from step 4, reset `_spawn_timer`

### 6. (Optional) Visual / UX polish

- Play a brief shake or "shoo" animation before `walking_out`
- Show a small text cue ("Come back later…") in the bubble before dismissing
- Make the cooldown transaction count tunable via a constant at the top of `store_scene.lua`
