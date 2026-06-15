-- src/scenes/character_select.lua
local SM = require("src/scene_manager")

local CS = {}
CS.__index = CS

local CHARS = {
  -- Row 1
  { name="Godzilla",      module="src/characters/godzilla",      color={0.20,0.60,0.30}, hp=120, spd=70,  arch="Heavy hitter"  },
  { name="Kong",          module="src/characters/kong",          color={0.55,0.38,0.22}, hp=110, spd=85,  arch="Fast striker"  },
  { name="Mothra",        module="src/characters/mothra",        color={0.88,0.80,0.55}, hp=90,  spd=90,  arch="Beam blaster"  },
  { name="Rodan",         module="src/characters/rodan",         color={0.55,0.25,0.18}, hp=95,  spd=100, arch="Aerial ace"    },
  -- Row 2
  { name="Ghidorah",      module="src/characters/ghidorah",      color={0.85,0.75,0.10}, hp=130, spd=60,  arch="Triple threat" },
  { name="MechaGodzilla", module="src/characters/mechagodzilla", color={0.63,0.65,0.70}, hp=140, spd=60,  arch="Missile tank"  },
  { name="Biollante",     module="src/characters/biollante",     color={0.16,0.52,0.20}, hp=150, spd=50,  arch="Acid grappler" },
  { name="Destoroyah",    module="src/characters/destoroyah",    color={0.38,0.08,0.12}, hp=135, spd=65,  arch="Oxygen slayer" },
  -- Row 3
  { name="Gigan",         module="src/characters/gigan",         color={0.32,0.36,0.28}, hp=115, spd=80,  arch="Buzzsaw fury"  },
  { name="SpaceGodzilla", module="src/characters/spacegodzilla", color={0.28,0.16,0.42}, hp=125, spd=70,  arch="Crystal king"  },
  { name="Hedorah",       module="src/characters/hedorah",       color={0.20,0.30,0.18}, hp=100, spd=55,  arch="Sludge beast"  },
  { name="Anguirus",      module="src/characters/anguirus",      color={0.42,0.32,0.22}, hp=105, spd=75,  arch="Rolling spike" },
  -- Row 4: Heroes
  { name="Titan",         module="src/characters/titan",         color={0.08,0.20,0.72}, hp=80,  spd=110, arch="Laser vision"  },
  { name="Ironclad",      module="src/characters/ironclad",      color={0.72,0.10,0.10}, hp=90,  spd=100, arch="Repulsor blast"},
  { name="Webslinger",    module="src/characters/webslinger",    color={0.72,0.08,0.08}, hp=70,  spd=130, arch="Web acrobat"   },
  { name="Thunderstrike", module="src/characters/thunderstrike", color={0.32,0.48,0.72}, hp=85,  spd=105, arch="Lightning god" },
}

local COLS    = 4
local CARD_W  = 108
local CARD_H  = 57
local PAD_X   = 6
local PAD_Y   = 4
local START_X = math.floor((480 - (COLS * CARD_W + (COLS-1) * PAD_X)) / 2)
local START_Y = 14

function CS.new(isSinglePlayer, isStoryMode)
  local previews = {}
  for _, c in ipairs(CHARS) do
    local path = "sprites/characters/" .. c.name .. "_Frame0.png"
    local ok, img = pcall(love.graphics.newImage, path)
    previews[c.name] = ok and img or nil
  end
  return setmetatable({
    _cursor         = 1,
    _p1Idx          = nil,
    _p2Idx          = nil,
    _selectingP2    = false,
    _previews       = previews,
    _confirmTimer   = 0,
    _isSinglePlayer = isSinglePlayer or false,
    _isStoryMode    = isStoryMode or false,
  }, CS)
end

function CS:update(dt)
  if self._confirmTimer > 0 then
    self._confirmTimer = self._confirmTimer - dt
    if self._confirmTimer <= 0 then
      if self._isStoryMode then
        local SS = require("src/story_state")
        local WM = require("src/scenes/world_map")
        SS.startNew(CHARS[self._p1Idx])
        SM.replace(WM.new())
      else
        local Battle = require("src/scenes/battle")
        SM.replace(Battle.new(CHARS[self._p1Idx], CHARS[self._p2Idx], self._isSinglePlayer))
      end
    end
  end
end

function CS:_cardPos(idx)
  local col = (idx - 1) % COLS
  local row = math.floor((idx - 1) / COLS)
  return START_X + col * (CARD_W + PAD_X),
         START_Y + row * (CARD_H + PAD_Y)
end

