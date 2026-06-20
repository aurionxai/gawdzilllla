const test = require('node:test');
const assert = require('node:assert');
const LP = require('../levelparse.js');

const ROWS = [
  "  =   ",
  "o   ^ ",
  "P  s  ",
  "######",
];

test('dims = widest row x row count', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.LW, 6);
  assert.strictEqual(r.LH, 4);
});

test('tile types map correctly', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.tiles[0][2], 2); // '=' platform
  assert.strictEqual(r.tiles[1][4], 4); // '^' spike hazard
  assert.strictEqual(r.tiles[3][0], 1); // '#' solid
  assert.strictEqual(r.tiles[0][0], 0); // ' ' air
});

test('spawn chars leave air and record positions', () => {
  const r = LP.parseLevel(ROWS);
  assert.strictEqual(r.tiles[1][0], 0);            // 'o' -> air tile
  assert.deepStrictEqual(r.spawns.food[0], { r:1, c:0 });
  assert.deepStrictEqual(r.spawns.player, { r:2, c:0 });
  assert.deepStrictEqual(r.spawns.enemies[0], { r:2, c:3, type:'slime' });
});

test('short rows pad to width with air', () => {
  const r = LP.parseLevel(["#", "   ##"]);
  assert.strictEqual(r.LW, 5);
  assert.strictEqual(r.tiles[0][4], 0); // padded
  assert.strictEqual(r.tiles[1][3], 1);
});
