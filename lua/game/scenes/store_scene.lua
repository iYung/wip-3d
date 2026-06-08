local Scene3D        = require("lua/core/scene_3d")
local Map            = require("lua/core/map")
local Player3D       = require("lua/game/player_3d")
local Timer          = require("lua/core/timer")
local WateringCan    = require("lua/game/items/watering_can")
local PCStore        = require("lua/game/items/pc_store")
local GarbageBin     = require("lua/game/items/garbage_bin")
local BuyScene       = require("lua/game/scenes/buy_scene")
local PLANT_DATA     = require("lua/game/data/plant_data")
local CUSTOMER_SCRIPTS = require("lua/game/data/customer_scripts")
local COOLDOWN_TIERS = require("lua/game/data/cooldown_tiers")
local Customer       = require("lua/game/customer")
local A              = require("lua/game/assets")
local ColorReplace   = require("lua/game/shaders/color_replace")
local WallPattern    = require("lua/game/shaders/wall_pattern")
local Sound          = require("lua/game/sound")
local WaterDrone     = require("lua/game/water_drone")

-- Map layout: cashier room (north) / separator row / store room (grows south).
-- The separator runs east-west, so passage cols are fixed regardless of store depth.
--
--   row 1      : north outer wall
--   row 2      : cashier room
--   row 3 (SEP): separator — all wall except cols 5 & 6 (passage, centred in 8 inner cols)
--   rows 4..3+n: store room (n rows, grows south)
--   row 4+n    : south outer wall
--
-- Inner cols 2-9 (8 cols): 3 wall | 2 passage | 3 wall → equal, never changes.
local function build_map_grid(n)
    local W     = 10   -- 1 outer-left + 8 inner + 1 outer-right
    local SEP   = 3    -- map row index of the separator
    local PASS_L = 5   -- left passage col  (cols 2-4 = wall, 5-6 = open, 7-9 = wall)
    local PASS_R = 6   -- right passage col

    local function all_walls()
        local r = {}; for c = 1, W do r[c] = 1 end; return r
    end
    local function open_row()
        local r = {}
        for c = 1, W do r[c] = (c == 1 or c == W) and 1 or 0 end
        return r
    end

    local rows = {}
    rows[1]   = all_walls()   -- north outer wall
    rows[2]   = open_row()    -- cashier room

    local sep_row = {}        -- separator: wall everywhere except passage cols
    for c = 1, W do
        sep_row[c] = (c >= PASS_L and c <= PASS_R) and 0 or 1
    end
    rows[SEP] = sep_row

    for map_row = SEP + 1, SEP + n do
        rows[map_row] = open_row()   -- store room rows
    end
    rows[SEP + n + 1] = all_walls()  -- south outer wall

    return rows
end

-- Player spawns at the southernmost store row.
-- Store row r has center y = 4.5 + (r-1), matching GRID_ORIGIN_Y in store.lua.
local function store_geometry(n)
    return { player_y = 4.5 + (n - 1) }
end

local CASHIER_THRESH  = 4.0   -- player.y <= this → cashier/separator zone
local CASHIER_POS_X   = 6.0   -- customer billboard x (passage centre)
local CASHIER_POS_Y   = 2.5   -- customer billboard y (cashier room centre)
local CASHIER_ENTRY_X  = 1.5  -- customer walk-in start x
local CUST_WALK_SPEED  = 1.0  -- grid units/s during walk animation
local CUST_WALK_FRAME_T = 0.15 -- seconds per walk frame toggle

local PLAYER_START_X  = 6.0   -- passage centre x; aligned so walking north goes straight through
local PLAYER_START_A  = -math.pi / 2  -- facing north

local INTERACT_RANGE  = 3.0   -- grid units: max look-ray distance for slot hover
local HOVER_MIN_T     = 1.0  -- ignore tiles the ray enters closer than this (player is on the edge)
local COLLISION_M     = 0.25  -- grid units: wall collision margin

local BASE_PX_SPEED   = 220   -- reference 2D speed (px/s)
local BASE_3D_SPEED   = 3.0   -- matching 3D speed (grid units/s)

local DISMISS_COOLDOWN_SALES = 3

local function spawn_cooldown(gs)
    if gs.cooldown_level == 0 then return 4 end
    return COOLDOWN_TIERS[gs.cooldown_level].cooldown
