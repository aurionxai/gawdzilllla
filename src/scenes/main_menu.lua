-- src/scenes/main_menu.lua
local SM   = require("src/scene_manager")

local Menu = {}
Menu.__index = Menu

function Menu.new()
  return setmetatable({
    _buttons = {
      { label="PLAY",  y=130, action="play"  },
      { label="QUIT",  y=158, action="quit"  },
    },
    _selected = 1,
  }, Menu)
end

function Menu:update(dt) end

function Menu:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Title
  love.graphics.setColor(0.9, 0.7, 0.1)
  love.graphics.printf("GAWDZILLLLA", 0, 70, 480, "center")

  love.graphics.setColor(0.5, 0.5, 0.7)
  love.graphics.printf("The Most Important Kaiju Game", 0, 95, 480, "center")

  -- Buttons
  for i, btn in ipairs(self._buttons) do
    if i == self._selected then
      love.graphics.setColor(1, 0.8, 0.1)
    else
      love.graphics.setColor(0.6, 0.6, 0.6)
    end
    love.graphics.printf(btn.label, 0, btn.y, 480, "center")
  end

  love.graphics.setColor(0.3, 0.3, 0.4)
  love.graphics.printf("UP/DOWN to select  ENTER to confirm", 0, 250, 480, "center")
end

function Menu:keypressed(key)
  if key == "up"    then self._selected = math.max(1, self._selected - 1) end
  if key == "down"  then self._selected = math.min(#self._buttons, self._selected + 1) end
  if key == "return" or key == "space" then
    local action = self._buttons[self._selected].action
    if action == "play" then
      local CS = require("src/scenes/character_select")
      SM.replace(CS.new())
    elseif action == "quit" then
      love.event.quit()
    end
  end
end

return Menu
