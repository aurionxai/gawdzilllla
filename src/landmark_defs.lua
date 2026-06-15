-- src/landmark_defs.lua
-- Pixel-art landmark structures for each story city.
-- Each landmark is drawn with love.graphics.rectangle calls only.
-- draw(x, groundY, scale) — x is left edge, groundY is ground line

local L = {}

-- Helper: draw a simple rectangular tower with windows
local function tower(x, gY, w, h, bodyCol, roofCol, winCol, scale)
  local s = scale or 1
  love.graphics.setColor(bodyCol)
  love.graphics.rectangle("fill", x, gY - h*s, w*s, h*s)
  if roofCol then
    love.graphics.setColor(roofCol)
    love.graphics.rectangle("fill", x + w*s*0.2, gY - h*s - 8*s, w*s*0.6, 8*s)
  end
  if winCol then
    love.graphics.setColor(winCol)
    for row = 1, math.floor(h/14) do
      for col = 0, math.floor(w/8)-1 do
        love.graphics.rectangle("fill",
          x + col*8*s + 2*s, gY - row*14*s - 10*s, 4*s, 6*s)
      end
    end
  end
end

-- ── Per-city landmark draw functions ──────────────────────────────────────────

L.honolulu = function(x, gY)
  -- Diamond Head volcano silhouette
  love.graphics.setColor(0.22, 0.30, 0.18)
  love.graphics.rectangle("fill", x,      gY-90, 20, 90)
  love.graphics.rectangle("fill", x+20,   gY-120, 30, 120)
  love.graphics.rectangle("fill", x+50,   gY-100, 20, 100)
  love.graphics.rectangle("fill", x+70,   gY-70, 20, 70)
  -- Beach hut row
  love.graphics.setColor(0.85, 0.72, 0.40)
  for i = 0, 3 do
    love.graphics.rectangle("fill", x+i*22, gY-22, 16, 22)
    love.graphics.setColor(0.9, 0.25, 0.20)
    love.graphics.rectangle("fill", x+i*22-2, gY-26, 20, 6)
    love.graphics.setColor(0.85, 0.72, 0.40)
  end
end

L.tokyo = function(x, gY)
  -- Tokyo Tower (red lattice)
  love.graphics.setColor(0.85, 0.20, 0.10)
  love.graphics.rectangle("fill", x+20, gY-180, 6,  180)
  love.graphics.rectangle("fill", x+54, gY-180, 6,  180)
  -- cross beams
  for i = 0, 6 do
    love.graphics.rectangle("fill", x+20, gY-25*i-20, 40, 4)
  end
  love.graphics.rectangle("fill", x+28, gY-180, 24, 20)  -- top spire base
  love.graphics.rectangle("fill", x+32, gY-210, 16, 30)
  love.graphics.rectangle("fill", x+35, gY-240, 10, 30)
  -- Observation deck
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.rectangle("fill", x+14, gY-140, 52, 10)
  love.graphics.rectangle("fill", x+22, gY-100, 36, 8)
end

L.sf = function(x, gY)
  -- Golden Gate Bridge (two towers + cables)
  love.graphics.setColor(0.85, 0.30, 0.10)
  -- Left tower
  love.graphics.rectangle("fill", x+10,  gY-110, 10, 110)
  love.graphics.rectangle("fill", x+8,   gY-90,  14, 8)
  love.graphics.rectangle("fill", x+8,   gY-60,  14, 8)
  -- Right tower
  love.graphics.rectangle("fill", x+100, gY-110, 10, 110)
  love.graphics.rectangle("fill", x+98,  gY-90,  14, 8)
  love.graphics.rectangle("fill", x+98,  gY-60,  14, 8)
  -- Road deck
  love.graphics.setColor(0.55, 0.40, 0.30)
  love.graphics.rectangle("fill", x, gY-28, 120, 8)
  -- Cable arcs (approximated as horizontal bands)
  love.graphics.setColor(0.75, 0.22, 0.08)
  for i = 0, 4 do
    local cx = x + 15 + i*18
    local cy = gY - 110 + math.floor(math.abs(i-2)*18)
    love.graphics.rectangle("fill", cx, cy, 4, 2)
  end
