-- tests/test_npc_spawner.lua
local R       = require("tests/runner")
local Spawner = require("src/npc_spawner")

print("\n-- npc_spawner.lua --")

R.test("registerSplat accumulates dollars", function()
  local s = Spawner.new()
  s:registerSplat("Human", 1000)
  s:registerSplat("Police", 2000)
  R.eq(s:getDestructionScore(), 3000)
end)

R.test("registerSplat counts total splats", function()
  local s = Spawner.new()
  s:registerSplat("Human", 500)
  s:registerSplat("Human", 500)
  R.eq(s:getSplatCount(), 2)
end)

R.test("streak fires when 5 splats within window", function()
  local s = Spawner.new()
  local streakFired = 0
  s.onSplatStreak = function() streakFired = streakFired + 1 end
  for i = 1, 5 do
    s:registerSplat("Human", 100)
    -- Don't advance time so timer stays active
  end
  R.eq(streakFired, 1)
end)
