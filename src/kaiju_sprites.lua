-- src/kaiju_sprites.lua
-- Pixel-art kaiju sprite renderer. All shapes drawn with love.graphics.rectangle.
-- Usage: KS.draw(characterName, ctrl)
-- Sprites are designed at 28×44 game pixels (displayed at 2x = 56×88 screen px).
-- Origin: (0,0) = foot center. Sprite always drawn facing right; scale(-1,1) when facing left.

local KS = {}
KS._flash = false   -- set true before KS.draw to render sprite all-white (hit flash)

-- ── Draw helper ───────────────────────────────────────────────────────────────
-- Called inside each sprite function. Draws a rect relative to foot center.
local WHITE = {1, 1, 1}
local function R(c, x, y, w, h)
  love.graphics.setColor(KS._flash and WHITE or c)
  love.graphics.rectangle("fill", x, y, w, h)
end

-- ── Godzilla ──────────────────────────────────────────────────────────────────
local G_SH = {0.06, 0.12, 0.06}   -- deep shadow
local G_BG = {0.14, 0.28, 0.12}   -- base green
local G_MG = {0.22, 0.44, 0.17}   -- mid highlight
local G_HG = {0.33, 0.60, 0.24}   -- brightest highlight
local G_BE = {0.50, 0.62, 0.36}   -- belly/throat
local G_EY = {0.98, 0.92, 0.08}   -- yellow eye
local G_PU = {0.04, 0.04, 0.04}   -- pupil
local G_SP = {0.38, 0.06, 0.06}   -- dorsal spine (dark red)
local G_SK = {0.55, 0.10, 0.08}   -- spine highlight
local G_CL = {0.80, 0.76, 0.52}   -- claw
local G_TE = {0.90, 0.88, 0.84}   -- teeth

local function drawGodzilla(wt, grounded)
  local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0

  -- TAIL (behind = left when facing right)
  R(G_SH, -16, -8+bob, 6, 6)
  R(G_BG, -15, -7+bob, 5, 5)
  R(G_SH, -21, -5+bob, 6, 4)
  R(G_BG, -20, -5+bob, 5, 3)
  R(G_SH, -25, -3+bob, 5, 3)
  R(G_MG, -24, -3+bob, 4, 2)
  R(G_SH, -28, -1+bob, 5, 2)

  -- DORSAL SPINES (on back, left side)
  R(G_SP, -10, -43+bob, 5, 12)
  R(G_SK, -9,  -42+bob, 3,  8)
  R(G_SP, -9,  -35+bob, 4,  9)
  R(G_SK, -8,  -34+bob, 2,  6)
  R(G_SP, -8,  -28+bob, 4,  7)
  R(G_SK, -7,  -27+bob, 2,  5)
  R(G_SP, -7,  -22+bob, 3,  5)

  -- BODY
  R(G_SH, -11, -28+bob, 22, 18)
  R(G_BG, -10, -27+bob, 20, 17)
  R(G_MG,  -6, -26+bob, 14, 14)
  R(G_BE,  -5, -25+bob, 10, 12)
  -- Scale texture rows
  R(G_MG, -9, -22+bob, 4, 2)
  R(G_MG,  5, -22+bob, 4, 2)
  R(G_MG, -8, -17+bob, 4, 2)
  R(G_MG,  4, -17+bob, 4, 2)

  -- NECK
  R(G_SH, -5, -34+bob, 10, 8)
  R(G_BG, -4, -33+bob,  8, 7)
  R(G_BE, -3, -32+bob,  6, 5)

  -- HEAD (skull)
  R(G_SH, -8, -44+bob, 20, 13)
  R(G_BG, -7, -43+bob, 18, 11)
  R(G_MG, -5, -42+bob, 12,  7)
  -- Brow ridge
  R(G_SH, -8, -44+bob, 8, 3)
  R(G_SH,  6, -44+bob, 4, 2)

  -- SNOUT / LOWER JAW
  R(G_SH, -4, -34+bob, 14, 5)
  R(G_BG, -3, -34+bob, 12, 4)
  R(G_BE, -2, -33+bob,  8, 3)

  -- NOSTRIL
  R(G_SH,  2, -37+bob, 2, 2)

  -- EYE (prominent, glowing)
  R(G_SH,  3, -42+bob, 8, 6)   -- socket
  R(G_EY,  4, -41+bob, 7, 5)   -- iris
  R(G_PU,  6, -40+bob, 3, 3)   -- pupil
  -- glow
  love.graphics.setColor(G_EY[1], G_EY[2], G_EY[3], 0.30)
  love.graphics.rectangle("fill", 2, -43+bob, 10, 7)

  -- TEETH
  R(G_SH, -2, -30+bob, 10, 2)   -- gum line
  R(G_TE, -1, -28+bob,  2, 4)
  R(G_TE,  2, -28+bob,  2, 3)
  R(G_TE,  5, -28+bob,  2, 4)
  R(G_TE,  7, -28+bob,  2, 2)

  -- ARM LEFT (far, less detail)
  R(G_SH, -14, -26+bob, 5, 10)
  R(G_BG, -13, -25+bob, 4,  9)
  R(G_CL, -14, -17+bob, 2,  3)
  R(G_CL, -12, -16+bob, 2,  3)
  R(G_CL, -10, -16+bob, 2,  2)

  -- ARM RIGHT (near / front)
  R(G_BG,  9, -26+bob, 5, 10)
  R(G_MG, 10, -25+bob, 4,  8)
  R(G_CL,  9, -16+bob, 2,  3)
  R(G_CL, 11, -16+bob, 2,  3)
  R(G_CL, 13, -16+bob, 2,  2)

  -- LEGS
  R(G_SH, -11, -10+bob,  9, 10)
  R(G_BG, -10,  -9+bob,  7,  9)
  R(G_MG,  -8,  -8+bob,  4,  6)
  R(G_SH,   2, -10+bob,  9, 10)
  R(G_BG,   3,  -9+bob,  7,  9)
  R(G_HG,   4,  -8+bob,  4,  5)

  -- FEET
  R(G_SH, -13, -2+bob, 12, 4)
  R(G_BG, -12, -2+bob, 10, 3)
  R(G_CL, -14,  0,     3,  2)
  R(G_CL, -11,  0,     3,  2)
  R(G_CL,  -8,  0,     3,  2)
  R(G_SH,   0, -2+bob, 12, 4)
  R(G_BG,   1, -2+bob, 10, 3)
  R(G_CL,   0,  0,     3,  2)
  R(G_CL,   3,  0,     3,  2)
  R(G_CL,   6,  0,     3,  2)
