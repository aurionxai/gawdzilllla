-- src/city_renderer.lua
-- Side-scrolling city renderer.
-- Dusk atmosphere: rich gradient sky, dark building silhouettes, warm amber windows.
-- Platform-style building tops for clear landing cues.

local CR = {}

-- ── Palettes ──────────────────────────────────────────────────────────────────

-- Darker, moodier building palette for dusk atmosphere
local BUILDING_COLS = {
  { 0.22, 0.24, 0.36 },  -- deep blue-grey
  { 0.20, 0.22, 0.32 },  -- deep navy slate
  { 0.28, 0.24, 0.26 },  -- deep mauve-grey
  { 0.18, 0.20, 0.28 },  -- very dark slate
  { 0.25, 0.28, 0.38 },  -- medium blue-grey
  { 0.30, 0.24, 0.22 },  -- deep sienna-grey
  { 0.16, 0.18, 0.24 },  -- near-black slate
  { 0.24, 0.22, 0.32 },  -- deep violet-grey
}

local TRIM_DARKEN = 0.75

-- Warm amber windows for dusk glow
local WINDOW_LIGHT  = { 0.98, 0.82, 0.35 }  -- warm amber lit
local WINDOW_WARM2  = { 1.00, 0.92, 0.58 }  -- soft gold lit
local WINDOW_DARK   = { 0.10, 0.12, 0.18 }  -- very dark unlit
local WINDOW_TINT   = { 0.30, 0.40, 0.55 }  -- deep blue-glass

local SIGN_COLS = {
  { 0.88, 0.22, 0.18 },
  { 0.22, 0.52, 0.82 },
  { 0.20, 0.55, 0.25 },
  { 0.82, 0.62, 0.12 },
}

local SIGN_NAMES = {
  "GROCERY", "LAUNDRY", "DELI", "PHARMACY", "DINER", "BODEGA",
  "MARKET", "BARBER", "NOODLES", "BAKERY", "PAWN", "GAS",
}

-- ── Gradient helper ───────────────────────────────────────────────────────────

local function gradLerp(stops, t)
  local s1, s2 = stops[1], stops[2]
  for i = 1, #stops - 1 do
    if t >= stops[i].t and t <= stops[i+1].t then
      s1, s2 = stops[i], stops[i+1]
      break
    end
  end
  local span = s2.t - s1.t
  if span <= 0 then return s1.r, s1.g, s1.b end
  local f = (t - s1.t) / span
  return s1.r + (s2.r-s1.r)*f, s1.g + (s2.g-s1.g)*f, s1.b + (s2.b-s1.b)*f
end

-- ── Sky ───────────────────────────────────────────────────────────────────────

function CR.drawSky(camX, w, h, groundY, timeOfDay)
  -- Dusk gradient: deep navy top → indigo → warm purple → amber → golden horizon
  local stops = {
    { t=0.00, r=0.04, g=0.06, b=0.20 },  -- deep night navy
    { t=0.18, r=0.08, g=0.07, b=0.30 },  -- deep indigo
    { t=0.40, r=0.28, g=0.14, b=0.42 },  -- rich purple
    { t=0.62, r=0.65, g=0.28, b=0.35 },  -- warm red-purple
    { t=0.80, r=0.88, g=0.48, b=0.18 },  -- amber orange
    { t=0.92, r=0.95, g=0.65, b=0.20 },  -- golden orange
    { t=1.00, r=0.98, g=0.78, b=0.38 },  -- warm horizon gold
  }

  local bands = 50
  local bandH = groundY / bands
  for i = 0, bands - 1 do
    local t = i / bands
    local r, g, b = gradLerp(stops, t)
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, math.floor(i * bandH), w, math.ceil(bandH) + 1)
  end

  -- Subtle star scatter in upper third
  love.graphics.setColor(1, 1, 1, 0.45)
  math.randomseed(7331)
  for i = 1, 28 do
    local sx = math.random(0, w)
    local sy = math.random(0, math.floor(groundY * 0.32))
    love.graphics.rectangle("fill", sx, sy, 1, 1)
  end
  math.randomseed(os.time())
