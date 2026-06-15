-- src/restaurant_defs.lua
-- Per-city restaurant data: signature food, cultural flavor, power-up effect,
-- and the food pool for items scattered through that city's level.

local RD = {}

-- effect choices: "SPEED SURGE" | "DAMAGE BOOST" | "RAGE MODE" | "HEAL"

RD.CITIES = {

  ["Tokyo"] = {
    name      = "竜の居酒屋",
    sub       = "Dragon Izakaya",
    welcome   = "いらっしゃいませ！",
    signCol   = {0.95, 0.18, 0.12},
    food      = "ramen",
    foodLabel = "KAIJU RAMEN",
    effect    = "SPEED SURGE",
    foods     = {"ramen","sushi","dumpling","bao","noodles","friedrice"},
  },

  ["Seoul"] = {
    name      = "가와지라 식당",
    sub       = "Gawdzilla BBQ",
    welcome   = "어서 오세요!",
    signCol   = {0.88, 0.20, 0.15},
    food      = "kebab",
    foodLabel = "GALBI BBQ",
    effect    = "DAMAGE BOOST",
    foods     = {"kebab","ramen","noodles","dumpling","springroll"},
  },

  ["Hong Kong"] = {
    name      = "怪獸點心",
    sub       = "Monster Dim Sum",
    welcome   = "歡迎光臨！",
    signCol   = {0.95, 0.72, 0.05},
    food      = "dumpling",
    foodLabel = "DIM SUM FEAST",
    effect    = "DAMAGE BOOST",
    foods     = {"dumpling","bao","springroll","friedrice","noodles"},
  },

  ["Shanghai"] = {
    name      = "怪兽小笼包",
    sub       = "Monster Soup Dumplings",
    welcome   = "欢迎！",
    signCol   = {0.92, 0.30, 0.08},
    food      = "bao",
    foodLabel = "XIAO LONG BAO",
    effect    = "SPEED SURGE",
    foods     = {"bao","dumpling","noodles","friedrice","springroll"},
  },

  ["Bangkok"] = {
    name      = "ก๋วยเตี๋ยวยักษ์",
    sub       = "Kaiju Noodle House",
    welcome   = "ยินดีต้อนรับ!",
    signCol   = {0.95, 0.65, 0.05},
    food      = "noodles",
    foodLabel = "PAD THAI SUPREME",
    effect    = "SPEED SURGE",
    foods     = {"noodles","springroll","friedrice","curry","bao"},
  },

  ["Singapore"] = {
    name      = "Hawker GAWDZILLA",
    sub       = "Hawker Centre #1",
    welcome   = "Lah, come eat!",
    signCol   = {0.88, 0.60, 0.10},
    food      = "friedrice",
    foodLabel = "HAINANESE RICE",
    effect    = "SPEED SURGE",
    foods     = {"friedrice","noodles","bao","springroll","dumpling"},
  },

  ["Taipei"] = {
    name      = "怪獸珍奶",
    sub       = "Monster Bubble Tea",
    welcome   = "歡迎來！",
    signCol   = {0.22, 0.62, 0.92},
    food      = "boba",
    foodLabel = "GIANT BUBBLE TEA",
    effect    = "SPEED SURGE",
    foods     = {"boba","dumpling","noodles","bao","friedrice"},
  },

  ["Kuala Lumpur"] = {
    name      = "Nasi GAWDZILLA",
    sub       = "Malaysian Kitchen",
    welcome   = "Selamat datang!",
    signCol   = {0.92, 0.72, 0.08},
    food      = "curry",
    foodLabel = "NASI LEMAK KAIJU",
    effect    = "DAMAGE BOOST",
    foods     = {"curry","noodles","friedrice","bao","springroll"},
  },

  ["New York City"] = {
    name      = "GAWDZILLA'S DELI",
    sub       = "Est. Monster Ave 1954",
    welcome   = "BEST CITY IN THE WORLD!",
    signCol   = {0.95, 0.82, 0.08},
    food      = "hotdog",
    foodLabel = "NYC HOT DOG",
    effect    = "RAGE MODE",
    foods     = {"hotdog","pizza","burger","fries","sandwich"},
  },

  ["Chicago"] = {
    name      = "Deep Dish STOMP",
    sub       = "Chicago's Finest",
    welcome   = "GO BEARS!",
    signCol   = {0.88, 0.22, 0.15},
    food      = "pizza",
    foodLabel = "DEEP DISH PIZZA",
    effect    = "DAMAGE BOOST",
    foods     = {"pizza","hotdog","burger","fries","sandwich"},
  },

  ["Los Angeles"] = {
    name      = "Sunset Roll",
    sub       = "Hollywood Kaiju Eats",
    welcome   = "Like, welcome!",
    signCol   = {0.95, 0.55, 0.10},
    food      = "sushi",
    foodLabel = "SPICY TUNA ROLL",
    effect    = "SPEED SURGE",
    foods     = {"sushi","taco","burger","boba","fries"},
  },

  ["San Francisco"] = {
    name      = "Kaiju Mission Burrito",
    sub       = "SF Street Kitchen",
    welcome   = "Welcome to the Bay!",
    signCol   = {0.88, 0.62, 0.15},
    food      = "taco",
    foodLabel = "SUPER BURRITO",
    effect    = "DAMAGE BOOST",
    foods     = {"taco","burger","sushi","sandwich","fries"},
  },

  ["Las Vegas"] = {
    name      = "ALL-YOU-CAN-SMASH",
    sub       = "Open 24 Hours",
    welcome   = "JACKPOT, BABY!!",
    signCol   = {0.98, 0.88, 0.05},
    food      = "steak",
    foodLabel = "PRIME RIB BUFFET",
    effect    = "RAGE MODE",
    foods     = {"steak","lobster","turkey","cake","fries"},
  },

  ["Miami"] = {
    name      = "Kaiju Ceviche Bar",
    sub       = "South Beach Bites",
    welcome   = "¡Bienvenidos!",
    signCol   = {0.95, 0.35, 0.65},
    food      = "lobster",
    foodLabel = "STONE CRAB FEAST",
    effect    = "DAMAGE BOOST",
    foods     = {"lobster","sandwich","juice","empanada","nachos"},
  },

  ["New Orleans"] = {
    name      = "Jazz GAWDZILLA",
    sub       = "Bourbon Street Kitchen",
    welcome   = "Laissez les bons temps rouler!",
    signCol   = {0.92, 0.68, 0.08},
    food      = "bao",
    foodLabel = "KAIJU PO'BOY",
    effect    = "RAGE MODE",
    foods     = {"bao","sandwich","wings","pie","candy"},
  },

  ["Nashville"] = {
    name      = "HOT CHICKEN STOMP",
    sub       = "Nashville's Hottest",
    welcome   = "Y'ALL COME EAT!",
    signCol   = {0.95, 0.30, 0.05},
    food      = "wings",
    foodLabel = "NASHVILLE HOT WINGS",
    effect    = "DAMAGE BOOST",
    foods     = {"wings","hotdog","corndog","sandwich","waffle"},
  },

  ["Paris"] = {
    name      = "Café du Monstre",
    sub       = "Depuis 1947",
    welcome   = "Bienvenue, monstre!",
    signCol   = {0.25, 0.50, 0.85},
    food      = "croissant",
    foodLabel = "CROISSANT GÉANT",
    effect    = "SPEED SURGE",
    foods     = {"croissant","crepe","chocolate","cheese","cake"},
  },

  ["London"] = {
    name      = "The Kaiju Arms",
    sub       = "Est. 1952 — Proper Grub",
    welcome   = "Blimey, welcome!",
    signCol   = {0.22, 0.42, 0.68},
    food      = "sandwich",
    foodLabel = "FULL ENGLISH",
    effect    = "DAMAGE BOOST",
    foods     = {"sandwich","pie","cheese","cookie","chips"},
  },

  ["Dubai"] = {
    name      = "Kaiju Shawarma Palace",
    sub       = "Est. 2008",
    welcome   = "أهلاً وسهلاً!",
    signCol   = {0.95, 0.72, 0.15},
    food      = "kebab",
    foodLabel = "MEGA SHAWARMA",
    effect    = "DAMAGE BOOST",
    foods     = {"kebab","falafel","gyro","boba","pretzel"},
  },

  ["Sydney"] = {
    name      = "Down Under Smash",
    sub       = "Bondi Beach Kitchen",
    welcome   = "G'day, mate!",
    signCol   = {0.95, 0.55, 0.15},
    food      = "steak",
    foodLabel = "WAGYU BEEF SLAB",
    effect    = "DAMAGE BOOST",
    foods     = {"steak","pie","sandwich","cookie","apple"},
  },

  ["Tampa"] = {
    name      = "GAWDZILLA'S CUBAN",
    sub       = "Ybor City Original",
    welcome   = "Bienvenido!",
    signCol   = {0.92, 0.60, 0.08},
    food      = "sandwich",
    foodLabel = "CUBAN SANDWICH",
    effect    = "SPEED SURGE",
    foods     = {"sandwich","hotdog","fries","juice","cake"},
  },

  ["Honolulu"] = {
    name      = "KAIJU LUAU",
    sub       = "Aloha Feasts",
    welcome   = "Aloha! E komo mai!",
    signCol   = {0.92, 0.35, 0.20},
    food      = "turkey",
    foodLabel = "KALUA PIG FEAST",
    effect    = "RAGE MODE",
    foods     = {"turkey","sandwich","pineapple-juice","watermelon","boba"},
  },

}

