# Progression Spine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the single-level Kaiju Clash game into a data-driven campaign skeleton — an overworld level-select, a level loader, a rank/reward screen, and a persistent meta-progression layer (Spirit Orbs + growth stage) — so World 1 content, NPCs, and the hub can plug in later.

**Architecture:** All progression *logic* (rank computation, orb rewards, growth-stage thresholds, save/load serialization, level-unlock rules) lives in a new `progression.js` that works in BOTH Node (for automated tests via `node --test`) and the browser (loaded as a plain `<script>` exposing a global `Progression`). `index.html` consumes that global: it loads/saves meta-state to `localStorage`, refactors the hardcoded level into a registry-keyed loader, and adds two new scenes (`overworld`, upgraded `victory`). Pure logic is unit-tested; canvas/UI changes are verified manually in a browser.

**Tech Stack:** Vanilla JS (ES2020), HTML5 Canvas, Web Audio. No build system. Node v24 (`node --test`, `node:assert`) for tests only — ships nothing to the browser bundle. Deployed as static `index.html` to higgsfield.gg.

## Global Constraints

- `progression.js` MUST be CommonJS-compatible: define a `Progression` object and end with `if (typeof module !== 'undefined' && module.exports) module.exports = Progression;`. The browser includes it via `<script src="progression.js"></script>` placed BEFORE the main inline `<script>` so the `Progression` global is available synchronously.
- Pure functions in `progression.js` MUST NOT touch `window`, `document`, `localStorage`, or `Date` — callers pass values in. This keeps them testable in Node.
- Tile size `TS=32`, level dims `LW=110`, `LH=11` are fixed and reused — do not change.
- Scene values are string literals on the existing global `let scene`. New value: `'overworld'`. Existing: `select|playing|victory|gameover`.
- localStorage key for saved progress: `'kaiju_meta'`.
- Run the full test suite with `node --test` from `kaiju-clash/`. All tests must pass before each commit in logic tasks.
- Commit after every task. Keep commits small.

---

### Task 1: progression.js scaffold + rank computation

**Files:**
- Create: `kaiju-clash/progression.js`
- Test: `kaiju-clash/test/progression.test.js`

**Interfaces:**
- Produces: `Progression.computeRank({ timeSec, hitsTaken, citizensSaved, citizensTotal }) -> 'S'|'A'|'B'|'C'`

- [ ] **Step 1: Write the failing test**

Create `kaiju-clash/test/progression.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const Progression = require('../progression.js');

test('computeRank: flawless fast full-save is S', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 8, citizensTotal: 8 }),
    'S');
});

test('computeRank: most saved, few hits is A', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 200, hitsTaken: 2, citizensSaved: 6, citizensTotal: 8 }),
    'A');
});

test('computeRank: half saved is B', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 5, citizensSaved: 4, citizensTotal: 8 }),
    'B');
});

test('computeRank: poor save rate is C', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 9, citizensSaved: 1, citizensTotal: 8 }),
    'C');
});

test('computeRank: handles zero citizens total without dividing by zero', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 0, citizensTotal: 0 }),
    'S');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Cannot find module '../progression.js'`.

- [ ] **Step 3: Write minimal implementation**

Create `kaiju-clash/progression.js`:

```js
// Pure progression logic. Runs in Node (tests) and the browser (global Progression).
// MUST NOT reference window/document/localStorage/Date.
const Progression = {};

// S/A/B/C letter rank for a completed level.
// Evaluated top-down: first matching tier wins.
Progression.computeRank = function computeRank({ timeSec, hitsTaken, citizensSaved, citizensTotal }) {
  const ratio = citizensTotal > 0 ? citizensSaved / citizensTotal : 1;
  if (ratio >= 1 && hitsTaken === 0 && timeSec <= 90) return 'S';
  if (ratio >= 0.75 && hitsTaken <= 2) return 'A';
  if (ratio >= 0.5) return 'B';
  return 'C';
};

if (typeof module !== 'undefined' && module.exports) module.exports = Progression;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 5 tests passing.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/progression.js kaiju-clash/test/progression.test.js
git commit -m "feat: progression.js scaffold + computeRank (S/A/B/C)"
```

---

### Task 2: Orb rewards + star count

**Files:**
- Modify: `kaiju-clash/progression.js`
- Test: `kaiju-clash/test/progression.test.js`

**Interfaces:**
- Consumes: `Progression.computeRank` (Task 1)
- Produces:
  - `Progression.orbsForResult({ rank, citizensSaved, sideQuestsDone }) -> number` (integer Spirit Orbs)
  - `Progression.starsForResult({ rank, citizensSaved, citizensTotal }) -> 1|2|3`

- [ ] **Step 1: Write the failing test**

Append to `kaiju-clash/test/progression.test.js`:

