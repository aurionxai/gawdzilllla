-- src/city.lua
local AS = require("src/attack_system")

local City = {}
City.__index = City

local GROUND_Y = 220
local GRAVITY  = 280

function City.new(cityDef)
  local self = setmetatable({ buildings = {}, fallers = {} }, City)
  self.name  = cityDef and cityDef.name or "Unknown City"
  self.skyC  = cityDef and cityDef.skyC or {0.08, 0.10, 0.20}
  self.gndC  = cityDef and cityDef.gndC or {0.22, 0.20, 0.18}
  -- Set by battle after init: self._audio, self._pool, self._spawner
  self._audio   = nil
  self._pool    = nil
  self._spawner = nil

  local defs = cityDef and cityDef.buildings or {}
  for _, d in ipairs(defs) do
    local hp = d.w
    table.insert(self.buildings, {
      x=d.x, y=d.y, w=d.w, h=d.h,
      health=hp, maxHealth=hp,
      isDestroyed=false,
      dollarsValue=5000000,
    })
  end
  return self
end

local function windowSlot(wx, wy, bx, by)
  return math.floor((wx - bx + wy - by) / 7)
end

local function spawnFallers(fallers, b)
  for wy = b.y + 6, b.y + b.h - 10, 10 do
    for wx = b.x + 4, b.x + b.w - 8, 7 do
      local slot = windowSlot(wx, wy, b.x, b.y)
      if slot % 4 == 1 then
        -- One person per qualifying window
        fallers[#fallers + 1] = {
          x   = wx + 2,
          y   = wy + 2,
          vx  = (math.random() * 2 - 1) * 30,
          vy  = -15 - math.random() * 35,
          rot = 0,
          rotV = (math.random() * 2 - 1) * 8,
          done = false,
        }
      end
    end
  end
end

function City:checkHits(attackSystem, attackerCtrl, spawner)
  local boxes = attackSystem:getHitboxes(attackerCtrl.x, attackerCtrl.y, attackerCtrl.facingRight)
  local anyHit = false
  for _, b in ipairs(self.buildings) do
    if not b.isDestroyed then
      local bb = { x=b.x, y=b.y, w=b.w, h=b.h }
      for _, hb in ipairs(boxes) do
        if AS.overlaps(hb, bb) then
          b.health = math.max(0, b.health - hb.damage)
          b._shakeTimer = 0.25
          anyHit = true
          -- Scream on every hit (not collapse)
          if b.health > 0 and self._audio then
            self._audio:playScream()
          end
          if b.health <= 0 then
            b.isDestroyed = true
            b._rubbleTimer = 0
            if spawner then spawner:registerSplat("Building", b.dollarsValue) end
            if self._audio then
              self._audio:playCollapse()
              self._audio:playCrowdPanic()
            end
            spawnFallers(self.fallers, b)
          end
          break
        end
      end
    end
  end
  return anyHit
end

function City:update(dt)
  for _, b in ipairs(self.buildings) do
    if b._shakeTimer and b._shakeTimer > 0 then
      b._shakeTimer = b._shakeTimer - dt
    end
    if b._rubbleTimer then
      b._rubbleTimer = b._rubbleTimer + dt
    end
  end

  -- Update fallers
  for _, f in ipairs(self.fallers) do
    if not f.done then
      f.vy  = f.vy + GRAVITY * dt
      f.x   = f.x + f.vx * dt
      f.y   = f.y + f.vy * dt
      f.rot = f.rot + f.rotV * dt
      if f.y >= GROUND_Y - 2 then
        f.y    = GROUND_Y - 2
        f.done = true
        if self._audio   then self._audio:playRandomSplat() end
        if self._pool    then self._pool:spawn(f.x, GROUND_Y) end
        if self._spawner then self._spawner:registerSplat("NPC", 50000) end
      end
    end
  end
end