end

-- ── Water reflection ─────────────────────────────────────────────────────────

function CR.drawWaterReflection(groundY, w)
  -- Semi-transparent warm water/bay glow overlay over the road area.
  -- Draws in screen space after world content, giving a coastal dusk feel.
  local roadY  = groundY + 18   -- where road begins
  local roadH  = 52             -- road area height
  local bands  = 14
  for i = 0, bands - 1 do
    local t = i / bands
    -- Warm amber-to-dark gradient mirroring the horizon sky
    local r = 0.82 - t * 0.50
    local g = 0.48 - t * 0.32
    local b = 0.18 - t * 0.10
    local a = 0.38 - t * 0.35   -- strong at top, fades out
    love.graphics.setColor(r, g, b, a)
    local y = roadY + math.floor(i * roadH / bands)
    love.graphics.rectangle("fill", 0, y, w, math.ceil(roadH / bands) + 1)
  end
  -- Horizontal shimmer lines (water ripples)
  love.graphics.setColor(1.0, 0.88, 0.45, 0.22)
  love.graphics.rectangle("fill", 0, roadY + 4,  w, 1)
  love.graphics.rectangle("fill", 0, roadY + 12, w, 1)
  love.graphics.setColor(1.0, 0.80, 0.35, 0.14)
  love.graphics.rectangle("fill", 0, roadY + 20, w, 1)
  love.graphics.rectangle("fill", 0, roadY + 29, w, 1)
  love.graphics.rectangle("fill", 0, roadY + 38, w, 1)
end

-- ── Distant cityscape (parallax layer 1) ─────────────────────────────────────

function CR.drawDistantSkyline(camX, levelW, groundY)
  -- Slow parallax: moves at 20% of camera speed
  local px = -camX * 0.20
  math.randomseed(42)
  local x = math.floor(px % 80) - 80
  while x < 480 + 80 do
    local bw = math.random(22, 68)
    local bh = math.random(38, 130)
    -- Near-black silhouette against dusk sky
    love.graphics.setColor(0.05, 0.06, 0.16, 0.92)
    love.graphics.rectangle("fill", x, groundY - bh, bw, bh)

    -- Warm amber lit windows (deterministic per building using hash)
    local wx_count = math.floor(bw / 10)
    local wy_count = math.floor(bh / 14)
    for row = 1, wy_count do
      for col = 0, wx_count - 1 do
        local hash = (row * 17 + col * 31 + math.floor(x) * 7 + math.floor(bh) * 3) % 100
        if hash > 38 then
          local winX = x + col * 10 + 3
          local winY = groundY - row * 14 - 4
          -- Amber glow halo
          love.graphics.setColor(0.95, 0.72, 0.20, 0.28)
          love.graphics.rectangle("fill", winX - 1, winY - 1, 7, 9)
          -- Window face
          local wc = (hash % 3 == 0) and WINDOW_WARM2 or WINDOW_LIGHT
          love.graphics.setColor(wc[1], wc[2], wc[3], 0.88)
          love.graphics.rectangle("fill", winX, winY, 5, 7)
        end
      end
    end

    -- Glowing spire on tall buildings
    local hash2 = (math.floor(x) * 13 + math.floor(bh) * 7) % 100
    if hash2 > 55 and bh > 70 then
      local tx = x + math.floor(bw * 0.45)
      -- Spire antenna
      love.graphics.setColor(0.05, 0.06, 0.16, 0.92)
      love.graphics.rectangle("fill", tx, groundY - bh - 18, 2, 18)
      -- Red warning glow at tip
      love.graphics.setColor(1.0, 0.25, 0.10, 0.95)
      love.graphics.rectangle("fill", tx - 1, groundY - bh - 20, 4, 4)
      love.graphics.setColor(1.0, 0.25, 0.10, 0.40)
      love.graphics.rectangle("fill", tx - 3, groundY - bh - 22, 8, 6)
    end

    x = x + bw + math.random(4, 18)
  end
  math.randomseed(os.time())
