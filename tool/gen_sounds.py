# -*- coding: utf-8 -*-
"""Generates the notification / preview sounds of the Awwab app.

These are *synthesized placeholders* (a sung-style melodic call per option, with
its own maqam, pitch, tempo and timbre, plus a soft chime). They are NOT
recordings of any of the muezzins / reciters named in the app. To use real recordings,
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

SR = 16000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(7)

# Scale degrees (semitones from the tonic) of the maqamat used.
MAQAM = {
    'hijaz':    [0, 1, 4, 5, 7, 8, 10],
    'bayati':   [0, 1.5, 3, 5, 7, 8, 10],
    'rast':     [0, 2, 3.5, 5, 7, 9, 10.5],
    'nahawand': [0, 2, 3, 5, 7, 8, 10],
    'saba':     [0, 1.5, 3, 4, 7, 8, 10],
    'sika':     [0, 1.5, 3.5, 5, 7, 8.5, 10],
    'ajam':     [0, 2, 4, 5, 7, 9, 11],
}

# Melodic skeletons: three lines of (scale degree, seconds, glide seconds).
SKELETONS = {
    1: [
        [(4, 1.7, 0), (3, .5, .15), (4, .7, .12), (7, 2.4, .35), (6, .45, .1), (5, .45, .1), (4, 1.5, .1)],
        [(4, 1.4, 0), (5, .5, .1), (4, .6, .1), (7, 2.0, .3), (8, .6, .12), (7, .5, .1), (5, .5, .1), (4, 1.7, .2)],
        [(2, 1.0, 0), (3, .6, .12), (4, 1.5, .2), (3, .6, .1), (2, .5, .1), (1, .6, .15), (0, 2.2, .3)],
    ],
    2: [
        [(4, 1.5, 0), (5, .4, .1), (4, .5, .1), (3, 1.4, .25), (2, .5, .12), (1, .6, .12), (0, 1.8, .25)],
        [(3, 1.2, 0), (4, .8, .2), (6, 2.2, .3), (5, .5, .12), (4, .5, .1), (3, 1.4, .15), (2, .6, .12)],
        [(2, .9, 0), (3, .7, .15), (4, 1.8, .25), (3, .6, .12), (2, .5, .1), (1, .6, .12), (0, 2.6, .3)],
    ],
    3: [
        [(4, 1.6, 0), (5, .5, .12), (6, .7, .15), (7, 2.2, .3), (6, .5, .1), (5, .5, .1), (4, 1.4, .12)],
        [(3, 1.0, 0), (4, .7, .15), (5, 1.4, .2), (4, .5, .1), (3, .6, .1), (2, .6, .12), (1, .6, .1), (0, 2.0, .25)],
        [(4, 1.3, 0), (7, 1.9, .35), (6, .5, .1), (5, .5, .1), (4, .6, .1), (4, 2.3, .15)],
    ],
}

# name: (maqam, tonic Hz, tempo, skeleton, vibrato Hz, formant shift, reverb s)
# Order and file names match lib/features/notifications/domain/entities/adhan_sound.dart.
VOICES = {
    'adhan_makkah_mulla':     ('hijaz',    146.8, .82, 1, 5.4, 1.00, 2.0),
    'adhan_makkah_faida':     ('hijaz',    155.6, .78, 2, 5.8, 1.06, 2.2),
    'adhan_makkah_hadrawi':   ('bayati',   146.8, .85, 3, 5.0, 0.96, 1.9),
    'adhan_makkah_daghriri':  ('hijaz',    138.6, .90, 1, 5.2, 0.92, 2.3),
    'adhan_madinah_bukhari':  ('bayati',   146.8, .80, 2, 5.6, 1.02, 2.0),
    'adhan_madinah_surayhi':  ('rast',     155.6, .84, 3, 5.3, 1.08, 2.1),
    'adhan_aqsa':             ('saba',     146.8, .75, 2, 5.0, 0.98, 2.6),
    'adhan_afasy':            ('nahawand', 164.8, .80, 3, 5.9, 1.10, 1.9),
    'adhan_abdulbasit':       ('saba',     130.8, .92, 2, 4.8, 0.90, 2.4),
    'adhan_minshawi':         ('bayati',   130.8, .88, 2, 4.9, 0.93, 2.2),
    'adhan_qatami':           ('hijaz',    155.6, .82, 1, 5.7, 1.04, 1.8),
    'adhan_dosari':           ('nahawand', 146.8, .80, 1, 5.5, 1.00, 2.0),
    'adhan_muaiqly':          ('bayati',   164.8, .78, 3, 5.1, 1.07, 2.1),
    'adhan_abkar':            ('rast',     138.6, .85, 3, 5.4, 0.95, 1.9),
    'adhan_islam_sobhi':      ('hijaz',    174.6, .80, 3, 6.1, 1.14, 1.7),
    'adhan_zahrani':          ('sika',     146.8, .82, 2, 5.5, 1.01, 2.0),
    'adhan_arkani':           ('ajam',     155.6, .80, 1, 5.7, 1.05, 1.8),
    'adhan_zayed':            ('rast',     130.8, .85, 1, 5.2, 0.94, 2.8),
    'adhan_takbeer':          ('hijaz',    146.8, .80, 1, 5.4, 1.00, 1.6),
    'adhan_calm':             None,  # soft chime, see calm()
}


def voice(freq_track, dur, amp_env, vib_rate=5.4, fs=1.0):
    """Sung 'aa' vowel: harmonics shaped by formants, with vibrato and breath."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib_depth = np.clip((t - 0.25) / 0.5, 0, 1) * 0.012
    vib = 1 + vib_depth * np.sin(2 * np.pi * vib_rate * t)
    f = freq_track * vib
    phase = 2 * np.pi * np.cumsum(f) / SR
    out = np.zeros(n)
    for h in range(1, 40):
        hf = h * np.median(f)
        if hf > 5200:
            break
        formant = (
            1.0 * np.exp(-((hf - 700 * fs) / 260) ** 2)
            + 0.7 * np.exp(-((hf - 1150 * fs) / 300) ** 2)
            + 0.35 * np.exp(-((hf - 2600 * fs) / 500) ** 2)
        )
        out += (formant + 0.02) / h ** 0.8 * np.sin(h * phase)
    out += 0.015 * rng.standard_normal(n) * amp_env
    return out * amp_env


