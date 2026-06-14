-- src/scene_manager.lua
local SM = {}
local _stack = {}

function SM.push(scene)    table.insert(_stack, scene) end
function SM.pop()          table.remove(_stack) end
function SM.replace(scene) _stack[#_stack] = scene end
function SM.current()      return _stack[#_stack] end

function SM.update(dt)
  local s = _stack[#_stack]; if s and s.update then s:update(dt) end
end
function SM.draw()
  local s = _stack[#_stack]; if s and s.draw then s:draw() end
end
function SM.keypressed(key)
  local s = _stack[#_stack]; if s and s.keypressed then s:keypressed(key) end
end
function SM.keyreleased(key)
  local s = _stack[#_stack]; if s and s.keyreleased then s:keyreleased(key) end
end

return SM
