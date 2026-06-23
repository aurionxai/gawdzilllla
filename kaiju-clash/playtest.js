#!/usr/bin/env node
// Headless playtest: drives a bot through each World-1 level toward its exit and reports
// outcomes + invariant violations + frame errors. Strong signals (crash, spawn-embedded,
// instant death, fall-through-floor) are bugs; "stuck early" is flagged for manual review
// (could be a bot limitation, not necessarily a game bug).
//   Usage: node playtest.js   (local server must be on :8080)
const PW_DIR = '/Users/tc/.npm/_npx/9833c18b2d85bc59/node_modules/playwright';
const EXE = '/Users/tc/Library/Caches/ms-playwright/chromium_headless_shell-1228/chrome-headless-shell-mac-arm64/chrome-headless-shell';
const { chromium } = require(PW_DIR);
const URL = process.env.URL || 'http://localhost:8080/';
const LEVELS = ['w1l1', 'w1l2', 'w1l3', 'w1l4', 'w2l1', 'w2l2', 'w2l3', 'w2l4'];
const CHAR = 'lulah';
const PER_LEVEL_MS = 35000;

// The bot runs inside the page: drives `keys` toward the exit, pulses jumps over gaps/walls/enemies.
function botSource() {
  window.__bot = { install(){
    const T = (typeof TS!=='undefined') ? TS : 32;
    let jumpHeld = false, lastImprove = performance.now(), minDist = Infinity;
    const tel = window.__tel = { maxX:0, minDist:Infinity, stuckMs:0, died:false, won:false, fellThroughFloor:false, embedded:false, startScene:scene };
    // spawn invariants (first tick)
    const s0 = state, p0 = s0.player;
    const r = Math.floor((p0.y+66-2)/T), c = Math.floor((p0.x+22)/T);
    if (typeof solid==='function' && solid(s0.level.tiles, r, c)) tel.embedded = true; // standing inside a solid
    tel.timer = setInterval(() => {
      if (!state || scene!=='playing') {
        if (scene==='victory') tel.won = true;
        if (scene==='gameover') tel.died = true;
        return;
      }
      const s = state, pl = s.player, t = s.level.tiles, PWi=44, PHi=66;
      const exit = s.level.exit;
      const boss = s.level.boss;
      // target point
      let tx, ty;
      const gems = (s.level.gems||[]).filter(g=>!g.collected && !g.hidden);   // exit is gated on these
      if (boss) { tx = boss.x; ty = boss.y; }
      else if (gems.length) { let ng=gems[0],nd=1e9; gems.forEach(g=>{const d=Math.hypot(g.x-pl.x,g.y-pl.y); if(d<nd){nd=d;ng=g;}}); tx=ng.x; ty=ng.y; }
      else if (exit) { tx = exit.c*T; ty = exit.r*T; }
      else { tx = (LW-3)*T; ty = pl.y; }
      const goRight = tx > pl.x + 4;
      const goLeft  = tx < pl.x - 4;
      keys.delete('ArrowLeft'); keys.delete('ArrowRight');
      if (goRight) keys.add('ArrowRight'); else if (goLeft) keys.add('ArrowLeft');
      const dir = goRight ? 1 : -1;
      // look ahead: wall (solid at body height ahead) / gap (no ground ahead) / enemy ahead
      const aheadX = pl.x + (goRight ? PWi+8 : -8);
      const aheadC = Math.floor(aheadX / T);
      const bodyR  = Math.floor((pl.y+PHi-10) / T);
      const footR  = Math.floor((pl.y+PHi+4) / T);
      const wallAhead = solid(t, bodyR, aheadC);
      const gapAhead  = !solid(t, footR, aheadC) && !solid(t, footR+1, aheadC) && !solid(t, footR+2, aheadC);
      const needUp    = ty < pl.y - T*0.5;           // vertical climb (tower) or boss above
      const enemyAhead = s.level.enemies.some(e => !e.dead && Math.abs(e.y-pl.y)<70 && (goRight ? (e.x>pl.x && e.x-pl.x<80) : (e.x<pl.x && pl.x-e.x<80)));
      const wantJump = pl.onGround && (wallAhead || gapAhead || enemyAhead || needUp);
      // pulse jump (must release for re-trigger: jump fires on press edge + onGround)
      if (wantJump && !jumpHeld) { keys.add('ArrowUp'); jumpHeld = true; }
      else { keys.delete('ArrowUp'); jumpHeld = false; }
      // attack toward boss/enemy
      if (boss || enemyAhead) { justDn.add('KeyZ'); }
      // telemetry
      tel.maxX = Math.max(tel.maxX, pl.x);
      const dist = Math.hypot(tx-pl.x, ty-pl.y);
      if (dist < minDist - 4) { minDist = dist; lastImprove = performance.now(); }
      tel.minDist = Math.round(minDist);
      tel.stuckMs = Math.round(performance.now() - lastImprove);
      if (pl.y > LH*T + 40) tel.fellThroughFloor = true; // below the map = fell in a pit (lethal by design)
    }, 40);
    return true;
  }};
}

