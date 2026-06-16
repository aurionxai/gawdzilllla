# Phase 2: Mobile Touch Controls + Docker/Railway Deploy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the game playable on mobile browsers via love.js (WebAssembly) served from a Docker container deployed to Railway with a public URL.

**Architecture:** love.js compiles Love2D's C core to WebAssembly; the game's Lua source + assets are zipped into `game.love` and loaded client-side. A new `src/touch_controls.lua` module handles touch zone geometry and state; `src/input.lua` is extended to merge keyboard and touch into one unified API so fight logic never changes. An nginx:alpine container serves the static bundle; Railway auto-deploys on `git push`.

**Tech Stack:** Love2D 11.x / Lua, love.js v11.4 (pre-built WASM), nginx:alpine, Docker multi-stage build, Railway (Dockerfile deploy)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `src/touch_controls.lua` | **Create** | Zone definitions, hit detection, axis math, draw overlay |
| `src/input.lua` | **Modify** | Merge keyboard + touch state, same public API |
| `main.lua` | **Modify** | Add `love.mousepressed`, `love.mousereleased` handlers |
| `src/hud.lua` | **Modify** | Call `TouchControls.draw()` when touch mode active |
| `tests/test_touch_controls.lua` | **Create** | Unit tests for zone detection, axis, button hits |
| `tests/run_all.lua` | **Modify** | Register new test file |
| `docker/index.html` | **Create** | love.js game shell (canvas + Module config) |
| `docker/nginx.conf` | **Create** | COOP/COEP headers, gzip, static serve |
| `docker/Dockerfile` | **Create** | Two-stage: zip .love → nginx:alpine |
| `docker/lovejs/` | **Create** | Pre-built love.js + love.wasm binaries (committed to repo) |
| `railway.json` | **Create** | Dockerfile path, health check |

---

## Task 1: touch_controls.lua — zone geometry and state

**Files:**
- Create: `src/touch_controls.lua`
- Create: `tests/test_touch_controls.lua`
- Modify: `tests/run_all.lua`

The module owns all touch geometry. Logical (REF) space is 480×270. Left 40% is the joystick zone; right 40% is the button zone split into 4 quadrants. It tracks one active touch per zone by touch ID (or `"mouse"` when called from mouse events).

- [ ] **Step 1: Write the failing tests**

Create `tests/test_touch_controls.lua`:

