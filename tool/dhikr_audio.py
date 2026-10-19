# -*- coding: utf-8 -*-
"""Prepares the voiced periodic-dhikr notification sounds.

Source MP3s live in `azkarmp3/`. Each becomes
  ios/Runner/dhikr_<id>.caf                      (iOS notification sound)
  android/app/src/main/res/raw/dhikr_<id>.wav    (Android notification sound)
and the .caf is registered in ios/Runner.xcodeproj/project.pbxproj.

Usage (macOS: needs ffmpeg and afconvert):  python3 tool/dhikr_audio.py
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402
from adhan_audio import (  # noqa: E402
    ROOT, decode, loudify, register_in_xcode, write_wav)

SR = 24000

# id -> source file in azkarmp3/ (the order is the rotation order in the app)
SOURCES = {
    'subhan_allah': 'subhan_allah_male.mp3',
    'la_ilaha_illa_allah': 'la_ilaha_illa_allah_male.mp3',
    'astaghfirullah': 'astaghfirullah_male.mp3',
    'allahumma_salli': 'allahumma_salli_male.mp3',
    'allahu_akbar': 'allahu_akbar_male_deep.mp3',
    'uthkur_allah': 'uthkur_allah_male.mp3',
    'subhan_allah_wa_bihamdihi': 'subhan_allah_wa_bihamdihi_male.mp3',
    'alhamdulillah': 'alhamdulillah_male.mp3',
}


def main():
    raw = os.path.join(ROOT, 'android/app/src/main/res/raw')
    os.makedirs(raw, exist_ok=True)
    for sid, src in SOURCES.items():
        name = f'dhikr_{sid}'
        wav = os.path.join(raw, f'{name}.wav')
        x = decode(os.path.join(ROOT, 'azkarmp3', src), SR)
        x = np.concatenate([loudify(x, SR, -12.0), np.zeros(int(0.15 * SR))])
        write_wav(wav, x, SR)
        subprocess.run(
            ['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
             os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
        register_in_xcode(f'{name}.caf')
        print(name)


if __name__ == '__main__':
    main()
