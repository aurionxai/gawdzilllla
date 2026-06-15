-- src/fps/player_state.lua
-- Tracks the FPS player's kaiju HP, stats, move cooldowns, XP, and level.

local PlayerState = {}
PlayerState.__index = PlayerState

local UNLOCK_LEVELS = {
  ranged  = 1,
  claw    = 1,
  bite    = 5,
  tail    = 7,
  special = 9,
}

local COOLDOWN_MAX = {
  ranged  = 2.0,
  claw    = 0.5,
  bite    = 1.5,
  tail    = 2.5,
  special = 8.0,
}

function PlayerState.new(kaijuName)
  return setmetatable({
    kaijuName = kaijuName,
    level     = 1,
    xp        = 0,
    xpToNext  = 100,
    statPoints = 0,
    stats = { str=8, def=6, spd=6, rage=6, instinct=4 },
    maxHp = 100,
    hp    = 100,
    cooldowns    = { ranged=0, claw=0, bite=0, tail=0, special=0 },
    cooldownMax  = {
      ranged  = COOLDOWN_MAX.ranged,
      claw    = COOLDOWN_MAX.claw,
      bite    = COOLDOWN_MAX.bite,
      tail    = COOLDOWN_MAX.tail,
      special = COOLDOWN_MAX.special,
    },
  }, PlayerState)
end

function PlayerState:isUnlocked(moveName)
  return self.level >= (UNLOCK_LEVELS[moveName] or 99)
end

function PlayerState:canUse(moveName)
  return self:isUnlocked(moveName) and self.cooldowns[moveName] <= 0
end

function PlayerState:useMove(moveName)
  assert(COOLDOWN_MAX[moveName], "useMove: unknown move '" .. tostring(moveName) .. "'")
  self.cooldowns[moveName] = self.cooldownMax[moveName]
end

function PlayerState:update(dt)
  for k in pairs(self.cooldowns) do
    if self.cooldowns[k] > 0 then
      self.cooldowns[k] = math.max(0, self.cooldowns[k] - dt)
    end
  end
end

-- Defense stat reduces incoming damage. Minimum 1 damage always applies.
function PlayerState:takeDamage(amount)
  local reduced = math.max(1, amount - math.floor(self.stats.def / 3))
  self.hp = math.max(0, self.hp - reduced)
  return reduced
end

function PlayerState:gainXp(amount)
  self.xp = self.xp + amount
  while self.xp >= self.xpToNext do
    self.xp        = self.xp - self.xpToNext
    self.level     = self.level + 1
    self.xpToNext  = math.floor(self.xpToNext * 1.4)
    self.statPoints = self.statPoints + 2
    self.maxHp     = 100 + (self.level - 1) * 10
    self.hp        = math.min(self.hp + 20, self.maxHp)
  end
end

function PlayerState:getRangedDamage()
  return 15 + math.floor(self.stats.rage * 1.5)
end

function PlayerState:getMeleeDamage(moveType)
  local base = { claw=10, bite=25, tail=18 }
  return (base[moveType] or 10) + math.floor(self.stats.str * 1.2)
end

return PlayerState
