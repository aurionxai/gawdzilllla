#!/usr/bin/env python3
"""Generate battle BGM and hit SFX for GAWDZILLLLA."""
import struct, math, os, random

OUT = "/Users/tc/godzilla-game/assets/audio"
os.makedirs(OUT, exist_ok=True)
SR = 22050

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

def sine(t, freq):  return math.sin(2 * math.pi * freq * t)
def tri(t, freq):
    p = (t * freq) % 1.0
    return (4 * p - 2) if p < 0.5 else (4 * (1 - p) - 2 + 2)
def noise(): return (random.random() * 2 - 1)
def sq(t, freq, duty=0.5):
    return 1.0 if (t * freq) % 1.0 < duty else -1.0

# ── Battle BGM (~22 second loop) ─────────────────────────────────────────────
def make_bgm():
    random.seed(42)
    BPM  = 145
    BEAT = 60.0 / BPM          # seconds per beat
    BAR  = BEAT * 4
    BARS = 8                   # 8 bars = one loop
    dur  = BAR * BARS

    n = int(dur * SR)
    out = [0.0] * n

    def add(t0, dur_s, gen, vol=1.0):
        start = int(t0 * SR)
        end   = min(n, start + int(dur_s * SR))
        for i in range(start, end):
            t = (i - start) / SR
            out[i] = max(-1, min(1, out[i] + gen(t) * vol))

    # Bass synth — root note sequence
    bass_notes = [55, 55, 65, 55, 49, 55, 62, 58]  # A1 A1 C2 A1 G1 A1 B1 A#1
    for bar in range(BARS):
        freq = bass_notes[bar % len(bass_notes)]
        t0   = bar * BAR
        def bass(t, f=freq):
            e = math.exp(-t * 5) * 0.9 + 0.1 * max(0, 1 - t / (BAR * 0.9))
            return (sq(t, f, 0.4) * 0.5 + sine(t, f * 2) * 0.3) * e
        add(t0, BAR, bass, 0.45)
        # Beat 3 accent
        def bass2(t, f=freq):
            e = math.exp(-t * 5)
            return (sq(t, f * 1.5, 0.4) * 0.5) * e
        add(t0 + BAR * 0.5, BEAT, bass2, 0.25)

    # Melody — 8-note theme repeating
    melody = [
        (0,     220, BEAT * 0.75),
        (BEAT,  261, BEAT * 0.75),
        (BEAT*2,220, BEAT * 0.5),
        (BEAT*2.5,196,BEAT * 0.5),
        (BEAT*3,220, BEAT * 1.5),
        (BEAT*4,261, BEAT * 0.75),
        (BEAT*5,293, BEAT * 0.75),
        (BEAT*6,261, BEAT * 1.0),
        (BEAT*7,220, BEAT * 1.0),
    ]
    for bar in range(BARS):
        bar_t = bar * BAR
        for (off, freq, dur_s) in melody:
            def lead(t, f=freq, d=dur_s):
                e = min(1, t / 0.02) * max(0, 1 - (t - d * 0.8) / (d * 0.2))
                return (tri(t, f) * 0.6 + sine(t, f * 2) * 0.25) * e
            add(bar_t + off, dur_s, lead, 0.30)

    # Kick drum: beat 1 and 3 of each bar
    def kick(t):
        freq = 60 * math.exp(-t * 25)
        e    = math.exp(-t * 18)
        return sine(t, freq) * e

    for bar in range(BARS):
        for beat_off in [0, BAR * 0.5]:
            add(bar * BAR + beat_off, 0.15, kick, 0.7)

    # Snare: beat 2 and 4
    def snare(t):
        return noise() * math.exp(-t * 30) * 0.9 + \
               sine(t, 180) * math.exp(-t * 25) * 0.3

    for bar in range(BARS):
        for beat_off in [BEAT, BEAT * 3]:
            add(bar * BAR + beat_off, 0.12, snare, 0.45)

    # Hi-hat: every 8th note
    def hihat(t):
        return noise() * math.exp(-t * 80) * 0.4

    for bar in range(BARS):
        for i in range(8):
            add(bar * BAR + i * BEAT * 0.5, 0.04, hihat, 0.3)

    # Normalize
    peak = max(abs(s) for s in out) or 1.0
    return [s / peak * 0.88 for s in out]

print("Generating battle BGM...")
write_wav(f"{OUT}/battle_bgm.wav", make_bgm())

# ── Hit impact sounds ─────────────────────────────────────────────────────────
def make_hit(freq_start, freq_end, dur, noise_mix, seed):
    """Meaty punch/impact sound."""
    random.seed(seed)
    n = int(dur * SR)
    samples = []
    for i in range(n):
        t   = i / SR
        pct = t / dur
        e   = math.exp(-t * 20) * 1.2
        e   = min(1.0, e)
        freq = freq_start + (freq_end - freq_start) * (t / dur)
        tone = sine(t, freq) * (1 - noise_mix)
        nz   = noise() * noise_mix
        thud = (tone + nz) * e
        samples.append(max(-1.0, min(1.0, thud * 0.85)))
    return samples

def make_heavy_hit(seed):
    """Low brutal thud for heavy/unleash."""
    random.seed(seed)
    n   = int(0.18 * SR)
    out = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 15)
        s  = sine(t, 80) * 0.5 * e
        s += sine(t, 45) * 0.4 * math.exp(-t * 25)
        s += noise() * 0.35 * math.exp(-t * 40)
        out.append(max(-1.0, min(1.0, s)))
    return out

print("Generating hit sounds...")
# Light hit: higher pitch, quick
for i, (fs, fe, dur, nm, seed) in enumerate([
    (300, 180, 0.10, 0.4, 100),
    (260, 150, 0.11, 0.45, 101),
    (340, 200, 0.09, 0.35, 102),
], 1):
    write_wav(f"{OUT}/hit_light_{i:02d}.wav", make_hit(fs, fe, dur, nm, seed))

# Heavy hit: lower, bigger
for i in range(1, 4):
    write_wav(f"{OUT}/hit_heavy_{i:02d}.wav", make_heavy_hit(110 + i))

print(f"\n✅ BGM + hits generated → {OUT}/")