end

local SW = 1280
local SH = 720

local function plant_sell_value(plant)
    if plant.stage ~= 3 then return 1 end
    local pd = PLANT_DATA[plant.plant_type]
    return pd and pd.sell or 5
end

-- Returns the current displayable image for an item (Sprite or SpriteSet)
local function item_image(item)
    local s = item.sprite
    if not s then return nil end
    if type(s._active) == "function" then
        local active = s:_active()
        return active and active.image
    end
    return s.image
end

-- Returns distance along ray (px,py)+(dx,dy)*t to the slot's 1x1 floor tile, or nil.
local function ray_slot_dist(px, py, dx, dy, slot)
    local tx, ty = math.floor(slot.px), math.floor(slot.py)
    local function slab(p, d, lo, hi)
        if math.abs(d) < 1e-10 then
            return (p >= lo and p <= hi) and 0 or math.huge, math.huge
        end
        local t1, t2 = (lo - p) / d, (hi - p) / d
        if t1 > t2 then t1, t2 = t2, t1 end
        return t1, t2
    end
    local x1, x2 = slab(px, dx, tx, tx + 1)
    local y1, y2 = slab(py, dy, ty, ty + 1)
    local tmin = math.max(x1, y1)
    local tmax = math.min(x2, y2)
    if tmax < 0 or tmin > tmax then return nil end
    return math.max(0, tmin)
end

local StoreScene = setmetatable({}, { __index = Scene3D })
StoreScene.__index = StoreScene

function StoreScene.new(game_state, input, scene_manager, is_new_game)
    local self              = Scene3D.new()
    setmetatable(self, StoreScene)
    self.game_state         = game_state
    self.input              = input
    self.scene_manager      = scene_manager
    self._is_new_game       = is_new_game
    self._initialized       = false
    self._last_active_slot  = nil
    self._hover_tile        = nil
    self._last_active_rows  = nil
    self.esc_opens_settings = true
    return self
end

function StoreScene:on_enter()
    local gs = self.game_state

    if not self._initialized then
        self._initialized = true
        self:_setup_store()
    end

    -- Patch player.active_slot so item interact() calls use 3D proximity
    local scene = self
    gs.player.active_slot = function(_, _)
        return scene._last_active_slot
    end

    -- Wire drone if purchased while the scene was already initialized
    if gs.has_drone and not self._water_drone then
        self._water_drone = WaterDrone.new(gs.store, gs)
    end

    -- Sync movement speed with game state
    self.player3d.move_speed = gs.player.speed / BASE_PX_SPEED * BASE_3D_SPEED

    local n = gs.store:active_rows()
    if n ~= self._last_active_rows then
        self.map = Map.new(build_map_grid(n))
        self._last_active_rows = n
    end
end

function StoreScene:on_exit() end

function StoreScene:_setup_store()
    local gs      = self.game_state
    local slots   = gs.store:all_slots()
    local self_ref = self

    slots[1].item = WateringCan.new()
    slots[2].item = GarbageBin.new()
    slots[3].item = PCStore.new(function()
        return BuyScene.new(gs, self_ref.input, self_ref.scene_manager, self_ref)
    end)

    local geom = store_geometry(gs.store:active_rows())
    self.player3d = Player3D.new(PLAYER_START_X, geom.player_y, PLAYER_START_A)

    -- Customer: pixel positions unused in 3D; state machine & dialog still drive logic
    self._customer          = Customer.new(100, -1000, 0)
    self._spawn_timer       = Timer.new(self._is_new_game and 0.1 or spawn_cooldown(gs))
    self._water_drone       = gs.has_drone and WaterDrone.new(gs.store, gs) or nil
    self._active_script_key = nil
    self._active_script     = nil
    self._script_cooldowns  = {}
    self._cust_3d_x        = CASHIER_POS_X
    self._cust_anim        = nil
    self._cust_walk_timer  = 0
    self._cust_walk_frame  = false
end

-- -------------------------------------------------------------------------
-- Update
-- -------------------------------------------------------------------------

