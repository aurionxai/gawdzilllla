# Kaiju Clash Backend API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Kaiju Clash backend — a Fastify + Prisma + Postgres service on Railway providing player handles, score leaderboards, opt-in email signups, and play analytics — built and tested independently of the game client.

**Architecture:** A standalone Node service in `backend/`. Fastify serves JSON routes; Prisma is the ORM over Postgres. Route handlers are thin and delegate to small testable service functions. Tests use Fastify's `app.inject()` (in-process HTTP, no network) against a dedicated **test Postgres database** reset between runs. The game client integration (`api.js`) is a follow-on plan that depends on the progression spine; this plan stops at a deployed, tested API.

**Tech Stack:** Node v24, Fastify 4, Prisma 5, PostgreSQL 16, `node --test` + `app.inject()` for tests. Railway for Postgres + service hosting.

## Global Constraints

- Service lives entirely under `backend/` — it does not touch `kaiju-clash/`.
- Identity = handle + secret `token` (UUID) bearer; NO passwords, NO sessions. Writes require `Authorization: Bearer <token>`; `POST /players` and `GET /leaderboard` and `GET /healthz` are unauthenticated.
- Data model matches the spec (`docs/superpowers/specs/2026-06-19-kaiju-clash-backend-design.md` §4) exactly: models `Player`, `Score`, `Event` with the listed fields and indexes.
- `levelId` allowlist mirrors the progression spine's `Progression.LEVELS` ids: `['w1l1','w1l2','w1l3','w1l4']`. Reject any other `levelId`.
- `rank` ∈ `{'S','A','B','C'}`. `score`, `timeSec`, `citizensSaved` are non-negative integers; reject values above sane caps: `score ≤ 1_000_000`, `timeSec ≤ 86_400`, `citizensSaved ≤ 999`.
- Email capture must record consent: `PATCH /players/:id` with `consent:true` sets `consentAt`; without consent, `marketingOptIn` MUST stay false. (COPPA: audience includes under-13.)
- CORS allows origins: `https://lemon-vista-573.higgsfield.gg`, `http://localhost:8000`.
- Two databases: `DATABASE_URL` (dev/prod) and `TEST_DATABASE_URL` (tests). Tests must never run against the prod DB.
- Run tests: `cd backend && npm test`. All green before each commit.
- Commit after every task.

---

### Task 1: Project scaffold + Prisma schema + healthz

**Files:**
- Create: `backend/package.json`, `backend/.gitignore`, `backend/.env.example`
- Create: `backend/prisma/schema.prisma`
- Create: `backend/src/app.js` (Fastify app factory), `backend/src/server.js` (listen entrypoint)
- Test: `backend/test/health.test.js`

**Interfaces:**
- Produces: `buildApp({ prisma }) -> FastifyInstance` (exported from `src/app.js`); `GET /healthz -> 200 { ok: true }`.

- [ ] **Step 1: Create package.json**

`backend/package.json`:

```json
{
  "name": "kaiju-clash-backend",
  "version": "0.1.0",
  "private": true,
  "type": "commonjs",
  "scripts": {
    "test": "node --test",
    "dev": "node src/server.js",
    "start": "node src/server.js",
    "prisma:generate": "prisma generate",
    "migrate:dev": "prisma migrate dev",
    "migrate:deploy": "prisma migrate deploy"
  },
  "dependencies": {
    "@fastify/cors": "^9.0.1",
    "@prisma/client": "^5.18.0",
    "fastify": "^4.28.1"
  },
  "devDependencies": {
    "prisma": "^5.18.0"
  }
}
```

`backend/.gitignore`:

```
node_modules/
.env
.env.test
```

`backend/.env.example`:

```
DATABASE_URL="postgresql://USER:PASS@HOST:5432/kaiju?schema=public"
TEST_DATABASE_URL="postgresql://USER:PASS@HOST:5432/kaiju_test?schema=public"
PORT=3000
```

- [ ] **Step 2: Create the Prisma schema**

