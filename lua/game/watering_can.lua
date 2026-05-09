local Item   = require("lua/game/item")
local Sprite = require("lua/core/sprite")

local WateringCan = setmetatable({}, { __index = Item })
WateringCan.__index = WateringCan

function WateringCan.new()
    local self        = Item.new()
    setmetatable(self, WateringCan)
    self.sprite       = Sprite.new(0, 0, 40, 30)
    self.sprite.color = {0.3, 0.6, 1.0, 1}
    self.carriable    = true
    return self
end

function WateringCan:interact(player, store, scene_manager)
    local slot = player:active_slot(store)
    if slot and slot.item and slot.item.water then
        slot.item:water()
    end
end

return WateringCan
