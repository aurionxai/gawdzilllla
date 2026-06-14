-- src/city.lua
local AS = require("src/attack_system")

local City = {}
City.__index = City

function City.new(cityDef)
  local self = setmetatable({ buildings = {} }, City)
  self.name  = cityDef and cityDef.name or "Unknown City"
  self.skyC  = cityDef and cityDef.skyC or {0.08, 0.10, 0.20}
  self.gndC  = cityDef and cityDef.gndC or {0.22, 0.20, 0.18}

  local defs = cityDef and cityDef.buildings or {}
  for _, d in ipairs(defs) do
    local hp = d.w * 2
    table.insert(self.buildings, {
      x=d.x, y=d.y, w=d.w, h=d.h,
      health=hp, maxHealth=hp,
      isDestroyed=false,
      dollarsValue=5000000,
    })
  end
  return self
end

function City:checkHits(attackSystem, attackerCtrl, spawner)
  local boxes = attackSystem:getHitboxes(attackerCtrl.x, attackerCtrl.y, attackerCtrl.facingRight)
  for _, b in ipairs(self.buildings) do
    if not b.isDestroyed then
      local bb = { x=b.x, y=b.y, w=b.w, h=b.h }
      for _, hb in ipairs(boxes) do
        if AS.overlaps(hb, bb) then
          b.health = math.max(0, b.health - hb.damage)
          if b.health <= 0 then
            b.isDestroyed = true
            if spawner then spawner:registerSplat("Building", b.dollarsValue) end
          end
          break
        end
      end
    end
  end
end

function City:draw()
  for _, b in ipairs(self.buildings) do
    if b.isDestroyed then
      -- Rubble pile
      love.graphics.setColor(0.38, 0.30, 0.22)
      love.graphics.rectangle("fill", b.x, b.y + b.h - 10, b.w, 10)
      love.graphics.setColor(0.50, 0.40, 0.30)
      love.graphics.rectangle("fill", b.x + 3, b.y + b.h - 17, b.w * 0.45, 8)
      love.graphics.rectangle("fill", b.x + b.w * 0.5, b.y + b.h - 14, b.w * 0.35, 5)
    else
      local pct = b.health / b.maxHealth

      -- Building fill: blue-gray intact → brown damaged → dark red near-collapse
      if pct > 0.6 then
        love.graphics.setColor(0.40, 0.43, 0.60)
      elseif pct > 0.3 then
        love.graphics.setColor(0.52, 0.38, 0.28)
      else
        love.graphics.setColor(0.48, 0.22, 0.18)
      end
      love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)

      -- Outline so buildings pop against the dark sky
      love.graphics.setColor(0.70, 0.73, 0.88)
      love.graphics.rectangle("line", b.x, b.y, b.w, b.h)

      -- Windows (deterministic, no math.random in draw)
      for wy = b.y + 6, b.y + b.h - 10, 10 do
        for wx = b.x + 4, b.x + b.w - 8, 7 do
          local slot = math.floor((wx - b.x + wy - b.y) / 7)
          local lit = pct > 0.6
                   or (pct > 0.3 and slot % 3 ~= 0)
                   or (pct <= 0.3 and slot % 2 == 0)
          if lit then
            if pct > 0.6 then
              love.graphics.setColor(0.95, 0.92, 0.52)   -- yellow: normal
            elseif pct > 0.3 then
              love.graphics.setColor(1.00, 0.55, 0.15)   -- orange: fire
            else
              love.graphics.setColor(1.00, 0.25, 0.05)   -- red: inferno
            end
            love.graphics.rectangle("fill", wx, wy, 4, 5)
          end
        end
      end

      -- Damage health bar (only when not full health)
      if pct < 1.0 then
        love.graphics.setColor(0.15, 0.15, 0.15)
        love.graphics.rectangle("fill", b.x, b.y - 5, b.w, 3)
        if pct > 0.5 then
          love.graphics.setColor(0.20, 0.80, 0.20)
        elseif pct > 0.25 then
          love.graphics.setColor(0.90, 0.70, 0.10)
        else
          love.graphics.setColor(0.90, 0.20, 0.10)
        end
        love.graphics.rectangle("fill", b.x, b.y - 5, b.w * pct, 3)
      end
    end
  end
end

return City
