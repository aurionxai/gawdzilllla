-- src/controller.lua
local Ctrl    = {}
Ctrl.__index  = Ctrl

local GRAVITY  = 800   -- pixels/sec²
local GROUND_Y = 220   -- y where feet touch ground (in 480×270 reference space)
local JUMP_VY  = -420  -- initial upward velocity on jump

Ctrl.GROUND_Y  = GROUND_Y  -- expose so battle.lua can place characters

function Ctrl.new(character, x, y)
  return setmetatable({
    character   = character,
    x           = x,
    y           = y or GROUND_Y,
    vx          = 0,
    vy          = 0,
    isGrounded  = (y == nil or y >= GROUND_Y),
    isStunned   = false,
    stunTimer   = 0,
    facingRight = true,
    width       = 28,
    height      = 44,
  }, Ctrl)
end

function Ctrl:update(dt, moveX)
  -- Stun countdown
  if self.stunTimer > 0 then
    self.stunTimer = self.stunTimer - dt
    if self.stunTimer <= 0 then
      self.isStunned = false
      self.stunTimer = 0
    end
  end

  if self.isStunned or self.character.isDefeated then
    self.vx = 0
  else
    self.vx = (moveX or 0) * self.character.stats.moveSpeed
    if moveX and moveX ~= 0 then
      self.facingRight = moveX > 0
    end
  end

  -- Gravity
  if not self.isGrounded then
    self.vy = self.vy + GRAVITY * dt
  end

  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt

  -- Ground
  if self.y >= GROUND_Y then
    self.y         = GROUND_Y
    self.vy        = 0
    self.isGrounded = true
  else
    self.isGrounded = false
  end

  -- Horizontal bounds (480 ref width, padding = half width)
  local hw = self.width / 2
  self.x = math.max(hw, math.min(480 - hw, self.x))
end

function Ctrl:jump()
  if self.isGrounded then
    self.vy        = JUMP_VY
    self.isGrounded = false
  end
end

function Ctrl:applyStun(duration)
  self.isStunned = true
  self.stunTimer = math.max(self.stunTimer, duration)
end

-- Returns AABB rect { x, y, w, h } in world space (top-left origin)
function Ctrl:getBounds()
  return { x = self.x - self.width/2, y = self.y - self.height, w = self.width, h = self.height }
end

-- Draw placeholder rectangle (colored rect = character sprite stand-in)
function Ctrl:draw(color)
  local b = self:getBounds()
  love.graphics.setColor(color or {1,1,1})
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  -- eyes to show facing
  local eyeX = self.facingRight and (b.x + b.w * 0.7) or (b.x + b.w * 0.3)
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill", eyeX - 2, b.y + 8, 4, 4)
end

return Ctrl
