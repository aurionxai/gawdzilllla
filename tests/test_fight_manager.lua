-- tests/test_fight_manager.lua
local R    = require("tests/runner")
local Char = require("src/character")
local FM   = require("src/fight_manager")

print("\n-- fight_manager.lua --")

local function makeChars()
  local c1 = Char.new({ maxHealth=100, moveSpeed=5 })
  local c2 = Char.new({ maxHealth=100, moveSpeed=5 })
  return c1, c2
end

R.test("startMatch resets round counts", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  fm:startMatch()
  R.eq(fm.p1RoundsWon, 0)
  R.eq(fm.p2RoundsWon, 0)
  R.eq(fm.currentRound, 1)
  R.ok(fm.roundActive)
end)

R.test("P2 wins round when P1 defeated", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  local winner = nil
  fm.onRoundEnd = function(w) winner = w end
  fm:startMatch()
  c1:takeDamage(999)
  fm:update(0)   -- one frame to detect defeat
  R.eq(winner, 2)
  R.eq(fm.p2RoundsWon, 1)
end)

R.test("time out winner is player with more health", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=1 })
  local winner = nil
  fm.onRoundEnd = function(w) winner = w end
  fm:startMatch()
  c2:takeDamage(50)      -- P2 lower health
  fm:update(2)           -- past roundDuration=1
  R.eq(winner, 1)        -- P1 wins by health
end)

R.test("match ends when player wins majority", function()
  local c1, c2 = makeChars()
  -- totalRounds=3, need 2 wins (ceil(3/2)) to win match
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  local matchWinner = nil
  fm.onMatchEnd = function(w) matchWinner = w end
  fm:startMatch()

  -- P1 wins round 1
  c2:takeDamage(999); fm:update(0)
  fm:_forceStartNextRound()  -- skip 2s delay for test

  -- P1 wins round 2
  c2:takeDamage(999); fm:update(0)

  R.eq(matchWinner, 1)
end)
