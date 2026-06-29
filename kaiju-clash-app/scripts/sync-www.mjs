// Copy the kaiju-clash GAME RUNTIME into ./www (Capacitor's webDir). Bundles only what index.html
// actually loads — no tests, backend, tooling, or scratch files. Re-run on every game change
// (`npm run ios:sync`). The app then ships these assets fully offline.
import { cpSync, rmSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SRC = join(__dirname, '..', '..', 'kaiju-clash');   // the live game folder
const WWW = join(__dirname, '..', 'www');

const FILES = ['index.html', 'progression.js', 'levelparse.js', 'privacy.html'];   // runtime + policy
const DIRS  = ['bg', 'bosses', 'enemies', 'food', 'npcs', 'skins', 'sounds'];   // bundled assets

rmSync(WWW, { recursive: true, force: true });
mkdirSync(WWW, { recursive: true });
for (const f of FILES) {
  if (!existsSync(join(SRC, f))) { console.error('MISSING:', f); process.exit(1); }
  cpSync(join(SRC, f), join(WWW, f));
}
for (const d of DIRS) {
  if (existsSync(join(SRC, d))) cpSync(join(SRC, d), join(WWW, d), { recursive: true });
}
console.log('✓ Synced game → www/  (' + FILES.length + ' files + ' + DIRS.length + ' asset dirs)');
