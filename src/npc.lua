-- src/npc.lua
local NPC   = {}
NPC.__index = NPC

function NPC.new(x, y, npcType, dollarsValue)
  return setmetatable({
    x            = x,
    y            = y,
    npcType      = npcType or "Human",
    dollarsValue = dollarsValue or 1000,
    isDead       = false,
    vx           = (math.random() > 0.5) and 25 or -25,
    wanderTimer  = math.random() * 2 + 1,
    width        = 8,
    height       = 12,
  }, NPC)
end

function NPC:update(dt)
  if self.isDead then return end
  self.wanderTimer = self.wanderTimer - dt
  if self.wanderTimer <= 0 then
    self.vx = -self.vx
    self.wanderTimer = math.random() * 2 + 1
  end
  self.x = math.max(4, math.min(476, self.x + self.vx * dt))
end

function NPC:stomp(bloodPool, spawner)
  if self.isDead then return end
  self.isDead = true
  if bloodPool then bloodPool:spawn(self.x, self.y) end
  if spawner   then spawner:registerSplat(self.npcType, self.dollarsValue) end
end

function NPC:getBounds()
  return { x=self.x - self.width/2, y=self.y - self.height, w=self.width, h=self.height }
end

function NPC:draw()
  if self.isDead then return end
  love.graphics.setColor(1, 0.85, 0.7)
  love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height, self.width, self.height)
  -- tiny head dot
  love.graphics.setColor(1, 0.7, 0.5)
  love.graphics.circle("fill", self.x, self.y - self.height - 3, 3)
end

return NPC
