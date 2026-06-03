local Store  = require("lua/game/store")
local Player = require("lua/game/player")

local INIT_COLS = 7
local INIT_ROWS = 5

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self    = setmetatable({}, GameState)
    self.store    = Store.new(INIT_COLS, INIT_ROWS)
    self.player   = Player.new(0)
    self.currency        = 1000
    self.speed_level     = 0
    self.growth_level    = 0
    self.cooldown_level  = 0
    self.growth_mult     = 1.0
    self.unlocked_plants = { [1] = true }
    self.stage3_counts   = {}
    self.seen_scripts    = {}
    return self
end

return GameState
