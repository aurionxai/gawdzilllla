-- src/fps/hud_fps.lua
-- Overlay drawn on top of the raycaster each frame.
-- Draws: player HP, enemy HP, city integrity, civilians saved, ability bar,
--        Monarch comms panel, and player kaiju hands at bottom corners.

local Hud = {}

local SCREEN_W = 480
local SCREEN_H = 270

local ABILITIES = {
  { key="Q", name="ATOMIC BREATH", move="ranged",  color={0.10,0.90,1.00} },
  { key="Z", name="CLAW SWIPE",    move="claw",    color={0.90,0.40,0.20} },
  { key="X", name="BITE",          move="bite",    color={0.90,0.20,0.20} },
  { key="C", name="TAIL SLAM",     move="tail",    color={0.90,0.60,0.10} },
}
local SLOT_W = math.floor(SCREEN_W / #ABILITIES)

-- Internal helper: draw a filled bar with a dark background track.
-- Must be defined before Hud.draw (Lua 5.1: no forward references).
local function _bar(x, y, w, h, ratio, color)
  love.graphics.setColor(0.08, 0.08, 0.08)
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.rectangle("fill", x, y, math.floor(w * math.max(0, math.min(1, ratio))), h)
end

function Hud.draw(player, enemy, cityIntegrity, civsSaved, totalCivs, monarchMsg)
  -- Player kaiju hands (your body in FPS)
  love.graphics.setColor(0.15, 0.40, 0.20)
  love.graphics.polygon("fill", -10,SCREEN_H, 60,SCREEN_H, 55,232, 14,218, -5,245)
  love.graphics.polygon("fill", SCREEN_W+10,SCREEN_H, SCREEN_W-60,SCREEN_H,
                                SCREEN_W-55,232, SCREEN_W-14,218, SCREEN_W+5,245)

  -- Top-left: player HP
  love.graphics.setColor(0,0,0, 0.60)
  love.graphics.rectangle("fill", 4, 4, 118, 34)
  love.graphics.setColor(0.20, 0.85, 0.35)
  love.graphics.print("GAWDZILLA  LVL " .. player.level, 7, 6)
  _bar(7, 17, 110, 6, player.hp / player.maxHp, {0.10,0.90,0.25})
  love.graphics.setColor(0.55, 0.55, 0.55)
  love.graphics.print("HP " .. player.hp .. " / " .. player.maxHp, 7, 26)

  -- Top-center: city integrity
  love.graphics.setColor(0,0,0, 0.60)
  love.graphics.rectangle("fill", 178, 4, 124, 26)
  love.graphics.setColor(0.95, 0.80, 0.25)
  love.graphics.printf("TOKYO INTEGRITY", 178, 6, 124, "center")
  _bar(181, 17, 118, 5, cityIntegrity, {0.95,0.80,0.25})

  -- Top-right: civilians saved
  love.graphics.setColor(0,0,0, 0.60)
  love.graphics.rectangle("fill", 354, 4, 122, 26)
  love.graphics.setColor(0.35, 0.68, 1.00)
  love.graphics.print("CIVILIANS SAFE", 358, 6)
  love.graphics.print(civsSaved .. " / " .. totalCivs, 358, 18)

  -- Enemy HP bar (below top strip when alive)
  if enemy and enemy.hp > 0 then
    love.graphics.setColor(0,0,0, 0.65)
    love.graphics.rectangle("fill", 138, 32, 204, 18)
    love.graphics.setColor(0.85, 0.15, 0.15)
    love.graphics.printf("GHIDORAH  " .. enemy.hp .. " / " .. enemy.maxHp,
                         138, 34, 204, "center")
    _bar(141, 43, 198, 4, enemy.hp / enemy.maxHp, {0.90,0.10,0.10})
  end

  -- Monarch comms panel (above ability bar)
  if monarchMsg then
    love.graphics.setColor(0,0,0, 0.80)
    love.graphics.rectangle("fill", 4, SCREEN_H - 44, SCREEN_W - 8, 24)
    love.graphics.setColor(0.20, 0.85, 0.35)
    love.graphics.print("⚡ DR. CHEN — MONARCH COMMAND", 8, SCREEN_H - 42)
    love.graphics.setColor(0.88, 0.88, 0.88)
    love.graphics.print(monarchMsg, 8, SCREEN_H - 30)
  end

  -- Ability bar (bottom strip)
  love.graphics.setColor(0,0,0, 0.85)
  love.graphics.rectangle("fill", 0, SCREEN_H - 18, SCREEN_W, 18)

  for i, ab in ipairs(ABILITIES) do
    local x       = (i - 1) * SLOT_W
    local unlocked = player:isUnlocked(ab.move)
    local ready    = unlocked and player.cooldowns[ab.move] <= 0

    if unlocked and ready then
      love.graphics.setColor(ab.color[1], ab.color[2], ab.color[3])
    elseif unlocked then
      love.graphics.setColor(0.35, 0.35, 0.35)
    else
      love.graphics.setColor(0.22, 0.22, 0.22)
    end

    local label = unlocked and ("[" .. ab.key .. "] " .. ab.name) or ("[" .. ab.key .. "] LOCKED")
    love.graphics.print(label, x + 3, SCREEN_H - 14)

    -- Cooldown fill bar (2px at very bottom)
    if unlocked and not ready then
      local ratio = 1 - (player.cooldowns[ab.move] / player.cooldownMax[ab.move])
      love.graphics.setColor(ab.color[1] * 0.5, ab.color[2] * 0.5, ab.color[3] * 0.5)
      love.graphics.rectangle("fill", x, SCREEN_H - 18, math.floor(SLOT_W * ratio), 2)
    end
  end
end

return Hud
