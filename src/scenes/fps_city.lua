-- src/scenes/fps_city.lua
-- Main FPS battle scene. Wires camera, map, player, enemy, combat, and HUD.
-- State machine: FIGHTING → VICTORY | DEFEAT → returns to world map.

local SM       = require("src/scene_manager")
local Camera   = require("src/fps/camera")
local Map      = require("src/fps/map")
local Renderer = require("src/fps/renderer")
local Player   = require("src/fps/player_state")
local Enemy    = require("src/fps/enemy_titan")
local Combat   = require("src/fps/combat_fps")
local Hud      = require("src/fps/hud_fps")
local AM       = require("src/audio_manager")

local FPSCity = {}
FPSCity.__index = FPSCity

local SCREEN_W = 480
local SCREEN_H = 270
local END_DELAY = 3.0   -- seconds on victory/defeat screen before returning to map

local MONARCH_MSGS = {
  "Ghidorah is charging gravity beams — dodge now!",
  "Target the chest — that's the weak point!",
  "Civilians at grid 4 need cover, watch your left!",
  "Atomic breath charged — fire when it's facing you!",
  "City integrity dropping — push it back from the buildings!",
}

function FPSCity.new(cityKey, playerChar)
  local map = Map.new()
  local cam = Camera.new(map.PLAYER_START_X, map.PLAYER_START_Y, map.PLAYER_START_ANGLE)
  local ps  = Player.new(playerChar and playerChar.name or "Godzilla")
  local et  = Enemy.new(map.TITAN_START_X, map.TITAN_START_Y)

  return setmetatable({
    _cityKey  = cityKey,
    _camera   = cam,
    _map      = map,
    _player   = ps,
    _enemy    = et,
    -- City metrics
    _cityIntegrity = 1.0,   -- 1.0 = fully standing, 0.0 = destroyed
    _civsSaved     = 0,
    _totalCivs     = 12,
    -- Monarch comms
    _monarchMsg   = MONARCH_MSGS[1],
    _monarchTimer = 9.0,
    _monarchIdx   = 1,
    -- Scene state
    _state    = "FIGHTING",   -- FIGHTING | VICTORY | DEFEAT
    _endTimer = 0,
    -- Per-frame flags
    _keys     = {},
    _hitFlash = 0,
    _shake    = 0,
  }, FPSCity)
end