```js
test('orbsForResult: S rank base + bonuses', () => {
  // base S=100, +5/citizen *8 = 40, +20/sidequest *1 = 20  => 160
  assert.strictEqual(
    Progression.orbsForResult({ rank: 'S', citizensSaved: 8, sideQuestsDone: 1 }),
    160);
});

test('orbsForResult: C rank minimal', () => {
  // base C=30, +0 citizens, +0 sidequests => 30
  assert.strictEqual(
    Progression.orbsForResult({ rank: 'C', citizensSaved: 0, sideQuestsDone: 0 }),
    30);
});

test('starsForResult: complete only is 1 star', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'C', citizensSaved: 2, citizensTotal: 8 }),
    1);
});

test('starsForResult: A rank adds a star', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'A', citizensSaved: 6, citizensTotal: 8 }),
    2);
});

test('starsForResult: A rank + all citizens is 3 stars', () => {
  assert.strictEqual(
    Progression.starsForResult({ rank: 'A', citizensSaved: 8, citizensTotal: 8 }),
    3);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Progression.orbsForResult is not a function`.

- [ ] **Step 3: Write minimal implementation**

In `kaiju-clash/progression.js`, add before the `module.exports` line:

```js
const RANK_ORB_BASE = { S: 100, A: 75, B: 50, C: 30 };

Progression.orbsForResult = function orbsForResult({ rank, citizensSaved, sideQuestsDone }) {
  const base = RANK_ORB_BASE[rank] || 0;
  return base + citizensSaved * 5 + sideQuestsDone * 20;
};

// 1 star: completed. +1 star: rank A or S. +1 star: every citizen saved.
Progression.starsForResult = function starsForResult({ rank, citizensSaved, citizensTotal }) {
  let stars = 1;
  if (rank === 'A' || rank === 'S') stars += 1;
  if (citizensTotal > 0 && citizensSaved >= citizensTotal) stars += 1;
  return stars;
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 10 tests passing.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/progression.js kaiju-clash/test/progression.test.js
git commit -m "feat: orb rewards + star count"
```

---

### Task 3: Growth stages

**Files:**
- Modify: `kaiju-clash/progression.js`
- Test: `kaiju-clash/test/progression.test.js`

**Interfaces:**
- Produces:
  - `Progression.GROWTH_STAGES` — array of `{ key, name, minOrbs }`, ascending by `minOrbs`, length 5.
  - `Progression.stageForOrbs(totalOrbs) -> number` (index 0..4, highest stage whose `minOrbs <= totalOrbs`)

- [ ] **Step 1: Write the failing test**

Append to `kaiju-clash/test/progression.test.js`:

```js
test('GROWTH_STAGES has 5 named ascending stages', () => {
  assert.strictEqual(Progression.GROWTH_STAGES.length, 5);
  assert.deepStrictEqual(
    Progression.GROWTH_STAGES.map(s => s.key),
    ['hatchling', 'juvenile', 'adolescent', 'leviathan', 'apex']);
  for (let i = 1; i < Progression.GROWTH_STAGES.length; i++) {
    assert.ok(Progression.GROWTH_STAGES[i].minOrbs > Progression.GROWTH_STAGES[i - 1].minOrbs);
  }
});

test('stageForOrbs maps orb totals to stage index', () => {
  assert.strictEqual(Progression.stageForOrbs(0), 0);   // hatchling
  assert.strictEqual(Progression.stageForOrbs(149), 0);
  assert.strictEqual(Progression.stageForOrbs(150), 1); // juvenile
  assert.strictEqual(Progression.stageForOrbs(400), 2); // adolescent
  assert.strictEqual(Progression.stageForOrbs(750), 3); // leviathan
  assert.strictEqual(Progression.stageForOrbs(99999), 4); // apex (capped)
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Cannot read properties of undefined (reading 'length')`.

- [ ] **Step 3: Write minimal implementation**

In `kaiju-clash/progression.js`, add before the `module.exports` line:

```js
Progression.GROWTH_STAGES = [
  { key: 'hatchling',  name: 'Hatchling',  minOrbs: 0 },
  { key: 'juvenile',   name: 'Juvenile',   minOrbs: 150 },
  { key: 'adolescent', name: 'Adolescent', minOrbs: 400 },
  { key: 'leviathan',  name: 'Leviathan',  minOrbs: 750 },
  { key: 'apex',       name: 'Apex',       minOrbs: 1200 },
];

Progression.stageForOrbs = function stageForOrbs(totalOrbs) {
  let idx = 0;
  for (let i = 0; i < Progression.GROWTH_STAGES.length; i++) {
    if (totalOrbs >= Progression.GROWTH_STAGES[i].minOrbs) idx = i;
  }
  return idx;
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 12 tests passing.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/progression.js kaiju-clash/test/progression.test.js
git commit -m "feat: 5-stage growth thresholds (stageForOrbs)"
```

---

### Task 4: Meta state — default, serialize/deserialize, applyResult

**Files:**
- Modify: `kaiju-clash/progression.js`
- Test: `kaiju-clash/test/progression.test.js`