end

-- ── Kong ─────────────────────────────────────────────────────────────────────
local K_SH  = {0.12, 0.08, 0.06}
local K_FU  = {0.28, 0.18, 0.12}   -- brown fur
local K_MF  = {0.42, 0.28, 0.18}   -- mid fur
local K_HF  = {0.56, 0.40, 0.26}   -- highlight fur
local K_SK  = {0.52, 0.35, 0.24}   -- skin (face/chest)
local K_EY  = {0.60, 0.80, 0.20}   -- green eyes
local K_PU  = {0.04, 0.04, 0.04}
local K_TE  = {0.88, 0.84, 0.78}

local function drawKong(wt, grounded)
  local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0
  -- Knuckle walk pose (arms longer, hunched)

  -- BODY (broad, muscular)
  R(K_SH, -12, -30+bob, 26, 22)
  R(K_FU, -11, -29+bob, 24, 21)
  R(K_MF,  -8, -27+bob, 18, 17)
  -- Chest bare skin
  R(K_SK,  -5, -26+bob, 12, 14)
  -- Fur texture patches
  R(K_HF, -10, -24+bob, 4, 4)
  R(K_HF,   6, -24+bob, 4, 4)
  R(K_HF, -10, -16+bob, 4, 4)
  R(K_HF,   6, -16+bob, 4, 4)

  -- NECK (thick)
  R(K_SH, -5, -36+bob, 12, 8)
  R(K_FU, -4, -35+bob, 10, 7)
  R(K_SK, -3, -34+bob,  8, 5)

  -- HEAD (large, ape-like)
  R(K_SH,  -9, -46+bob, 20, 14)
  R(K_FU,  -8, -45+bob, 18, 12)
  R(K_MF,  -6, -44+bob, 14,  9)
  -- Brow ridge (prominent)
  R(K_SH,  -8, -46+bob, 18,  4)
  R(K_FU,  -7, -45+bob, 14,  3)
  -- Face skin
  R(K_SK,  -5, -40+bob, 12,  8)

  -- EYES (under brow)
  R(K_SH,  -3, -42+bob, 6, 4)
  R(K_EY,  -2, -41+bob, 5, 3)
  R(K_PU,  -1, -40+bob, 2, 2)
  love.graphics.setColor(K_EY[1], K_EY[2], K_EY[3], 0.25)
  love.graphics.rectangle("fill", -4, -43+bob, 8, 5)

  -- NOSE / MOUTH
  R(K_SH, -2, -36+bob, 6, 2)   -- nostrils
  R(K_SH, -4, -33+bob, 10, 3)  -- mouth
  R(K_TE, -3, -32+bob,  2, 3)
  R(K_TE,  0, -32+bob,  2, 3)
  R(K_TE,  3, -32+bob,  2, 3)

  -- EARS
  R(K_FU, -10, -43+bob, 4, 5)
  R(K_SK,  -9, -42+bob, 2, 3)

  -- ARMS (long, powerful — partially knuckle pose)
  R(K_SH, -15, -28+bob, 7, 16)
  R(K_FU, -14, -27+bob, 6, 15)
  R(K_MF, -13, -26+bob, 4, 12)
  -- Fist
  R(K_SK, -15, -14+bob, 8, 7)
  R(K_SH, -16, -13+bob, 9, 5)

  R(K_SH,  8, -28+bob, 7, 16)
  R(K_FU,  9, -27+bob, 6, 15)
  R(K_MF, 10, -26+bob, 4, 12)
  R(K_SK,  8, -14+bob, 8,  7)

  -- LEGS
  R(K_SH, -10, -10+bob,  8, 10)
  R(K_FU,  -9,  -9+bob,  6,  9)
  R(K_MF,  -8,  -8+bob,  4,  6)
  R(K_SH,   2, -10+bob,  8, 10)
  R(K_FU,   3,  -9+bob,  6,  9)
  R(K_HF,   4,  -8+bob,  4,  5)

  -- FEET
  R(K_SH, -12, -2+bob, 10, 4)
  R(K_SK, -11, -1+bob,  8, 3)
  R(K_SH,   2, -2+bob, 10, 4)
  R(K_SK,   3, -1+bob,  8, 3)
end

-- ── Mechagodzilla ─────────────────────────────────────────────────────────────
local M_SH = {0.20, 0.22, 0.26}   -- shadow metal
local M_BG = {0.50, 0.52, 0.58}   -- base silver
local M_HM = {0.72, 0.75, 0.82}   -- highlight metal
local M_WH = {0.88, 0.90, 0.95}   -- bright chrome
local M_EY = {0.95, 0.08, 0.08}   -- red laser eye
local M_AC = {0.10, 0.60, 0.95}   -- blue accent/vents
local M_GD = {0.70, 0.62, 0.20}   -- gold accents
local M_BO = {0.85, 0.20, 0.10}   -- orange glow (chest cannon)

