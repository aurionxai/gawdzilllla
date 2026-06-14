# GAWDZILLLLA — LÖVE 2D Phase 1 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable 2-player local fighting game in LÖVE 2D (Lua) with 3 kaiju characters, combat system, NPC splat, HUD, and scene flow — runnable immediately with `love .`

**Architecture:** Pure Lua modules (no external dependencies). Simple AABB physics with gravity constant — no Box2D needed for a fighting game. All logic modules avoid love APIs so they can be unit-tested with plain `lua`. Scenes are Lua tables pushed/popped via SceneManager. Reference resolution 480×270, pixel-perfect scaled to any window.

**Tech Stack:** LÖVE 2D 11.x, Lua 5.1, `lua` CLI for unit tests (logic only), `love .` to run the game

---

## File Map

```
conf.lua                          window config (480×270 × 2 = 960×540)
main.lua                          love.load / update / draw / keypressed
src/
  scene_manager.lua               push/pop scene stack, dispatch update/draw/keypressed
  character.lua                   base character: health, power, events, combat state
  attack_system.lua               attack state machine (startup→active→recovery), hitboxes, combo
  controller.lua                  position, velocity, gravity, ground clamp, stun
  input.lua                       P1 (WASD+ZXCV) and P2 (arrows+IJKL) keyboard map
  npc.lua                         NPC wander + stomp death
  npc_spawner.lua                 spawn pool, destruction score, splat streak
  blood_pool.lua                  object pool for blood splat particles (colored rects)
  hud.lua                         draws health bars, power meter, timer, combo text
  fight_manager.lua               round/match state machine, round timer, KO/timeout detection
  audio_manager.lua               plays SFX/music, graceful no-op if files missing
  scenes/
    main_menu.lua                 GAWDZILLLLA title + PLAY / QUIT buttons
    character_select.lua          3-card picker (P1 first, then P2), FIGHT button
    battle.lua                    wires all systems, runs the fight, renders scene
  characters/
    godzilla.lua                  Godzilla stats + NuclearPulse unleash
    kong.lua                      Kong stats + PrimalRage unleash
    ghidorah.lua                  Ghidorah stats + TripleBeam unleash
tests/
  runner.lua                      minimal assert harness (run with: lua tests/run_all.lua)
  run_all.lua                     requires all test files
  test_character.lua              9 tests for character.lua
  test_attack_system.lua          5 tests for attack_system.lua
  test_controller.lua             4 tests for controller.lua
  test_npc_spawner.lua            3 tests for npc_spawner.lua
  test_fight_manager.lua          4 tests for fight_manager.lua
```

---

## Task 1: Scaffold — conf.lua + main.lua + scene_manager.lua

**Files:**
- Create: `conf.lua`
- Create: `main.lua`
- Create: `src/scene_manager.lua`

- [ ] **Step 1: Create conf.lua**

```lua
-- conf.lua
function love.conf(t)
  t.window.title  = "GAWDZILLLLA"
  t.window.width  = 960
  t.window.height = 540
  t.window.resizable = true
  t.modules.joystick = false
  t.modules.physics  = false
end
```

- [ ] **Step 2: Create src/scene_manager.lua**

```lua
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
```

- [ ] **Step 3: Create main.lua**

```lua
-- main.lua
local SM = require("src/scene_manager")

-- Reference resolution
local REF_W, REF_H = 480, 270

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  -- Defer scene import to avoid circular requires at module load time
  local MainMenu = require("src/scenes/main_menu")
  SM.push(MainMenu.new())
end

function love.update(dt)
  SM.update(dt)
end

function love.draw()
  local sw, sh = love.graphics.getDimensions()
  local scale  = math.min(sw / REF_W, sh / REF_H)
  local ox     = math.floor((sw - REF_W * scale) / 2)
  local oy     = math.floor((sh - REF_H * scale) / 2)
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(scale, scale)
  love.graphics.setScissor(ox, oy, REF_W * scale, REF_H * scale)
  SM.draw()
  love.graphics.setScissor()
  love.graphics.pop()
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  SM.keypressed(key)
end

function love.keyreleased(key)
  SM.keyreleased(key)
end
```

- [ ] **Step 4: Create placeholder main_menu.lua so love.load() doesn't crash**

```lua
-- src/scenes/main_menu.lua
-- Full implementation in Task 10. Placeholder keeps the scaffold runnable.
local SM   = require("src/scene_manager")
local Menu = {}
Menu.__index = Menu

function Menu.new()
  return setmetatable({ _ready = false }, Menu)
end

function Menu:update(dt) end

function Menu:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)
  love.graphics.setColor(1, 0.8, 0)
  love.graphics.printf("GAWDZILLLLA", 0, 100, 480, "center")
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.printf("(scaffold — press any key)", 0, 140, 480, "center")
end

function Menu:keypressed(key) end

return Menu
```

- [ ] **Step 5: Create directory structure**

```bash
mkdir -p src/scenes src/characters tests
```

- [ ] **Step 6: Verify scaffold runs**

```bash
love .
```

Expected: 960×540 dark window opens with gold "GAWDZILLLLA" title. No errors in console.

- [ ] **Step 7: Commit**

```bash
git add conf.lua main.lua src/scene_manager.lua src/scenes/main_menu.lua
git commit -m "feat: LÖVE 2D scaffold — window, scene manager, placeholder menu"
```

---

## Task 2: Character Base + Tests

**Files:**
- Create: `src/character.lua`
- Create: `tests/runner.lua`
- Create: `tests/run_all.lua`
- Create: `tests/test_character.lua`

- [ ] **Step 1: Create tests/runner.lua**

```lua
-- tests/runner.lua
-- Minimal test harness. Run with: lua tests/run_all.lua
local R = {}
R._pass = 0
R._fail = 0

function R.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    R._pass = R._pass + 1
    print("  ✓ " .. name)
  else
    R._fail = R._fail + 1
    print("  ✗ " .. name)
    print("    " .. tostring(err))
  end
end

function R.eq(a, b, label)
  if a ~= b then
    error((label and label .. ": " or "") .. "expected " .. tostring(b) .. ", got " .. tostring(a), 2)
  end
end

function R.approx(a, b, label)
  if math.abs(a - b) > 0.001 then
    error((label and label .. ": " or "") .. "expected ~" .. tostring(b) .. ", got " .. tostring(a), 2)
  end
end

function R.ok(v, label)
  if not v then error((label or "expected truthy"), 2) end
end

function R.notok(v, label)
  if v then error((label or "expected falsy"), 2) end
end

function R.summary()
  print(string.format("\n%d passed, %d failed", R._pass, R._fail))
  if R._fail > 0 then os.exit(1) end
end

return R
```

- [ ] **Step 2: Create tests/run_all.lua**

```lua
-- tests/run_all.lua
-- Run with: lua tests/run_all.lua
require("tests/test_character")
require("tests/test_attack_system")
require("tests/test_controller")
require("tests/test_npc_spawner")
require("tests/test_fight_manager")
require("tests/runner").summary()
```

- [ ] **Step 3: Write failing tests for character.lua**

