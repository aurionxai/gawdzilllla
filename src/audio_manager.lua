-- src/audio_manager.lua
-- Gracefully no-ops if audio files are missing.
local AM   = {}
AM.__index = AM

local _instance = nil

function AM.getInstance()
  if not _instance then _instance = AM.new() end
  return _instance
end

function AM.new()
  local self = setmetatable({
    _sfxSource   = nil,
    _musicSource = nil,
    _splatClips  = {},
    _lastSplat   = -1,
    _enabled     = true,
  }, AM)

  -- Try loading splat placeholder (silent if file absent)
  -- Place real files in assets/audio/splat_01.wav through splat_12.wav
  local ok
  self._splatClips = {}
  for i = 1, 12 do
    local path = string.format("assets/audio/splat_%02d.wav", i)
    local exists = love.filesystem.getInfo(path)
    if exists then
      ok, self._splatClips[#self._splatClips + 1] = pcall(love.audio.newSource, path, "static")
    end
  end

  local musicPath = "assets/audio/battle_bgm.ogg"
  if love.filesystem.getInfo(musicPath) then
    local mok, src = pcall(love.audio.newSource, musicPath, "stream")
    if mok then
      self._musicSource = src
      self._musicSource:setLooping(true)
    end
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
  if #self._splatClips == 0 then return end
  local idx
  repeat idx = math.random(1, #self._splatClips)
  until idx ~= self._lastSplat or #self._splatClips == 1
  self._lastSplat = idx
  local src = self._splatClips[idx]:clone()
  src:play()
end

function AM:playSFX(clip)
  if not clip then return end
  local src = clip:clone()
  src:play()
end

return AM
