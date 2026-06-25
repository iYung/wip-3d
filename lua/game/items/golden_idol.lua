local Item = require("lua/game/items/item")
local A    = require("lua/game/assets")

local GoldenIdol = setmetatable({}, { __index = Item })
GoldenIdol.__index = GoldenIdol

function GoldenIdol.new()
    local self             = Item.new()
    setmetatable(self, GoldenIdol)
    self.sprite            = { image = A.golden_idol }
    self.carriable         = true
    self.name              = "Golden Idol"
    self.win_scene_factory = nil
    return self
end

function GoldenIdol:interact(player, store, scene_manager)
    if self.win_scene_factory then
        scene_manager:switch(self.win_scene_factory())
    end
end

return GoldenIdol
