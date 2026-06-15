-- src/fps/portal_transition.lua
-- 2.5-second animated portal opening before entering FPS battle.
-- Monarch activates the portal; player steps through into the city mid-attack.

local SM = require("src/scene_manager")

local Portal = {}
Portal.__index = Portal

local SCREEN_W = 480
local SCREEN_H = 270
local DURATION = 2.5

function Portal.new(cityKey, playerChar, cityDisplayName)
  return setmetatable({
    _cityKey         = cityKey,
    _playerChar      = playerChar,
    _cityDisplayName = cityDisplayName or "TOKYO",
    _t               = 0,
  }, Portal)
end

function Portal:update(dt)
  self._t = self._t + dt
  if self._t >= DURATION then
    local FPS = require("src/scenes/fps_city")
    SM.replace(FPS.new(self._cityKey, self._playerChar))
  end
end

function Portal:keypressed(key)
  if key == "space" or key == "return" then
    local FPS = require("src/scenes/fps_city")
    SM.replace(FPS.new(self._cityKey, self._playerChar))
  end
end

function Portal:draw()
  local t = math.min(1, self._t / DURATION)

  -- Dark background
  love.graphics.setColor(0.03, 0.03, 0.08)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  -- Portal rings: expanding circle from center
  local radius = 18 + t * 170
  local alpha  = math.sin(t * math.pi)
  love.graphics.setColor(0.10, 0.50, 1.00, alpha * 0.85)
  love.graphics.circle("line", SCREEN_W / 2, SCREEN_H / 2, radius)
  love.graphics.setColor(0.30, 0.70, 1.00, alpha * 0.45)
  love.graphics.circle("line", SCREEN_W / 2, SCREEN_H / 2, radius - 5)

  -- Orbiting energy nodes
  love.graphics.setColor(0.20, 0.85, 1.00, alpha)
  for i = 1, 8 do
    local ang = (i / 8) * math.pi * 2 + self._t * 2.5
    local px  = SCREEN_W / 2 + math.cos(ang) * radius
    local py  = SCREEN_H / 2 + math.sin(ang) * radius
    love.graphics.circle("fill", px, py, 3)
  end

  -- White flash as portal fully opens
  if t > 0.78 then
    local flash = (t - 0.78) / 0.22
    love.graphics.setColor(1, 1, 1, flash)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
  end

  -- Text
  local textAlpha = math.min(1, t * 5)
  love.graphics.setColor(0.75, 0.78, 1.00, textAlpha)
  love.graphics.printf("MONARCH QUANTUM PORTAL", 0, SCREEN_H / 2 - 28, SCREEN_W, "center")
  love.graphics.setColor(1.00, 0.80, 0.20, textAlpha)
  love.graphics.printf(self._cityDisplayName .. " — ATTACK IN PROGRESS", 0, SCREEN_H / 2 - 8, SCREEN_W, "center")
  love.graphics.setColor(0.38, 0.38, 0.58, math.min(1, t * 2.5))
  love.graphics.printf("SPACE to skip", 0, SCREEN_H / 2 + 18, SCREEN_W, "center")
end

return Portal
