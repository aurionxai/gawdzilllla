#!/usr/bin/env node
// Higgsfield image generator for Kaiju Clash art.
// Creds live ONLY in ~/.higgsfield/credentials (chmod 600) — never in code, args, or stdout.
//   HIGGSFIELD_API_KEY=...
//   HIGGSFIELD_SECRET=...
// Usage: node tools/higgsfield-gen.mjs <preset> [outDir]
//   preset: crane | boss-idle | ...   (see PRESETS below)
// Official API (docs.higgsfield.ai): POST https://platform.higgsfield.ai/<model>
//   auth header: Authorization: Key <key>:<secret>  ; async job -> poll status_url -> images[].url
import fs from 'fs'; import os from 'os'; import path from 'path';

const CRED = path.join(os.homedir(), '.higgsfield', 'credentials');
if (!fs.existsSync(CRED)) { console.error('✗ no credentials at ~/.higgsfield/credentials — create it (chmod 600) first.'); process.exit(2); }
const env = Object.fromEntries(fs.readFileSync(CRED, 'utf8').split('\n').filter(Boolean)
  .map(l => { const i = l.indexOf('='); return [l.slice(0, i).trim(), l.slice(i + 1).trim()]; }));
const KEY = env.HIGGSFIELD_API_KEY, SECRET = env.HIGGSFIELD_SECRET;
if (!KEY || !SECRET) { console.error('✗ creds file missing HIGGSFIELD_API_KEY / HIGGSFIELD_SECRET'); process.exit(2); }
const AUTH = `Key ${KEY}:${SECRET}`;
const BASE = 'https://platform.higgsfield.ai';
const MODEL = process.env.HF_MODEL || 'higgsfield-ai/soul/standard';   // override once nano-banana path is confirmed

const STYLE = '16-bit SNES pixel art game sprite, crisp hard pixels, bold dark outline, full shading ramp '
  + '(bright highlight -> mid tone -> deep shadow), consistent top-left light, soft rim light, vibrant '
  + 'kid-friendly palette, cute friendly face, clean readable silhouette, centered, plain flat background';
const PRESETS = {
  crane: `${STYLE}. A cute Japanese red-crowned crane (tancho / tsuru) flying with wings spread, 3/4 front `
    + `view, talons reaching down as if gently carrying a small creature. White body and wings, jet-black `
    + `wingtips, red crown patch on the head, orange beak, slate-grey legs. Friendly soft expression to match `
    + `a cute pixel kaiju platformer. Full body, side-scroller game asset.`,
};

const preset = process.argv[2];
const outDir = process.argv[3] || 'skins/crane';
if (!preset || !PRESETS[preset]) { console.error('usage: node tools/higgsfield-gen.mjs <' + Object.keys(PRESETS).join('|') + '> [outDir]'); process.exit(2); }

const headers = { 'Authorization': AUTH, 'Content-Type': 'application/json' };
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const body = { prompt: PRESETS[preset], aspect_ratio: '1:1', resolution: '1080p' };
  console.log(`→ submitting "${preset}" to ${MODEL} …`);
  const res = await fetch(`${BASE}/${MODEL}`, { method: 'POST', headers, body: JSON.stringify(body) });
  const txt = await res.text();
  if (res.status === 401 || res.status === 403) { console.error('✗ auth rejected (' + res.status + ') — check the key/secret in the creds file.'); process.exit(1); }
  let job; try { job = JSON.parse(txt); } catch { console.error('✗ non-JSON submit response (' + res.status + '):', txt.slice(0, 500)); process.exit(1); }
  const id = job.id || job.request_id || job.job_id || (job.status_url && (job.status_url.match(/requests\/([^/]+)/) || [])[1]);
  const statusUrl = job.status_url || (id && `${BASE}/requests/${id}/status`);
  if (!statusUrl) { console.error('✗ could not find a job id / status_url in submit response:', JSON.stringify(job).slice(0, 500)); process.exit(1); }
  console.log('  job:', id || '(from status_url)');

  let result = job;
  for (let i = 0; i < 90; i++) {
    const st = (result.status || '').toString().toLowerCase();
    if (st.includes('complet')) break;
    if (st.includes('fail') || st.includes('nsfw') || st.includes('cancel')) { console.error('✗ job ended:', result.status); process.exit(1); }
    await sleep(2000);
    const r = await fetch(statusUrl, { headers });
    const t = await r.text();
    try { result = JSON.parse(t); } catch { console.error('✗ non-JSON status:', t.slice(0, 300)); process.exit(1); }
    process.stdout.write('.');
  }
  console.log();
  const imgs = result.images || (result.result && result.result.images) || [];
  if (!imgs.length) { console.error('✗ no images in result:', JSON.stringify(result).slice(0, 500)); process.exit(1); }
  fs.mkdirSync(outDir, { recursive: true });
  let n = 0;
  for (const im of imgs) {
    const url = im.url || im;
    const buf = Buffer.from(await (await fetch(url)).arrayBuffer());
    const f = path.join(outDir, `${preset}_raw_${++n}.png`);
    fs.writeFileSync(f, buf);
    console.log('✓ saved', f, '(' + (buf.length / 1024 | 0) + ' KB)');
  }
  console.log('done. Review the raw images, then we cut/scale + remove background to game spec.');
}
main().catch(e => { console.error('✗', e.message); process.exit(1); });
