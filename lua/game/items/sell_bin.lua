local Item   = require("lua/game/items/item")
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U

local SellBin = setmetatable({}, { __index = Item })
SellBin.__index = SellBin

function SellBin.new()
    local self        = Item.new()
    setmetatable(self, SellBin)
    self.sprite       = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image = A.sell_bin
    self.sprite.color = {1, 1, 1, 1}
    self.carriable    = true
    self.name         = "Sell Bin"
    self.is_sell_bin  = true
    return self
end

return SellBin
