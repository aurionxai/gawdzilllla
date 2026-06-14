-- src/scenes/battle.lua
local SM       = require("src/scene_manager")
local Ctrl     = require("src/controller")
local Input    = require("src/input")
local HUD      = require("src/hud")
local FM       = require("src/fight_manager")
local Spawner  = require("src/npc_spawner")
local Pool     = require("src/blood_pool")
local AS       = require("src/attack_system")
local AM       = require("src/audio_manager")

local Battle   = {}
Battle.__index = Battle

local GROUND_Y = Ctrl.GROUND_Y   -- 220

function Battle.new(p1Info, p2Info)
  local self  = setmetatable({}, Battle)

  -- Build characters
  local P1Mod = require(p1Info.module)
  local P2Mod = require(p2Info.module)
  self._p1  = P1Mod.new()
  self._p2  = P2Mod.new()

  -- Controllers (position, physics)
  self._ctrl1 = Ctrl.new(self._p1.character, 120, GROUND_Y)
  self._ctrl2 = Ctrl.new(self._p2.character, 360, GROUND_Y)
  self._ctrl2.facingRight = false

  -- NPC system
  self._spawner = Spawner.new()
  self._spawner:spawnBatch(60, 480, GROUND_Y)
  self._pool    = Pool.new()

  -- HUD
  self._hud = HUD.new(self._p1.character, self._p2.character, self._spawner)

  -- Fight manager
  self._fm = FM.new(self._p1.character, self._p2.character, { totalRounds=3, roundDuration=99 })
  self._matchOver = false
  self._resultText = nil
  self._resultTimer = 0

  self._fm.onRoundStart = function(r)
    self._announceText  = "ROUND " .. r .. " — FIGHT!"
    self._announceTimer = 1.5
  end

  self._fm.onRoundEnd = function(winner)
    local name = winner == 1 and self._p1.stats.characterName or self._p2.stats.characterName
    self._announceText  = name .. " WINS ROUND!"
    self._announceTimer = 1.8
  end

  self._fm.onMatchEnd = function(winner)
    local name = winner == 1 and self._p1.stats.characterName or self._p2.stats.characterName
    self._resultText  = name .. " WINS!\nDestruction: $" ..
                         string.format("%.1f", self._spawner:getDestructionScore() / 1e6) .. "M"
    self._matchOver   = true
    self._resultTimer = 4.0
  end

  self._announceText  = nil
  self._announceTimer = 0

  -- Audio
  self._audio = AM.getInstance()
  self._audio:playMusic()

  self._fm:startMatch()
  return self
end

function Battle:update(dt)
  if self._matchOver then
    self._resultTimer = self._resultTimer - dt
    if self._resultTimer <= 0 then
      local MM = require("src/scenes/main_menu")
      SM.replace(MM.new())
    end
    return
  end

  -- Input → controllers
  local mx1 = Input.getMoveX(1)
  local mx2 = Input.getMoveX(2)
  self._ctrl1:update(dt, mx1)
  self._ctrl2:update(dt, mx2)

  -- Update character-specific logic (unleash timers etc.)
  self._p1:update(dt)
  self._p2:update(dt)

  -- Sync attack systems (need facing for hitbox direction)
  self._p1.attacks:update(dt, self._ctrl1.x, self._ctrl1.facingRight)
  self._p2.attacks:update(dt, self._ctrl2.x, self._ctrl2.facingRight)

  -- Hit detection: P1 attacks hitting P2 and vice-versa
  self:_checkHits(self._p1.attacks, self._ctrl1, self._p2.character, self._ctrl2)
  self:_checkHits(self._p2.attacks, self._ctrl2, self._p1.character, self._ctrl1)

  -- NPC stomp: characters walking over NPCs
  self:_checkStomps(self._ctrl1)
  self:_checkStomps(self._ctrl2)

  -- Update systems
  self._spawner:update(dt)
  self._pool:update(dt)
  self._fm:update(dt)
  self._hud:update(dt, self._fm.timeRemaining)

  -- Announce timer
  if self._announceTimer > 0 then
    self._announceTimer = self._announceTimer - dt
  end
end