-- Regional fallbacks for unmapped cities
local REGIONAL = {
  US     = { name="LOCAL DINER",          sub="Est. America",      welcome="Welcome!",             signCol={0.88,0.65,0.15}, food="burger",    foodLabel="ALL-AMERICAN BURGER", effect="DAMAGE BOOST", foods={"burger","hotdog","fries","sandwich","pie"} },
  ASIA   = { name="NOODLE HOUSE",         sub="Asian Kitchen",     welcome="Welcome!",             signCol={0.92,0.22,0.15}, food="noodles",   foodLabel="NOODLE BOWL",         effect="SPEED SURGE",  foods={"noodles","dumpling","friedrice","bao","springroll"} },
  EUROPE = { name="LE BISTROT DU MONSTRE",sub="European Cuisine",  welcome="Bienvenue!",           signCol={0.22,0.42,0.75}, food="croissant", foodLabel="EUROPEAN PLATTER",    effect="SPEED SURGE",  foods={"croissant","cheese","sandwich","pie","pretzel"} },
  LATAM  = { name="KAIJU TAQUERIA",       sub="Latin Kitchen",     welcome="¡Bienvenidos!",        signCol={0.92,0.35,0.10}, food="taco",      foodLabel="MEGA TACOS",          effect="RAGE MODE",    foods={"taco","empanada","nachos","sandwich","candy"} },
}

-- US city → REGIONAL key mapping (best-guess regional fallback)
local US_CITIES = {
  "Houston","Dallas","Atlanta","Philadelphia","Minneapolis","Denver",
  "Pittsburgh","Baltimore","Cincinnati","Nashville","Milwaukee","Indianapolis",
  "Columbus","Kansas City","Memphis","Louisville","Richmond","Charlotte",
  "Raleigh","Jacksonville","Detroit","Cleveland","St. Louis","Portland",
  "Salt Lake City","Albuquerque","Seattle","Boston",
}
local US_SET = {}
for _, c in ipairs(US_CITIES) do US_SET[c] = true end

function RD.get(cityKey)
  if not cityKey then return REGIONAL.US end
  local d = RD.CITIES[cityKey]
  if d then return d end
  if US_SET[cityKey] then return REGIONAL.US end
  -- Regional guess by name hints
  if cityKey:find("Paris") or cityKey:find("London") or cityKey:find("Frankfurt") then return REGIONAL.EUROPE end
  return REGIONAL.US
end

return RD
