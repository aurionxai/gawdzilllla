-- src/fps/renderer.lua
-- DDA raycaster: casts 240 rays (2px strips) from camera.
-- Draws enemy titan as a Z-buffered billboard sprite.

local Renderer = {}

local SCREEN_W = 480
local SCREEN_H = 270
local NUM_RAYS = 240   -- one ray per 2px column
local STRIP_W  = 2

local HALF_W = SCREEN_W / 2
local HALF_H = SCREEN_H / 2

local _zBuf = {}  -- perpendicular wall distance per ray column, for sprite occlusion

local function drawTitan(camera, map, enemy, dirX, dirY, planeX, planeY)
  local spx = enemy.x - camera.x
  local spy = enemy.y - camera.y

  -- Camera-space transform
  local invDet = 1 / (planeX * dirY - dirX * planeY)
  local tx = invDet * ( dirY * spx - dirX * spy)
  local tz = invDet * (-planeY * spx + planeX * spy)

  if tz <= 0.5 then return end   -- behind camera or too close

  local screenCX = math.floor(HALF_W * (1 + tx / tz))
  local size     = math.floor(SCREEN_H / tz)
  if size <= 0 then return end

  local half = math.floor(size / 2)
  local x0 = math.max(0,          screenCX - half)
  local x1 = math.min(SCREEN_W-1, screenCX + half)
  local y0 = math.max(0,          math.floor(HALF_H) - half)
  local y1 = math.min(SCREEN_H-1, math.floor(HALF_H) + half)

  local flashOn = enemy.flashTimer > 0 and (math.floor(enemy.flashTimer * 16) % 2 == 0)

  -- Determine body color once before the per-column loop
  local r, g, b
  if flashOn then
    r, g, b = 1, 1, 1
  elseif enemy.damageState == "CRITICAL" then
    r, g, b = 0.35, 0.08, 0.04
  elseif enemy.damageState == "HURT" then
    r, g, b = 0.25, 0.05, 0.05
  else
    r, g, b = 0.18, 0.03, 0.03
  end
  love.graphics.setColor(r, g, b)

  for sx = x0, x1 do
    local col = math.floor(sx / STRIP_W)
    if col >= 0 and col < NUM_RAYS and tz < _zBuf[col] then
      love.graphics.rectangle("fill", sx, y0, 1, y1 - y0)

      -- Glowing eyes: two columns near center
      local mid  = screenCX
      local eyeY = y0 + math.floor((y1 - y0) * 0.25)
      local eyeH = math.max(2, math.floor((y1 - y0) * 0.06))
      if sx == mid - math.floor(size * 0.14) or sx == mid + math.floor(size * 0.06) then
        if enemy.damageState == "CRITICAL" then
          love.graphics.setColor(1, 1, 0)
        else
          love.graphics.setColor(1, 0, 0)
        end
        love.graphics.rectangle("fill", sx, eyeY, 1, eyeH)
        -- Restore body color for subsequent columns
        love.graphics.setColor(r, g, b)
      end
    end
  end

  -- Status label above titan
  if enemy.damageState ~= "FULL" then
    love.graphics.setColor(1, 0.4, 0.1)
    love.graphics.printf("⚠ " .. enemy.damageState, screenCX - 35, y0 - 12, 70, "center")
  end
end

function Renderer.draw(camera, map, enemy)
  local dirX, dirY    = camera:getDir()
  local planeX, planeY = camera:getPlane()

  -- Sky and floor rectangles
  love.graphics.setColor(0.06, 0.04, 0.10)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, HALF_H)
  love.graphics.setColor(0.12, 0.10, 0.08)
  love.graphics.rectangle("fill", 0, HALF_H, SCREEN_W, HALF_H)

  local CELL = map.CELL

  -- Cast one ray per strip
  for col = 0, NUM_RAYS - 1 do
    local sx      = col * STRIP_W
    local camX    = 2 * col / (NUM_RAYS - 1) - 1  -- -1..1 symmetric across screen
    local rayDirX = dirX + planeX * camX
    local rayDirY = dirY + planeY * camX

    local mapX = math.floor(camera.x / CELL)
    local mapY = math.floor(camera.y / CELL)

    local ddx = rayDirX == 0 and 1e30 or math.abs(1 / rayDirX)
    local ddy = rayDirY == 0 and 1e30 or math.abs(1 / rayDirY)

    local stepX, sdx, stepY, sdy
    if rayDirX < 0 then
      stepX = -1
      sdx   = (camera.x / CELL - mapX) * ddx
    else
      stepX = 1
      sdx   = (mapX + 1 - camera.x / CELL) * ddx
    end
    if rayDirY < 0 then
      stepY = -1
      sdy   = (camera.y / CELL - mapY) * ddy
    else
      stepY = 1
      sdy   = (mapY + 1 - camera.y / CELL) * ddy
    end

    local side = 0
    for _ = 1, 30 do  -- 30 > max map dimension (20×15), so ray always terminates
      if sdx < sdy then
        sdx  = sdx + ddx;  mapX = mapX + stepX;  side = 0
      else
        sdy  = sdy + ddy;  mapY = mapY + stepY;  side = 1
      end
      if map:getCell(mapX, mapY) > 0 then break end
    end

    local perp = (side == 0) and (sdx - ddx) or (sdy - ddy)
    _zBuf[col] = perp > 0 and perp or 1e30

    if perp > 0 then
      local lineH = math.floor(SCREEN_H / perp)
      local y0    = math.max(0, math.floor(HALF_H - lineH / 2))
      local y1    = math.min(SCREEN_H - 1, math.floor(HALF_H + lineH / 2))

      local wt      = map:getCell(mapX, mapY)
      local r, g, b = map:getWallColor(wt)

      -- Y-side walls darker for pseudo-lighting
      if side == 1 then r, g, b = r * 0.65, g * 0.65, b * 0.65 end

      -- Distance fog blends toward dark indigo
      local fog = math.min(1, perp / 14)
      r = r + (0.04 - r) * fog
      g = g + (0.03 - g) * fog
      b = b + (0.10 - b) * fog

      love.graphics.setColor(r, g, b)
      love.graphics.rectangle("fill", sx, y0, STRIP_W, y1 - y0)
    end
  end

  -- Billboard titan sprite (drawn after walls, Z-checked per column)
  if enemy and enemy.hp > 0 then
    drawTitan(camera, map, enemy, dirX, dirY, planeX, planeY)
  end
end

return Renderer
