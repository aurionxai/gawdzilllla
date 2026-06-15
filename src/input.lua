-- src/input.lua
-- Arrows: left/right/up(climb)/down(crouch)   Space: jump
-- A: special   S: super   D: special2   F: fart
-- Story mode single-player only uses player 1 map.

local Input = {}

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

function Input.getMoveX(player)
  local m = MAPS[player]
  local x = 0
  if love.keyboard.isDown(m.left)  then x = x - 1 end
  if love.keyboard.isDown(m.right) then x = x + 1 end
  return x
end

function Input.isDown(player, action)
  local m = MAPS[player]
  return m[action] and love.keyboard.isDown(m[action]) or false
end

function Input.getAction(player, key)
  local m = MAPS[player]
  for action, k in pairs(m) do
    if k == key then return action end
  end
  return nil
end

return Input
