local Scene       = require("lua/core/scene")
local Plant       = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local Grafter     = require("lua/game/items/grafter")
local config      = require("lua/game/config")

local PLANT_COST = config.PLANT_COST
local SLOT_COST  = config.SLOT_COST

local OPTIONS = {
    { label = "Plant",    cost = PLANT_COST },
    { label = "Expand",   cost = SLOT_COST  },
    { label = "W.Can",    cost = 0          },
    { label = "Grafter",  cost = 0          },
}

local BuyScene = setmetatable({}, { __index = Scene })
BuyScene.__index = BuyScene

function BuyScene.new(game_state, input, scene_manager, store_scene, target_slot)
    local self           = Scene.new()
    setmetatable(self, BuyScene)
    self.game_state      = game_state
    self.input           = input
    self.scene_manager   = scene_manager
    self.store_scene     = store_scene
    self.target_slot     = target_slot
    self.selected        = 1
    return self
end

function BuyScene:on_enter() end

function BuyScene:on_exit() end

function BuyScene:update(dt)
    local input = self.input

    if input:pressed("move_left") then
        self.selected = math.max(1, self.selected - 1)
    elseif input:pressed("move_right") then
        self.selected = math.min(#OPTIONS, self.selected + 1)
    end

    if input:pressed("interact") then
        self:_confirm()
    elseif input:pressed("pick_up_down") then
        self.scene_manager:switch(self.store_scene)
    end
end

function BuyScene:_confirm()
    local gs   = self.game_state
    local opt  = OPTIONS[self.selected]

    if gs.currency < opt.cost then return end

    gs.currency = gs.currency - opt.cost

    local sel = self.selected
    if sel == 1 then
        gs.player.held_item = Plant.new(1)
    elseif sel == 2 then
        gs.store:grow()
    elseif sel == 3 then
        gs.player.held_item = WateringCan.new()
    elseif sel == 4 then
        gs.player.held_item = Grafter.new()
    end

    self.scene_manager:switch(self.store_scene)
end

function BuyScene:draw()
    local gs       = self.game_state
    local currency = gs.currency

    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.print("-- Shop --", 560, 200, 0, 2, 2)
    love.graphics.print("Currency: " .. currency, 530, 260, 0, 1.3, 1.3)

    local spacing = 240
    local start_x = 1280 / 2 - (#OPTIONS - 1) * spacing / 2

    for i, opt in ipairs(OPTIONS) do
        local can_afford = currency >= opt.cost
        if self.selected == i then
            love.graphics.setColor(1, 1, 0, 1)
        elseif can_afford then
            love.graphics.setColor(0.95, 0.95, 0.95, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        end
        local x = start_x + (i - 1) * spacing - 50
        love.graphics.print(opt.label, x, 340, 0, 1.4, 1.4)
        love.graphics.print("$" .. opt.cost, x + 10, 380, 0, 1.2, 1.2)
    end

    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("A/D select   F buy   E cancel", 460, 460, 0, 1.2, 1.2)

    love.graphics.setColor(1, 1, 1, 1)
end

return BuyScene