```lua
-- tests/test_character.lua
local R   = require("tests/runner")
local Char = require("src/character")

local function makeChar(maxHp)
  return Char.new({ maxHealth = maxHp or 100, moveSpeed = 5 })
end

print("\n-- character.lua --")

R.test("takeDamage reduces health", function()
  local c = makeChar()
  c:takeDamage(30)
  R.eq(c.health, 70)
end)

R.test("takeDamage cannot go below zero", function()
  local c = makeChar()
  c:takeDamage(999)
  R.eq(c.health, 0)
  R.ok(c.isDefeated)
end)

R.test("takeDamage does nothing when invincible", function()
  local c = makeChar()
  c.isInvincible = true
  c:takeDamage(50)
  R.eq(c.health, 100)
end)

R.test("takeDamage doubles in counter state and resets counter", function()
  local c = makeChar()
  c.isCounterState = true
  c:takeDamage(20)
  R.eq(c.health, 60)      -- 20 * 2 = 40 damage
  R.notok(c.isCounterState)
end)

R.test("gainPower increases meter", function()
  local c = makeChar()
  c:gainPower(30)
  R.eq(c.power, 30)
end)

R.test("gainPower caps at 100", function()
  local c = makeChar()
  c:gainPower(200)
  R.eq(c.power, 100)
  R.ok(c:isPowerFull())
end)

R.test("gainPower fires onPowerFull only on 0→full transition", function()
  local c = makeChar()
  local fired = 0
  c.onPowerFull = function() fired = fired + 1 end
  c:gainPower(100)
  R.eq(fired, 1)
  c:gainPower(50)   -- already full, should not re-fire
  R.eq(fired, 1)
end)

R.test("spendPower reduces meter", function()
  local c = makeChar()
  c:gainPower(50)
  c:spendPower(25)
  R.eq(c.power, 25)
end)

R.test("resetForNewRound restores all state", function()
  local c = makeChar()
  c:takeDamage(80)
  c:gainPower(60)
  c.isInvincible  = true
  c.isCounterState = true
  c:resetForNewRound()
  R.eq(c.health, 100)
  R.eq(c.power, 0)
  R.notok(c.isDefeated)
  R.notok(c.isInvincible)
  R.notok(c.isCounterState)
end)
```

- [ ] **Step 4: Run tests — expect failure (module not found)**

```bash
lua tests/run_all.lua 2>&1 | head -20
```

Expected: `module 'src/character' not found`

- [ ] **Step 5: Create src/character.lua**

```lua
-- src/character.lua
local Character = {}
Character.__index = Character

function Character.new(stats)
  return setmetatable({
    stats        = stats,
    health       = stats.maxHealth,
    power        = 0,
    isDefeated   = false,
    isInvincible = false,
    isCounterState = false,
    -- event callbacks (assign externally)
    onHealthChanged = nil,
    onPowerChanged  = nil,
    onDefeated      = nil,
    onPowerFull     = nil,
  }, Character)
end

function Character:takeDamage(amount)
  if self.isInvincible or self.isDefeated then return end
  local mult = self.isCounterState and 2 or 1
  self.isCounterState = false
  self.health = math.max(0, self.health - amount * mult)
  if self.onHealthChanged then self.onHealthChanged(self.health) end
  if self.health <= 0 and not self.isDefeated then
    self.isDefeated = true
    if self.onDefeated then self.onDefeated() end
  end
end

function Character:gainPower(amount)
  if self.isDefeated then return end
  local wasFull = self:isPowerFull()
  self.power = math.min(100, self.power + amount)
  if self.onPowerChanged then self.onPowerChanged(self.power) end
  if not wasFull and self:isPowerFull() then
    if self.onPowerFull then self.onPowerFull() end
  end
end

function Character:spendPower(amount)
  self.power = math.max(0, self.power - amount)
  if self.onPowerChanged then self.onPowerChanged(self.power) end
end

function Character:restoreHealth(percent)
  self.health = math.min(self.stats.maxHealth, self.health + self.stats.maxHealth * percent)
  if self.onHealthChanged then self.onHealthChanged(self.health) end
end

function Character:resetForNewRound()
  self.health        = self.stats.maxHealth
  self.power         = 0
  self.isDefeated    = false
  self.isInvincible  = false
  self.isCounterState = false
  if self.onHealthChanged then self.onHealthChanged(self.health) end
  if self.onPowerChanged  then self.onPowerChanged(self.power) end
end

function Character:healthPercent() return self.health / self.stats.maxHealth end
function Character:powerPercent()  return self.power / 100 end
function Character:isPowerFull()   return self.power >= 100 end

return Character
```

- [ ] **Step 6: Run tests — expect character tests pass (others still fail)**

```bash
lua tests/run_all.lua 2>&1 | head -30
```

Expected: 9 character tests pass. Other modules not found yet (expected).

- [ ] **Step 7: Commit**

```bash
git add src/character.lua tests/runner.lua tests/run_all.lua tests/test_character.lua
git commit -m "feat: Character base with health/power system + 9 passing tests"
```

---

## Task 3: Attack System + Tests

**Files:**
- Create: `src/attack_system.lua`
- Create: `tests/test_attack_system.lua`

- [ ] **Step 1: Write tests/test_attack_system.lua**

```lua
-- tests/test_attack_system.lua
local R   = require("tests/runner")
local Char = require("src/character")
local AS   = require("src/attack_system")

print("\n-- attack_system.lua --")

local ATTACKS = {
  light   = { damage=10, powerGain=5,  powerCost=0,  stunDuration=0,   hitboxW=30, hitboxH=20, hitboxOffX=20, startupTime=0.1, activeTime=0.15, recoveryTime=0.2 },
  heavy   = { damage=25, powerGain=15, powerCost=0,  stunDuration=0.5, hitboxW=40, hitboxH=30, hitboxOffX=25, startupTime=0.25,activeTime=0.2,  recoveryTime=0.4 },
  special = { damage=20, powerGain=0,  powerCost=25, stunDuration=0.2, hitboxW=80, hitboxH=10, hitboxOffX=40, startupTime=0.3, activeTime=0.5,  recoveryTime=0.3 },
  unleash = { damage=40, powerGain=0,  powerCost=100,stunDuration=1,   hitboxW=200,hitboxH=40, hitboxOffX=50, startupTime=0.5, activeTime=1,    recoveryTime=0.5 },
}

local function makeAS(power)
  local c = Char.new({ maxHealth=100, moveSpeed=5 })
  if power then c.power = power end
  return AS.new(c, ATTACKS), c
end

R.test("performLight sets isAttacking", function()
  local a = makeAS()
  a:performLight()
  R.ok(a.isAttacking)
end)

R.test("performSpecial blocked when insufficient power", function()
  local a, c = makeAS(10)   -- needs 25
  a:performSpecial()
  R.notok(a.isAttacking)
  R.eq(c.power, 10)  -- power unchanged
end)

R.test("performSpecial spends power when sufficient", function()
  local a, c = makeAS(50)
  a:performSpecial()
  R.ok(a.isAttacking)
  R.eq(c.power, 25)  -- 50 - 25
end)

R.test("performUnleash blocked when not full", function()
  local a, c = makeAS(99)
  a:performUnleash()
  R.notok(a.isAttacking)
end)

R.test("update advances through startup→active→recovery→idle", function()
  local a = makeAS()
  a:performLight()
  R.ok(a.isAttacking)
  R.eq(a._phase, "startup")

  a:update(0.15)    -- past startupTime(0.1) → enters active, hitbox present
  R.eq(a._phase, "active")
  R.ok(#a:getHitboxes(100, 150, true) > 0)

  a:update(0.2)     -- past activeTime(0.15) → enters recovery, hitboxes cleared
  R.eq(a._phase, "recovery")
  R.eq(#a:getHitboxes(100, 150, true), 0)

  a:update(0.25)    -- past recoveryTime(0.2) → idle
  R.notok(a.isAttacking)
end)
```

- [ ] **Step 2: Run tests to confirm failure**

```bash
lua tests/run_all.lua 2>&1 | grep -E "(attack_system|✗)" | head -10
```

Expected: `module 'src/attack_system' not found`

- [ ] **Step 3: Create src/attack_system.lua**

