-- main.lua
local SM = require("src/scene_manager")

local REF_W, REF_H = 480, 270

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
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
