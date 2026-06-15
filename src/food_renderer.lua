-- src/food_renderer.lua
-- Draw functions for 50 food types. Each takes (x, y, w, h).
local R = {}

local function c(r,g,b,a) love.graphics.setColor(r,g,b,a or 1) end
local function rect(x,y,w,h) love.graphics.rectangle("fill",x,y,w,h) end

-- helper: horizontal stripes
local function stripes(x, y, w, h, colors)
  local sh = math.ceil(h / #colors)
  for i, col in ipairs(colors) do
    c(unpack(col))
    rect(x, y + (i-1)*sh, w, sh)
  end
end

local function bun(x,y,w,h, bC, fC, fH)
  local top = math.floor(h*0.35)
  local fil = math.floor(h*fH)
  c(unpack(bC)); rect(x, y, w, top)
  c(unpack(fC)); rect(x, y+top, w, fil)
  c(unpack(bC)); rect(x, y+top+fil, w, h-top-fil)
end

local FOOD = {}

-- 1 pizza
FOOD.pizza = function(x,y,w,h)
  c(0.85,0.55,0.1); rect(x,y,w,h)
  c(0.75,0.1,0.1); rect(x+2,y+2,w-4,h-6)
  c(0.9,0.7,0.2); rect(x+4,y+5,3,3); rect(x+9,y+3,2,2)
  c(0.4,0.8,0.2); rect(x+7,y+6,2,2)
end

-- 2 burger
FOOD.burger = function(x,y,w,h)
  bun(x,y,w,h, {0.65,0.38,0.12}, {0.8,0.4,0.1}, 0.38)
  c(0.15,0.6,0.15); rect(x,y+math.floor(h*0.35),w,2)
end

-- 3 hotdog
FOOD.hotdog = function(x,y,w,h)
  c(0.82,0.58,0.38); rect(x,y+4,w,h-8)
  c(0.72,0.15,0.1); rect(x+2,y+6,w-4,h-12)
  c(0.9,0.8,0.3); rect(x+3,y+7,w-6,2)
end

-- 4 sushi
FOOD.sushi = function(x,y,w,h)
  c(0.92,0.92,0.88); rect(x,y,w,h)
  c(0.1,0.1,0.1); rect(x,y,w,4)
  c(0.85,0.15,0.15); rect(x+2,y+5,w-4,5)
end

-- 5 donut
FOOD.donut = function(x,y,w,h)
  c(0.9,0.5,0.65); rect(x,y,w,h)
  c(0.15,0.07,0.02); rect(x+4,y+4,w-8,h-8)
  c(0.9,0.5,0.65); rect(x+5,y+5,w-10,h-10)
  c(1,0.9,0.2); rect(x+2,y+2,2,1)
  c(0.3,0.8,1); rect(x+9,y+1,2,1)
  c(1,0.3,0.5); rect(x+13,y+2,2,1)
end

-- 6 taco
FOOD.taco = function(x,y,w,h)
  c(0.92,0.82,0.45); rect(x,y+4,w,h-4)
  c(0.8,0.4,0.1); rect(x+3,y+6,w-6,h-10)
  c(0.2,0.7,0.2); rect(x+3,y+6,w-6,3)
  c(0.9,0.2,0.2); rect(x+3,y+9,w-6,2)
  c(0.95,0.90,0.6); rect(x,y+4,w,2)
  c(0.95,0.90,0.6); rect(x,y+h-2,w,2)
end

-- 7 nachos
FOOD.nachos = function(x,y,w,h)
  c(0.92,0.78,0.3); rect(x,y+6,w,h-6)
  c(0.92,0.78,0.3); rect(x+3,y+2,w-6,6)
  c(0.9,0.2,0.1); rect(x+5,y+7,4,3)
  c(1,0.85,0.3); rect(x+10,y+8,4,3)
  c(0.2,0.6,0.1); rect(x+2,y+11,3,2)
end

-- 8 fries
FOOD.fries = function(x,y,w,h)
  c(0.85,0.3,0.3); rect(x,y+8,w,h-8)
  c(0.95,0.8,0.25)
  rect(x+2,y,3,h-6); rect(x+6,y+2,3,h-8)
  rect(x+10,y+1,3,h-7); rect(x+14,y,3,h-6)
end

-- 9 wings
FOOD.wings = function(x,y,w,h)
  c(0.75,0.35,0.1); rect(x,y,w,h)
  c(0.9,0.5,0.1); rect(x+2,y+2,w-4,h-4)
  c(0.5,0.2,0.05)
  rect(x+3,y+3,3,2); rect(x+9,y+3,3,2)
  rect(x+3,y+h-5,3,2); rect(x+9,y+h-5,3,2)
end

-- 10 corn dog
FOOD.corndog = function(x,y,w,h)
  c(0.95,0.8,0.3); rect(x+3,y,w-6,h-2)
  c(0.8,0.4,0.1); rect(x+5,y+3,w-10,h-8)
  c(0.75,0.55,0.25); rect(x+6,y,4,h+2)
end

-- 11 ice cream
FOOD.icecream = function(x,y,w,h)
  c(0.85,0.65,0.5); rect(x+3,y+8,w-6,h-8)
  c(0.92,0.78,0.72); rect(x+2,y+5,w-4,8)
  c(1,0.3,0.5); rect(x+1,y+2,w-2,6)
  c(1,0.95,0.95); rect(x+2,y,w-4,5)
  c(1,0.2,0.3); rect(x+w/2-1,y,2,2)
end

-- 12 cake
FOOD.cake = function(x,y,w,h)
  stripes(x,y,w,h, {{0.95,0.90,0.9},{0.85,0.5,0.7},{0.95,0.90,0.9},{0.7,0.3,0.5}})
  c(1,0.95,0.95); rect(x,y,w,3)
  c(1,0.9,0.1); rect(x+w/2-1,y-3,2,4)
end

-- 13 pie
FOOD.pie = function(x,y,w,h)
  c(0.82,0.58,0.35); rect(x,y+5,w,h-5)
  c(0.75,0.4,0.2); rect(x+1,y+h-4,w-2,3)
  c(0.9,0.35,0.1); rect(x+3,y+6,w-6,h-12)
  c(0.82,0.58,0.35); rect(x,y+2,w,5)
end

-- 14 cookie
FOOD.cookie = function(x,y,w,h)
  c(0.82,0.6,0.32); rect(x,y,w,h)
  c(0.6,0.35,0.1); rect(x+1,y+1,w-2,h-2)
  c(0.35,0.18,0.05); rect(x+3,y+3,3,3); rect(x+9,y+5,3,3); rect(x+5,y+8,3,3)
end

-- 15 waffle
FOOD.waffle = function(x,y,w,h)
  c(0.88,0.72,0.42); rect(x,y,w,h)
  c(0.75,0.55,0.28)
  for gx = x+4, x+w-4, 4 do rect(gx, y, 1, h) end
  for gy = y+4, y+h-4, 4 do rect(x, gy, w, 1) end
  c(0.95,0.7,0.1); rect(x+2,y+2,4,4)
end

-- 16 ramen
FOOD.ramen = function(x,y,w,h)
  c(0.8,0.55,0.25); rect(x,y+6,w,h-6)
  c(0.6,0.35,0.1); rect(x+1,y+h-3,w-2,2)
  c(0.95,0.85,0.65); rect(x+2,y+8,w-4,h-14)
  c(0.9,0.3,0.2); rect(x+3,y+8,4,3)
  c(0.5,0.8,0.3); rect(x+9,y+9,3,2)
  c(0.95,0.85,0.65); rect(x+2,y+12,w-4,2); rect(x+2,y+14,w-4,2)
end

-- 17 dumpling
FOOD.dumpling = function(x,y,w,h)
  c(0.95,0.9,0.8); rect(x,y+4,w,h-4)
  c(0.88,0.82,0.7); rect(x+2,y+2,w-4,h-2)
  c(0.75,0.65,0.5); rect(x+4,y,w-8,5)
  c(0.65,0.5,0.35); rect(x+5,y+1,w-10,2)
end

-- 18 bao
FOOD.bao = function(x,y,w,h)
  c(0.96,0.94,0.92); rect(x+1,y,w-2,h)
  c(0.92,0.88,0.84); rect(x,y+3,w,h-3)
  c(0.85,0.65,0.45); rect(x+4,y+8,w-8,h-12)
  c(0.7,0.2,0.1); rect(x+5,y+9,3,3)
end

-- 19 spring roll
FOOD.springroll = function(x,y,w,h)
  c(0.88,0.72,0.35); rect(x,y+2,w,h-4)
  c(0.78,0.60,0.25); rect(x+2,y,w-4,h)
  c(0.65,0.48,0.18); rect(x+3,y+4,1,h-8); rect(x+w-4,y+4,1,h-8)
  c(0.4,0.7,0.2); rect(x+5,y+5,4,3)
  c(0.9,0.5,0.1); rect(x+5,y+8,4,2)
end

-- 20 fried rice
FOOD.friedrice = function(x,y,w,h)
  c(0.75,0.6,0.35); rect(x,y+5,w,h-5)
  c(0.6,0.45,0.2); rect(x+1,y+h-3,w-2,2)
  c(0.92,0.88,0.78)
  for i=0,3 do for j=0,2 do
    rect(x+3+i*3, y+7+j*3, 2, 2)
  end end
  c(0.9,0.7,0.1); rect(x+3,y+10,3,2)
  c(0.2,0.6,0.1); rect(x+9,y+12,3,2)
end

-- 21 croissant
FOOD.croissant = function(x,y,w,h)
  c(0.88,0.68,0.3); rect(x,y+4,w,h-4)
  c(0.78,0.55,0.2); rect(x+2,y+2,w-4,h-4)
  c(0.68,0.45,0.15)
  rect(x+3,y+3,3,2); rect(x+w-6,y+3,3,2)
  rect(x+5,y+6,w-10,2)
end

-- 22 pretzel
FOOD.pretzel = function(x,y,w,h)
  c(0.72,0.48,0.22); rect(x,y,w,h)
  c(0.60,0.38,0.15); rect(x+3,y+3,w-6,h-6)
  c(0.72,0.48,0.22); rect(x+4,y+4,w-8,h-8)
  c(0.90,0.80,0.65); rect(x+5,y+2,2,2); rect(x+9,y+2,2,2)
end

-- 23 empanada
FOOD.empanada = function(x,y,w,h)
  c(0.88,0.75,0.45); rect(x,y+6,w,h-6)
  c(0.82,0.68,0.38); rect(x+1,y+3,w-2,h-4)
  c(0.70,0.52,0.25); rect(x+3,y+4,w-6,h-8)
  c(0.85,0.68,0.38); rect(x+2,y+3,2,2); rect(x+w-4,y+3,2,2)
end

-- 24 falafel
FOOD.falafel = function(x,y,w,h)
  c(0.55,0.42,0.22); rect(x,y,w,h)
  c(0.65,0.52,0.30); rect(x+2,y+2,w-4,h-4)
  c(0.30,0.50,0.18); rect(x+4,y+4,3,3); rect(x+9,y+6,3,2)
  c(0.55,0.42,0.22); rect(x+1,y+1,1,1); rect(x+w-2,y+1,1,1)
end

-- 25 kebab
FOOD.kebab = function(x,y,w,h)
  c(0.50,0.32,0.15); rect(x+6,y,4,h)
  c(0.75,0.35,0.15); rect(x+3,y+2,w-6,4)
  c(0.40,0.65,0.20); rect(x+3,y+7,w-6,4)
  c(0.75,0.35,0.15); rect(x+3,y+12,w-6,4)
end

-- 26 chips
FOOD.chips = function(x,y,w,h)
  c(0.92,0.48,0.18); rect(x,y,w,h)
  c(0.78,0.35,0.10); rect(x+1,y+1,w-2,h-2)
  c(0.98,0.75,0.32)
  rect(x+3,y+4,w-6,2); rect(x+3,y+8,w-6,2); rect(x+3,y+12,w-6,2)
  c(1,0.9,0.2); rect(x,y,w,4)
end

-- 27 popcorn
FOOD.popcorn = function(x,y,w,h)
  c(0.85,0.25,0.25); rect(x,y+7,w,h-7)
  c(0.95,0.90,0.65)
  rect(x+2,y+3,4,5); rect(x+6,y+2,4,6); rect(x+10,y+3,4,5)
  rect(x+3,y,3,5);   rect(x+8,y+1,3,4); rect(x+11,y,3,5)
end

-- 28 cheese
FOOD.cheese = function(x,y,w,h)
  c(0.96,0.82,0.18); rect(x,y,w,h)
  c(0.88,0.72,0.10); rect(x+1,y+1,w-2,h-2)
  c(0.75,0.58,0.05)
  rect(x+3,y+4,4,4); rect(x+10,y+8,4,4); rect(x+5,y+10,3,3)
end

-- 29 apple
FOOD.apple = function(x,y,w,h)
  c(0.85,0.15,0.15); rect(x+2,y+2,w-4,h-2)
  c(0.78,0.12,0.12); rect(x+1,y+4,1,h-6); rect(x+w-2,y+4,1,h-6)
  c(0.30,0.55,0.20); rect(x+w/2-1,y,2,3)
  c(0.7,0.12,0.10); rect(x+2,y+h-4,w-4,3)
end

-- 30 banana
FOOD.banana = function(x,y,w,h)
  c(0.96,0.88,0.15); rect(x+2,y,w-4,h)
  c(0.88,0.75,0.10); rect(x,y+4,w,h-8)
  c(0.55,0.42,0.08); rect(x+2,y,2,4); rect(x+w-4,y+h-4,2,4)
end

-- 31 watermelon
FOOD.watermelon = function(x,y,w,h)
  c(0.15,0.72,0.22); rect(x,y,w,h)
  c(0.95,0.22,0.28); rect(x+1,y,w-2,h-3)
  c(0.30,0.68,0.22); rect(x,y,w,3)
  c(0.1,0.1,0.1); rect(x+4,y+5,2,2); rect(x+9,y+7,2,2); rect(x+7,y+3,2,2)
end

-- 32 turkey
FOOD.turkey = function(x,y,w,h)
  c(0.72,0.48,0.22); rect(x+2,y,w-4,h)
  c(0.62,0.38,0.15); rect(x,y+3,w,h-6)
  c(0.55,0.28,0.10); rect(x+4,y+5,w-8,h-10)
  c(0.85,0.55,0.35); rect(x+w-4,y+2,4,5)
  c(0.98,0.15,0.15); rect(x+w-3,y+1,2,3)
end

-- 33 steak
FOOD.steak = function(x,y,w,h)
  c(0.55,0.20,0.12); rect(x,y,w,h)
  c(0.72,0.28,0.15); rect(x+1,y+2,w-2,h-4)
  c(0.88,0.68,0.58); rect(x+3,y+5,w-6,h-10)
  c(0.65,0.28,0.15); rect(x+4,y+6,4,2); rect(x+9,y+8,4,2)
end

-- 34 lobster
FOOD.lobster = function(x,y,w,h)
  c(0.90,0.25,0.15); rect(x,y,w,h)
  c(0.82,0.20,0.12); rect(x+3,y+2,w-6,h-4)
  c(0.98,0.50,0.30); rect(x+1,y+4,w-2,h-8)
  c(0.90,0.25,0.15); rect(x,y+h-4,3,4); rect(x+w-3,y+h-4,3,4)
  c(0.1,0.1,0.1); rect(x+4,y+3,2,2); rect(x+w-6,y+3,2,2)
end

-- 35 sandwich
FOOD.sandwich = function(x,y,w,h)
  stripes(x,y,w,h, {
    {0.88,0.72,0.42},{0.2,0.7,0.2},{0.9,0.9,0.9},
    {0.9,0.3,0.2},{0.85,0.72,0.38}
  })
end

-- 36 boba
FOOD.boba = function(x,y,w,h)
  c(0.75,0.5,0.8); rect(x+2,y+2,w-4,h-2)
  c(0.6,0.35,0.65); rect(x+3,y+h-6,w-6,5)
  c(0.95,0.95,0.95); rect(x+3,y+3,w-6,h-9)
  c(0.2,0.15,0.1); rect(x+4,y+8,3,3); rect(x+9,y+9,3,3); rect(x+6,y+12,3,3)
  c(0.65,0.4,0.7); rect(x+w/2-1,y,2,3)
end

-- 37 coffee
FOOD.coffee = function(x,y,w,h)
  c(0.85,0.72,0.55); rect(x+2,y+2,w-4,h-2)
  c(0.5,0.32,0.18); rect(x+3,y+6,w-6,h-8)
  c(0.85,0.72,0.55); rect(x+3,y+4,w-6,3)
  c(0.95,0.90,0.85); rect(x+3,y+4,w-6,2)
  c(0.55,0.35,0.20); rect(x+w-3,y+4,3,4)
end

-- 38 soda
FOOD.soda = function(x,y,w,h)
  c(0.75,0.15,0.20); rect(x+2,y+2,w-4,h-2)
  c(0.65,0.10,0.15); rect(x+3,y+8,w-6,h-10)
  c(0.90,0.90,0.95); rect(x+3,y+4,w-6,5)
  c(0.95,0.92,0.88); rect(x+3,y+4,4,3)
  c(0.55,0.55,0.55); rect(x+w/2-2,y,4,3)
end

-- 39 energy drink
FOOD.energydrink = function(x,y,w,h)
  c(0.05,0.05,0.05); rect(x+2,y,w-4,h)
  c(0.25,0.90,0.10); rect(x+3,y+3,w-6,5)
  c(0.05,0.05,0.05); rect(x+3,y+8,w-6,h-10)
  c(0.20,0.80,0.08); rect(x+4,y+4,3,3)
end

-- 40 juice
FOOD.juice = function(x,y,w,h)
  c(0.95,0.75,0.15); rect(x+2,y+2,w-4,h-2)
  c(0.88,0.62,0.10); rect(x+3,y+7,w-6,h-9)
  c(0.98,0.88,0.65); rect(x+3,y+4,w-6,4)
  c(0.85,0.88,0.4); rect(x+w-4,y+3,3,5)
  c(0.55,0.55,0.55); rect(x+w/2-2,y,4,3)
end

-- 41 candy
FOOD.candy = function(x,y,w,h)
  c(0.95,0.20,0.45); rect(x,y,w,h)
  c(0.99,0.99,0.99); rect(x+2,y+2,3,h-4); rect(x+w-5,y+2,3,h-4)
  c(0.95,0.20,0.45); rect(x+3,y+4,w-6,h-8)
  c(0.98,0.60,0.20); rect(x+1,y,w-2,3)
end

-- 42 lollipop
FOOD.lollipop = function(x,y,w,h)
  c(0.90,0.20,0.55); rect(x+1,y,w-2,h-4)
  c(0.99,0.65,0.75); rect(x+3,y+2,w-6,h-8)
  c(0.99,0.99,0.99); rect(x+2,y+2,3,3)
  c(0.65,0.65,0.65); rect(x+w/2-1,y+h-5,2,6)
end

-- 43 chocolate
FOOD.chocolate = function(x,y,w,h)
  c(0.28,0.14,0.06); rect(x,y,w,h)
  c(0.38,0.20,0.08); rect(x+1,y+1,w-2,h-2)
  c(0.25,0.12,0.05)
  rect(x+w/2,y,1,h); rect(x,y+h/2,w,1)
  c(0.48,0.28,0.12); rect(x+2,y+2,4,4); rect(x+w/2+2,y+2,4,4)
end

-- 44 pancake
FOOD.pancake = function(x,y,w,h)
  stripes(x,y,w,h, {{0.88,0.70,0.45},{0.78,0.58,0.32},{0.88,0.70,0.45}})
  c(0.88,0.65,0.28); rect(x+1,y,w-2,3); rect(x+1,y+h-3,w-2,3)
  c(0.96,0.78,0.22); rect(x+3,y+2,4,4)
end

-- 45 crepe
FOOD.crepe = function(x,y,w,h)
  c(0.92,0.80,0.55); rect(x,y+3,w,h-3)
  c(0.85,0.70,0.42); rect(x+2,y,w-4,h-1)
  c(0.92,0.3,0.5); rect(x+4,y+5,w-8,3)
  c(0.62,0.45,0.22); rect(x+1,y+h-4,w-2,3)
end

-- 46 gyro
FOOD.gyro = function(x,y,w,h)
  c(0.95,0.92,0.82); rect(x,y,w,h)
  c(0.88,0.85,0.72); rect(x+1,y+1,w-2,h-2)
  c(0.75,0.40,0.22); rect(x+3,y+3,w-6,h-6)
  c(0.2,0.65,0.2); rect(x+3,y+3,w-6,3)
  c(0.9,0.75,0.55); rect(x+3,y+6,w-6,3)
end

-- 47 pierogi
FOOD.pierogi = function(x,y,w,h)
  c(0.92,0.86,0.70); rect(x+1,y+3,w-2,h-3)
  c(0.85,0.78,0.60); rect(x,y+5,w,h-7)
  c(0.70,0.60,0.40)
  rect(x+2,y+3,2,2); rect(x+w-4,y+3,2,2)
  rect(x+4,y+8,w-8,2)
  c(0.5,0.35,0.15); rect(x+5,y+6,3,3)
end

-- 48 noodles
FOOD.noodles = function(x,y,w,h)
  c(0.65,0.45,0.25); rect(x,y+6,w,h-6)
  c(0.55,0.35,0.15); rect(x+1,y+h-3,w-2,2)
  c(0.95,0.88,0.65)
  for i=0,4 do rect(x+2, y+7+i*2, w-4, 1) end
  c(0.8,0.25,0.15); rect(x+4,y+8,3,2)
  c(0.2,0.6,0.15); rect(x+10,y+10,3,2)
end

-- 49 curry
FOOD.curry = function(x,y,w,h)
  c(0.55,0.40,0.20); rect(x,y+6,w,h-6)
  c(0.95,0.72,0.22); rect(x+2,y+8,w-4,h-12)
  c(0.85,0.60,0.18); rect(x+3,y+9,w-6,h-14)
  c(0.42,0.28,0.12); rect(x+4,y+10,3,3); rect(x+9,y+11,3,3)
  c(0.65,0.55,0.38); rect(x+1,y+6,w-2,3)
end

-- 50 birthday cake
FOOD.birthdaycake = function(x,y,w,h)
  stripes(x,y,w,h, {{1,0.3,0.5},{1,0.9,0.95},{0.4,0.4,0.95},{1,0.9,0.95},{1,0.3,0.5}})
  c(1,0.95,0.95); rect(x,y,w,3)
  -- candles
  c(0.1,0.1,0.9); rect(x+3,y-5,2,5)
  c(0.9,0.1,0.1); rect(x+7,y-6,2,6)
  c(0.1,0.7,0.1); rect(x+11,y-4,2,4)
  -- flames
  c(1,0.85,0.1); rect(x+3,y-6,2,2); rect(x+7,y-7,2,2); rect(x+11,y-5,2,2)
end

-- All 50 keys (exposed for random selection)
R.TYPES = {
  "pizza","burger","hotdog","sushi","donut",
  "taco","nachos","fries","wings","corndog",
  "icecream","cake","pie","cookie","waffle",
  "ramen","dumpling","bao","springroll","friedrice",
  "croissant","pretzel","empanada","falafel","kebab",
  "chips","popcorn","cheese","apple","banana",
  "watermelon","turkey","steak","lobster","sandwich",
  "boba","coffee","soda","energydrink","juice",
  "candy","lollipop","chocolate","pancake","crepe",
  "gyro","pierogi","noodles","curry","birthdaycake",
}

function R.draw(item)
  local x, y, w, h = item.x, item.y, item.w, item.h
  -- Glow halo
  love.graphics.setColor(1, 1, 0.4, 0.25)
  love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6)
  local fn = FOOD[item.type]
  if fn then fn(x, y, w, h) end
end

return R