local function drawMechagodzilla(wt, grounded)
  local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0

  -- TAIL (mechanical segments)
  R(M_SH, -16, -8+bob, 6, 6)
  R(M_BG, -15, -7+bob, 4, 4)
  R(M_HM, -14, -8+bob, 2, 2)
  R(M_SH, -21, -5+bob, 6, 4)
  R(M_BG, -20, -5+bob, 4, 3)
  R(M_SH, -25, -3+bob, 5, 3)
  R(M_BG, -24, -3+bob, 3, 2)
  -- Segment joints
  R(M_GD, -17, -7+bob, 2, 3)
  R(M_GD, -22, -5+bob, 2, 2)

  -- BODY (armored plating)
  R(M_SH, -12, -30+bob, 24, 22)
  R(M_BG, -11, -29+bob, 22, 20)
  R(M_HM,  -8, -27+bob, 18, 16)
  -- Chest cannon
  R(M_SH,  -4, -24+bob, 10, 10)
  R(M_BO,  -3, -23+bob,  8,  8, 2)
  love.graphics.setColor(M_BO[1], M_BO[2], M_BO[3], 0.40)
  love.graphics.rectangle("fill", -5, -25+bob, 12, 12)
  -- Plate lines
  R(M_SH, -10, -22+bob, 22, 1)
  R(M_SH, -10, -16+bob, 22, 1)
  R(M_WH,  -9, -22+bob, 20, 1)
  -- Vent slots (blue)
  for i = 0, 2 do
    R(M_AC, 6, -26+i*4+bob, 4, 2)
  end

  -- NECK
  R(M_SH, -5, -36+bob, 10, 8)
  R(M_BG, -4, -35+bob,  8, 7)
  R(M_HM, -3, -34+bob,  6, 5)
  -- Neck joint rings
  R(M_GD, -5, -36+bob, 10, 2)
  R(M_GD, -5, -30+bob, 10, 2)

  -- HEAD (boxy, armored)
  R(M_SH,  -9, -46+bob, 20, 12)
  R(M_BG,  -8, -45+bob, 18, 10)
  R(M_HM,  -6, -44+bob, 14,  8)
  R(M_WH,  -4, -43+bob, 10,  4)
  -- Head ridge
  R(M_GD,  -8, -46+bob, 18,  3)
  -- Jaw
  R(M_SH,  -6, -35+bob, 14,  4)
  R(M_BG,  -5, -35+bob, 12,  3)
  R(M_HM,  -3, -35+bob,  8,  2)

  -- EYES (red, glowing)
  R(M_SH,  -1, -43+bob, 8, 5)
  R(M_EY,   0, -42+bob, 7, 4)
  love.graphics.setColor(M_EY[1], M_EY[2], M_EY[3], 0.50)
  love.graphics.rectangle("fill", -2, -44+bob, 11, 6)
  -- Scan line
  R(M_EY,  -1, -40+bob, 8, 1)

  -- Teeth (metal)
  R(M_WH, -4, -33+bob, 2, 3)
  R(M_WH, -1, -33+bob, 2, 4)
  R(M_WH,  2, -33+bob, 2, 3)
  R(M_WH,  5, -33+bob, 2, 3)

  -- ARMS (mechanical, boxy)
  R(M_SH, -14, -28+bob, 6, 12)
  R(M_BG, -13, -27+bob, 5, 11)
  R(M_HM, -12, -26+bob, 3,  8)
  R(M_GD, -14, -23+bob, 6,  2)  -- elbow joint
  -- Hand / missile pod
  R(M_SH, -15, -17+bob, 8, 7)
  R(M_BG, -14, -17+bob, 6, 6)
  R(M_AC, -14, -16+bob, 2, 5)   -- missile ports
  R(M_AC, -11, -16+bob, 2, 5)

  R(M_SH,  8, -28+bob, 6, 12)
  R(M_BG,  9, -27+bob, 5, 11)
  R(M_HM, 10, -26+bob, 3,  8)
  R(M_GD,  8, -23+bob, 6,  2)
  R(M_SH,  7, -17+bob, 8,  7)
  R(M_BG,  8, -17+bob, 6,  6)
  R(M_AC,  8, -16+bob, 2,  5)
  R(M_AC, 11, -16+bob, 2,  5)

  -- LEGS (thick armor)
  R(M_SH, -12, -12+bob, 10, 12)
  R(M_BG, -11, -11+bob,  8, 11)
  R(M_HM,  -9,  -9+bob,  4,  7)
  R(M_GD, -12,  -8+bob, 10,  2)  -- knee joint
  R(M_SH,   2, -12+bob, 10, 12)
  R(M_BG,   3, -11+bob,  8, 11)
  R(M_HM,   5,  -9+bob,  4,  7)
  R(M_GD,   2,  -8+bob, 10,  2)

  -- FEET (heavy treads)
  R(M_SH, -14, -2+bob, 14, 4)
  R(M_BG, -13, -2+bob, 12, 3)
  R(M_GD, -14, -2+bob, 14, 1)
  R(M_SH,   0, -2+bob, 14, 4)
  R(M_BG,   1, -2+bob, 12, 3)
  R(M_GD,   0, -2+bob, 14, 1)
end

-- ── Mothra ────────────────────────────────────────────────────────────────────
local MO_BW = {0.88, 0.82, 0.55}  -- wing base warm
local MO_WL = {0.95, 0.90, 0.65}  -- wing light
local MO_WD = {0.72, 0.60, 0.25}  -- wing dark
local MO_WP = {0.80, 0.42, 0.60}  -- wing pink
local MO_WB = {0.28, 0.20, 0.12}  -- wing border
local MO_BO = {0.72, 0.65, 0.40}  -- body
local MO_FU = {0.88, 0.80, 0.55}  -- body fur
local MO_EY = {0.30, 0.85, 0.95}  -- cyan eye
local MO_PU = {0.04, 0.04, 0.04}

