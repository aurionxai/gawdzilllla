-- src/scenes/world_map.lua
local SM   = require("src/scene_manager")
local SS   = require("src/story_state")

-- CHARS table (same list as character_select, needed for defender lookup)
local CHARS = {
  { name="Godzilla",      module="src/characters/godzilla",      color={0.20,0.60,0.30}, hp=120, spd=70  },
  { name="Kong",          module="src/characters/kong",          color={0.55,0.38,0.22}, hp=110, spd=85  },
  { name="Mothra",        module="src/characters/mothra",        color={0.88,0.80,0.55}, hp=90,  spd=90  },
  { name="Rodan",         module="src/characters/rodan",         color={0.55,0.25,0.18}, hp=95,  spd=100 },
  { name="Ghidorah",      module="src/characters/ghidorah",      color={0.85,0.75,0.10}, hp=130, spd=60  },
  { name="MechaGodzilla", module="src/characters/mechagodzilla", color={0.63,0.65,0.70}, hp=140, spd=60  },
  { name="Biollante",     module="src/characters/biollante",     color={0.16,0.52,0.20}, hp=150, spd=50  },
  { name="Destoroyah",    module="src/characters/destoroyah",    color={0.38,0.08,0.12}, hp=135, spd=65  },
  { name="Gigan",         module="src/characters/gigan",         color={0.32,0.36,0.28}, hp=115, spd=80  },
  { name="SpaceGodzilla", module="src/characters/spacegodzilla", color={0.28,0.16,0.42}, hp=125, spd=70  },
  { name="Hedorah",       module="src/characters/hedorah",       color={0.20,0.30,0.18}, hp=100, spd=55  },
  { name="Anguirus",      module="src/characters/anguirus",      color={0.42,0.32,0.22}, hp=105, spd=75  },
  { name="Titan",         module="src/characters/titan",         color={0.08,0.20,0.72}, hp=80,  spd=110 },
  { name="Ironclad",      module="src/characters/ironclad",      color={0.72,0.10,0.10}, hp=90,  spd=100 },
  { name="Webslinger",    module="src/characters/webslinger",    color={0.72,0.08,0.08}, hp=70,  spd=130 },
  { name="Thunderstrike", module="src/characters/thunderstrike", color={0.32,0.48,0.72}, hp=85,  spd=105 },
}

-- Simplified continent rectangles for the background map
local LAND = {
  -- North America
  { x=42,  y=65,  w=130, h=95  },
  { x=65,  y=138, w=80,  h=22  },
  -- South America
  { x=102, y=152, w=65,  h=78  },
  -- Europe
  { x=196, y=68,  w=52,  h=52  },
  -- Africa
  { x=210, y=115, w=52,  h=92  },
  -- Asia main
  { x=246, y=58,  w=190, h=112 },
  -- Indian subcontinent
  { x=278, y=148, w=35,  h=32  },
  -- Australia
  { x=360, y=166, w=78,  h=46  },
  -- Greenland
  { x=155, y=52,  w=30,  h=22  },
  -- Japan islands (rough)
  { x=370, y=116, w=20,  h=18  },
}

local WM = {}
WM.__index = WM

function WM.new(lastResult)
  -- lastResult: { won=bool, cityKey=string } or nil (first visit)
  local self = setmetatable({
    _cursor      = 1,
    _pulse       = 0,
    _lastResult  = lastResult,
    _resultTimer = lastResult and 2.5 or 0,
    _CitiesData  = require("src/cities_data"),
  }, WM)

  -- Snap cursor to first available city that isn't conquered
  for i, city in ipairs(SS.CITIES) do
    if SS.isUnlocked(city) and not SS.isConquered(city.key) then
      self._cursor = i
      break
    end
  end

  return self
end

function WM:update(dt)
  self._pulse = self._pulse + dt * 3
  if self._resultTimer > 0 then
    self._resultTimer = self._resultTimer - dt
  end
end

function WM:_selectedCity()
  return SS.CITIES[self._cursor]
end

function WM:keypressed(key)
  if key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
    return
  end

  -- Navigate to next/prev available city
  if key == "right" or key == "d" or key == "down" or key == "s" then
    local n = #SS.CITIES
    for i = 1, n - 1 do
      local next = (self._cursor % n) + 1
      self._cursor = next
      if SS.isUnlocked(SS.CITIES[next]) then break end
    end
  elseif key == "left" or key == "a" or key == "up" or key == "w" then
    local n = #SS.CITIES
    for i = 1, n - 1 do
      local prev = ((self._cursor - 2 + n) % n) + 1
      self._cursor = prev
      if SS.isUnlocked(SS.CITIES[prev]) then break end
    end
  end

  if key == "return" or key == "space" then
    local city = self:_selectedCity()
    if not SS.isUnlocked(city) then return end

    -- Launch battle
    local defender = SS.getDefender(city, CHARS)
    local cityDef  = SS.findCityDef(self._CitiesData, city.cityName)

    local SC = require("src/scenes/story_card")
    SM.replace(SC.new(city.key, SS.playerChar, defender, self._CitiesData))
  end
end

