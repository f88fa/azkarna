# -*- coding: utf-8 -*-
"""Prepares the voiced pre-prayer alert sounds ("اقتربت صلاة …").

Source MP3s live in `iqtarabamp3/`. Each becomes
  ios/Runner/before_<prayer>.caf                      (iOS notification sound)
  android/app/src/main/res/raw/before_<prayer>.wav    (Android notification sound)
and the .caf is registered in ios/Runner.xcodeproj/project.pbxproj.

Usage (macOS: needs ffmpeg and afconvert):  python3 tool/before_prayer_audio.py
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402
from adhan_audio import (  # noqa: E402
    ROOT, decode, loudify, register_in_xcode, write_wav)

SR = 24000

# prayer id (matches the Dart `Prayer` enum name) -> source file
SOURCES = {
    'fajr': 'iqtaraba_fajr_male_calm.mp3',
    'dhuhr': 'iqtaraba_duhr_male_calm.mp3',
    'asr': 'iqtaraba_asr_male_calm.mp3',
    'maghrib': 'iqtaraba_maghrib_male_calm.mp3',
    'isha': 'iqtaraba_isha_male_calm.mp3',
}


def main():
    raw = os.path.join(ROOT, 'android/app/src/main/res/raw')
    os.makedirs(raw, exist_ok=True)
    for pid, src in SOURCES.items():
        name = f'before_{pid}'
        wav = os.path.join(raw, f'{name}.wav')
        x = decode(os.path.join(ROOT, 'iqtarabamp3', src), SR)
        x = np.concatenate([loudify(x, SR, -12.0), np.zeros(int(0.15 * SR))])
        write_wav(wav, x, SR)
        subprocess.run(
            ['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
             os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
        register_in_xcode(f'{name}.caf')
        print(name)


if __name__ == '__main__':
    main()
