# -*- coding: utf-8 -*-
"""Generates the soft chime used by «نغمة تنبيه إسلامية هادئة» (adhan_calm).

This is a plain synthesized bell tone, not a voice. The muezzin sounds are real
recordings prepared by tool/adhan_audio.py.

Run:  python3 tool/gen_sounds.py   (macOS: needs numpy and afconvert)
"""
import os
import subprocess
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from adhan_audio import ROOT, register_in_xcode  # noqa: E402

SR = 22050
rng = np.random.default_rng(7)


def reverb(x, seconds=1.4, mix=0.2):
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (0.42 * SR))
    ir[0] = 0
    size = 1 << (len(x) + n).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    wet /= np.max(np.abs(wet)) + 1e-9
    x = x / (np.max(np.abs(x)) + 1e-9)
    return (1 - mix) * x + mix * wet


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
    x = np.concatenate([reverb(out), np.zeros(int(0.3 * SR))])
    fade = int(0.8 * SR)
    x[-fade:] *= np.linspace(1, 0, fade)
    return x / (np.max(np.abs(x)) + 1e-9) * 0.7


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == '__main__':
    x = calm()
    wav = os.path.join(ROOT, 'assets/audio/adhan_calm.wav')
    write_wav(wav, x)
    write_wav(os.path.join(ROOT, 'android/app/src/main/res/raw/adhan_calm.wav'), x)
    subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
                    os.path.join(ROOT, 'ios/Runner/adhan_calm.caf')], check=True)
    register_in_xcode('adhan_calm.caf')
    print(f'adhan_calm: {len(x) / SR:.1f}s')
