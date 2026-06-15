-- src/fps/camera.lua
-- Player POV: position in world units, direction as angle in radians.
-- 0 = east, pi/2 = south, pi = west, 3pi/2 = north.
-- Camera plane length 0.66 gives ~66 degree horizontal FOV.

local Camera = {}
Camera.__index = Camera

function Camera.new(startX, startY, startAngle)
  return setmetatable({
    x         = startX,
    y         = startY,
    angle     = startAngle or 0,
    moveSpeed = 200,  -- world units / second
    rotSpeed  = 2.5,  -- radians / second
  }, Camera)
end

function Camera:getDir()
  return math.cos(self.angle), math.sin(self.angle)
end

function Camera:getPlane()
  -- Perpendicular to direction; length 0.66 ≈ 66° FOV
  return -math.sin(self.angle) * 0.66, math.cos(self.angle) * 0.66
end

-- forward: +1 = forward, -1 = back. strafe: +1 = right, -1 = left.
function Camera:move(dt, forward, strafe)
  local dx, dy = self:getDir()
  local sx, sy = self:getPlane()
  self.x = self.x + (dx * forward + sx * strafe) * self.moveSpeed * dt
  self.y = self.y + (dy * forward + sy * strafe) * self.moveSpeed * dt
end

-- dir: +1 = clockwise (right), -1 = counter-clockwise (left)
function Camera:rotate(dt, dir)
  self.angle = self.angle + dir * self.rotSpeed * dt
end

return Camera