```lua
-- src/attack_system.lua
local AS = {}
AS.__index = AS

local COMBO_WINDOW       = 1.5   -- seconds
local COMBO_EXTRA_POWER  = 3     -- bonus power at 5-hit combo milestone

function AS.new(character, attacks)
  return setmetatable({
    character   = character,
    attacks     = attacks,   -- table with keys: light, heavy, special, unleash
    isAttacking = false,
    _phase      = nil,       -- "startup" | "active" | "recovery"
    _timer      = 0,
    _activeData = nil,
    _hitboxes   = {},        -- list of {offsetX, w, h, damage, powerGain, stunDuration}
    comboCount  = 0,
    _comboTimer = 0,
  }, AS)
end

function AS:performLight()    self:_startAttack(self.attacks.light) end
function AS:performHeavy()    self:_startAttack(self.attacks.heavy) end

function AS:performSpecial()
  local sp = self.attacks.special
  if self.character.power < sp.powerCost then return end
  self.character:spendPower(sp.powerCost)
  self:_startAttack(sp)
end

function AS:performUnleash()
  if not self.character:isPowerFull() then return end
  self.character:spendPower(100)
  self:_startAttack(self.attacks.unleash)
end

function AS:_startAttack(data)
  if self.isAttacking then return end
  self.isAttacking = true
  self._activeData = data
  self._phase      = "startup"
  self._timer      = data.startupTime
end

function AS:update(dt)
  -- Combo window countdown
  if self._comboTimer > 0 then
    self._comboTimer = self._comboTimer - dt
    if self._comboTimer <= 0 then
      self.comboCount = 0
    end
  end

  if not self.isAttacking then return end

  self._timer = self._timer - dt

  if self._phase == "startup" and self._timer <= 0 then
    local d = self._activeData
    self._hitboxes = {{ offsetX=d.hitboxOffX, w=d.hitboxW, h=d.hitboxH,
                        damage=d.damage, powerGain=d.powerGain, stunDuration=d.stunDuration }}
    self._phase = "active"
    self._timer = d.activeTime

  elseif self._phase == "active" and self._timer <= 0 then
    self._hitboxes = {}
    -- Combo tracking
    self._comboTimer = COMBO_WINDOW
    self.comboCount  = self.comboCount + 1
    if self.comboCount == 5 then
      self.character:gainPower(COMBO_EXTRA_POWER)
    end
    self._phase = "recovery"
    self._timer = self._activeData.recoveryTime

  elseif self._phase == "recovery" and self._timer <= 0 then
    self.isAttacking = false
    self._phase      = nil
    self._activeData = nil
  end
end

-- Returns world-space hitbox rects given character world position and facing.
function AS:getHitboxes(cx, cy, facingRight)
  local result = {}
  local dir    = facingRight and 1 or -1
  for _, hb in ipairs(self._hitboxes) do
    table.insert(result, {
      x            = cx + hb.offsetX * dir - hb.w / 2,
      y            = cy - hb.h / 2,
      w            = hb.w,
      h            = hb.h,
      damage       = hb.damage,
      powerGain    = hb.powerGain,
      stunDuration = hb.stunDuration,
    })
  end
  return result
end

-- AABB overlap check utility
function AS.overlaps(a, b)
  return a.x < b.x + b.w and a.x + a.w > b.x
     and a.y < b.y + b.h and a.y + a.h > b.y
end

return AS
```

- [ ] **Step 4: Run tests**

```bash
lua tests/run_all.lua 2>&1 | head -40
```

Expected: 9 character + 5 attack system tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/attack_system.lua tests/test_attack_system.lua
git commit -m "feat: AttackSystem state machine + hitbox generation + 5 passing tests"
```

---

## Task 4: Controller (Physics + Movement) + Tests

**Files:**
- Create: `src/controller.lua`
- Create: `tests/test_controller.lua`

- [ ] **Step 1: Write tests/test_controller.lua**

```lua
-- tests/test_controller.lua
local R    = require("tests/runner")
local Char = require("src/character")
local Ctrl = require("src/controller")

print("\n-- controller.lua --")

local GROUND_Y = 220  -- must match controller.lua GROUND_Y

local function makeCtrl(x, y)
  local c = Char.new({ maxHealth=100, moveSpeed=80 })
  return Ctrl.new(c, x or 100, y or GROUND_Y), c
end

R.test("moveX applies velocity and moves position", function()
  local ctrl = makeCtrl(100, GROUND_Y)
  ctrl:update(1, 1)   -- 1 second, moving right at moveSpeed=80
  R.approx(ctrl.x, 180)  -- 100 + 80*1
end)

R.test("facingRight flips on negative moveX", function()
  local ctrl = makeCtrl()
  ctrl:update(0.1, -1)
  R.notok(ctrl.facingRight)
end)

R.test("gravity pulls character down when airborne", function()
  local ctrl = makeCtrl(100, 100)   -- y=100, above ground
  ctrl.isGrounded = false
  ctrl:update(0.1, 0)
  R.ok(ctrl.y > 100)
end)

R.test("ground clamp stops at GROUND_Y", function()
  local ctrl = makeCtrl(100, 100)
  ctrl.vy = 9999
  ctrl:update(1, 0)
  R.eq(ctrl.y, GROUND_Y)
  R.ok(ctrl.isGrounded)
end)
```

- [ ] **Step 2: Run tests to confirm failure**

```bash
lua tests/run_all.lua 2>&1 | grep controller | head -5
```

Expected: `module 'src/controller' not found`

- [ ] **Step 3: Create src/controller.lua**

```lua
-- src/controller.lua
local Ctrl    = {}
Ctrl.__index  = Ctrl

local GRAVITY  = 800   -- pixels/sec²
local GROUND_Y = 220   -- y where feet touch ground (in 480×270 reference space)
local JUMP_VY  = -420  -- initial upward velocity on jump

Ctrl.GROUND_Y  = GROUND_Y  -- expose so battle.lua can place characters

function Ctrl.new(character, x, y)
  return setmetatable({
    character   = character,
    x           = x,
    y           = y or GROUND_Y,
    vx          = 0,
    vy          = 0,
    isGrounded  = (y == nil or y >= GROUND_Y),
    isStunned   = false,
    stunTimer   = 0,
    facingRight = true,
    width       = 28,
    height      = 44,
  }, Ctrl)
end

function Ctrl:update(dt, moveX)
  -- Stun countdown
  if self.stunTimer > 0 then
    self.stunTimer = self.stunTimer - dt
    if self.stunTimer <= 0 then
      self.isStunned = false
      self.stunTimer = 0
    end
  end

  if self.isStunned or self.character.isDefeated then
    self.vx = 0
  else
    self.vx = (moveX or 0) * self.character.stats.moveSpeed
    if moveX and moveX ~= 0 then
      self.facingRight = moveX > 0
    end
  end

  -- Gravity
  if not self.isGrounded then
    self.vy = self.vy + GRAVITY * dt
  end

  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt

  -- Ground
  if self.y >= GROUND_Y then
    self.y         = GROUND_Y
    self.vy        = 0
    self.isGrounded = true
  else
    self.isGrounded = false
  end

  -- Horizontal bounds (480 ref width, padding = half width)
  local hw = self.width / 2
  self.x = math.max(hw, math.min(480 - hw, self.x))
end

function Ctrl:jump()
  if self.isGrounded then
    self.vy        = JUMP_VY
    self.isGrounded = false
  end
end

function Ctrl:applyStun(duration)
  self.isStunned = true
  self.stunTimer = math.max(self.stunTimer, duration)
end

-- Returns AABB rect { x, y, w, h } in world space (top-left origin)
function Ctrl:getBounds()
  return { x = self.x - self.width/2, y = self.y - self.height, w = self.width, h = self.height }
end

-- Draw placeholder rectangle (colored rect = character sprite stand-in)
function Ctrl:draw(color)
  local b = self:getBounds()
  love.graphics.setColor(color or {1,1,1})
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  -- eyes to show facing
  local eyeX = self.facingRight and (b.x + b.w * 0.7) or (b.x + b.w * 0.3)
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill", eyeX - 2, b.y + 8, 4, 4)
end

return Ctrl
```

- [ ] **Step 4: Run all tests**

```bash
lua tests/run_all.lua 2>&1 | head -40
```

Expected: 9 + 5 + 4 = 18 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/controller.lua tests/test_controller.lua
git commit -m "feat: Controller physics — gravity, ground clamp, stun, AABB bounds"
```

---

## Task 5: Input Module

**Files:**
- Create: `src/input.lua`

No unit tests — keyboard requires love runtime. Verified visually in battle scene.

- [ ] **Step 1: Create src/input.lua**