local function drawMothra(wt, grounded)
  local flapA = math.sin(wt * 4) * 8
  local bob = math.sin(wt * 3) * 2

  -- WINGS (large, decorated)
  -- Upper wing pair
  R(MO_WB, -28, -44+bob, 22, 16)
  R(MO_BW, -27, -43+bob, 20, 14)
  R(MO_WL, -25, -42+bob, 16, 10)
  -- Eye pattern on wing
  R(MO_WB, -22, -38+bob, 8, 6)
  R(MO_WP, -21, -37+bob, 6, 5)
  R(MO_EY, -20, -36+bob, 4, 3)
  R(MO_WD, -26, -40+bob, 4, 3)   -- dark leading edge
  -- Right upper wing
  R(MO_WB,  6, -44+bob, 22, 16)
  R(MO_BW,  7, -43+bob, 20, 14)
  R(MO_WL,  9, -42+bob, 16, 10)
  R(MO_WB, 14, -38+bob, 8, 6)
  R(MO_WP, 15, -37+bob, 6, 5)
  R(MO_EY, 16, -36+bob, 4, 3)
  R(MO_WD, 20, -40+bob, 4, 3)

  -- Lower wing pair (smaller)
  R(MO_WB, -22, -30+bob, 16, 18)
  R(MO_BW, -21, -29+bob, 14, 16)
  R(MO_WD, -20, -28+bob, 12, 14)
  R(MO_WP, -18, -26+bob,  8,  8)
  R(MO_WB,  6, -30+bob, 16, 18)
  R(MO_BW,  7, -29+bob, 14, 16)
  R(MO_WD,  8, -28+bob, 12, 14)
  R(MO_WP, 10, -26+bob,  8,  8)

  -- BODY (fuzzy caterpillar-like)
  R(MO_WB,  -7, -40+bob, 14, 28)
  R(MO_BO,  -6, -39+bob, 12, 26)
  R(MO_FU,  -4, -38+bob,  8, 22)
  -- Fur rings
  for i = 0, 4 do
    R(MO_WD, -6, -36+i*5+bob, 12, 1)
  end

  -- HEAD
  R(MO_WB,  -6, -46+bob, 12,  8)
  R(MO_BO,  -5, -45+bob, 10,  6)
  R(MO_FU,  -4, -44+bob,  8,  5)
  -- EYES
  R(MO_WB,  -4, -44+bob, 5, 4)
  R(MO_EY,  -3, -43+bob, 4, 3)
  R(MO_PU,  -2, -42+bob, 2, 2)
  R(MO_WB,   2, -44+bob, 5, 4)
  R(MO_EY,   3, -43+bob, 4, 3)
  R(MO_PU,   4, -42+bob, 2, 2)
  -- Antennae
  R(MO_WB,  -3, -52+bob, 2, 8)
  R(MO_WD,  -4, -53+bob, 4, 3)
  R(MO_WB,   2, -52+bob, 2, 8)
  R(MO_WD,   1, -53+bob, 4, 3)

  -- LEGS (tiny, under body)
  for i = 0, 3 do
    R(MO_WB, -6+i*3, 0, 2, 4)
    R(MO_WB, -5+i*3, 0, 2, 4)
  end
end

-- ── Ghidorah ─────────────────────────────────────────────────────────────────
local GH_SH = {0.35, 0.28, 0.02}
local GH_BG = {0.68, 0.58, 0.08}   -- gold
local GH_MG = {0.82, 0.72, 0.18}   -- bright gold
local GH_HG = {0.95, 0.88, 0.50}   -- highlight gold
local GH_EY = {0.95, 0.15, 0.08}   -- red eye
local GH_PU = {0.04, 0.04, 0.04}
local GH_WG = {0.58, 0.48, 0.06}   -- wing gold
local GH_WD = {0.42, 0.34, 0.04}   -- wing dark

local function drawGhidorah(wt, grounded)
  local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0
  local hs = math.sin(wt * 2.5) * 2  -- head sway

  -- WINGS (huge, behind body)
  R(GH_WD, -26, -44+bob, 20, 36)
  R(GH_WG, -25, -43+bob, 18, 34)
  R(GH_BG, -22, -40+bob, 12, 28)
  -- Wing membranes
  for i = 0, 5 do
    R(GH_SH, -25+i*2, -40+i*3+bob, 1, 30-i*3)
  end
  R(GH_WD,   6, -44+bob, 20, 36)
  R(GH_WG,   7, -43+bob, 18, 34)
  R(GH_BG,  10, -40+bob, 12, 28)
  for i = 0, 5 do
    R(GH_SH, 24-i*2, -40+i*3+bob, 1, 30-i*3)
  end

  -- BODY
  R(GH_SH, -10, -30+bob, 20, 22)
  R(GH_BG,  -9, -29+bob, 18, 20)
  R(GH_MG,  -6, -27+bob, 12, 16)
  R(GH_HG,  -3, -25+bob,  6, 12)
  -- Scale texture
  for i = 0, 2 do
    R(GH_SH, -8+i*6, -24+bob, 4, 2)
  end

  -- THREE NECKS
  -- Left neck
  R(GH_SH, -10, -46+bob+hs, 6, 18)
  R(GH_BG,  -9, -45+bob+hs, 5, 16)
  R(GH_MG,  -8, -43+bob+hs, 4, 14)
  -- Left head
  R(GH_SH, -12, -58+bob+hs*1.5, 12, 14)
  R(GH_BG, -11, -57+bob+hs*1.5, 10, 12)
  R(GH_MG,  -9, -55+bob+hs*1.5,  8,  8)
  R(GH_EY,  -8, -55+bob+hs*1.5,  4,  4)
  R(GH_PU,  -7, -54+bob+hs*1.5,  2,  2)
  love.graphics.setColor(GH_EY[1], GH_EY[2], GH_EY[3], 0.35)
  love.graphics.rectangle("fill", -10, -57+bob+hs*1.5, 8, 6)

  -- Center neck (tallest)
  R(GH_SH, -3, -50+bob, 6, 22)
  R(GH_BG, -2, -49+bob, 5, 20)
  R(GH_MG, -1, -47+bob, 4, 18)
  -- Center head (biggest)
  R(GH_SH, -7, -66+bob, 14, 18)
  R(GH_BG, -6, -65+bob, 12, 16)
  R(GH_MG, -4, -63+bob,  8, 11)
  R(GH_EY, -3, -63+bob,  6,  5)
  R(GH_PU, -2, -62+bob,  3,  3)
  love.graphics.setColor(GH_EY[1], GH_EY[2], GH_EY[3], 0.40)
  love.graphics.rectangle("fill", -5, -65+bob, 10, 8)
  -- Center teeth
  R({0.92,0.88,0.78}, -4, -50+bob, 2, 4)
  R({0.92,0.88,0.78}, -1, -50+bob, 2, 5)
  R({0.92,0.88,0.78},  2, -50+bob, 2, 4)

  -- Right neck
  R(GH_SH,  4, -46+bob-hs, 6, 18)
  R(GH_BG,  5, -45+bob-hs, 5, 16)
  R(GH_MG,  6, -43+bob-hs, 4, 14)
  -- Right head
  R(GH_SH,  0, -58+bob-hs*1.5, 12, 14)
  R(GH_BG,  1, -57+bob-hs*1.5, 10, 12)
  R(GH_MG,  3, -55+bob-hs*1.5,  8,  8)
  R(GH_EY,  6, -55+bob-hs*1.5,  4,  4)
  R(GH_PU,  7, -54+bob-hs*1.5,  2,  2)
  love.graphics.setColor(GH_EY[1], GH_EY[2], GH_EY[3], 0.35)
  love.graphics.rectangle("fill",  2, -57+bob-hs*1.5, 8, 6)

  -- LEGS
  R(GH_SH, -10, -10+bob, 9, 10)
  R(GH_BG,  -9,  -9+bob, 7,  9)
  R(GH_MG,  -7,  -7+bob, 4,  6)
  R(GH_SH,   1, -10+bob, 9, 10)
  R(GH_BG,   2,  -9+bob, 7,  9)
  R(GH_HG,   3,  -7+bob, 4,  5)
  -- Feet
  R(GH_SH, -12, -2+bob, 11, 4)
  R(GH_BG, -11, -1+bob,  9, 3)
  R(GH_SH,   1, -2+bob, 11, 4)
  R(GH_BG,   2, -1+bob,  9, 3)
