-- src/npc.lua
-- Multi-type NPCs with state-machine AI
local NPC   = {}
NPC.__index = NPC

-- NPC types and their base behavior
-- "civilian"  → wanders, flees kaiju
-- "police"    → marches toward nearest kaiju, fires pea-shot
-- "tank"      → slow vehicle, drives toward kaiju, fires shell (10 dmg)
-- "monster"   → small mutant creature, aggressively chases and bites kaiju

local FLEE_RADIUS   = 100   -- pixels: civilians start fleeing within this range
local POLICE_RANGE  = 200   -- range at which police start moving to kaiju
local TANK_RANGE    = 300   -- tanks always advance
local SHOT_COOLDOWN = 2.0   -- seconds between police shots
local TANK_COOLDOWN = 3.5

local SHIRT_COLORS = {
  {0.9,0.2,0.2}, {0.2,0.5,0.9}, {0.2,0.8,0.3},
  {0.9,0.8,0.1}, {0.8,0.3,0.8}, {0.95,0.5,0.1},
}

function NPC.new(x, y, npcType, dollarsValue)
  local t = npcType or "civilian"
  return setmetatable({
    x            = x,
    y            = y,
    npcType      = t,
    dollarsValue = dollarsValue or 1000,
    isDead       = false,
    vx           = (math.random() > 0.5) and 25 or -25,
    wanderTimer  = math.random() * 2 + 1,
    shotCooldown = math.random() * SHOT_COOLDOWN,  -- stagger initial shots
    _state       = "wander",
    _fleeDir     = 1,
    -- HP by type
    health       = (t == "tank") and 3 or (t == "monster") and 2 or 1,
    -- projectiles this NPC fired (handled by spawner)
    width        = (t == "tank") and 18 or (t == "monster") and 10 or 8,
    height       = (t == "tank") and 10 or (t == "monster") and 14 or 12,
    -- visual flash on hit
    _hitFlash    = 0,
  }, NPC)
end

-- Returns nearest target distance and direction, or nil
local function nearestTarget(self, targets)
  local bestDist, bestDir = math.huge, 1
  if not targets then return bestDist, bestDir end
  for _, t in ipairs(targets) do
    local dx = t.x - self.x
    local dist = math.abs(dx)
    if dist < bestDist then
      bestDist = dist
      bestDir  = dx > 0 and 1 or -1
    end
  end
  return bestDist, bestDir
end