function City:draw()
  -- Draw buildings
  for _, b in ipairs(self.buildings) do
    local ox, oy = 0, 0
    if b._shakeTimer and b._shakeTimer > 0 then
      local mag = b._shakeTimer * 3
      ox = math.floor(math.sin(b._shakeTimer * 80) * mag)
      oy = math.floor(math.cos(b._shakeTimer * 60) * mag * 0.5)
    end

    if b.isDestroyed then
      local rt = b._rubbleTimer or 99
      if rt < 0.8 then
        local alpha = 1 - rt / 0.8
        love.graphics.setColor(0.7, 0.65, 0.55, alpha * 0.7)
        love.graphics.rectangle("fill", b.x - 8, b.y, b.w + 16, b.h * 0.6)
      end
      love.graphics.setColor(0.38, 0.30, 0.22)
      love.graphics.rectangle("fill", b.x, b.y + b.h - 10, b.w, 10)
      love.graphics.setColor(0.50, 0.40, 0.30)
      love.graphics.rectangle("fill", b.x + 3, b.y + b.h - 17, b.w * 0.45, 8)
      love.graphics.rectangle("fill", b.x + b.w * 0.5, b.y + b.h - 14, b.w * 0.35, 5)
    else
      local pct = b.health / b.maxHealth
      local bx, by = b.x + ox, b.y + oy

      if pct > 0.6 then
        love.graphics.setColor(0.40, 0.43, 0.60)
      elseif pct > 0.3 then
        love.graphics.setColor(0.52, 0.38, 0.28)
      else
        love.graphics.setColor(0.48, 0.22, 0.18)
      end
      love.graphics.rectangle("fill", bx, by, b.w, b.h)

      love.graphics.setColor(0.70, 0.73, 0.88)
      love.graphics.rectangle("line", bx, by, b.w, b.h)

      -- Windows + people
      for wy = by + 6, by + b.h - 10, 10 do
        for wx = bx + 4, bx + b.w - 8, 7 do
          local slot = windowSlot(wx, wy, bx, by)
          local lit = pct > 0.6
                   or (pct > 0.3 and slot % 3 ~= 0)
                   or (pct <= 0.3 and slot % 2 == 0)
          if lit then
            if pct > 0.6 then
              love.graphics.setColor(0.95, 0.92, 0.52)
            elseif pct > 0.3 then
              love.graphics.setColor(1.00, 0.55, 0.15)
            else
              love.graphics.setColor(1.00, 0.25, 0.05)
            end
            love.graphics.rectangle("fill", wx, wy, 4, 5)

            -- Person silhouette in this window
            if slot % 4 == 1 then
              love.graphics.setColor(0.04, 0.04, 0.06)
              if pct > 0.6 then
                -- Standing calmly
                love.graphics.rectangle("fill", wx + 1, wy,     2, 2)  -- head
                love.graphics.rectangle("fill", wx + 1, wy + 2, 2, 3)  -- body
              elseif pct > 0.3 then
                -- Arms up in panic
                love.graphics.rectangle("fill", wx + 1, wy,     2, 2)  -- head
                love.graphics.rectangle("fill", wx + 1, wy + 2, 2, 2)  -- body
                love.graphics.rectangle("fill", wx,     wy + 1, 1, 2)  -- left arm up
                love.graphics.rectangle("fill", wx + 3, wy + 1, 1, 2)  -- right arm up
              else
                -- Waving frantically (arms wide)
                love.graphics.rectangle("fill", wx + 1, wy,     2, 2)  -- head
                love.graphics.rectangle("fill", wx + 1, wy + 2, 2, 2)  -- body
                love.graphics.rectangle("fill", wx,     wy + 2, 1, 1)  -- left arm
                love.graphics.rectangle("fill", wx + 3, wy + 2, 1, 1)  -- right arm
              end
            end
          end
        end
      end

      if pct < 1.0 then
        love.graphics.setColor(0.15, 0.15, 0.15)
        love.graphics.rectangle("fill", bx, by - 5, b.w, 3)
        if pct > 0.5 then
          love.graphics.setColor(0.20, 0.80, 0.20)
        elseif pct > 0.25 then
          love.graphics.setColor(0.90, 0.70, 0.10)
        else
          love.graphics.setColor(0.90, 0.20, 0.10)
        end
        love.graphics.rectangle("fill", bx, by - 5, b.w * pct, 3)
      end
    end
  end

  -- Draw falling people
  for _, f in ipairs(self.fallers) do
    if not f.done then
      love.graphics.push()
      love.graphics.translate(math.floor(f.x), math.floor(f.y))
      love.graphics.rotate(f.rot)
      love.graphics.setColor(0.08, 0.06, 0.04)
      love.graphics.rectangle("fill", -1, -4, 2, 2)  -- head
      love.graphics.rectangle("fill", -1, -2, 2, 3)  -- body
      love.graphics.rectangle("fill", -2, -1, 1, 1)  -- left arm
      love.graphics.rectangle("fill",  2, -1, 1, 1)  -- right arm
      love.graphics.pop()
    end
  end
end

return City