end

-- ── Mid-ground cityscape (parallax layer 2) ───────────────────────────────────

function CR.drawMidSkyline(camX, levelW, groundY)
  local px = -camX * 0.45
  math.randomseed(99)
  local x = math.floor(px % 120) - 120
  while x < 480 + 120 do
    local bw = math.random(18, 52)
    local bh = math.random(28, 85)
    -- Deep indigo-navy, slightly lighter than distant
    love.graphics.setColor(0.08, 0.09, 0.22, 0.82)
    love.graphics.rectangle("fill", x, groundY - bh, bw, bh)
    -- A few warm windows
    if bw >= 16 then
      local hash = (math.floor(x) * 11 + math.floor(bh) * 5) % 100
      if hash > 50 then
        love.graphics.setColor(0.95, 0.75, 0.25, 0.70)
        love.graphics.rectangle("fill", x + 3, groundY - bh + 6, 4, 6)
        if bw > 28 then
          love.graphics.rectangle("fill", x + bw - 9, groundY - bh + 12, 4, 6)
        end
      end
    end
    x = x + bw + math.random(3, 14)
  end
  math.randomseed(os.time())
end

-- ── Sidewalk / road ───────────────────────────────────────────────────────────

function CR.drawStreet(groundY, levelW)
  local lw = levelW or 5000
  -- Sidewalk (chunky tile look)
  love.graphics.setColor(0.28, 0.28, 0.32)
  love.graphics.rectangle("fill", 0, groundY, lw, 18)
  -- Top highlight edge (platform landing cue)
  love.graphics.setColor(0.50, 0.48, 0.55, 0.80)
  love.graphics.rectangle("fill", 0, groundY, lw, 2)
  -- Horizontal grout lines
  love.graphics.setColor(0.22, 0.22, 0.26)
  love.graphics.rectangle("fill", 0, groundY + 8,  lw, 1)
  love.graphics.rectangle("fill", 0, groundY + 17, lw, 1)
  -- Vertical tile seams (only visible range, ~200 seams max)
  for i = 0, math.ceil(lw / 24) do
    love.graphics.rectangle("fill", i * 24, groundY, 1, 18)
  end
  -- Road
  love.graphics.setColor(0.14, 0.14, 0.16)
  love.graphics.rectangle("fill", 0, groundY + 18, lw, 32)
  -- Road center dashes
  love.graphics.setColor(0.90, 0.78, 0.20, 0.65)
  for i = 0, math.ceil(lw / 38) do
    love.graphics.rectangle("fill", i * 38, groundY + 30, 20, 3)
  end
end

-- ── Street furniture ─────────────────────────────────────────────────────────

local function drawStreetlamp(x, gY)
  love.graphics.setColor(0.35, 0.35, 0.40)
  love.graphics.rectangle("fill", x - 1, gY - 70, 3, 70)
  love.graphics.rectangle("fill", x - 1, gY - 70, 18, 3)
  love.graphics.setColor(0.42, 0.42, 0.46)
  love.graphics.rectangle("fill", x + 14, gY - 76, 10, 8, 2)
  -- Warm amber lamp glow
  love.graphics.setColor(0.98, 0.82, 0.35, 0.90)
  love.graphics.rectangle("fill", x + 15, gY - 74, 8, 5, 1)
  love.graphics.setColor(1.0, 0.85, 0.40, 0.30)
  love.graphics.rectangle("fill", x + 10, gY - 80, 18, 14, 4)
end

local function drawBench(x, gY)
  love.graphics.setColor(0.40, 0.30, 0.20)
  love.graphics.rectangle("fill", x, gY - 12, 28, 4, 1)
  love.graphics.rectangle("fill", x, gY - 22, 28, 4, 1)
  love.graphics.rectangle("fill", x + 2,  gY - 8, 3, 8)
  love.graphics.rectangle("fill", x + 23, gY - 8, 3, 8)
