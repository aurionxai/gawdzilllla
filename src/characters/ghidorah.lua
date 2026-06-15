-- src/characters/ghidorah.lua
local Character = require("src/character")
local AS        = require("src/attack_system")
local SL        = require("src/sprite_loader")

local STATS = {
  characterName = "Ghidorah",
  maxHealth     = 130,
  moveSpeed     = 60,
  color         = { 0.85, 0.75, 0.1 },  -- gold
}

local ATTACKS = {
  light   = { damage=10, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=28, hitboxH=18, hitboxOffX=18, startupTime=0.12,activeTime=0.18, recoveryTime=0.22 },
  heavy   = { damage=32, powerGain=15, powerCost=0,  stunDuration=0.6,
              hitboxW=44, hitboxH=30, hitboxOffX=28, startupTime=0.28,activeTime=0.22, recoveryTime=0.45 },
  special = { damage=18, powerGain=0,  powerCost=25, stunDuration=0.2,
              hitboxW=100,hitboxH=10, hitboxOffX=50, startupTime=0.35,activeTime=0.6,  recoveryTime=0.35 },
  unleash = { damage=50, powerGain=0,  powerCost=100,stunDuration=2,
              hitboxW=250,hitboxH=45, hitboxOffX=70, startupTime=0.6, activeTime=1.2,  recoveryTime=0.7 },
}

local Ghidorah = {}
Ghidorah.__index = Ghidorah

function Ghidorah.new()
  local self     = setmetatable({}, Ghidorah)
  self.stats     = STATS
  self.character = Character.new(STATS)
  self.attacks   = AS.new(self.character, ATTACKS)
  self._beamTimer = 0
  self.sprites   = SL.load("Ghidorah")
  self.sprite    = self.sprites[1]
  return self
end

function Ghidorah:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._beamTimer = 1.2
  self.attacks:performUnleash()
end

function Ghidorah:update(dt)
  if self._beamTimer > 0 then self._beamTimer = self._beamTimer - dt end
end

function Ghidorah:drawExtra(ctrl)
  if self._beamTimer > 0 then
    local alpha = self._beamTimer / 1.2
    -- Three lightning beams
    love.graphics.setColor(0.9, 0.9, 0.2, alpha * 0.8)
    local bx = ctrl.facingRight and ctrl.x or ctrl.x - 200
    for i = 0, 2 do
      love.graphics.rectangle("fill", bx + i * 5, ctrl.y - ctrl.height - 2, 2, 200)
    end
  end
end

return Ghidorah