**Interfaces:**
- Consumes: `orbsForResult`, `starsForResult`, `stageForOrbs`
- Produces:
  - `Progression.defaultMeta() -> { version:1, orbs:0, growthStage:0, levels:{} }`
  - `Progression.serializeMeta(meta) -> string`
  - `Progression.deserializeMeta(str) -> meta` (returns `defaultMeta()` on null/parse-error/version-mismatch)
  - `Progression.applyResult(meta, { levelId, rank, citizensSaved, citizensTotal, sideQuestsDone }) -> meta` (pure; returns a NEW meta). Adds orbs, keeps best stars/rank for the level, recomputes `growthStage`. `meta.levels[levelId] = { stars, rank, sideQuestsDone }`.

- [ ] **Step 1: Write the failing test**

Append to `kaiju-clash/test/progression.test.js`:

```js
test('defaultMeta shape', () => {
  assert.deepStrictEqual(Progression.defaultMeta(),
    { version: 1, orbs: 0, growthStage: 0, levels: {} });
});

test('serialize/deserialize round-trips', () => {
  const m = Progression.defaultMeta();
  m.orbs = 320;
  const back = Progression.deserializeMeta(Progression.serializeMeta(m));
  assert.strictEqual(back.orbs, 320);
});

test('deserializeMeta falls back to default on garbage', () => {
  assert.deepStrictEqual(Progression.deserializeMeta('not json'), Progression.defaultMeta());
  assert.deepStrictEqual(Progression.deserializeMeta(null), Progression.defaultMeta());
  assert.deepStrictEqual(Progression.deserializeMeta('{"version":999}'), Progression.defaultMeta());
});

test('applyResult adds orbs, records level, recomputes growth stage', () => {
  let m = Progression.defaultMeta();
  m = Progression.applyResult(m, {
    levelId: 'w1l1', rank: 'S', citizensSaved: 8, citizensTotal: 8, sideQuestsDone: 1,
  });
  // orbs = orbsForResult(S,8,1) = 160
  assert.strictEqual(m.orbs, 160);
  assert.strictEqual(m.growthStage, 1); // 160 >= 150
  assert.strictEqual(m.levels['w1l1'].stars, 3);
  assert.strictEqual(m.levels['w1l1'].rank, 'S');
});

test('applyResult keeps best stars on replay, still adds orbs', () => {
  let m = Progression.defaultMeta();
  m = Progression.applyResult(m, { levelId: 'w1l1', rank: 'A', citizensSaved: 8, citizensTotal: 8, sideQuestsDone: 0 });
  const starsAfterFirst = m.levels['w1l1'].stars; // 3
  m = Progression.applyResult(m, { levelId: 'w1l1', rank: 'C', citizensSaved: 1, citizensTotal: 8, sideQuestsDone: 0 });
  assert.strictEqual(m.levels['w1l1'].stars, starsAfterFirst); // best kept (3 > 1)
  assert.strictEqual(m.levels['w1l1'].rank, 'A'); // best kept
});

test('applyResult does not mutate the input meta', () => {
  const m = Progression.defaultMeta();
  Progression.applyResult(m, { levelId: 'w1l1', rank: 'C', citizensSaved: 0, citizensTotal: 8, sideQuestsDone: 0 });
  assert.strictEqual(m.orbs, 0);
  assert.deepStrictEqual(m.levels, {});
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Progression.defaultMeta is not a function`.

- [ ] **Step 3: Write minimal implementation**

In `kaiju-clash/progression.js`, add before the `module.exports` line:

```js
const META_VERSION = 1;
const RANK_ORDER = { C: 0, B: 1, A: 2, S: 3 };

Progression.defaultMeta = function defaultMeta() {
  return { version: META_VERSION, orbs: 0, growthStage: 0, levels: {} };
};

Progression.serializeMeta = function serializeMeta(meta) {
  return JSON.stringify(meta);
};

Progression.deserializeMeta = function deserializeMeta(str) {
  if (!str) return Progression.defaultMeta();
  let parsed;
  try { parsed = JSON.parse(str); } catch (e) { return Progression.defaultMeta(); }
  if (!parsed || parsed.version !== META_VERSION) return Progression.defaultMeta();
  return parsed;
};

Progression.applyResult = function applyResult(meta, { levelId, rank, citizensSaved, citizensTotal, sideQuestsDone }) {
  const next = Progression.deserializeMeta(Progression.serializeMeta(meta)); // deep copy
  next.orbs += Progression.orbsForResult({ rank, citizensSaved, sideQuestsDone });
  const stars = Progression.starsForResult({ rank, citizensSaved, citizensTotal });
  const prev = next.levels[levelId];
  const bestStars = prev ? Math.max(prev.stars, stars) : stars;
  const bestRank = prev && RANK_ORDER[prev.rank] >= RANK_ORDER[rank] ? prev.rank : rank;
  next.levels[levelId] = { stars: bestStars, rank: bestRank, sideQuestsDone: sideQuestsDone };
  next.growthStage = Progression.stageForOrbs(next.orbs);
  return next;
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 18 tests passing.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/progression.js kaiju-clash/test/progression.test.js
git commit -m "feat: persistent meta state + applyResult"
```

