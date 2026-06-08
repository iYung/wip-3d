local WaterDrone = {}
WaterDrone.__index = WaterDrone

local FRAME_RATE   = 0.1   -- seconds per animation frame
local MOVE_SPEED   = 4.0   -- grid units per second
local ARRIVE_DIST  = 0.15  -- grid units: close enough to water

function WaterDrone.new(store, game_state)
    local self        = setmetatable({}, WaterDrone)
    self._store       = store
    self._game_state  = game_state
    self._frame_timer = 0
    self.frame        = 1
    self._target_slot = nil
    local first = store:all_slots()[1]
    self.x         = first and first.px or 7.5
    self.y         = first and first.py or 4.5
    self._target_x = self.x
    self._target_y = self.y
    return self
end

function WaterDrone:update(dt)
    -- Animate between frame 1 and 2
    self._frame_timer = self._frame_timer + dt
    if self._frame_timer >= FRAME_RATE then
        self._frame_timer = self._frame_timer - FRAME_RATE
        self.frame = (self.frame % 2) + 1
    end

    -- Glide toward target
    local dx   = self._target_x - self.x
    local dy   = self._target_y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0.01 then
        local step = math.min(dist, MOVE_SPEED * dt)
        self.x = self.x + (dx / dist) * step
        self.y = self.y + (dy / dist) * step
    end

    -- If flying to a specific slot, water it on arrival
    if self._target_slot then
        local item = self._target_slot.item
        if not (item and item.plant_type and item.ready) then
            -- Plant was picked up or already watered; forget it
            self._target_slot = nil
        elseif dist <= ARRIVE_DIST then
            item:water(self._store)
            if item.stage == 3 then
                local pt = item.plant_type
                self._game_state.stage3_counts[pt] = (self._game_state.stage3_counts[pt] or 0) + 1
            end
            self._target_slot = nil
        end
        return
    end

    -- Idle: scan for next ready plant and fly to it
    for _, slot in ipairs(self._store:all_slots()) do
        local item = slot.item
        if item and item.plant_type and item.ready then
            self._target_slot = slot
            self._target_x    = slot.px
            self._target_y    = slot.py
            return
        end
    end
end

return WaterDrone
