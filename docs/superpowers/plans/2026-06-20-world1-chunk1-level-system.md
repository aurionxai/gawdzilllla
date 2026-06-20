# World 1 — Chunk 1: Level System + Deep w1l1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single hardcoded flat level with an ASCII-tilemap level system + a two-axis (vertical-scrolling) camera + themed Tokyo tiles + a new spike hazard, and rebuild `w1l1` as a deep, climbable level.

**Architecture:** A new pure `levelparse.js` (Node-testable, browser-global) turns ASCII rows into a tile grid + spawn lists + dimensions. `index.html` consumes it: a `buildFromRows()` helper converts that into the game's level object; level dims `LW/LH` become per-level; the camera gains vertical follow+clamp (the renderer already subtracts `cam.y` everywhere); `drawTiles` renders themed Tokyo tiles incl. spikes; `w1l1` becomes a tall tilemap.

**Tech Stack:** Vanilla JS (ES2020), HTML5 Canvas. Node v24 (`node --test`) for the parser only. No build system.

## Global Constraints

- `levelparse.js` MUST be CommonJS-compatible: define a `LevelParse` object and end with `if (typeof module !== 'undefined' && module.exports) module.exports = LevelParse;`. Browser includes it via `<script src="levelparse.js"></script>` BEFORE the inline game script.
- Tile ints (unchanged + one new): `T_AIR=0, T_SOLID=1, T_PLAT=2, T_DEST=3, T_HAZARD=4`.
- Tile size `TS=32`; viewport `VW=640, VH=360`.
- ASCII char legend (exact): `' '`=air · `'#'`=solid · `'='`=one-way platform · `'x'`=destructible crate · `'^'`=spike hazard · `'o'`=food · `'s'`=slime enemy · `'w'`=whelp enemy · `'t'`=tinbot enemy · `'C'`=citizen · `'P'`=player spawn · `'E'`=exit. Spawn chars (`o s w t C P E`) leave an AIR tile under them.
- Run parser tests: `cd kaiju-clash && node --test`. All pass before each commit in Task 1.
- Commit after every task.

---

### Task 1: `levelparse.js` — ASCII rows → tiles + spawns + dims

**Files:**
- Create: `kaiju-clash/levelparse.js`
- Test: `kaiju-clash/test/levelparse.test.js`

**Interfaces:**
- Produces: `LevelParse.parseLevel(rows) -> { tiles, LW, LH, spawns }` where `tiles` is `int[LH][LW]` (rows padded to the widest with `T_AIR`), `LW`=max row length, `LH`=rows.length, and `spawns = { food:[{r,c}], enemies:[{r,c,type}], citizens:[{r,c}], player:{r,c}|null, exit:{r,c}|null }`. `type` is `'slime'|'whelp'|'tinbot'`.

- [ ] **Step 1: Write the failing test**

Create `kaiju-clash/test/levelparse.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const LP = require('../levelparse.js');

const ROWS = [
  "  =   ",
  "o   ^ ",
  "P  s  ",
  "######",
];

test('dims = widest row x row count', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.LW, 6);
  assert.strictEqual(r.LH, 4);
});

test('tile types map correctly', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.tiles[0][2], 2); // '=' platform
  assert.strictEqual(r.tiles[1][4], 4); // '^' spike hazard
  assert.strictEqual(r.tiles[3][0], 1); // '#' solid
  assert.strictEqual(r.tiles[0][0], 0); // ' ' air
});

test('spawn chars leave air and record positions', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.tiles[1][0], 0);            // 'o' -> air tile
  assert.deepStrictEqual(r.spawns.food[0], { r:1, c:0 });
  assert.deepStrictEqual(r.spawns.player, { r:2, c:0 });
  assert.deepStrictEqual(r.spawns.enemies[0], { r:2, c:3, type:'slime' });
});

test('short rows pad to width with air', () => {
  const r = LP.parseLevel(["#", "   ##"]);
  assert.strictEqual(r.LW, 5);
  assert.strictEqual(r.tiles[0][4], 0); // padded
  assert.strictEqual(r.tiles[1][3], 1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Cannot find module '../levelparse.js'`.

- [ ] **Step 3: Write minimal implementation**

Create `kaiju-clash/levelparse.js`:

