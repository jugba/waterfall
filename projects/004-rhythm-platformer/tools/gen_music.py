#!/usr/bin/env python3
"""Generate Beatrunner's original music track AND its beat map from one source of truth.

    python3 -I projects/004-rhythm-platformer/tools/gen_music.py

Writes (deterministic, no randomness without a fixed seed):
  game/assets/audio/music/beatrunner_theme.wav   44.1 kHz mono 16-bit, 125 BPM, ~71 s
  game/data/beatmap.json                         beat times + gameplay event types

Everything is synthesised here (sine/saw/square/noise), so there is no licensing issue.
Every gameplay event also gets an audible accent that starts exactly on its beat (kick for
jumps, clap for punches, "boing" for bounce pads, crash for checkpoints), so the music tells
the player what to do; tests/unit/test_beatmap.gd checks those onsets against the map (+-10 ms).
"""
import json
import os
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", "game"))
WAV_OUT = os.path.join(GAME, "assets", "audio", "music", "beatrunner_theme.wav")
MAP_OUT = os.path.join(GAME, "data", "beatmap.json")

SR = 44100
BPM = 125.0
BEAT = 60.0 / BPM
BARS = 36
LENGTH_BEATS = BARS * 4
TAIL = 1.6
DURATION = LENGTH_BEATS * BEAT + TAIL
N = int(DURATION * SR)
rng = np.random.default_rng(1234)
mix = np.zeros(N, dtype=np.float64)


def t_of(beat):
    return beat * BEAT


def add(sig, at, gain=1.0):
    i = int(round(at * SR))
    if i >= N:
        return
    end = min(N, i + len(sig))
    mix[i:end] += sig[: end - i] * gain


def env(n, attack=0.002, decay=0.2):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-6), 0, 1)
    return a * np.exp(-t / decay)


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# ---------------------------------------------------------------- instruments
def kick(gain=1.0):
    n = int(0.32 * SR)
    t = np.arange(n) / SR
    f = 45 + 110 * np.exp(-t / 0.035)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) * np.exp(-t / 0.13)
    s[: int(0.003 * SR)] += np.linspace(0.6, 0, int(0.003 * SR))  # click on the attack
    return s * gain


def snare():
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    noise = noise - np.concatenate([[0], noise[:-1]]) * 0.6  # brighten
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.04)
    return (noise * np.exp(-t / 0.06) * 0.55 + tone * 0.5)


def clap():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    noise = noise - np.concatenate([[0], noise[:-1]])
    e = np.zeros(n)
    for k, d in enumerate([0.0, 0.011, 0.022]):
        i = int(d * SR)
        e[i:] += np.exp(-(t[: n - i]) / (0.012 if k < 2 else 0.09))
    e[:1] = 1.0
    return noise * e * 0.45


def hat(open_=False):
    n = int((0.16 if open_ else 0.05) * SR)
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    hp = noise - np.concatenate([[0], noise[:-1]])
    return hp * np.exp(-t / (0.06 if open_ else 0.014)) * 0.22


def crash():
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    hp = noise - np.concatenate([[0], noise[:-1]])
    return hp * np.exp(-t / 0.45) * 0.3


def boing():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 220 + 520 * (1 - np.exp(-t / 0.08))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env(n, 0.001, 0.12) * 0.5


def bass_note(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    saw = 2 * ((t * freq) % 1.0) - 1
    sq = np.sign(np.sin(2 * np.pi * freq * t))
    s = 0.6 * saw + 0.4 * sq
    # one-pole lowpass with an envelope on the cutoff for a plucky bass
    out = np.zeros(n)
    y = 0.0
    cut = 0.04 + 0.25 * np.exp(-t / 0.06)
    for i in range(n):
        y += cut[i] * (s[i] - y)
        out[i] = y
    e = np.clip(t / 0.004, 0, 1) * np.clip((dur - t) / 0.02, 0, 1)
    return out * e * 0.5


def lead_note(freq, dur, bright=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.12) / 0.1, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vib) / SR
    s = np.sin(ph) + 0.35 * bright * np.sin(2 * ph) + 0.18 * bright * np.sign(np.sin(ph))
    e = np.clip(t / 0.01, 0, 1) * np.exp(-t / 0.5) * np.clip((dur - t) / 0.03, 0, 1)
    return s * e * 0.16


