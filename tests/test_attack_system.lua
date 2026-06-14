-- tests/test_attack_system.lua
local R   = require("tests/runner")
local Char = require("src/character")
local AS   = require("src/attack_system")

print("\n-- attack_system.lua --")

local ATTACKS = {
  light   = { damage=10, powerGain=5,  powerCost=0,  stunDuration=0,   hitboxW=30, hitboxH=20, hitboxOffX=20, startupTime=0.1, activeTime=0.15, recoveryTime=0.2 },
  heavy   = { damage=25, powerGain=15, powerCost=0,  stunDuration=0.5, hitboxW=40, hitboxH=30, hitboxOffX=25, startupTime=0.25,activeTime=0.2,  recoveryTime=0.4 },
  special = { damage=20, powerGain=0,  powerCost=25, stunDuration=0.2, hitboxW=80, hitboxH=10, hitboxOffX=40, startupTime=0.3, activeTime=0.5,  recoveryTime=0.3 },
  unleash = { damage=40, powerGain=0,  powerCost=100,stunDuration=1,   hitboxW=200,hitboxH=40, hitboxOffX=50, startupTime=0.5, activeTime=1,    recoveryTime=0.5 },
}

local function makeAS(power)
  local c = Char.new({ maxHealth=100, moveSpeed=5 })
  if power then c.power = power end
  return AS.new(c, ATTACKS), c
end

R.test("performLight sets isAttacking", function()
  local a = makeAS()
  a:performLight()
  R.ok(a.isAttacking)
end)

R.test("performSpecial blocked when insufficient power", function()
  local a, c = makeAS(10)   -- needs 25
  a:performSpecial()
  R.notok(a.isAttacking)
  R.eq(c.power, 10)  -- power unchanged
end)

R.test("performSpecial spends power when sufficient", function()
  local a, c = makeAS(50)
  a:performSpecial()
  R.ok(a.isAttacking)
  R.eq(c.power, 25)  -- 50 - 25
end)

R.test("performUnleash blocked when not full", function()
  local a, c = makeAS(99)
  a:performUnleash()
  R.notok(a.isAttacking)
end)

R.test("update advances through startup→active→recovery→idle", function()
  local a = makeAS()
  a:performLight()
  R.ok(a.isAttacking)
  R.eq(a._phase, "startup")

  a:update(0.15)    -- past startupTime(0.1) → enters active, hitbox present
  R.eq(a._phase, "active")
  R.ok(#a:getHitboxes(100, 150, true) > 0)

  a:update(0.2)     -- past activeTime(0.15) → enters recovery, hitboxes cleared
  R.eq(a._phase, "recovery")
  R.eq(#a:getHitboxes(100, 150, true), 0)

  a:update(0.25)    -- past recoveryTime(0.2) → idle
  R.notok(a.isAttacking)
end)