end

L.seoul = function(x, gY)
  -- N Seoul Tower (Namsan) — slender tower on hill
  love.graphics.setColor(0.18, 0.22, 0.35)
  love.graphics.rectangle("fill", x+30, gY-50, 60, 50)  -- hill
  love.graphics.setColor(0.65, 0.65, 0.70)
  love.graphics.rectangle("fill", x+52, gY-200, 16, 150) -- shaft
  love.graphics.setColor(0.80, 0.80, 0.85)
  love.graphics.rectangle("fill", x+44, gY-150, 32, 22)  -- observation deck
  love.graphics.rectangle("fill", x+48, gY-170, 24, 20)
  love.graphics.setColor(0.90, 0.30, 0.20)
  love.graphics.rectangle("fill", x+55, gY-210, 10, 60)  -- antenna
end

L.newyork = function(x, gY)
  -- Empire State Building
  love.graphics.setColor(0.72, 0.72, 0.78)
  love.graphics.rectangle("fill", x,    gY-160, 80, 160)
  love.graphics.rectangle("fill", x+10, gY-195, 60, 35)
  love.graphics.rectangle("fill", x+20, gY-220, 40, 25)
  love.graphics.rectangle("fill", x+28, gY-240, 24, 20)
  love.graphics.rectangle("fill", x+34, gY-258, 12, 18)
  love.graphics.setColor(0.85, 0.85, 0.90)
  love.graphics.rectangle("fill", x+37, gY-280, 6,  22)  -- antenna
  -- Windows
  love.graphics.setColor(0.95, 0.90, 0.55, 0.8)
  for row = 1, 8 do
    for col = 0, 4 do
      love.graphics.rectangle("fill", x+col*15+4, gY-row*18-10, 8, 10)
    end
  end
end

L.hongkong = function(x, gY)
  -- Bank of China Tower (geometric facets)
  love.graphics.setColor(0.50, 0.68, 0.78)
  love.graphics.rectangle("fill", x+20, gY-220, 60, 220)
  love.graphics.setColor(0.38, 0.55, 0.68)
  -- Diagonal facet lines
  love.graphics.rectangle("fill", x+20, gY-220, 4, 220)
  love.graphics.rectangle("fill", x+76, gY-220, 4, 220)
  for i = 0, 5 do
    love.graphics.rectangle("fill", x+20, gY-40*i-30, 60, 3)
  end
  love.graphics.setColor(0.65, 0.80, 0.90)
  love.graphics.rectangle("fill", x+34, gY-240, 32, 20)
  love.graphics.rectangle("fill", x+40, gY-255, 20, 15)
  love.graphics.setColor(0.80, 0.85, 0.90)
  love.graphics.rectangle("fill", x+46, gY-275, 8,  20)
end

L.london = function(x, gY)
  -- Big Ben + Parliament
  love.graphics.setColor(0.72, 0.68, 0.52)
  love.graphics.rectangle("fill", x,    gY-60,  180, 60)  -- parliament base
  -- Clock tower
  love.graphics.setColor(0.78, 0.74, 0.58)
  love.graphics.rectangle("fill", x+10, gY-180, 36, 180)
  love.graphics.setColor(0.68, 0.64, 0.48)
  love.graphics.rectangle("fill", x+8,  gY-190, 40, 12)   -- belfry
  love.graphics.setColor(0.50, 0.55, 0.35)
  -- Clock face
  love.graphics.rectangle("fill", x+14, gY-165, 24, 24)
  love.graphics.setColor(0.90, 0.85, 0.70)
  love.graphics.rectangle("fill", x+17, gY-162, 18, 18)
  -- Spire
  love.graphics.setColor(0.55, 0.52, 0.38)
  love.graphics.rectangle("fill", x+20, gY-230, 16, 40)
  love.graphics.rectangle("fill", x+24, gY-250, 8,  20)
  love.graphics.rectangle("fill", x+26, gY-265, 4,  15)
end