```lua
-- src/input.lua
-- P1: A/D move, W jump, Z light, X heavy, C special, V unleash
-- P2: left/right move, up jump, comma light, period heavy, slash special, rshift unleash

local Input = {}

local MAPS = {
  [1] = { left="a",    right="d",     jump="w",
          light="z",   heavy="x",     special="c",    unleash="v" },
  [2] = { left="left", right="right", jump="up",
          light=",",   heavy=".",     special="/",    unleash="rshift" },
}

function Input.getMoveX(player)
  local m = MAPS[player]
  local x = 0
  if love.keyboard.isDown(m.left)  then x = x - 1 end
  if love.keyboard.isDown(m.right) then x = x + 1 end
  return x
end

-- Call in love.keypressed to check one-shot actions (jump, attacks)
function Input.getAction(player, key)
  local m = MAPS[player]
  for action, k in pairs(m) do
    if k == key then return action end
  end
  return nil
end

return Input
```

- [ ] **Step 2: Commit**

```bash
git add src/input.lua
git commit -m "feat: Input module — P1 WASD+ZXCV, P2 arrows+,./ keyboard maps"
```

---

## Task 6: Character Implementations (Godzilla, Kong, Ghidorah)

**Files:**
- Create: `src/characters/godzilla.lua`
- Create: `src/characters/kong.lua`
- Create: `src/characters/ghidorah.lua`

No separate tests — these are data + thin unleash wrappers. Verified in battle scene.

- [ ] **Step 1: Create src/characters/godzilla.lua**

```lua
-- src/characters/godzilla.lua
local Character = require("src/character")
local AS        = require("src/attack_system")

local STATS = {
  characterName = "Godzilla",
  maxHealth     = 120,
  moveSpeed     = 70,
  color         = { 0.2, 0.6, 0.3 },  -- dark green
}

local ATTACKS = {
  light   = { damage=12, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=30, hitboxH=22, hitboxOffX=20, startupTime=0.1, activeTime=0.15, recoveryTime=0.2 },
  heavy   = { damage=30, powerGain=15, powerCost=0,  stunDuration=0.5,
              hitboxW=40, hitboxH=28, hitboxOffX=26, startupTime=0.25,activeTime=0.2,  recoveryTime=0.4 },
  special = { damage=20, powerGain=0,  powerCost=25, stunDuration=0.2,
              hitboxW=90, hitboxH=12, hitboxOffX=45, startupTime=0.3, activeTime=0.5,  recoveryTime=0.3 },
  unleash = { damage=45, powerGain=0,  powerCost=100,stunDuration=1.5,
              hitboxW=220,hitboxH=50, hitboxOffX=60, startupTime=0.5, activeTime=1,    recoveryTime=0.6 },
}

local Godzilla = {}
Godzilla.__index = Godzilla

function Godzilla.new()
  local self    = setmetatable({}, Godzilla)
  self.stats    = STATS
  self.character = Character.new(STATS)
  self.attacks  = AS.new(self.character, ATTACKS)
  -- Flash timer for unleash visual (set to duration when unleash fires)
  self._flashTimer = 0
  self.character.onPowerFull = function()
    -- HUD will listen separately; nothing needed here
  end
  return self
end

function Godzilla:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._flashTimer = 1.0
  self.attacks:performUnleash()
end

function Godzilla:update(dt)
  self.attacks:update(dt, 0, true)
  if self._flashTimer > 0 then self._flashTimer = self._flashTimer - dt end
end

function Godzilla:drawExtra(ctrl)
  -- Nuclear pulse ring when unleash active
  if self._flashTimer > 0 then
    local alpha = self._flashTimer / 1.0
    love.graphics.setColor(0, 1, 0.3, alpha * 0.6)
    love.graphics.circle("line", ctrl.x, ctrl.y - ctrl.height/2, 40 * (1 - alpha) + 10)
  end
end

return Godzilla
```

- [ ] **Step 2: Create src/characters/kong.lua**

```lua
-- src/characters/kong.lua
local Character = require("src/character")
local AS        = require("src/attack_system")

local STATS = {
  characterName = "Kong",
  maxHealth     = 110,
  moveSpeed     = 85,
  color         = { 0.55, 0.38, 0.22 },  -- brown
}

local ATTACKS = {
  light   = { damage=14, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=34, hitboxH=24, hitboxOffX=22, startupTime=0.08,activeTime=0.12, recoveryTime=0.18 },
  heavy   = { damage=28, powerGain=15, powerCost=0,  stunDuration=0.5,
              hitboxW=42, hitboxH=32, hitboxOffX=24, startupTime=0.22,activeTime=0.18, recoveryTime=0.35 },
  special = { damage=22, powerGain=0,  powerCost=25, stunDuration=0.3,
              hitboxW=50, hitboxH=50, hitboxOffX=30, startupTime=0.2, activeTime=0.4,  recoveryTime=0.3 },
  unleash = { damage=42, powerGain=0,  powerCost=100,stunDuration=1,
              hitboxW=180,hitboxH=60, hitboxOffX=55, startupTime=0.4, activeTime=0.8,  recoveryTime=0.5 },
}

local Kong = {}
Kong.__index = Kong

function Kong.new()
  local self    = setmetatable({}, Kong)
  self.stats    = STATS
  self.character = Character.new(STATS)
  self.attacks  = AS.new(self.character, ATTACKS)
  self._rageTimer = 0
  return self
end

function Kong:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._rageTimer = 0.8
  self.attacks:performUnleash()
end

function Kong:update(dt)
  self.attacks:update(dt, 0, true)
  if self._rageTimer > 0 then self._rageTimer = self._rageTimer - dt end
end

function Kong:drawExtra(ctrl)
  if self._rageTimer > 0 then
    local alpha = self._rageTimer / 0.8
    love.graphics.setColor(1, 0.4, 0, alpha * 0.5)
    love.graphics.rectangle("fill", ctrl.x - 30, ctrl.y - ctrl.height - 10, 60, 10)
  end
end

return Kong
```

- [ ] **Step 3: Create src/characters/ghidorah.lua**

```lua
-- src/characters/ghidorah.lua
local Character = require("src/character")
local AS        = require("src/attack_system")

local STATS = {
  characterName = "Ghidorah",
  maxHealth     = 130,
  moveSpeed     = 60,
  color         = { 0.85, 0.75, 0.1 },  -- gold
}

local ATTACKS = {
  light   = { damage=10, powerGain=5,  powerCost=0,  stunDuration=0,
              hitboxW=28, hitboxH=18, hitboxOffX=18, startupTime=0.12,activeTime=0.18, recoveryTime=0.22 },
  heavy   = { damage=32, powerGain=15, powerCost=0,  stunDuration=0.6,
              hitboxW=44, hitboxH=30, hitboxOffX=28, startupTime=0.28,activeTime=0.22, recoveryTime=0.45 },
  special = { damage=18, powerGain=0,  powerCost=25, stunDuration=0.2,
              hitboxW=100,hitboxH=10, hitboxOffX=50, startupTime=0.35,activeTime=0.6,  recoveryTime=0.35 },
  unleash = { damage=50, powerGain=0,  powerCost=100,stunDuration=2,
              hitboxW=250,hitboxH=45, hitboxOffX=70, startupTime=0.6, activeTime=1.2,  recoveryTime=0.7 },
}

local Ghidorah = {}
Ghidorah.__index = Ghidorah

function Ghidorah.new()
  local self     = setmetatable({}, Ghidorah)
  self.stats     = STATS
  self.character = Character.new(STATS)
  self.attacks   = AS.new(self.character, ATTACKS)
  self._beamTimer = 0
  return self
end

function Ghidorah:triggerUnleash()
  if not self.character:isPowerFull() then return end
  self._beamTimer = 1.2
  self.attacks:performUnleash()
end

function Ghidorah:update(dt)
  self.attacks:update(dt, 0, true)
  if self._beamTimer > 0 then self._beamTimer = self._beamTimer - dt end
end

function Ghidorah:drawExtra(ctrl)
  if self._beamTimer > 0 then
    local alpha = self._beamTimer / 1.2
    -- Three lightning beams
    love.graphics.setColor(0.9, 0.9, 0.2, alpha * 0.8)
    local bx = ctrl.facingRight and ctrl.x or ctrl.x - 200
    for i = 0, 2 do
      love.graphics.rectangle("fill", bx + i * 5, ctrl.y - ctrl.height - 2, 2, 200)
    end
  end
end

return Ghidorah
```