---

### Task 5: Level registry + unlock logic

**Files:**
- Modify: `kaiju-clash/progression.js`
- Test: `kaiju-clash/test/progression.test.js`

**Interfaces:**
- Produces:
  - `Progression.LEVELS` — ordered array of `{ id, world, name, order, playable }`. World 1 has 4 entries; only `w1l1` has `playable: true` in this milestone (levels 2-4 are built in the World 1 content plan).
  - `Progression.isLevelUnlocked(meta, levelId) -> boolean`: the first level is always unlocked; a later level is unlocked only if it is `playable` AND the immediately-preceding level (by `order`) is recorded complete in `meta.levels`.
  - `Progression.nextLevelId(levelId) -> string|null` (next playable level by order, or null)

- [ ] **Step 1: Write the failing test**

Append to `kaiju-clash/test/progression.test.js`:

```js
test('LEVELS: world 1 has 4 ordered entries, only w1l1 playable now', () => {
  const w1 = Progression.LEVELS.filter(l => l.world === 1);
  assert.strictEqual(w1.length, 4);
  assert.strictEqual(w1[0].id, 'w1l1');
  assert.strictEqual(w1[0].playable, true);
  assert.strictEqual(w1[1].playable, false);
});

test('isLevelUnlocked: first level always unlocked', () => {
  assert.strictEqual(Progression.isLevelUnlocked(Progression.defaultMeta(), 'w1l1'), true);
});

test('isLevelUnlocked: locked when prior level incomplete', () => {
  assert.strictEqual(Progression.isLevelUnlocked(Progression.defaultMeta(), 'w1l2'), false);
});

test('isLevelUnlocked: non-playable stays locked even if prior complete', () => {
  let m = Progression.defaultMeta();
  m.levels['w1l1'] = { stars: 1, rank: 'C', sideQuestsDone: 0 };
  // w1l2 is not playable in this milestone
  assert.strictEqual(Progression.isLevelUnlocked(m, 'w1l2'), false);
});

test('nextLevelId returns next playable or null', () => {
  // w1l1 is the only playable level this milestone -> no next playable
  assert.strictEqual(Progression.nextLevelId('w1l1'), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd kaiju-clash && node --test`
Expected: FAIL — `Cannot read properties of undefined (reading 'filter')`.

- [ ] **Step 3: Write minimal implementation**

In `kaiju-clash/progression.js`, add before the `module.exports` line:

```js
Progression.LEVELS = [
  { id: 'w1l1', world: 1, name: 'Tokyo Streets', order: 1, playable: true },
  { id: 'w1l2', world: 1, name: 'Rooftop Run',   order: 2, playable: false },
  { id: 'w1l3', world: 1, name: 'Tower Climb',    order: 3, playable: false },
  { id: 'w1l4', world: 1, name: 'Riot Mecha',     order: 4, playable: false },
];

function levelById(id) { return Progression.LEVELS.find(l => l.id === id) || null; }

Progression.isLevelUnlocked = function isLevelUnlocked(meta, levelId) {
  const lvl = levelById(levelId);
  if (!lvl) return false;
  if (lvl.order === 1) return true;
  if (!lvl.playable) return false;
  const prev = Progression.LEVELS.find(l => l.world === lvl.world && l.order === lvl.order - 1);
  return !!(prev && meta.levels && meta.levels[prev.id]);
};

Progression.nextLevelId = function nextLevelId(levelId) {
  const lvl = levelById(levelId);
  if (!lvl) return null;
  const candidates = Progression.LEVELS
    .filter(l => l.playable && (l.world > lvl.world || (l.world === lvl.world && l.order > lvl.order)))
    .sort((a, b) => (a.world - b.world) || (a.order - b.order));
  return candidates.length ? candidates[0].id : null;
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 23 tests passing.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/progression.js kaiju-clash/test/progression.test.js
git commit -m "feat: level registry + unlock logic"
```

---

### Task 6: Wire progression.js into the browser + registry-driven level loader

**Files:**
- Modify: `kaiju-clash/index.html` (script include near top of `<body>`; `mkState`; the `LEVEL DATA` builders region ~lines 268-343; meta load on boot)

**Interfaces:**
- Consumes: the `Progression` global (all of Tasks 1-5).
- Produces:
  - Global `let meta` loaded from localStorage on boot.
  - `function saveMeta()` — writes `meta` to `localStorage['kaiju_meta']`.
  - `const LEVEL_BUILDERS = { w1l1: () => ({ tiles, food, enemies, citizens }) }` — registry keyed by level id.
  - `mkState(charKey, levelId)` — now takes a level id and builds via `LEVEL_BUILDERS[levelId]`. Adds `s.levelId`, `s.startTick`, `s.hitsTaken` fields.

