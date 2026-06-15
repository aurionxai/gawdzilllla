-- src/fps/enemy_titan.lua
-- Ghidorah enemy AI: chases player, attacks at close range, shows damage states.

local EnemyTitan = {}
EnemyTitan.__index = EnemyTitan

-- Visual damage state thresholds (hp ratio → state name, eye color, move speed)
local DAMAGE_STATES = {
  { thresh=0.66, name="FULL",     eyes={1,0,0},       speed=80  },
  { thresh=0.33, name="HURT",     eyes={1,0.4,0},     speed=95  },
  { thresh=0.0,  name="CRITICAL", eyes={1,1,0},       speed=55  },
}

function EnemyTitan.new(x, y)
  return setmetatable({
    x = x, y = y,
    hp = 200, maxHp = 200,
    speed = 80,
    -- AI state machine
    state         = "CHASE",   -- CHASE | ATTACK | STUNNED | DEAD
    stunTimer     = 0,
    attackCooldown = 0,
    attackWindup  = 0,
    isAttacking   = false,     -- true for ONE frame when attack lands
    -- Visual
    damageState = "FULL",
    flashTimer  = 0,
  }, EnemyTitan)
end

function EnemyTitan:takeDamage(amount)
  self.hp = math.max(0, self.hp - amount)
  self.flashTimer = 0.18
  local ratio = self.hp / self.maxHp
  for _, ds in ipairs(DAMAGE_STATES) do
    if ratio >= ds.thresh then
      self.damageState = ds.name
      self.speed       = ds.speed
      break
    end
  end
  if self.hp <= 0 then self.state = "DEAD" end
end

-- Stuns the titan for `duration` seconds.
function EnemyTitan:stun(duration)
  if self.state == "DEAD" then return end
  self.state     = "STUNNED"
  self.stunTimer = duration
end

function EnemyTitan:update(dt, playerX, playerY)
  if self.state == "DEAD" then return end

  self.isAttacking   = false
  self.attackCooldown = math.max(0, self.attackCooldown - dt)
  self.flashTimer     = math.max(0, self.flashTimer - dt)

  if self.state == "STUNNED" then
    self.stunTimer = self.stunTimer - dt
    if self.stunTimer <= 0 then self.state = "CHASE" end
    return
  end

  local dx   = playerX - self.x
  local dy   = playerY - self.y
  local dist = math.sqrt(dx * dx + dy * dy)

  if self.state == "CHASE" then
    if dist < 90 and self.attackCooldown <= 0 then
      self.state       = "ATTACK"
      self.attackWindup = 0.7
      self.attackCooldown = 3.5
    elseif dist > 90 then
      -- Move toward player (simple linear chase, no pathfinding)
      if dist > 0 then
        self.x = self.x + (dx / dist) * self.speed * dt
        self.y = self.y + (dy / dist) * self.speed * dt
      end
    end

  elseif self.state == "ATTACK" then
    self.attackWindup = self.attackWindup - dt
    if self.attackWindup <= 0 then
      self.isAttacking = true   -- caller checks this flag each frame
      self.state       = "CHASE"
    end
  end
end

-- Returns projected screen height of the titan given perpendicular camera distance.
function EnemyTitan:getScreenSize(perpDist)
  if perpDist <= 0 then return 0 end
  return math.floor(270 * 100 / perpDist)
end

return EnemyTitan
