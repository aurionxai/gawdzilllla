// Kaiju Clash leaderboard API — Node + pg, no framework. Deployed on Railway.
// COPPA-safe: usernames + friend-codes only, no PII. Writes require a per-player secret.
// Env: DATABASE_URL (Railway Postgres reference). Optional: ALLOW_ORIGINS (comma list).
const http = require('http');
const crypto = require('crypto');
const { Pool } = require('pg');

// Connect over Railway's PRIVATE network (DATABASE_URL points at *.railway.internal — same project),
// so the link is private and SSL is not used. Never disable TLS verification on a public endpoint.
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const ALLOW = (process.env.ALLOW_ORIGINS || 'https://kaijukids.co,https://www.kaijukids.co,https://aurionxai.github.io,http://localhost,file://')
  .split(',').map(s => s.trim());

async function migrate() {
  await pool.query(`
    create extension if not exists "pgcrypto";
    create table if not exists players (
      id uuid primary key default gen_random_uuid(),
      secret uuid not null default gen_random_uuid(),
      username text not null,
      friend_code text not null unique,
      words_learned int not null default 0,
      created_at timestamptz not null default now()
    );
    create table if not exists level_times (
      player_id uuid not null references players(id) on delete cascade,
      level_id text not null,
      best_ms int not null check (best_ms > 0),
      updated_at timestamptz not null default now(),
      primary key (player_id, level_id)
    );
    create table if not exists friends (
      player_id uuid not null references players(id) on delete cascade,
      friend_id uuid not null references players(id) on delete cascade,
      primary key (player_id, friend_id)
    );
    create index if not exists idx_times_board on level_times(level_id, best_ms);
    create index if not exists idx_players_words on players(words_learned desc);
  `);
  console.log('migrate ok');
}

const clean = (s, n) => String(s || '').replace(/[^A-Za-z0-9 _-]/g, '').slice(0, n);
async function auth(id, secret) {
  const r = await pool.query('select 1 from players where id=$1 and secret=$2', [id, secret]);
  return r.rowCount > 0;
}

const routes = {
  'POST /register': async (b) => {
    const name = clean(b.username, 16) || 'Kaiju';
    let code;
    for (let i = 0; i < 6; i++) { code = crypto.randomBytes(4).toString('hex').slice(0, 6).toUpperCase();
      const ex = await pool.query('select 1 from players where friend_code=$1', [code]); if (!ex.rowCount) break; }
    const r = await pool.query('insert into players(username,friend_code) values($1,$2) returning id,friend_code,secret', [name, code]);
    return r.rows[0];
  },
  'POST /submit': async (b) => {
    if (!await auth(b.id, b.secret)) return { error: 'auth' };
    const ms = b.ms | 0; if (ms <= 0 || ms > 36000000) return { ok: true };
    await pool.query(`insert into level_times(player_id,level_id,best_ms) values($1,$2,$3)
      on conflict (player_id,level_id) do update set best_ms=least(level_times.best_ms,excluded.best_ms), updated_at=now()`,
      [b.id, clean(b.level, 16), ms]);
    return { ok: true };
  },
  'POST /words': async (b) => {
    if (!await auth(b.id, b.secret)) return { error: 'auth' };
    await pool.query('update players set words_learned=greatest(words_learned,$2) where id=$1', [b.id, b.words | 0]);
    return { ok: true };
  },
  'POST /friend': async (b) => {
    if (!await auth(b.id, b.secret)) return { error: 'auth' };
    const f = await pool.query('select id,username from players where friend_code=$1', [clean(b.code, 6).toUpperCase()]);
    if (!f.rowCount || f.rows[0].id === b.id) return { name: null };
    const fid = f.rows[0].id;
    await pool.query('insert into friends(player_id,friend_id) values($1,$2),($2,$1) on conflict do nothing', [b.id, fid]);
    return { name: f.rows[0].username };
  },
};

async function board(q) {
  if (q.type === 'scholar')
    return (await pool.query('select username,words_learned from players where words_learned>0 order by words_learned desc limit 50')).rows;
  if (q.type === 'friends')
    return (await pool.query(`select pl.username,lt.best_ms from level_times lt join players pl on pl.id=lt.player_id
      where lt.level_id=$2 and (lt.player_id=$1 or lt.player_id in (select friend_id from friends where player_id=$1))
      order by lt.best_ms asc limit 50`, [q.id, clean(q.level, 16)])).rows;
  return (await pool.query(`select pl.username,lt.best_ms from level_times lt join players pl on pl.id=lt.player_id
    where lt.level_id=$1 order by lt.best_ms asc limit 50`, [clean(q.level, 16)])).rows;
}

const server = http.createServer(async (req, res) => {
  const origin = req.headers.origin || '';
  const cors = ALLOW.includes(origin) || ALLOW.some(a => origin.startsWith(a)) ? origin : ALLOW[0];
  res.setHeader('Access-Control-Allow-Origin', cors);
  res.setHeader('Access-Control-Allow-Headers', 'content-type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
  const url = new URL(req.url, 'http://x'); const key = req.method + ' ' + url.pathname;
  const send = (code, obj) => { res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(obj)); };
  try {
    if (req.method === 'GET' && url.pathname === '/health') return send(200, { ok: true });
    if (req.method === 'GET' && url.pathname === '/board') return send(200, await board(Object.fromEntries(url.searchParams)));
    if (routes[key]) {
      let body = ''; req.on('data', c => body += c);
      req.on('end', async () => { try { send(200, await routes[key](body ? JSON.parse(body) : {})); }
        catch (e) { console.error(e); send(500, { error: 'server' }); } });
      return;
    }
    send(404, { error: 'not found' });
  } catch (e) { console.error(e); send(500, { error: 'server' }); }
});

migrate().then(() => server.listen(process.env.PORT || 3000, () => console.log('leaderboard up on', process.env.PORT || 3000)))
  .catch(e => { console.error('migrate failed', e); process.exit(1); });