```js
// Pure ASCII-tilemap parser. Runs in Node (tests) and the browser (global LevelParse).
const LevelParse = {};
const T_AIR=0, T_SOLID=1, T_PLAT=2, T_DEST=3, T_HAZARD=4;
const TILE = { ' ':T_AIR, '#':T_SOLID, '=':T_PLAT, 'x':T_DEST, '^':T_HAZARD };
const ENEMY = { 's':'slime', 'w':'whelp', 't':'tinbot' };

LevelParse.parseLevel = function parseLevel(rows){
  const LH = rows.length;
  const LW = rows.reduce((m,r)=>Math.max(m,r.length), 0);
  const tiles = Array.from({length:LH}, ()=>new Array(LW).fill(T_AIR));
  const spawns = { food:[], enemies:[], citizens:[], player:null, exit:null };
  for(let r=0;r<LH;r++){
    for(let c=0;c<LW;c++){
      const ch = rows[r][c] || ' ';
      if(ch in TILE){ tiles[r][c] = TILE[ch]; continue; }
      // spawn chars: leave air, record position
      tiles[r][c] = T_AIR;
      if(ch==='o') spawns.food.push({r,c});
      else if(ch in ENEMY) spawns.enemies.push({r,c,type:ENEMY[ch]});
      else if(ch==='C') spawns.citizens.push({r,c});
      else if(ch==='P') spawns.player = {r,c};
      else if(ch==='E') spawns.exit = {r,c};
    }
  }
  return { tiles, LW, LH, spawns };
};

if (typeof module !== 'undefined' && module.exports) module.exports = LevelParse;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — levelparse tests + the existing 23 progression tests all green.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/levelparse.js kaiju-clash/test/levelparse.test.js
git commit -m "feat: ASCII tilemap parser (levelparse.js)"
```

---

### Task 2: Wire the parser into the browser + per-level LW/LH

**Files:**
- Modify: `kaiju-clash/index.html` (script include; `const LW/LH` → `let`; add `buildFromRows`; point `LEVEL_BUILDERS.w1l1` at a tilemap)

**Interfaces:**
- Consumes: `LevelParse.parseLevel`, `FOOD_TYPES`, `ENEMIES`, `NPC_TYPES`, `TS`.
- Produces: `buildFromRows(rows) -> { tiles, food, enemies, citizens, playerSpawn, exit, LW, LH }` — the game level object. Sets module-level `LW`/`LH` to the level's dims when a level is built.

- [ ] **Step 1: Add the script include**

In `kaiju-clash/index.html`, find `<script src="progression.js"></script>` and add immediately after it:

```html
<script src="levelparse.js"></script>
```

- [ ] **Step 2: Make LW/LH mutable**

Find (around line 281):

```js
const LW    = 110;  // level tiles wide
const LH    = 11;   // level tiles tall (352px)
```

Replace with:

```js
let LW    = 110;  // level tiles wide  (set per-level on load)
let LH    = 11;   // level tiles tall  (set per-level on load)
```

- [ ] **Step 3: Add `buildFromRows` near the LEVEL_BUILDERS registry**

In `index.html`, find `const LEVEL_BUILDERS = {` and insert ABOVE it:

```js
// Convert an ASCII tilemap (array of strings) into a game level object.
function buildFromRows(rows){
  const p = LevelParse.parseLevel(rows);
  LW = p.LW; LH = p.LH;                       // level dims are global, set on build
  const food = p.spawns.food.map((s,i)=>({
    type: FOOD_TYPES[i % FOOD_TYPES.length],
    x: s.c*TS + TS/2 - 10, y: s.r*TS - 20, collected:false, bobOff:i*0.8,
  }));
  const enemies = p.spawns.enemies.map(s=>({
    x: s.c*TS, y: s.r*TS, dir:-1, type:s.type,
    hp: ENEMIES[s.type].hp, maxHp: ENEMIES[s.type].hp,
    patrol:[(s.c-3)*TS, (s.c+3)*TS], stunMs:0, dead:false, flashMs:0,
  }));
  const citizens = p.spawns.citizens.map((s,i)=>({
    x: s.c*TS, y: s.r*TS, dir: i%2?1:-1, clr:'#ffd8a8', npc: NPC_TYPES[i % NPC_TYPES.length],
    saved:false, eaten:false, eatenTimer:0, savedTimer:0, particles:[],
  }));
  const ps = p.spawns.player || { r:7, c:2 };
  return { tiles:p.tiles, food, enemies, citizens,
           playerSpawn:{ x:ps.c*TS, y:ps.r*TS }, exit:p.spawns.exit, LW:p.LW, LH:p.LH };
}
```

