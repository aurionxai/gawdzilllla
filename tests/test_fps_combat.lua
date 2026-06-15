-- tests/test_fps_combat.lua
local R = require("tests/runner")
if not love then love = {} end

local Camera = require("src/fps/camera")
local Combat = require("src/fps/combat_fps")

print("\n-- fps/combat_fps.lua --")

local function enemy(x, y)
  return { x=x, y=y }
end

R.test("ranged hits enemy directly in front (east)", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkRangedHit(cam, enemy(200, 0), 600)
  R.ok(hit, "enemy at (200,0) is directly east — should hit")
end)

R.test("ranged misses enemy directly behind", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkRangedHit(cam, enemy(-200, 0), 600)
  R.notok(hit, "enemy at (-200,0) is directly behind — should miss")
end)

R.test("ranged misses enemy beyond max range", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkRangedHit(cam, enemy(700, 0), 600)
  R.notok(hit, "enemy at 700 beyond range 600 — should miss")
end)

R.test("ranged misses enemy more than 30° off axis", function()
  local cam = Camera.new(0, 0, 0)
  -- 90 degrees off axis (due south) — well outside the cone
  local hit = Combat.checkRangedHit(cam, enemy(0, 200), 600)
  R.notok(hit, "enemy 90° off-axis — outside cone")
end)

R.test("melee hits enemy within range", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkMeleeHit(cam, enemy(80, 10), 120)
  R.ok(hit, "enemy at dist ~81 within melee range 120")
end)

R.test("melee misses enemy out of range", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkMeleeHit(cam, enemy(200, 0), 120)
  R.notok(hit, "enemy at dist 200 outside melee range 120")
end)

R.test("tail hits enemy to the side", function()
  local cam = Camera.new(0, 0, 0)   -- facing east
  -- Due south — 90° off-axis, within range
  local hit = Combat.checkTailHit(cam, enemy(0, 100), 150)
  R.ok(hit, "enemy directly south — tail side arc should hit")
end)

R.test("tail does not hit enemy directly in front", function()
  local cam = Camera.new(0, 0, 0)
  local hit = Combat.checkTailHit(cam, enemy(100, 0), 150)
  R.notok(hit, "enemy directly east (in front) — outside tail arc")
end)

R.test("checkRangedHit returns distance as second value", function()
  local cam = Camera.new(0, 0, 0)
  local hit, dist = Combat.checkRangedHit(cam, enemy(200, 0), 600)
  R.ok(hit)
  R.approx(dist, 200, "distance to enemy")
end)