end

-- ── Generic REPTILE template ──────────────────────────────────────────────────
local function makeReptile(sh, bg, mg, hg, be, ey, sp, cl)
  return function(wt, grounded)
    local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0
    -- Tail
    R(sh, -14, -8+bob, 6, 5)
    R(bg, -13, -7+bob, 5, 4)
    R(sh, -18, -6+bob, 5, 4)
    R(bg, -22, -4+bob, 4, 3)
    -- Spines
    if sp then
      R(sp, -9, -42+bob, 4, 10)
      R(sp, -8, -34+bob, 3,  8)
      R(sp, -7, -28+bob, 3,  6)
    end
    -- Body
    R(sh, -11, -28+bob, 22, 18)
    R(bg, -10, -27+bob, 20, 16)
    R(mg,  -6, -25+bob, 14, 13)
    R(be,  -5, -24+bob, 10, 10)
    -- Neck
    R(sh, -5, -34+bob, 10, 8)
    R(bg, -4, -33+bob,  8, 6)
    R(be, -3, -31+bob,  6, 4)
    -- Head
    R(sh, -8, -44+bob, 18, 12)
    R(bg, -7, -43+bob, 16, 10)
    R(mg, -5, -41+bob, 12,  7)
    -- Eye
    R(sh,  3, -42+bob, 7, 5)
    R(ey,  4, -41+bob, 6, 4)
    R({0.04,0.04,0.04}, 6, -40+bob, 2, 2)
    love.graphics.setColor(ey[1], ey[2], ey[3], 0.28)
    love.graphics.rectangle("fill", 2, -43+bob, 9, 6)
    -- Snout
    R(sh, -4, -34+bob, 12, 4)
    R(bg, -3, -34+bob, 10, 3)
    R(be, -2, -33+bob,  7, 2)
    -- Teeth
    R({0.88,0.84,0.78}, -1, -29+bob, 2, 3)
    R({0.88,0.84,0.78},  2, -29+bob, 2, 4)
    R({0.88,0.84,0.78},  5, -29+bob, 2, 3)
    -- Arms
    R(sh, -13, -26+bob, 5, 10)
    R(bg, -12, -25+bob, 4,  9)
    if cl then
      R(cl, -13, -16+bob, 2, 3)
      R(cl, -11, -16+bob, 2, 3)
    end
    R(bg,  8, -26+bob, 5, 10)
    R(mg,  9, -25+bob, 4,  9)
    -- Legs
    R(sh, -11, -10+bob,  9, 10)
    R(bg, -10,  -9+bob,  7,  9)
    R(mg,  -8,  -7+bob,  4,  6)
    R(sh,   2, -10+bob,  9, 10)
    R(bg,   3,  -9+bob,  7,  9)
    R(hg,   4,  -7+bob,  4,  5)
    -- Feet
    R(sh, -13, -2+bob, 12, 4)
    R(bg, -12, -1+bob, 10, 3)
    if cl then
      R(cl, -13, 0, 3, 2)
      R(cl, -10, 0, 3, 2)
      R(cl,  -7, 0, 3, 2)
    end
    R(sh,   0, -2+bob, 12, 4)
    R(bg,   1, -1+bob, 10, 3)
    if cl then
      R(cl, 0, 0, 3, 2)
      R(cl, 3, 0, 3, 2)
      R(cl, 6, 0, 3, 2)
    end
  end
end

-- ── Generic HUMANOID template (superheroes) ───────────────────────────────────
local function makeHuman(sh, bg, mg, hg, ac, ey, mask)
  return function(wt, grounded)
    local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0
    -- Cape / back detail
    if ac then
      R(ac, -8, -36+bob, 16, 28)
    end
    -- Body
    R(sh,  -9, -30+bob, 18, 22)
    R(bg,  -8, -29+bob, 16, 20)
    R(mg,  -5, -27+bob, 10, 16)
    -- Chest emblem
    R(hg,  -3, -24+bob,  6,  8)
    R(ac and ac or bg, -2, -23+bob, 4, 6)
    -- Belt
    R(sh,  -8, -12+bob, 16,  3)
    R(hg,  -7, -12+bob, 14,  3)
    -- Head
    R(sh,  -6, -46+bob, 12, 18)
    R(bg,  -5, -45+bob, 10, 16)
    R(mg,  -4, -44+bob,  8, 12)
    -- Mask/helmet
    if mask then
      R(mask, -6, -46+bob, 12, 10)
      R(sh,   -5, -44+bob, 10,  8)
    end
    -- Eyes
    R(sh,   -3, -42+bob, 6, 4)
    R(ey,   -2, -41+bob, 5, 3)
    R({0.04,0.04,0.04}, 0, -40+bob, 2, 2)
    love.graphics.setColor(ey[1], ey[2], ey[3], 0.30)
    love.graphics.rectangle("fill", -3, -43+bob, 7, 5)
    -- Chin/jaw
    R(bg,   -3, -34+bob, 8, 5)
    R(mg,   -2, -33+bob, 6, 3)
    -- Arms
    R(sh, -12, -28+bob, 5, 14)
    R(bg, -11, -27+bob, 4, 13)
    R(sh,   7, -28+bob, 5, 14)
    R(bg,   8, -27+bob, 4, 13)
    -- Fists
    R(bg, -13, -15+bob, 6, 7)
    R(mg, -12, -15+bob, 4, 6)
    R(bg,   7, -15+bob, 6, 7)
    R(mg,   8, -15+bob, 4, 6)
    -- Legs
    R(sh, -9, -10+bob, 8, 10)
    R(bg, -8,  -9+bob, 6,  9)
    R(sh,  1, -10+bob, 8, 10)
    R(bg,  2,  -9+bob, 6,  9)
    -- Boots
    R(sh, -11, -2+bob, 10, 4)
    R(hg, -10, -1+bob,  8, 3)
    R(sh,   1, -2+bob, 10, 4)
    R(hg,   2, -1+bob,  8, 3)
  end