- [ ] **Step 4: Commit**

```bash
git add src/characters/
git commit -m "feat: Godzilla, Kong, Ghidorah — stats, attack data, unleash visual effects"
```

---

## Task 7: NPC System + Object Pool + Tests

**Files:**
- Create: `src/npc.lua`
- Create: `src/blood_pool.lua`
- Create: `src/npc_spawner.lua`
- Create: `tests/test_npc_spawner.lua`

- [ ] **Step 1: Write tests/test_npc_spawner.lua**

```lua
-- tests/test_npc_spawner.lua
local R       = require("tests/runner")
local Spawner = require("src/npc_spawner")

print("\n-- npc_spawner.lua --")

R.test("registerSplat accumulates dollars", function()
  local s = Spawner.new()
  s:registerSplat("Human", 1000)
  s:registerSplat("Police", 2000)
  R.eq(s:getDestructionScore(), 3000)
end)

R.test("registerSplat counts total splats", function()
  local s = Spawner.new()
  s:registerSplat("Human", 500)
  s:registerSplat("Human", 500)
  R.eq(s:getSplatCount(), 2)
end)

R.test("streak fires when 5 splats within window", function()
  local s = Spawner.new()
  local streakFired = 0
  s.onSplatStreak = function() streakFired = streakFired + 1 end
  for i = 1, 5 do
    s:registerSplat("Human", 100)
    -- Don't advance time so timer stays active
  end
  R.eq(streakFired, 1)
end)
```

- [ ] **Step 2: Run tests to confirm failure**

```bash
lua tests/run_all.lua 2>&1 | grep "npc_spawner" | head -5
```

Expected: `module 'src/npc_spawner' not found`

- [ ] **Step 3: Create src/npc.lua**

```lua
-- src/npc.lua
local NPC   = {}
NPC.__index = NPC

function NPC.new(x, y, npcType, dollarsValue)
  return setmetatable({
    x            = x,
    y            = y,
    npcType      = npcType or "Human",
    dollarsValue = dollarsValue or 1000,
    isDead       = false,
    vx           = (math.random() > 0.5) and 25 or -25,
    wanderTimer  = math.random() * 2 + 1,
    width        = 8,
    height       = 12,
  }, NPC)
end

function NPC:update(dt)
  if self.isDead then return end
  self.wanderTimer = self.wanderTimer - dt
  if self.wanderTimer <= 0 then
    self.vx = -self.vx
    self.wanderTimer = math.random() * 2 + 1
  end
  self.x = math.max(4, math.min(476, self.x + self.vx * dt))
end

function NPC:stomp(bloodPool, spawner)
  if self.isDead then return end
  self.isDead = true
  if bloodPool then bloodPool:spawn(self.x, self.y) end
  if spawner   then spawner:registerSplat(self.npcType, self.dollarsValue) end
end

function NPC:getBounds()
  return { x=self.x - self.width/2, y=self.y - self.height, w=self.width, h=self.height }
end

function NPC:draw()
  if self.isDead then return end
  love.graphics.setColor(1, 0.85, 0.7)
  love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height, self.width, self.height)
  -- tiny head dot
  love.graphics.setColor(1, 0.7, 0.5)
  love.graphics.circle("fill", self.x, self.y - self.height - 3, 3)
end

return NPC
```

- [ ] **Step 4: Create src/blood_pool.lua**

```lua
-- src/blood_pool.lua
-- Object pool of blood splat particles (colored rectangles, no love.graphics.ParticleSystem needed)
local Pool   = {}
Pool.__index = Pool

local POOL_SIZE = 30

local Particle = {}
Particle.__index = Particle

function Particle.new()
  return setmetatable({ active=false, x=0, y=0, timer=0, vx=0, vy=0, size=4 }, Particle)
end

function Pool.new()
  local self = setmetatable({ _particles={} }, Pool)
  for i = 1, POOL_SIZE do
    table.insert(self._particles, Particle.new())
  end
  return self
end

function Pool:spawn(x, y)
  -- Spawn 5 particles per stomp
  local count = 0
  for _, p in ipairs(self._particles) do
    if not p.active then
      p.active = true
      p.x      = x + math.random(-4, 4)
      p.y      = y + math.random(-4, 4)
      p.vx     = math.random(-60, 60)
      p.vy     = math.random(-80, -20)
      p.timer  = 0.4 + math.random() * 0.3
      p.size   = math.random(2, 5)
      count    = count + 1
      if count >= 5 then break end
    end
  end
end

function Pool:update(dt)
  for _, p in ipairs(self._particles) do
    if p.active then
      p.timer = p.timer - dt
      if p.timer <= 0 then
        p.active = false
      else
        p.vy = p.vy + 300 * dt   -- gravity on particles
        p.x  = p.x + p.vx * dt
        p.y  = p.y + p.vy * dt
      end
    end
  end
end

function Pool:draw()
  love.graphics.setColor(0.8, 0.05, 0.05)
  for _, p in ipairs(self._particles) do
    if p.active then
      love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end
  end
end

return Pool
```

- [ ] **Step 5: Create src/npc_spawner.lua**

```lua
-- src/npc_spawner.lua
local NPC    = require("src/npc")
local Spawner = {}
Spawner.__index = Spawner

local STREAK_WINDOW    = 2.0   -- seconds
local STREAK_THRESHOLD = 5     -- splats within window to trigger streak

function Spawner.new()
  return setmetatable({
    npcs               = {},
    _totalDollars      = 0,
    _splatCount        = 0,
    _recentSplatCount  = 0,
    _recentSplatTimer  = 0,
    onDestructionScoreChanged = nil,
    onSplatStreak             = nil,
  }, Spawner)
end

function Spawner:spawnBatch(count, areaWidth, groundY)
  for i = 1, count do
    local x = math.random(20, areaWidth - 20)
    table.insert(self.npcs, NPC.new(x, groundY, "Human", 1000))
  end
end

function Spawner:update(dt)
  self._recentSplatTimer = self._recentSplatTimer - dt
  if self._recentSplatTimer <= 0 then
    self._recentSplatCount = 0
  end
  for _, npc in ipairs(self.npcs) do
    npc:update(dt)
  end
end

function Spawner:registerSplat(npcType, dollars)
  self._totalDollars    = self._totalDollars + dollars
  self._splatCount      = self._splatCount + 1
  self._recentSplatCount = self._recentSplatCount + 1
  self._recentSplatTimer = STREAK_WINDOW
  if self.onDestructionScoreChanged then
    self.onDestructionScoreChanged(self._totalDollars)
  end
  if self._recentSplatCount >= STREAK_THRESHOLD then
    self._recentSplatCount = 0
    if self.onSplatStreak then self.onSplatStreak() end
  end
end

function Spawner:getDestructionScore() return self._totalDollars end
function Spawner:getSplatCount()       return self._splatCount end

function Spawner:draw()
  for _, npc in ipairs(self.npcs) do npc:draw() end
end

return Spawner
```

- [ ] **Step 6: Run all tests**

```bash
lua tests/run_all.lua 2>&1 | head -50
```

Expected: 18 + 3 = 21 tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/npc.lua src/blood_pool.lua src/npc_spawner.lua tests/test_npc_spawner.lua
git commit -m "feat: NPC wander + blood splat pool + spawner streak detection + 3 tests"
```

---

## Task 8: HUD

**Files:**
- Create: `src/hud.lua`

No unit tests (requires love.graphics). Verified visually in battle.

- [ ] **Step 1: Create src/hud.lua**

```lua
-- src/hud.lua
local HUD   = {}
HUD.__index = HUD

-- Layout constants (in 480×270 reference space)
local BAR_H    = 8
local BAR_W    = 160
local P1_BAR_X = 10
local P2_BAR_X = 480 - 10 - BAR_W
local BARS_Y   = 10
local PWR_Y    = BARS_Y + BAR_H + 3

