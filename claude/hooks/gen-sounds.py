#!/usr/bin/env python3
"""Synthesize custom notification cues (pure beeps + instrument-style tones).

Writes .wav files into ~/.claude/sounds/. Re-run after editing to regenerate.
No dependencies — pure Python stdlib. Audition with `sound-shop`.
"""
import wave, struct, math, os

SR = 44100
OUT = os.path.expanduser("~/.claude/sounds")
os.makedirs(OUT, exist_ok=True)

# Note frequencies (Hz)
N = {
    "A3": 220.00, "C4": 261.63, "D4": 293.66, "E4": 329.63, "G4": 392.00,
    "A4": 440.00, "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99,
    "A5": 880.00, "C6": 1046.50, "E6": 1318.51,
}

# Timbres: list of (harmonic_multiple, amplitude), plus decay rate.
TIMBRES = {
    "beep":     ([(1, 1.0)],                                   6.0),  # pure sine
    "marimba":  ([(1, 1.0), (4, 0.5), (10, 0.12)],             11.0), # woody, fast decay
    "musicbox": ([(1, 1.0), (2, 0.5), (3, 0.3), (5.4, 0.12)],  5.0),  # bright, ringing
    "bell":     ([(1, 1.0), (2.0, 0.6), (2.76, 0.4),
                  (3.0, 0.25), (4.5, 0.15)],                   2.5),  # inharmonic bell
}


def note(freq, dur, timbre, decay=None, attack=0.004):
    partials, dflt = TIMBRES[timbre]
    decay = dflt if decay is None else decay
    out = []
    n = int(SR * dur)
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t)
        if t < attack:
            env *= t / attack
        s = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials)
        out.append(s * env)
    return out


def seq(*notes):
    """Concatenate notes into one melody."""
    out = []
    for nlist in notes:
        out.extend(nlist)
    return out


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.85 * 32767 / peak
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-32768, min(32767, s * scale)))
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))
    print("  wrote", path)


# ── DONE cues (ascending = positive) ──
write("done-beep",     seq(note(N["C5"], .10, "beep"),     note(N["G5"], .16, "beep")))
write("done-marimba",  seq(note(N["C5"], .12, "marimba"),  note(N["E5"], .12, "marimba"), note(N["G5"], .30, "marimba")))
write("done-musicbox", seq(note(N["C5"], .14, "musicbox"), note(N["G5"], .45, "musicbox")))
write("done-bell",     seq(note(N["C5"], .20, "bell"),     note(N["G5"], .90, "bell")))

# ── ATTENTION cues (single/neutral, gets your ear) ──
write("attn-beep",     note(N["A5"], .16, "beep"))
write("attn-marimba",  note(N["A5"], .40, "marimba"))
write("attn-marimba3", seq(note(N["A5"], .14, "marimba"), note(N["A5"], .14, "marimba"), note(N["A5"], .32, "marimba")))
write("attn-musicbox", note(N["E6"], .55, "musicbox"))
write("attn-ding",     seq(note(N["E5"], .12, "musicbox"), note(N["A5"], .45, "musicbox")))

# ── FAIL cues (descending/low = negative) ──
write("fail-beep",     seq(note(N["A4"], .12, "beep"),     note(N["E4"], .22, "beep")))
write("fail-marimba",  seq(note(N["G4"], .14, "marimba"),  note(N["C4"], .34, "marimba")))
write("fail-bell",     seq(note(N["A3"], 1.0, "bell")))
write("fail-buzz",     seq(note(N["C4"], .10, "beep"),     note(N["A3"], .28, "beep")))

print("done. audition with:  sound-shop all   (or sound-shop <name>)")