end

-- ── Rodan (flying, different silhouette) ─────────────────────────────────────
local RD_SH = {0.22, 0.10, 0.07}
local RD_BG = {0.48, 0.20, 0.12}
local RD_MG = {0.62, 0.30, 0.18}
local RD_HG = {0.75, 0.42, 0.25}
local RD_BE = {0.68, 0.52, 0.35}
local RD_EY = {0.95, 0.60, 0.08}

local function drawRodan(wt, grounded)
  local flapA = math.sin(wt * 3) * 6
  local bob = math.sin(wt * 2.5) * 1.5

  -- WINGS (pterodactyl)
  R(RD_SH, -28, -36+bob, 22, 22)
  R(RD_BG, -26, -35+bob, 20, 20)
  R(RD_MG, -22, -32+bob, 14, 16)
  R(RD_SH,  -28, -30+bob, 4,  12)  -- leading edge dark
  -- Wing membranes
  for i = 0, 4 do
    R(RD_SH, -26+i*3, -34+i*3+bob, 1, 14-i*2)
  end
  R(RD_SH,  6, -36+bob, 22, 22)
  R(RD_BG,  8, -35+bob, 20, 20)
  R(RD_MG, 10, -32+bob, 14, 16)
  R(RD_SH, 24, -30+bob, 4, 12)
  for i = 0, 4 do
    R(RD_SH, 20-i*3, -34+i*3+bob, 1, 14-i*2)
  end

  -- BODY (more compact)
  R(RD_SH, -8, -30+bob, 16, 20)
  R(RD_BG, -7, -29+bob, 14, 18)
  R(RD_MG, -5, -27+bob, 10, 14)
  R(RD_BE, -3, -25+bob,  6, 10)

  -- NECK
  R(RD_SH, -4, -38+bob, 8, 10)
  R(RD_BG, -3, -37+bob, 6,  9)

  -- HEAD (beak-like)
  R(RD_SH, -6, -48+bob, 16, 12)
  R(RD_BG, -5, -47+bob, 14, 10)
  R(RD_MG, -3, -45+bob, 10,  7)
  -- Beak
  R(RD_SH,  4, -44+bob, 10,  5)
  R(RD_HG,  5, -43+bob,  8,  3)
  R(RD_BE,  6, -42+bob,  6,  2)
  -- Crest
  R(RD_SH, -2, -52+bob, 6, 6)
  R(RD_MG, -1, -51+bob, 4, 5)
  -- Eye
  R(RD_SH, -3, -46+bob, 6, 4)
  R(RD_EY, -2, -45+bob, 5, 3)
  R({0.04,0.04,0.04}, 0, -44+bob, 2, 2)

  -- LEGS / TALONS
  R(RD_SH, -6, -10+bob, 6, 10)
  R(RD_BG, -5,  -9+bob, 5,  9)
  R(RD_SH,  0, -10+bob, 6, 10)
  R(RD_BG,  1,  -9+bob, 5,  9)
  -- Talons
  R({0.80,0.72,0.50}, -7, 0, 3, 2)
  R({0.80,0.72,0.50}, -4, 0, 3, 2)
  R({0.80,0.72,0.50}, -1, 0, 3, 2)
  R({0.80,0.72,0.50},  2, 0, 3, 2)
end

-- ── Biollante (plant-monster) ─────────────────────────────────────────────────
local BI_SH = {0.06, 0.18, 0.06}
local BI_BG = {0.12, 0.38, 0.10}
local BI_MG = {0.20, 0.55, 0.16}
local BI_HG = {0.30, 0.72, 0.22}
local BI_FL = {0.85, 0.78, 0.18}   -- flower yellow
local BI_EY = {0.95, 0.30, 0.05}   -- orange eye
local BI_TH = {0.65, 0.12, 0.12}   -- vine thorns

local function drawBiollante(wt, grounded)
  local bob = (grounded and math.floor(wt) % 2 == 0) and 1 or 0
  local sw  = math.sin(wt * 1.5) * 3  -- sway

  -- VINE TENDRILS (background)
  R(BI_SH, -18, -38+bob, 4, 30)
  R(BI_BG, -17, -37+bob, 3, 28)
  R(BI_SH,  14, -34+bob, 4, 26)
  R(BI_BG,  15, -33+bob, 3, 24)
  R(BI_SH, -22, -24+bob, 4, 18)
  R(BI_BG, -21, -23+bob, 3, 16)
  -- Thorn spikes
  for i = 0, 4 do
    R(BI_TH, -19, -36+i*6+bob, 2, 3)
    R(BI_TH,  13, -32+i*5+bob, 2, 3)
  end

  -- BODY (massive plant body)
  R(BI_SH, -12, -32+bob, 24, 24)
  R(BI_BG, -11, -31+bob, 22, 22)
  R(BI_MG,  -8, -29+bob, 16, 18)
  R(BI_HG,  -4, -27+bob,  8, 14)
  -- Vine texture
  for i = 0, 3 do
    R(BI_SH, -10+i*5, -26+bob, 3, 10)
  end

  -- NECK (vine-like)
  R(BI_SH, -5, -40+bob, 10, 10)
  R(BI_BG, -4, -39+bob,  8,  9)
  R(BI_MG, -3, -38+bob,  6,  7)

  -- HEAD (massive flower/maw)
  R(BI_SH, -10, -52+bob, 20, 14)
  R(BI_BG,  -9, -51+bob, 18, 12)
  R(BI_MG,  -7, -50+bob, 14,  9)
  -- Flower petals around head
  R(BI_FL,  -12, -54+bob, 6, 4)
  R(BI_FL,   6, -54+bob, 6, 4)
  R(BI_FL,  -4, -58+bob, 8, 5)
  R(BI_FL,  -12, -48+bob, 4, 4)
  R(BI_FL,   8, -48+bob, 4, 4)
  -- Maw interior
  R({0.08,0.04,0.04}, -7, -50+bob, 14, 8)
  R({0.18,0.05,0.05}, -6, -49+bob, 12, 6)
  -- Eyes (inside the maw, glowing)
  R(BI_SH, -4, -49+bob, 6, 4)
  R(BI_EY, -3, -48+bob, 5, 3)
  R({0.04,0.04,0.04}, -1, -47+bob, 2, 2)
  R(BI_SH,  1, -49+bob, 5, 4)
  R(BI_EY,  2, -48+bob, 4, 3)
  love.graphics.setColor(BI_EY[1], BI_EY[2], BI_EY[3], 0.35)
  love.graphics.rectangle("fill", -5, -51+bob, 10, 6)
  -- Teeth (plant-like)
  for i = 0, 5 do
    R({0.78,0.72,0.28}, -5+i*2, -44+bob, 2, 4)
  end

  -- ROOTS as legs
  for i = -1, 1 do
    local rx = i * 8
    R(BI_SH, rx-2, -12+bob, 6, 12)
    R(BI_BG, rx-1, -11+bob, 4, 10)
    R(BI_SH, rx-3, -1, 8, 3)
  end