function StoreScene:update(dt)
    local gs = self.game_state
    if self._water_drone then self._water_drone:update(dt) end
    local p  = self.player3d

    -- Sync 3D move speed from game state
    p.move_speed = gs.player.speed / BASE_PX_SPEED * BASE_3D_SPEED

    -- Movement + collision
    local ox, oy = p.x, p.y
    p:update(dt)
    local m = COLLISION_M
    if self.map:is_wall(math.floor(p.x + m), math.floor(oy)) or
       self.map:is_wall(math.floor(p.x - m), math.floor(oy)) then
        p.x = ox
    end
    if self.map:is_wall(math.floor(p.x), math.floor(p.y + m)) or
       self.map:is_wall(math.floor(p.x), math.floor(p.y - m)) then
        p.y = oy
    end

    -- Active slot: look-ray hits the slot's tile and it's within INTERACT_RANGE
    if p.y > CASHIER_THRESH then
        local dx, dy = math.cos(p.angle), math.sin(p.angle)
        local best_slot, best_t = nil, INTERACT_RANGE
        for _, slot in ipairs(gs.store:all_slots()) do
            local t = ray_slot_dist(p.x, p.y, dx, dy, slot)
            if t and t >= HOVER_MIN_T and t < best_t then best_t = t; best_slot = slot end
        end
        self._last_active_slot = best_slot
        self._hover_tile = best_slot and
            { x = math.floor(best_slot.px), y = math.floor(best_slot.py) } or nil
    else
        self._last_active_slot = nil
        self._hover_tile       = nil
    end

    -- Detect walking_out (set by serve/dismiss at end of previous frame's input handling)
    if self._customer.state == "walking_out" and self._cust_anim ~= "out" then
        self._cust_anim = "out"
    end

    -- Customer update (dialog typewriter)
    self._customer:update(dt)

    -- 3D walk animation
    if self._cust_anim then
        self._cust_walk_timer = self._cust_walk_timer + dt
        if self._cust_walk_timer >= CUST_WALK_FRAME_T then
            self._cust_walk_timer  = self._cust_walk_timer - CUST_WALK_FRAME_T
            self._cust_walk_frame  = not self._cust_walk_frame
        end
        if self._cust_anim == "in" then
            self._cust_3d_x = math.min(CASHIER_POS_X, self._cust_3d_x + CUST_WALK_SPEED * dt)
            if self._cust_3d_x >= CASHIER_POS_X then
                self._customer.state          = "waiting"
                self._customer.bubble.visible = true
                self._cust_anim               = nil
                self._cust_walk_timer         = 0
                self._cust_walk_frame         = false
            end
        elseif self._cust_anim == "out" then
            self._cust_3d_x = math.max(CASHIER_ENTRY_X, self._cust_3d_x - CUST_WALK_SPEED * dt)
            if self._cust_3d_x <= CASHIER_ENTRY_X then
                self._customer.state                    = "idle"
                self._customer.sprite.visible           = false
                self._customer.bubble.visible           = false
                self._customer.heart_bubble.visible     = false
                self._cust_anim                         = nil
                self._cust_walk_timer                   = 0
                self._cust_walk_frame                   = false
            end
        end
    end

    -- Spawn timer
    if not self._customer:active() and not self._cust_anim then
        local cd = spawn_cooldown(self.game_state)
        if cd == 0 then
            local cfg = self:_next_customer_cfg()
            if cfg then
                self._customer:show(cfg)
                self._cust_3d_x       = CASHIER_ENTRY_X
                self._cust_anim       = "in"
                self._cust_walk_timer = 0
                self._cust_walk_frame = false
            end
        elseif self._spawn_timer:update(dt) then
            local cfg = self:_next_customer_cfg()
            if cfg then
                self._customer:show(cfg)
                self._cust_3d_x       = CASHIER_ENTRY_X
                self._cust_anim       = "in"
                self._cust_walk_timer = 0
                self._cust_walk_frame = false
            end
            self._spawn_timer:reset(spawn_cooldown(self.game_state))
        end
    end

    -- Store (plant timers)
    gs.store:update(dt * gs.growth_mult)

    -- Held item timers (e.g. grafter no-space bubble)
    local held = gs.player.held_item
    if held and held.update then held:update(dt) end

    -- Action input (E / F — updated globally by love.update before this)
    if self.input:pressed("pick_up_down") then self:_handle_pick_up_down() end
    if self.input:pressed("interact")     then self:_handle_interact()      end
end

function StoreScene:_handle_pick_up_down()
    local player = self.game_state.player
    local p      = self.player3d
    local slot   = self._last_active_slot

    if p.y <= CASHIER_THRESH then
        if self._customer:arrived() and not self._cust_anim
           and not (self._active_script and self._active_script.no_dismiss) then
            self._customer:dismiss()
            Sound.play("dismiss_customer")
            if self._active_script_key then
                self._script_cooldowns[self._active_script_key] = DISMISS_COOLDOWN_SALES
                self._active_script_key = nil
                self._active_script     = nil
            end
        end
        return
    end

    if player.held_item then
        if slot and not slot.item then
            slot.item        = player.held_item
            player.held_item = nil
            Sound.play("put_down")
        end
    else
        if slot and slot.item and slot.item.carriable then
            player.held_item = slot.item
            slot.item        = nil
            Sound.play("pick_up")
        end
    end
end

function StoreScene:_handle_interact()
    local gs     = self.game_state
    local player = gs.player
    local store  = gs.store
    local p      = self.player3d
    local slot   = self._last_active_slot

    -- Cashier zone: dialog / sale
    if p.y <= CASHIER_THRESH and self._customer.state == "talking_after" and not self._cust_anim then
        if not self._customer:line_complete() then
            self._customer:skip_reveal()
            Sound.play("dialogue_skip")
        else
            self._customer:advance_after()
            Sound.play("dialogue_advance")
        end
        return
    end

    if p.y <= CASHIER_THRESH and self._customer:arrived() and not self._cust_anim then
        local held = player.held_item
        if self._customer:on_last_message()
           and held
           and held.plant_type == self._customer.plant_type
           and held.stage == 3 then
            gs.currency      = gs.currency + plant_sell_value(held)
            player.held_item = nil
            self._customer:serve()
            Sound.play("sell_plant")
            if self._active_script_key then
                gs.seen_scripts[self._active_script_key] = true
                self._active_script_key = nil
                self._active_script     = nil
            end
            for key, count in pairs(self._script_cooldowns) do
                local rem = count - 1
                if rem <= 0 then self._script_cooldowns[key] = nil
                else              self._script_cooldowns[key] = rem end
            end
        else
            if not self._customer:line_complete() then
                self._customer:skip_reveal()
                Sound.play("dialogue_skip")
                return
            end
            self._customer:advance()
            Sound.play("dialogue_advance")
        end
        return
    end

    -- Garbage bin discard
    if p.y > CASHIER_THRESH
       and player.held_item
       and player.held_item.sellable ~= false
       and slot and slot.item and slot.item.is_garbage_bin then
        player.held_item = nil
        Sound.play("discard_plant")
        return
    end

    local item = player.held_item or (slot and slot.item)
    if item then
        local prev_stage = slot and slot.item and slot.item.stage
        if item.buy_scene_factory then Sound.play("open_shop") end
        item:interact(player, store, self.scene_manager)
        if slot and slot.item and slot.item.stage == 3 and prev_stage == 2 then
            local pt = slot.item.plant_type
            gs.stage3_counts[pt] = (gs.stage3_counts[pt] or 0) + 1
        end
    end
end

function StoreScene:_next_customer_cfg()
    local gs = self.game_state

    local qualified = {}
    for _, script in ipairs(CUSTOMER_SCRIPTS) do
        local key = script.id .. ":" .. script.chapter
        if not gs.seen_scripts[key] and not self._script_cooldowns[key] then
            local t = script.trigger
            if (gs.stage3_counts[t.plant_type] or 0) >= t.count then
                local prior_ok = true
                for ch = 1, script.chapter - 1 do
                    if not gs.seen_scripts[script.id .. ":" .. ch] then
                        prior_ok = false; break
                    end
                end
                if prior_ok then qualified[#qualified + 1] = script end
            end
        end
    end

    if #qualified > 0 then
        local script            = qualified[math.random(#qualified)]
        self._active_script_key = script.id .. ":" .. script.chapter
        self._active_script     = script
        return script
    end

    self._active_script_key = nil
    self._active_script     = nil
    local keys = {}
    for pt in pairs(gs.unlocked_plants) do keys[#keys + 1] = pt end
    if #keys == 0 then return nil end
    local pt = keys[math.random(#keys)]
    return {
        plant_type      = pt,
        primary_color   = { math.random(), math.random(), math.random(), 1 },
        secondary_color = { math.random(), math.random(), math.random(), 1 },
    }
end

-- -------------------------------------------------------------------------
-- Draw
-- -------------------------------------------------------------------------

function StoreScene:draw()
    local gs  = self.game_state
    local p   = self.player3d

    -- Build billboard sprite list
    local sprites = {}
    for _, slot in ipairs(gs.store:all_slots()) do
        if slot.item then
            local img = item_image(slot.item)
            if img then
                sprites[#sprites + 1] = { x = slot.px, y = slot.py, image = img }
            end
            -- Plant ready bubble floats above the item (not for intercom — it uses HUD box)
            if slot.item.bubble and slot.item.bubble.visible and slot.item.bubble.image
               and not slot.item.is_intercom then
                sprites[#sprites + 1] = {
                    x       = slot.px,
                    y       = slot.py,
                    image   = slot.item.bubble.image,
                    scale   = 0.45,
                    voffset = 1.3,
                }
            end
        end
    end

    -- Water drone billboard
    if self._water_drone then
        local drone_img = (self._water_drone.frame == 2 and A.water_drone2) or A.water_drone
        if drone_img then
            sprites[#sprites + 1] = {
                x       = self._water_drone.x,
                y       = self._water_drone.y,
                image   = drone_img,
                scale   = 0.5,
                voffset = 1.4,
            }
        end
    end

    -- Customer billboard
    if self._customer:active() or self._cust_anim ~= nil then
        local cust_img = (self._cust_anim and self._cust_walk_frame) and A.customer_walk or A.customer
        self._customer:push_billboard_sprites(sprites, self._cust_3d_x, CASHIER_POS_Y, cust_img, (self._cust_anim == "out"))
    end

    -- 3D world
    local wall_shader = A.wall_pattern and {
        apply = function() WallPattern.apply(A.wall_pattern, A.store_wall) end,
        clear = WallPattern.clear,
    } or nil
    self.raycaster:draw(self.map, p.x, p.y, p.angle, self._hover_tile, {[1] = A.store_wall}, wall_shader)
    self.raycaster:draw_sprites(sprites, p.x, p.y, p.angle)

    -- Screen-space HUD
    self:_draw_hud()
end

function StoreScene:_draw_hud()
    local gs     = self.game_state
    local player = gs.player
    local p      = self.player3d
    local hud    = self:_hud_labels()

    -- Currency: top-left
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("$" .. gs.currency, 10, 10)

    -- Held item: bottom-right corner (FPS-style)
    if player.held_item then
        local img = item_image(player.held_item)
        if img then
            local size = 180
            local hx   = SW - size - 20
            local hy   = SH - size - 20
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, hx, hy, 0, size / img:getWidth(), size / img:getHeight())
            -- Bubble indicator above held item (not for intercom — it uses HUD box)
            if player.held_item.bubble and player.held_item.bubble.visible
               and player.held_item.bubble.image
               and not player.held_item.is_intercom then
                local b = player.held_item.bubble.image
                love.graphics.draw(b, hx + size / 2 - 25, hy - 55, 0,
                    50 / b:getWidth(), 50 / b:getHeight())
            end
        end
    end

    -- Context labels: bottom-left, stacked upward
    local labels = {}
    if hud.slot then labels[#labels + 1] = hud.slot end
    if hud.f    then labels[#labels + 1] = hud.f    end
    if hud.e    then labels[#labels + 1] = hud.e    end

    local ly = 700
    love.graphics.setColor(1, 1, 1, 0.9)
    for _, label in ipairs(labels) do
        love.graphics.print(label, 10, ly)
        ly = ly - 20
    end

    -- Customer dialog: shown when player is in cashier room
    if p.y <= CASHIER_THRESH then
        self:_draw_customer_dialog()
    end

    -- Intercom plant request: shown when player is in store room
    if p.y > CASHIER_THRESH then
        self:_draw_intercom_request(gs)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function StoreScene:_draw_customer_dialog()
    local cust = self._customer
    if not cust:active() or not cust.bubble.visible then return end

    if cust.done_talking and cust.state ~= "talking_after" then
        -- Plant request box at bottom-center
        local bw, bh = 104, 104
        local bx = SW / 2 - bw / 2
        local by = SH - bh - 80
        love.graphics.setColor(0.93, 0.93, 0.93, 1)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        love.graphics.setColor(0.25, 0.25, 0.25, 1)
        love.graphics.rectangle("line", bx, by, bw, bh)
        local img = A["plant_" .. cust.plant_type][3]
        local iw, ih = img:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, bx + 12, by + 12, 0, 80 / iw, 80 / ih)
    else
        -- Dialog text bar (pre-sale dialogue and after-messages)
        -- Walk back from reveal_index to a valid UTF-8 character boundary
        local idx = cust.reveal_index
        while idx > 0 and (string.byte(cust._full_text, idx) or 0) >= 0x80
                      and (string.byte(cust._full_text, idx) or 0) <  0xC0 do
            idx = idx - 1
        end
        if (string.byte(cust._full_text, idx) or 0) >= 0xC0 then
            idx = idx - 1
        end
        local revealed = string.sub(cust._full_text, 1, idx)
        love.graphics.setColor(0.08, 0.08, 0.12, 0.92)
        love.graphics.rectangle("fill", 0, SH - 90, SW, 90)
        love.graphics.setColor(0.88, 0.88, 0.88, 1)
        love.graphics.print(revealed, 20, SH - 68)
    end
end

function StoreScene:_draw_intercom_request(gs)
    -- Find an intercom with a visible request that the player is near
    local p = self.player3d
    local req_img = nil
    for _, slot in ipairs(gs.store:all_slots()) do
        if slot.item and slot.item.is_intercom
           and slot.item.bubble.visible and slot.item.bubble.image then
            local dx = p.x - slot.px
            local dy = p.y - slot.py
            if dx * dx + dy * dy <= 4 then  -- 2 grid units
                req_img = slot.item.bubble.image
                break
            end
        end
    end
    if not req_img then return end

    local bw, bh = 104, 104
    local bx = SW / 2 - bw / 2
    local by = SH - bh - 80
    love.graphics.setColor(0.93, 0.93, 0.93, 1)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    love.graphics.rectangle("line", bx, by, bw, bh)
    local iw, ih = req_img:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(req_img, bx + 12, by + 12, 0, 80 / iw, 80 / ih)
end

function StoreScene:_hud_labels()
    local gs        = self.game_state
    local player    = gs.player
    local p         = self.player3d
    local slot      = self._last_active_slot
    local held      = player.held_item
    local slot_item = slot and slot.item
    local in_cash   = p.y <= CASHIER_THRESH and not self._cust_anim

    local slot_label = not in_cash and slot_item and slot_item.name
                       and ("HOVER: " .. slot_item.name:upper())

    local e_label
    if in_cash and self._customer:arrived() then
        e_label = "E: DISMISS"
    elseif not in_cash then
        if held and slot and not slot_item then
            e_label = "E: PUT DOWN"
        elseif not held and slot_item and slot_item.carriable then
            e_label = "E: PICK UP"
        end
    end

    local f_label
    if in_cash and self._customer and self._customer.state == "talking_after" then
        if not self._customer:line_complete() then
            f_label = "F: SKIP"
        else
            f_label = "F: CONTINUE"
        end
    elseif in_cash and self._customer:arrived() then
        if self._customer:on_last_message() then
            if held and held.plant_type == self._customer.plant_type and held.stage == 3 then
                f_label = "F: SELL TO CUSTOMER ($" .. plant_sell_value(held) .. ")"
            end
        elseif not self._customer:line_complete() then
            f_label = "F: SKIP"
        else
            f_label = "F: NEXT"
        end
    elseif not in_cash then
        if not held and slot_item and slot_item.buy_scene_factory then
            f_label = "F: OPEN SHOP"
        elseif held and held.name == "Watering Can" and slot_item and slot_item.plant_type then
            f_label = "F: WATER"
        elseif held and held.name == "Grafter"
               and slot_item and slot_item.stage == 3 then
            f_label = "F: CLONE"
        elseif held and held.sellable ~= false and slot_item and slot_item.is_garbage_bin then
            f_label = "F: DISCARD"
        end
    end

    return { slot = slot_label, e = e_label, f = f_label }
end

return StoreScene
