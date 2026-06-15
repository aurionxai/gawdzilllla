-- src/scenes/results.lua
local SM = require("src/scene_manager")

local Results = {}
Results.__index = Results

function Results.new(data)
  -- data: { winner, p1name, p2name, dollars, splats, buildingsDestroyed, totalBuildings }
  return setmetatable({
    _data  = data,
    _timer = 7.0,
    _lines = Results._buildLines(data),
  }, Results)
end

function Results._buildLines(d)
  local pct = d.totalBuildings > 0
    and math.floor(d.buildingsDestroyed / d.totalBuildings * 100) or 0
  return {
    { text = d.winner .. " WINS!",                  color={1,0.85,0.1},  size="big" },
    { text = "",                                     color={1,1,1},       size="sm"  },
    { text = "Destruction: $" .. string.format("%.1f", d.dollars/1e6) .. "M",
                                                     color={0.9,0.9,0.5}, size="med" },
    { text = "Civilians stomped: " .. d.splats,      color={0.9,0.5,0.5}, size="med" },
    { text = "Buildings leveled: " .. d.buildingsDestroyed .. "/" .. d.totalBuildings
             .. " (" .. pct .. "%)",                 color={0.6,0.8,1},   size="med" },
    { text = "",                                     color={1,1,1},       size="sm"  },
    { text = "Returning to menu…",                   color={0.4,0.4,0.5}, size="sm"  },
  }
end

function Results:update(dt)
  self._timer = self._timer - dt
  if self._timer <= 0 then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
  end
end

function Results:draw()
  -- Dark overlay
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Backdrop card
  love.graphics.setColor(0.06, 0.07, 0.18)
  love.graphics.rectangle("fill", 60, 40, 360, 190, 10)
  love.graphics.setColor(0.9, 0.75, 0.1, 0.8)
  love.graphics.rectangle("line", 60, 40, 360, 190, 10)

  local y = 55
  for _, line in ipairs(self._lines) do
    love.graphics.setColor(line.color)
    if line.size == "big" then
      love.graphics.printf(line.text, 60, y, 360, "center")
      y = y + 26
    elseif line.size == "med" then
      love.graphics.printf(line.text, 60, y, 360, "center")
      y = y + 20
    else
      y = y + 12
    end
  end

  -- Progress bar until auto-return
  local pct = math.max(0, self._timer / 7.0)
  love.graphics.setColor(0.15, 0.15, 0.25)
  love.graphics.rectangle("fill", 80, 222, 320, 4)
  love.graphics.setColor(0.9, 0.75, 0.1)
  love.graphics.rectangle("fill", 80, 222, 320 * pct, 4)

  -- SPACE to skip
  love.graphics.setColor(0.4, 0.4, 0.5)
  love.graphics.printf("SPACE or ENTER to continue", 0, 250, 480, "center")
end

function Results:keypressed(key)
  if key == "space" or key == "return" or key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
  end
end

return Results
