-- tests/test_fps_player.lua
local R = require("tests/runner")
if not love then love = {} end

local Player = require("src/fps/player_state")

print("\n-- fps/player_state.lua --")

R.test("new player starts at level 1 with full HP", function()
  local p = Player.new("Godzilla")
  R.eq(p.level, 1)
  R.eq(p.hp, p.maxHp)
end)

R.test("ranged and claw are unlocked at level 1", function()
  local p = Player.new("Godzilla")
  R.ok(p:isUnlocked("ranged"), "ranged at lv1")
  R.ok(p:isUnlocked("claw"),   "claw at lv1")
end)

R.test("bite is locked at level 1, unlocks at level 5", function()
  local p = Player.new("Godzilla")
  R.notok(p:isUnlocked("bite"), "bite locked at lv1")
  p.level = 5
  R.ok(p:isUnlocked("bite"), "bite unlocked at lv5")
end)

R.test("tail is locked at level 4, unlocks at level 7", function()
  local p = Player.new("Godzilla")
  p.level = 4
  R.notok(p:isUnlocked("tail"), "tail locked at lv4")
  p.level = 7
  R.ok(p:isUnlocked("tail"), "tail unlocked at lv7")
end)

R.test("canUse returns false for locked move", function()
  local p = Player.new("Godzilla")
  R.notok(p:canUse("bite"), "cannot use locked bite")
end)

R.test("canUse returns false while on cooldown", function()
  local p = Player.new("Godzilla")
  R.ok(p:canUse("ranged"), "ranged ready initially")
  p:useMove("ranged")
  R.notok(p:canUse("ranged"), "ranged on cooldown after use")
end)

R.test("cooldown expires after update", function()
  local p = Player.new("Godzilla")
  p:useMove("ranged")
  p:update(p.cooldownMax.ranged + 0.1)
  R.ok(p:canUse("ranged"), "ranged ready after cooldown")
end)

R.test("takeDamage reduces HP", function()
  local p = Player.new("Godzilla")
  local start = p.hp
  p:takeDamage(20)
  R.ok(p.hp < start, "HP reduced after damage")
end)

R.test("defense reduces incoming damage below raw amount", function()
  local p = Player.new("Godzilla")
  p.stats.def = 9
  local start = p.hp
  p:takeDamage(20)
  R.ok((start - p.hp) < 20, "defense reduced damage")
end)

R.test("gainXp triggers level up when threshold reached", function()
  local p = Player.new("Godzilla")
  p:gainXp(p.xpToNext)
  R.eq(p.level, 2, "level up to 2")
  R.ok(p.statPoints >= 2, "awarded stat points")
end)

R.test("getRangedDamage scales with rage stat", function()
  local p = Player.new("Godzilla")
  local baseDmg = p:getRangedDamage()
  p.stats.rage = p.stats.rage + 10
  R.ok(p:getRangedDamage() > baseDmg, "higher rage = higher ranged damage")
end)

R.test("getMeleeDamage bite is higher than claw", function()
  local p = Player.new("Godzilla")
  R.ok(p:getMeleeDamage("bite") > p:getMeleeDamage("claw"), "bite > claw damage")
end)
