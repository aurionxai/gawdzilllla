-- src/story_lore.lua
-- Narrative text cards shown before each city assault.
-- Each entry: title, year/context, lines (2-3 sentences), and spare/destroy flavor text.

local L = {}

L.CITY = {
  honolulu = {
    title  = "Honolulu, Hawaii",
    year   = "Year Zero",
    lines  = {
      "The first reading came from 3,000 feet beneath the Pacific.",
      "By morning, the beach was empty.",
      "By noon, so was the island.",
    },
    spare_text   = "You turn away from the burning shore.\nSomething watches from the water.",
    destroy_text = "The city goes silent.\nSomewhere, a beach umbrella tumbles into the sea.",
  },

  tokyo = {
    title  = "Tokyo, Japan",
    year   = "Where It Began",
    lines  = {
      "1954. A fishing boat. A flash of light below the waves.",
      "Seventy years of rebuilding. Seventy years of waiting.",
      "They always knew something would return.",
    },
    spare_text   = "The defender limps into the bay and disappears.\nOld wounds. Old memories.",
    destroy_text = "The last skyscraper falls at dawn.\nHistory repeats itself, exactly as feared.",
  },

  sf = {
    title  = "San Francisco, California",
    year   = "Day 4",
    lines  = {
      "The Golden Gate Bridge has survived earthquakes, fog, and budget committees.",
      "No one planned for this.",
    },
    spare_text   = "You let them go.\nThe bridge, somehow, still stands.",
    destroy_text = "The bridge did not survive this one.",
  },

  seoul = {
    title  = "Seoul, South Korea",
    year   = "Day 8",
    lines  = {
      "The music stopped at 3:47 AM.",
      "No announcement. No warning. Just silence, then thunder.",
      "Twelve million people reached for their phones at the same moment.",
    },
    spare_text   = "Silence returns to the Han River.\nIn the distance, an alarm still plays.",
    destroy_text = "The last broadcast was a weather report.\nIt was wrong about the forecast.",
  },

  newyork = {
    title  = "New York City",
    year   = "Day 12",
    lines  = {
      "Manhattan has survived much.",
      "The locals are annoyed, mostly.",
      "The pigeons don't even look up anymore.",
    },
    spare_text   = "You leave. The city complains about the commute.",
    destroy_text = "Several buildings collapse.\nA hot dog stand, somehow, remains.",
  },

  hongkong = {
    title  = "Hong Kong",
    year   = "Day 18",
    lines  = {
      "The harbor has witnessed dynasties rise and fall for three thousand years.",
      "It has never been particularly impressed by anything.",
      "Tonight is different.",
    },
    spare_text   = "The neon lights flicker back on, one by one.",
    destroy_text = "The lights go out across the harbor.\nFor the first time in a century, real darkness.",
  },

  london = {
    title  = "London, England",
    year   = "Day 23",
    lines  = {
      "The Thames ran backwards for six minutes.",
      "Scientists called it a tidal anomaly.",
      "The Thames had no comment.",
    },
    spare_text   = "Big Ben still ticks.\nSomething to be said for stubbornness.",
    destroy_text = "Parliament is rubble.\nNobody is sure if this is bad or not.",
  },

  sydney = {
    title  = "Sydney, Australia",
    year   = "Day 29",
    lines  = {
      "The Opera House has some of the finest acoustics on Earth.",
      "The roar that echoed through it last night was not on the program.",
    },
    spare_text   = "You spare the city.\nThe Opera House gives you a five-star review.",
    destroy_text = "The harbor bridge comes down in one clean arc.\nVery dramatic.",
  },

  dubai = {
    title  = "Dubai, UAE",
    year   = "Day 35",
    lines  = {
      "The Burj Khalifa was engineered to touch the sky.",
      "Something else had the same idea.",
    },
    spare_text   = "You walk away.\nThe tower stands. For now.",
    destroy_text = "The tallest building in the world is no longer the tallest building in the world.",
  },

  monster = {
    title  = "Monster Island",
    year   = "The End",
    lines  = {
      "No civilians. No military. No cameras.",
      "Just the island. The silence.",
      "And whatever has been waiting here.",
    },
    spare_text   = "You show mercy at the edge of everything.\nThe island remembers.",
    destroy_text = "It is over.\nYou are the last thing standing on Monster Island.",
  },
}

-- Fallback for cities not in the lore table
L.DEFAULT = {
  title  = "Somewhere on Earth",
  year   = "",
  lines  = {
    "Another city. Another reckoning.",
    "The military is already here.",
  },
  spare_text   = "You leave the city standing. Mostly.",
  destroy_text = "Another skyline, gone.",
}

function L.get(cityKey)
  return L.CITY[cityKey] or L.DEFAULT
end

return L