- [ ] **Step 1: Add the script include**

In `kaiju-clash/index.html`, find the main inline game script tag (the large `<script>` that begins the game code). Immediately BEFORE it, add:

```html
<script src="progression.js"></script>
```

Verify ordering: open the file and confirm `<script src="progression.js"></script>` appears before the inline `<script>` containing `const TS = 32;`.

- [ ] **Step 2: Add meta load + saveMeta near the GAME STATE section**

In `index.html`, find the `GAME STATE` block (around line 345-351, the `let scene = 'select';` line). Add directly below `let state = null;`:

```js
// ── Persistent meta-progression (Spirit Orbs, growth stage, per-level stars) ──
let meta = Progression.deserializeMeta(
  (typeof localStorage !== 'undefined') ? localStorage.getItem('kaiju_meta') : null);
function saveMeta(){
  try { localStorage.setItem('kaiju_meta', Progression.serializeMeta(meta)); } catch (e) {}
}
```

- [ ] **Step 3: Wrap the existing builders into a registry**

In `index.html`, the functions `buildLevel()`, `spawnFood()`, `spawnEnemies()`, `spawnCitizens()` already exist (lines ~274-343). Leave them as-is. Directly AFTER `spawnCitizens()` (after its closing `}` near line 343), add:

```js
// Level registry: maps a Progression.LEVELS id to a concrete level builder.
// World 1 levels 2-4 are added in the World 1 content plan.
const LEVEL_BUILDERS = {
  w1l1: () => ({
    tiles:    buildLevel(),
    food:     spawnFood(),
    enemies:  spawnEnemies(),
    citizens: spawnCitizens(),
  }),
};
```

- [ ] **Step 4: Make mkState take a levelId and build from the registry**

In `index.html`, replace the existing `mkState(charKey)` function (lines ~353-379) with:

```js
function mkState(charKey, levelId){
  const build = (LEVEL_BUILDERS[levelId] || LEVEL_BUILDERS.w1l1)();
  return {
    charKey,
    levelId,
    player: {
      x: 2*TS, y: 7*TS,
      vx:0, vy:0,
      onGround:false,
      dir:1,
      hp: charKey==='poppy' ? 80 : 100,
      maxHp: charKey==='poppy' ? 80 : 100,
      fartMeter:0,
      invincMs:0,
      eatAnim:0,
      fartAnim:0,
      jumpPressed:false,
    },
    level:    build,
    cam:      { x:0, y:0 },
    score:    0,
    savedCitizens: 0,
    lostCitizens:  0,
    hitsTaken: 0,
    startTick: 0,
    msgs:     [],
    dmgNums:  [],
    fartCloud:null,
    tick:     0,
  };
}
```

- [ ] **Step 5: Fix existing mkState call sites to pass a level id**

In `index.html`, find every `mkState(SEL_CHARS[selIdx])` call (lines ~1605, 1625, 1675, 1685 per current grep). Replace each occurrence of `mkState(SEL_CHARS[selIdx])` with `mkState(SEL_CHARS[selIdx], 'w1l1')`.

Run: `cd kaiju-clash && grep -n "mkState(SEL_CHARS\[selIdx\])" index.html`
Expected: no matches (all updated).

- [ ] **Step 6: Manual browser verification**

Run: `cd kaiju-clash && python3 -m http.server 8000`
Open `http://localhost:8000/` in a browser. Open DevTools console.
Expected:
- No console errors (especially no `Progression is not defined`).
- Type `Progression.LEVELS.length` in console → `4`.
- Type `meta` in console → object `{version:1, orbs:0, growthStage:0, levels:{}}`.
- Pick a character and play — the level loads and plays exactly as before (this task is a no-behavior-change refactor).