```lua
-- tests/test_touch_controls.lua
local R = require("tests/runner")
if not love then love = {} end

local TC = require("src/touch_controls")

print("\n-- touch_controls.lua --")

-- Zone geometry constants (must match touch_controls.lua)
local REF_W, REF_H = 480, 270

R.test("left zone: x < 192 is joystick zone", function()
  R.ok(TC.inJoystickZone(50, 200))
  R.notok(TC.inJoystickZone(300, 200))
end)

R.test("button zone: x > 288 is button zone", function()
  R.ok(TC.inButtonZone(400, 200))
  R.notok(TC.inButtonZone(100, 200))
end)

R.test("hitButton returns nil outside button zone", function()
  R.eq(TC.hitButton(100, 200), nil)
end)

R.test("hitButton: top-right quadrant of button zone = unleash", function()
  -- button zone x: 288..480, y: 190..270
  -- top-right of button grid = unleash
  local zone_x = 288
  local btn_w   = (REF_W - zone_x) / 2   -- 96
  local btn_h   = REF_H / 2              -- 135... but bottom half only
  -- buttons sit in bottom half (y >= 135)
  -- unleash = top-right of 2x2 grid in button zone
  local bx = zone_x + btn_w + btn_w * 0.5  -- center of right col
  local by = REF_H - btn_h + btn_h * 0.25  -- center of top row of bottom half
  local result = TC.hitButton(bx, by)
  R.eq(result, "unleash")
end)

R.test("hitButton: bottom-left = heavy", function()
  local zone_x = 288
  local btn_w   = (REF_W - zone_x) / 2
  local btn_h   = REF_H / 2
  local bx = zone_x + btn_w * 0.5
  local by = REF_H - btn_h * 0.5
  R.eq(TC.hitButton(bx, by), "heavy")
end)

R.test("getAxis returns 0,0 with no touch", function()
  TC.reset()
  local dx, dy = TC.getAxis()
  R.approx(dx, 0)
  R.approx(dy, 0)
end)

R.test("getAxis clamps to [-1,1] when dragged far", function()
  TC.reset()
  TC.touchpressed("mouse", 40, 200)   -- anchor at 40,200
  TC.touchmoved("mouse", 40 + 9999, 200)  -- drag way right
  local dx, _ = TC.getAxis()
  R.approx(dx, 1.0)
end)

R.test("isButtonDown false before press", function()
  TC.reset()
  R.notok(TC.isButtonDown("attack"))
end)

R.test("isButtonDown true after touchpressed on attack zone", function()
  TC.reset()
  -- attack = bottom-left of 2x2 in button zone, left col top row
  -- button zone x 288..480, buttons in bottom half y 135..270
  -- attack = top-left: col 0, row 0 of bottom 2x2 grid
  local zone_x = 288
  local btn_w   = (480 - zone_x) / 2   -- 96
  local btn_h   = 270 / 2              -- 135
  local bx = zone_x + btn_w * 0.5
  local by = btn_h + btn_h * 0.25
  TC.touchpressed("m2", bx, by)
  R.ok(TC.isButtonDown("attack"))
end)

R.test("isButtonDown false after touchreleased", function()
  TC.reset()
  local zone_x = 288
  local btn_w   = (480 - zone_x) / 2
  local btn_h   = 270 / 2
  local bx = zone_x + btn_w * 0.5
  local by = btn_h + btn_h * 0.25
  TC.touchpressed("m2", bx, by)
  TC.touchreleased("m2")
  R.notok(TC.isButtonDown("attack"))
end)
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd /Users/tc/godzilla-game
love . tests/run_all.lua
```

Expected: `Error: module 'src/touch_controls' not found`

- [ ] **Step 3: Create src/touch_controls.lua**

