-- src/food_manager.lua
-- Food pickups + Gregg easter egg, random 1-in-500 spawn chance per food item.
local AS = require("src/attack_system")
local FR = require("src/food_renderer")
local KS = require("src/kaiju_sprites")

local FoodManager = {}
FoodManager.__index = FoodManager

local SPECIAL_THRESHOLD_FOOD  = 1   -- food appears after first special
local FOOD_SPAWN_INTERVAL     = 9.0
local FOOD_HEAL               = 20
local GROUND_Y                = 220
local FOOD_W, FOOD_H          = 16, 16

local FOOD_TYPES = FR.TYPES  -- 50 food types

local GREGG_W            = 18
local GREGG_H            = 44
local GREGG_SPEED        = 42
local GREGG_SPAWN_CHANCE = 500

local BLAME_BY_NAME = {
  ["Godzilla"]      = "He does this every time. Classic Godzilla.",
  ["Kong"]          = "I've been saying Kong has a problem. Nobody listens.",
  ["MechaGodzilla"] = "Exhaust leak. It's a mech thing. Engineering issue.",
  ["Ghidorah"]      = "Three heads, one source. I've run the math.",
  ["Mothra"]        = "Moths. You have no idea what they get up to.",
  ["Rodan"]         = "Supersonic wingspan. Aerodynamic displacement. Not me.",
  ["Titan"]         = "Super-powered metabolism. It's a hero thing.",
  ["Ironclad"]      = "Exhaust ports. Engineering issue. Totally different.",
  ["Webslinger"]    = "Silk glands. You really don't want to know.",
  ["Thunderstrike"] = "He gets a lightning hammer. I get the blame. Classic.",
  ["Biollante"]     = "Plant biology is wildly misunderstood. This tracks.",
  ["Destoroyah"]    = "End-stage mutation. Practically expected at this point.",
  ["Gigan"]         = "Cybernetic propulsion. Documented exhaust signature.",
  ["SpaceGodzilla"] = "Cosmic radiation. Not a me problem, technically.",
  ["Hedorah"]       = "Smog monster. Honestly I'm surprised you're surprised.",
  ["Anguirus"]      = "That armored shell traps everything. Common knowledge.",
}
local BLAME_FALLBACK = {
  "That little guy right there. I saw him.",
  "Military grade diesel. That's on the government.",
  "...There was someone here. They left.",
  "I take no responsibility for this whatsoever.",
}

function FoodManager.new(p1, p2, ctrl1, ctrl2)
  return setmetatable({
    _p1    = p1,    _p2    = p2,
    _ctrl1 = ctrl1, _ctrl2 = ctrl2,
    _specialCount = 0,
    _foodTimer    = FOOD_SPAWN_INTERVAL,
    _items        = {},
    _gregg        = nil,
    _announce     = nil,
    _announceTimer = 0,
  }, FoodManager)
end

function FoodManager:registerSpecial()
  self._specialCount = self._specialCount + 1
  if self._specialCount == SPECIAL_THRESHOLD_FOOD then
    self:_spawnFood()
    self._announce      = "FOOD FALLS FROM THE SKY!"
    self._announceTimer = 2.2
  end
  -- Gregg now spawns randomly via _spawnFood(), not on special count
end

