"""Generates original placeholder SFX + music loops (WAV) for Kingdoms of Ember.
Run from the project root:  python3 tools/generate_audio.py
Replace these files with professionally produced audio before store release."""
import math, os, random, struct, wave

SR = 22050
random.seed(4)


def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def tone(freq, dur, vol=0.5, decay=4.0, end_freq=None, shape="sine", trem=0.0):
    n = int(SR * dur); out = []; ph = 0.0
    for i in range(n):
        t = i / n
        f = freq + ((end_freq - freq) * t if end_freq else 0)
        ph += 2 * math.pi * f / SR
        s = math.sin(ph)
        if shape == "square": s = 1.0 if s > 0 else -1.0
        if shape == "saw": s = 2 * ((ph / (2 * math.pi)) % 1) - 1
        a = min(1, i / 120) * math.exp(-decay * t)
        if trem: a *= 0.7 + 0.3 * math.sin(2 * math.pi * trem * i / SR)
        out.append(s * vol * a)
    return out


def noise(dur, vol=0.4, decay=8.0):
    n = int(SR * dur)
    return [(random.random() * 2 - 1) * vol * math.exp(-decay * i / n) for i in range(n)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def seq(*parts):
    out = []
    for p in parts: out += p
    return out


def pad(x, n): return x + [0.0] * max(0, n - len(x))


sfx = "assets/audio/sfx/"
write(sfx + "tap.wav", tone(880, 0.07, 0.35, 30))
write(sfx + "recruit.wav", seq(tone(440, 0.09, 0.4, 6), tone(660, 0.16, 0.4, 6)))
write(sfx + "sword.wav", mix(noise(0.14, 0.45, 18), tone(320, 0.1, 0.35, 25, 160)))
write(sfx + "shield.wav", mix(tone(150, 0.18, 0.6, 14, 90), noise(0.08, 0.25, 30)))
write(sfx + "bow.wav", mix(noise(0.2, 0.25, 9), tone(700, 0.18, 0.2, 10, 250)))
write(sfx + "arrow_hit.wav", tone(220, 0.09, 0.5, 30, 120, "square"))
write(sfx + "magic_cast.wav", tone(300, 0.4, 0.4, 3, 900, "sine", 18))
write(sfx + "magic_hit.wav", mix(noise(0.35, 0.5, 8), tone(200, 0.35, 0.5, 8, 60)))
write(sfx + "fortress_hit.wav", mix(tone(80, 0.35, 0.7, 7, 45), noise(0.3, 0.4, 10)))
write(sfx + "victory.wav", seq(*[tone(f, 0.2, 0.4, 3) for f in (523, 659, 784)], tone(1047, 0.6, 0.45, 2.5)))
write(sfx + "defeat.wav", seq(*[tone(f, 0.28, 0.4, 3, shape="saw") for f in (392, 349, 311)], tone(262, 0.7, 0.4, 2.5, shape="saw")))
write(sfx + "ability.wav", mix(tone(250, 0.5, 0.4, 2.5, 1200, "sine", 12), noise(0.4, 0.2, 6)))
write(sfx + "mine.wav", mix(tone(1500, 0.07, 0.45, 45, 900, "square"), noise(0.05, 0.35, 45), tone(540, 0.09, 0.3, 30)))
write(sfx + "error.wav", seq(tone(160, 0.1, 0.45, 8, shape="square"), tone(130, 0.14, 0.45, 8, shape="square")))


def music(path, bpm, chords, steps, lead_pat, vol=0.22, bars=8):
    beat = 60.0 / bpm / 2  # eighth note
    nsteps = bars * 8
    total = int(SR * beat * nsteps)
    buf = [0.0] * total
    for s in range(nsteps):
        chord = chords[(s // 8) % len(chords)]
        start = int(SR * beat * s)
        notes = []
        if s % 8 in steps:  # arpeggio
            notes.append((chord[(s // 2) % 3] * 2, 0.9 * beat, 0.5, "sine"))
        if s % 4 == 0:  # bass
            notes.append((chord[0] / 2, 1.8 * beat, 0.9, "sine"))
        lead = lead_pat[s % len(lead_pat)]
        if lead:
            notes.append((chord[lead % 3] * 4, 0.9 * beat, 0.35, "sine"))
        for f, d, v, sh in notes:
            t = tone(f, d, vol * v, 3.5, shape=sh)
            for i, x in enumerate(t):
                if start + i < total: buf[start + i] += x
    fade = int(SR * 0.05)
    for i in range(fade):
        buf[-1 - i] *= i / fade
    write(path, buf)


Am, F, C, G = (110.0, 130.8, 164.8), (87.3, 110.0, 130.8), (130.8, 164.8, 196.0), (98.0, 123.5, 146.8)
music("assets/audio/music/menu.wav", 72, [Am, F, C, G], {0, 2, 4, 6}, [0, 0, 0, 0, 2, 0, 0, 0], 0.22)
music("assets/audio/music/battle.wav", 118, [Am, Am, F, G], {0, 1, 2, 3, 4, 5, 6, 7}, [0, 0, 1, 0, 2, 0, 1, 0], 0.2)
print("audio written")