`backend/prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Player {
  id             String    @id @default(uuid())
  handle         String
  token          String    @unique @default(uuid())
  email          String?
  marketingOptIn Boolean   @default(false)
  consentAt      DateTime?
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
  scores         Score[]
  events         Event[]

  @@index([handle])
}

model Score {
  id            String   @id @default(uuid())
  player        Player   @relation(fields: [playerId], references: [id])
  playerId      String
  levelId       String
  score         Int
  rank          String
  timeSec       Int
  citizensSaved Int
  createdAt     DateTime @default(now())

  @@index([levelId, score(sort: Desc)])
  @@index([playerId])
}

model Event {
  id        String   @id @default(uuid())
  player    Player?  @relation(fields: [playerId], references: [id])
  playerId  String?
  type      String
  levelId   String?
  data      Json?
  createdAt DateTime @default(now())

  @@index([type, createdAt])
}
```

- [ ] **Step 3: Create the app factory + server**

`backend/src/app.js`:

```js
const Fastify = require('fastify');
const cors = require('@fastify/cors');

const CORS_ORIGINS = [
  'https://lemon-vista-573.higgsfield.gg',
  'http://localhost:8000',
];

// buildApp lets tests inject a Prisma client and call routes via app.inject().
function buildApp({ prisma }) {
  const app = Fastify({ logger: false });
  app.register(cors, { origin: CORS_ORIGINS });
  app.decorate('prisma', prisma);

  app.get('/healthz', async () => ({ ok: true }));

  return app;
}

module.exports = { buildApp, CORS_ORIGINS };
```

`backend/src/server.js`:

```js
const { PrismaClient } = require('@prisma/client');
const { buildApp } = require('./app');

const prisma = new PrismaClient();
const app = buildApp({ prisma });
const port = Number(process.env.PORT) || 3000;

app.listen({ port, host: '0.0.0.0' })
  .then(() => console.log(`kaiju-clash-backend listening on ${port}`))
  .catch((err) => { console.error(err); process.exit(1); });
```

- [ ] **Step 4: Write the failing test**

`backend/test/health.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { buildApp } = require('../src/app');

test('GET /healthz returns ok', async () => {
  const app = buildApp({ prisma: {} }); // healthz needs no DB
  const res = await app.inject({ method: 'GET', url: '/healthz' });
  assert.strictEqual(res.statusCode, 200);
  assert.deepStrictEqual(res.json(), { ok: true });
  await app.close();
});
```

- [ ] **Step 5: Install deps, generate client, run the test**

```bash
cd backend && npm install && npx prisma generate && npm test
```

Expected: `npm install` succeeds, `prisma generate` creates the client, test PASSES (1 test). If `prisma generate` requires `DATABASE_URL`, copy `.env.example` to `.env` and set a placeholder URL — generate does not connect.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): scaffold Fastify+Prisma service + healthz"
```

---

### Task 2: Test harness + migrations against a test database

**Files:**
- Create: `backend/test/helpers/db.js` (test Prisma client + table reset)
- Create: `backend/test/db.test.js`
- Modify: `backend/package.json` (add `migrate:test` script)

**Interfaces:**
- Produces: `makeTestApp() -> { app, prisma, reset }` — builds an app wired to a Prisma client pointed at `TEST_DATABASE_URL`; `reset()` truncates all tables.

- [ ] **Step 1: Add a test migration script**

In `backend/package.json` scripts, add:

```json
    "migrate:test": "dotenv -e .env.test -- prisma migrate deploy",
```

Note: if `dotenv-cli` is not desired, the test helper sets `DATABASE_URL` from `TEST_DATABASE_URL` in-process instead (Step 2 does this). The script is a convenience; the helper is the source of truth.

- [ ] **Step 2: Create the test DB helper**

`backend/test/helpers/db.js`:

```js
// Points Prisma at the TEST database and provides a table reset.
// Requires TEST_DATABASE_URL to be set; never touches the prod DATABASE_URL.
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
if (!process.env.DATABASE_URL) {
  throw new Error('TEST_DATABASE_URL must be set to run tests');
}
const { PrismaClient } = require('@prisma/client');
const { buildApp } = require('../../src/app');

const prisma = new PrismaClient();

async function reset() {
  // Truncate in FK-safe order; RESTART IDENTITY + CASCADE clears everything.
  await prisma.$executeRawUnsafe('TRUNCATE TABLE "Event","Score","Player" RESTART IDENTITY CASCADE');
}

function makeTestApp() {
  const app = buildApp({ prisma });
  return { app, prisma, reset };
}

