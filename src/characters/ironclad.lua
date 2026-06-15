-- src/characters/ironclad.lua
local Character = require("src/character")
local AS        = require("src/attack_system")
local SL        = require("src/sprite_loader")

local STATS = {
  characterName = "Ironclad",
  maxHealth     = 90,
  moveSpeed     = 100,
  color         = { 0.72, 0.10, 0.10 },
}

local ATTACKS = {
  light   = { damage=12, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=30, hitboxH=22, hitboxOffX=20, startupTime=0.1, activeTime=0.15, recoveryTime=0.2 },
  heavy   = { damage=30, powerGain=15, powerCost=0,  stunDuration=0.5,
              hitboxW=40, hitboxH=28, hitboxOffX=26, startupTime=0.25,activeTime=0.2,  recoveryTime=0.4 },
  special = { damage=20, powerGain=0,  powerCost=25, stunDuration=0.2,
              hitboxW=90, hitboxH=12, hitboxOffX=45, startupTime=0.3, activeTime=0.5,  recoveryTime=0.3 },
  unleash = { damage=45, powerGain=0,  powerCost=100,stunDuration=1.5,
              hitboxW=220,hitboxH=50, hitboxOffX=60, startupTime=0.5, activeTime=1,    recoveryTime=0.6 },
}

local Ironclad = {}
Ironclad.__index = Ironclad

function Ironclad.new()
  local self    = setmetatable({}, Ironclad)
  self.stats    = STATS
  self.character = Character.new(STATS)
  self.attacks  = AS.new(self.character, ATTACKS)
  self._flashTimer = 0
  self.sprites  = SL.load("Ironclad")
  self.sprite   = self.sprites[1]
  self.character.onPowerFull = function() end
  return self
end

function Ironclad:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._flashTimer = 1.0
  self.attacks:performUnleash()
end

function Ironclad:update(dt)
  if self._flashTimer > 0 then self._flashTimer = self._flashTimer - dt end
end

function Ironclad:drawExtra(ctrl)
  if self._flashTimer > 0 then
    local alpha = self._flashTimer / 1.0
    love.graphics.setColor(1, 0.8, 0.2, alpha * 0.6)
    love.graphics.circle("line", ctrl.x, ctrl.y - ctrl.height/2, 40 * (1 - alpha) + 10)
  end
end

return Ironclad