- [ ] **Step 7: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "refactor: registry-driven level loader + meta load wiring"
```

---

### Task 7: Overworld scene (level select)

**Files:**
- Modify: `kaiju-clash/index.html` (scene flow; add `updateOverworld()` + `drawOverworld()`; route character-select to overworld)

**Interfaces:**
- Consumes: `Progression.LEVELS`, `Progression.isLevelUnlocked`, `meta`, `mkState`, existing `VW`/`VH`, input helpers `wasDown`/`isMoveL`/`isMoveR`/`isJump`/`touchInBtn`, `drawBg`.
- Produces:
  - Global `let owIdx = 0;` (highlighted level node index into `Progression.LEVELS`).
  - `function updateOverworld()` — left/right moves `owIdx` across nodes; jump/confirm on an unlocked playable node sets `state = mkState(SEL_CHARS[selIdx], id); scene='playing';`.
  - `function drawOverworld()` — draws the 4 world-1 nodes left-to-right with name, lock icon if locked, star pips from `meta.levels[id].stars`, and highlights `owIdx`.
  - New scene value `'overworld'` reachable from character select and returned to from victory/gameover.

- [ ] **Step 1: Route character-select confirm into the overworld**

In `index.html`, the character-select confirm currently does `state=mkState(...); scene='playing';` (lines ~1675/1685 inside the `scene==='select'` update branch). Replace those two select-branch transitions so they set `scene='overworld';` instead of building state and going to playing. Concretely, within the `if(scene==='select'){ ... }` block, change each `state=mkState(SEL_CHARS[selIdx], 'w1l1'); scene='playing';` to:

```js
scene='overworld'; owIdx=0;
```

(Leave the character-select left/right `selIdx` logic untouched.)

- [ ] **Step 2: Declare owIdx near the other scene globals**

In `index.html`, just below `let selIdx = 0;` (line ~349) add:

```js
let owIdx = 0; // highlighted node in the overworld
```

- [ ] **Step 3: Implement updateOverworld + drawOverworld**

In `index.html`, add these two functions near the other scene update/draw functions (e.g. just above the main `loop` function near line 1730):

```js
function updateOverworld(){
  const nodes = Progression.LEVELS;
  if(wasDown('ArrowRight','KeyD') || touchInBtn('right')) owIdx = Math.min(nodes.length-1, owIdx+1);
  if(wasDown('ArrowLeft','KeyA')  || touchInBtn('left'))  owIdx = Math.max(0, owIdx-1);
  const sel = nodes[owIdx];
  const unlocked = Progression.isLevelUnlocked(meta, sel.id);
  if((isFart() || wasDown('Space','ArrowUp','KeyW','Enter') || touchInBtn('jump')) && unlocked && sel.playable){
    state = mkState(SEL_CHARS[selIdx], sel.id);
    scene = 'playing';
  }
}

function drawOverworld(){
  ctx.fillStyle='#1b1030'; ctx.fillRect(0,0,VW,VH);
  ctx.textAlign='center';
  ctx.fillStyle='#ffd84a'; ctx.font='bold 28px monospace';
  ctx.fillText('KAIJU KID’S QUEST', VW/2, 48);
  ctx.font='14px monospace'; ctx.fillStyle='#cfc6e6';
  ctx.fillText('Spirit Orbs: '+meta.orbs+'   Growth: '+Progression.GROWTH_STAGES[meta.growthStage].name, VW/2, 74);

  const nodes = Progression.LEVELS;
  const gap = VW/(nodes.length+1);
  const cy = VH/2;
  for(let i=0;i<nodes.length;i++){
    const n = nodes[i];
    const cx = gap*(i+1);
    const unlocked = Progression.isLevelUnlocked(meta, n.id);
    // connector
    if(i>0){ ctx.strokeStyle='#4a3a66'; ctx.lineWidth=4; ctx.beginPath(); ctx.moveTo(gap*i, cy); ctx.lineTo(cx, cy); ctx.stroke(); }
    // node circle
    ctx.beginPath(); ctx.arc(cx, cy, 26, 0, Math.PI*2);
    ctx.fillStyle = unlocked ? '#ff6db0' : '#3a2f50';
    ctx.fill();
    if(i===owIdx){ ctx.strokeStyle='#fff'; ctx.lineWidth=3; ctx.stroke(); }
    // number / lock
    ctx.fillStyle = unlocked ? '#2a0c1c' : '#9a8fb5';
    ctx.font='bold 20px monospace';
    ctx.fillText(unlocked ? String(i+1) : '🔒', cx, cy+7);
    // name
    ctx.fillStyle = unlocked ? '#fff' : '#7d7299';
    ctx.font='12px monospace';
    ctx.fillText(n.name, cx, cy+50);
    // stars
    const rec = meta.levels[n.id];
    if(rec){
      ctx.fillStyle='#ffd84a'; ctx.font='14px monospace';
      ctx.fillText('★'.repeat(rec.stars), cx, cy-40);
    }
  }
  ctx.fillStyle='#cfc6e6'; ctx.font='12px monospace';
  ctx.fillText('← → choose   ↑/Space enter', VW/2, VH-24);
  ctx.textAlign='left';
}
```

- [ ] **Step 4: Dispatch the overworld scene in the main update + draw**

In `index.html`, find the main per-frame update/draw dispatch (the block around lines 1669-1726 that branches on `scene==='select'`, `scene==='playing'`, etc.).

Add an update branch alongside the others (e.g. after the `scene==='select'` update branch):

```js
  if(scene==='overworld'){ updateOverworld(); }
```

Add a draw branch alongside the other draw branches (near line 1725, beside the victory/gameover draws):

```js
  if(scene==='overworld'){ drawOverworld(); }