end

-- ── Sprite table ──────────────────────────────────────────────────────────────
-- Reptile variants using the template:
local SP_SH = {0.10, 0.08, 0.20}
local SP_BG = {0.22, 0.16, 0.45}
local SP_MG = {0.36, 0.26, 0.62}
local SP_HG = {0.55, 0.40, 0.80}
local SP_BE = {0.65, 0.55, 0.80}
local SP_EY = {0.30, 0.80, 0.95}

local DSH_SH = {0.20, 0.04, 0.08}
local DSH_BG = {0.42, 0.08, 0.14}
local DSH_MG = {0.58, 0.16, 0.20}
local DSH_HG = {0.72, 0.28, 0.28}
local DSH_BE = {0.78, 0.55, 0.45}
local DSH_EY = {0.95, 0.30, 0.05}
local DSH_SP = {0.80, 0.60, 0.20}  -- crystal spine

local GI_SH = {0.14, 0.18, 0.12}
local GI_BG = {0.26, 0.30, 0.22}
local GI_MG = {0.38, 0.44, 0.32}
local GI_HG = {0.52, 0.58, 0.44}
local GI_BE = {0.60, 0.65, 0.50}
local GI_EY = {0.95, 0.85, 0.10}
local GI_SP = {0.55, 0.08, 0.08}  -- scythe blades red

local HE_SH = {0.08, 0.12, 0.06}
local HE_BG = {0.14, 0.22, 0.10}
local HE_MG = {0.20, 0.30, 0.14}
local HE_HG = {0.28, 0.38, 0.20}
local HE_BE = {0.30, 0.35, 0.22}
local HE_EY = {0.60, 0.90, 0.20}

local AN_SH = {0.18, 0.14, 0.08}
local AN_BG = {0.36, 0.28, 0.16}
local AN_MG = {0.50, 0.38, 0.22}
local AN_HG = {0.65, 0.50, 0.30}
local AN_BE = {0.60, 0.52, 0.35}
local AN_EY = {0.95, 0.82, 0.15}

-- ── Gregg (easter egg human) ──────────────────────────────────────────────────
local GG_SKIN = {0.86, 0.68, 0.51}   -- skin tone
local GG_HAIR = {0.18, 0.09, 0.04}   -- dark brown hair + beard
local GG_CAP  = {0.10, 0.16, 0.47}   -- navy baseball cap
local GG_CAPD = {0.06, 0.10, 0.32}   -- cap shadow
local GG_POLO = {0.39, 0.65, 0.88}   -- light blue polo
local GG_PLOD = {0.30, 0.52, 0.72}   -- polo shadow
local GG_COLR = {0.90, 0.95, 1.00}   -- polo collar (white-ish)
local GG_KHAK = {0.70, 0.62, 0.38}   -- khaki pants
local GG_KHDP = {0.55, 0.48, 0.28}   -- khaki shadow
local GG_SHOE = {0.96, 0.96, 0.93}   -- white shoes
local GG_SWSH = {0.94, 0.40, 0.08}   -- orange Nike swoosh
local GG_BREF = {0.53, 0.35, 0.16}   -- brown briefcase
local GG_BLTB = {0.75, 0.56, 0.25}   -- belt buckle (gold)
local GG_EBRN = {0.32, 0.20, 0.09}   -- eye iris (brown)
local GG_PUPL = {0.04, 0.04, 0.04}   -- pupil
local GG_BLTL = {0.26, 0.14, 0.05}   -- belt band

