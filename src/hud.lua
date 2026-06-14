-- src/hud.lua
local HUD   = {}
HUD.__index = HUD

-- Layout constants (in 480×270 reference space)
local BAR_H    = 8
local BAR_W    = 160
local P1_BAR_X = 10
local P2_BAR_X = 480 - 10 - BAR_W
local BARS_Y   = 10
local PWR_Y    = BARS_Y + BAR_H + 3

function HUD.new(p1char, p2char, spawner)
  local self = setmetatable({
    p1      = p1char,
    p2      = p2char,
    spawner = spawner,
    timerSeconds = 99,
    _comboText = nil,
    _comboTimer = 0,
  }, HUD)

  -- Wire events
  if spawner then
    spawner.onSplatStreak = function()
      self._comboText  = "SQUISH x5 — GAWDZILLLLA APPROVES"
      self._comboTimer = 2.5
    end
  end

  return self
end

function HUD:update(dt, timeRemaining)
  self.timerSeconds = timeRemaining
  if self._comboTimer > 0 then
    self._comboTimer = self._comboTimer - dt
  end
end

function HUD:draw()
  -- P1 Health bar
  self:_drawBar(P1_BAR_X, BARS_Y, BAR_W, BAR_H, self.p1:healthPercent(), {0.15,0.75,0.2}, {0.5,0.15,0.1})
  -- P1 Power bar
  self:_drawBar(P1_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p1:powerPercent(), {0.2,0.4,1}, {0.1,0.1,0.3})

  -- P2 Health bar (right-aligned, fills left)
  self:_drawBarRTL(P2_BAR_X, BARS_Y, BAR_W, BAR_H, self.p2:healthPercent(), {0.75,0.2,0.15}, {0.5,0.15,0.1})
  -- P2 Power bar
  self:_drawBarRTL(P2_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p2:powerPercent(), {0.2,0.4,1}, {0.1,0.1,0.3})

  -- Character names
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(self.p1.stats.characterName, P1_BAR_X, BARS_Y + BAR_H * 2 + 4)
  local name2 = self.p2.stats.characterName
  love.graphics.print(name2, P2_BAR_X + BAR_W - #name2 * 6, BARS_Y + BAR_H * 2 + 4)

  -- Timer
  local tStr = tostring(math.max(0, math.ceil(self.timerSeconds)))
  love.graphics.setColor(1, 0.9, 0.2)
  love.graphics.printf(tStr, 0, 8, 480, "center")

  -- Destruction score
  if self.spawner then
    local dollars = self.spawner:getDestructionScore()
    if dollars > 0 then
      love.graphics.setColor(0.9, 0.9, 0.5)
      love.graphics.printf(string.format("$%.1fM", dollars / 1e6), 0, 255, 480, "center")
    end
  end

  -- Power-full flash indicator
  if self.p1:isPowerFull() then
    love.graphics.setColor(1, 0, 0, 0.7 + 0.3 * math.sin(love.timer.getTime() * 8))
    love.graphics.printf("UNLEASH!", P1_BAR_X, PWR_Y + 10, BAR_W, "left")
  end
  if self.p2:isPowerFull() then
    love.graphics.setColor(1, 0, 0, 0.7 + 0.3 * math.sin(love.timer.getTime() * 8))
    love.graphics.printf("UNLEASH!", P2_BAR_X, PWR_Y + 10, BAR_W, "right")
  end

  -- Combo text
  if self._comboTimer > 0 then
    local alpha = math.min(1, self._comboTimer)
    love.graphics.setColor(1, 0.8, 0.1, alpha)
    love.graphics.printf(self._comboText or "", 0, 120, 480, "center")
  end
end

function HUD:_drawBar(x, y, w, h, percent, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.2,0.2,0.2})
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(fillColor or {0.3,0.8,0.3})
  love.graphics.rectangle("fill", x, y, w * math.max(0, percent), h)
  love.graphics.setColor(1,1,1,0.3)
  love.graphics.rectangle("line", x, y, w, h)
end

function HUD:_drawBarRTL(x, y, w, h, percent, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.2,0.2,0.2})
  love.graphics.rectangle("fill", x, y, w, h)
  local fillW = w * math.max(0, percent)
  love.graphics.setColor(fillColor or {0.3,0.8,0.3})
  love.graphics.rectangle("fill", x + w - fillW, y, fillW, h)
  love.graphics.setColor(1,1,1,0.3)
  love.graphics.rectangle("line", x, y, w, h)
end

return HUD
