# Stage 4 — Multiplayer Prompt

**Goal:** Add online PvP and co-op defender modes with Higgsfield lobby + state sync. Produce final shareable live link.

---

## Higgsfield Prompt (additive — builds on Stage 3 output)

ADD MULTIPLAYER — two modes selectable from lobby:

LOBBY SCREEN: Host generates a link. Guest joins via the link. Lobby shows: Mode select (PvP or Co-op), Kaiju select (Gawdzilla / Kong / Mothra — each player picks different), City select (Tokyo / New York / Seoul). Both players must confirm ready before match starts.

PVP MODE — Kaiju vs Kaiju:
- 2 players each as a different kaiju in the same city
- The city has NO invading titan — the two kaiju fight each other
- Health bars for both players displayed at top (P1 left, P2 right)
- 3 rounds, 90-second timer per round
- Standard power-ups drop from destroyed buildings — first player to reach them gets the effect
- Food power-ups appear after city block evacuation — but in PvP both players race to reach it, Gregg can steal it from either
- Win: best of 3 rounds wins the match

CO-OP DEFENDER MODE — 2 kaiju vs harder titan:
- Both players choose different kaiju, defend the same city together
- Titan variant: 50% more HP, larger AoE attacks, 2 additional minion waves
- Shared city integrity bar — both players' actions contribute or hurt it
- If one player's HP reaches zero: they enter a 5-sec downed state, other player can revive by standing near them and holding the special button
- Food power-ups: only one player can eat each pickup (whichever reaches it first) — Gregg can still steal from either
- Win: both players alive when titan is defeated; city integrity > 50%

STATE SYNC: Both players see the same titan HP bar, same building damage state, same Gregg position and movement. Power-up pickups are first-come exclusive — client that reaches it first consumes it; the icon disappears for both.

---

## Verify Before Advancing (Final Checks)

- [ ] Lobby link generates and works for both players to join
- [ ] Mode select (PvP / Co-op) accessible from lobby
- [ ] PvP: health bars for both players, 3 rounds, timer functional
- [ ] PvP: food power-up race between players works (first touch wins)
- [ ] Co-op: titan has increased HP and additional minion wave
- [ ] Co-op: revive mechanic works (downed → revived by ally)
- [ ] Shared city integrity bar updates from both players' actions
- [ ] State sync: titan HP and building damage match on both clients
- [ ] Gregg position synced across both clients
- [ ] Final live link produced by Higgsfield hosting — shareable
