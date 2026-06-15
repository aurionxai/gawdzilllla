-- src/fps/combat_fps.lua
-- Geometric hit checks for FPS combat. No LÖVE dependencies — pure math.

local Combat = {}

-- Atomic breath: cone in front of player.
-- cone half-angle ≈ 30° → dot threshold cos(30°) ≈ 0.866.
-- Returns hit (bool), dist (number).
function Combat.checkRangedHit(camera, enemy, rangeMax)
  local dx = enemy.x - camera.x
  local dy = enemy.y - camera.y
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist > rangeMax or dist == 0 then return false, 0 end
  local dirX, dirY = camera:getDir()
  local dot = (dx / dist) * dirX + (dy / dist) * dirY
  if dot < 0.866 then return false, 0 end
  return true, dist
end

-- Claw / bite: radius distance check in all directions.
-- Returns hit (bool), dist (number).
function Combat.checkMeleeHit(camera, enemy, rangeMax)
  local dx = enemy.x - camera.x
  local dy = enemy.y - camera.y
  local dist = math.sqrt(dx * dx + dy * dy)
  return dist <= rangeMax, dist
end

-- Tail slam: wide arc to sides and behind (dot < 0.5 → more than ~60° off-axis).
-- Returns hit (bool), dist (number).
function Combat.checkTailHit(camera, enemy, rangeMax)
  local dx = enemy.x - camera.x
  local dy = enemy.y - camera.y
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist > rangeMax or dist == 0 then return false, 0 end
  local dirX, dirY = camera:getDir()
  local dot = (dx / dist) * dirX + (dy / dist) * dirY
  if dot > 0.5 then return false, 0 end   -- too far forward; tail doesn't reach there
  return true, dist
end

return Combat
