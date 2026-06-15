-- src/cpu_controller.lua
-- Simple CPU AI: chase enemy, attack when close, jump over them occasionally
local CPU = {}
CPU.__index = CPU

local ATTACK_RANGE  = 60   -- px from center to trigger attack
local JUMP_CHANCE   = 0.25 -- probability per jump-decision tick
local REACT_INTERVAL = 0.18 -- seconds between AI decisions

function CPU.new()
  return setmetatable({
    _timer    = 0,
    _moveDir  = 0,
    _doJump   = false,
    _doAttack = false,
    _doSpecial = false,
    _specialTimer = 0,
  }, CPU)
end

-- Returns: moveX (-1/0/1), and sets flags _doJump / _doAttack / _doSpecial
function CPU:think(dt, selfCtrl, enemyCtrl)
  self._doJump   = false
  self._doAttack = false
  self._doSpecial = false

  self._timer = self._timer - dt
  self._specialTimer = self._specialTimer - dt

  if self._timer > 0 then return self._moveDir end

  self._timer = REACT_INTERVAL + math.random() * 0.12

  local dx = enemyCtrl.x - selfCtrl.x
  local dist = math.abs(dx)

  -- Move toward enemy
  if dist > ATTACK_RANGE then
    self._moveDir = dx > 0 and 1 or -1
  elseif dist < 20 then
    -- Too close: back off slightly
    self._moveDir = dx > 0 and -1 or 1
  else
    self._moveDir = 0
  end

  -- Attack if in range and grounded
  if dist <= ATTACK_RANGE and selfCtrl.isGrounded then
    self._doAttack = true
  end

  -- Occasionally fire special
  if self._specialTimer <= 0 and dist <= ATTACK_RANGE * 1.5 then
    self._doSpecial = true
    self._specialTimer = 8 + math.random() * 6
  end

  -- Random jump to avoid getting cornered or hop over enemy
  if selfCtrl.isGrounded and math.random() < JUMP_CHANCE then
    self._doJump = true
  end

  return self._moveDir
end

return CPU
