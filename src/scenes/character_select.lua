-- src/scenes/character_select.lua
local SM = require("src/scene_manager")

local CS = {}
CS.__index = CS

local CHARS = {
  { name="Godzilla", module="src/characters/godzilla", color={0.2,0.6,0.3}, desc="HP 120 | SPD 70 | Heavy hitter" },
  { name="Kong",     module="src/characters/kong",     color={0.55,0.38,0.22}, desc="HP 110 | SPD 85 | Fast striker" },
  { name="Ghidorah", module="src/characters/ghidorah", color={0.85,0.75,0.1}, desc="HP 130 | SPD 60 | Tanky blaster" },
}

function CS.new()
  return setmetatable({
    _p1Idx     = 1,
    _p2Idx     = 2,
    _selectingP2 = false,
    _cursor    = 1,
  }, CS)
end

function CS:update(dt) end

function CS:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  love.graphics.setColor(1, 0.8, 0)
  love.graphics.printf(self._selectingP2 and "P2 SELECT" or "P1 SELECT", 0, 15, 480, "center")

  -- Character cards
  for i, c in ipairs(CHARS) do
    local x = 30 + (i-1) * 145
    local y = 50
    local w, h = 130, 150

    -- Card background
    local highlight = (i == self._cursor)
    love.graphics.setColor(highlight and {0.15,0.15,0.25} or {0.08,0.08,0.14})
    love.graphics.rectangle("fill", x, y, w, h, 6)
    if highlight then
      love.graphics.setColor(0.9, 0.8, 0.2)
      love.graphics.rectangle("line", x, y, w, h, 6)
    end

    -- Character color swatch
    love.graphics.setColor(c.color)
    love.graphics.rectangle("fill", x + 20, y + 15, 90, 70, 4)

    -- Eyes
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", x + 50, y + 42, 6)
    love.graphics.circle("fill", x + 80, y + 42, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", x + 53, y + 40, 2)
    love.graphics.circle("fill", x + 83, y + 40, 2)

    -- Name
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(c.name, x, y + 92, w, "center")

    -- Desc
    love.graphics.setColor(0.6, 0.6, 0.8)
    love.graphics.printf(c.desc, x + 4, y + 108, w - 8, "center")

    -- P1/P2 badges
    if i == self._p1Idx then
      love.graphics.setColor(0.2, 0.7, 1)
      love.graphics.printf("P1", x, y + 132, w, "center")
    end
    if i == self._p2Idx then
      love.graphics.setColor(1, 0.4, 0.4)
      love.graphics.printf("P2", x, i == self._p1Idx and y + 142 or y + 132, w, "center")
    end
  end

  -- Controls hint
  love.graphics.setColor(0.5, 0.5, 0.6)
  love.graphics.printf("LEFT/RIGHT select  ENTER confirm  ESC back", 0, 248, 480, "center")
end

function CS:keypressed(key)
  if key == "left"  then self._cursor = math.max(1, self._cursor - 1) end
  if key == "right" then self._cursor = math.min(#CHARS, self._cursor + 1) end
  if key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
  end
  if key == "return" or key == "space" then
    if not self._selectingP2 then
      self._p1Idx      = self._cursor
      self._selectingP2 = true
    else
      self._p2Idx = self._cursor
      -- Launch battle
      local Battle = require("src/scenes/battle")
      SM.replace(Battle.new(CHARS[self._p1Idx], CHARS[self._p2Idx]))
    end
  end
end

return CS