module.exports = { makeTestApp, prisma, reset };
```

- [ ] **Step 3: Write the failing test**

`backend/test/db.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { makeTestApp } = require('./helpers/db');

test('test database is reachable and resettable', async () => {
  const { prisma, reset } = makeTestApp();
  await reset();
  const count = await prisma.player.count();
  assert.strictEqual(count, 0);
});
```

- [ ] **Step 4: Prepare the test DB and run**

```bash
cd backend
cp .env.example .env.test   # then edit .env.test: set TEST_DATABASE_URL to a real empty Postgres
# apply the schema to the test DB:
DATABASE_URL="$TEST_DATABASE_URL" npx prisma migrate dev --name init
# run tests with the test URL exported:
export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: a migration `init` is created under `backend/prisma/migrations/`, and `db.test.js` PASSES (player count 0). The `health.test.js` test still passes.

- [ ] **Step 5: Commit**

```bash
git add backend/
git commit -m "feat(backend): test DB harness + initial migration"
```

---

### Task 3: Players — create + auth middleware + profile

**Files:**
- Create: `backend/src/routes/players.js`
- Create: `backend/src/auth.js` (bearer-token lookup)
- Modify: `backend/src/app.js` (register players routes)
- Test: `backend/test/players.test.js`

**Interfaces:**
- Consumes: `app.prisma`.
- Produces:
  - `POST /players { handle } -> 201 { playerId, token }`
  - `requirePlayer(app)` preHandler: reads `Authorization: Bearer <token>`, looks up the player, sets `req.player`; `401` if missing/invalid.
  - `GET /players/:id` (auth; token must match the :id player) `-> 200 { handle, email, marketingOptIn }`

- [ ] **Step 1: Write the failing test**

`backend/test/players.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { makeTestApp } = require('./helpers/db');

test('POST /players creates a player with handle and token', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const res = await app.inject({ method: 'POST', url: '/players', payload: { handle: 'Rex' } });
  assert.strictEqual(res.statusCode, 201);
  const body = res.json();
  assert.ok(body.playerId);
  assert.ok(body.token);
  await app.close();
});

test('POST /players rejects empty handle', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const res = await app.inject({ method: 'POST', url: '/players', payload: { handle: '' } });
  assert.strictEqual(res.statusCode, 400);
  await app.close();
});

test('GET /players/:id with valid token returns profile', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const made = (await app.inject({ method: 'POST', url: '/players', payload: { handle: 'Rex' } })).json();
  const res = await app.inject({
    method: 'GET', url: `/players/${made.playerId}`,
    headers: { authorization: `Bearer ${made.token}` },
  });
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.json().handle, 'Rex');
  await app.close();
});

test('GET /players/:id without token is 401', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const made = (await app.inject({ method: 'POST', url: '/players', payload: { handle: 'Rex' } })).json();
  const res = await app.inject({ method: 'GET', url: `/players/${made.playerId}` });
  assert.strictEqual(res.statusCode, 401);
  await app.close();
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd backend && export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: FAIL — `POST /players` returns 404 (route not registered).

- [ ] **Step 3: Implement auth + players routes**

`backend/src/auth.js`:

```js
// Bearer-token auth: resolves the player from Authorization header.
function bearerToken(req) {
  const h = req.headers['authorization'] || '';
  const m = /^Bearer\s+(.+)$/i.exec(h);
  return m ? m[1] : null;
}

function requirePlayer(app) {
  return async function (req, reply) {
    const token = bearerToken(req);
    if (!token) return reply.code(401).send({ error: 'missing token' });
    const player = await app.prisma.player.findUnique({ where: { token } });
    if (!player) return reply.code(401).send({ error: 'invalid token' });
    req.player = player;
  };
}

module.exports = { bearerToken, requirePlayer };
```

`backend/src/routes/players.js`:

```js
const { requirePlayer } = require('../auth');

async function playerRoutes(app) {
  app.post('/players', async (req, reply) => {
    const handle = (req.body && typeof req.body.handle === 'string') ? req.body.handle.trim() : '';
    if (!handle || handle.length > 24) return reply.code(400).send({ error: 'invalid handle' });
    const player = await app.prisma.player.create({ data: { handle } });
    return reply.code(201).send({ playerId: player.id, token: player.token });
  });

  app.get('/players/:id', { preHandler: requirePlayer(app) }, async (req, reply) => {
    if (req.player.id !== req.params.id) return reply.code(403).send({ error: 'forbidden' });
    const { handle, email, marketingOptIn } = req.player;
    return reply.send({ handle, email, marketingOptIn });
  });
}