```lua
-- src/touch_controls.lua
-- Touch zone geometry and state for mobile/browser play.
-- All coordinates are in logical (REF) space: 480x270.
-- Call touchpressed/touchmoved/touchreleased from main.lua mouse handlers.
-- Call draw() from hud.lua each frame.

local TC = {}

local REF_W, REF_H = 480, 270

-- Joystick zone: left 40% of screen, bottom 50%
local JOY_X_MAX  = REF_W * 0.40   -- 192
local JOY_RADIUS = 40              -- max drag radius for full axis

-- Button zone: right 40% of screen, bottom 50%
local BTN_X_MIN = REF_W * 0.60    -- 288
local BTN_Y_MIN = REF_H * 0.50    -- 135
-- 2x2 grid of buttons in the bottom-right quadrant
-- Layout (col, row): attack=0,0  special=1,0  heavy=0,1  unleash=1,1
local BTN_W = (REF_W - BTN_X_MIN) / 2   -- 96
local BTN_H = (REF_H - BTN_Y_MIN) / 2   -- 67.5
local BTN_ACTIONS = {
  [0] = { [0] = "attack",  [1] = "special"  },
  [1] = { [0] = "heavy",   [1] = "unleash"  },
}

-- State
local _joyId     = nil   -- touch ID controlling joystick
local _joyAnchor = { x = 0, y = 0 }
local _joyDelta  = { x = 0, y = 0 }
local _buttons   = {}    -- action -> touch ID

-- ── Public helpers ────────────────────────────────────────────────────────────

function TC.inJoystickZone(x, y)
  return x < JOY_X_MAX and y > BTN_Y_MIN
end

function TC.inButtonZone(x, y)
  return x > BTN_X_MIN and y > BTN_Y_MIN
end

function TC.hitButton(x, y)
  if not TC.inButtonZone(x, y) then return nil end
  local col = math.floor((x - BTN_X_MIN) / BTN_W)
  local row = math.floor((y - BTN_Y_MIN) / BTN_H)
  col = math.max(0, math.min(1, col))
  row = math.max(0, math.min(1, row))
  return BTN_ACTIONS[row] and BTN_ACTIONS[row][col]
end

function TC.getAxis()
  return _joyDelta.x, _joyDelta.y
end

function TC.isButtonDown(action)
  return _buttons[action] ~= nil
end

-- ── Event handlers (called from main.lua) ────────────────────────────────────

function TC.touchpressed(id, x, y)
  if TC.inJoystickZone(x, y) and _joyId == nil then
    _joyId        = id
    _joyAnchor.x  = x
    _joyAnchor.y  = y
    _joyDelta.x   = 0
    _joyDelta.y   = 0
    return
  end
  local action = TC.hitButton(x, y)
  if action then
    _buttons[action] = id
  end
end

function TC.touchmoved(id, x, y)
  if id == _joyId then
    local dx = x - _joyAnchor.x
    local dy = y - _joyAnchor.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len > JOY_RADIUS then
      dx = dx / len
      dy = dy / len
    else
      dx = dx / JOY_RADIUS
      dy = dy / JOY_RADIUS
    end
    _joyDelta.x = dx
    _joyDelta.y = dy
  end
end

function TC.touchreleased(id)
  if id == _joyId then
    _joyId        = nil
    _joyDelta.x   = 0
    _joyDelta.y   = 0
  end
  for action, tid in pairs(_buttons) do
    if tid == id then _buttons[action] = nil end
  end
end

function TC.reset()
  _joyId        = nil
  _joyDelta.x   = 0
  _joyDelta.y   = 0
  _joyAnchor.x  = 0
  _joyAnchor.y  = 0
  _buttons      = {}
end

-- ── Draw (call from hud.lua when touch mode active) ──────────────────────────

function TC.draw()
  if not love or not love.graphics then return end
  local lg = love.graphics

  -- Joystick base
  local jbx = _joyId and _joyAnchor.x or (JOY_X_MAX / 2)
  local jby = _joyId and _joyAnchor.y or (BTN_Y_MIN + (REF_H - BTN_Y_MIN) / 2)
  lg.setColor(1, 1, 1, 0.18)
  lg.circle("fill", jbx, jby, JOY_RADIUS)
  lg.setColor(1, 1, 1, 0.35)
  lg.circle("line", jbx, jby, JOY_RADIUS)
  -- Joystick nub
  local nx = jbx + _joyDelta.x * JOY_RADIUS
  local ny = jby + _joyDelta.y * JOY_RADIUS
  lg.setColor(1, 1, 1, 0.55)
  lg.circle("fill", nx, ny, 12)

  -- Buttons
  local labels = { attack = "Z", special = "S", heavy = "H", unleash = "U" }
  local colors  = {
    attack  = {0.2, 0.8, 0.3},
    special = {0.2, 0.5, 1.0},
    heavy   = {1.0, 0.5, 0.1},
    unleash = {0.9, 0.1, 0.1},
  }
  for row = 0, 1 do
    for col = 0, 1 do
      local action = BTN_ACTIONS[row][col]
      local cx = BTN_X_MIN + col * BTN_W + BTN_W / 2
      local cy = BTN_Y_MIN + row * BTN_H + BTN_H / 2
      local r  = math.min(BTN_W, BTN_H) / 2 - 4
      local c  = colors[action]
      local alpha = TC.isButtonDown(action) and 0.75 or 0.30
      lg.setColor(c[1], c[2], c[3], alpha)
      lg.circle("fill", cx, cy, r)
      lg.setColor(c[1], c[2], c[3], 0.8)
      lg.circle("line", cx, cy, r)
    end
  end
  lg.setColor(1, 1, 1)
end

return TC
```

- [ ] **Step 4: Register test in run_all.lua**

Open `tests/run_all.lua`, add before the `runner.summary()` line:

```lua
require("tests/test_touch_controls")
```

Full file after edit:
```lua
require("tests/test_character")
require("tests/test_attack_system")
require("tests/test_controller")
require("tests/test_npc_spawner")
require("tests/test_fight_manager")
require("tests/test_fps_camera")
require("tests/test_fps_map")
require("tests/test_fps_player")
require("tests/test_fps_combat")
require("tests/test_touch_controls")
require("tests/runner").summary()
```

