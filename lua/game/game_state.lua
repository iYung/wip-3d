local Store  = require("lua/game/store")
local Player = require("lua/game/player")

local SLOT_WIDTH    = 200
local INITIAL_SLOTS = 8

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self    = setmetatable({}, GameState)
    self.store    = Store.new(INITIAL_SLOTS, SLOT_WIDTH)
    self.player   = Player.new(SLOT_WIDTH / 2)
    self.currency = 0
    return self
end

return GameState
