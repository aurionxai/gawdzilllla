-- tests/test_fps_map.lua
local R = require("tests/runner")
if not love then love = {} end

local Map = require("src/fps/map")

print("\n-- fps/map.lua --")

R.test("boundary cells are walls (non-zero)", function()
  local m = Map.new()
  R.ok(m:getCell(0, 0) > 0, "top-left corner is wall")
  R.ok(m:getCell(19, 14) > 0, "bottom-right corner is wall")
end)

R.test("out-of-bounds coordinates return wall", function()
  local m = Map.new()
  R.ok(m:getCell(-1, 0) > 0,  "x=-1 is wall")
  R.ok(m:getCell(0, -1) > 0,  "y=-1 is wall")
  R.ok(m:getCell(100, 0) > 0, "x=100 is wall")
  R.ok(m:getCell(0, 100) > 0, "y=100 is wall")
end)

R.test("player start position is walkable", function()
  local m = Map.new()
  R.ok(m:isWalkable(m.PLAYER_START_X, m.PLAYER_START_Y), "player start is open")
end)

R.test("titan start position is walkable", function()
  local m = Map.new()
  R.ok(m:isWalkable(m.TITAN_START_X, m.TITAN_START_Y), "titan start is open")
end)

R.test("player and titan start positions are not the same cell", function()
  local m = Map.new()
  local px = math.floor(m.PLAYER_START_X / m.CELL)
  local py = math.floor(m.PLAYER_START_Y / m.CELL)
  local tx = math.floor(m.TITAN_START_X / m.CELL)
  local ty = math.floor(m.TITAN_START_Y / m.CELL)
  R.ok(px ~= tx or py ~= ty, "player and titan not in same cell")
end)

R.test("getWallColor returns RGB in [0,1] range", function()
  local m = Map.new()
  local r, g, b = m:getWallColor(1)
  R.ok(r >= 0 and r <= 1, "red in range")
  R.ok(g >= 0 and g <= 1, "green in range")
  R.ok(b >= 0 and b <= 1, "blue in range")
end)

R.test("CELL constant is 64", function()
  local m = Map.new()
  R.eq(m.CELL, 64)
end)