```

- [ ] **Step 5: Manual browser verification**

Run: `cd kaiju-clash && python3 -m http.server 8000` and open `http://localhost:8000/`.
Expected:
- Pick a character, confirm → the **overworld** appears titled "KAIJU KID'S QUEST" with 4 nodes.
- Node 1 (Tokyo Streets) is pink/unlocked; nodes 2-4 show a 🔒 lock.
- `←/→` moves the white highlight ring between nodes.
- Pressing `Space`/`↑` on node 1 starts the level; pressing it on a locked node does nothing.
- Header shows `Spirit Orbs: 0   Growth: Hatchling`.

- [ ] **Step 6: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: overworld level-select scene"
```

---

### Task 8: Victory = rank + reward + persist + return to overworld

**Files:**
- Modify: `kaiju-clash/index.html` (victory transition; `drawVictory`; track `hitsTaken` and `startTick`; result-applied guard)

**Interfaces:**
- Consumes: `Progression.computeRank`, `Progression.applyResult`, `meta`, `saveMeta`, `state.levelId`, `state.savedCitizens`, `state.level.citizens.length`, `state.tick`, `state.startTick`, `state.hitsTaken`.
- Produces:
  - On entering `victory`, exactly once, compute rank, call `applyResult`, `saveMeta()`, and stash a `lastResult` object for display.
  - Global `let lastResult = null; // { rank, orbsEarned, stars, levelId }`.
  - `drawVictory()` shows rank letter, citizens saved, time, orbs earned, and a "press to continue" that returns to `scene='overworld'`.

- [ ] **Step 1: Record startTick and count hits**

In `index.html`, set the run start time when a level begins. In `mkState` (Task 6) `startTick` is already initialized to 0; instead capture it at play start. Find each place that sets `scene='playing'` after building state (in `updateOverworld`, Task 7). Immediately after `scene='playing';` in `updateOverworld`, add:

```js
    state.startTick = state.tick;
```

For hit counting: locate where the player takes damage. Search:

Run: `cd kaiju-clash && grep -n "player.hp" index.html`

Find the spot(s) where `s.player.hp -= ...` (player loses HP from an enemy). At each such damage application that is gated by `invincMs<=0`, increment hits. Add immediately after the HP subtraction line:

```js
      s.hitsTaken++;
```

(If there are multiple damage sources, add it after each. If `hitsTaken` is undefined on an older state, it is initialized in `mkState`.)

- [ ] **Step 2: Compute the result once on victory**

In `index.html`, there are two places that set `scene='victory'` (lines ~479 and ~556). Replace each bare `scene='victory'; sndVictory();` with a call to a single helper `finishLevel()`:

```js
finishLevel();
```

Then add the `finishLevel` helper near `mkState` / the scene helpers:

```js
function finishLevel(){
  if(scene==='victory') return; // already finished
  const s = state;
  const total = s.level.citizens.length;
  const timeSec = Math.max(0, Math.round((s.tick - s.startTick)/60));
  const rank = Progression.computeRank({
    timeSec, hitsTaken: s.hitsTaken, citizensSaved: s.savedCitizens, citizensTotal: total,
  });
  const before = meta.orbs;
  meta = Progression.applyResult(meta, {
    levelId: s.levelId, rank, citizensSaved: s.savedCitizens, citizensTotal: total, sideQuestsDone: 0,
  });
  saveMeta();
  lastResult = {
    rank,
    orbsEarned: meta.orbs - before,
    stars: meta.levels[s.levelId].stars,
    timeSec,
    saved: s.savedCitizens,
    total,
  };
  scene='victory'; sndVictory();
}
```

- [ ] **Step 2b: Declare lastResult**

Below `let state = null;` (or near the other scene globals), add:

```js
let lastResult = null; // populated by finishLevel(), shown on the victory screen
```

- [ ] **Step 3: Rewrite drawVictory to show the rank card**

In `index.html`, find the existing `drawVictory()` function (referenced near line 1725; search `function drawVictory`). Replace its body with:

```js
function drawVictory(){
  ctx.fillStyle='rgba(8,4,20,0.78)'; ctx.fillRect(0,0,VW,VH);
  ctx.textAlign='center';
  ctx.fillStyle='#7CFF8A'; ctx.font='bold 34px monospace';
  ctx.fillText('LEVEL CLEAR!', VW/2, VH/2-90);
  if(lastResult){
    ctx.fillStyle='#ffd84a'; ctx.font='bold 72px monospace';
    ctx.fillText('RANK '+lastResult.rank, VW/2, VH/2-18);
    ctx.fillStyle='#fff'; ctx.font='16px monospace';
    ctx.fillText('★'.repeat(lastResult.stars)+'☆'.repeat(3-lastResult.stars), VW/2, VH/2+14);
    ctx.fillText('Citizens saved: '+lastResult.saved+' / '+lastResult.total, VW/2, VH/2+40);
    ctx.fillText('Time: '+lastResult.timeSec+'s', VW/2, VH/2+62);
    ctx.fillStyle='#7CD7FF';
    ctx.fillText('+'+lastResult.orbsEarned+' Spirit Orbs  (total '+meta.orbs+')', VW/2, VH/2+88);
  }
  ctx.fillStyle='#cfc6e6'; ctx.font='13px monospace';
  ctx.fillText('Press Space / tap to continue', VW/2, VH-30);
  ctx.textAlign='left';
}
```