end

local function drawTree(x, gY)
  love.graphics.setColor(0.28, 0.20, 0.12)
  love.graphics.rectangle("fill", x - 4, gY - 50, 8, 50)
  -- Silhouette foliage against dusk sky
  love.graphics.setColor(0.12, 0.22, 0.10)
  love.graphics.ellipse("fill", x, gY - 68, 24, 28)
  love.graphics.setColor(0.16, 0.28, 0.12)
  love.graphics.ellipse("fill", x - 10, gY - 60, 18, 22)
  love.graphics.ellipse("fill", x + 10, gY - 62, 18, 22)
  love.graphics.setColor(0.20, 0.34, 0.14)
  love.graphics.ellipse("fill", x, gY - 80, 16, 18)
end

local function drawTrashcan(x, gY)
  love.graphics.setColor(0.22, 0.24, 0.26)
  love.graphics.rectangle("fill", x, gY - 20, 10, 20, 2)
  love.graphics.setColor(0.16, 0.18, 0.20)
  love.graphics.rectangle("fill", x - 1, gY - 22, 12, 4, 1)
end

-- ── Window drawing ────────────────────────────────────────────────────────────

local function drawWindow(x, y, w, h, lit, style)
  -- Frame
  love.graphics.setColor(0.12, 0.14, 0.20)
  love.graphics.rectangle("fill", x, y, w, h, 1)

  local iw, ih = w - 3, h - 3
  local ix, iy = x + 1, y + 1
  if style == "glass" then
    love.graphics.setColor(unpack(WINDOW_TINT))
    love.graphics.rectangle("fill", ix, iy, iw, ih)
  elseif lit then
    -- Amber glow halo (strong, dusk feel)
    love.graphics.setColor(1.0, 0.75, 0.20, 0.35)
    love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6, 2)
    -- Window face
    local wc = (math.floor(x * 3 + y * 7) % 3 == 0) and WINDOW_WARM2 or WINDOW_LIGHT
    love.graphics.setColor(wc[1], wc[2], wc[3])
    love.graphics.rectangle("fill", ix, iy, iw, ih)
  else
    love.graphics.setColor(unpack(WINDOW_DARK))
    love.graphics.rectangle("fill", ix, iy, iw, ih)
  end

  -- Pane dividers
  love.graphics.setColor(0.12, 0.14, 0.20)
  love.graphics.rectangle("fill", ix + iw/2 - 1, iy, 1, ih)
  if h > 12 then
    love.graphics.rectangle("fill", ix, iy + ih/2 - 1, iw, 1)
  end
end

-- ── AC unit ───────────────────────────────────────────────────────────────────

local function drawAC(x, y)
  love.graphics.setColor(0.28, 0.30, 0.34)
  love.graphics.rectangle("fill", x, y, 14, 8, 1)
  love.graphics.setColor(0.20, 0.22, 0.26)
  love.graphics.rectangle("fill", x + 1, y + 1, 12, 3)
  love.graphics.setColor(0.24, 0.26, 0.30)
  for i = 0, 3 do
    love.graphics.rectangle("fill", x + i*3 + 1, y + 5, 2, 2)
  end
end

-- ── Antenna ───────────────────────────────────────────────────────────────────

local function drawAntenna(x, y)
  love.graphics.setColor(0.25, 0.26, 0.30)
  love.graphics.rectangle("fill", x, y - 20, 1, 20)
  love.graphics.rectangle("fill", x - 8, y - 16, 17, 1)
  love.graphics.rectangle("fill", x - 5, y - 10, 11, 1)
  love.graphics.rectangle("fill", x - 3, y - 5,  7,  1)
  -- Red blinking light at tip
  love.graphics.setColor(1.0, 0.20, 0.10, 0.88)
  love.graphics.rectangle("fill", x - 1, y - 21, 3, 3)
