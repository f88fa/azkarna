# -*- coding: utf-8 -*-
"""Prepares the REAL muezzin recordings used for the Adhan notification sound.

Every sound ships as three files that share a base name `adhan_<id>`:
  assets/audio/adhan_<id>.wav                in-app preview
  ios/Runner/adhan_<id>.caf                  iOS notification sound (< 30 s, bundled)
  android/app/src/main/res/raw/adhan_<id>.wav   Android notification sound

Usage (macOS: needs ffmpeg, numpy and afconvert):

  python3 tool/adhan_audio.py fetch
      Downloads the freely licensed recordings listed in SOURCES from Wikimedia
      Commons (see assets/audio/CREDITS.md for authors and licences) and
      converts them.

  python3 tool/adhan_audio.py fetch-archive
      Same for the named muezzins listed in ARCHIVE (archive.org). Those items
      have no licence metadata - see the note above ARCHIVE.

  python3 tool/adhan_audio.py import <id> <audio-file> [--takbeer]
      Converts YOUR OWN licensed recording (mp3 / m4a / wav / ogg ...) of any
      muezzin into the three files above and registers the .caf in
      ios/Runner.xcodeproj/project.pbxproj. Then add one entry to the
      `AdhanSound` enum (lib/features/notifications/domain/entities/adhan_sound.dart).
      --takbeer keeps only the opening takbir (about 10 s).

Only use recordings you are licensed to redistribute inside the app.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import wave

import numpy as np

SR = 16000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = '/tmp/adhan_src'
UA = {'User-Agent': 'AwwabApp/1.0 (adhan sound preparation)'}

# id -> Wikimedia Commons file title (all freely licensed, see CREDITS.md)
SOURCES = {
    'nabawi': '33937 ejaz215 call-to-prayer-from-the-prophet-s-mo.ogg',
    'sabah_fakhri': 'Call to prayer by Sabah Fakhry.mp3',
    'maahur': 'AzaanMaahur.ogg',
    'voice_1': 'Adhan.ogg',
    'voice_2': 'Beautiful adhan.ogg',
}

# id -> archive.org item identifier. These items carry NO licence metadata:
# they are third-party uploads, so redistribution rights are the publisher's
# responsibility (see assets/audio/CREDITS.md).
ARCHIVE = {
    'makkah_mulla': 'athan_maghrib_1-6-2014_ali_mulla',
    'madinah': 'azan-madinah',
    'aqsa': 'youtube-Vb_O4tZytrI',
    'afasy': 'AdhanMisharyRashid',
    'qatami': 'azan-by-nasir-al-qatami',
    'zahrani': 'adhan_fajr_mansour_zahrani',
    'sobhi': 'A.S.I.S',
    'zayed': 'MostBeautifulAzanEverHeardWhichWillMakeYouSheikhZayedGrandMosqmp3cut.net',
}
MAX_SECONDS = 28.0  # + 0.2 s tail: stays under iOS's 30 s notification limit


def decode(path):
    """Any audio file -> mono float32 at SR (via ffmpeg)."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR),
         '-f', 'f32le', '-'],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype='<f4').copy()


def frame_rms(x, ms=60):
    n = int(SR * ms / 1000)
    k = len(x) // n
    return np.sqrt((x[: k * n].reshape(k, n) ** 2).mean(axis=1)), n


def trim_start(x):
    rms, n = frame_rms(x)
    thr = max(rms.max() * 0.08, 1e-4)
    first = int(np.argmax(rms > thr))
    return x[max(0, first * n - int(0.15 * SR)):]


def cut(x, lo, hi):
    """End the clip at the quietest moment between lo..hi seconds."""
    if len(x) / SR <= hi:
        return x
    rms, n = frame_rms(x)
    a, b = int(lo * SR / n), int(hi * SR / n)
    smooth = np.convolve(rms, np.ones(3) / 3, mode='same')
    end = (a + int(np.argmin(smooth[a:b]))) * n
    return x[:end]