module.exports = playerRoutes;
```

- [ ] **Step 4: Register the routes**

In `backend/src/app.js`, inside `buildApp`, after the `/healthz` route add:

```js
  app.register(require('./routes/players'));
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd backend && export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: PASS — all players tests + prior tests green.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): player create + bearer auth + profile"
```

---

### Task 4: Scores + leaderboard with validation

**Files:**
- Create: `backend/src/validate.js` (shared score validation + level allowlist)
- Create: `backend/src/routes/scores.js`
- Modify: `backend/src/app.js` (register scores routes)
- Test: `backend/test/scores.test.js`, `backend/test/validate.test.js`

**Interfaces:**
- Consumes: `requirePlayer`, `app.prisma`.
- Produces:
  - `validateScore({ levelId, score, rank, timeSec, citizensSaved }) -> { ok:true } | { ok:false, error }` (pure).
  - `LEVEL_IDS = ['w1l1','w1l2','w1l3','w1l4']`.
  - `POST /scores` (auth) `{ levelId, score, rank, timeSec, citizensSaved } -> 201 { id }`.
  - `GET /leaderboard?levelId=&limit= -> 200 [{ handleTag, score, rank, timeSec }]` (top by score desc; default limit 20, max 100).

- [ ] **Step 1: Write the failing validation test (pure)**

`backend/test/validate.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { validateScore } = require('../src/validate');

const good = { levelId: 'w1l1', score: 1200, rank: 'A', timeSec: 90, citizensSaved: 8 };

test('validateScore accepts a good payload', () => {
  assert.strictEqual(validateScore(good).ok, true);
});

test('validateScore rejects unknown levelId', () => {
  assert.strictEqual(validateScore({ ...good, levelId: 'zzz' }).ok, false);
});

test('validateScore rejects bad rank', () => {
  assert.strictEqual(validateScore({ ...good, rank: 'Z' }).ok, false);
});

test('validateScore rejects negative score', () => {
  assert.strictEqual(validateScore({ ...good, score: -5 }).ok, false);
});

test('validateScore rejects absurd score', () => {
  assert.strictEqual(validateScore({ ...good, score: 9_999_999 }).ok, false);
});
```

- [ ] **Step 2: Implement validate.js (make it pass)**

`backend/src/validate.js`:

```js
const LEVEL_IDS = ['w1l1', 'w1l2', 'w1l3', 'w1l4'];
const RANKS = ['S', 'A', 'B', 'C'];
const CAPS = { score: 1_000_000, timeSec: 86_400, citizensSaved: 999 };

function isNonNegInt(v, cap) {
  return Number.isInteger(v) && v >= 0 && v <= cap;
}

function validateScore({ levelId, score, rank, timeSec, citizensSaved }) {
  if (!LEVEL_IDS.includes(levelId)) return { ok: false, error: 'bad levelId' };
  if (!RANKS.includes(rank)) return { ok: false, error: 'bad rank' };
  if (!isNonNegInt(score, CAPS.score)) return { ok: false, error: 'bad score' };
  if (!isNonNegInt(timeSec, CAPS.timeSec)) return { ok: false, error: 'bad timeSec' };
  if (!isNonNegInt(citizensSaved, CAPS.citizensSaved)) return { ok: false, error: 'bad citizensSaved' };
  return { ok: true };
}

module.exports = { validateScore, LEVEL_IDS, RANKS };
```

Run: `cd backend && export $(grep TEST_DATABASE_URL .env.test) && node --test test/validate.test.js`
Expected: PASS — 5 validation tests.

- [ ] **Step 3: Write the failing route test**

`backend/test/scores.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { makeTestApp } = require('./helpers/db');

async function newPlayer(app, handle) {
  return (await app.inject({ method: 'POST', url: '/players', payload: { handle } })).json();
}

