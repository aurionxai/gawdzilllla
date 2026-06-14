-- src/blood_pool.lua
-- Object pool of blood splat particles (colored rectangles, no love.graphics.ParticleSystem needed)
local Pool   = {}
Pool.__index = Pool

local POOL_SIZE = 30

local Particle = {}
Particle.__index = Particle

function Particle.new()
  return setmetatable({ active=false, x=0, y=0, timer=0, vx=0, vy=0, size=4 }, Particle)
end

function Pool.new()
  local self = setmetatable({ _particles={} }, Pool)
  for i = 1, POOL_SIZE do
    table.insert(self._particles, Particle.new())
  end
  return self
end

function Pool:spawn(x, y)
  -- Spawn 5 particles per stomp
  local count = 0
  for _, p in ipairs(self._particles) do
    if not p.active then
      p.active = true
      p.x      = x + math.random(-4, 4)
      p.y      = y + math.random(-4, 4)
      p.vx     = math.random(-60, 60)
      p.vy     = math.random(-80, -20)
      p.timer  = 0.4 + math.random() * 0.3
      p.size   = math.random(2, 5)
      count    = count + 1
      if count >= 5 then break end
    end
  end
end

function Pool:update(dt)
  for _, p in ipairs(self._particles) do
    if p.active then
      p.timer = p.timer - dt
      if p.timer <= 0 then
        p.active = false
      else
        p.vy = p.vy + 300 * dt   -- gravity on particles
        p.x  = p.x + p.vx * dt
        p.y  = p.y + p.vy * dt
      end
    end
  end
end

function Pool:draw()
  love.graphics.setColor(0.8, 0.05, 0.05)
  for _, p in ipairs(self._particles) do
    if p.active then
      love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end
  end
end

return Pool