function HUD.new(p1char, p2char, spawner)
  local self = setmetatable({
    p1      = p1char,
    p2      = p2char,
    spawner = spawner,
    timerSeconds = 99,
    _comboText = nil,
    _comboTimer = 0,
  }, HUD)

  -- Wire events
  if spawner then
    spawner.onSplatStreak = function()
      self._comboText  = "SQUISH x5 — GAWDZILLLLA APPROVES"
      self._comboTimer = 2.5
    end
  end

  return self
end

function HUD:update(dt, timeRemaining)
  self.timerSeconds = timeRemaining
  if self._comboTimer > 0 then
    self._comboTimer = self._comboTimer - dt
  end
end

function HUD:draw()
  -- P1 Health bar
  self:_drawBar(P1_BAR_X, BARS_Y, BAR_W, BAR_H, self.p1:healthPercent(), {0.15,0.75,0.2}, {0.5,0.15,0.1})
  -- P1 Power bar
  self:_drawBar(P1_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p1:powerPercent(), {0.2,0.4,1}, {0.1,0.1,0.3})

  -- P2 Health bar (right-aligned, fills left)
  self:_drawBarRTL(P2_BAR_X, BARS_Y, BAR_W, BAR_H, self.p2:healthPercent(), {0.75,0.2,0.15}, {0.5,0.15,0.1})
  -- P2 Power bar
  self:_drawBarRTL(P2_BAR_X, PWR_Y, BAR_W, BAR_H - 2, self.p2:powerPercent(), {0.2,0.4,1}, {0.1,0.1,0.3})

  -- Character names
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(self.p1.stats.characterName, P1_BAR_X, BARS_Y + BAR_H * 2 + 4)
  local name2 = self.p2.stats.characterName
  love.graphics.print(name2, P2_BAR_X + BAR_W - #name2 * 6, BARS_Y + BAR_H * 2 + 4)

  -- Timer
  local tStr = tostring(math.max(0, math.ceil(self.timerSeconds)))
  love.graphics.setColor(1, 0.9, 0.2)
  love.graphics.printf(tStr, 0, 8, 480, "center")

  -- Destruction score
  if self.spawner then
    local dollars = self.spawner:getDestructionScore()
    if dollars > 0 then
      love.graphics.setColor(0.9, 0.9, 0.5)
      love.graphics.printf(string.format("$%.1fM", dollars / 1e6), 0, 255, 480, "center")
    end
  end

  -- Power-full flash indicator
  if self.p1:isPowerFull() then
    love.graphics.setColor(1, 0, 0, 0.7 + 0.3 * math.sin(love.timer.getTime() * 8))
    love.graphics.printf("UNLEASH!", P1_BAR_X, PWR_Y + 10, BAR_W, "left")
  end
  if self.p2:isPowerFull() then
    love.graphics.setColor(1, 0, 0, 0.7 + 0.3 * math.sin(love.timer.getTime() * 8))
    love.graphics.printf("UNLEASH!", P2_BAR_X, PWR_Y + 10, BAR_W, "right")
  end

  -- Combo text
  if self._comboTimer > 0 then
    local alpha = math.min(1, self._comboTimer)
    love.graphics.setColor(1, 0.8, 0.1, alpha)
    love.graphics.printf(self._comboText or "", 0, 120, 480, "center")
  end
end

function HUD:_drawBar(x, y, w, h, percent, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.2,0.2,0.2})
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(fillColor or {0.3,0.8,0.3})
  love.graphics.rectangle("fill", x, y, w * math.max(0, percent), h)
  love.graphics.setColor(1,1,1,0.3)
  love.graphics.rectangle("line", x, y, w, h)
end

function HUD:_drawBarRTL(x, y, w, h, percent, fillColor, bgColor)
  love.graphics.setColor(bgColor or {0.2,0.2,0.2})
  love.graphics.rectangle("fill", x, y, w, h)
  local fillW = w * math.max(0, percent)
  love.graphics.setColor(fillColor or {0.3,0.8,0.3})
  love.graphics.rectangle("fill", x + w - fillW, y, fillW, h)
  love.graphics.setColor(1,1,1,0.3)
  love.graphics.rectangle("line", x, y, w, h)
end

return HUD
```

- [ ] **Step 2: Commit**

```bash
git add src/hud.lua
git commit -m "feat: HUD — health bars, power meters, timer, destruction score, combo text"
```

---

## Task 9: Fight Manager + Tests

**Files:**
- Create: `src/fight_manager.lua`
- Create: `tests/test_fight_manager.lua`

- [ ] **Step 1: Write tests/test_fight_manager.lua**

```lua
-- tests/test_fight_manager.lua
local R    = require("tests/runner")
local Char = require("src/character")
local FM   = require("src/fight_manager")

print("\n-- fight_manager.lua --")

local function makeChars()
  local c1 = Char.new({ maxHealth=100, moveSpeed=5 })
  local c2 = Char.new({ maxHealth=100, moveSpeed=5 })
  return c1, c2
end

R.test("startMatch resets round counts", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  fm:startMatch()
  R.eq(fm.p1RoundsWon, 0)
  R.eq(fm.p2RoundsWon, 0)
  R.eq(fm.currentRound, 1)
  R.ok(fm.roundActive)
end)

R.test("P2 wins round when P1 defeated", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  local winner = nil
  fm.onRoundEnd = function(w) winner = w end
  fm:startMatch()
  c1:takeDamage(999)
  fm:update(0)   -- one frame to detect defeat
  R.eq(winner, 2)
  R.eq(fm.p2RoundsWon, 1)
end)

R.test("time out winner is player with more health", function()
  local c1, c2 = makeChars()
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=1 })
  local winner = nil
  fm.onRoundEnd = function(w) winner = w end
  fm:startMatch()
  c2:takeDamage(50)      -- P2 lower health
  fm:update(2)           -- past roundDuration=1
  R.eq(winner, 1)        -- P1 wins by health
end)

R.test("match ends when player wins majority", function()
  local c1, c2 = makeChars()
  -- totalRounds=3, need 2 wins (ceil(3/2)) to win match
  local fm = FM.new(c1, c2, { totalRounds=3, roundDuration=99 })
  local matchWinner = nil
  fm.onMatchEnd = function(w) matchWinner = w end
  fm:startMatch()

  -- P1 wins round 1
  c2:takeDamage(999); fm:update(0)
  fm:_forceStartNextRound()  -- skip 2s delay for test

  -- P1 wins round 2
  c2:takeDamage(999); fm:update(0)

  R.eq(matchWinner, 1)
end)
```

- [ ] **Step 2: Run tests to confirm failure**

```bash
lua tests/run_all.lua 2>&1 | grep "fight_manager" | head -5
```

Expected: `module 'src/fight_manager' not found`

- [ ] **Step 3: Create src/fight_manager.lua**

```lua
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
```

- [ ] **Step 4: Run all tests**

```bash
lua tests/run_all.lua
```

Expected: 9 + 5 + 4 + 3 + 4 = 25 tests, all pass. Output ends with `25 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add src/fight_manager.lua tests/test_fight_manager.lua
git commit -m "feat: FightManager round/match system + 4 tests — 25 total passing"
```

---

## Task 10: Audio Manager

**Files:**
- Create: `src/audio_manager.lua`

No unit tests — audio requires runtime.

- [ ] **Step 1: Create src/audio_manager.lua**

```lua
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
```

- [ ] **Step 2: Create assets/audio/ placeholder directory**

```bash
mkdir -p assets/audio
```

- [ ] **Step 3: Commit**

```bash
git add src/audio_manager.lua assets/audio/.gitkeep
git commit -m "feat: AudioManager singleton with random no-repeat splat + graceful missing-file handling"
```

---

## Task 11: Scenes (Main Menu, Character Select, Battle)

**Files:**
- Modify: `src/scenes/main_menu.lua` (replace placeholder with full implementation)
- Create: `src/scenes/character_select.lua`
- Create: `src/scenes/battle.lua`

- [ ] **Step 1: Replace src/scenes/main_menu.lua with full implementation**

```lua
-- src/scenes/main_menu.lua
local SM   = require("src/scene_manager")

local Menu = {}
Menu.__index = Menu

function Menu.new()
  return setmetatable({
    _buttons = {
      { label="PLAY",  y=130, action="play"  },
      { label="QUIT",  y=158, action="quit"  },
    },
    _selected = 1,
  }, Menu)