function FoodManager:_spawnFood()
  local ft = FOOD_TYPES[math.random(#FOOD_TYPES)]
  table.insert(self._items, {
    x         = math.random(30, 445),
    y         = GROUND_Y - FOOD_H,
    w         = FOOD_W,
    h         = FOOD_H,
    type      = ft,
    collected = false,
  })
  -- Easter egg: 1-in-GREGG_SPAWN_CHANCE Gregg crashes the party
  if not self._gregg and math.random(GREGG_SPAWN_CHANCE) == 1 then
    self:_spawnGregg()
    self._announce      = "GREGG HAS ARRIVED. OH NO."
    self._announceTimer = 2.5
  end
end

function FoodManager:_spawnGregg()
  self._gregg = {
    x           = -30,
    y           = GROUND_Y - GREGG_H,
    w           = GREGG_W,
    h           = GREGG_H,
    state       = "WANDER",
    dir         = 1,
    _timer      = 0,
    _targetFood = nil,
    _blameText  = nil,
    _fartAlpha  = 0,
    _strutDir   = 1,
    _walkTimer  = 0,
  }
end

-- ── update ────────────────────────────────────────────────────────────────────

function FoodManager:update(dt)
  if self._announceTimer > 0 then
    self._announceTimer = self._announceTimer - dt
  end

  if self._specialCount >= SPECIAL_THRESHOLD_FOOD then
    self._foodTimer = self._foodTimer - dt
    if self._foodTimer <= 0 then
      self._foodTimer = FOOD_SPAWN_INTERVAL + math.random() * 6
      self:_spawnFood()
    end
  end

  self:_checkCollections()

  for i = #self._items, 1, -1 do
    if self._items[i].collected then table.remove(self._items, i) end
  end

  if self._gregg then self:_updateGregg(dt) end
end

function FoodManager:_checkCollections()
  for _, item in ipairs(self._items) do
    if not item.collected then
      local ib = item
      local function overlapsCtrl(ctrl)
        local cb = ctrl:getBounds()
        return cb.x < ib.x + ib.w and cb.x + cb.w > ib.x
           and cb.y < ib.y + ib.h and cb.y + cb.h > ib.y
      end
      if not self._p1.character.isDefeated and overlapsCtrl(self._ctrl1) then
        item.collected = true
        self._p1.character:heal(FOOD_HEAL)
      elseif not self._p2.character.isDefeated and overlapsCtrl(self._ctrl2) then
        item.collected = true
        self._p2.character:heal(FOOD_HEAL)
      end
    end
  end
end

function FoodManager:_updateGregg(dt)
  local g = self._gregg

  g._walkTimer = g._walkTimer + dt

  if g.state == "WANDER" then
    g.x = g.x + g.dir * GREGG_SPEED * dt
    if g.x < 5  then g.dir =  1 end
    if g.x > 450 then g.dir = -1 end
    -- Seek food if available
    if #self._items > 0 then
      local best, bestD = nil, math.huge
      for _, item in ipairs(self._items) do
        if not item.collected then
          local d = math.abs(item.x - g.x)
          if d < bestD then best = item; bestD = d end
        end
      end
      if best then
        g._targetFood = best
        g.state = "SEEK"
      end
    end

  elseif g.state == "SEEK" then
    if not g._targetFood or g._targetFood.collected then
      g.state = "WANDER"; g._targetFood = nil; return
    end
    local dx = g._targetFood.x - g.x
    g.dir = dx > 0 and 1 or -1
    g.x = g.x + g.dir * GREGG_SPEED * 1.5 * dt
    local gb = { x=g.x, y=g.y, w=g.w, h=g.h }
    local fb = g._targetFood
    if AS.overlaps(gb, fb) then
      g._targetFood.collected = true
      g._targetFood = nil
      g.state = "EAT"
      g._timer = 0.8
    end

  elseif g.state == "EAT" then
    g._timer = g._timer - dt
    if g._timer <= 0 then
      g.state      = "FART"
      g._timer     = 1.1
      g._fartAlpha = 1.0
    end

  elseif g.state == "FART" then
    g._timer     = g._timer - dt
    g._fartAlpha = math.max(0, g._timer)
    if g._timer <= 0 then
      local d1 = math.abs(self._ctrl1.x - g.x)
      local d2 = math.abs(self._ctrl2.x - g.x)
      local targetName, targetCtrl
      if d1 <= d2 then
        targetName  = self._p1.stats.characterName
        targetCtrl  = self._ctrl1
      else
        targetName  = self._p2.stats.characterName
        targetCtrl  = self._ctrl2
      end
      g._blameText = BLAME_BY_NAME[targetName]
          or BLAME_FALLBACK[math.random(#BLAME_FALLBACK)]
      g._strutDir  = targetCtrl.x > g.x and -1 or 1
      g._fartAlpha = 0.45
      g.state      = "BLAME"
      g._timer     = 2.0
    end

  elseif g.state == "BLAME" then
    g._timer     = g._timer - dt
    g._fartAlpha = math.max(0, g._timer * 0.2)
    if g._timer <= 0 then
      g.state      = "STRUT"
      g._timer     = 1.4
      g._blameText = nil
      g._fartAlpha = 0
    end

  elseif g.state == "STRUT" then
    g.dir    = g._strutDir   -- face the direction of travel
    g._timer = g._timer - dt
    g.x = g.x + g._strutDir * GREGG_SPEED * 1.7 * dt
    if g._timer <= 0 then
      g.state  = "LEAVE"
      g._timer = 3.0
    end

  elseif g.state == "LEAVE" then
    g._timer = g._timer - dt
    g.x = g.x + g._strutDir * GREGG_SPEED * 2.8 * dt
    if g.x < -60 or g.x > 540 or g._timer <= 0 then
      self._gregg = nil
      return
    end
  end
end

-- ── draw ─────────────────────────────────────────────────────────────────────

function FoodManager:draw()
  for _, item in ipairs(self._items) do
    if not item.collected then FR.draw(item) end
  end
  if self._gregg then self:_drawGregg() end

  if self._announceTimer > 0 then
    local alpha = math.min(1, self._announceTimer * 1.2)
    love.graphics.setColor(0.2, 1.0, 0.5, alpha)
    love.graphics.printf(self._announce or "", 0, 148, 480, "center")
  end
end

function FoodManager:_drawGregg()
  local g = self._gregg
  local x, y = g.x, g.y

  -- Fart cloud (behind Gregg)
  if g._fartAlpha and g._fartAlpha > 0 then
    local cloudX = g.dir > 0 and (x - 14) or (x + GREGG_W + 2)
    love.graphics.setColor(0.35, 0.78, 0.25, g._fartAlpha * 0.7)
    love.graphics.rectangle("fill", cloudX,     y + GREGG_H - 16, 18, 10)
    love.graphics.rectangle("fill", cloudX + 2, y + GREGG_H - 24, 12,  9)
    love.graphics.rectangle("fill", cloudX + 4, y + GREGG_H - 31,  8,  8)
  end

  -- Pixel art sprite
  love.graphics.setColor(1, 1, 1)
  KS.drawGregg(g)

  -- "NOM NOM!" while eating
  if g.state == "EAT" then
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.printf("NOM NOM!", x - 22, y - 16, GREGG_W + 44, "center")
  end

  -- Smug strut face
  if g.state == "STRUT" or g.state == "LEAVE" then
    love.graphics.setColor(0, 1, 0.5)
    love.graphics.printf(":)", x - 10, y - 14, GREGG_W + 20, "center")
  end

  -- Name tag
  love.graphics.setColor(0.85, 0.4, 1)
  love.graphics.printf("GREGG", x - 22, y - 14, GREGG_W + 44, "center")

  -- Blame speech bubble
  if g._blameText then
    love.graphics.setColor(1, 0.15, 0.15)
    love.graphics.printf(g._blameText, x - 70, y - 30, GREGG_W + 140, "center")
  end
end

return FoodManager
