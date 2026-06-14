-- tests/test_controller.lua
local R    = require("tests/runner")
local Char = require("src/character")
local Ctrl = require("src/controller")

print("\n-- controller.lua --")

local GROUND_Y = 220  -- must match controller.lua GROUND_Y

local function makeCtrl(x, y)
  local c = Char.new({ maxHealth=100, moveSpeed=80 })
  return Ctrl.new(c, x or 100, y or GROUND_Y), c
end

R.test("moveX applies velocity and moves position", function()
  local ctrl = makeCtrl(100, GROUND_Y)
  ctrl:update(1, 1)   -- 1 second, moving right at moveSpeed=80
  R.approx(ctrl.x, 180)  -- 100 + 80*1
end)

R.test("facingRight flips on negative moveX", function()
  local ctrl = makeCtrl()
  ctrl:update(0.1, -1)
  R.notok(ctrl.facingRight)
end)

R.test("gravity pulls character down when airborne", function()
  local ctrl = makeCtrl(100, 100)   -- y=100, above ground
  ctrl.isGrounded = false
  ctrl:update(0.1, 0)
  R.ok(ctrl.y > 100)
end)

R.test("ground clamp stops at GROUND_Y", function()
  local ctrl = makeCtrl(100, 100)
  ctrl.vy = 9999
  ctrl:update(1, 0)
  R.eq(ctrl.y, GROUND_Y)
  R.ok(ctrl.isGrounded)
end)