end

function Menu:update(dt) end

function Menu:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- Title
  love.graphics.setColor(0.9, 0.7, 0.1)
  love.graphics.printf("GAWDZILLLLA", 0, 70, 480, "center")

  love.graphics.setColor(0.5, 0.5, 0.7)
  love.graphics.printf("The Most Important Kaiju Game", 0, 95, 480, "center")

  -- Buttons
  for i, btn in ipairs(self._buttons) do
    if i == self._selected then
      love.graphics.setColor(1, 0.8, 0.1)
    else
      love.graphics.setColor(0.6, 0.6, 0.6)
    end
    love.graphics.printf(btn.label, 0, btn.y, 480, "center")
  end

  love.graphics.setColor(0.3, 0.3, 0.4)
  love.graphics.printf("UP/DOWN to select  ENTER to confirm", 0, 250, 480, "center")
end

function Menu:keypressed(key)
  if key == "up"    then self._selected = math.max(1, self._selected - 1) end
  if key == "down"  then self._selected = math.min(#self._buttons, self._selected + 1) end
  if key == "return" or key == "space" then
    local action = self._buttons[self._selected].action
    if action == "play" then
      local CS = require("src/scenes/character_select")
      SM.replace(CS.new())
    elseif action == "quit" then
      love.event.quit()
    end
  end
end

return Menu
```

- [ ] **Step 2: Create src/scenes/character_select.lua**

```lua
-- src/scenes/character_select.lua
local SM = require("src/scene_manager")

local CS = {}
CS.__index = CS

local CHARS = {
  { name="Godzilla", module="src/characters/godzilla", color={0.2,0.6,0.3}, desc="HP 120 | SPD 70 | Heavy hitter" },
  { name="Kong",     module="src/characters/kong",     color={0.55,0.38,0.22}, desc="HP 110 | SPD 85 | Fast striker" },
  { name="Ghidorah", module="src/characters/ghidorah", color={0.85,0.75,0.1}, desc="HP 130 | SPD 60 | Tanky blaster" },
}

function CS.new()
  return setmetatable({
    _p1Idx     = 1,
    _p2Idx     = 2,
    _selectingP2 = false,
    _cursor    = 1,
  }, CS)
end

function CS:update(dt) end

function CS:draw()
  love.graphics.setColor(0.05, 0.06, 0.12)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  love.graphics.setColor(1, 0.8, 0)
  love.graphics.printf(self._selectingP2 and "P2 SELECT" or "P1 SELECT", 0, 15, 480, "center")

  -- Character cards
  for i, c in ipairs(CHARS) do
    local x = 30 + (i-1) * 145
    local y = 50
    local w, h = 130, 150

    -- Card background
    local highlight = (i == self._cursor)
    love.graphics.setColor(highlight and {0.15,0.15,0.25} or {0.08,0.08,0.14})
    love.graphics.rectangle("fill", x, y, w, h, 6)
    if highlight then
      love.graphics.setColor(0.9, 0.8, 0.2)
      love.graphics.rectangle("line", x, y, w, h, 6)
    end

    -- Character color swatch
    love.graphics.setColor(c.color)
    love.graphics.rectangle("fill", x + 20, y + 15, 90, 70, 4)

    -- Eyes
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", x + 50, y + 42, 6)
    love.graphics.circle("fill", x + 80, y + 42, 6)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", x + 53, y + 40, 2)
    love.graphics.circle("fill", x + 83, y + 40, 2)

    -- Name
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(c.name, x, y + 92, w, "center")

    -- Desc
    love.graphics.setColor(0.6, 0.6, 0.8)
    love.graphics.printf(c.desc, x + 4, y + 108, w - 8, "center")

    -- P1/P2 badges
    if i == self._p1Idx then
      love.graphics.setColor(0.2, 0.7, 1)
      love.graphics.printf("P1", x, y + 132, w, "center")
    end
    if i == self._p2Idx then
      love.graphics.setColor(1, 0.4, 0.4)
      love.graphics.printf("P2", x, i == self._p1Idx and y + 142 or y + 132, w, "center")
    end
  end

  -- Controls hint
  love.graphics.setColor(0.5, 0.5, 0.6)
  love.graphics.printf("LEFT/RIGHT select  ENTER confirm  ESC back", 0, 248, 480, "center")
end

function CS:keypressed(key)
  if key == "left"  then self._cursor = math.max(1, self._cursor - 1) end
  if key == "right" then self._cursor = math.min(#CHARS, self._cursor + 1) end
  if key == "escape" then
    local MM = require("src/scenes/main_menu")
    SM.replace(MM.new())
  end
  if key == "return" or key == "space" then
    if not self._selectingP2 then
      self._p1Idx      = self._cursor
      self._selectingP2 = true
    else
      self._p2Idx = self._cursor
      -- Launch battle
      local Battle = require("src/scenes/battle")
      SM.replace(Battle.new(CHARS[self._p1Idx], CHARS[self._p2Idx]))
    end
  end
end

return CS
```

- [ ] **Step 3: Create src/scenes/battle.lua**

```lua
-- src/scenes/battle.lua
local SM       = require("src/scene_manager")
local Ctrl     = require("src/controller")
local Input    = require("src/input")
local HUD      = require("src/hud")
local FM       = require("src/fight_manager")
local Spawner  = require("src/npc_spawner")
local Pool     = require("src/blood_pool")
local AS       = require("src/attack_system")
local AM       = require("src/audio_manager")

local Battle   = {}
Battle.__index = Battle

local GROUND_Y = Ctrl.GROUND_Y   -- 220

function Battle.new(p1Info, p2Info)
  local self  = setmetatable({}, Battle)

  -- Build characters
  local P1Mod = require(p1Info.module)
  local P2Mod = require(p2Info.module)
  self._p1  = P1Mod.new()
  self._p2  = P2Mod.new()

  -- Controllers (position, physics)
  self._ctrl1 = Ctrl.new(self._p1.character, 120, GROUND_Y)
  self._ctrl2 = Ctrl.new(self._p2.character, 360, GROUND_Y)
  self._ctrl2.facingRight = false

  -- NPC system
  self._spawner = Spawner.new()
  self._spawner:spawnBatch(60, 480, GROUND_Y)
  self._pool    = Pool.new()

  -- HUD
  self._hud = HUD.new(self._p1.character, self._p2.character, self._spawner)

  -- Fight manager
  self._fm = FM.new(self._p1.character, self._p2.character, { totalRounds=3, roundDuration=99 })
  self._matchOver = false
  self._resultText = nil
  self._resultTimer = 0

  self._fm.onRoundStart = function(r)
    self._announceText  = "ROUND " .. r .. " — FIGHT!"
    self._announceTimer = 1.5
  end

  self._fm.onRoundEnd = function(winner)
    local name = winner == 1 and self._p1.stats.characterName or self._p2.stats.characterName
    self._announceText  = name .. " WINS ROUND!"
    self._announceTimer = 1.8
  end

  self._fm.onMatchEnd = function(winner)
    local name = winner == 1 and self._p1.stats.characterName or self._p2.stats.characterName
    self._resultText  = name .. " WINS!\nDestruction: $" ..
                         string.format("%.1f", self._spawner:getDestructionScore() / 1e6) .. "M"
    self._matchOver   = true
    self._resultTimer = 4.0
  end

  self._announceText  = nil
  self._announceTimer = 0

  -- Audio
  self._audio = AM.getInstance()
  self._audio:playMusic()

  self._fm:startMatch()
  return self
end

function Battle:update(dt)
  if self._matchOver then
    self._resultTimer = self._resultTimer - dt
    if self._resultTimer <= 0 then
      local MM = require("src/scenes/main_menu")
      SM.replace(MM.new())
    end
    return
  end

  -- Input → controllers
  local mx1 = Input.getMoveX(1)
  local mx2 = Input.getMoveX(2)
  self._ctrl1:update(dt, mx1)
  self._ctrl2:update(dt, mx2)

  -- Update character-specific logic (unleash timers etc.)
  self._p1:update(dt)
  self._p2:update(dt)

  -- Sync attack systems (need facing for hitbox direction)
  self._p1.attacks:update(dt, self._ctrl1.x, self._ctrl1.facingRight)
  self._p2.attacks:update(dt, self._ctrl2.x, self._ctrl2.facingRight)

  -- Hit detection: P1 attacks hitting P2 and vice-versa
  self:_checkHits(self._p1.attacks, self._ctrl1, self._p2.character, self._ctrl2)
  self:_checkHits(self._p2.attacks, self._ctrl2, self._p1.character, self._ctrl1)

  -- NPC stomp: characters walking over NPCs
  self:_checkStomps(self._ctrl1)
  self:_checkStomps(self._ctrl2)

  -- Update systems
  self._spawner:update(dt)
  self._pool:update(dt)
  self._fm:update(dt)
  self._hud:update(dt, self._fm.timeRemaining)

  -- Announce timer
  if self._announceTimer > 0 then
    self._announceTimer = self._announceTimer - dt
  end
end

function Battle:_checkHits(attackSystem, attackerCtrl, targetChar, targetCtrl)
  if targetChar.isDefeated then return end
  local boxes = attackSystem:getHitboxes(attackerCtrl.x, attackerCtrl.y, attackerCtrl.facingRight)
  local tb    = targetCtrl:getBounds()
  for _, hb in ipairs(boxes) do
    if AS.overlaps(hb, tb) then
      targetChar:takeDamage(hb.damage)
      attackSystem.character:gainPower(hb.powerGain)
      if hb.stunDuration and hb.stunDuration > 0 then
        targetCtrl:applyStun(hb.stunDuration)
      end
      self._audio:playRandomSplat()
    end
  end
end

function Battle:_checkStomps(ctrl)
  local cb = ctrl:getBounds()
  -- Stomp box = bottom 8px of character
  local stomper = { x=cb.x, y=cb.y + cb.h - 8, w=cb.w, h=8 }
  for _, npc in ipairs(self._spawner.npcs) do
    if not npc.isDead then
      local nb = npc:getBounds()
      if AS.overlaps(stomper, nb) then
        npc:stomp(self._pool, self._spawner)
        self._audio:playRandomSplat()
      end
    end
  end
end

function Battle:keypressed(key)
  -- P1 one-shot actions
  local a1 = Input.getAction(1, key)
  if a1 == "jump"    then self._ctrl1:jump() end
  if a1 == "light"   then self._p1.attacks:performLight() end
  if a1 == "heavy"   then self._p1.attacks:performHeavy() end
  if a1 == "special" then self._p1.attacks:performSpecial() end
  if a1 == "unleash" then self._p1:triggerUnleash() end

  -- P2 one-shot actions
  local a2 = Input.getAction(2, key)
  if a2 == "jump"    then self._ctrl2:jump() end
  if a2 == "light"   then self._p2.attacks:performLight() end
  if a2 == "heavy"   then self._p2.attacks:performHeavy() end
  if a2 == "special" then self._p2.attacks:performSpecial() end
  if a2 == "unleash" then self._p2:triggerUnleash() end
end

function Battle:draw()
  -- Sky
  love.graphics.setColor(0.08, 0.1, 0.2)
  love.graphics.rectangle("fill", 0, 0, 480, 270)

  -- City silhouette (placeholder buildings)
  love.graphics.setColor(0.12, 0.12, 0.2)
  local buildings = { {40,180,30,80},{90,160,50,100},{160,150,40,110},{220,170,60,90},
                      {300,155,35,105},{350,165,50,95},{410,145,40,115},{450,175,25,85} }
  for _, b in ipairs(buildings) do
    love.graphics.rectangle("fill", b[1], b[2], b[3], b[4])
    -- Windows
    love.graphics.setColor(0.9, 0.85, 0.4, 0.4)
    for wy = b[2]+6, b[2]+b[4]-10, 10 do
      for wx = b[1]+4, b[1]+b[3]-8, 7 do
        love.graphics.rectangle("fill", wx, wy, 4, 5)
      end
    end
    love.graphics.setColor(0.12, 0.12, 0.2)
  end

  -- Ground
  love.graphics.setColor(0.22, 0.2, 0.18)
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 270 - GROUND_Y)
  love.graphics.setColor(0.35, 0.3, 0.28)
  love.graphics.rectangle("fill", 0, GROUND_Y, 480, 2)

  -- NPCs
  self._spawner:draw()

  -- Blood pool
  self._pool:draw()

  -- Characters
  self._p1.attacks:getHitboxes(self._ctrl1.x, self._ctrl1.y, self._ctrl1.facingRight)  -- (no-op draw)
  self._ctrl1:draw(self._p1.stats.color)
  self._p1:drawExtra(self._ctrl1)

  self._ctrl2:draw(self._p2.stats.color)
  self._p2:drawExtra(self._ctrl2)

  -- HUD
  self._hud:draw()

  -- Round announcement
  if self._announceTimer > 0 then
    local alpha = math.min(1, self._announceTimer * 1.5)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(self._announceText or "", 0, 120, 480, "center")
  end

  -- Match result
  if self._matchOver and self._resultText then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 80, 90, 320, 90, 8)
    love.graphics.setColor(1, 0.85, 0.1)
    love.graphics.printf(self._resultText, 80, 108, 320, "center")
  end
