-- src/scenes/battle.lua
local SM         = require("src/scene_manager")
local Ctrl       = require("src/controller")
local Input      = require("src/input")
local HUD        = require("src/hud")
local FM         = require("src/fight_manager")
local Spawner    = require("src/npc_spawner")
local Pool       = require("src/blood_pool")
local AS         = require("src/attack_system")
local AM         = require("src/audio_manager")
local City       = require("src/city")
local CitiesData = require("src/cities_data")
local FoodMgr    = require("src/food_manager")
local CPU        = require("src/cpu_controller")

local Battle   = {}
Battle.__index = Battle

local GROUND_Y = Ctrl.GROUND_Y   -- 220

-- Story mode constructor: uses a specific city, returns to world map when done.
function Battle.newStory(p1Info, p2Info, cityDef, cityKey)
  local self = Battle._build(p1Info, p2Info, true, cityDef)
  self._storyCityKey = cityKey
  self._fm.onMatchEnd = function(winner)
    local p1won = winner == 1
    self._matchWinner = p1won and self._p1.stats.characterName or self._p2.stats.characterName
    self._matchOver   = true
    self._resultTimer = 2.0
    self._storyWon    = p1won
    if p1won then
      local SS = require("src/story_state")
      SS.conquer(cityKey)
    end
  end
  return self
end

function Battle.new(p1Info, p2Info, isSinglePlayer)
  return Battle._build(p1Info, p2Info, isSinglePlayer or false, nil)
end