def finish(x, fade=0.45):
    fi, fo = int(0.04 * SR), int(fade * SR)
    x = x.copy()
    x[:fi] *= np.linspace(0, 1, fi)
    x[-fo:] *= np.linspace(1, 0, fo)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    return np.concatenate([x, np.zeros(int(0.2 * SR))])


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def register_in_xcode(caf_name):
    """Adds <caf_name> to the Runner target's Resources (idempotent)."""
    p = os.path.join(ROOT, 'ios/Runner.xcodeproj/project.pbxproj')
    text = open(p, encoding='utf-8').read()
    if caf_name in text:
        return
    fid = lambda k: hashlib.md5(k.encode()).hexdigest()[:24].upper()
    ref, bld = fid('f' + caf_name), fid('b' + caf_name)
    lines = text.split('\n')

    def insert_after(pred, new):
        for i, l in enumerate(lines):
            if pred(l):
                lines[i + 1:i + 1] = [new]
                return
        raise SystemExit('project.pbxproj layout not recognised')

    insert_after(lambda l: '/* Begin PBXBuildFile section */' in l,
                 f'\t\t{bld} /* {caf_name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {caf_name} */; }};')
    insert_after(lambda l: '/* Begin PBXFileReference section */' in l,
                 f'\t\t{ref} /* {caf_name} */ = {{isa = PBXFileReference; lastKnownFileType = audio.caf; path = {caf_name}; sourceTree = "<group>"; }};')
    for i, l in enumerate(lines):
        if l.strip() == 'path = Runner;':
            j = i
            while 'children = (' not in lines[j]:
                j -= 1
            lines[j + 1:j + 1] = [f'\t\t\t\t{ref} /* {caf_name} */,']
            break
    for i, l in enumerate(lines):
        if '97C146EC1CF9000F007C117D /* Resources */ = {' in l:
            j = i
            while 'files = (' not in lines[j]:
                j += 1
            lines[j + 1:j + 1] = [f'\t\t\t\t{bld} /* {caf_name} in Resources */,']
            break
    open(p, 'w', encoding='utf-8').write('\n'.join(lines))


def build(sound_id, src, takbeer=False, fade=0.45):
    name = f'adhan_{sound_id}'
    x = trim_start(decode(src))
    x = cut(x, 5, 13) if takbeer else cut(x, 14, MAX_SECONDS)
    x = finish(x, fade)
    secs = len(x) / SR
    assert secs < 29, f'{name} is {secs:.1f}s (iOS limit is 30s)'
    for d in ('assets/audio', 'android/app/src/main/res/raw', 'ios/Runner'):
        os.makedirs(os.path.join(ROOT, d), exist_ok=True)
    wav = os.path.join(ROOT, 'assets/audio', f'{name}.wav')
    write_wav(wav, x)
    write_wav(os.path.join(ROOT, 'android/app/src/main/res/raw', f'{name}.wav'), x)
    subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
                    os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
    register_in_xcode(f'{name}.caf')
    print(f'{name}: {secs:.1f}s')


def fetch_archive(item):
    """Downloads the first audio file of an archive.org item (cached)."""
    os.makedirs(CACHE, exist_ok=True)
    meta = json.load(urllib.request.urlopen(urllib.request.Request(
        'https://archive.org/metadata/' + urllib.parse.quote(item), headers=UA),
        timeout=60))
    audio = [f for f in meta['files']
             if f['name'].lower().endswith(('.mp3', '.m4a', '.ogg', '.webm'))
             and f.get('source') == 'original']
    if not audio:
        raise SystemExit(f'{item}: no audio file')
    f = max(audio, key=lambda f: int(f.get('size', 0)) if int(f.get('size', 0)) < 30e6 else 0)
    ext = os.path.splitext(f['name'])[1]
    dest = os.path.join(CACHE, 'ia_' + re.sub(r'[^\w.]+', '_', item) + ext)
    if not os.path.exists(dest):
        url = f'https://archive.org/download/{item}/' + urllib.parse.quote(f['name'])
        blob = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=180).read()
        with open(dest, 'wb') as out:
            out.write(blob)
    return dest


def fetch(title):
    os.makedirs(CACHE, exist_ok=True)
    dest = os.path.join(CACHE, re.sub(r'[^\w.]+', '_', title))
    if os.path.exists(dest):
        return dest
    api = ('https://commons.wikimedia.org/w/api.php?action=query&format=json'
           '&prop=imageinfo&iiprop=url&titles=' + urllib.parse.quote('File:' + title))
    data = json.load(urllib.request.urlopen(urllib.request.Request(api, headers=UA)))
    url = next(iter(data['query']['pages'].values()))['imageinfo'][0]['url']
    for attempt in range(6):  # Commons rate-limits bursts: back off and retry
        try:
            blob = urllib.request.urlopen(urllib.request.Request(url, headers=UA)).read()
            break
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == 5:
                raise
            time.sleep(8 * (attempt + 1))
    with open(dest, 'wb') as f:
        f.write(blob)
    time.sleep(3)
    return dest


if __name__ == '__main__':
    args = sys.argv[1:]
    if args[:1] == ['fetch']:
        for sid, title in SOURCES.items():
            build(sid, fetch(title))
        # The takbir-only sound is the opening of the Prophet's Mosque recording.
        build('takbeer', fetch(SOURCES['nabawi']), takbeer=True)
    elif args[:1] == ['fetch-archive']:
        for sid, item in ARCHIVE.items():
            build(sid, fetch_archive(item), fade=2.0)
    elif args[:1] == ['import'] and len(args) >= 3:
        build(args[1], args[2], takbeer='--takbeer' in args)
    else:
        print(__doc__)
