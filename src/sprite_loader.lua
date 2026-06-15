-- src/sprite_loader.lua
-- Loads Frame0/1/2 for a character; returns table of up to 3 images.
local M = {}

function M.load(name)
  local frames = {}
  for i = 0, 2 do
    local path = string.format("sprites/characters/%s_Frame%d.png", name, i)
    local ok, img = pcall(love.graphics.newImage, path)
    frames[i + 1] = ok and img or nil
  end
  return frames
end

return M