end

return Battle
```

- [ ] **Step 4: Verify full game flow works**

```bash
love .
```

Expected:
- Main menu opens with GAWDZILLLLA title
- UP/DOWN selects PLAY/QUIT
- ENTER → Character Select: 3 cards, LEFT/RIGHT cursor, ENTER picks P1 then P2
- ENTER again → Battle scene: dark city background, 2 colored blocks (characters), 60 tiny humanoids wandering
- P1: A/D move, W jump, Z light attack, X heavy, C special, V unleash
- P2: arrows move, UP jump, comma/period/slash attack, RSHIFT unleash
- Health bars decrease when characters hit each other
- Humanoids splat red pixels when walked over
- Round timer counts down from 99
- Round ends on KO or timeout, match ends after 2 round wins
- Results panel shows winner + destruction dollars
- Auto-returns to main menu after 4s

- [ ] **Step 5: Commit**

```bash
git add src/scenes/main_menu.lua src/scenes/character_select.lua src/scenes/battle.lua
git commit -m "feat: full scene flow — main menu → character select → battle with complete game loop"
```

---

## Spec Coverage Check

| Requirement | Task |
|-------------|------|
| Health + power meter | Task 2 (character.lua) |
| Light/heavy/special/unleash attacks | Task 3 (attack_system.lua) |
| Counter state (2× damage) | Task 2 |
| 3 starter characters with unique stats | Task 6 |
| Unleash visual effect | Task 6 (drawExtra) |
| GAWDZILLLLA shout on unleash | Audio hook in audio_manager (sound file needed) |
| NPC wandering humanoids | Task 7 (npc.lua) |
| Blood splat object pool | Task 7 (blood_pool.lua) |
| Splat streak detection | Task 7 (npc_spawner.lua) |
| VS mode, 3 rounds, KO/timeout | Task 9 (fight_manager.lua) |
| Health bars + power meter UI | Task 8 (hud.lua) |
| Round timer | Task 8 + Task 9 |
| Destruction score | Task 7 + Task 8 |
| Keyboard controls P1 + P2 | Task 5 (input.lua) |
| Main menu | Task 11 |
| Character select (P1/P2 picker) | Task 11 |
| Jump | Task 4 (controller.lua) |
| Stun on heavy/special hit | Task 3 + Task 4 |
| 480×270 pixel-perfect scaling | Task 1 (main.lua) |
| Audio (graceful no-op) | Task 10 |

**Deferred to Phase 2:** Food power-ups, fart system, Gregg easter egg, all 20 characters, 50 cities, online PvP, IAP, mobile touch controls, Story/Smash mode.

---

## Running Tests

```bash
# Logic unit tests (no love required):
lua tests/run_all.lua

# Full game:
love .
```

25 logic tests cover: Character (9), AttackSystem (5), Controller (4), NPCSpawner (3), FightManager (4).