function WM:draw()
  -- Ocean
  love.graphics.setColor(0.06, 0.10, 0.22)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Land masses
  love.graphics.setColor(0.14, 0.20, 0.14)
  for _, r in ipairs(LAND) do
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 2)
  end

  -- Connection lines
  for _, conn in ipairs(SS.CONNECTIONS) do
    local a = self:_cityByKey(conn[1])
    local b = self:_cityByKey(conn[2])
    if a and b then
      local bothConq = SS.isConquered(a.key) and SS.isConquered(b.key)
      if bothConq then
        love.graphics.setColor(0.8, 0.3, 0.1, 0.8)
      else
        love.graphics.setColor(0.3, 0.3, 0.45, 0.5)
      end
      love.graphics.line(a.x, a.y, b.x, b.y)
    end
  end

  -- City nodes
  for i, city in ipairs(SS.CITIES) do
    local unlocked  = SS.isUnlocked(city)
    local conquered = SS.isConquered(city.key)
    local selected  = (i == self._cursor)
    local pulse     = 0.6 + 0.4 * math.sin(self._pulse)

    -- Node dot
    if conquered then
      love.graphics.setColor(0.9, 0.35, 0.1)  -- fire orange = destroyed
    elseif selected and unlocked then
      love.graphics.setColor(1, 0.9, 0.1, pulse)
    elseif unlocked then
      love.graphics.setColor(0.7, 0.7, 0.3, 0.85)
    else
      love.graphics.setColor(0.25, 0.25, 0.32)
    end

    local r = city.isFinal and 5 or 4
    love.graphics.circle("fill", city.x, city.y, r)

    -- Selection ring
    if selected then
      love.graphics.setColor(1, 1, 0.3, pulse * 0.9)
      love.graphics.circle("line", city.x, city.y, r + 4)
    end

    -- City name label
    if unlocked or conquered then
      local textY = city.y + 6
      if conquered then
        love.graphics.setColor(0.9, 0.55, 0.25)
      elseif selected then
        love.graphics.setColor(1, 1, 0.5)
      else
        love.graphics.setColor(0.65, 0.65, 0.5)
      end
      love.graphics.printf(city.name, city.x - 45, textY, 90, "center")
    end
  end

  -- Info panel at bottom for selected city
  local city = self:_selectedCity()
  love.graphics.setColor(0, 0, 0, 0.70)
  love.graphics.rectangle("fill", 0, 240, 480, 30)

  if SS.isUnlocked(city) then
    local defender = SS.getDefender(city, CHARS)
    if SS.isConquered(city.key) then
      love.graphics.setColor(0.7, 0.4, 0.2)
      love.graphics.printf(city.name .. "  —  CONQUERED", 0, 246, 480, "center")
    elseif city.isFinal then
      love.graphics.setColor(1, 0.3, 0.3)
      love.graphics.printf("⚠  " .. city.name .. "  —  FINAL BOSS: " .. defender.name .. "  —  ENTER to fight", 0, 246, 480, "center")
    else
      love.graphics.setColor(0.85, 0.85, 0.5)
      love.graphics.printf(city.name .. "  —  Defender: " .. defender.name .. "  —  ENTER to fight", 0, 246, 480, "center")
    end
  else
    love.graphics.setColor(0.4, 0.4, 0.55)
    local needed = {}
    for _, req in ipairs(city.requires) do
      if not SS.isConquered(req) then
        local reqCity = self:_cityByKey(req)
        if reqCity then table.insert(needed, reqCity.name) end
      end
    end
    love.graphics.printf("LOCKED — Conquer: " .. table.concat(needed, ", "), 0, 246, 480, "center")
  end

  -- Victory/defeat flash
  if self._resultTimer > 0 and self._lastResult then
    local alpha = math.min(1, self._resultTimer)
    if self._lastResult.won then
      love.graphics.setColor(0.1, 0.8, 0.3, alpha * 0.7)
    else
      love.graphics.setColor(0.8, 0.1, 0.1, alpha * 0.6)
    end
    love.graphics.rectangle("fill", 0, 0, 480, 270)
    if self._lastResult.won then
      love.graphics.setColor(0.3, 1, 0.5, alpha)
      love.graphics.printf("CITY CONQUERED!", 0, 116, 480, "center")
    else
      love.graphics.setColor(1, 0.4, 0.4, alpha)
      love.graphics.printf("DEFEATED… TRY AGAIN", 0, 116, 480, "center")
    end
  end

  -- Header
  love.graphics.setColor(0.7, 0.7, 0.9, 0.9)
  love.graphics.printf("WORLD MAP  —  " .. SS.playerChar.name, 0, 4, 480, "center")
  local cnt = 0
  for k in pairs(SS.conquered) do cnt = cnt + 1 end
  love.graphics.setColor(0.5, 0.5, 0.7)
  love.graphics.printf(cnt .. "/" .. #SS.CITIES .. " cities", 0, 14, 480, "center")

  -- Controls
  love.graphics.setColor(0.3, 0.3, 0.42)
  love.graphics.printf("A/D navigate   ENTER fight   ESC menu", 0, 258, 480, "center")
end

function WM:_cityByKey(key)
  for _, c in ipairs(SS.CITIES) do
    if c.key == key then return c end
  end
end

return WM
