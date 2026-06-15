-- src/story_state.lua
-- Singleton: tracks the player's story-mode campaign progress.
local S = {}

-- City definitions for the world map campaign.
-- cityName must match a name in src/cities_data.lua exactly.
-- defender must match a name in the CHARS table in character_select.lua.
-- requires: list of city keys that must be conquered first.
S.CITIES = {
  -- Tier 1: always available
  { key="honolulu",   name="Honolulu",       cityName="San Francisco",
    defender="Mothra",        x=52,  y=152, requires={}, isStart=true  },
  { key="tokyo",      name="Tokyo",           cityName="Tokyo",
    defender="MechaGodzilla", x=375, y=125, requires={}, isStart=true  },

  -- Tier 2
  { key="sf",         name="San Francisco",   cityName="San Francisco",
    defender="Hedorah",       x=76,  y=120, requires={"honolulu"}       },
  { key="seoul",      name="Seoul",           cityName="Seoul",
    defender="Rodan",         x=368, y=104, requires={"tokyo"}          },

  -- Tier 3
  { key="newyork",    name="New York",        cityName="New York City",
    defender="Destoroyah",    x=146, y=104, requires={"sf"}             },
  { key="hongkong",   name="Hong Kong",       cityName="Hong Kong",
    defender="Anguirus",      x=352, y=150, requires={"seoul"}          },

  -- Tier 4
  { key="london",     name="London",          cityName="London",
    defender="Gigan",         x=215, y=92,  requires={"newyork"}        },
  { key="sydney",     name="Sydney",          cityName="Sydney",
    defender="Biollante",     x=382, y=186, requires={"hongkong"}       },

  -- Tier 5
  { key="dubai",      name="Dubai",           cityName="Dubai",
    defender="SpaceGodzilla", x=283, y=140, requires={"london","hongkong"} },

  -- Final
  { key="monster",    name="Monster Island",  cityName="Las Vegas",
    defender="Ghidorah",      x=200, y=178, requires={"dubai","sydney"}, isFinal=true },
}

-- Map each key → index for fast lookup
S._cityIdx = {}
for i, c in ipairs(S.CITIES) do S._cityIdx[c.key] = i end

-- Connections to draw as lines on the map
S.CONNECTIONS = {
  {"honolulu","sf"},
  {"sf","newyork"},
  {"newyork","london"},
  {"london","dubai"},
  {"tokyo","seoul"},
  {"seoul","hongkong"},
  {"hongkong","dubai"},
  {"hongkong","sydney"},
  {"dubai","monster"},
  {"sydney","monster"},
}

-- Runtime state (reset when starting a new story)
S.playerChar = nil     -- CHARS table entry for the player
S.conquered  = {}      -- set of conquered city keys

function S.startNew(charEntry)
  S.playerChar = charEntry
  S.conquered  = {}
end

function S.conquer(key)
  S.conquered[key] = true
end

function S.isConquered(key)
  return S.conquered[key] == true
end

function S.isUnlocked(city)
  if city.isStart then return true end
  for _, req in ipairs(city.requires) do
    if not S.conquered[req] then return false end
  end
  return true
end

-- Returns the effective defender for a city, swapping if player is the same character.
function S.getDefender(city, CHARS)
  local defName = city.defender
  -- If player picked this character, use the fallback (next in roster)
  if S.playerChar and S.playerChar.name == defName then
    -- Find a substitute: highest-HP character that isn't the player or already a defender
    local used = { [defName] = true, [S.playerChar.name] = true }
    local best
    for _, c in ipairs(CHARS) do
      if not used[c.name] then
        if not best or c.hp > best.hp then best = c end
      end
    end
    return best or CHARS[1]
  end
  for _, c in ipairs(CHARS) do
    if c.name == defName then return c end
  end
  return CHARS[1]
end

-- Find the CitiesData entry that matches a cityName
function S.findCityDef(CitiesData, cityName)
  for _, cd in ipairs(CitiesData) do
    if cd.name == cityName then return cd end
  end
  return CitiesData[1]
end

function S.allConquered()
  for _, city in ipairs(S.CITIES) do
    if not S.conquered[city.key] then return false end
  end
  return true
end

return S