- [ ] **Step 4: Point w1l1 at a tilemap (temporary, replaced in Task 6)**

Replace the `w1l1` entry inside `LEVEL_BUILDERS` with a tilemap build. Find:

```js
const LEVEL_BUILDERS = {
  w1l1: () => ({
    tiles:    buildLevel(),
    food:     spawnFood(),
    enemies:  spawnEnemies(),
    citizens: spawnCitizens(),
  }),
};
```

Replace with:

```js
// A small starter tilemap proving the pipeline; the real deep w1l1 lands in Task 6.
const W1L1_ROWS = [
  "                                        ",
  "                                        ",
  "                   ===                  ",
  "          o              o        E     ",
  "      ===        x x          ===       ",
  "                                        ",
  "   o        s       C      w       o    ",
  "  ===      ###     ===    ###      ===   ",
  "                  ^^                     ",
  "P    o   C    s        o    C      s   o ",
  "########################################",
  "########################################",
];
const LEVEL_BUILDERS = {
  w1l1: () => buildFromRows(W1L1_ROWS),
};
```

- [ ] **Step 5: Use the player spawn in mkState**

`mkState` currently hardcodes `x: 2*TS, y: 7*TS`. Find those lines in `mkState` and replace the player's `x`/`y` initialization so it uses the built level's spawn. After `const build = (LEVEL_BUILDERS[levelId] || LEVEL_BUILDERS.w1l1)();`, change the `player: { x: 2*TS, y: 7*TS, ...}` to:

```js
    player: {
      x: (build.playerSpawn ? build.playerSpawn.x : 2*TS),
      y: (build.playerSpawn ? build.playerSpawn.y : 7*TS),
```

(leave the rest of the player object unchanged).

- [ ] **Step 6: Manual browser verification**

Run: `cd kaiju-clash && python3 -m http.server 8000` → open `http://localhost:8000/`.
Expected:
- Console: no errors; `typeof LevelParse` is `object`.
- Pick a character → overworld → enter level 1. It loads from the tilemap: ground along the bottom, a few floating platforms, food, a couple enemies, citizens, an EXIT marker. The kaiju spawns at the `P` (bottom-left) and can run/jump on the platforms.
- `LW`/`LH` in console equal `40`/`12`.

- [ ] **Step 7: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: build levels from ASCII tilemaps; per-level LW/LH"
```

---

### Task 3: Vertical camera follow + clamp

**Files:**
- Modify: `kaiju-clash/index.html` (camera-follow block, ~line 584)

**Interfaces:**
- Consumes: `LW`, `LH`, `TS`, `VW`, `VH`, `s.cam`, `s.player`.
- Produces: `s.cam.y` now tracks the player vertically, clamped to `[0, LH*TS - VH]` (0 when the level is ≤ viewport height).

- [ ] **Step 1: Add vertical follow next to the horizontal one**

Find (around line 584):

```js
  s.cam.x += (tx - s.cam.x) * 0.11;
  s.cam.x = Math.max(0, Math.min(LW*TS - VW, s.cam.x));
```

Replace with:

```js
  s.cam.x += (tx - s.cam.x) * 0.11;
  s.cam.x = Math.max(0, Math.min(LW*TS - VW, s.cam.x));
  // Vertical follow: keep the player ~55% down the screen; clamp to level height.
  const tyc = pl.y - VH*0.55;
  s.cam.y += (tyc - s.cam.y) * 0.11;
  s.cam.y = Math.max(0, Math.min(Math.max(0, LH*TS - VH), s.cam.y));
```

(`tx` is the existing horizontal target; `pl` is the existing player reference in this function. If the player variable is named `s.player` here, use `s.player.y`.)

- [ ] **Step 2: Manual browser verification**

Serve and open the game; enter level 1. Since the starter map is 12 tiles tall (384px > 360px viewport), climbing onto the upper platforms now **scrolls the view upward**, and descending scrolls back down. On the bottom the camera sits at `cam.y=0`. No jitter.

- [ ] **Step 3: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: vertical camera follow + clamp (two-axis scrolling)"
```

---

### Task 4: Spike hazard tile (`T_HAZARD`) — damage on contact

