-- src/characters/kong.lua
local Character = require("src/character")
local AS        = require("src/attack_system")

local STATS = {
  characterName = "Kong",
  maxHealth     = 110,
  moveSpeed     = 85,
  color         = { 0.55, 0.38, 0.22 },  -- brown
}

local ATTACKS = {
  light   = { damage=14, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=34, hitboxH=24, hitboxOffX=22, startupTime=0.08,activeTime=0.12, recoveryTime=0.18 },
  heavy   = { damage=28, powerGain=15, powerCost=0,  stunDuration=0.5,
              hitboxW=42, hitboxH=32, hitboxOffX=24, startupTime=0.22,activeTime=0.18, recoveryTime=0.35 },
  special = { damage=22, powerGain=0,  powerCost=25, stunDuration=0.3,
              hitboxW=50, hitboxH=50, hitboxOffX=30, startupTime=0.2, activeTime=0.4,  recoveryTime=0.3 },
  unleash = { damage=42, powerGain=0,  powerCost=100,stunDuration=1,
              hitboxW=180,hitboxH=60, hitboxOffX=55, startupTime=0.4, activeTime=0.8,  recoveryTime=0.5 },
}

local Kong = {}
Kong.__index = Kong

function Kong.new()
  local self    = setmetatable({}, Kong)
  self.stats    = STATS
  self.character = Character.new(STATS)
  self.attacks  = AS.new(self.character, ATTACKS)
  self._rageTimer = 0
  return self
end

function Kong:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._rageTimer = 0.8
  self.attacks:performUnleash()
end

function Kong:update(dt)
  self.attacks:update(dt, 0, true)
  if self._rageTimer > 0 then self._rageTimer = self._rageTimer - dt end
end

function Kong:drawExtra(ctrl)
  if self._rageTimer > 0 then
    local alpha = self._rageTimer / 0.8
    love.graphics.setColor(1, 0.4, 0, alpha * 0.5)
    love.graphics.rectangle("fill", ctrl.x - 30, ctrl.y - ctrl.height - 10, 60, 10)
  end
end

return Kong