test('POST /scores stores a score (auth) and leaderboard returns it', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const p = await newPlayer(app, 'Rex');
  const res = await app.inject({
    method: 'POST', url: '/scores',
    headers: { authorization: `Bearer ${p.token}` },
    payload: { levelId: 'w1l1', score: 5000, rank: 'S', timeSec: 70, citizensSaved: 8 },
  });
  assert.strictEqual(res.statusCode, 201);

  const lb = await app.inject({ method: 'GET', url: '/leaderboard?levelId=w1l1' });
  assert.strictEqual(lb.statusCode, 200);
  const rows = lb.json();
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].score, 5000);
  assert.ok(rows[0].handleTag.startsWith('Rex#'));
  await app.close();
});

test('POST /scores without token is 401', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const res = await app.inject({
    method: 'POST', url: '/scores',
    payload: { levelId: 'w1l1', score: 1, rank: 'C', timeSec: 1, citizensSaved: 0 },
  });
  assert.strictEqual(res.statusCode, 401);
  await app.close();
});

test('POST /scores with bad payload is 400', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const p = await newPlayer(app, 'Rex');
  const res = await app.inject({
    method: 'POST', url: '/scores',
    headers: { authorization: `Bearer ${p.token}` },
    payload: { levelId: 'nope', score: 1, rank: 'C', timeSec: 1, citizensSaved: 0 },
  });
  assert.strictEqual(res.statusCode, 400);
  await app.close();
});

test('leaderboard orders by score desc and respects limit', async () => {
  const { app, reset } = makeTestApp();
  await reset();
  const a = await newPlayer(app, 'A');
  const b = await newPlayer(app, 'B');
  const send = (p, score) => app.inject({
    method: 'POST', url: '/scores', headers: { authorization: `Bearer ${p.token}` },
    payload: { levelId: 'w1l1', score, rank: 'B', timeSec: 100, citizensSaved: 4 },
  });
  await send(a, 100);
  await send(b, 900);
  const rows = (await app.inject({ method: 'GET', url: '/leaderboard?levelId=w1l1&limit=1' })).json();
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].score, 900);
  await app.close();
});
```

- [ ] **Step 4: Implement scores routes (make it pass)**

`backend/src/routes/scores.js`:

```js
const { requirePlayer } = require('../auth');
const { validateScore } = require('../validate');

function handleTag(handle, playerId) {
  return `${handle}#${playerId.slice(0, 3)}`;
}

async function scoreRoutes(app) {
  app.post('/scores', { preHandler: requirePlayer(app) }, async (req, reply) => {
    const body = req.body || {};
    const v = validateScore(body);
    if (!v.ok) return reply.code(400).send({ error: v.error });
    const created = await app.prisma.score.create({
      data: {
        playerId: req.player.id,
        levelId: body.levelId,
        score: body.score,
        rank: body.rank,
        timeSec: body.timeSec,
        citizensSaved: body.citizensSaved,
      },
    });
    return reply.code(201).send({ id: created.id });
  });

  app.get('/leaderboard', async (req, reply) => {
    const levelId = req.query.levelId;
    let limit = parseInt(req.query.limit, 10);
    if (!Number.isInteger(limit) || limit < 1) limit = 20;
    if (limit > 100) limit = 100;
    const rows = await app.prisma.score.findMany({
      where: { levelId },
      orderBy: { score: 'desc' },
      take: limit,
      include: { player: true },
    });
    return reply.send(rows.map((r) => ({
      handleTag: handleTag(r.player.handle, r.player.id),
      score: r.score,
      rank: r.rank,
      timeSec: r.timeSec,
    })));
  });
}

module.exports = scoreRoutes;
```

- [ ] **Step 5: Register the routes**

In `backend/src/app.js`, after the players registration add:

```js
  app.register(require('./routes/scores'));
```

- [ ] **Step 6: Run all tests**

```bash
cd backend && export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: PASS — validate + scores + players + health all green.

- [ ] **Step 7: Commit**

```bash
git add backend/
git commit -m "feat(backend): scores + leaderboard with validation"
```

---

### Task 5: Email + consent, and analytics events

**Files:**
- Create: `backend/src/routes/profile.js` (PATCH email/consent)
- Create: `backend/src/routes/events.js` (POST events)
- Modify: `backend/src/app.js` (register both)
- Test: `backend/test/profile.test.js`, `backend/test/events.test.js`

