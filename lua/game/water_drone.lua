local WaterDrone = {}
WaterDrone.__index = WaterDrone

function WaterDrone.new(store, game_state)
    local self = setmetatable({}, WaterDrone)
    self._store      = store
    self._game_state = game_state
    return self
end

function WaterDrone:update(_dt)
    for _, slot in ipairs(self._store:all_slots()) do
        local item = slot.item
        if item and item.plant_type and item.ready then
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
