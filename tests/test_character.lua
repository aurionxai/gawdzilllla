-- tests/test_character.lua
local R    = require("tests/runner")
local Char = require("src/character")

local function makeChar(maxHp)
  return Char.new({ maxHealth = maxHp or 100, moveSpeed = 5 })
end

print("\n-- character.lua --")

R.test("takeDamage reduces health", function()
  local c = makeChar()
  c:takeDamage(30)
  R.eq(c.health, 70)
end)

R.test("takeDamage cannot go below zero", function()
  local c = makeChar()
  c:takeDamage(999)
  R.eq(c.health, 0)
  R.ok(c.isDefeated)
end)

R.test("takeDamage does nothing when invincible", function()
  local c = makeChar()
  c.isInvincible = true
  c:takeDamage(50)
  R.eq(c.health, 100)
end)

R.test("takeDamage doubles in counter state and resets counter", function()
  local c = makeChar()
  c.isCounterState = true
  c:takeDamage(20)
  R.eq(c.health, 60)
  R.notok(c.isCounterState)
end)

R.test("gainPower increases meter", function()
  local c = makeChar()
  c:gainPower(30)
  R.eq(c.power, 30)
end)

R.test("gainPower caps at 100", function()
  local c = makeChar()
  c:gainPower(200)
  R.eq(c.power, 100)
  R.ok(c:isPowerFull())
end)

R.test("gainPower fires onPowerFull only on 0->full transition", function()
  local c = makeChar()
  local fired = 0
  c.onPowerFull = function() fired = fired + 1 end
  c:gainPower(100)
  R.eq(fired, 1)
  c:gainPower(50)
  R.eq(fired, 1)
end)

R.test("spendPower reduces meter", function()
  local c = makeChar()
  c:gainPower(50)
  c:spendPower(25)
  R.eq(c.power, 25)
end)

R.test("resetForNewRound restores all state", function()
  local c = makeChar()
  c:takeDamage(80)
  c:gainPower(60)
  c.isInvincible   = true
  c.isCounterState = true
  c:resetForNewRound()
  R.eq(c.health, 100)
  R.eq(c.power, 0)
  R.notok(c.isDefeated)
  R.notok(c.isInvincible)
  R.notok(c.isCounterState)
end)