- [ ] **Step 4: Make victory advance back to the overworld**

In `index.html`, find the victory-scene update handling (where pressing a key after victory currently restarts — near the `scene==='victory'` handling / the lines ~1605-1625 that rebuild state). Replace the victory continue-handler so a confirm press returns to the overworld:

```js
  if(scene==='victory'){
    if(wasDown('Space','Enter','ArrowUp','KeyW') || _lastTouchCount>0){
      scene='overworld';
    }
  }
```

Place this in the per-frame update dispatch beside the other scene branches. Ensure no other code in the same frame immediately rebuilds state for victory (remove/replace the old victory restart lines at ~1605 and ~1625 if they conflict — the only victory transition now is to `overworld`).

- [ ] **Step 5: Manual browser verification**

Run: `cd kaiju-clash && python3 -m http.server 8000` and open `http://localhost:8000/`.
Expected:
- Play level 1 to the end (reach the right side OR save all citizens).
- A **RANK** card appears: big letter (S/A/B/C), star row, citizens saved, time, and `+N Spirit Orbs (total N)`.
- Press Space → returns to the **overworld**.
- The overworld header orb count increased; node 1 now shows star pips.
- Reload the page (F5) → orbs and stars persist (loaded from localStorage). Confirm in console: `meta.orbs` > 0.

- [ ] **Step 6: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: rank + orb reward screen, persisted, returns to overworld"
```

---

### Task 9: Game-over returns to overworld + growth/orb HUD readout

**Files:**
- Modify: `kaiju-clash/index.html` (`gameover` continue handler; in-level HUD draw)

**Interfaces:**
- Consumes: `meta`, `Progression.GROWTH_STAGES`, existing HUD draw code, `drawGameover`.
- Produces:
  - Game-over confirm returns to `scene='overworld'` (no progress recorded — a loss earns nothing).
  - The in-level HUD shows current growth-stage name + total orbs in a corner.

- [ ] **Step 1: Game-over returns to the overworld**

In `index.html`, find the `gameover` continue handling (near the same scene-update dispatch; current restart lives around lines 1605-1625). Replace it so a confirm press goes to the overworld:

```js
  if(scene==='gameover'){
    if(wasDown('Space','Enter','ArrowUp','KeyW') || _lastTouchCount>0){
      scene='overworld';
    }
  }
```

- [ ] **Step 2: Add growth/orb readout to the in-level HUD**

In `index.html`, find the in-level HUD drawing (search for where the score/`SAVED` HUD text is drawn during `scene==='playing'` — e.g. the `drawHUD` function or the score draw near line 1598/1510). At the end of that HUD draw, add:

```js
  ctx.save();
  ctx.textAlign='right'; ctx.font='12px monospace'; ctx.fillStyle='#7CD7FF';
  ctx.fillText('◈ '+meta.orbs+'  '+Progression.GROWTH_STAGES[meta.growthStage].name, VW-12, VH-12);
  ctx.restore();
```

- [ ] **Step 3: Manual browser verification**

Run: `cd kaiju-clash && python3 -m http.server 8000` and open `http://localhost:8000/`.
Expected:
- During play, the bottom-right HUD shows `◈ <orbs>  <StageName>` (e.g. `◈ 0  Hatchling`, or higher after clears).
- Lose a level (let 3 citizens be eaten or HP reach 0) → game-over screen → press Space → returns to overworld with **no** orb gain recorded for the loss.

- [ ] **Step 4: Run the full automated suite one more time**

Run: `cd kaiju-clash && node --test`
Expected: PASS — 23 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add kaiju-clash/index.html
git commit -m "feat: gameover returns to overworld + growth/orb HUD"
```

---

## What this milestone delivers

A complete, testable progression skeleton: character select → **overworld** → play a registry-loaded level → **rank + Spirit Orb reward** → persisted to localStorage → back to the overworld with stars and growth-stage progress. World 1 levels 2-4 + the Riot Mecha boss, the NPC hub, and visible sprite growth are follow-on plans that plug into this spine (`LEVEL_BUILDERS`, `Progression.LEVELS`, `meta.growthStage`).

## Follow-on plans (not in scope here)
- **World 1 content:** build `w1l2`/`w1l3`/`w1l4` builders + flip them `playable`, add the Riot Mecha boss level.
- **Living NPCs + hub town:** hub scene, NPC shops, second currency (Yen/coins), side-quest hooks (`sideQuestsDone` is already plumbed through `applyResult`).
- **Visible growth:** scale/swap the player sprite by `meta.growthStage`; wire the §4a art (Lulah/Poppy growth sheets) in.
- **Worlds 2-4 + bosses + two endings.**
