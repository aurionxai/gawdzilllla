#!/usr/bin/env python3
"""Generate panic/scream/collapse WAV files for GAWDZILLLLA."""
import struct, math, os, random

OUT = "/Users/tc/godzilla-game/assets/audio"
os.makedirs(OUT, exist_ok=True)
SR  = 22050   # sample rate

def write_wav(path, samples):
    n = len(samples)
    with open(path, 'wb') as f:
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + n * 2))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, SR, SR * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', n * 2))
        for s in samples:
            v = max(-32768, min(32767, int(s * 32767)))
            f.write(struct.pack('<h', v))
    print(f"  ✓ {os.path.basename(path)}")

def env(t, dur, attack=0.03, release_start=0.65):
    a = min(1.0, t / attack)
    r = max(0.0, 1.0 - (t - dur * release_start) / (dur * (1 - release_start)))
    return a * r

def sine(t, freq): return math.sin(2 * math.pi * freq * t)
def noise(amp=1.0): return (random.random() * 2 - 1) * amp

# ── Screams (short, high-pitched, human panic) ─────────────────────────────
def make_scream(base_freq, dur, wobble=6, pitch_drop=0, seed=0):
    """Voice-like scream with vibrato and harmonic content."""
    random.seed(seed)
    n = int(dur * SR)
    samples = []
    for i in range(n):
        t   = i / SR
        e   = env(t, dur, attack=0.015, release_start=0.55)
        # Pitch wobble (screaming is never perfectly steady)
        freq = base_freq - pitch_drop * (t / dur) + math.sin(t * wobble * 2 * math.pi) * 22
        # Mix fundamental + harmonics (makes it voice-like, not pure sine)
        s  = sine(t, freq)       * 0.55
        s += sine(t, freq * 2)   * 0.28
        s += sine(t, freq * 3)   * 0.12
        s += sine(t, freq * 0.5) * 0.06
        s += noise(0.04)          # breath noise
        samples.append(s * e * 0.72)
    return samples

# 4 distinct screams with different pitches/durations
scream_params = [
    (880,  0.45, 7,  80,  1),   # high, short, drops
    (660,  0.65, 5,  40,  2),   # mid, longer
    (1040, 0.35, 9,  100, 3),   # very high, short panic yelp
    (740,  0.55, 6,  60,  4),   # mid-high
]
print("Generating screams...")
for i, (freq, dur, wob, drop, seed) in enumerate(scream_params, 1):
    write_wav(f"{OUT}/scream_{i:02d}.wav", make_scream(freq, dur, wob, drop, seed))

# ── Crowd panic (layered screams, longer) ─────────────────────────────────
def make_crowd_panic(dur=1.8, seed=10):
    """Multiple voices overlapping — building collapse panic."""
    random.seed(seed)
    n = int(dur * SR)
    layers = []
    voice_params = [
        (820,  0.8,  8,  60),
        (960,  0.6,  6,  40),
        (680,  1.1,  5,  80),
        (1100, 0.45, 10, 120),
        (750,  0.9,  7,  50),
        (870,  0.7,  8,  70),
    ]
    offsets = [0, 0.05, 0.12, 0.18, 0.25, 0.32]
    for (freq, vdur, wob, drop), offset in zip(voice_params, offsets):
        v = make_scream(freq, vdur, wob, drop, seed)
        start = int(offset * SR)
        for j, s in enumerate(v):
            idx = start + j
            if idx < n:
                if idx >= len(layers):
                    layers.extend([0.0] * (idx - len(layers) + 1))
                layers[idx] += s * 0.38
    if len(layers) < n:
        layers.extend([0.0] * (n - len(layers)))
    return layers[:n]

print("Generating crowd panic...")
write_wav(f"{OUT}/crowd_panic.wav", make_crowd_panic())

# ── Building collapse rumble ──────────────────────────────────────────────
def make_collapse(dur=1.4, seed=20):
    """Low-frequency crunch + debris shower."""
    random.seed(seed)
    n = int(dur * SR)
    samples = []
    for i in range(n):
        t = i / SR
        pct = t / dur
        # Envelope: sharp attack, long decay
        e = math.exp(-t * 3.5) * 1.2
        e = min(1.0, e) * max(0, 1 - pct * 0.4)
        # Low rumble (50–120 Hz)
        rumble  = sine(t, 65 + math.sin(t * 3) * 15) * 0.5
        rumble += sine(t, 90 + math.sin(t * 5) * 10) * 0.3
        # Debris crackle (band-limited noise)
        crackle  = noise(1.0) * math.exp(-t * 6)
        crackle += noise(0.5) * math.exp(-t * 2) * math.sin(t * 300)
        # Impact thud at start
        thud = math.exp(-t * 25) * sine(t, 45) * 1.5
        s = (rumble + crackle * 0.6 + thud) * e
        samples.append(max(-1.0, min(1.0, s * 0.85)))
    return samples

print("Generating collapse sounds...")
# 3 collapse variants
for i, seed in enumerate([20, 21, 22], 1):
    write_wav(f"{OUT}/collapse_{i:02d}.wav", make_collapse(1.2 + i*0.15, seed))

# ── Splat sounds (quick, wet impact) ─────────────────────────────────────
def make_splat(dur=0.12, seed=30):
    """Short wet slap sound."""
    random.seed(seed)
    n = int(dur * SR)
    samples = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 40)
        s = noise(1.0) * e * 0.9
        # Low thud component
        s += sine(t, 120) * math.exp(-t * 60) * 0.5
        samples.append(max(-1.0, min(1.0, s)))
    return samples

print("Generating splat sounds...")
for i in range(1, 13):
    # Vary pitch slightly for each
    random.seed(30 + i)
    dur = 0.08 + random.random() * 0.08
    write_wav(f"{OUT}/splat_{i:02d}.wav", make_splat(dur, seed=30+i))

print(f"\n✅ All audio generated! → {OUT}/")