function CS:draw()
  love.graphics.setColor(0.04, 0.05, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Header
  local phase
  if self._isStoryMode then
    phase = "STORY — CHOOSE YOUR KAIJU"
  elseif self._isSinglePlayer then
    phase = "PICK YOUR FIGHTER"
  else
    phase = self._selectingP2 and "P2 — PICK YOUR FIGHTER" or "P1 — PICK YOUR FIGHTER"
  end
  local hcol  = self._selectingP2 and {1,0.3,0.3} or {0.2,0.7,1}
  love.graphics.setColor(hcol)
  love.graphics.printf(phase, 0, 2, 480, "center")

  -- Cards
  for i, c in ipairs(CHARS) do
    local x, y = self:_cardPos(i)
    local sel   = (i == self._cursor)
    local isP1  = (i == self._p1Idx)
    local isP2  = (i == self._p2Idx)

    -- Card background
    if sel then
      love.graphics.setColor(0.14, 0.14, 0.28)
    elseif isP1 or isP2 then
      love.graphics.setColor(0.10, 0.10, 0.22)
    else
      love.graphics.setColor(0.07, 0.07, 0.14)
    end
    love.graphics.rectangle("fill", x, y, CARD_W, CARD_H, 3)

    -- Border
    if sel then
      local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 6)
      love.graphics.setColor(hcol[1], hcol[2], hcol[3], pulse)
      love.graphics.rectangle("line", x, y, CARD_W, CARD_H, 3)
    elseif isP1 then
      love.graphics.setColor(0.2, 0.7, 1, 0.8)
      love.graphics.rectangle("line", x, y, CARD_W, CARD_H, 3)
    elseif isP2 then
      love.graphics.setColor(1, 0.3, 0.3, 0.8)
      love.graphics.rectangle("line", x, y, CARD_W, CARD_H, 3)
    end

    -- Portrait (centered top, max 52×28 display)
    local img = self._previews[c.name]
    if img then
      local iw, ih = img:getDimensions()
      local scale  = math.min(52 / iw, 28 / ih)
      local pw     = math.floor(iw * scale)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(img, x + math.floor((CARD_W - pw) / 2), y + 3, 0, scale, scale)
    else
      love.graphics.setColor(c.color)
      love.graphics.rectangle("fill", x + CARD_W/2 - 14, y + 3, 28, 28, 2)
    end

    -- Name (centered, below portrait)
    love.graphics.setColor(sel and {1,1,1} or {0.80,0.80,0.90})
    love.graphics.printf(c.name, x + 2, y + 34, CARD_W - 4, "center")

    -- Stats (one line, centered)
    love.graphics.setColor(0.55, 0.60, 0.75)
    love.graphics.printf(
      string.format("%dhp  %dspd", c.hp, c.spd),
      x + 2, y + 46, CARD_W - 4, "center")

    -- P1/P2 badge (top-right corner)
    if isP1 then
      love.graphics.setColor(0.2, 0.7, 1)
      love.graphics.printf("P1", x, y + 2, CARD_W - 3, "right")
    end
    if isP2 then
      love.graphics.setColor(1, 0.3, 0.3)
      love.graphics.printf("P2", x, y + 2, CARD_W - 3, "right")
    end
  end

  -- Archetype info strip for selected character
  local sel_c = CHARS[self._cursor]
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 246, 480, 14)
  love.graphics.setColor(0.70, 0.70, 0.85)
  love.graphics.printf(
    sel_c.name .. "  —  " .. sel_c.arch,
    0, 248, 480, "center")

  -- VS banner
  if self._p1Idx and self._p2Idx then
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", 90, 100, 300, 38, 6)
    love.graphics.setColor(0.9, 0.75, 0.1)
    love.graphics.printf(
      CHARS[self._p1Idx].name .. "  vs  " .. CHARS[self._p2Idx].name,
      90, 112, 300, "center")
  end

  -- Controls
  love.graphics.setColor(0.28, 0.28, 0.42)
  love.graphics.printf("WASD/Arrows move   ENTER/SPACE confirm   ESC back", 0, 260, 480, "center")
end

function CS:keypressed(key)
  if self._confirmTimer > 0 then return end

  if key == "right" or key == "d" then
    self._cursor = (self._cursor % #CHARS) + 1
  elseif key == "left" or key == "a" then
    self._cursor = ((self._cursor - 2 + #CHARS) % #CHARS) + 1
  elseif key == "down" or key == "s" then
    local next = self._cursor + COLS
    if next <= #CHARS then self._cursor = next end
  elseif key == "up" or key == "w" then
    local prev = self._cursor - COLS
    if prev >= 1 then self._cursor = prev end
  end

  if key == "escape" then
    if self._selectingP2 and not self._isSinglePlayer then
      self._selectingP2 = false
      self._p1Idx       = nil
    else
      local MM = require("src/scenes/main_menu")
      SM.replace(MM.new())
    end
    return
  end

  if key == "return" or key == "space" then
    if self._isStoryMode then
      -- Story: pick your kaiju only, world map handles opponents
      self._p1Idx        = self._cursor
      self._confirmTimer = 0.5
    elseif self._isSinglePlayer then
      -- 1P: just pick for P1, CPU gets a random different character
      self._p1Idx = self._cursor
      local cpuIdx
      repeat cpuIdx = math.random(#CHARS) until cpuIdx ~= self._p1Idx
      self._p2Idx        = cpuIdx
      self._confirmTimer = 0.5
    elseif not self._selectingP2 then
      self._p1Idx       = self._cursor
      self._selectingP2 = true
      self._cursor      = (self._p1Idx % #CHARS) + 1
    else
      if self._cursor == self._p1Idx then
        self._cursor = (self._cursor % #CHARS) + 1
        return
      end
      self._p2Idx        = self._cursor
      self._confirmTimer = 0.5
    end
  end
end

return CS