L.sydney = function(x, gY)
  -- Sydney Opera House sails
  love.graphics.setColor(0.94, 0.92, 0.88)
  -- Sail 1 (big)
  love.graphics.rectangle("fill", x+10, gY-80,  20, 80)
  love.graphics.rectangle("fill", x+30, gY-100, 20, 100)
  love.graphics.rectangle("fill", x+50, gY-80,  20, 80)
  -- Sail 2 (smaller)
  love.graphics.rectangle("fill", x+80, gY-55,  16, 55)
  love.graphics.rectangle("fill", x+96, gY-70,  16, 70)
  love.graphics.rectangle("fill", x+112,gY-55,  16, 55)
  -- Base / steps
  love.graphics.setColor(0.75, 0.73, 0.70)
  love.graphics.rectangle("fill", x,    gY-18, 140, 18)
  love.graphics.rectangle("fill", x+5,  gY-10, 130, 10)
  -- Harbour bridge arch
  love.graphics.setColor(0.45, 0.45, 0.48)
  love.graphics.rectangle("fill", x+150, gY-60, 8, 60)   -- left pylon
  love.graphics.rectangle("fill", x+240, gY-60, 8, 60)   -- right pylon
  love.graphics.rectangle("fill", x+150, gY-80, 100, 6)  -- arch top
  love.graphics.rectangle("fill", x+148, gY-14, 104, 4)  -- road deck
end

L.dubai = function(x, gY)
  -- Burj Khalifa
  love.graphics.setColor(0.60, 0.68, 0.75)
  love.graphics.rectangle("fill", x+30, gY-260, 60, 260)
  love.graphics.rectangle("fill", x+36, gY-300, 48, 40)
  love.graphics.rectangle("fill", x+42, gY-335, 36, 35)
  love.graphics.rectangle("fill", x+48, gY-365, 24, 30)
  love.graphics.rectangle("fill", x+54, gY-385, 12, 20)
  love.graphics.setColor(0.72, 0.80, 0.88)
  love.graphics.rectangle("fill", x+57, gY-420, 6,  35)  -- spire
  -- Setback stripes
  love.graphics.setColor(0.50, 0.58, 0.65)
  for i = 0, 8 do
    love.graphics.rectangle("fill", x+30, gY-30*i-20, 60, 2)
  end
end

L.monster = function(x, gY)
  -- Monster Island: jagged volcanic peaks + ruins
  love.graphics.setColor(0.15, 0.18, 0.12)
  love.graphics.rectangle("fill", x,    gY-100, 30, 100)
  love.graphics.rectangle("fill", x+30, gY-160, 40, 160)
  love.graphics.rectangle("fill", x+70, gY-120, 30, 120)
  love.graphics.rectangle("fill", x+100,gY-80,  40, 80)
  love.graphics.rectangle("fill", x+140,gY-140, 35, 140)
  -- Ancient ruins
  love.graphics.setColor(0.30, 0.28, 0.22)
  love.graphics.rectangle("fill", x+180, gY-50, 20, 50)
  love.graphics.rectangle("fill", x+205, gY-65, 20, 65)
  love.graphics.rectangle("fill", x+178, gY-56, 50, 8)  -- lintel
  -- Glowing eyes in darkness
  love.graphics.setColor(0.90, 0.15, 0.05)
  love.graphics.rectangle("fill", x+52, gY-130, 6, 5)
  love.graphics.rectangle("fill", x+62, gY-130, 6, 5)
end

-- Fallback for any city without a custom landmark
L.default = function(x, gY)
  love.graphics.setColor(0.45, 0.42, 0.50)
  love.graphics.rectangle("fill", x+20, gY-180, 40, 180)
  love.graphics.rectangle("fill", x+65, gY-140, 30, 140)
  love.graphics.rectangle("fill", x+5,  gY-120, 28, 120)
  -- Generic antenna
  love.graphics.setColor(0.62, 0.60, 0.65)
  love.graphics.rectangle("fill", x+36, gY-200, 8, 20)
end

function L.get(cityKey)
  return L[cityKey] or L.default
end

return L