def pad_chord(notes, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for m in notes:
        f = midi(m)
        for det in (-0.12, 0.12):
            ff = f * 2 ** (det / 12)
            s += 2 * ((t * ff) % 1.0) - 1
    s /= len(notes) * 2
    out = np.zeros(n)
    y = 0.0
    for i in range(n):
        y += 0.03 * (s[i] - y)
        out[i] = y
    e = np.clip(t / 0.25, 0, 1) * np.clip((dur - t) / 0.3, 0, 1)
    return out * e * 0.5


# ---------------------------------------------------------------- arrangement
# vi-IV-I-V in C major (A minor feel): Am F C G, one chord per bar.
CHORDS = [(45, [57, 60, 64]), (41, [53, 57, 60]), (48, [55, 60, 64]), (43, [55, 59, 62])]
# Lead motifs: (eighth index within 2 bars, length in eighths, midi). A minor pentatonic.
MOTIF_A = [(0, 2, 76), (2, 1, 74), (3, 1, 72), (4, 2, 74), (6, 2, 69),
           (8, 1, 72), (9, 1, 74), (10, 2, 76), (12, 3, 79), (15, 1, 76)]
MOTIF_A2 = [(0, 2, 76), (2, 1, 74), (3, 1, 72), (4, 2, 74), (6, 2, 76),
            (8, 3, 72), (11, 1, 69), (12, 4, 69)]
MOTIF_B = [(0, 1, 81), (1, 1, 79), (2, 2, 76), (4, 1, 79), (5, 1, 76), (6, 2, 74),
           (8, 2, 72), (10, 2, 74), (12, 2, 76), (14, 2, 79)]
MOTIF_B2 = [(0, 1, 81), (1, 1, 79), (2, 2, 76), (4, 2, 79), (6, 2, 84),
            (8, 4, 81), (12, 4, 76)]


def section(bar):
    if bar < 4:
        return "intro"
    if bar < 12:
        return "A"
    if bar < 20:
        return "B"
    if bar < 24:
        return "break"
    if bar < 32:
        return "A2"
    return "outro"


for bar in range(BARS):
    sec = section(bar)
    root, chord = CHORDS[bar % 4]
    b0 = bar * 4
    # drums
    for k in range(4):
        beat = b0 + k
        if sec != "break" or k in (0,):
            add(kick(0.95 if sec != "break" else 0.6), t_of(beat))
        if sec in ("A", "B", "A2", "outro") and k in (1, 3):
            add(snare(), t_of(beat), 0.8)
    for e8 in range(8):
        if sec == "break" and bar < 22:
            continue
        open_ = (e8 % 2 == 1) and sec in ("B", "A2")
        add(hat(open_), t_of(b0 + e8 * 0.5), 1.0 if e8 % 2 else 0.6)
    # bass (from bar 2)
    if bar >= 2 and sec != "outro" or (sec == "outro" and bar < 34):
        pattern = [0, 0, 12, 0, 7, 0, 12, 7] if sec != "break" else [0, None, None, None, 0, None, None, None]
        for e8, iv in enumerate(pattern):
            if iv is None:
                continue
            dur = BEAT * (0.45 if sec != "break" else 1.8)
            add(bass_note(midi(root - 12 + iv + 12), dur), t_of(b0 + e8 * 0.5), 0.9)
    # pad in break and outro
    if sec in ("break", "outro", "B"):
        add(pad_chord(chord, BEAT * 4), t_of(b0), 0.5 if sec == "B" else 0.8)
    # lead
    if sec in ("A", "B", "A2") and bar % 2 == 0:
        if sec == "B":
            motif = MOTIF_B if (bar // 2) % 2 == 0 else MOTIF_B2
        else:
            motif = MOTIF_A if (bar // 2) % 2 == 0 else MOTIF_A2
        for e8, ln, m in motif:
            if sec == "A2":
                m += 12 if e8 >= 12 else 0
            add(lead_note(midi(m), ln * BEAT * 0.5), t_of(b0 + e8 * 0.5))
    if sec == "break":  # arpeggio
        for e8 in range(8):
            m = chord[e8 % 3] + 12
            add(lead_note(midi(m), BEAT * 0.45, 0.4), t_of(b0 + e8 * 0.5), 0.7)

# ---------------------------------------------------------------- beat map (gameplay)
# Beats are absolute quarter-note indices (bar*4 + beat). Jumps sit on kicks (beats 1/3),
# punches on snares (2/4), bounce pads and checkpoints on downbeats.
EVENTS = [
    (0, "checkpoint"),
    # A: learn the jump, then jump + punch
    (16, "jump"), (18, "jump"), (20, "jump"), (22, "jump"),
    (24, "jump"), (26, "punch"), (28, "jump"), (30, "punch"),
    (32, "jump"), (34, "punch"), (36, "jump"), (38, "punch"),
    (40, "long_jump"), (43, "punch"), (44, "jump"), (46, "punch"),
    # B: bounce pads
    (48, "checkpoint"),
    (50, "bounce"), (55, "punch"), (57, "punch"), (60, "jump"), (62, "jump"),
    (64, "bounce"), (69, "punch"), (72, "long_jump"), (75, "punch"), (77, "jump"),
    # breakdown: bounce + glide over the canyon
    (80, "checkpoint"),
    (82, "bounce_glide"), (90, "bounce_glide"),
    # A2: everything, faster
    (96, "checkpoint"),
    (98, "jump"), (100, "punch"), (102, "jump"), (104, "punch"),
    (106, "long_jump"), (109, "punch"), (112, "bounce"), (117, "punch"),
    (119, "punch"), (120, "jump"), (122, "jump"), (124, "punch"), (126, "long_jump"),
    (129, "punch"), (132, "end"),
]
ACCENT = {"jump": lambda: kick(0.7), "long_jump": lambda: kick(0.8), "punch": clap,
          "bounce": boing, "bounce_glide": boing, "checkpoint": crash, "end": crash}
for beat, kind in EVENTS:
    if beat == 0:
        continue
    add(ACCENT[kind](), t_of(beat), 0.9 if kind != "checkpoint" else 0.7)

# Lums: on every free beat/half-beat (filled in by the level from the ideal trajectory).
busy = set()
for beat, kind in EVENTS:
    span = {"jump": 1, "long_jump": 2, "punch": 0, "bounce": 3, "bounce_glide": 6,
            "checkpoint": 0, "end": 0}[kind]
    for b in range(beat, beat + span + 1):
        busy.add(b)
lums = []
for half in range(4 * 2, 132 * 2):
    b = half / 2.0
    near_event = any(abs(b - e) < 0.6 for e, k in EVENTS if k in ("punch",))
    if near_event:
        continue
    # in-air arcs get half-beat lums, the ground gets one per beat
    if b in busy or int(b) in busy or half % 2 == 0:
        lums.append(b)

events = [{"beat": float(b), "time": round(t_of(b), 4), "type": k} for b, k in EVENTS]
events += [{"beat": b, "time": round(t_of(b), 4), "type": "lum"} for b in lums]
events.sort(key=lambda e: (e["time"], e["type"]))

# ---------------------------------------------------------------- write
peak = np.max(np.abs(mix))
mix = np.tanh(mix / peak * 1.4) * 0.89  # soft-clip and normalise
pcm = (mix * 32767).astype("<i2")
os.makedirs(os.path.dirname(WAV_OUT), exist_ok=True)
with wave.open(WAV_OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())

beatmap = {
    "_doc": "Generated by tools/gen_music.py - edit the script, not this file. time = offset + beat * 60 / bpm (seconds of audio).",
    "title": "Beatrunner Theme (original, procedurally generated)",
    "music": "res://assets/audio/music/beatrunner_theme.wav",
    "bpm": BPM,
    "offset": 0.0,
    "beats_per_bar": 4,
    "length_beats": LENGTH_BEATS,
    "duration": round(DURATION, 3),
    "events": events,
}
with open(MAP_OUT, "w") as f:
    json.dump(beatmap, f, indent=1)
print(f"wrote {WAV_OUT} ({os.path.getsize(WAV_OUT) / 1e6:.1f} MB, {DURATION:.1f} s) and {MAP_OUT} ({len(events)} events, {len(lums)} lums)")