function FPSCity:update(dt)
  if self._state ~= "FIGHTING" then
    self._endTimer = self._endTimer - dt
    if self._endTimer <= 0 then
      local WM = require("src/scenes/world_map")
      SM.replace(WM.new({ won = self._state == "VICTORY", cityKey = self._cityKey }))
    end
    return
  end

  -- Camera movement from held keys
  local fwd = 0
  if self._keys["up"]   or self._keys["w"] then fwd =  1 end
  if self._keys["down"] or self._keys["s"] then fwd = -1 end
  local rot = 0
  if self._keys["right"] or self._keys["d"] then rot =  1 end
  if self._keys["left"]  or self._keys["a"] then rot = -1 end

  local oldX, oldY = self._camera.x, self._camera.y
  if fwd ~= 0 then self._camera:move(dt, fwd, 0) end
  if rot ~= 0 then self._camera:rotate(dt, rot) end
  -- Collision: revert if new position is inside a wall
  if not self._map:isWalkable(self._camera.x, self._camera.y) then
    self._camera.x = oldX
    self._camera.y = oldY
  end

  self._player:update(dt)
  self._enemy:update(dt, self._camera.x, self._camera.y)

  -- Enemy attack lands on player
  if self._enemy.isAttacking then
    self._player:takeDamage(18)
    self._hitFlash = 0.30
    self._shake    = 0.20
    self._cityIntegrity = math.max(0, self._cityIntegrity - 0.05)
  end

  -- Titan presence slowly degrades city integrity
  if self._enemy.state ~= "DEAD" then
    self._cityIntegrity = math.max(0, self._cityIntegrity - 0.0015 * dt)
  end

  -- Timers
  self._hitFlash = math.max(0, self._hitFlash - dt)
  self._shake    = math.max(0, self._shake    - dt)

  -- Monarch comms rotation
  self._monarchTimer = self._monarchTimer - dt
  if self._monarchTimer <= 0 then
    self._monarchTimer = 10 + math.random(0, 5)
    self._monarchIdx   = (self._monarchIdx % #MONARCH_MSGS) + 1
    self._monarchMsg   = MONARCH_MSGS[self._monarchIdx]
  end

  -- Win / lose checks
  if self._enemy.state == "DEAD" then
    self._state    = "VICTORY"
    self._endTimer = END_DELAY
  elseif self._player.hp <= 0 or self._cityIntegrity <= 0 then
    self._state    = "DEFEAT"
    self._endTimer = END_DELAY
  end
end

function FPSCity:keypressed(key)
  self._keys[key] = true
  if self._state ~= "FIGHTING" then return end

  -- [Q] Atomic breath (ranged cone)
  if key == "q" and self._player:canUse("ranged") then
    self._player:useMove("ranged")
    local hit, dist = Combat.checkRangedHit(self._camera, self._enemy, 600)
    if hit then
      self._enemy:takeDamage(self._player:getRangedDamage())
      self._player:gainXp(8)
    end
  end

  -- [Z] Claw swipe (close melee)
  if key == "z" and self._player:canUse("claw") then
    self._player:useMove("claw")
    local hit = Combat.checkMeleeHit(self._camera, self._enemy, 120)
    if hit then
      self._enemy:takeDamage(self._player:getMeleeDamage("claw"))
      self._player:gainXp(5)
    end
  end

  -- [X] Bite (unlocks at Lv5; bonus damage vs stunned enemy)
  if key == "x" and self._player:canUse("bite") then
    self._player:useMove("bite")
    local hit = Combat.checkMeleeHit(self._camera, self._enemy, 90)
    if hit then
      local dmg = self._player:getMeleeDamage("bite")
      if self._enemy.state == "STUNNED" then dmg = math.floor(dmg * 2) end
      self._enemy:takeDamage(dmg)
      self._player:gainXp(10)
    end
  end

  -- [C] Tail slam (unlocks at Lv7; stuns enemy on hit)
  if key == "c" and self._player:canUse("tail") then
    self._player:useMove("tail")
    local hit = Combat.checkMeleeHit(self._camera, self._enemy, 150)
    if hit then
      self._enemy:takeDamage(self._player:getMeleeDamage("tail"))
      self._enemy:stun(2.5)
      self._player:gainXp(12)
    end
  end
end

function FPSCity:keyreleased(key)
  self._keys[key] = nil
end

function FPSCity:draw()
  -- Screen shake
  local sx, sy = 0, 0
  if self._shake > 0 then
    sx = math.random(-3, 3)
    sy = math.random(-2, 2)
  end
  love.graphics.push()
  love.graphics.translate(sx, sy)

  Renderer.draw(self._camera, self._map, self._enemy)

  -- Red hit-flash overlay
  if self._hitFlash > 0 then
    love.graphics.setColor(0.80, 0.08, 0.08, self._hitFlash * 0.45)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
  end

  Hud.draw(self._player, self._enemy, self._cityIntegrity,
           self._civsSaved, self._totalCivs, self._monarchMsg)

  -- End-of-battle overlay
  if self._state == "VICTORY" then
    love.graphics.setColor(0.05, 0.55, 0.15, 0.72)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    love.graphics.setColor(0.30, 1.00, 0.50)
    love.graphics.printf("CITY DEFENDED!", 0, SCREEN_H / 2 - 8, SCREEN_W, "center")
  elseif self._state == "DEFEAT" then
    love.graphics.setColor(0.55, 0.04, 0.04, 0.72)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    love.graphics.setColor(1.00, 0.30, 0.30)
    love.graphics.printf("CITY FALLEN", 0, SCREEN_H / 2 - 8, SCREEN_W, "center")
  end

  love.graphics.pop()
end

return FPSCity