function Battle._build(p1Info, p2Info, isSinglePlayer, forceCityDef)
  local self  = setmetatable({}, Battle)
  self._shake  = 0
  self._isSinglePlayer = isSinglePlayer
  self._cpu = isSinglePlayer and CPU.new() or nil
  self._storyCityKey = nil
  self._storyWon     = nil

  -- Build characters
  local P1Mod = require(p1Info.module)
  local P2Mod = require(p2Info.module)
  self._p1  = P1Mod.new()
  self._p2  = P2Mod.new()

  -- Controllers
  self._ctrl1 = Ctrl.new(self._p1.character, 100, GROUND_Y)
  self._ctrl2 = Ctrl.new(self._p2.character, 380, GROUND_Y)
  self._ctrl2.facingRight = false

  self._ctrl1.character = self._p1.character
  self._ctrl2.character = self._p2.character

  -- City (use forced cityDef in story mode, random otherwise)
  local cityDef = forceCityDef or CitiesData[math.random(#CitiesData)]
  self._city = City.new(cityDef)
  self._totalBuildings    = #self._city.buildings
  self._destroyedBuildings= 0

  -- NPC system
  self._spawner = Spawner.new()
  self._spawner:spawnBatch(40, 480, GROUND_Y)
  self._pool    = Pool.new()

  -- Food + Gregg
  self._foodMgr = FoodMgr.new(self._p1, self._p2, self._ctrl1, self._ctrl2)
  self._p1.attacks.onSpecialFired = function() self._foodMgr:registerSpecial() end
  self._p2.attacks.onSpecialFired = function() self._foodMgr:registerSpecial() end

  -- HUD
  self._hud = HUD.new(self._p1.character, self._p2.character, self._spawner, nil)

  -- Fight manager
  self._fm = FM.new(self._p1.character, self._p2.character, { totalRounds=3, roundDuration=99 })
  self._hud.fm = self._fm
  self._matchOver  = false
  self._matchWinner = nil

  self._fm.onRoundStart = function(r)
    self._announceText  = "ROUND " .. r .. "  FIGHT!"
    self._announceTimer = 1.5
  end

  self._fm.onRoundEnd = function(winner)
    local name = winner == 1 and self._p1.stats.characterName or self._p2.stats.characterName
    self._announceText  = name .. " WINS ROUND!"
    self._announceTimer = 1.8
  end

  self._fm.onMatchEnd = function(winner)
    self._matchWinner = winner == 1
      and self._p1.stats.characterName
      or  self._p2.stats.characterName
    self._matchOver  = true
    self._resultTimer = 2.0
  end

  self._announceText  = nil
  self._announceTimer = 0

  -- Audio
  self._audio = AM.getInstance()
  self._audio:playMusic()

  self._city._audio   = self._audio
  self._city._pool    = self._pool
  self._city._spawner = self._spawner

  self._fm:startMatch()
  return self
end

-- ── Update ────────────────────────────────────────────────────────────────────

function Battle:update(dt)
  if self._matchOver then
    self._resultTimer = self._resultTimer - dt
    if self._resultTimer <= 0 then
      if self._storyCityKey then
        -- Story mode: return to world map
        local WM = require("src/scenes/world_map")
        SM.replace(WM.new({ won=self._storyWon, cityKey=self._storyCityKey }))
      else
        local Results = require("src/scenes/results")
        SM.replace(Results.new({
          winner             = self._matchWinner,
          p1name             = self._p1.stats.characterName,
          p2name             = self._p2.stats.characterName,
          dollars            = self._spawner:getDestructionScore(),
          splats             = self._spawner:getSplatCount(),
          buildingsDestroyed = self._destroyedBuildings,
          totalBuildings     = self._totalBuildings,
        }))
      end
    end
    return
  end

  -- Count destroyed buildings
  local destroyed = 0
  for _, b in ipairs(self._city.buildings) do
    if b.isDestroyed then destroyed = destroyed + 1 end
  end
  self._destroyedBuildings = destroyed
  local destroyPct = destroyed / math.max(1, self._totalBuildings)
  self._spawner:setDestroyPct(destroyPct)

  -- CPU AI for P2 in single-player
  local p2MoveX
  if self._cpu and not self._p2.character.isDefeated then
    p2MoveX = self._cpu:think(dt, self._ctrl2, self._ctrl1)
    if self._cpu._doJump   then self._ctrl2:jump() end
    if self._cpu._doAttack then self._p2.attacks:performLight() end
    if self._cpu._doSpecial then self._p2.attacks:performSpecial() end
  else
    p2MoveX = Input.getMoveX(2)
  end

  -- Input → controllers
  self._ctrl1:update(dt, Input.getMoveX(1), self._city.buildings)
  self._ctrl2:update(dt, p2MoveX, self._city.buildings)

  -- Character logic
  self._p1:update(dt)
  self._p2:update(dt)

  -- Attack systems
  self._p1.attacks:update(dt, self._ctrl1.x, self._ctrl1.facingRight)
  self._p2.attacks:update(dt, self._ctrl2.x, self._ctrl2.facingRight)

  -- Hit detection
  self:_checkHits(self._p1.attacks, self._ctrl1, self._p2.character, self._ctrl2)
  self:_checkHits(self._p2.attacks, self._ctrl2, self._p1.character, self._ctrl1)

  -- Buildings take damage
  local h1 = self._city:checkHits(self._p1.attacks, self._ctrl1, self._spawner)
  local h2 = self._city:checkHits(self._p2.attacks, self._ctrl2, self._spawner)
  if h1 or h2 then self._shake = 0.22 end

  -- NPC stomps
  self:_checkStomps(self._ctrl1)
  self:_checkStomps(self._ctrl2)

  -- NPC system
  local targets = {
    { x = self._ctrl1.x, y = self._ctrl1.y },
    { x = self._ctrl2.x, y = self._ctrl2.y },
  }
  self._spawner:update(dt, targets, GROUND_Y)
  self._spawner:checkProjectileHits({ self._ctrl1, self._ctrl2 })

  -- Other systems
  self._pool:update(dt)
  self._foodMgr:update(dt)
  self._fm:update(dt)
  self._shake = math.max(0, self._shake - dt)
  self._city:update(dt)
  self._hud:update(dt, self._fm.timeRemaining, self._destroyedBuildings, self._totalBuildings)

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
      local dir = attackerCtrl.facingRight and 1 or -1
      targetCtrl:applyKnockback(dir * hb.damage * 4, -hb.damage * 2)
      self._audio:playHit(hb.damage)
    end
  end
end

function Battle:_checkStomps(ctrl)
  local cb = ctrl:getBounds()
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

-- ── Input ─────────────────────────────────────────────────────────────────────

function Battle:keypressed(key)
  -- P1 controls
  local a1 = Input.getAction(1, key)
  if a1 == "jump"    then self._ctrl1:jump() end
  if a1 == "light"   then self._p1.attacks:performLight() end
  if a1 == "special" then self._p1.attacks:performSpecial() end

  -- P2 controls (only in 2-player mode)
  if not self._isSinglePlayer then
    local a2 = Input.getAction(2, key)
    if a2 == "jump"    then self._ctrl2:jump() end
    if a2 == "light"   then self._p2.attacks:performLight() end
    if a2 == "special" then self._p2.attacks:performSpecial() end
  end

  if key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
  end
end

-- ── Draw ──────────────────────────────────────────────────────────────────────

function Battle:draw()
  love.graphics.push()
  if self._shake > 0 then
    local sx = math.floor(math.sin(self._shake * 120) * self._shake * 6)
    local sy = math.floor(math.cos(self._shake * 90)  * self._shake * 3)
    love.graphics.translate(sx, sy)
  end

  -- Sky
  local sc = self._city.skyC
  love.graphics.setColor(sc[1], sc[2], sc[3])
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- City buildings
  self._city:draw()

  -- Ground
  local gc = self._city.gndC
  love.graphics.setColor(gc[1], gc[2], gc[3])
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 270 - GROUND_Y)
  love.graphics.setColor(gc[1]+0.12, gc[2]+0.10, gc[3]+0.08)
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 2)

  -- NPCs + projectiles
  self._spawner:draw()

  -- Blood pool
  self._pool:draw()

  -- Food / Gregg
  self._foodMgr:draw()

  -- Characters
  self._ctrl1:draw(self._p1.stats.color, self._p1.sprites or self._p1.sprite)
  self._p1:drawExtra(self._ctrl1)
  self._ctrl2:draw(self._p2.stats.color, self._p2.sprites or self._p2.sprite)
  self._p2:drawExtra(self._ctrl2)

  -- HUD
  self._hud:draw()

  -- City name
  love.graphics.setColor(0.35, 0.35, 0.45)
  love.graphics.printf(self._city.name, 0, 258, 474, "right")

  -- Round announcement
  if self._announceTimer > 0 then
    local alpha = math.min(1, self._announceTimer * 1.5)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(self._announceText or "", 0, 116, 480, "center")
  end

  -- Match over card
  if self._matchOver and self._matchWinner then
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 90, 95, 300, 50, 8)
    love.graphics.setColor(1, 0.85, 0.1)
    love.graphics.printf(self._matchWinner .. " WINS!", 90, 108, 300, "center")
  end

  love.graphics.pop()

  -- Controls hint
  love.graphics.setColor(0.25, 0.25, 0.35)
  if self._isSinglePlayer then
    love.graphics.printf("WASD move/jump   Z attack   X special   ESC menu", 0, 262, 480, "center")
  else
    love.graphics.printf("P1: WASD  Z=attack  X=special     P2: Arrows  KP0=attack  KP1=special     ESC menu", 0, 262, 480, "center")
  end
end

return Battle
