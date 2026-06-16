-- main.lua
local SM    = require("src/scene_manager")
local Input = require("src/input")

local REF_W, REF_H = 480, 270

local function toRef(sx, sy)
  local sw, sh = love.graphics.getDimensions()
  local scale  = math.min(sw / REF_W, sh / REF_H)
  local ox     = (sw - REF_W * scale) / 2
  local oy     = (sh - REF_H * scale) / 2
  return (sx - ox) / scale, (sy - oy) / scale
end

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  if love.system and love.system.getOS() == "Web" then
    Input.enableTouch()
  end
  local MM = require("src/scenes/main_menu")
  SM.push(MM.new())
end

function love.update(dt)
  SM.update(dt)
end

function love.draw()
  local sw, sh = love.graphics.getDimensions()
  local scale  = math.min(sw / REF_W, sh / REF_H)
  local ox     = math.floor((sw - REF_W * scale) / 2)
  local oy     = math.floor((sh - REF_H * scale) / 2)
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(scale, scale)
  love.graphics.setScissor(ox, oy, REF_W * scale, REF_H * scale)
  SM.draw()
  love.graphics.setScissor()
  love.graphics.pop()
end

function love.keypressed(key)
  SM.keypressed(key)
end

function love.keyreleased(key)
  SM.keyreleased(key)
end

-- Mouse events (love.js maps mobile touch → mouse on Web)
function love.mousepressed(x, y, button)
  if button == 1 then
    local rx, ry = toRef(x, y)
    Input.touchpressed("mouse", rx, ry)
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    Input.touchreleased("mouse")
  end
end

function love.mousemoved(x, y, dx, dy)
  local rx, ry = toRef(x, y)
  if love.mouse.isDown(1) then
    Input.touchmoved("mouse", rx, ry)
  end
  SM.mousemoved(rx, ry, dx, dy)   -- dx/dy are raw pixel deltas (not REF-scaled); FPS camera sensitivity expects this
end

-- Native multi-touch (Love2D desktop / love-android / love-ios)
function love.touchpressed(id, x, y)
  local rx, ry = toRef(x, y)
  Input.touchpressed(id, rx, ry)
end

function love.touchmoved(id, x, y)
  local rx, ry = toRef(x, y)
  Input.touchmoved(id, rx, ry)
end

function love.touchreleased(id)
  Input.touchreleased(id)
end
