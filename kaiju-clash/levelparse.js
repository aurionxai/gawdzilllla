// Pure ASCII-tilemap parser. Runs in Node (tests) and the browser (global LevelParse).
// Wrapped in an IIFE so its internal constants don't leak into the page's globals
// (the game script also declares T_AIR etc.).
(function(root){
  const T_AIR=0, T_SOLID=1, T_PLAT=2, T_DEST=3, T_HAZARD=4;
  const TILE = { ' ':T_AIR, '#':T_SOLID, '=':T_PLAT, 'x':T_DEST, '^':T_HAZARD };
  const ENEMY = { 's':'slime', 'w':'whelp', 't':'tinbot' };

  const LevelParse = {};
  LevelParse.parseLevel = function parseLevel(rows){
    const LH = rows.length;
    const LW = rows.reduce((m,r)=>Math.max(m,r.length), 0);
    const tiles = Array.from({length:LH}, ()=>new Array(LW).fill(T_AIR));
    const spawns = { food:[], enemies:[], citizens:[], gems:[], player:null, exit:null, door:null };
    for(let r=0;r<LH;r++){
      for(let c=0;c<LW;c++){
        const ch = rows[r][c] || ' ';
        if(ch in TILE){ tiles[r][c] = TILE[ch]; continue; }
        tiles[r][c] = T_AIR;                       // spawn chars leave air
        if(ch==='o') spawns.food.push({r,c});
        else if(ch in ENEMY) spawns.enemies.push({r,c,type:ENEMY[ch]});
        else if(ch==='C') spawns.citizens.push({r,c});
        else if(ch==='g') spawns.gems.push({r,c});
        else if(ch==='P') spawns.player = {r,c};
        else if(ch==='E') spawns.exit = {r,c};
        else if(ch==='D') spawns.door = {r,c};   // secret door -> warps to the secret stage
      }
    }
    return { tiles, LW, LH, spawns };
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = LevelParse;
  else root.LevelParse = LevelParse;
})(typeof globalThis !== 'undefined' ? globalThis : this);
