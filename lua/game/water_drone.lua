local WaterDrone = {}
WaterDrone.__index = WaterDrone

local FRAME_RATE = 0.1   -- seconds per animation frame

function WaterDrone.new(store, game_state)
    local self        = setmetatable({}, WaterDrone)
    self._store       = store
    self._game_state  = game_state
    self._frame_timer = 0
    self.frame        = 1   -- 1 or 2; store_scene reads this to pick the sprite
    -- Start hovering at the first slot
    local first = store:all_slots()[1]
    self.x = first and first.px or 7.5
    self.y = first and first.py or 4.5
    return self
end

function WaterDrone:update(dt)
    -- Animate between frame 1 and 2
    self._frame_timer = self._frame_timer + dt
    if self._frame_timer >= FRAME_RATE then
        self._frame_timer = self._frame_timer - FRAME_RATE
        self.frame = (self.frame % 2) + 1
    end

    -- Find and water first ready plant; move to that slot
    for _, slot in ipairs(self._store:all_slots()) do
        local item = slot.item
        if item and item.plant_type and item.ready then
            self.x = slot.px
            self.y = slot.py
            item:water(self._store)
            if item.stage == 3 then
                local pt = item.plant_type
                self._game_state.stage3_counts[pt] = (self._game_state.stage3_counts[pt] or 0) + 1
            end
            return
        end
    end
end

return WaterDrone
