-- src/hud.lua
local HUD   = {}
HUD.__index = HUD

local BAR_H    = 8
local BAR_W    = 150
local P1_BAR_X = 10
local P2_BAR_X = 480 - 10 - BAR_W
local BARS_Y   = 10
local PWR_Y    = BARS_Y + BAR_H + 3
local PIP_Y    = PWR_Y + (BAR_H - 2) + 4   -- row of round-win pips
local PIP_SIZE = 5
local PIP_GAP  = 8

function HUD.new(p1char, p2char, spawner, fm)
  local self = setmetatable({
    p1           = p1char,
    p2           = p2char,
    spawner      = spawner,
    fm           = fm,
    timerSeconds = 99,
    _comboText   = nil,
    _comboTimer  = 0,
    _destroyPct  = 0,
    _totalBuildings    = 0,
    _destroyedBuildings= 0,
  }, HUD)

  if spawner then
    spawner.onSplatStreak = function()
      self._comboText  = "SQUISH x5 — GAWDZILLLLA APPROVES"
      self._comboTimer = 2.5
    end
  end

  return self
end

function HUD:update(dt, timeRemaining, destroyedBuildings, totalBuildings)
  self.timerSeconds         = timeRemaining
  self._destroyedBuildings  = destroyedBuildings or 0
  self._totalBuildings      = totalBuildings or 1
  self._destroyPct          = self._destroyedBuildings / math.max(1, self._totalBuildings)
  if self._comboTimer > 0 then
    self._comboTimer = self._comboTimer - dt
  end
end

