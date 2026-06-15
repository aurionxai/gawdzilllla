-- src/attack_system.lua
local AS = {}
AS.__index = AS

local COMBO_WINDOW       = 1.5   -- seconds
local COMBO_EXTRA_POWER  = 3     -- bonus power at 5-hit combo milestone

function AS.new(character, attacks)
  return setmetatable({
    character      = character,
    attacks        = attacks,   -- table with keys: light, heavy, special, unleash
    isAttacking    = false,
    _phase         = nil,       -- "startup" | "active" | "recovery"
    _timer         = 0,
    _activeData    = nil,
    _hitboxes      = {},        -- list of {offsetX, w, h, damage, powerGain, stunDuration}
    comboCount     = 0,
    _comboTimer    = 0,
    onSpecialFired = nil,       -- callback() when special successfully fires
  }, AS)
end

function AS:performLight()    self:_startAttack(self.attacks.light) end
function AS:performHeavy()    self:_startAttack(self.attacks.heavy) end

function AS:performSpecial()
  local sp = self.attacks.special
  if self.character.power < sp.powerCost then return end
  self.character:spendPower(sp.powerCost)
  self:_startAttack(sp)
  if self.onSpecialFired then self.onSpecialFired() end
end

function AS:performUnleash()
  if not self.character:isPowerFull() then return end
  self.character:spendPower(100)
  self:_startAttack(self.attacks.unleash)
end

function AS:_startAttack(data)
  if self.isAttacking then return end
  self.isAttacking = true
  self._activeData = data
  self._phase      = "startup"
  self._timer      = data.startupTime
end

function AS:update(dt)
  -- Combo window countdown
  if self._comboTimer > 0 then
    self._comboTimer = self._comboTimer - dt
    if self._comboTimer <= 0 then
      self.comboCount = 0
    end
  end

  if not self.isAttacking then return end

  self._timer = self._timer - dt

  if self._phase == "startup" and self._timer <= 0 then
    local d = self._activeData
    self._hitboxes = {{ offsetX=d.hitboxOffX, w=d.hitboxW, h=d.hitboxH,
                        damage=d.damage, powerGain=d.powerGain, stunDuration=d.stunDuration }}
    self._phase = "active"
    self._timer = d.activeTime

  elseif self._phase == "active" and self._timer <= 0 then
    self._hitboxes = {}
    -- Combo tracking
    self._comboTimer = COMBO_WINDOW
    self.comboCount  = self.comboCount + 1
    if self.comboCount == 5 then
      self.character:gainPower(COMBO_EXTRA_POWER)
    end
    self._phase = "recovery"
    self._timer = self._activeData.recoveryTime

  elseif self._phase == "recovery" and self._timer <= 0 then
    self.isAttacking = false
    self._phase      = nil
    self._activeData = nil
  end
end

-- Returns world-space hitbox rects given character world position and facing.
function AS:getHitboxes(cx, cy, facingRight)
  local result = {}
  local dir    = facingRight and 1 or -1
  for _, hb in ipairs(self._hitboxes) do
    table.insert(result, {
      x            = cx + hb.offsetX * dir - hb.w / 2,
      y            = cy - hb.h / 2,
      w            = hb.w,
      h            = hb.h,
      damage       = hb.damage,
      powerGain    = hb.powerGain,
      stunDuration = hb.stunDuration,
    })
  end
  return result
end

-- AABB overlap check utility
function AS.overlaps(a, b)
  return a.x < b.x + b.w and a.x + a.w > b.x
     and a.y < b.y + b.h and a.y + a.h > b.y
end

return AS