**Interfaces:**
- Consumes: `requirePlayer`, `app.prisma`.
- Produces:
  - `PATCH /players/:id` (auth, self) `{ email, marketingOptIn, consent } -> 200 { ok:true }`; sets `consentAt = now()` only when `consent === true`; `marketingOptIn` forced false when `consent !== true`.
  - `POST /events` (auth optional) `{ type, levelId?, data? } -> 202 { ok:true }`; records an Event (with `playerId` if a valid token is present, else null).

- [ ] **Step 1: Write the failing profile test**

`backend/test/profile.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { makeTestApp } = require('./helpers/db');

async function newPlayer(app, handle) {
  return (await app.inject({ method: 'POST', url: '/players', payload: { handle } })).json();
}

test('PATCH sets email + consent timestamp when consent is true', async () => {
  const { app, prisma, reset } = makeTestApp();
  await reset();
  const p = await newPlayer(app, 'Rex');
  const res = await app.inject({
    method: 'PATCH', url: `/players/${p.playerId}`,
    headers: { authorization: `Bearer ${p.token}` },
    payload: { email: 'parent@example.com', marketingOptIn: true, consent: true },
  });
  assert.strictEqual(res.statusCode, 200);
  const row = await prisma.player.findUnique({ where: { id: p.playerId } });
  assert.strictEqual(row.email, 'parent@example.com');
  assert.strictEqual(row.marketingOptIn, true);
  assert.ok(row.consentAt instanceof Date);
  await app.close();
});

test('PATCH without consent forces marketingOptIn false and no consentAt', async () => {
  const { app, prisma, reset } = makeTestApp();
  await reset();
  const p = await newPlayer(app, 'Rex');
  await app.inject({
    method: 'PATCH', url: `/players/${p.playerId}`,
    headers: { authorization: `Bearer ${p.token}` },
    payload: { email: 'kid@example.com', marketingOptIn: true, consent: false },
  });
  const row = await prisma.player.findUnique({ where: { id: p.playerId } });
  assert.strictEqual(row.marketingOptIn, false);
  assert.strictEqual(row.consentAt, null);
  await app.close();
});
```

- [ ] **Step 2: Implement profile route**

`backend/src/routes/profile.js`:

```js
const { requirePlayer } = require('../auth');

async function profileRoutes(app) {
  app.patch('/players/:id', { preHandler: requirePlayer(app) }, async (req, reply) => {
    if (req.player.id !== req.params.id) return reply.code(403).send({ error: 'forbidden' });
    const body = req.body || {};
    const consent = body.consent === true;
    const data = {};
    if (typeof body.email === 'string') data.email = body.email.trim();
    data.marketingOptIn = consent ? (body.marketingOptIn === true) : false;
    data.consentAt = consent ? new Date() : null;
    await app.prisma.player.update({ where: { id: req.player.id }, data });
    return reply.send({ ok: true });
  });
}

module.exports = profileRoutes;
```

- [ ] **Step 3: Write the failing events test**

`backend/test/events.test.js`:

```js
const test = require('node:test');
const assert = require('node:assert');
const { makeTestApp } = require('./helpers/db');

test('POST /events records an event (anonymous allowed)', async () => {
  const { app, prisma, reset } = makeTestApp();
  await reset();
  const res = await app.inject({
    method: 'POST', url: '/events',
    payload: { type: 'play_start', levelId: 'w1l1' },
  });
  assert.strictEqual(res.statusCode, 202);
  const count = await prisma.event.count();
  assert.strictEqual(count, 1);
  await app.close();
});

test('POST /events attaches playerId when a valid token is sent', async () => {
  const { app, prisma, reset } = makeTestApp();
  await reset();
  const p = (await app.inject({ method: 'POST', url: '/players', payload: { handle: 'Rex' } })).json();
  await app.inject({
    method: 'POST', url: '/events',
    headers: { authorization: `Bearer ${p.token}` },
    payload: { type: 'level_complete', levelId: 'w1l1', data: { rank: 'S' } },
  });
  const ev = await prisma.event.findFirst({ where: { type: 'level_complete' } });
  assert.strictEqual(ev.playerId, p.playerId);
  await app.close();
});
```

- [ ] **Step 4: Implement events route**

`backend/src/routes/events.js`:

```js
const { bearerToken } = require('../auth');

async function eventRoutes(app) {
  app.post('/events', async (req, reply) => {
    const body = req.body || {};
    if (typeof body.type !== 'string' || !body.type) return reply.code(400).send({ error: 'bad type' });
    // Optional auth: attach playerId only if the token resolves.
    let playerId = null;
    const token = bearerToken(req);
    if (token) {
      const player = await app.prisma.player.findUnique({ where: { token } });
      if (player) playerId = player.id;
    }
    await app.prisma.event.create({
      data: {
        type: body.type,
        levelId: typeof body.levelId === 'string' ? body.levelId : null,
        data: body.data ?? null,
        playerId,
      },
    });
    return reply.code(202).send({ ok: true });
  });
}

module.exports = eventRoutes;
```

- [ ] **Step 5: Register both routes**

In `backend/src/app.js`, after the scores registration add:

```js
  app.register(require('./routes/profile'));
  app.register(require('./routes/events'));
```

- [ ] **Step 6: Run all tests**

```bash
cd backend && export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: PASS — profile + events + scores + players + validate + health all green.

- [ ] **Step 7: Commit**

```bash
git add backend/
git commit -m "feat(backend): email+consent profile route + analytics events"
```

---

### Task 6: Railway deploy config + README

**Files:**
- Create: `backend/railway.json`
- Create: `backend/README.md`

**Interfaces:**
- Produces: a deployable service (start command + migrate-on-deploy) and operator docs. No new runtime endpoints.

- [ ] **Step 1: Add Railway config**

`backend/railway.json`:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": { "builder": "NIXPACKS" },
  "deploy": {
    "startCommand": "npx prisma migrate deploy && node src/server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 5
  }
}
```

- [ ] **Step 2: Write the README**

`backend/README.md`:

```markdown
# Kaiju Clash Backend

Fastify + Prisma + Postgres API for handles, leaderboards, email signups, analytics.

## Local dev
1. `npm install`
2. Copy `.env.example` → `.env`, set `DATABASE_URL` (and `TEST_DATABASE_URL` in `.env.test`).
3. `npx prisma migrate dev` to create tables.
4. `npm run dev` → http://localhost:3000/healthz

## Tests
`export $(grep TEST_DATABASE_URL .env.test) && npm test`
Tests run against `TEST_DATABASE_URL` via Fastify `app.inject()` — no network, no prod DB.

## Endpoints
- `GET /healthz`
- `POST /players { handle }` → `{ playerId, token }`
- `GET /players/:id` (Bearer token) → profile
- `PATCH /players/:id` (Bearer) `{ email, marketingOptIn, consent }`
- `POST /scores` (Bearer) `{ levelId, score, rank, timeSec, citizensSaved }`
- `GET /leaderboard?levelId=&limit=`
- `POST /events` `{ type, levelId?, data? }`

## Deploy (Railway)
- Provision a Postgres plugin; set `DATABASE_URL` from it.
- `railway.json` runs `prisma migrate deploy` then starts the server.
- Set CORS origins in `src/app.js` if the game's deployed URL changes.

## Privacy / COPPA
Audience includes under-13. Email capture is opt-in with explicit consent
(`consentAt`). Encourage non-identifying handles. Review obligations before launch.
```

- [ ] **Step 3: Verify tests still pass (no regressions)**

```bash
cd backend && export $(grep TEST_DATABASE_URL .env.test) && npm test
```

Expected: PASS — full suite green.

- [ ] **Step 4: Commit**

```bash
git add backend/
git commit -m "chore(backend): Railway deploy config + README"
```

---

## What this delivers

A tested, deployable backend covering all four data-tracking goals — handles, score leaderboards, opt-in email + consent, and analytics events — independent of the game client. Client wiring (`kaiju-clash/api.js` + hooks into the progression spine's `finishLevel()` and overworld) is the follow-on integration plan, sequenced after the progression spine lands.

## Self-review notes (coverage vs. backend spec)
- Leaderboards → Task 4 (`/scores`, `/leaderboard`). ✅
- Email signups + consent → Task 5 (`PATCH /players/:id`). ✅
- Player handles/profiles → Task 3 (`/players`, auth, profile). ✅
- Analytics → Task 5 (`/events`). ✅
- Schema matches spec §4 (Player/Score/Event + indexes) → Task 1. ✅
- Validation/allowlist/caps from Global Constraints → Task 4 (`validate.js`). ✅
- Client `api.js` integration → intentionally out of scope (follow-on, depends on progression spine).