**Files:**
- Modify: `kaiju-clash/index.html` (tile constants if needed; player update damage check)

**Interfaces:**
- Consumes: `tile()`, `s.player`, the existing damage path (`pl.hp`, `pl.invincMs`, `s.hitsTaken`).
- Produces: standing on / touching a `T_HAZARD` tile damages the player like an enemy hit, respecting invincibility frames.

- [ ] **Step 1: Ensure T_HAZARD constant exists**

Find the tile constant line (around line 290): `const T_AIR=0, T_SOLID=1, T_PLAT=2, T_DEST=3;` and replace with:

```js
const T_AIR=0, T_SOLID=1, T_PLAT=2, T_DEST=3, T_HAZARD=4;
```

- [ ] **Step 2: Add a hazard-contact check in updatePlayer**

In `updatePlayer`, after the vertical movement/collision resolution (after `resolveY(...)` is called), add a hazard check. Find where `resolveY` is invoked in `updatePlayer` and insert directly after it:

```js
  // Spikes / hazards: damage if the player's box overlaps a hazard tile.
  if((pl.invincMs||0) <= 0){
    const c0 = Math.floor(pl.x / TS), c1 = Math.floor((pl.x+PW) / TS);
    const r0 = Math.floor(pl.y / TS), r1 = Math.floor((pl.y+PH) / TS);
    let onHazard = false;
    for(let r=r0;r<=r1;r++) for(let c=c0;c<=c1;c++) if(tile(s.level.tiles,r,c)===T_HAZARD) onHazard=true;
    if(onHazard){
      pl.hp = Math.max(0, pl.hp - 12);
      pl.invincMs = 1000;
      s.hitsTaken++;
      pl.vy = -6;                     // small knock-up
      addShake(5, 180);
    }
  }
```

(`PW`/`PH` are the existing player width/height constants used by `resolveX`/`resolveY`; reuse them.)

- [ ] **Step 3: Manual browser verification**

Serve, enter level 1. Walk the kaiju onto the `^^` spikes (mid-level). Expected: the player flashes (invincibility), HP drops, a small knock-up + screen shake fire, and repeated contact doesn't drain HP faster than once per second.

- [ ] **Step 4: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: spike hazard tile damages the player"
```

---

### Task 5: Themed Tokyo tile rendering

**Files:**
- Modify: `kaiju-clash/index.html` (`drawTiles`, ~line 896)

**Interfaces:**
- Consumes: `s.level.tiles`, `s.cam`, `TS`, `T_*` constants.
- Produces: World-1 tiles drawn as themed Tokyo art — solids as building blocks with a lit edge, platforms as rooftop slabs, crates as wooden boxes, hazards as metal spikes — replacing flat colored rectangles.

- [ ] **Step 1: Replace the per-tile draw in drawTiles**

Read `drawTiles` (around line 896-950). It loops rows/cols computing `px=~~(c*TS-cam.x), py=~~(r*TS-cam.y)` and fills by tile type. Replace the per-tile fill body so each type draws themed art. Inside the loop, after computing `px,py` and the tile value `t`, use:

```js
    if(t===T_SOLID){
      ctx.fillStyle='#6b5536'; ctx.fillRect(px,py,TS,TS);           // building wall
      ctx.fillStyle='#7d6440'; ctx.fillRect(px,py,TS,4);            // lit top edge
      ctx.fillStyle='rgba(0,0,0,0.18)'; ctx.fillRect(px,py+TS-4,TS,4);
      ctx.strokeStyle='rgba(0,0,0,0.15)'; ctx.strokeRect(px+0.5,py+0.5,TS-1,TS-1);
    } else if(t===T_PLAT){
      ctx.fillStyle='#9a4a3a'; ctx.fillRect(px,py,TS,7);            // rooftop slab
      ctx.fillStyle='#bd5f49'; ctx.fillRect(px,py,TS,3);
      ctx.fillStyle='rgba(0,0,0,0.12)'; ctx.fillRect(px,py+7,TS,3);
    } else if(t===T_DEST){
      ctx.fillStyle='#a9762e'; ctx.fillRect(px+1,py+1,TS-2,TS-2);   // wooden crate
      ctx.strokeStyle='#6e4a18'; ctx.lineWidth=2; ctx.strokeRect(px+2,py+2,TS-4,TS-4);
      ctx.beginPath(); ctx.moveTo(px+2,py+2); ctx.lineTo(px+TS-2,py+TS-2);
      ctx.moveTo(px+TS-2,py+2); ctx.lineTo(px+2,py+TS-2); ctx.stroke();
    } else if(t===T_HAZARD){
      ctx.fillStyle='#3a3f4a'; ctx.fillRect(px,py+TS-6,TS,6);       // base
      ctx.fillStyle='#c8ccd4';                                      // metal spikes
      for(let k=0;k<4;k++){ const sx=px+k*8;
        ctx.beginPath(); ctx.moveTo(sx,py+TS-6); ctx.lineTo(sx+4,py+10); ctx.lineTo(sx+8,py+TS-6); ctx.fill(); }
    }
