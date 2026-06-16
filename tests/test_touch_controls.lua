-- tests/test_touch_controls.lua
local R = require("tests/runner")
if not love then love = {} end

local TC = require("src/touch_controls")

print("\n-- touch_controls.lua --")

-- 1. Left zone: x < 192 is joystick zone
R.test("left zone: x < 192 is joystick zone", function()
  R.ok(TC.inJoystickZone(50, 200),   "x=50,y=200 is joystick zone")
  R.notok(TC.inJoystickZone(300, 200), "x=300,y=200 is NOT joystick zone")
end)

-- 2. Button zone: x > 288 is button zone
R.test("button zone: x > 288 is button zone", function()
  R.ok(TC.inButtonZone(400, 200),   "x=400,y=200 is button zone")
  R.notok(TC.inButtonZone(100, 200), "x=100,y=200 is NOT button zone")
end)

-- 3. hitButton returns nil outside button zone
R.test("hitButton returns nil outside button zone", function()
  R.eq(TC.hitButton(100, 200), nil, "x=100 not in button zone → nil")
end)

-- 4. hitButton: top-right cell = special
-- Button zone x: 288..480, BTN_W=96, BTN_H=67.5
-- right col (col=1): x in [288+96, 288+192] = [384,480]; center x = 288 + 96 + 48 = 432
-- top row (row=0): y in [135, 135+67.5] = [135,202.5]; center y = 135 + 67.5*0.25 ≈ 152
R.test("hitButton: top-right = special", function()
  local action = TC.hitButton(432, 152)
  R.eq(action, "special", "top-right cell should be special")
end)

-- 5. hitButton: bottom-left cell = heavy
-- left col (col=0): x in [288,384]; center x = 288 + 48 = 336
-- bottom row (row=1): y in [202.5,270]; center y = 135 + 67.5 + 67.5*0.5 = 135+67.5+33.75 = 236
R.test("hitButton: bottom-left = heavy", function()
  local action = TC.hitButton(336, 236)
  R.eq(action, "heavy", "bottom-left cell should be heavy")
end)

-- 6. getAxis returns 0,0 with no touch
R.test("getAxis returns 0,0 with no touch", function()
  TC.reset()
  local dx, dy = TC.getAxis()
  R.approx(dx, 0, "dx should be 0")
  R.approx(dy, 0, "dy should be 0")
end)

-- 7. getAxis clamps to [-1,1] when dragged far
R.test("getAxis clamps to [-1,1] when dragged far", function()
  TC.reset()
  TC.touchpressed("mouse", 40, 200)
  TC.touchmoved("mouse", 40 + 9999, 200)
  local dx, dy = TC.getAxis()
  R.approx(dx, 1.0, "dx should be clamped to 1.0")
  R.approx(dy, 0.0, "dy should be 0 (no vertical drag)")
  TC.reset()
end)

-- 8. isButtonDown false before press
R.test("isButtonDown false before press", function()
  TC.reset()
  R.notok(TC.isButtonDown("attack"), "attack not down before press")
end)

-- 9. isButtonDown true after touchpressed on attack zone
-- attack = row=0,col=0 → x in [288,384], y in [135,202.5]
-- center: x = 288 + 48 = 336, y = 135 + 33.75 ≈ 169
R.test("isButtonDown true after touchpressed on attack zone", function()
  TC.reset()
  TC.touchpressed("t1", 336, 169)
  R.ok(TC.isButtonDown("attack"), "attack should be down after press")
  TC.reset()
end)

-- 10. isButtonDown false after touchreleased
R.test("isButtonDown false after touchreleased", function()
  TC.reset()
  TC.touchpressed("t1", 336, 169)
  R.ok(TC.isButtonDown("attack"), "attack down before release")
  TC.touchreleased("t1")
  R.notok(TC.isButtonDown("attack"), "attack not down after release")
end)
