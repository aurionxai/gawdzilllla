-- src/character.lua
local Character = {}
Character.__index = Character

function Character.new(stats)
  return setmetatable({
    stats          = stats,
    health         = stats.maxHealth,
    power          = 0,
    isDefeated     = false,
    isInvincible   = false,
    isCounterState = false,
    onHealthChanged = nil,
    onPowerChanged  = nil,
    onDefeated      = nil,
    onPowerFull     = nil,
  }, Character)
end

function Character:takeDamage(amount)
  if self.isInvincible or self.isDefeated then return end
  local mult = self.isCounterState and 2 or 1
  self.isCounterState = false
  self.health = math.max(0, self.health - amount * mult)
  if self.onHealthChanged then self.onHealthChanged(self.health) end
  if self.health <= 0 and not self.isDefeated then
    self.isDefeated = true
    if self.onDefeated then self.onDefeated() end
  end
end

function Character:gainPower(amount)
  if self.isDefeated then return end
  local wasFull = self:isPowerFull()
  self.power = math.min(100, self.power + amount)
  if self.onPowerChanged then self.onPowerChanged(self.power) end
  if not wasFull and self:isPowerFull() then
    if self.onPowerFull then self.onPowerFull() end
  end
end

function Character:spendPower(amount)
  self.power = math.max(0, self.power - amount)
  if self.onPowerChanged then self.onPowerChanged(self.power) end
end

function Character:resetForNewRound()
  self.health        = self.stats.maxHealth
  self.power         = 0
  self.isDefeated    = false
  self.isInvincible  = false
  self.isCounterState = false
  if self.onHealthChanged then self.onHealthChanged(self.health) end
  if self.onPowerChanged  then self.onPowerChanged(self.power) end
end

function Character:healthPercent() return self.health / self.stats.maxHealth end
function Character:powerPercent()  return self.power / 100 end
function Character:isPowerFull()   return self.power >= 100 end

return Character
