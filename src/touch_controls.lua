-- src/touch_controls.lua
-- Touch input: zone geometry, axis state, button state, drawing.
-- Logical (REF) space is 480x270. All coordinates passed in are already in REF space.

local TC = {}

-- ── Constants ────────────────────────────────────────────────────────────────
local REF_W        = 480
local REF_H        = 270
local BTN_Y_MIN    = 135   -- bottom half starts here
local JOY_X_MAX    = 192   -- joystick zone: x < 192
local BTN_X_MIN    = 288   -- button zone:   x > 288
local JOY_RADIUS   = 40

local BTN_W = (REF_W - BTN_X_MIN) / 2   -- 96
local BTN_H = (REF_H - BTN_Y_MIN) / 2   -- 67.5

-- row-major [row][col], 0-indexed
local BTN_ACTIONS = {
  [0] = { [0] = "attack",  [1] = "special" },
  [1] = { [0] = "heavy",   [1] = "unleash" },
}

local BTN_COLORS = {
  attack  = { 0.2, 0.8, 0.3 },
  special = { 0.2, 0.5, 1.0 },
  heavy   = { 1.0, 0.5, 0.1 },
  unleash = { 0.9, 0.1, 0.1 },
}

-- ── Internal state ────────────────────────────────────────────────────────────
local joy = {
  id     = nil,   -- touch id holding the joystick
  ax     = 0,     -- anchor x
  ay     = 0,     -- anchor y
  dx     = 0,     -- current axis [-1,1]
  dy     = 0,
}

-- btnTouches[action] = touch id currently pressing that action (or nil)
local btnTouches = {}

-- ── Zone queries (pure) ───────────────────────────────────────────────────────
function TC.inJoystickZone(x, y)
  return x < JOY_X_MAX and y > BTN_Y_MIN
end

function TC.inButtonZone(x, y)
  return x > BTN_X_MIN and y > BTN_Y_MIN
end

function TC.hitButton(x, y)
  if not TC.inButtonZone(x, y) then return nil end
  local col = math.floor((x - BTN_X_MIN) / BTN_W)
  local row = math.floor((y - BTN_Y_MIN) / BTN_H)
  col = math.max(0, math.min(1, col))
  row = math.max(0, math.min(1, row))
  return BTN_ACTIONS[row][col]
end

-- ── State getters ─────────────────────────────────────────────────────────────
function TC.getAxis()
  return joy.dx, joy.dy
end

function TC.isButtonDown(action)
  return btnTouches[action] ~= nil
end

-- ── Event handlers ────────────────────────────────────────────────────────────
function TC.touchpressed(id, x, y)
  -- Joystick zone
  if TC.inJoystickZone(x, y) and joy.id == nil then
    joy.id = id
    joy.ax = x
    joy.ay = y
    joy.dx = 0
    joy.dy = 0
    return
  end
  -- Button zone
  local action = TC.hitButton(x, y)
  if action then
    btnTouches[action] = id
  end
end

function TC.touchmoved(id, x, y)
  if joy.id == id then
    local ddx = x - joy.ax
    local ddy = y - joy.ay
    local len = math.sqrt(ddx * ddx + ddy * ddy)
    if len > JOY_RADIUS then
      joy.dx = ddx / len
      joy.dy = ddy / len
    else
      joy.dx = ddx / JOY_RADIUS
      joy.dy = ddy / JOY_RADIUS
    end
  end
end

function TC.touchreleased(id)
  -- Release joystick
  if joy.id == id then
    joy.id = nil
    joy.ax = 0
    joy.ay = 0
    joy.dx = 0
    joy.dy = 0
  end
  -- Release any buttons held by this touch
  for action, tid in pairs(btnTouches) do
    if tid == id then
      btnTouches[action] = nil
    end
  end
end

-- ── Test utility ──────────────────────────────────────────────────────────────
function TC.reset()
  joy.id = nil
  joy.ax = 0
  joy.ay = 0
  joy.dx = 0
  joy.dy = 0
  btnTouches = {}
end

-- ── Rendering ─────────────────────────────────────────────────────────────────
function TC.draw()
  if not love or not love.graphics then return end
  local g = love.graphics

  -- Default joystick base position (centered in left bottom zone)
  local baseX = JOY_X_MAX / 2
  local baseY = BTN_Y_MIN + (REF_H - BTN_Y_MIN) / 2

  if joy.id ~= nil then
    baseX = joy.ax
    baseY = joy.ay
  end

  -- Joystick base circle
  g.setColor(1, 1, 1, 0.18)
  g.circle("fill", baseX, baseY, JOY_RADIUS)
  g.setColor(1, 1, 1, 0.35)
  g.circle("line", baseX, baseY, JOY_RADIUS)

  -- Joystick nub
  local nubX = baseX + joy.dx * JOY_RADIUS
  local nubY = baseY + joy.dy * JOY_RADIUS
  g.setColor(1, 1, 1, 0.55)
  g.circle("fill", nubX, nubY, 12)

  -- Buttons
  local btnRadius = math.min(BTN_W, BTN_H) / 2 - 4
  for row = 0, 1 do
    for col = 0, 1 do
      local action = BTN_ACTIONS[row][col]
      local cx = BTN_X_MIN + col * BTN_W + BTN_W / 2
      local cy = BTN_Y_MIN + row * BTN_H + BTN_H / 2
      local color = BTN_COLORS[action]
      local alpha = TC.isButtonDown(action) and 0.75 or 0.30
      g.setColor(color[1], color[2], color[3], alpha)
      g.circle("fill", cx, cy, btnRadius)
    end
  end

  g.setColor(1, 1, 1, 1)  -- reset color
end

return TC