end

-- ── Storefront (ground floor) ─────────────────────────────────────────────────

local function drawStorefront(b, gY, signIdx, signColIdx)
  local x, w = b.x, b.w
  local floorH = math.min(30, b.h * 0.30)
  local gy = gY - floorH

  -- Storefront (slightly lighter than building body)
  local c = BUILDING_COLS[b.paletteIdx or 1]
  love.graphics.setColor(c[1]*1.25, c[2]*1.22, c[3]*1.18)
  love.graphics.rectangle("fill", x, gy, w, floorH)

  -- Roll-up door or small door
  if w >= 28 then
    love.graphics.setColor(0.20, 0.22, 0.26)
    local dw, dh = math.min(w*0.55, 28), floorH - 4
    local dx = x + (w - dw) / 2
    love.graphics.rectangle("fill", dx, gy + 2, dw, dh, 1)
    love.graphics.setColor(0.16, 0.18, 0.22)
    for i = 1, math.floor(dh / 4) do
      love.graphics.rectangle("fill", dx + 1, gy + 2 + i*4, dw - 2, 1)
    end
  else
    love.graphics.setColor(0.22, 0.16, 0.10)
    love.graphics.rectangle("fill", x + w/2 - 5, gy + 4, 10, floorH - 4, 1)
  end

  -- Awning
  if (signIdx % 2) == 0 then
    local sc = SIGN_COLS[signColIdx or 1]
    love.graphics.setColor(sc[1], sc[2], sc[3], 0.88)
    love.graphics.rectangle("fill", x, gy - 6, w, 8)
    love.graphics.setColor(sc[1]*0.80, sc[2]*0.80, sc[3]*0.80)
    love.graphics.rectangle("fill", x, gy - 6, w, 2)
  end

  -- Sign board
  if w >= 22 then
    local sc = SIGN_COLS[signColIdx or 1]
    love.graphics.setColor(sc[1]*0.90, sc[2]*0.90, sc[3]*0.90)
    love.graphics.rectangle("fill", x + 2, gy - 14, w - 4, 9, 1)
    love.graphics.setColor(1, 1, 1, 0.90)
    local name = SIGN_NAMES[((signIdx-1) % #SIGN_NAMES) + 1]
    love.graphics.printf(name, x + 2, gy - 13, w - 4, "center")
  end
end

-- ── Main building draw ────────────────────────────────────────────────────────

function CR.drawBuilding(b, groundY)
  if b.isDestroyed then
    love.graphics.setColor(0.18, 0.16, 0.14)
    love.graphics.rectangle("fill", b.x, groundY - 10, b.w, 10)
    love.graphics.setColor(0.12, 0.10, 0.08)
    love.graphics.rectangle("fill", b.x + 2, groundY - 6, b.w - 4, 6)
    -- Dust/smoke wisps
    love.graphics.setColor(0.35, 0.28, 0.22, 0.45)
    love.graphics.ellipse("fill", b.x + b.w/2, groundY - 18, b.w*0.4, 12)
    -- Embers
    love.graphics.setColor(1.0, 0.45, 0.10, 0.55)
    love.graphics.ellipse("fill", b.x + b.w*0.35, groundY - 22, 4, 6)
    return
  end

  local c   = BUILDING_COLS[b.paletteIdx or 1]
  local dmg = b.health / b.maxHealth

  -- Damage shifts toward charcoal/red
  local dr = c[1] * (0.5 + 0.5*dmg)
  local dg = c[2] * (0.5 + 0.5*dmg)
  local db = c[3] * (0.45 + 0.55*dmg)

  -- ── Main body ──────────────────────────────────────────────────────────────
  love.graphics.setColor(dr, dg, db)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)

  -- ── Cornices / floor banding ───────────────────────────────────────────────
  love.graphics.setColor(dr*TRIM_DARKEN, dg*TRIM_DARKEN, db*TRIM_DARKEN)
  love.graphics.rectangle("fill", b.x - 2, b.y, b.w + 4, 3)
  local floorH = b.floorH or 22
  for floor = 1, math.floor(b.h / floorH) do
    love.graphics.rectangle("fill", b.x, b.y + floor * floorH - 1, b.w, 2)
  end

  -- ── Windows (mostly lit — dusk city glow) ─────────────────────────────────
  if b.w >= 16 then
    local winW   = math.max(7,  math.floor(b.w * 0.28))
    local winH   = math.max(9,  math.floor(floorH * 0.55))
    local cols   = math.max(1,  math.floor((b.w - 8) / (winW + 6)))
    local colGap = math.floor((b.w - cols * winW) / (cols + 1))

    for floor = 1, math.floor((b.h - 8) / floorH) do
      if floor == math.floor(b.h / floorH) and b.hasStorefront then break end
      local wy = b.y + floor * floorH - winH - 2
      for col = 0, cols - 1 do
        local wx   = b.x + colGap + col * (winW + colGap)
        local hash = (floor * 19 + col * 37 + math.floor(b.x) * 11) % 100
        local lit  = (hash > 28) and (dmg > 0.35)   -- ~72% of windows lit
        local style = (hash % 5 == 0) and "glass" or "normal"
        drawWindow(wx, wy, winW, winH, lit, style)
        if math.random() < 0.14 and winW >= 9 then
          drawAC(wx + (winW - 14)/2, wy + winH - 1)
        end
      end
    end
  end

  -- ── Storefront ────────────────────────────────────────────────────────────
  if b.hasStorefront and b.w >= 20 then
    drawStorefront(b, groundY, b.signIdx or 1, b.signColIdx or 1)
  end

  -- ── Rooftop details ───────────────────────────────────────────────────────
  if b.w >= 14 then
    -- Parapet
    love.graphics.setColor(dr*TRIM_DARKEN, dg*TRIM_DARKEN, db*TRIM_DARKEN)
    love.graphics.rectangle("fill", b.x, b.y - 5, b.w, 5)
    love.graphics.rectangle("fill", b.x - 2, b.y - 5, 4, 5)
    love.graphics.rectangle("fill", b.x + b.w - 2, b.y - 5, 4, 5)

    -- ── PLATFORM TOP EDGE (Mario-style landing surface) ────────────────────
    -- Bright highlight strip so players can see exactly where to land
    love.graphics.setColor(0.55, 0.52, 0.68, 0.90)
    love.graphics.rectangle("fill", b.x - 2, b.y - 5, b.w + 4, 3)
    love.graphics.setColor(0.70, 0.65, 0.82, 0.50)
    love.graphics.rectangle("fill", b.x - 2, b.y - 6, b.w + 4, 1)

    if b.hasAntenna then
      drawAntenna(b.x + b.w * (b.antennaX or 0.3), b.y)
      if b.hasSecondAntenna then
        drawAntenna(b.x + b.w * 0.7, b.y)
      end
    end

    if b.hasWaterTower and b.h > 70 then
      local tx = b.x + b.w * 0.6
      local ty = b.y - 20
      love.graphics.setColor(0.22, 0.16, 0.10)
      love.graphics.rectangle("fill", tx,   ty + 10, 2, 12)
      love.graphics.rectangle("fill", tx+8, ty + 10, 2, 12)
      love.graphics.rectangle("fill", tx+4, ty + 8,  2, 14)
      love.graphics.setColor(0.30, 0.22, 0.14)
      love.graphics.rectangle("fill", tx - 2, ty, 16, 12, 3)
      love.graphics.setColor(0.22, 0.16, 0.10)
      love.graphics.rectangle("fill", tx - 2, ty, 16, 3, 3)
    end
  end

  -- ── Damage cracks and fire ────────────────────────────────────────────────
  if dmg < 0.6 then
    love.graphics.setColor(0.08, 0.06, 0.04, 0.80)
    love.graphics.rectangle("fill", b.x + b.w*0.3, b.y + b.h*0.2, 1, b.h*0.3)
    love.graphics.rectangle("fill", b.x + b.w*0.6, b.y + b.h*0.5, 1, b.h*0.2)
    -- Smoke
    love.graphics.setColor(0.25, 0.20, 0.16, 0.30)
    love.graphics.ellipse("fill", b.x + b.w*0.4, b.y + 8, 10, 6)
  end
  if dmg < 0.35 then
    -- Fire glow at base
    love.graphics.setColor(1.0, 0.35, 0.05, 0.45)
    love.graphics.rectangle("fill", b.x, b.y, b.w, 4)
    -- Broken windows flash orange
    love.graphics.setColor(1.0, 0.55, 0.10, 0.25)
    love.graphics.rectangle("fill", b.x + 2, b.y + 4, b.w - 4, 8)
  end
end

-- ── Level generator ───────────────────────────────────────────────────────────

function CR.generateBuildings(levelW, groundY)
  local buildings = {}
  local x = 200
  local signIdx = 1

  while x < levelW - 150 do
    local pi  = math.random(#BUILDING_COLS)
    local w   = math.random(28, 75)
    local h   = math.random(60, 190)
    local fh  = math.random(20, 26)
    h = math.ceil(h / fh) * fh

    local hp  = math.ceil(w * 0.75)
    table.insert(buildings, {
      x            = x,
      y            = groundY - h,
      w            = w,
      h            = h,
      health       = hp,
      maxHealth    = hp,
      isDestroyed  = false,
      dollarsValue = 5000000,
      paletteIdx   = pi,
      floorH       = fh,
      hasStorefront   = (math.random() < 0.45) and (h < 80),
      signIdx         = signIdx,
      signColIdx      = math.random(#SIGN_COLS),
      hasAntenna      = (math.random() < 0.50),
      antennaX        = 0.2 + math.random() * 0.6,
      hasSecondAntenna= (math.random() < 0.25),
      hasWaterTower   = (math.random() < 0.20) and (h > 60),
    })
    signIdx = signIdx + 1
    x = x + w + math.random(5, 24)
  end
  return buildings
end

-- ── Street furniture generator ────────────────────────────────────────────────

function CR.generateFurniture(levelW, groundY)
  local items = {}
  local x = 60
  while x < levelW - 60 do
    table.insert(items, { kind="lamp",  x=x, y=groundY })
    x = x + math.random(100, 160)
  end
  x = 110
  while x < levelW - 60 do
    table.insert(items, { kind="tree",  x=x, y=groundY })
    x = x + math.random(180, 260)
  end
  x = 200
  while x < levelW - 60 do
    table.insert(items, { kind="bench", x=x, y=groundY })
    x = x + math.random(220, 350)
  end
  x = 80
  while x < levelW - 40 do
    table.insert(items, { kind="trash", x=x, y=groundY })
    x = x + math.random(140, 240)
  end
  return items
end

function CR.drawFurniture(item)
  if item.kind == "lamp"  then drawStreetlamp(item.x, item.y) end
  if item.kind == "tree"  then drawTree(item.x, item.y) end
  if item.kind == "bench" then drawBench(item.x, item.y) end
  if item.kind == "trash" then drawTrashcan(item.x, item.y) end
end

-- ── Restaurant building (special per-city landmark) ──────────────────────────

function CR.drawRestaurant(x, groundY, name, signCol, sub)
  local w, h = 60, 70
  local bx   = x - w / 2
  local by   = groundY - h

  -- Building body (warmer color than regular buildings)
  love.graphics.setColor(0.20, 0.16, 0.14)
  love.graphics.rectangle("fill", bx, by, w, h)

  -- Lit windows (lots, warm amber)
  love.graphics.setColor(0.95, 0.80, 0.30, 0.85)
  for row = 1, 3 do
    for col = 0, 2 do
      love.graphics.rectangle("fill", bx + 6 + col*18, by + 8 + row*16, 10, 10)
    end
  end
  -- Window glow halos
  love.graphics.setColor(1.0, 0.75, 0.25, 0.25)
  for row = 1, 3 do
    for col = 0, 2 do
      love.graphics.rectangle("fill", bx + 4 + col*18, by + 6 + row*16, 14, 14)
    end
  end

  -- Awning
  local sc = signCol or {0.88, 0.65, 0.15}
  love.graphics.setColor(sc[1], sc[2], sc[3])
  love.graphics.rectangle("fill", bx - 4, groundY - 28, w + 8, 10, 2)
  love.graphics.setColor(sc[1]*0.7, sc[2]*0.7, sc[3]*0.7)
  love.graphics.rectangle("fill", bx - 4, groundY - 28, w + 8, 3, 2)
  -- Awning fringe
  for i = 0, 6 do
    love.graphics.setColor(sc[1]*0.85, sc[2]*0.85, sc[3]*0.85)
    love.graphics.rectangle("fill", bx - 2 + i*9, groundY - 18, 6, 5)
  end

  -- Door
  love.graphics.setColor(0.28, 0.20, 0.14)
  love.graphics.rectangle("fill", bx + w/2 - 7, groundY - 18, 14, 18, 1)
  -- Door window
  love.graphics.setColor(0.95, 0.80, 0.30, 0.60)
  love.graphics.rectangle("fill", bx + w/2 - 5, groundY - 16, 10, 8)

  -- Neon sign (above awning)
  love.graphics.setColor(sc[1]*0.6, sc[2]*0.6, sc[3]*0.6, 0.9)
  love.graphics.rectangle("fill", bx + 2, by - 14, w - 4, 16, 2)
  -- Neon glow
  love.graphics.setColor(sc[1], sc[2], sc[3], 0.85)
  love.graphics.rectangle("fill", bx + 4, by - 12, w - 8, 12, 2)
  love.graphics.setColor(sc[1], sc[2], sc[3], 0.35)
  love.graphics.rectangle("fill", bx - 2, by - 18, w + 4, 22, 3)
  -- Sign text (restaurant name, abbreviated if long)
  love.graphics.setColor(1, 1, 1, 0.90)
  local displayName = (name and #name > 16) and (name:sub(1,14).."…") or (name or "DINER")
  love.graphics.printf(displayName, bx + 2, by - 11, w - 4, "center")

  -- Platform top highlight
  love.graphics.setColor(0.55, 0.52, 0.68, 0.90)
  love.graphics.rectangle("fill", bx - 2, by - 5, w + 4, 3)
end

-- ── Question-mark item box (Mario-style collectible) ──────────────────────────

function CR.drawItemBox(x, y, w, h, pulse, collected)
  if collected then return end
  local bob = math.sin(pulse * 3) * 2  -- gentle float

  -- Shadow
  love.graphics.setColor(0, 0, 0, 0.30)
  love.graphics.rectangle("fill", x + 2, y + h + bob + 2, w, 3, 1)

  -- Box body
  love.graphics.setColor(0.95, 0.70, 0.05)
  love.graphics.rectangle("fill", x, y + bob, w, h, 2)

  -- 3D top/left highlight
  love.graphics.setColor(1.0, 0.90, 0.40)
  love.graphics.rectangle("fill", x,     y + bob,     w, 3)
  love.graphics.rectangle("fill", x,     y + bob,     3, h)

  -- 3D bottom/right shadow
  love.graphics.setColor(0.65, 0.42, 0.02)
  love.graphics.rectangle("fill", x,     y + bob + h - 3, w, 3)
  love.graphics.rectangle("fill", x + w - 3, y + bob, 3, h)

  -- Outline
  love.graphics.setColor(0.30, 0.18, 0.02)
  love.graphics.rectangle("line", x, y + bob, w, h, 2)

  -- Question mark
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.printf("?", x - 2, y + bob + math.floor(h*0.18), w + 4, "center")
end

return CR
