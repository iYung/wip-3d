# Plant Types Steps

Goal: add plant types 2–6. Each type has its own cooldowns, stage colors, and a name. The shop lets the player choose which type to buy.

---

## What Already Exists

- `Plant.new(plant_type)` already accepts a type argument
- `PLANT_COOLDOWNS[plant_type][stage]` drives the cooldown per stage
- Stage colors are currently shared across all types (`STAGE_COLORS` in `plant.lua`)
- Only type 1 is defined in `plant_cooldowns.lua`

---

## Open Questions

- What are the 6 plant names?
- What cooldowns should types 2–6 have? (type 1 is 3s / 5s)
- Should each type have its own stage colors, or just a base tint per type?
- Should sell value vary by plant type, or stay flat (`SELL_VALUE` for all stage-3)?
- How does the shop present 6 plant types — expand the buy menu, or sub-menu?

---

## Step 1 — Plant Data

- [ ] Give each type a name — add to a new `lua/game/data/plant_data.lua`
- [ ] Add a buy cost per type to `plant_data.lua` (replaces the flat `PLANT_COST` for plants)
- [ ] Add entries for types 2–6 in `plant_cooldowns.lua`
  - Suggestion: faster types have shorter cooldowns (e.g. type 1 = slow/cheap, type 6 = fast/expensive)
- [ ] Add a `PLANT_COLORS` table — `[plant_type][stage] = {r,g,b,a}` — so each type has a distinct palette
  - Can live in `plant_data.lua` alongside name and cost

---

## Step 2 — Plant.new Uses Per-Type Colors

- [ ] In `Plant.new(plant_type)`, look up colors from `PLANT_COLORS[plant_type]` instead of the shared `STAGE_COLORS`
- [ ] Verify all 6 types render visually distinct at each stage

---

## Step 3 — Add Plant Types to Shop Catalogue

The shop UI uses a `CATALOGUE` table in `buy_scene.lua` (see [shop-ui-steps.md](shop-ui-steps.md)). Each plant type is one entry with `kind = "plant"` and a `plant_type` index.

- [ ] For each type 2–6, append an entry to `CATALOGUE`:
  ```
  { label = PLANT_NAMES[i], description = "...", cost = PLANT_DATA[i].cost, kind = "plant", plant_type = i }
  ```
- [ ] Remove the flat `PLANT_COST` from `config.lua` once all per-type costs are live

---

## Step 4 — Sell Value Per Type (optional)

- [ ] Decide if sell value scales with plant type (e.g. type 1 = 5, type 6 = 15)
- [ ] If yes: add `SELL_VALUES = { [1]=5, ... }` to config and update sell logic in `store_scene.lua`

---

## Step 5 — End-to-End Test

- [ ] Buy each plant type from the shop — correct name shown, correct cost deducted
- [ ] Grow each type through stages — correct cooldowns, correct colors per stage
- [ ] Sell each type at stage 3 — correct currency awarded
- [ ] Graft each type — clone inherits correct plant_type