function Battle:_checkHits(attackSystem, attackerCtrl, targetChar, targetCtrl)
  if targetChar.isDefeated then return end
  local boxes = attackSystem:getHitboxes(attackerCtrl.x, attackerCtrl.y, attackerCtrl.facingRight)
  local tb    = targetCtrl:getBounds()
  for _, hb in ipairs(boxes) do
    if AS.overlaps(hb, tb) then
      targetChar:takeDamage(hb.damage)
      attackSystem.character:gainPower(hb.powerGain)
      if hb.stunDuration and hb.stunDuration > 0 then
        targetCtrl:applyStun(hb.stunDuration)
      end
      self._audio:playRandomSplat()
    end
  end
end

function Battle:_checkStomps(ctrl)
  local cb = ctrl:getBounds()
  -- Stomp box = bottom 8px of character
  local stomper = { x=cb.x, y=cb.y + cb.h - 8, w=cb.w, h=8 }
  for _, npc in ipairs(self._spawner.npcs) do
    if not npc.isDead then
      local nb = npc:getBounds()
      if AS.overlaps(stomper, nb) then
        npc:stomp(self._pool, self._spawner)
        self._audio:playRandomSplat()
      end
    end
  end
end

function Battle:keypressed(key)
  -- P1 one-shot actions
  local a1 = Input.getAction(1, key)
  if a1 == "jump"    then self._ctrl1:jump() end
  if a1 == "light"   then self._p1.attacks:performLight() end
  if a1 == "heavy"   then self._p1.attacks:performHeavy() end
  if a1 == "special" then self._p1.attacks:performSpecial() end
  if a1 == "unleash" then self._p1:triggerUnleash() end

  -- P2 one-shot actions
  local a2 = Input.getAction(2, key)
  if a2 == "jump"    then self._ctrl2:jump() end
  if a2 == "light"   then self._p2.attacks:performLight() end
  if a2 == "heavy"   then self._p2.attacks:performHeavy() end
  if a2 == "special" then self._p2.attacks:performSpecial() end
  if a2 == "unleash" then self._p2:triggerUnleash() end
end

function Battle:draw()
  -- Sky
  love.graphics.setColor(0.08, 0.1, 0.2)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- City silhouette (placeholder buildings)
  love.graphics.setColor(0.12, 0.12, 0.2)
  local buildings = { {40,180,30,80},{90,160,50,100},{160,150,40,110},{220,170,60,90},
                      {300,155,35,105},{350,165,50,95},{410,145,40,115},{450,175,25,85} }
  for _, b in ipairs(buildings) do
    love.graphics.rectangle("fill", b[1], b[2], b[3], b[4])
    -- Windows
    love.graphics.setColor(0.9, 0.85, 0.4, 0.4)
    for wy = b[2]+6, b[2]+b[4]-10, 10 do
      for wx = b[1]+4, b[1]+b[3]-8, 7 do
        love.graphics.rectangle("fill", wx, wy, 4, 5)
      end
    end
    love.graphics.setColor(0.12, 0.12, 0.2)
  end

  -- Ground
  love.graphics.setColor(0.22, 0.2, 0.18)
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 270 - GROUND_Y)
  love.graphics.setColor(0.35, 0.3, 0.28)
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 2)

  -- NPCs
  self._spawner:draw()

  -- Blood pool
  self._pool:draw()

  -- Characters
  self._p1.attacks:getHitboxes(self._ctrl1.x, self._ctrl1.y, self._ctrl1.facingRight)  -- (no-op draw)
  self._ctrl1:draw(self._p1.stats.color)
  self._p1:drawExtra(self._ctrl1)

  self._ctrl2:draw(self._p2.stats.color)
  self._p2:drawExtra(self._ctrl2)

  -- HUD
  self._hud:draw()

  -- Round announcement
  if self._announceTimer > 0 then
    local alpha = math.min(1, self._announceTimer * 1.5)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(self._announceText or "", 0, 120, 480, "center")
  end

  -- Match result
  if self._matchOver and self._resultText then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 80, 90, 320, 90, 8)
    love.graphics.setColor(1, 0.85, 0.1)
    love.graphics.printf(self._resultText, 80, 108, 320, "center")
  end
end

return Battle
