const test = require('node:test');
const assert = require('node:assert');
const Progression = require('../progression.js');

test('computeRank: flawless fast full-save is S', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 8, citizensTotal: 8 }),
    'S');
});

test('computeRank: most saved, few hits is A', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 200, hitsTaken: 2, citizensSaved: 6, citizensTotal: 8 }),
    'A');
});

test('computeRank: half saved is B', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 5, citizensSaved: 4, citizensTotal: 8 }),
    'B');
});

test('computeRank: poor save rate is C', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 300, hitsTaken: 9, citizensSaved: 1, citizensTotal: 8 }),
    'C');
});

test('computeRank: handles zero citizens total without dividing by zero', () => {
  assert.strictEqual(
    Progression.computeRank({ timeSec: 60, hitsTaken: 0, citizensSaved: 0, citizensTotal: 0 }),
    'S');
});
