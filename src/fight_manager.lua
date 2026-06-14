-- src/fight_manager.lua
local FM   = {}
FM.__index = FM

function FM.new(p1char, p2char, opts)
  opts = opts or {}
  return setmetatable({
    p1char        = p1char,
    p2char        = p2char,
    totalRounds   = opts.totalRounds   or 3,
    roundDuration = opts.roundDuration or 99,
    p1RoundsWon   = 0,
    p2RoundsWon   = 0,
    currentRound  = 0,
    timeRemaining = 0,
    roundActive   = false,
    _nextRoundTimer = 0,
    -- Callbacks
    onRoundStart = nil,
    onRoundEnd   = nil,
    onMatchEnd   = nil,
  }, FM)
end

function FM:startMatch()
  self.p1RoundsWon  = 0
  self.p2RoundsWon  = 0
  self.currentRound = 0
  self:_startNextRound()
end

function FM:_startNextRound()
  self.currentRound  = self.currentRound + 1
  self.timeRemaining = self.roundDuration
  self.roundActive   = true
  self._nextRoundTimer = 0
  self.p1char:resetForNewRound()
  self.p2char:resetForNewRound()
  if self.onRoundStart then self.onRoundStart(self.currentRound) end
end

-- Exposed for tests to skip the 2s delay
function FM:_forceStartNextRound()
  self._nextRoundTimer = 0
  self:_startNextRound()
end

function FM:update(dt)
  -- Pending next-round countdown
  if self._nextRoundTimer > 0 then
    self._nextRoundTimer = self._nextRoundTimer - dt
    if self._nextRoundTimer <= 0 then
      self:_startNextRound()
    end
    return
  end

  if not self.roundActive then return end

  self.timeRemaining = self.timeRemaining - dt

  if self.p1char.isDefeated then
    self:_endRound(2)
  elseif self.p2char.isDefeated then
    self:_endRound(1)
  elseif self.timeRemaining <= 0 then
    local w = self.p1char:healthPercent() >= self.p2char:healthPercent() and 1 or 2
    self:_endRound(w)
  end
end

function FM:_endRound(winner)
  self.roundActive = false
  if winner == 1 then self.p1RoundsWon = self.p1RoundsWon + 1
  else                self.p2RoundsWon = self.p2RoundsWon + 1 end
  if self.onRoundEnd then self.onRoundEnd(winner) end

  local needed = math.ceil(self.totalRounds / 2)
  if self.p1RoundsWon >= needed then
    if self.onMatchEnd then self.onMatchEnd(1) end
  elseif self.p2RoundsWon >= needed then
    if self.onMatchEnd then self.onMatchEnd(2) end
  else
    self._nextRoundTimer = 2.0
  end
end

return FM
