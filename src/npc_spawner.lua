-- src/npc_spawner.lua
local NPC    = require("src/npc")
local Spawner = {}
Spawner.__index = Spawner

local STREAK_WINDOW    = 2.0   -- seconds
local STREAK_THRESHOLD = 5     -- splats within window to trigger streak

function Spawner.new()
  return setmetatable({
    npcs               = {},
    _totalDollars      = 0,
    _splatCount        = 0,
    _recentSplatCount  = 0,
    _recentSplatTimer  = 0,
    onDestructionScoreChanged = nil,
    onSplatStreak             = nil,
  }, Spawner)
end

function Spawner:spawnBatch(count, areaWidth, groundY)
  for i = 1, count do
    local x = math.random(20, areaWidth - 20)
    table.insert(self.npcs, NPC.new(x, groundY, "Human", 1000))
  end
end

function Spawner:update(dt)
  self._recentSplatTimer = self._recentSplatTimer - dt
  if self._recentSplatTimer <= 0 then
    self._recentSplatCount = 0
  end
  for _, npc in ipairs(self.npcs) do
    npc:update(dt)
  end
end

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

function Spawner:draw()
  for _, npc in ipairs(self.npcs) do npc:draw() end
end

return Spawner
