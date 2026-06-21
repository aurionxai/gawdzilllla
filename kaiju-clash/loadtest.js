#!/usr/bin/env node
// Runtime LOAD test: `node --check` only catches syntax, not runtime crashes at startup
// (e.g. a TDZ ReferenceError from using a `let` before its declaration line runs). This
// stubs the browser APIs and actually executes the page's top-level — externals + inline —
// to confirm the game initializes. Run: `node loadtest.js`
const fs = require('fs');
const path = require('path');
const dir = __dirname;

const html = fs.readFileSync(path.join(dir, 'index.html'), 'utf8');
const inline = require('child_process'); // not used; kept minimal
const scripts = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]).join('\n;\n');

const anything = new Proxy(function(){}, {
  get(t,k){ if(k==='then') return undefined; if(k===Symbol.toPrimitive) return ()=>0; return anything; },
  apply(){ return anything; }, construct(){ return anything; },
});
const win = { AudioContext:function(){return anything;}, webkitAudioContext:function(){return anything;},
  visualViewport:null, devicePixelRatio:2, innerWidth:800, innerHeight:600,
  addEventListener:()=>{}, removeEventListener:()=>{}, matchMedia:()=>anything };
const stubs = { window:win, document:anything,
  localStorage:{getItem:()=>null,setItem:()=>{},removeItem:()=>{}},
  requestAnimationFrame:()=>0, cancelAnimationFrame:()=>{},
  fetch:()=>Promise.reject(new Error('no-net')), Image:function(){return anything;}, Audio:function(){return anything;},
  innerWidth:800, innerHeight:600, devicePixelRatio:2,
  AudioContext:function(){return anything;}, webkitAudioContext:function(){return anything;}, ontouchstart:undefined };
for(const [k,v] of Object.entries(stubs)){ try{ globalThis[k]=v; }catch(e){ try{ Object.defineProperty(globalThis,k,{value:v,configurable:true,writable:true}); }catch(_){} } }

const prog = fs.readFileSync(path.join(dir,'progression.js'),'utf8');
const lp   = fs.readFileSync(path.join(dir,'levelparse.js'),'utf8');
try {
  (0,eval)(prog + '\n;\n' + lp + '\n;\n' + scripts);
  console.log('\x1b[32m✓ LOAD OK\x1b[0m — page top-level ran clean; game initializes (no runtime crash).');
} catch(e){
  console.log('\x1b[31m✗ LOAD CRASH\x1b[0m:', e.constructor.name + ':', e.message);
  console.log((e.stack||'').split('\n').slice(1,5).join('\n'));
  process.exit(1);
}
