# -*- coding: utf-8 -*-
"""Generates the notification / preview sounds of the Awwab app.

These are *synthesized placeholders* (a sung-style melodic call per option and a
soft chime). They are NOT recordings of any muezzin. To use real recordings,
replace the files below with licensed audio that keeps the same file names and
is shorter than 29 s (iOS limit for notification sounds):

  assets/audio/<name>.wav          in-app preview
  ios/Runner/<name>.caf            iOS notification sound (afconvert -f caff -d LEI16)
  android/app/src/main/res/raw/<name>.wav   Android notification sound

Run:  python3 tool/gen_sounds.py   (macOS: needs numpy and afconvert)
"""
import os
import subprocess
import wave

import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(7)


def voice(freq_track, dur, amp_env):
    """Sung 'aa' vowel: harmonics shaped by formants, with vibrato and breath."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib_depth = np.clip((t - 0.25) / 0.5, 0, 1) * 0.012
    vib = 1 + vib_depth * np.sin(2 * np.pi * 5.4 * t)
    f = freq_track * vib
    phase = 2 * np.pi * np.cumsum(f) / SR
    out = np.zeros(n)
    for h in range(1, 28):
        hf = h * np.median(f)
        if hf > 5200:
            break
        formant = (
            1.0 * np.exp(-((hf - 700) / 260) ** 2)
            + 0.7 * np.exp(-((hf - 1150) / 300) ** 2)
            + 0.35 * np.exp(-((hf - 2600) / 500) ** 2)
        )
        out += (formant + 0.02) / h ** 0.8 * np.sin(h * phase)
    out += 0.015 * rng.standard_normal(n) * amp_env
    return out * amp_env


def phrase(tonic, notes):
    """notes: list of (semitones from tonic, seconds, glide seconds)."""
    pieces = []
    prev = None
    for semis, dur, glide in notes:
        n = int(dur * SR)
        target = tonic * 2 ** (semis / 12)
        track = np.full(n, target)
        if prev is not None and glide > 0:
            g = min(int(glide * SR), n)
            track[:g] = np.linspace(prev, target, g)
        att = min(int(0.09 * SR), n // 3)
        rel = min(int(0.22 * SR), n // 2)
        env = np.ones(n)
        env[:att] = np.linspace(0, 1, att)
        env[-rel:] = np.linspace(1, 0.0, rel)
        env *= 0.78 + 0.22 * np.sin(np.pi * np.arange(n) / n)  # gentle swell
        pieces.append(voice(track, dur, env))
        prev = target
    return np.concatenate(pieces)


def reverb(x, seconds=1.9, mix=0.28):
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (0.42 * SR))
    ir[0] = 0
    size = 1 << (len(x) + n).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    wet /= np.max(np.abs(wet)) + 1e-9
    x = x / (np.max(np.abs(x)) + 1e-9)
    return (1 - mix) * x + mix * wet


def finish(x, tail=0.6):
    x = np.concatenate([x, np.zeros(int(0.3 * SR))])
    fade = int(tail * SR)
    x[-fade:] *= np.linspace(1, 0, fade)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.7
    return x


def gap(sec):
    return np.zeros(int(sec * SR))


def makkah():
    # Hijaz colour on D.
    t = 146.83
    a = phrase(t, [(7, 1.7, 0), (5, .5, .15), (7, .7, .12), (12, 2.4, .35), (10, .45, .1), (8, .45, .1), (7, 1.5, .1)])
    b = phrase(t, [(7, 1.4, 0), (8, .5, .1), (7, .6, .1), (12, 2.0, .3), (13, .6, .12), (12, .5, .1), (8, .5, .1), (7, 1.7, .2)])
    c = phrase(t, [(4, 1.0, 0), (5, .6, .12), (7, 1.5, .2), (5, .6, .1), (4, .5, .1), (1, .6, .15), (0, 2.2, .3)])
    return finish(reverb(np.concatenate([a, gap(.35), b, gap(.35), c])))


def madinah():
    # Bayati colour on D (quarter-tone second).
    t = 146.83
    a = phrase(t, [(7, 1.5, 0), (8, .4, .1), (7, .5, .1), (5, 1.4, .25), (3, .5, .12), (1.5, .6, .12), (0, 1.8, .25)])
    b = phrase(t, [(5, 1.2, 0), (7, .8, .2), (10, 2.2, .3), (8, .5, .12), (7, .5, .1), (5, 1.4, .15), (3, .6, .12)])
    c = phrase(t, [(3, .9, 0), (5, .7, .15), (7, 1.8, .25), (5, .6, .12), (3, .5, .1), (1.5, .6, .12), (0, 2.6, .3)])
    return finish(reverb(np.concatenate([a, gap(.35), b, gap(.35), c])))


def afasy():
    # Nahawand colour on E.
    t = 164.81
    a = phrase(t, [(7, 1.6, 0), (8, .5, .12), (10, .7, .15), (12, 2.2, .3), (10, .5, .1), (8, .5, .1), (7, 1.4, .12)])
    b = phrase(t, [(5, 1.0, 0), (7, .7, .15), (8, 1.4, .2), (7, .5, .1), (5, .6, .1), (3, .6, .12), (2, .6, .1), (0, 2.0, .25)])
    c = phrase(t, [(7, 1.3, 0), (12, 1.9, .35), (11, .5, .1), (10, .5, .1), (8, .6, .1), (7, 2.3, .15)])
    return finish(reverb(np.concatenate([a, gap(.35), b, gap(.35), c])))


def calm():
    """Soft three-note bell chime."""
    out = np.zeros(int(8 * SR))
    for k, (f, start) in enumerate([(523.25, 0.0), (659.25, 0.55), (783.99, 1.1), (1046.5, 1.9)]):
        n = int(5.5 * SR)
        t = np.arange(n) / SR
        env = np.exp(-t / 1.25) * np.clip(t / 0.01, 0, 1)
        tone = sum(a * np.sin(2 * np.pi * f * m * t) * np.exp(-t * d)
                   for m, a, d in [(1, 1, 0), (2.0, .35, .8), (3.01, .18, 1.6), (4.2, .08, 2.4)])
        s = int(start * SR)
        out[s:s + n] += (tone * env)[: len(out) - s]
    return finish(reverb(out, 1.4, 0.2), tail=0.8)


SOUNDS = {
    'adhan_makkah': makkah,
    'adhan_madinah': madinah,
    'adhan_afasy': afasy,
    'adhan_calm': calm,
}


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == '__main__':
    for d in ('assets/audio', 'android/app/src/main/res/raw', 'ios/Runner'):
        os.makedirs(os.path.join(ROOT, d), exist_ok=True)
    for name, fn in SOUNDS.items():
        x = fn()
        secs = len(x) / SR
        assert secs < 29, f'{name} is {secs:.1f}s (iOS limit is 30s)'
        wav = os.path.join(ROOT, 'assets/audio', f'{name}.wav')
        write_wav(wav, x)
        write_wav(os.path.join(ROOT, 'android/app/src/main/res/raw', f'{name}.wav'), x)
        subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
                        os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
        print(f'{name}: {secs:.1f}s')