local function drawGregg(wt, grounded)
  local bob  = (grounded and math.floor(wt * 2) % 2 == 0) and 1 or 0
  local step = math.floor(wt * 3) % 2   -- leg alternation

  -- SHOES (foot level: y = 0)
  R(GG_SHOE, -8, -3+bob,  8, 3)
  R(GG_SHOE,  2, -3+bob,  8, 3)
  R(GG_SWSH, -6, -2+bob,  3, 1)
  R(GG_SWSH,  4, -2+bob,  3, 1)

  -- LEGS / TROUSERS (khaki, alternating walk)
  if step == 0 then
    R(GG_KHAK, -7, -13+bob,  6, 11)
    R(GG_KHAK,  1, -13+bob,  6, 11)
  else
    R(GG_KHAK, -8, -14+bob,  6, 12)
    R(GG_KHAK,  2, -12+bob,  6, 10)
  end
  R(GG_KHDP, -5, -13+bob, 1, 10)
  R(GG_KHDP,  3, -13+bob, 1, 10)

  -- BELT
  R(GG_BLTL, -7, -14+bob, 14,  2)
  R(GG_BLTB, -1, -14+bob,  3,  2)

  -- POLO SHIRT (torso)
  R(GG_POLO, -8, -27+bob, 16, 14)
  R(GG_PLOD, -8, -27+bob,  2, 14)
  R(GG_COLR, -2, -28+bob,  4,  2)
  R(GG_PLOD,  0, -25+bob,  1,  1)
  R(GG_PLOD,  0, -22+bob,  1,  1)
  R(GG_PLOD,  0, -19+bob,  1,  1)

  -- LEFT ARM (extended, empty hand)
  R(GG_POLO, -11, -26+bob,  4, 12)
  R(GG_SKIN, -11, -15+bob,  4,  4)

  -- RIGHT ARM (briefcase arm)
  R(GG_POLO,   8, -26+bob,  4, 12)
  R(GG_SKIN,   8, -15+bob,  4,  4)   -- right hand

  -- BRIEFCASE (right side, at waist)
  R(GG_HAIR,  13, -27+bob,  4,  2)   -- briefcase handle (dark strap)
  R(GG_BREF,  11, -25+bob,  8,  9)
  R(GG_HAIR,  12, -27+bob,  6,  3)
  R(GG_BLTB,  13, -22+bob,  3,  1)
  R(GG_KHDP,  11, -21+bob,  8,  1)

  -- NECK
  R(GG_SKIN, -3, -30+bob,  6,  3)

  -- HEAD (face)
  R(GG_SKIN, -6, -40+bob, 12, 11)
  R(GG_SKIN, -7, -38+bob,  2,  5)
  R(GG_SKIN,  5, -38+bob,  2,  5)

  -- HAIR (sides below cap)
  R(GG_HAIR, -6, -39+bob,  2,  5)
  R(GG_HAIR,  4, -39+bob,  2,  5)

  -- EYES
  R(GG_EBRN, -4, -37+bob,  3,  3)
  R(GG_EBRN,  1, -37+bob,  3,  3)
  R(GG_PUPL, -3, -36+bob,  1,  2)
  R(GG_PUPL,  2, -36+bob,  1,  2)

  -- BEARD (full, lower face)
  R(GG_HAIR, -5, -32+bob, 10,  6)
  R({0.28,0.14,0.06}, -4, -31+bob, 8, 4)
  R(GG_HAIR, -5, -33+bob, 10,  2)

  -- CAP (navy)
  R(GG_CAP,  -6, -46+bob, 12,  7)
  R(GG_CAP,  -7, -42+bob, 14,  4)
  R(GG_CAPD, -7, -46+bob,  2,  7)
  R(GG_CAP,   5, -40+bob,  9,  3)
  R(GG_CAPD,  5, -40+bob,  1,  3)
  -- Nike tick (~2px white checkmark)
  R({0.85,0.90,1.00}, -1, -45+bob, 2, 1)
  R({0.85,0.90,1.00},  0, -44+bob, 3, 1)
end

KS._sprites = {
  ["Godzilla"]      = drawGodzilla,
  ["Kong"]          = drawKong,
  ["Mothra"]        = drawMothra,
  ["Ghidorah"]      = drawGhidorah,
  ["Rodan"]         = drawRodan,
  ["Biollante"]     = drawBiollante,
  -- Reptile variants
  ["MechaGodzilla"] = drawMechagodzilla,
  ["SpaceGodzilla"] = makeReptile(SP_SH, SP_BG, SP_MG, SP_HG, SP_BE, SP_EY, SP_SH),
  ["Destoroyah"]    = makeReptile(DSH_SH, DSH_BG, DSH_MG, DSH_HG, DSH_BE, DSH_EY, DSH_SP),
  ["Gigan"]         = makeReptile(GI_SH, GI_BG, GI_MG, GI_HG, GI_BE, GI_EY, GI_SP),
  ["Hedorah"]       = makeReptile(HE_SH, HE_BG, HE_MG, HE_HG, HE_BE, HE_EY, nil),
  ["Anguirus"]      = makeReptile(AN_SH, AN_BG, AN_MG, AN_HG, AN_BE, AN_EY, AN_SH),
  -- Humanoids
  ["Titan"] = makeHuman(
    {0.04,0.08,0.28}, {0.08,0.16,0.62}, {0.14,0.26,0.80}, {0.24,0.40,0.95},
    {0.60,0.70,0.95}, {0.90,0.95,1.00}, {0.06,0.10,0.45}
  ),
  ["Ironclad"] = makeHuman(
    {0.22,0.06,0.06}, {0.55,0.12,0.10}, {0.72,0.20,0.16}, {0.88,0.30,0.22},
    {0.50,0.50,0.55}, {0.95,0.85,0.20}, {0.35,0.08,0.06}
  ),
  ["Webslinger"] = makeHuman(
    {0.35,0.04,0.04}, {0.68,0.08,0.08}, {0.82,0.16,0.14}, {0.92,0.28,0.22},
    {0.12,0.12,0.55}, {0.95,0.92,0.88}, {0.50,0.06,0.06}
  ),
  ["Thunderstrike"] = makeHuman(
    {0.12,0.18,0.36}, {0.26,0.38,0.68}, {0.38,0.52,0.82}, {0.55,0.68,0.95},
    {0.80,0.72,0.22}, {0.95,0.95,0.50}, {0.18,0.26,0.55}
  ),
}

-- ── Public draw function ───────────────────────────────────────────────────────
-- scale: visual scale multiplier (default 2 — kaiju should be big!)
-- The controller hitbox stays at 28×44; the sprite is drawn larger.

function KS.draw(name, ctrl, scale)
  scale = scale or 2
  love.graphics.push()
  -- Translate to foot position, then scale, so sprite grows upward from foot
  love.graphics.translate(ctrl.x, ctrl.y)
  if ctrl.facingRight then
    love.graphics.scale(scale, scale)
  else
    love.graphics.scale(-scale, scale)
  end
  local fn = KS._sprites[name] or KS._sprites["Godzilla"]
  fn(ctrl._walkTimer or 0, ctrl.isGrounded)
  love.graphics.pop()
end

function KS.drawBoss(name, ctrl, scale)
  KS.draw(name, ctrl, scale or 2)
end

-- ── Gregg (easter egg) — called from food_manager.lua ─────────────────────────
-- g = Gregg entity table: { x, y, w, h, dir, _walkTimer }
-- Translates to foot-center then draws using the same coordinate system as other sprites.
function KS.drawGregg(g)
  love.graphics.push()
  love.graphics.translate(g.x + g.w * 0.5, g.y + g.h)
  if g.dir < 0 then
    love.graphics.scale(-1, 1)
  end
  drawGregg(g._walkTimer or 0, true)
  love.graphics.pop()
end

return KS
