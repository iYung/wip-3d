local Item = require("lua/game/items/item")
local A    = require("lua/game/assets")

local Intercom = setmetatable({}, { __index = Item })
Intercom.__index = Intercom

function Intercom.new(customer_getter)
    local self            = Item.new()
    setmetatable(self, Intercom)
    self.carriable        = true
    self.name             = "Intercom"
    self._customer_getter = customer_getter
    self.bubble           = { visible = false, image = nil }
    return self
end

function Intercom:set_customer_getter(fn)
    self._customer_getter = fn
end

function Intercom:update(_dt)
    if self._customer_getter == nil then
        self.bubble.visible = false
        return
    end
    local customer = self._customer_getter()
    if customer == nil
       or not customer.bubble.visible
       or not customer.done_talking
       or customer.state == "talking_after" then
        self.bubble.visible = false
        return
    end
    local pt = customer.plant_type
    self.bubble.visible = true
    self.bubble.image   = pt and A["plant_" .. pt] and A["plant_" .. pt][3] or nil
end

return Intercom
