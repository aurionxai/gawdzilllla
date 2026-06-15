-- src/npc_spawner.lua
-- Phase-based wave spawner with military escalation
local NPC     = require("src/npc")
local Spawner = {}
Spawner.__index = Spawner

-- Phase thresholds
local PHASES = {
  { name="PANIC",       minTime=0,   destroyPct=0,    color={1,0.7,0.1} },
  { name="POLICE",      minTime=25,  destroyPct=0.15, color={0.3,0.5,1} },
  { name="MILITARY",    minTime=55,  destroyPct=0.35, color={0.5,0.8,0.3} },
  { name="TOTAL WAR",   minTime=90,  destroyPct=0.60, color={1,0.2,0.2} },
}

local STREAK_WINDOW    = 2.0
local STREAK_THRESHOLD = 5

-- Projectiles: {x,y,vx,damage,type}
local function newProjectile(x, y, dir, ptype)
  local spd = ptype == "tank" and 220 or 140
  local dmg = ptype == "tank" and 10  or 2
  return { x=x, y=y, vx=dir*spd, damage=dmg, type=ptype,
           w=6, h=3, _alive=true }
end

function Spawner.new()
  return setmetatable({
    npcs               = {},
    projectiles        = {},
    _totalDollars      = 0,
    _splatCount        = 0,
    _recentSplatCount  = 0,
    _recentSplatTimer  = 0,
    _phaseIdx          = 1,
    _phaseTimer        = 0,
    _phaseAnnounce     = nil,
    _phaseAnnounceTimer= 0,
    _waveTimer         = 0,
    _destroyPct        = 0,
    onDestructionScoreChanged = nil,
    onSplatStreak             = nil,
  }, Spawner)
end

function Spawner:spawnBatch(count, areaWidth, groundY)
  for i = 1, count do
    local x = math.random(20, areaWidth - 20)
    table.insert(self.npcs, NPC.new(x, groundY, "civilian", 1000))
  end
end

function Spawner:setDestroyPct(pct)
  self._destroyPct = pct
end

-- ── Update ────────────────────────────────────────────────────────────────────

function Spawner:update(dt, targets, groundY)
  local gy = groundY or 220

  self._phaseTimer = self._phaseTimer + dt
  if self._phaseAnnounceTimer > 0 then
    self._phaseAnnounceTimer = self._phaseAnnounceTimer - dt
  end

  -- Phase escalation
  self:_checkPhase(gy)

  -- Wave spawning timer
  self._waveTimer = self._waveTimer - dt
  if self._waveTimer <= 0 then
    self._waveTimer = 12 + math.random() * 8
    self:_spawnWave(gy)
  end

  -- Streak timer
  self._recentSplatTimer = self._recentSplatTimer - dt
  if self._recentSplatTimer <= 0 then
    self._recentSplatCount = 0
  end

  -- NPC updates
  for _, npc in ipairs(self.npcs) do
    local result, dir = npc:update(dt, targets)
    if result == "police_shot" or result == "tank_shot" then
      local projY = npc.y - npc.height / 2
      table.insert(self.projectiles, newProjectile(npc.x, projY, dir, npc.npcType))
    end
  end

  -- Projectile updates
  for _, p in ipairs(self.projectiles) do
    p.x = p.x + p.vx * dt
    if p.x < -10 or p.x > 490 then p._alive = false end
  end

  -- Clean dead
  for i = #self.npcs, 1, -1 do
    if self.npcs[i].isDead then table.remove(self.npcs, i) end
  end
  for i = #self.projectiles, 1, -1 do
    if not self.projectiles[i]._alive then table.remove(self.projectiles, i) end
  end
end

