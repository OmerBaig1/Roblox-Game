"""
Quiet Hours: original, mellow background music for Steal a Game, synthesized from scratch here (no samples).

    python quiet_hours.py OUTPUT.ogg [--wav OUTPUT.wav]

D major, 60 BPM, 56 bars: soft pads, a few felted piano notes, a low bass, lots of room. Nothing else on purpose.
The file is LOOP_SECONDS of music plus TAIL_SECONDS ringing out. The game starts the next pass at LOOP_SECONDS on top of
that tail, so the last chord fades under the first one and there is no loop point to hear.
"""
import argparse
import numpy as np
import soundfile as sf

SR = 44100
BEAT = 1.0
SLOT = 8 * BEAT  # one chord every two bars
TAIL_SECONDS = 9.0
rng = np.random.default_rng(2026)
NOTE = {"C": 0, "C#": 1, "D": 2, "E": 4, "F#": 6, "G": 7, "A": 9, "B": 11}


def m(name):
    return NOTE[name[:-1]] + (int(name[-1]) + 1) * 12


def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


CHORDS = {
    "D": ("D3 A3 C#4 E4 F#4", "D2"), "Bm": ("B2 F#3 A3 C#4 D4", "B1"), "G": ("G2 D3 F#3 A3 B3", "G1"),
    "A": ("A2 E3 G3 B3 D4", "A1"), "F#m": ("F#2 C#3 E3 A3 C#4", "F#1"), "Em": ("E3 G3 B3 D4 F#4", "E2"),
}
CHORDS = {k: ([m(x) for x in v[0].split()], m(v[1])) for k, v in CHORDS.items()}

# each slot: chord, then piano notes (name, beat, length). Long rests are the point.
FIRST = [
    ("D", [("F#4", 1, 2), ("A4", 3, 1), ("F#4", 5, 3)]),
    ("Bm", [("C#5", 2, 2), ("A4", 4, 4)]),
    ("G", [("B4", 1, 2), ("A4", 3, 1), ("F#4", 4, 4)]),
    ("A", [("E4", 2, 2), ("A4", 4, 4)]),
    ("D", [("F#4", 1, 2), ("A4", 3, 1), ("D5", 4, 4)]),
    ("F#m", [("C#5", 0, 2), ("A4", 2, 2), ("E4", 4, 4)]),
    ("G", [("D5", 1, 2), ("B4", 3, 1), ("A4", 4, 2), ("F#4", 6, 2)]),
    ("A", [("E4", 0, 4)]),
]
MIDDLE = [
    ("Em", [("G4", 2, 2), ("B4", 4, 4)]),
    ("A", [("D5", 1, 3), ("B4", 4, 2), ("A4", 6, 2)]),
    ("D", [("F#4", 0, 4)]),
    ("Bm", [("D5", 2, 2), ("C#5", 4, 2), ("A4", 6, 2)]),
    ("G", [("B4", 0, 3), ("F#4", 4, 4)]),
    ("F#m", [("A4", 2, 2), ("C#5", 4, 4)]),
    ("Em", [("B4", 1, 2), ("G4", 3, 1), ("F#4", 4, 4)]),
    ("A", [("E4", 6, 2)]),
]
# the opening again, thinned out so it doesn't feel like a repeat
AGAIN = [(c, n[:2] if i % 2 else n[1:]) for i, (c, n) in enumerate(FIRST)]
ENDING = [
    ("G", [("B4", 2, 2), ("A4", 4, 4)]),
    ("D", [("F#4", 1, 3), ("D4", 4, 4)]),
    ("Em", [("G4", 2, 2), ("E4", 4, 4)]),
    ("A", []),
]
FORM = FIRST + MIDDLE + AGAIN + ENDING
LOOP_SECONDS = len(FORM) * SLOT
N = int((LOOP_SECONDS + TAIL_SECONDS) * SR)
dry = np.zeros((N, 2), np.float32)
wet = np.zeros((N, 2), np.float32)
_cache = {}