- [ ] **Step 5: Run tests — expect all pass**

```bash
love . tests/run_all.lua
```

Expected output includes:
```
-- touch_controls.lua --
  ✓ left zone: x < 192 is joystick zone
  ✓ button zone: x > 288 is button zone
  ✓ hitButton returns nil outside button zone
  ✓ hitButton: top-right quadrant of button zone = unleash
  ✓ hitButton: bottom-left = heavy
  ✓ getAxis returns 0,0 with no touch
  ✓ getAxis clamps to [-1,1] when dragged far
  ✓ isButtonDown false before press
  ✓ isButtonDown true after touchpressed on attack zone
  ✓ isButtonDown false after touchreleased
```

No failures in prior tests.

- [ ] **Step 6: Commit**

```bash
git add src/touch_controls.lua tests/test_touch_controls.lua tests/run_all.lua
git commit -m "feat(touch): add touch_controls zone detection, axis, button state"
```

---

## Task 2: Extend input.lua to merge keyboard + touch

**Files:**
- Modify: `src/input.lua`

The existing `getMoveX` / `isDown` API is unchanged — fight logic requires no edits. Touch state from `touch_controls.lua` is OR'd in.

- [ ] **Step 1: Extend input.lua**

Replace the entire contents of `src/input.lua`:

```lua
-- src/input.lua
-- Unified input: keyboard (P1/P2) + touch (P1 only).
-- Public API unchanged: getMoveX(player), isDown(player, action), getAction(player, key).
-- Touch state lives in touch_controls.lua; this module merges it in.

local TC    = require("src/touch_controls")
local Input = {}

-- Keyboard maps
local MAPS = {
  [1] = {
    left    = "left",
    right   = "right",
    up      = "up",
    down    = "down",
    jump    = "space",
    attack  = "z",
    heavy   = "x",
    unleash = "q",
    special = "a",
    super   = "s",
    special2= "d",
    fart    = "f",
  },
  [2] = {
    left    = "a",
    right   = "d",
    up      = "w",
    down    = "s",
    jump    = "lshift",
    special = "z",
    super   = "x",
    special2= "c",
    fart    = "v",
  },
}

-- Touch mode: auto-enabled on Web OS or after first touch event
local _touchMode = false

function Input.enableTouch()  _touchMode = true  end
function Input.isTouchMode()  return _touchMode   end

-- ── Touch event forwarders (called from main.lua) ─────────────────────────────

function Input.touchpressed(id, x, y)
  _touchMode = true
  TC.touchpressed(id, x, y)
end

function Input.touchmoved(id, x, y)
  TC.touchmoved(id, x, y)
end

function Input.touchreleased(id)
  TC.touchreleased(id)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Input.getMoveX(player)
  local m = MAPS[player]
  local x = 0
  if love.keyboard.isDown(m.left)  then x = x - 1 end
  if love.keyboard.isDown(m.right) then x = x + 1 end
  -- Layer in touch axis for P1
  if player == 1 and _touchMode then
    local tdx, _ = TC.getAxis()
    if math.abs(tdx) > 0.1 then
      x = x + tdx
    end
  end
  return math.max(-1, math.min(1, x))
end

function Input.isDown(player, action)
  local m = MAPS[player]
  local kb = m[action] and love.keyboard.isDown(m[action]) or false
  if kb then return true end
  -- Touch for P1 only
  if player == 1 and _touchMode then
    return TC.isButtonDown(action)
  end
  return false
end

function Input.getAction(player, key)
  local m = MAPS[player]
  for action, k in pairs(m) do
    if k == key then return action end
  end
  return nil
end

-- Expose TC for HUD draw
Input.TouchControls = TC

return Input
```

- [ ] **Step 2: Run all tests — expect pass**

```bash
love . tests/run_all.lua
```

All existing tests must still pass (keyboard path unchanged). Touch tests pass from Task 1.

- [ ] **Step 3: Commit**

