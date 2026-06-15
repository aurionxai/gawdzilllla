-- src/fps/map.lua
-- Tokyo city grid for the raycaster.
-- 0 = open / walkable. Non-zero = wall (different building types).
-- Grid is 20 wide x 15 tall. Each cell = 64 world units.

local Map = {}
Map.__index = Map

Map.CELL = 64
Map.W    = 20
Map.H    = 15

-- 9 = boundary wall, 1 = office block, 2 = residential, 3 = skyscraper
local TOKYO_GRID = {
  {9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9},
  {9,0,0,0,0,1,0,0,0,0,0,0,3,0,0,0,0,0,0,9},
  {9,0,1,1,0,0,0,1,1,0,0,0,0,0,2,2,0,0,0,9},
  {9,0,1,1,0,0,0,1,1,0,0,0,0,0,2,2,0,0,0,9},
  {9,0,0,0,0,0,0,0,0,0,3,3,0,0,0,0,0,1,0,9},
  {9,0,0,0,0,2,0,0,0,0,3,3,0,0,0,0,0,1,0,9},
  {9,0,2,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,9},
  {9,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,9},
  {9,0,0,1,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,9},
  {9,0,0,1,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,9},
  {9,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,2,0,9},
  {9,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,2,0,9},
  {9,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,9},
  {9,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,9},
  {9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9},
}

-- Player starts mid-left (col=2, row=7), facing east
Map.PLAYER_START_X     = 2.5 * 64
Map.PLAYER_START_Y     = 7.5 * 64
Map.PLAYER_START_ANGLE = 0

-- Ghidorah starts mid-right (col=17, row=7)
Map.TITAN_START_X = 17.5 * 64
Map.TITAN_START_Y = 7.5 * 64

local WALL_COLORS = {
  [1] = {0.25, 0.30, 0.35},  -- office: blue-grey
  [2] = {0.30, 0.25, 0.22},  -- residential: warm brown
  [3] = {0.18, 0.20, 0.32},  -- skyscraper: dark indigo
  [9] = {0.15, 0.15, 0.20},  -- boundary
}

function Map.new()
  return setmetatable({ _grid = TOKYO_GRID }, Map)
end

-- Returns cell type at grid coordinates (x, y). Out-of-bounds returns 9 (wall).
function Map:getCell(x, y)
  if x < 0 or x >= self.W or y < 0 or y >= self.H then return 9 end
  return self._grid[y + 1][x + 1] or 0
end

-- Returns RGB triple (r, g, b) for a wall type, each in [0, 1].
function Map:getWallColor(wallType)
  local c = WALL_COLORS[wallType] or {0.40, 0.40, 0.40}
  return c[1], c[2], c[3]
end

-- Returns true if world-space position (wx, wy) is in an open cell.
function Map:isWalkable(wx, wy)
  local cx = math.floor(wx / self.CELL)
  local cy = math.floor(wy / self.CELL)
  return self:getCell(cx, cy) == 0
end

return Map
