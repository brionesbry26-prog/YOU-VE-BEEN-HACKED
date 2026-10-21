#!/usr/bin/env python3
"""Generates every sound effect bundled in assets/audio/.

All sounds are synthesized from scratch (sine/square waves, filtered noise)
so they are original works with no third-party licensing. The robotic voice
line is rendered offline with espeak-ng and then processed to sound robotic.

Usage (from the project root):
    python3 tool/generate_sounds.py

Requirements: Python 3 with numpy. espeak-ng + ffmpeg for the voice line.
"""

import os
import shutil
import subprocess
import tempfile
import wave

import numpy as np

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(1337)


def t_axis(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def envelope(n, attack=0.005, release=0.05):
    env = np.ones(n)
    a = max(1, int(RATE * attack))
    r = max(1, int(RATE * release))
    env[:a] = np.linspace(0, 1, a)
    env[-r:] = np.minimum(env[-r:], np.linspace(1, 0, r))
    return env


def tone(freq, seconds, kind="sine", attack=0.005, release=0.05):
    t = t_axis(seconds)
    phase = 2 * np.pi * np.cumsum(np.broadcast_to(freq, t.shape)) / RATE
    if kind == "square":
        sig = np.sign(np.sin(phase)) * 0.6
    elif kind == "saw":
        sig = 2 * ((phase / (2 * np.pi)) % 1.0) - 1
        sig *= 0.6
    else:
        sig = np.sin(phase)
    return sig * envelope(len(t), attack, release)


def silence(seconds):
    return np.zeros(int(RATE * seconds))


def lowpass(sig, alpha):
    out = np.empty_like(sig)
    acc = 0.0
    for i, x in enumerate(sig):
        acc += alpha * (x - acc)
        out[i] = acc
    return out


def place(buf, sig, at):
    start = int(RATE * at)
    end = min(len(buf), start + len(sig))
    buf[start:end] += sig[: end - start]


def normalize(sig, peak_db=-6.0):
    peak = np.max(np.abs(sig)) or 1.0
    return sig / peak * (10 ** (peak_db / 20))


def write(name, sig, peak_db=-6.0):
    sig = normalize(sig, peak_db)
    data = (np.clip(sig, -1, 1) * 32767).astype("<i2")
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(f"wrote {path} ({len(sig) / RATE:.2f}s)")


def key_click():
    n = int(RATE * 0.035)
    noise = rng.uniform(-1, 1, n)
    click = lowpass(noise, 0.35) * np.exp(-np.linspace(0, 9, n))
    thock = tone(rng.uniform(140, 220), 0.035, release=0.03) * 0.5
    return click + thock


def typing():
    # Loopable ~1.8s of irregular mechanical key presses over a faint
    # electronic noise bed (the "background noise" of stage 1).
    length = 1.8
    buf = silence(length)
    at = 0.02
    while at < length - 0.06:
        place(buf, key_click() * rng.uniform(0.55, 1.0), at)
        at += rng.uniform(0.06, 0.16)
    t = t_axis(length)
    hum = 0.05 * np.sin(2 * np.pi * 60 * t) + 0.03 * np.sin(2 * np.pi * 120 * t)
    hiss = lowpass(rng.uniform(-1, 1, len(buf)), 0.05) * 0.12
    return buf + hum + hiss


def startup():
    # Soft, warm two-note pad: innocent on purpose.
    t = t_axis(1.4)
    pad = (np.sin(2 * np.pi * 261.63 * t) + 0.6 * np.sin(2 * np.pi * 392.0 * t)
           + 0.25 * np.sin(2 * np.pi * 523.25 * t))
    env = np.minimum(t / 0.35, 1.0) * np.exp(-np.maximum(t - 0.35, 0) * 2.2)
    return pad * env


def heartbeat():
    # Exactly 1.0s so that looping it ticks once per countdown second:
    # a low "lub-dub" heartbeat plus a quiet clock tick.
    buf = silence(1.0)

    def thump(freq, dur, gain):
        t = t_axis(dur)
        return np.sin(2 * np.pi * freq * t) * np.exp(-t * 28) * gain

    place(buf, thump(55, 0.18, 1.0), 0.0)
    place(buf, thump(48, 0.18, 0.75), 0.22)
    place(buf, tone(2400, 0.012, release=0.008) * 0.25, 0.5)
    return buf


def reveal():
    # A calm, resolving two-note tone: serious, not celebratory.
    buf = silence(1.8)
    place(buf, tone(523.25, 1.2, attack=0.03, release=0.9) * 0.7, 0.0)
    place(buf, tone(783.99, 1.4, attack=0.03, release=1.1) * 0.55, 0.18)
    return buf


def beep():
    return np.concatenate([tone(1320, 0.07, "square"), silence(0.04), tone(1760, 0.09, "square")])


def connect():
    t = t_axis(0.45)
    sweep = tone(400 + 1400 * (t / t[-1]) ** 2, 0.45, release=0.08)
    chord = (tone(880, 0.35) + tone(1320, 0.35) * 0.6) * 0.7
    return np.concatenate([sweep, chord])


def alarm():
    parts = []
    for _ in range(3):
        parts += [tone(880, 0.16, "square"), tone(660, 0.16, "square"), silence(0.05)]
    return np.concatenate(parts)


def transfer():
    # Loopable modem-like chatter of short random bleeps.
    length = 1.6
    buf = silence(length)
    at = 0.0
    while at < length - 0.05:
        dur = rng.uniform(0.02, 0.05)
        freq = rng.choice([1200, 1500, 1800, 2100, 2400])
        place(buf, tone(freq, dur, "square", release=0.01) * 0.5, at)
        at += dur + rng.uniform(0.0, 0.03)
    hiss = lowpass(rng.uniform(-1, 1, len(buf)), 0.08) * 0.15
    return buf + hiss




def voice():
    if not shutil.which("espeak-ng") or not shutil.which("ffmpeg"):
        raise SystemExit("espeak-ng and ffmpeg are required to render voice.wav")
    with tempfile.TemporaryDirectory() as tmp:
        raw = os.path.join(tmp, "raw.wav")
        subprocess.run(
            ["espeak-ng", "-v", "en-us", "-s", "125", "-p", "20", "-w", raw,
             "Your device has been compromised."],
            check=True,
        )
        out = os.path.join(tmp, "out.wav")
        subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-ar", str(RATE), "-ac", "1", out],
            check=True,
        )
        with wave.open(out, "rb") as w:
            sig = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(float) / 32767
    t = np.arange(len(sig)) / RATE
    # Ring modulation + a short metallic echo gives the classic robot timbre.
    robot = sig * (0.55 + 0.45 * np.sin(2 * np.pi * 55 * t))
    echo = np.zeros_like(robot)
    d = int(RATE * 0.012)
    echo[d:] = robot[:-d] * 0.5
    crushed = np.round((robot + echo) * 24) / 24
    return np.concatenate([silence(0.05), crushed, silence(0.1)])


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    write("startup.wav", startup(), -12)
    write("typing.wav", typing(), -10)
    write("beep.wav", beep(), -9)
    write("connect.wav", connect(), -8)
    write("alarm.wav", alarm(), -8)
    write("transfer.wav", transfer(), -12)
    write("countdown.wav", heartbeat(), -8)
    write("voice.wav", voice(), -4)
    write("reveal.wav", reveal(), -12)


if __name__ == "__main__":
    main()