```bash
git add src/input.lua
git commit -m "feat(touch): extend input.lua to merge keyboard + touch state"
```

---

## Task 3: Wire touch/mouse events in main.lua

**Files:**
- Modify: `main.lua`

love.js maps mobile browser touches to `love.mousepressed` / `love.mousereleased` / `love.mousemoved`. We also handle `love.touchpressed` etc. for native Love2D multi-touch. The mouse events use ID `"mouse"`.

- [ ] **Step 1: Add event handlers to main.lua**

Current `main.lua` has `love.mousemoved`. Add the remaining handlers and auto-detect Web OS:

```lua
-- main.lua
local SM    = require("src/scene_manager")
local Input = require("src/input")

local REF_W, REF_H = 480, 270

-- Helper: convert screen coords to logical (REF) space
local function toRef(sx, sy)
  local sw, sh = love.graphics.getDimensions()
  local scale  = math.min(sw / REF_W, sh / REF_H)
  local ox     = (sw - REF_W * scale) / 2
  local oy     = (sh - REF_H * scale) / 2
  return (sx - ox) / scale, (sy - oy) / scale
end

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  -- Auto-enable touch on Web
  if love.system and love.system.getOS() == "Web" then
    Input.enableTouch()
  end
  local MM = require("src/scenes/main_menu")
  SM.push(MM.new())
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
  SM.keypressed(key)
end

function love.keyreleased(key)
  SM.keyreleased(key)
end

-- Mouse events (love.js maps touch → mouse on Web)
function love.mousepressed(x, y, button)
  if button == 1 then
    local rx, ry = toRef(x, y)
    Input.touchpressed("mouse", rx, ry)
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    Input.touchreleased("mouse")
  end
end

function love.mousemoved(x, y, dx, dy)
  local rx, ry = toRef(x, y)
  Input.touchmoved("mouse", rx, ry)
  SM.mousemoved(rx, ry, dx, dy)
end

-- Native multi-touch (Love2D desktop / love-android / love-ios)
function love.touchpressed(id, x, y)
  local rx, ry = toRef(x, y)
  Input.touchpressed(id, rx, ry)
end

function love.touchmoved(id, x, y)
  local rx, ry = toRef(x, y)
  Input.touchmoved(id, rx, ry)
end

function love.touchreleased(id)
  Input.touchreleased(id)
end
```

- [ ] **Step 2: Smoke test — launch native game, verify no errors**

```bash
love .
```

Expected: game launches, no Lua errors in console, keyboard still works normally.

- [ ] **Step 3: Commit**

```bash
git add main.lua
git commit -m "feat(touch): wire mouse/touch events in main.lua, auto-enable on Web"
```

---

## Task 4: Touch HUD overlay

**Files:**
- Modify: `src/hud.lua`

`HUD:draw()` calls `TouchControls.draw()` when touch mode is active. No other HUD logic changes.

- [ ] **Step 1: Edit hud.lua — add touch overlay call**

Open `src/hud.lua`. Find the `HUD:draw()` function (starts around line 85). Add the following at the **end** of `HUD:draw()`, before the closing `end`:

```lua
  -- Touch controls overlay (mobile / Web)
  if Input and Input.isTouchMode() then
    Input.TouchControls.draw()
  end
```

Also add the require at the top of `hud.lua` (after existing requires, or at the top):

```lua
local Input = require("src/input")
```

- [ ] **Step 2: Smoke test — launch, tap T key to force touch mode**

Add a temporary keybind to test (remove after): in `love.keypressed` in `main.lua`, temporarily add:
```lua
if key == "t" then Input.enableTouch() end
```

```bash
love .
```

Press `T` → touch overlay should appear (joystick circle bottom-left, 4 colored buttons bottom-right). Press `T` again has no effect (already enabled). Click/drag the joystick — nub follows cursor.

- [ ] **Step 3: Remove the test keybind from main.lua**

Delete the `if key == "t"` line added in Step 2.

- [ ] **Step 4: Commit**

```bash
git add src/hud.lua main.lua
git commit -m "feat(touch): draw virtual joystick + buttons overlay when touch mode active"
```