(async () => {
  const browser = await chromium.launch({ executablePath: EXE });
  const page = await browser.newPage({ viewport:{ width:740, height:420 } });
  const frameErrors = [];
  page.on('console', m => { if (/frame error/i.test(m.text())) frameErrors.push(m.text()); });
  page.on('pageerror', e => frameErrors.push('PAGEERROR: '+e.message));
  await page.goto(URL, { waitUntil:'load' });
  await page.waitForFunction(() => typeof spritesReady!=='undefined' && spritesReady===true, { timeout:20000 }).catch(()=>{});
  await page.addInitScript(botSource);   // (no-op here; we eval directly below)

  const report = [];
  for (const lvl of LEVELS) {
    frameErrors.length = 0;
    const spawn = await page.evaluate(([c, l]) => {
      try {
        scene='playing'; state = mkState(c, l);
        const s=state, p=s.player;
        return { ok:true, x:Math.round(p.x), y:Math.round(p.y), hp:p.hp, falling:!!p.falling,
                 enemies:s.level.enemies.length, citizens:s.level.citizens.length,
                 hasExit: !!s.level.exit, isBoss: !!s.level.boss, LW:LW, LH:LH };
      } catch(e){ return { ok:false, err:String(e) }; }
    }, [CHAR, lvl]);
    // install bot
    await page.evaluate(`(${botSource.toString()})(); window.__bot.install();`);
    // let it play
    const t0 = Date.now();
    let tel;
    while (Date.now() - t0 < PER_LEVEL_MS) {
      await page.waitForTimeout(500);
      tel = await page.evaluate(() => window.__tel);
      if (tel.won || tel.died) break;
    }
    await page.evaluate(() => { if (window.__tel && window.__tel.timer) clearInterval(window.__tel.timer); keys.clear(); });
    const widthPx = spawn.LW * 32;
    const reachPct = spawn.isBoss ? null : Math.round(100 * tel.maxX / Math.max(1, widthPx - 60));
    report.push({ lvl, spawn, tel, reachPct, frameErrors: frameErrors.slice(0,3) });
  }
  await browser.close();

  // ── Print ──
  console.log('\n══════════ PLAYTEST REPORT ══════════\n');
  let bugs = 0;
  for (const r of report) {
    const s = r.spawn, t = r.tel || {};
    console.log(`▶ ${r.lvl}  ${s.isBoss?'(BOSS)':''}`);
    if (!s.ok) { console.log(`   ✗ FAILED TO START: ${s.err}`); bugs++; continue; }
    console.log(`   spawn: x=${s.x} y=${s.y} hp=${s.hp} | enemies=${s.enemies} citizens=${s.citizens} | exit=${s.hasExit} boss=${s.isBoss} | size ${s.LW}x${s.LH}`);
    const outcome = t.won ? '🏁 WON' : t.died ? '💀 DIED' : (r.reachPct!=null ? `⏱ timeout — reached ~${r.reachPct}% of level` : '⏱ timeout');
    console.log(`   outcome: ${outcome}  (minDistToGoal=${t.minDist}, stuck=${t.stuckMs}ms)`);
    // bug flags
    const flags = [];
    if (s.falling) flags.push('BUG: player spawns mid-fall');
    if (t.embedded) flags.push('BUG: player spawns embedded in a solid tile');
    if (s.hp <= 0) flags.push('BUG: player spawns dead');
    if (!s.hasExit && !s.isBoss) flags.push('BUG: non-boss level has no exit tile');
    if (r.frameErrors.length) flags.push('BUG: frame error -> '+r.frameErrors[0]);
    if (t.died && t.stuckMs < 2000 && t.maxX < 80) flags.push('BUG: died almost immediately at spawn');
    for (const f of flags) { console.log(`   ${f.startsWith('BUG')?'✗':'⚠'} ${f}`); bugs++; }
    if (!t.won && !flags.length) console.log(`   ⚠ did not reach exit in ${PER_LEVEL_MS/1000}s — manual review (may be bot limitation)`);
    console.log('');
  }
  console.log(`Hard bugs flagged: ${bugs}`);
  process.exit(0);
})().catch(e => { console.error('HARNESS FAIL:', e.message); process.exit(1); });
