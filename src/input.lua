-- src/input.lua
-- Arrows: left/right/up(climb)/down(crouch)   Space: jump
-- A: special   S: super   D: special2   F: fart
-- Story mode single-player only uses player 1 map.
-- Touch input merged in via TouchControls for P1.

local Input = {}
local TC = require("src/touch_controls")

local MAPS = {
  [1] = {
    left    = "left",
    right   = "right",
    up      = "up",
    down    = "down",
    jump    = "space",
    attack  = "z",
    heavy   = "x",
    unleash = "q",
    special = "a",
    super   = "s",
    special2= "d",
    fart    = "f",
  },
  -- P2 kept for versus mode
  [2] = {
    left    = "a",
    right   = "d",
    up      = "w",
    down    = "s",
    jump    = "lshift",
    special = "z",
    super   = "x",
    special2= "c",
    fart    = "v",
  },
}

-- Touch mode flag
local _touchMode = false

function Input.enableTouch()
  _touchMode = true
end

function Input.isTouchMode()
  return _touchMode
end

-- Touch event forwarders (called from main.lua)
function Input.touchpressed(id, x, y)
  _touchMode = true
  TC.touchpressed(id, x, y)
end

function Input.touchmoved(id, x, y)
  TC.touchmoved(id, x, y)
end

function Input.touchreleased(id)
  TC.touchreleased(id)
end

-- Expose TC for HUD draw access
Input.TouchControls = TC

function Input.getMoveX(player)
  local m = MAPS[player]
  local x = 0
  if love.keyboard.isDown(m.left)  then x = x - 1 end
  if love.keyboard.isDown(m.right) then x = x + 1 end

  -- OR with touch axis for P1
  if player == 1 and _touchMode then
    local tdx, _ = TC.getAxis()
    if math.abs(tdx) > 0.1 then
      x = x + tdx
    end
  end

  return math.max(-1, math.min(1, x))
end

function Input.isDown(player, action)
  local m = MAPS[player]
  local kb = m[action] and love.keyboard.isDown(m[action]) or false
  if kb then return true end

  -- OR with touch buttons for P1
  if player == 1 and _touchMode then
    return TC.isButtonDown(action)
  end

  return false
end

function Input.getAction(player, key)
  local m = MAPS[player]
  for action, k in pairs(m) do
    if k == key then return action end
  end
  return nil
end

return Input
