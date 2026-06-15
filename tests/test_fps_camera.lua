-- tests/test_fps_camera.lua
local R = require("tests/runner")

-- Stub love so tests run outside LÖVE runtime
if not love then love = { graphics = {} } end

local Camera = require("src/fps/camera")

print("\n-- fps/camera.lua --")

R.test("camera stores start position and angle", function()
  local cam = Camera.new(128, 192, 0)
  R.eq(cam.x, 128)
  R.eq(cam.y, 192)
  R.eq(cam.angle, 0)
end)

R.test("getDir returns (1,0) when facing east (angle=0)", function()
  local cam = Camera.new(0, 0, 0)
  local dx, dy = cam:getDir()
  R.approx(dx, 1.0, "dirX")
  R.approx(dy, 0.0, "dirY")
end)

R.test("getDir returns (0,1) when facing south (angle=pi/2)", function()
  local cam = Camera.new(0, 0, math.pi / 2)
  local dx, dy = cam:getDir()
  R.approx(dx, 0.0, "dirX")
  R.approx(dy, 1.0, "dirY")
end)

R.test("getPlane is perpendicular to direction (dot product = 0)", function()
  local cam = Camera.new(0, 0, 0)
  local dx, dy = cam:getDir()
  local px, py = cam:getPlane()
  R.approx(dx * px + dy * py, 0.0, "perpendicular")
end)

R.test("rotate increases angle when turning right", function()
  local cam = Camera.new(0, 0, 0)
  cam:rotate(1, 1)
  R.ok(cam.angle > 0, "angle increased after right turn")
end)

R.test("move advances x when facing east", function()
  local cam = Camera.new(0, 0, 0)
  cam:move(1, 1, 0)
  R.ok(cam.x > 0, "moved east")
  R.approx(cam.y, 0, "no north/south drift when facing east")
end)
