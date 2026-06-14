-- src/input.lua
-- P1: A/D move, W jump, Z light, X heavy, C special, V unleash
-- P2: left/right move, up jump, comma light, period heavy, slash special, rshift unleash

local Input = {}

local MAPS = {
  [1] = { left="a",    right="d",     jump="w",
          light="z",   heavy="x",     special="c",    unleash="v" },
  [2] = { left="left", right="right", jump="up",
          light=",",   heavy=".",     special="/",    unleash="rshift" },
}

function Input.getMoveX(player)
  local m = MAPS[player]
  local x = 0
  if love.keyboard.isDown(m.left)  then x = x - 1 end
  if love.keyboard.isDown(m.right) then x = x + 1 end
  return x
end

-- Call in love.keypressed to check one-shot actions (jump, attacks)
function Input.getAction(player, key)
  local m = MAPS[player]
  for action, k in pairs(m) do
    if k == key then return action end
  end
  return nil
end

return Input