---

## Task 5: love.js pre-built files + index.html shell

**Files:**
- Create: `docker/lovejs/love.js`
- Create: `docker/lovejs/love.wasm`
- Create: `docker/index.html`

love.js v11.4 provides pre-built binaries at https://github.com/Davidobot/love.js/releases — download the release zip, extract `love.js` and `love.wasm`, and commit them to `docker/lovejs/`.

- [ ] **Step 1: Download love.js v11.4 pre-built files**

```bash
cd /Users/tc/godzilla-game
mkdir -p docker/lovejs
cd /tmp
curl -L -o love-js.zip "https://github.com/Davidobot/love.js/releases/download/v11.4a/love.js-11.4a.zip"
unzip -j love-js.zip "*.js" "*.wasm" -d /Users/tc/godzilla-game/docker/lovejs/
cd /Users/tc/godzilla-game
```

Verify:
```bash
ls -lh docker/lovejs/
```
Expected: `love.js` (~400KB) and `love.wasm` (~10–12MB) present.

If the exact release URL above doesn't work, check the latest release at:
`https://github.com/Davidobot/love.js/releases` and adjust the URL.

- [ ] **Step 2: Create docker/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>GAWDZILLLLA</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    canvas {
      display: block;
      width: 100%;
      height: 100%;
      image-rendering: pixelated;
      image-rendering: crisp-edges;
      touch-action: none;
    }
    #tap-to-start {
      position: fixed; inset: 0;
      display: flex; align-items: center; justify-content: center;
      background: rgba(0,0,0,0.85);
      color: #fff; font-family: monospace; font-size: 1.5rem;
      cursor: pointer; z-index: 100;
    }
  </style>
</head>
<body>
  <div id="tap-to-start">TAP TO START</div>
  <canvas id="canvas" oncontextmenu="event.preventDefault()"></canvas>

  <script>
    // Unlock Web Audio on first user gesture (required by all modern browsers)
    document.getElementById('tap-to-start').addEventListener('click', function() {
      this.remove();
      startGame();
    }, { once: true });

    function startGame() {
      var Module = {
        canvas: document.getElementById('canvas'),
        arguments: ['/game.love'],
        INITIAL_MEMORY: 268435456,  // 256MB
        onRuntimeInitialized: function() {
          console.log('love.js ready');
        },
        print: function(text) { console.log(text); },
        printErr: function(text) { console.error(text); },
        locateFile: function(path) { return 'lovejs/' + path; },
      };
      window.Module = Module;
      var script = document.createElement('script');
      script.src = 'lovejs/love.js';
      document.body.appendChild(script);
    }
  </script>