def phrase(tonic, scale, notes, tempo, vib_rate, fs):
    """notes: list of (scale degree, seconds, glide seconds)."""
    pieces = []
    prev = None
    for degree, dur, glide in notes:
        dur *= tempo
        n = int(dur * SR)
        semis = scale[degree % 7] + 12 * (degree // 7)
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
        pieces.append(voice(track, dur, env, vib_rate, fs))
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


def adhan(name):
    maqam, tonic, tempo, skeleton, vib, fs, rev = VOICES[name]
    global rng
    rng = np.random.default_rng(sum(map(ord, name)))
    lines = SKELETONS[skeleton]
    if name == 'adhan_takbeer':
        lines = [lines[0], lines[1]]  # just the takbir calls
    parts = []
    for line in lines:
        parts += [phrase(tonic, MAQAM[maqam], line, tempo, vib, fs), gap(.3)]
    return finish(reverb(np.concatenate(parts[:-1]), rev, 0.28))


def calm():
    """Soft four-note bell chime."""
    out = np.zeros(int(8 * SR))
    for f, start in [(523.25, 0.0), (659.25, 0.55), (783.99, 1.1), (1046.5, 1.9)]:
        n = int(5.5 * SR)
        t = np.arange(n) / SR
        env = np.exp(-t / 1.25) * np.clip(t / 0.01, 0, 1)
        tone = sum(a * np.sin(2 * np.pi * f * m * t) * np.exp(-t * d)
                   for m, a, d in [(1, 1, 0), (2.0, .35, .8), (3.01, .18, 1.6), (4.2, .08, 2.4)])
        s = int(start * SR)
        out[s:s + n] += (tone * env)[: len(out) - s]
    return finish(reverb(out, 1.4, 0.2), tail=0.8)


def make(name):
    return calm() if name == 'adhan_calm' else adhan(name)


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
    for name in VOICES:
        x = make(name)
        secs = len(x) / SR
        assert secs < 26, f'{name} is {secs:.1f}s (iOS limit is 30s)'
        wav = os.path.join(ROOT, 'assets/audio', f'{name}.wav')
        write_wav(wav, x)
        write_wav(os.path.join(ROOT, 'android/app/src/main/res/raw', f'{name}.wav'), x)
        subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
                        os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
        print(f'{name}: {secs:.1f}s')
