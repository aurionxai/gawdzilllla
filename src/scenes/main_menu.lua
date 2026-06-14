-- src/scenes/main_menu.lua
local Menu = {}
Menu.__index = Menu

function Menu.new()
  return setmetatable({ _ready = false }, Menu)
end

function Menu:update(dt) end

function Menu:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)
  love.graphics.setColor(1, 0.8, 0)
  love.graphics.printf("GAWDZILLLLA", 0, 100, 480, "center")
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.printf("(scaffold — press any key)", 0, 140, 480, "center")
end

function Menu:keypressed(key) end

return Menu