function NPC:update(dt, targets)
  if self.isDead then return end

  self._hitFlash = math.max(0, self._hitFlash - dt)

  local dist, dir = nearestTarget(self, targets)

  if self.npcType == "civilian" then
    -- State: flee if kaiju is close, else wander
    if dist < FLEE_RADIUS then
      self._state  = "flee"
      self._fleeDir = -dir  -- run away
    else
      if self._state == "flee" and dist > FLEE_RADIUS + 20 then
        self._state = "wander"
      end
    end

    if self._state == "flee" then
      self.vx = self._fleeDir * 65
    else
      -- Normal wander
      self.wanderTimer = self.wanderTimer - dt
      if self.wanderTimer <= 0 then
        self.vx = -self.vx
        self.wanderTimer = math.random() * 2 + 1
      end
    end
    self.x = math.max(4, math.min(99999,self.x + self.vx * dt))

  elseif self.npcType == "police" then
    -- March toward kaiju and fire
    if dist < POLICE_RANGE then
      -- Keep a safe distance (don't walk into the kaiju)
      if dist > 40 then
        self.vx = dir * 35
      else
        self.vx = 0
      end
    else
      self.vx = dir * 20  -- slowly advance anyway
    end
    self.x = math.max(4, math.min(99999,self.x + self.vx * dt))

    -- Shot cooldown
    self.shotCooldown = self.shotCooldown - dt
    if self.shotCooldown <= 0 and dist < POLICE_RANGE then
      self.shotCooldown = SHOT_COOLDOWN + math.random() * 0.5
      return "police_shot", dir  -- signal spawner to create a projectile
    end

  elseif self.npcType == "tank" then
    -- Drive toward kaiju
    if dist > 50 then
      self.vx = dir * 28
    else
      self.vx = 0
    end
    self.x = math.max(4, math.min(99999,self.x + self.vx * dt))

    self.shotCooldown = self.shotCooldown - dt
    if self.shotCooldown <= 0 and dist < TANK_RANGE then
      self.shotCooldown = TANK_COOLDOWN + math.random()
      return "tank_shot", dir
    end

  elseif self.npcType == "monster" then
    -- Aggressive small creature: always charges at kaiju
    if dist > 20 then
      self.vx = dir * (dist < 150 and 90 or 55)
    else
      self.vx = 0
    end
    self.x = math.max(4, math.min(99999, self.x + self.vx * dt))

    -- Bite when adjacent
    self.shotCooldown = self.shotCooldown - dt
    if self.shotCooldown <= 0 and dist < 35 then
      self.shotCooldown = 1.2 + math.random() * 0.6
      return "monster_bite", dir
    end
  end
end

function NPC:takeDamage(amount)
  if self.isDead then return end
  self._hitFlash = 0.15
  self.health = self.health - (amount or 1)
  if self.health <= 0 then
    self.isDead = true
  end
end

function NPC:stomp(bloodPool, spawner)
  if self.isDead then return end
  self:takeDamage(self.health)  -- instant kill on stomp
  if bloodPool then bloodPool:spawn(self.x, self.y) end
  if spawner   then spawner:registerSplat(self.npcType, self.dollarsValue) end
end

function NPC:getBounds()
  return { x=self.x - self.width/2, y=self.y - self.height, w=self.width, h=self.height }
end

-- ── Drawing ────────────────────────────────────────────────────────────────────

function NPC:draw()
  if self.isDead then return end

  local flash = self._hitFlash > 0

  if self.npcType == "tank" then
    self:_drawTank(flash)
  elseif self.npcType == "police" then
    self:_drawPerson(flash, {0.25,0.35,0.75}, {0.2,0.28,0.65})
  elseif self.npcType == "monster" then
    self:_drawMonster(flash)
  else
    self:_drawCivilian(flash)
  end
end

function NPC:_drawCivilian(flash)
  local x  = math.floor(self.x - self.width / 2)
  local by = math.floor(self.y - self.height)
  local sc = flash and {1,1,1} or
             SHIRT_COLORS[((math.floor(self.x * 7 + self.y * 3)) % #SHIRT_COLORS) + 1]

  -- Legs
  love.graphics.setColor(0.25, 0.25, 0.55)
  love.graphics.rectangle("fill", x,   by + 7, 3, 5)
  love.graphics.rectangle("fill", x+5, by + 7, 3, 5)

  -- Body
  love.graphics.setColor(sc)
  love.graphics.rectangle("fill", x, by + 3, 8, 5)

  -- Arms (wave when fleeing)
  love.graphics.setColor(1, 0.78, 0.58)
  local armY = (self._state == "flee") and (by + 2) or
               (self.vx > 0 and (by + 3) or (by + 5))
  love.graphics.rectangle("fill", x - 2, armY,     2, 3)
  love.graphics.rectangle("fill", x + 8, armY + 1, 2, 3)

  -- Head
  love.graphics.setColor(flash and {1,1,1} or {1, 0.78, 0.58})
  love.graphics.rectangle("fill", x + 1, by, 6, 5)

  -- Eyes — wider when fleeing
  love.graphics.setColor(0, 0, 0)
  if self._state == "flee" then
    love.graphics.rectangle("fill", x + 2, by + 1, 1, 3)
    love.graphics.rectangle("fill", x + 5, by + 1, 1, 3)
  else
    love.graphics.rectangle("fill", x + 2, by + 1, 1, 2)
    love.graphics.rectangle("fill", x + 5, by + 1, 1, 2)
  end
  -- Mouth
  love.graphics.rectangle("fill", x + 3, by + 3, 2, 1)
end

function NPC:_drawPerson(flash, shirtCol, pantCol)
  local x  = math.floor(self.x - self.width / 2)
  local by = math.floor(self.y - self.height)

  love.graphics.setColor(flash and {1,1,1} or pantCol)
  love.graphics.rectangle("fill", x, by + 7, 3, 5)
  love.graphics.rectangle("fill", x+5, by + 7, 3, 5)

  love.graphics.setColor(flash and {1,1,1} or shirtCol)
  love.graphics.rectangle("fill", x, by + 3, 8, 5)

  -- Cap
  love.graphics.setColor(flash and {1,1,1} or {0.2,0.25,0.65})
  love.graphics.rectangle("fill", x, by, 8, 3)

  love.graphics.setColor(flash and {1,1,1} or {1, 0.78, 0.58})
  love.graphics.rectangle("fill", x + 1, by + 2, 6, 4)

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", x + 2, by + 3, 1, 1)
  love.graphics.rectangle("fill", x + 5, by + 3, 1, 1)

  -- Gun (little rectangle pointing toward kaiju direction)
  love.graphics.setColor(0.3,0.3,0.3)
  local gunDir = self.vx >= 0 and 1 or -1
  love.graphics.rectangle("fill", gunDir > 0 and (x+8) or (x-4), by+4, 4, 2)
end

function NPC:_drawTank(flash)
  local x  = math.floor(self.x - self.width / 2)
  local by = math.floor(self.y - self.height)

  -- Body
  love.graphics.setColor(flash and {1,1,1} or {0.45,0.50,0.30})
  love.graphics.rectangle("fill", x, by + 4, self.width, 6)

  -- Turret
  love.graphics.setColor(flash and {1,1,1} or {0.38,0.42,0.24})
  love.graphics.rectangle("fill", x + 4, by + 1, 10, 5)

  -- Barrel
  local barDir = self.vx >= 0 and 1 or -1
  love.graphics.setColor(flash and {1,1,1} or {0.28,0.30,0.18})
  if barDir > 0 then
    love.graphics.rectangle("fill", x + 14, by + 2, 6, 2)
  else
    love.graphics.rectangle("fill", x - 2, by + 2, 6, 2)
  end

  -- Tracks
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", x, by + 8, self.width, 3)
  -- Track segments
  love.graphics.setColor(0.3, 0.3, 0.3)
  for i = 0, 3 do
    love.graphics.rectangle("fill", x + i*5, by + 8, 3, 3)
  end

  -- HP pips
  if self.health > 1 then
    love.graphics.setColor(0.2, 0.8, 0.2)
    for i = 1, self.health do
      love.graphics.rectangle("fill", x + (i-1)*4, by - 3, 3, 2)
    end
  end
end

function NPC:_drawMonster(flash)
  local x  = math.floor(self.x - self.width / 2)
  local by = math.floor(self.y - self.height)
  local facingR = self.vx >= 0

  -- Body
  love.graphics.setColor(flash and {1,1,1} or {0.12, 0.42, 0.16})
  love.graphics.rectangle("fill", x+1, by+5, 8, 6)

  -- Head
  love.graphics.setColor(flash and {1,1,1} or {0.18, 0.52, 0.20})
  if facingR then
    love.graphics.rectangle("fill", x+5, by+1, 5, 6)
    love.graphics.setColor(flash and {1,1,1} or {0.22, 0.58, 0.25})
    love.graphics.rectangle("fill", x+8, by+5, 4, 2)   -- jaw
  else
    love.graphics.rectangle("fill", x, by+1, 5, 6)
    love.graphics.setColor(flash and {1,1,1} or {0.22, 0.58, 0.25})
    love.graphics.rectangle("fill", x-2, by+5, 4, 2)   -- jaw
  end

  -- Glowing red eye
  love.graphics.setColor(0.95, 0.12, 0.05)
  if facingR then
    love.graphics.rectangle("fill", x+8, by+2, 2, 2)
  else
    love.graphics.rectangle("fill", x, by+2, 2, 2)
  end

  -- Tail
  love.graphics.setColor(flash and {1,1,1} or {0.10, 0.35, 0.14})
  if facingR then
    love.graphics.rectangle("fill", x-3, by+6, 5, 3)
    love.graphics.rectangle("fill", x-5, by+7, 3, 2)
  else
    love.graphics.rectangle("fill", x+8, by+6, 5, 3)
    love.graphics.rectangle("fill", x+11, by+7, 3, 2)
  end

  -- Legs (two stubs)
  love.graphics.setColor(flash and {1,1,1} or {0.10, 0.38, 0.14})
  love.graphics.rectangle("fill", x+2, by+10, 2, 4)
  love.graphics.rectangle("fill", x+6, by+10, 2, 4)

  -- HP pip (show second health pip if alive with full HP)
  if self.health > 1 then
    love.graphics.setColor(0.2, 0.9, 0.2)
    love.graphics.rectangle("fill", x, by-3, 4, 2)
    love.graphics.rectangle("fill", x+5, by-3, 4, 2)
  end
end

return NPC
