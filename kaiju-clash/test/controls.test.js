// Enforces the control rule: a key must NOT map to two actions within ONE context
// (gameplay or menu). Cross-context reuse (Z = fart in play, confirm in menus) is allowed.
// CI mirror of the in-game _ctlCheck() guard. Parses the literals with regex (no eval).
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const src = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');

// CONTROLS = { left:'ArrowLeft KeyA', right:'ArrowRight KeyD', ... }  ->  { left:['ArrowLeft','KeyA'], ... }
function parseControls() {
  const block = src.match(/const CONTROLS = \{([\s\S]*?)\};/);
  assert.ok(block, 'could not find `const CONTROLS`');
  const out = {};
  for (const m of block[1].matchAll(/(\w+)\s*:\s*'([^']*)'/g)) out[m[1]] = m[2].trim().split(/\s+/);
  return out;
}
// _CTL_CTX = { gameplay:['left','right',...], menu:[...] }
function parseContexts() {
  const block = src.match(/const _CTL_CTX = \{([\s\S]*?)\};/);
  assert.ok(block, 'could not find `const _CTL_CTX`');
  const out = {};
  for (const m of block[1].matchAll(/(\w+)\s*:\s*\[([^\]]*)\]/g))
    out[m[1]] = [...m[2].matchAll(/'([^']+)'/g)].map(x => x[1]);
  return out;
}

test('controls: no key bound to two actions within one context', () => {
  const C = parseControls(), CTX = parseContexts();
  for (const [ctx, actions] of Object.entries(CTX)) {
    const seen = {};
    for (const a of actions) {
      assert.ok(C[a], `context "${ctx}" references unknown action "${a}"`);
      for (const k of C[a]) {
        assert.ok(!seen[k], `CONTROL CONFLICT in "${ctx}": ${k} = "${seen[k]}" AND "${a}"`);
        seen[k] = a;
      }
    }
  }
});

test('controls: every context action exists in CONTROLS', () => {
  const C = parseControls(), CTX = parseContexts();
  for (const actions of Object.values(CTX))
    for (const a of actions) assert.ok(a in C, `action "${a}" missing from CONTROLS`);
});