```

Remove the old flat-rectangle fills for these types (keep the loop, the `px/py/t` computation, and any air `continue`).

- [ ] **Step 2: Manual browser verification**

Serve, enter level 1. Expected: the ground reads as building blocks, the floating `=` platforms as red **rooftop slabs**, `x` as **wooden crates**, `^^` as **metal spikes** — themed to Tokyo over the day backdrop, not flat colored boxes. Take a screenshot to confirm.

- [ ] **Step 3: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: themed Tokyo tile rendering (rooftops, crates, spikes)"
```

---

### Task 6: Author the deep, climbable w1l1

**Files:**
- Modify: `kaiju-clash/index.html` (`W1L1_ROWS`)

**Interfaces:**
- Consumes: `buildFromRows`, the legend, the camera + hazards + themed tiles from Tasks 2–5.
- Produces: a real World-1 level — taller than the screen (~20 rows), a winding street→rooftops→sky climb, with food/enemies/citizens, spikes, an exit up top.

- [ ] **Step 1: Replace W1L1_ROWS with the deep level**

Replace the `W1L1_ROWS` array (from Task 2) with this ~20-row-tall, climbable layout (40 wide). Vertical gaps between platforms are ≤3 tiles so the kaiju can jump them:

```js
const W1L1_ROWS = [
  "                                  E     ",
  "                              ===       ",
  "                    o      C            ",
  "                   ===        ===       ",
  "              w                         ",
  "         ===        ^^      o           ",
  "   o   C       ===        ===           ",
  "  ===              o                    ",
  "            s            C       w      ",
  "       ===     ===     ===      ===     ",
  "   o                          o         ",
  "  ===       x x      ===                ",
  "        C        o          C     s     ",
  "  ===  ===     ===   ^^    ===   ===     ",
  "                                        ",
  "   o   s    C    o    w    C    o    s   ",
  "  ###     ###       ###        ###      ",
  "              ^^^             o          ",
  "P   o   C   s    o   C   w   o   C    o  ",
  "########################################",
  "########################################",
];
```

- [ ] **Step 2: Manual browser verification (the deliverable)**

Serve, enter level 1. Expected — a real climb:
- The kaiju spawns bottom-left on the street; the bottom is solid ground with citizens/enemies/food.
- Jumping onto the lower rooftops and up through the staggered `=` platforms **scrolls the camera upward**; the day-sky shows at the top.
- Spikes (`^^`) punish bad jumps; crates (`x`) sit mid-climb; the **EXIT** is at the very top — reaching the right side / exit still triggers victory.
- Capture a screenshot mid-climb (camera scrolled up, rooftops + sky visible) to confirm the depth.

- [ ] **Step 3: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: deep climbable w1l1 (street -> rooftops -> sky)"
```

---

## What this chunk delivers

A working level system: ASCII tilemaps (Node-tested parser) → game levels, a two-axis vertical-scrolling camera, themed Tokyo tiles, a spike hazard, and `w1l1` rebuilt as a deep street→sky climb. Chunk 2 (`w1l2`+`w1l3`) and chunk 3 (Riot Mecha boss) author more tilemaps + the boss on top of this.

## Self-review notes (coverage vs. spec)
- Level format (ASCII tilemaps, variable W×H) → Task 1 + 2. ✅
- Two-axis camera + cam.y clamp → Task 3 (renderer already cam.y-aware). ✅
- Hazard tile → Task 4. ✅
- Themed Tokyo tiles → Task 5. ✅
- Deep w1l1 (the rebuilt level) → Task 6. ✅
- w1l2/w1l3/boss → explicitly out of this chunk (spec build-order chunks 2-3).
