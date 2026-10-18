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
from adhan_audio import ROOT, register_in_xcode  # noqa: E402

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
        subprocess.run(
            ['ffmpeg', '-y', '-v', 'error', '-i',
             os.path.join(ROOT, 'azkarmp3', src), '-ac', '1', '-ar', '24000',
             '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=0.15',
             '-c:a', 'pcm_s16le', wav], check=True)
        subprocess.run(
            ['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
             os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
        register_in_xcode(f'{name}.caf')
        print(name)


if __name__ == '__main__':
    main()
