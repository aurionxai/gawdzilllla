-- src/audio_manager.lua
local AM   = {}
AM.__index = AM

local _instance = nil

function AM.getInstance()
  if not _instance then _instance = AM.new() end
  return _instance
end

local function loadClips(pattern, count)
  local clips = {}
  for i = 1, count do
    local path = string.format(pattern, i)
    if love.filesystem.getInfo(path) then
      local ok, src = pcall(love.audio.newSource, path, "static")
      if ok then clips[#clips + 1] = src end
    end
  end
  return clips
end

local function loadClip(path, mode)
  if love.filesystem.getInfo(path) then
    local ok, src = pcall(love.audio.newSource, path, mode or "static")
    if ok then return src end
  end
  return nil
end

local function playRandom(clips, lastIdx)
  if #clips == 0 then return lastIdx end
  local idx
  repeat idx = math.random(1, #clips)
  until idx ~= lastIdx or #clips == 1
  clips[idx]:clone():play()
  return idx
end

function AM.new()
  local self = setmetatable({
    _splatClips      = {},
    _screamClips     = {},
    _collapseClips   = {},
    _hitLightClips   = {},
    _hitHeavyClips   = {},
    _crowdPanicClip  = nil,
    _musicSource     = nil,
    _lastSplat       = -1,
    _lastScream      = -1,
    _lastCollapse    = -1,
    _lastHitLight    = -1,
    _lastHitHeavy    = -1,
  }, AM)

  self._splatClips     = loadClips("Assets/audio/splat_%02d.wav", 12)
  self._screamClips    = loadClips("Assets/audio/scream_%02d.wav", 4)
  self._collapseClips  = loadClips("Assets/audio/collapse_%02d.wav", 3)
  self._hitLightClips  = loadClips("Assets/audio/hit_light_%02d.wav", 3)
  self._hitHeavyClips  = loadClips("Assets/audio/hit_heavy_%02d.wav", 3)
  self._crowdPanicClip = loadClip("Assets/audio/crowd_panic.wav")

  -- BGM (wav, streamed + looped)
  self._musicSource = loadClip("Assets/audio/battle_bgm.wav", "stream")
  if self._musicSource then
    self._musicSource:setLooping(true)
  end

  return self
end

function AM:playMusic()
  if self._musicSource and not self._musicSource:isPlaying() then
    self._musicSource:play()
  end
end

function AM:stopMusic()
  if self._musicSource then self._musicSource:stop() end
end

function AM:playRandomSplat()
  self._lastSplat = playRandom(self._splatClips, self._lastSplat)
end

function AM:playScream()
  self._lastScream = playRandom(self._screamClips, self._lastScream)
end

function AM:playCollapse()
  self._lastCollapse = playRandom(self._collapseClips, self._lastCollapse)
end

function AM:playCrowdPanic()
  if self._crowdPanicClip then
    self._crowdPanicClip:clone():play()
  end
end

-- Called when a kaiju lands a hit on the opponent.
-- Heavy hits (damage >= 25) use the heavier impact sound.
function AM:playHit(damage)
  if damage and damage >= 25 then
    self._lastHitHeavy = playRandom(self._hitHeavyClips, self._lastHitHeavy)
  else
    self._lastHitLight = playRandom(self._hitLightClips, self._lastHitLight)
  end
end

function AM:playSFX(clip)
  if not clip then return end
  clip:clone():play()
end

return AM