function HUD:draw()
  -- P1 Health
  self:_drawBar(P1_BAR_X, BARS_Y, BAR_W, BAR_H, self.p1:healthPercent(),
    {0.15,0.75,0.2}, {0.15,0.10,0.10})
  -- P1 Power
  self:_drawBar(P1_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p1:powerPercent(),
    {0.2,0.5,1}, {0.08,0.08,0.25})

  -- P2 Health (RTL)
  self:_drawBarRTL(P2_BAR_X, BARS_Y, BAR_W, BAR_H, self.p2:healthPercent(),
    {0.85,0.20,0.15}, {0.15,0.10,0.10})
  -- P2 Power
  self:_drawBarRTL(P2_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p2:powerPercent(),
    {0.2,0.5,1}, {0.08,0.08,0.25})

  -- Round win pips
  if self.fm then
    local total  = self.fm.totalRounds
    local p1wins = self.fm.p1RoundsWon
    local p2wins = self.fm.p2RoundsWon
    for i = 1, total do
      local px = P1_BAR_X + (i - 1) * PIP_GAP
      if i <= p1wins then
        love.graphics.setColor(0.2, 0.8, 1)
      else
        love.graphics.setColor(0.2, 0.2, 0.35)
      end
      love.graphics.rectangle("fill", px, PIP_Y, PIP_SIZE, PIP_SIZE, 1)
      love.graphics.setColor(0.5, 0.5, 0.7, 0.5)
      love.graphics.rectangle("line", px, PIP_Y, PIP_SIZE, PIP_SIZE, 1)
    end
    for i = 1, total do
      local px = P2_BAR_X + BAR_W - (i - 1) * PIP_GAP - PIP_SIZE
      if i <= p2wins then
        love.graphics.setColor(1, 0.3, 0.3)
      else
        love.graphics.setColor(0.35, 0.15, 0.15)
      end
      love.graphics.rectangle("fill", px, PIP_Y, PIP_SIZE, PIP_SIZE, 1)
      love.graphics.setColor(0.5, 0.5, 0.7, 0.5)
      love.graphics.rectangle("line", px, PIP_Y, PIP_SIZE, PIP_SIZE, 1)
    end
  end

  -- Character names
  love.graphics.setColor(0.9, 0.9, 1)
  love.graphics.print(self.p1.stats.characterName, P1_BAR_X, BARS_Y + BAR_H * 2 + 8)
  local n2 = self.p2.stats.characterName
  love.graphics.print(n2, P2_BAR_X + BAR_W - #n2 * 6, BARS_Y + BAR_H * 2 + 8)

  -- Timer (center top)
  local tStr = tostring(math.max(0, math.ceil(self.timerSeconds)))
  love.graphics.setColor(1, 0.9, 0.2)
  love.graphics.printf(tStr, 0, 8, 480, "center")

  -- Phase indicator (below timer)
  if self.spawner then
    local phase = self.spawner:getPhase()
    if phase then
      love.graphics.setColor(phase.color[1], phase.color[2], phase.color[3], 0.85)
      love.graphics.printf("◆ " .. phase.name, 0, 24, 480, "center")
    end

    -- Phase transition announcement
    local announce = self.spawner:getPhaseAnnounce()
    if announce then
      love.graphics.setColor(1, 0.2, 0.2)
      love.graphics.printf(announce, 0, 108, 480, "center")
    end
  end

  -- Destruction meter (bottom center)
  local meterW = 160
  local meterX = (480 - meterW) / 2
  local meterY = 254

  love.graphics.setColor(0.12, 0.12, 0.20)
  love.graphics.rectangle("fill", meterX, meterY, meterW, 6)

  local r = math.min(1, self._destroyPct * 2)
  local g = math.max(0, 1 - self._destroyPct * 1.5)
  love.graphics.setColor(r + 0.2, g + 0.1, 0.05)
  love.graphics.rectangle("fill", meterX, meterY, meterW * self._destroyPct, 6)

  love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
  love.graphics.rectangle("line", meterX, meterY, meterW, 6)

  love.graphics.setColor(0.6, 0.6, 0.7)
  love.graphics.printf(
    string.format("CITY %d%%", math.floor(self._destroyPct * 100)),
    meterX, meterY - 11, meterW, "center")

  if self.spawner then
    local dollars = self.spawner:getDestructionScore()
    if dollars > 0 then
      love.graphics.setColor(0.95, 0.88, 0.45)
      love.graphics.printf(string.format("$%.1fM", dollars / 1e6), 0, meterY - 11, 480, "right")
    end
  end

  -- UNLEASH flashes
  if self.p1:isPowerFull() then
    local a = 0.7 + 0.3 * math.sin(love.timer.getTime() * 8)
    love.graphics.setColor(1, 0.1, 0.1, a)
    love.graphics.printf("UNLEASH!", P1_BAR_X, PWR_Y + 10, BAR_W, "left")
  end
  if self.p2:isPowerFull() then
    local a = 0.7 + 0.3 * math.sin(love.timer.getTime() * 8)
    love.graphics.setColor(1, 0.1, 0.1, a)
    love.graphics.printf("UNLEASH!", P2_BAR_X, PWR_Y + 10, BAR_W, "right")
  end

  -- Combo
  if self._comboTimer > 0 then
    love.graphics.setColor(1, 0.8, 0.1, math.min(1, self._comboTimer))
    love.graphics.printf(self._comboText or "", 0, 128, 480, "center")
  end
end

function HUD:_drawBar(x, y, w, h, pct, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.15,0.15,0.15})
  love.graphics.rectangle("fill", x, y, w, h)
  local fc = fillColor
  if pct < 0.3 then fc = {0.9,0.1,0.1} elseif pct < 0.6 then fc = {0.9,0.7,0.1} end
  love.graphics.setColor(fc)
  love.graphics.rectangle("fill", x, y, w * math.max(0, pct), h)
  love.graphics.setColor(1,1,1,0.25)
  love.graphics.rectangle("line", x, y, w, h)
end

function HUD:_drawBarRTL(x, y, w, h, pct, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.15,0.15,0.15})
  love.graphics.rectangle("fill", x, y, w, h)
  local fc = fillColor
  if pct < 0.3 then fc = {0.9,0.1,0.1} elseif pct < 0.6 then fc = {0.9,0.7,0.1} end
  local fillW = w * math.max(0, pct)
  love.graphics.setColor(fc)
  love.graphics.rectangle("fill", x + w - fillW, y, fillW, h)
  love.graphics.setColor(1,1,1,0.25)
  love.graphics.rectangle("line", x, y, w, h)
end

return HUD