def env(n, attack, release):
    e = np.ones(n, np.float32)
    a, r = max(1, min(n, int(attack * SR))), max(1, min(n, int(release * SR)))
    e[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    e[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return e


def piano(note):
    # felt over the hammers: few partials, a slow-ish attack and no hammer noise, so notes bloom instead of strike
    if note not in _cache:
        f, n = hz(note), int(7 * SR)
        t = np.arange(n, dtype=np.float32) / SR
        out = np.zeros(n, np.float32)
        for p in range(1, 8):
            amp = np.exp(-(p - 1) * 0.95) / p
            decay = (0.42 + 0.32 * p) * (f / 262.0) ** 0.3
            for det in (-0.25, 0.3):
                out += amp / 2 * np.exp(-t * decay) * np.sin(2 * np.pi * f * p * (1 + 0.0002 * p * p) * t + p + det * t)
        _cache[note] = out * env(n, 0.02, 1.0)
    return _cache[note]


def bass(note):
    key = ("bass", note)
    if key not in _cache:
        f, n = hz(note), int((SLOT + 3) * SR)
        t = np.arange(n, dtype=np.float32) / SR
        _cache[key] = (np.sin(2 * np.pi * f * t) + 0.18 * np.sin(4 * np.pi * f * t)) * env(n, 1.2, 3.5)
    return _cache[key]


def pad(name):
    # a warm string-and-voice bed: detuned sines with hardly any top. Blooms over 3 s, so chord changes melt
    if name not in _cache:
        n = int((SLOT + 4) * SR)
        t = np.arange(n, dtype=np.float32) / SR
        out = np.zeros((n, 2), np.float32)
        for note in CHORDS[name][0]:
            f = hz(note)
            for k, (cents, pan) in enumerate(((-4, .15), (-1.2, .8), (1.5, .25), (4, .85))):
                ff = f * 2 ** (cents / 1200)
                s = (1 + .1 * np.sin(2 * np.pi * (.07 + k * .025) * t + k)) * (np.sin(2 * np.pi * ff * t + k) + .16 * np.sin(4 * np.pi * ff * t + k) + .04 * np.sin(6 * np.pi * ff * t))
                out[:, 0] += s * np.cos(pan * np.pi / 2)
                out[:, 1] += s * np.sin(pan * np.pi / 2)
        _cache[name] = out * env(n, 3.0, 4.0)[:, None] / (4 * len(CHORDS[name][0]))
    return _cache[name]


def put(sig, at, gain, pan=0.0, send=0.4):
    i = max(0, int(at * SR))
    seg = sig if sig.ndim == 2 else np.stack([sig * np.cos((pan + 1) * np.pi / 4), sig * np.sin((pan + 1) * np.pi / 4)], 1)
    seg = seg[: N - i] * gain
    dry[i: i + len(seg)] += seg
    wet[i: i + len(seg)] += seg * send


for slot, (name, notes) in enumerate(FORM):
    at = slot * SLOT
    put(pad(name), at, .30, send=.5)
    put(bass(CHORDS[name][1]), at, .03, send=.1)
    for note, beat, _ in notes:
        loud = float(np.clip(.15 * (1 + (m(note) - 69) * -.012) * (1 + rng.normal(0, .07)), .09, .19))  # high notes softer
        put(piano(m(note)), at + beat * BEAT + rng.normal(0, .012), loud, pan=-.06, send=.55)


def convolve(x, ir):
    size = 1 << int(np.ceil(np.log2(len(x) + len(ir))))
    return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]


# a large, dark room
ln = int(4.5 * SR)
t = np.arange(ln) / SR
mix = dry.astype(np.float64)
for ch in range(2):
    noise = np.random.default_rng(40 + ch).standard_normal(ln)
    ir = np.convolve(noise, np.ones(60) / 60, "same") * np.exp(-t * 1.5) * np.clip(t / .03, 0, 1)
    mix[:, ch] += .7 * convolve(wet[:, ch].astype(np.float64), ir / np.sqrt((ir ** 2).sum()))

# EQ: no rumble, a little less low-mid fog, and the top eased down from 2.5 kHz
for ch in range(2):
    size = 1 << int(np.ceil(np.log2(N)))
    spec = np.fft.rfft(mix[:, ch], size)
    f = np.fft.rfftfreq(size, 1 / SR)
    db = -2.5 * np.exp(-(np.log2(np.maximum(f, 1) / 220) / .9) ** 2) - 7 * np.clip((f - 2500) / 5000, 0, 1.5)
    mix[:, ch] = np.fft.irfft(spec * 10 ** (db / 20) / np.sqrt(1 + (40 / np.maximum(f, 1)) ** 4), size)[:N]

# level, a soft ceiling, and true silence at the very end
mix *= 10 ** (-24 / 20) / np.sqrt((mix[: int(LOOP_SECONDS * SR)] ** 2).mean())
mix = (np.tanh(mix / .6) * .6).astype(np.float32)
fade = int(2 * SR)
mix[-fade:] *= (np.cos(np.linspace(0, np.pi / 2, fade)) ** 2)[:, None].astype(np.float32)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("output")
    ap.add_argument("--wav")
    a = ap.parse_args()
    if a.wav:
        sf.write(a.wav, mix, SR, subtype="PCM_16")
    with sf.SoundFile(a.output, "w", SR, 2, format="OGG", subtype="VORBIS", compression_level=.45) as out:
        for i in range(0, len(mix), SR):  # in blocks: libsndfile's Vorbis writer fails on one huge buffer
            out.write(mix[i: i + SR])
    print(f"{LOOP_SECONDS:.0f}s loop + {TAIL_SECONDS:.0f}s tail, peak {np.abs(mix).max():.3f}")