function Spawner:_checkPhase(gy)
  local t   = self._phaseTimer
  local pct = self._destroyPct
  local nextIdx = self._phaseIdx + 1
  if nextIdx > #PHASES then return end
  local next = PHASES[nextIdx]
  if t >= next.minTime or pct >= next.destroyPct then
    self._phaseIdx = nextIdx
    self._phaseAnnounce     = "⚠ " .. next.name .. "!"
    self._phaseAnnounceTimer = 3.0
    self:_spawnPhaseWave(nextIdx, gy)
  end
end

function Spawner:_spawnPhaseWave(phaseIdx, gy)
  if phaseIdx == 2 then
    -- Police cordon: spawn 8 police from both sides
    for i = 1, 4 do
      table.insert(self.npcs, NPC.new(math.random(5, 60),  gy, "police", 2000))
      table.insert(self.npcs, NPC.new(math.random(420,475), gy, "police", 2000))
    end
  elseif phaseIdx == 3 then
    -- Military: 2 tanks from each side
    table.insert(self.npcs, NPC.new(10,  gy, "tank", 15000))
    table.insert(self.npcs, NPC.new(470, gy, "tank", 15000))
  elseif phaseIdx == 4 then
    -- Total war: more tanks + police
    table.insert(self.npcs, NPC.new(10,  gy, "tank", 15000))
    table.insert(self.npcs, NPC.new(470, gy, "tank", 15000))
    for i = 1, 3 do
      table.insert(self.npcs, NPC.new(math.random(5, 60),  gy, "police", 2000))
      table.insert(self.npcs, NPC.new(math.random(420,475), gy, "police", 2000))
    end
  end
end

function Spawner:_spawnWave(gy)
  -- Periodic civilian reinforcements
  local count = math.random(4, 8)
  for i = 1, count do
    local x = math.random() > 0.5 and math.random(5, 30) or math.random(450, 475)
    table.insert(self.npcs, NPC.new(x, gy, "civilian", 1000))
  end
end

-- ── Hit detection for projectiles ────────────────────────────────────────────

function Spawner:checkProjectileHits(ctrlList)
  for _, p in ipairs(self.projectiles) do
    if p._alive then
      for _, ctrl in ipairs(ctrlList) do
        local cb = ctrl:getBounds()
        if p.x < cb.x + cb.w and p.x + p.w > cb.x and
           p.y < cb.y + cb.h and p.y + p.h > cb.y then
          p._alive = false
          ctrl.character:takeDamage(p.damage)
          break
        end
      end
    end
  end
end

-- ── Scoring ───────────────────────────────────────────────────────────────────

function Spawner:registerSplat(npcType, dollars)
  self._totalDollars    = self._totalDollars + dollars
  self._splatCount      = self._splatCount + 1
  self._recentSplatCount = self._recentSplatCount + 1
  self._recentSplatTimer = STREAK_WINDOW
  if self.onDestructionScoreChanged then
    self.onDestructionScoreChanged(self._totalDollars)
  end
  if self._recentSplatCount >= STREAK_THRESHOLD then
    self._recentSplatCount = 0
    if self.onSplatStreak then self.onSplatStreak() end
  end
end

function Spawner:getDestructionScore() return self._totalDollars end
function Spawner:getSplatCount()       return self._splatCount end
function Spawner:getPhase()            return PHASES[self._phaseIdx] end
function Spawner:getPhaseAnnounce()    return self._phaseAnnounceTimer > 0 and self._phaseAnnounce or nil end

-- ── Draw ──────────────────────────────────────────────────────────────────────

function Spawner:draw()
  for _, npc in ipairs(self.npcs) do npc:draw() end
  self:_drawProjectiles()
end

function Spawner:_drawProjectiles()
  for _, p in ipairs(self.projectiles) do
    if p._alive then
      if p.type == "tank" then
        love.graphics.setColor(1, 0.5, 0.1)
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
        love.graphics.setColor(1, 0.8, 0.2, 0.5)
        love.graphics.rectangle("fill", p.x - 4, p.y, 4, p.h)
      else
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle("fill", p.x, p.y, 4, 2)
      end
    end
  end
end

return Spawner
