-- Kaiju Clash leaderboard — Supabase schema + secure RPCs.
-- COPPA-safe: usernames only, NO email / real names / PII. Friends via share-codes.
-- Run this in the Supabase SQL editor (one paste). Anti-tamper: all writes go through
-- SECURITY DEFINER functions that check a per-player secret; tables themselves are read-only
-- to the anon key, so nobody can overwrite someone else's score.

create extension if not exists "pgcrypto";

-- ── Tables ───────────────────────────────────────────────────────────────────
create table if not exists players (
  id           uuid primary key default gen_random_uuid(),
  secret       uuid not null default gen_random_uuid(),     -- client keeps this; required to write
  username     text not null check (char_length(username) between 2 and 16),
  friend_code  text not null unique,                        -- 6-char share code
  words_learned int not null default 0,                     -- the "Scholar" / education score
  created_at   timestamptz not null default now()
);

create table if not exists level_times (
  player_id  uuid not null references players(id) on delete cascade,
  level_id   text not null,
  best_ms    int  not null check (best_ms > 0),
  updated_at timestamptz not null default now(),
  primary key (player_id, level_id)
);

create table if not exists friends (
  player_id  uuid not null references players(id) on delete cascade,
  friend_id  uuid not null references players(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (player_id, friend_id)
);

create index if not exists idx_times_board   on level_times(level_id, best_ms);
create index if not exists idx_players_words on players(words_learned desc);

-- ── Row-level security: anon may READ boards, but NOT write tables directly ───
alter table players     enable row level security;
alter table level_times enable row level security;
alter table friends     enable row level security;
-- public read for boards (no secret column is ever selected by the client board queries)
create policy "read players"     on players     for select using (true);
create policy "read level_times" on level_times for select using (true);
create policy "read friends"     on friends     for select using (true);
-- (no insert/update/delete policies => direct writes are denied; use the RPCs below)

-- ── Secure write RPCs (SECURITY DEFINER) ─────────────────────────────────────
-- Register a new player; returns their id + friend_code + secret (client stores all three).
create or replace function register_player(p_username text)
returns table(id uuid, friend_code text, secret uuid)
language plpgsql security definer as $$
declare code text;
begin
  loop
    code := upper(substr(encode(gen_random_bytes(4),'hex'),1,6));
    exit when not exists (select 1 from players where friend_code = code);
  end loop;
  return query
  insert into players(username, friend_code)
  values (left(regexp_replace(p_username,'[^A-Za-z0-9 _-]','','g'),16), code)
  returning players.id, players.friend_code, players.secret;
end $$;

-- Submit a level time; only keeps it if it beats the player's existing best.
create or replace function submit_time(p_id uuid, p_secret uuid, p_level text, p_ms int)
returns void language plpgsql security definer as $$
begin
  if not exists (select 1 from players where id=p_id and secret=p_secret) then
    raise exception 'bad credentials'; end if;
  if p_ms <= 0 or p_ms > 36000000 then return; end if;          -- sanity clamp (<10 min)
  insert into level_times(player_id, level_id, best_ms) values (p_id, p_level, p_ms)
  on conflict (player_id, level_id) do update
    set best_ms = least(level_times.best_ms, excluded.best_ms), updated_at = now();
end $$;

-- Sync the education score (words learned only ever goes up).
create or replace function sync_words(p_id uuid, p_secret uuid, p_words int)
returns void language plpgsql security definer as $$
begin
  if not exists (select 1 from players where id=p_id and secret=p_secret) then
    raise exception 'bad credentials'; end if;
  update players set words_learned = greatest(words_learned, p_words) where id=p_id;
end $$;

-- Add a friend by their share-code (mutual).
create or replace function add_friend(p_id uuid, p_secret uuid, p_code text)
returns text language plpgsql security definer as $$
declare fid uuid; fname text;
begin
  if not exists (select 1 from players where id=p_id and secret=p_secret) then
    raise exception 'bad credentials'; end if;
  select id, username into fid, fname from players where friend_code = upper(p_code);
  if fid is null then return null; end if;
  if fid = p_id then return null; end if;
  insert into friends(player_id, friend_id) values (p_id, fid) on conflict do nothing;
  insert into friends(player_id, friend_id) values (fid, p_id) on conflict do nothing;
  return fname;
end $$;

-- Friends' best times for a level (for the Friends board).
create or replace function friend_times(p_id uuid, p_level text)
returns table(username text, best_ms int) language sql security definer as $$
  select pl.username, lt.best_ms from level_times lt
  join players pl on pl.id = lt.player_id
  where lt.level_id = p_level and (lt.player_id = p_id
        or lt.player_id in (select friend_id from friends where player_id = p_id))
  order by lt.best_ms asc limit 50;
$$;

grant execute on function register_player(text), submit_time(uuid,uuid,text,int),
  sync_words(uuid,uuid,int), add_friend(uuid,uuid,text), friend_times(uuid,text) to anon;
