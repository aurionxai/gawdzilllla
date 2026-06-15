-- src/controller.lua
local Ctrl    = {}
Ctrl.__index  = Ctrl

local GRAVITY     = 800
local GROUND_Y    = 220
local JUMP_VY     = -420
local CLIMB_SPEED = 52   -- pixels/sec upward while hugging a wall

Ctrl.GROUND_Y  = GROUND_Y

function Ctrl.new(character, x, y)
  return setmetatable({
    character      = character,
    x              = x,
    y              = y or GROUND_Y,
    prevY          = y or GROUND_Y,
    vx             = 0,
    vy             = 0,
    isGrounded     = (y == nil or y >= GROUND_Y),
    isStunned      = false,
    stunTimer      = 0,
    facingRight    = true,
    width          = 28,
    height         = 44,
    isCrouching    = false,
    _walkTimer     = 0,
    _knockbackVX   = 0,
    _onWall        = nil,
    _levelW        = 480,   -- overridden by city_assault for wide levels
  }, Ctrl)
end

function Ctrl:update(dt, moveX, buildings)
  self.prevY = self.y

  -- Stun countdown
  if self.stunTimer > 0 then
    self.stunTimer = self.stunTimer - dt
    if self.stunTimer <= 0 then
      self.isStunned = false
      self.stunTimer = 0
    end
  end

  -- Intended horizontal velocity
  if self.isStunned or self.character.isDefeated then
    self.vx          = self._knockbackVX
    self._knockbackVX = self._knockbackVX * math.max(0, 1 - dt * 6)
  else
    self._knockbackVX = 0
    self.vx = (moveX or 0) * self.character.stats.moveSpeed
    if moveX and moveX ~= 0 then
      self.facingRight = moveX > 0
    end
  end

  -- PHASE 1: Horizontal movement (kaiju walk THROUGH buildings — no wall blocking)
  self.x        = self.x + self.vx * dt
  self._onWall  = nil
  local hw      = self.width / 2

  -- PHASE 2: Vertical velocity
  if self._onWall then
    -- Climbing: override gravity, crawl upward
    self.vy        = -CLIMB_SPEED
    self.isGrounded = false
  else
    if not self.isGrounded then
      self.vy = self.vy + GRAVITY * dt
    end
  end
  self.y = self.y + self.vy * dt

  -- Walk animation (only while moving on ground)
  if self.isGrounded and math.abs(self.vx) > 5 then
    self._walkTimer = self._walkTimer + dt * 8
  end

  -- PHASE 3: Vertical collision — ground, building tops, climbing-to-top
  local effectiveGround = GROUND_Y
  if buildings then
    for _, b in ipairs(buildings) do
      if not b.isDestroyed then
        if self.x + hw > b.x and self.x - hw < b.x + b.w then
          local top = b.y
          local landingFall  = self.prevY <= top + 2 and self.y >= top
          local restingOnTop = math.abs(self.y - top) <= 2 and self.isGrounded
          local climbedToTop = self._onWall ~= nil and self.y <= top + 4
          if landingFall or restingOnTop or climbedToTop then
            if top < effectiveGround then effectiveGround = top end
          end
        end
      end
    end
  end

  if self.y >= effectiveGround then
    self.y          = effectiveGround
    self.vy         = 0
    self.isGrounded = true
    self._onWall    = nil   -- released from wall on landing
  else
    self.isGrounded = false
  end

  self.x = math.max(hw, math.min(self._levelW - hw, self.x))
end

function Ctrl:jump()
  if self._onWall then
    -- Wall-launch: burst upward and away from the wall
    self.vy          = JUMP_VY * 0.65
    self._onWall     = nil
    self.isGrounded  = false
  elseif self.isGrounded then
    self.vy          = JUMP_VY
    self.isGrounded  = false
  end
end

function Ctrl:applyStun(duration)
  self.isStunned = true
  self.stunTimer = math.max(self.stunTimer, duration)
end

function Ctrl:applyKnockback(vx, vy)
  self._knockbackVX = vx
  if vy and vy < 0 then
    self.vy         = vy
    self.isGrounded = false
    self._onWall    = nil
  end
end

function Ctrl:getBounds()
  return { x = self.x - self.width/2, y = self.y - self.height, w = self.width, h = self.height }
end

function Ctrl:draw(color, sprite)
  local img
  if type(sprite) == "table" then
    if self._onWall then
      -- Climbing: use frame 2 (spread/jump pose)
      img = sprite[3] or sprite[1]
    elseif not self.isGrounded then
      img = sprite[3] or sprite[1]
    elseif math.abs(self.vx) > 5 then
      local step = math.floor(self._walkTimer) % 2
      img = sprite[step + 1] or sprite[1]
    else
      img = sprite[1]
    end
  else
    img = sprite
  end

  if img then
    local sw, sh = img:getDimensions()
    local flip   = self.facingRight and 1 or -1
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, self.x, self.y, 0, flip, 1, sw / 2, sh)
  else
    local b = self:getBounds()
    love.graphics.setColor(color or {1,1,1})
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
    local eyeX = self.facingRight and (b.x + b.w * 0.7) or (b.x + b.w * 0.3)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", eyeX - 2, b.y + 8, 4, 4)
  end
end

return Ctrl
