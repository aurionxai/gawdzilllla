# Kaiju Clash leaderboard — Supabase setup (your 5-minute step)

The game is a static site, so the global board needs a backend. Supabase is free and needs no server.

## 1. Create the project
- Go to https://supabase.com → New project (free tier). Name it e.g. `kaiju-clash`.
- Wait ~1 min for it to provision.

## 2. Run the schema
- Open the project → **SQL Editor** → New query → paste all of `schema.sql` → **Run**.
- It creates the tables + secure write functions (no PII; usernames + friend-codes only).

## 3. Give me the connection (anon key is PUBLIC-safe)
- Project → **Settings → API**. Copy two values:
  - **Project URL** (e.g. `https://abcd1234.supabase.co`)
  - **anon public** key (the long `eyJ...` one — this is the *public* client key, safe to embed; it is
    NOT the `service_role` secret — never share that one).
- Put both in `kaiju-clash/supabase/config.json`:
  ```json
  { "url": "https://YOURPROJECT.supabase.co", "anonKey": "eyJ...your-anon-public-key..." }
  ```
- Tell me "config is in" and I'll wire the client in.

## What you get
- **Speedrun boards** — fastest time per level (uses the ⏱ timer). Global + Friends tabs.
- **Scholar board** — gamified education: ranks players by Japanese words learned.
- **Username + friend codes** — pick a name, share a 6-char code to add friends. COPPA-safe.

## Note on cheating
Client-submitted times are inherently spoofable in any browser game. The schema already clamps
implausible times and keeps only personal-best; for a kids' game that's enough. Server-side replay
validation can come later if it ever matters.