</body>
</html>
```

- [ ] **Step 3: Commit**

```bash
git add docker/lovejs/ docker/index.html
git commit -m "feat(docker): add love.js v11.4 pre-built binaries and index.html shell"
```

---

## Task 6: nginx.conf and Dockerfile

**Files:**
- Create: `docker/nginx.conf`
- Create: `docker/Dockerfile`

The COOP/COEP headers are mandatory — SharedArrayBuffer (required by love.js audio) only works with these headers in modern browsers.

- [ ] **Step 1: Create docker/nginx.conf**

```nginx
server {
    listen       8080;
    server_name  _;
    root         /usr/share/nginx/html;
    index        index.html;

    # REQUIRED for SharedArrayBuffer (love.js audio)
    add_header Cross-Origin-Opener-Policy   "same-origin"    always;
    add_header Cross-Origin-Embedder-Policy "require-corp"   always;

    # Serve WASM with correct MIME type
    types {
        application/wasm  wasm;
        text/html         html htm;
        application/javascript  js;
        application/octet-stream  love;
    }

    # Gzip everything compressible
    gzip            on;
    gzip_types      text/html application/javascript application/wasm;
    gzip_min_length 1024;

    # Long cache for versioned assets, short for HTML
    location ~* \.(js|wasm|love)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header Cross-Origin-Opener-Policy   "same-origin"  always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

- [ ] **Step 2: Create docker/Dockerfile**

```dockerfile
# ── Stage 1: package .love file ───────────────────────────────────────────────
FROM alpine:3.19 AS packager
WORKDIR /build
RUN apk add --no-cache zip
COPY . .
# Zip Lua source + assets into game.love (excluding dev/build dirs)
RUN zip -r game.love . \
      -x "docker/*" \
      -x "docs/*" \
      -x ".git/*" \
      -x "tests/*" \
      -x "*.sh" \
      -x ".gitignore"

# ── Stage 2: nginx serve ──────────────────────────────────────────────────────
FROM nginx:1.25-alpine AS runtime
WORKDIR /usr/share/nginx/html
# Remove default nginx content
RUN rm -f /etc/nginx/conf.d/default.conf index.html

# love.js pre-built binaries (committed to repo)
COPY docker/lovejs/ ./lovejs/

# Packaged game
COPY --from=packager /build/game.love ./game.love

# Shell + config
COPY docker/index.html ./index.html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

- [ ] **Step 3: Build and run locally**

```bash
docker build -t gawdzilllla .
docker run -p 8080:8080 gawdzilllla
```

Open `http://localhost:8080` in a browser. Expected: "TAP TO START" overlay → click → game loads in canvas.

If love.wasm fails to load, check browser DevTools → Network tab for MIME type and COOP/COEP header errors.

- [ ] **Step 4: Commit**

```bash
git add docker/Dockerfile docker/nginx.conf
git commit -m "feat(docker): add two-stage Dockerfile + nginx config with COOP/COEP headers"
```

---

## Task 7: Railway config + deploy

**Files:**
- Create: `railway.json`

- [ ] **Step 1: Create railway.json**

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "docker/Dockerfile"
  },
  "deploy": {
    "startCommand": "nginx -g 'daemon off;'",
    "healthcheckPath": "/",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

- [ ] **Step 2: Push to Railway**

```bash
git add railway.json
git commit -m "feat(railway): add railway.json for Dockerfile deploy"
git push origin main
```

In the Railway dashboard:
1. New Project → Deploy from GitHub repo → select `godzilla-game`
2. Railway detects `railway.json` → uses the Dockerfile builder
3. Watch build logs — expect `docker build` output, then `nginx` start
4. Click "Generate Domain" → Railway assigns `<project>.up.railway.app`

- [ ] **Step 3: Verify live URL**

Open `https://<project>.up.railway.app` on a desktop browser.
- Expected: "TAP TO START" → click → game canvas loads

Open on a mobile browser (iOS Safari / Android Chrome).
- Expected: same, plus touch overlay visible, joystick responds to thumb drag, buttons light up on tap

- [ ] **Step 4: Verify COOP/COEP headers are live**

```bash
curl -I https://<project>.up.railway.app | grep -i "cross-origin"
```

Expected:
```
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

If audio doesn't play on mobile, these headers are missing — check nginx.conf is in the right path in the Docker image.

---

## Self-Review Notes

- **Spec §3 (Docker):** Covered in Tasks 5–7 with exact Dockerfile, nginx.conf, Railway config.
- **Spec §4 (Mobile touch):** Covered in Tasks 1–4: zone geometry, axis, buttons, HUD overlay, OS detection.
- **Spec §4 (Web Audio):** Covered in Task 5 index.html tap-to-start overlay.
- **COOP/COEP:** Specified in nginx.conf in TWO locations (server block + location block) to ensure headers are set on all responses including `.wasm`.
- **Type consistency:** `TC.touchpressed(id, x, y)` / `TC.touchmoved(id, x, y)` / `TC.touchreleased(id)` — consistent across touch_controls.lua, input.lua, and main.lua.
- **`BTN_ACTIONS` row/col:** Row 0 = attack/special (top of button zone, y < BTN_Y_MIN + BTN_H); Row 1 = heavy/unleash (bottom). Tests reference `row=0,col=0` = attack — consistent with the implementation.
- **REF space in main.lua:** `toRef()` converts screen coords to logical 480×270 before passing to Input — touch zone geometry in touch_controls.lua works in REF space only.
