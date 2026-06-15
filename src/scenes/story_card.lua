-- src/scenes/story_card.lua
-- Pre-city narrative card shown before a city assault begins.
-- Fades in, displays lore text, player presses ENTER to begin.

local SM   = require("src/scene_manager")
local SL   = require("src/story_lore")

local SC   = {}
SC.__index = SC

local HOLD_TIME = 1.2   -- seconds before ENTER prompt appears

function SC.new(cityKey, playerCharInfo, defenderInfo, citiesData)
  local lore = SL.get(cityKey)
  return setmetatable({
    _cityKey      = cityKey,
    _playerChar   = playerCharInfo,
    _defender     = defenderInfo,
    _citiesData   = citiesData,
    _lore         = lore,
    _fadeAlpha    = 1.0,
    _fadingIn     = true,
    _timer        = 0,
    _blink        = 0,
    _ready        = false,   -- true once hold time is up
  }, SC)
end

function SC:update(dt)
  self._blink = self._blink + dt * 2.5

  if self._fadingIn then
    self._fadeAlpha = math.max(0, self._fadeAlpha - dt * 1.5)
    if self._fadeAlpha <= 0 then
      self._fadingIn = false
    end
  end

  if not self._fadingIn then
    self._timer = self._timer + dt
    if self._timer >= HOLD_TIME then
      self._ready = true
    end
  end
end

function SC:keypressed(key)
  if key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
    return
  end

  if (key == "return" or key == "space") and self._ready then
    self:_launch()
  end
end

function SC:_launch()
  local CA = require("src/scenes/city_assault")
  SM.replace(CA.new(self._playerChar, self._defender, self._citiesData, self._cityKey))
end

function SC:draw()
  local lore = self._lore

  -- Deep black background
  love.graphics.setColor(0.03, 0.03, 0.06)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Subtle horizontal rule at top
  love.graphics.setColor(0.25, 0.22, 0.15)
  love.graphics.rectangle("fill", 60, 62, 360, 1)

  -- Year / context label
  if lore.year ~= "" then
    love.graphics.setColor(0.55, 0.45, 0.22)
    love.graphics.printf(lore.year, 0, 48, 480, "center")
  end

  -- City title
  love.graphics.setColor(0.96, 0.90, 0.68)
  love.graphics.printf(lore.title, 0, 72, 480, "center")

  -- Separator dots
  love.graphics.setColor(0.35, 0.30, 0.20)
  love.graphics.printf("· · ·", 0, 92, 480, "center")

  -- Narrative lines
  local lineY = 110
  for _, line in ipairs(lore.lines) do
    love.graphics.setColor(0.72, 0.70, 0.65)
    love.graphics.printf(line, 80, lineY, 320, "center")
    lineY = lineY + 26
  end

  -- Defender callout
  love.graphics.setColor(0.35, 0.30, 0.20)
  love.graphics.rectangle("fill", 60, lineY + 12, 360, 1)
  love.graphics.setColor(0.65, 0.30, 0.22)
  love.graphics.printf("Defender: " .. self._defender.name, 0, lineY + 20, 480, "center")
  love.graphics.setColor(0.45, 0.42, 0.40)
  love.graphics.printf("Playing as: " .. self._playerChar.name, 0, lineY + 36, 480, "center")

  -- ENTER prompt (blinking, only once ready)
  if self._ready then
    local blink = 0.55 + 0.45 * math.sin(self._blink * math.pi)
    love.graphics.setColor(0.80, 0.75, 0.55, blink)
    love.graphics.printf("ENTER — Begin Assault", 0, 236, 480, "center")
  end

  -- ESC hint
  love.graphics.setColor(0.28, 0.28, 0.32)
  love.graphics.printf("ESC — World Map", 0, 256, 480, "center")

  -- Fade overlay
  if self._fadeAlpha > 0 then
    love.graphics.setColor(0, 0, 0, self._fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, 480, 270)
  end
end

return SC
