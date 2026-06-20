# Kaiju Clash — Backend & Data Tracking Design

**Date:** 2026-06-19
**Status:** Design approved (build gameplay first, backend in parallel)
**Relationship:** Separate subsystem from the gameplay client. The game
(`kaiju-clash/index.html`) stays a static deploy; this adds a small API + database
it talks to over HTTPS. Pairs with the progression spine
([../plans/2026-06-19-progression-spine.md]) whose `localStorage` meta stays the
offline source of truth and syncs up to this backend.

---

## 1. Goal

Add a lightweight backend so Kaiju Clash can do four things it cannot today (the game
is currently a static page with `localStorage` only):

1. **Global leaderboards** — best score / rank per level, across devices.
2. **Email signups** — an opt-in marketing list.
3. **Player handles / profiles** — progress and scores attach to a named player.
4. **Play analytics** — plays, completions, drop-off, signups.

## 2. Identity model (kid-friendly, low friction)

Target audience is kids 8+, so **no passwords, no required email**:

- A player **types a handle** (nickname). On first submit we create a player row and
  mint a secret **`player_token`** (UUID) stored in the browser's `localStorage`.
- That token authenticates future writes for that player (score submits, profile edits).
  It is a bearer secret, not a password — good enough for a casual kids' game, and it
  means a child never manages credentials.
- **Email is optional and opt-in** ("save your progress / get updates" prompt). Entering
  it never gates play.

### Privacy / COPPA note (must address before launch)
Because the audience includes under-13s and we may collect emails, the email capture
flow MUST: (a) be clearly optional, (b) ask for a parent/guardian email rather than the
child's where signup is for updates, (c) include a short privacy notice + consent
checkbox, and (d) store a consent timestamp. Treat handles as **non-identifying**
(no real names encouraged — UI copy: "pick a nickname"). This is a launch-blocker
checklist item, not an afterthought.

## 3. Architecture

```
[ index.html game ]  --HTTPS/JSON-->  [ Railway API service (Node/Fastify) ]  -->  [ Postgres ]
       |  localStorage (offline cache + player_token)            |  Prisma ORM
       +-- syncs scores/profile/events up; reads leaderboard down
```

- **Host:** Railway — one Postgres database + one small API service. (Railway tooling is
  already available in this environment.)
- **ORM:** Prisma (migrations + typed client).
- **API framework:** Fastify (small, fast, good JSON validation) on Node.
- **CORS:** allow the game origin(s): `https://lemon-vista-573.higgsfield.gg` (and the
  current deployed slug) + `http://localhost:8000` for dev.
- **No auth server / no sessions** — just the per-player bearer `player_token`.

The game client gets a tiny `api.js` module (separate from `progression.js`) that wraps
`fetch`. All calls are best-effort: if the backend is unreachable, the game keeps working
on `localStorage` (offline-first). Score submit + analytics never block gameplay.

## 4. Data model (Postgres / Prisma)

```prisma
model Player {
  id           String   @id @default(uuid())
  handle       String                         // display nickname, not unique
  token        String   @unique @default(uuid()) // secret bearer for writes
  email        String?                         // optional, opt-in
  marketingOptIn Boolean @default(false)
  consentAt    DateTime?                       // set when email captured w/ consent
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  scores       Score[]
  events       Event[]
  @@index([handle])
}

model Score {
  id            String   @id @default(uuid())
  player        Player   @relation(fields: [playerId], references: [id])
  playerId      String
  levelId       String                         // matches Progression.LEVELS id, e.g. "w1l1"
  score         Int
  rank          String                         // 'S' | 'A' | 'B' | 'C'
  timeSec       Int
  citizensSaved Int
  createdAt     DateTime @default(now())
  @@index([levelId, score(sort: Desc)])        // leaderboard query
  @@index([playerId])
}

model Event {                                   // analytics, append-only
  id        String   @id @default(uuid())
  player    Player?  @relation(fields: [playerId], references: [id])
  playerId  String?
  type      String                              // 'play_start' | 'level_complete' | 'signup' | 'level_fail' ...
  levelId   String?
  data      Json?                               // freeform extra (rank, orbs, etc.)
  createdAt DateTime @default(now())
  @@index([type, createdAt])
}
```

**Why these shapes:**
- `handle` is **not unique** — kids will collide on nicknames; leaderboards display
  `handle` plus a short id suffix (e.g. `Rex#a3f`) for disambiguation.
- Email lives on `Player` (single source) rather than a separate table; the marketing
  list is `Player where email is not null and marketingOptIn = true`.
- `Event` is a thin append-only analytics log — cheap to write, easy to aggregate later.

## 5. API surface

All JSON. Writes require `Authorization: Bearer <player_token>` except player creation.

| Method | Path | Body / params | Returns | Notes |
|---|---|---|---|---|
| `POST` | `/players` | `{ handle }` | `{ playerId, token }` | First-run; client stores both in localStorage |
| `PATCH` | `/players/:id` | `{ email, marketingOptIn, consent }` | `{ ok }` | Auth. Sets `consentAt` when consent true |
| `GET` | `/players/:id` | — (auth) | `{ handle, email, bestScores[] }` | Profile |
| `POST` | `/scores` | `{ levelId, score, rank, timeSec, citizensSaved }` | `201 { id }` | Auth. `playerId` derived from token |
| `GET` | `/leaderboard` | `?levelId=&limit=20` | `[{ rank, handleTag, score, timeSec }]` | Public; top N by score |
| `POST` | `/events` | `{ type, levelId?, data? }` | `202` | Auth optional; fire-and-forget |
| `GET` | `/healthz` | — | `{ ok: true }` | Liveness for Railway |

**Validation rules (server-side, anti-cheat-lite):**
- `levelId` must be in a server-side allowlist mirroring `Progression.LEVELS`.
- `rank` ∈ `{S,A,B,C}`; `score`, `timeSec`, `citizensSaved` non-negative integers with
  sane upper bounds (reject absurd values).
- Rate-limit `/scores` and `/players` per IP (basic abuse guard).
- Score auth is best-effort only — a determined cheater can still forge a client request;
  acceptable for a casual kids' leaderboard. (If real anti-cheat is ever needed, that's a
  separate hardening effort: signed runs / server-side replay. Out of scope.)

## 6. Client integration (game side)

New file `kaiju-clash/api.js` (loaded like `progression.js`, exposes global `KaijuAPI`):
- `KaijuAPI.ensurePlayer(handle)` → creates/loads player, caches `{playerId, token}` in
  `localStorage['kaiju_player']`.
- `KaijuAPI.submitScore({ levelId, score, rank, timeSec, citizensSaved })` → POST, swallow errors.
- `KaijuAPI.fetchLeaderboard(levelId)` → GET, returns rows for a leaderboard screen.
- `KaijuAPI.saveEmail({ email, marketingOptIn, consent })` → PATCH.
- `KaijuAPI.track(type, levelId, data)` → POST `/events`, fire-and-forget.
- A configurable `KaijuAPI.BASE_URL` (the Railway service URL); empty/unreachable ⇒ all
  calls no-op so the game still runs offline.

Hook points in the progression spine:
- After `finishLevel()` computes a result → `KaijuAPI.submitScore(...)` + `track('level_complete', ...)`.
- On overworld a new **Leaderboard** view per level → `fetchLeaderboard`.
- A **handle prompt** on first play (before/at the overworld) → `ensurePlayer`.
- An optional **"Save progress / get updates" email prompt** → `saveEmail`.
- `track('play_start' | 'level_fail' | 'signup')` at the obvious moments.

## 7. Out of scope (YAGNI for now)
- Passwords / OAuth / real auth server.
- Friends, chat, social graph.
- Server-authoritative anti-cheat / replay validation.
- Cosmetic purchases / payments.

## 8. Build order (its own spec → plan → implementation)
1. **DB + API skeleton:** Prisma schema, migrations, Fastify service, `/healthz`, deploy to Railway.
2. **Players + scores:** `POST /players`, `POST /scores`, `GET /leaderboard` with validation + tests.
3. **Email + consent:** `PATCH /players/:id`, consent handling, marketing-list query.
4. **Events/analytics:** `POST /events` + a basic aggregation query/endpoint.
5. **Client `api.js` + game hooks:** wire into the progression spine (after it exists).

Backend steps 1-4 can be built **in parallel** with the gameplay (progression spine);
step 5 depends on the progression spine landing first.
