# -*- coding: utf-8 -*-
"""Prepares the muezzin recordings used for the Adhan notification sound.

Every sound ships as three files that share a base name `adhan_<id>`:
  assets/audio/adhan_<id>.wav                in-app preview
  ios/Runner/adhan_<id>.caf                  iOS notification sound (< 30 s, bundled)
  android/app/src/main/res/raw/adhan_<id>.wav   Android notification sound

Usage (macOS: needs ffmpeg, numpy and afconvert):
  python3 tool/adhan_audio.py folder
      Converts every recording listed in FOLDER_SOURCES from the `mp3/` folder:
        * notification clip, first <= 28 s (cut at a quiet moment, fade-out),
        * "two takbeers" clip: the file listed in TAKBEER_SOURCES when there is
          one, else the first line up to the first long pause (best guess),
        * the whole adhan for in-app playback (assets/audio/full/*.m4a).

  python3 tool/adhan_audio.py import <id> <audio-file> [--takbeer]
      Same for any other recording, then add one entry to the `AdhanSound` enum
      (lib/features/notifications/domain/entities/adhan_sound.dart).
      --takbeer keeps only the opening takbir (about 10 s).

Only use recordings you are licensed to redistribute inside the app.
"""
import hashlib
import re
import tempfile
import unicodedata
import os
import subprocess
import sys
import wave

import numpy as np

SR = 16000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# id -> file inside mp3/ (recordings supplied by the app owner)
FOLDER_SOURCES = {
    'ali_mulla': 'علي بن أحمد ملا .mp3',
    'ali_mulla_2': 'علي ملا .mp3',
    'hadrawi': 'فاروق عبد الرحمن حضراوي .mp3',
    'dagriri': 'حمد الدغريري .mp3',
    'abdulbasit': 'الشيخ عبدالباسط .mp3',
    'qatami': 'ناصر القطامي .mp3',
    'dosari': 'ياسر الدوسري .mp3',
    'nasser_obaid': 'ناصر العبيد .mp3',
    'ramadan_saad': 'محمد رمضان سعد .mp3',
    'basaad': 'محمد باسعد.mp3',
    'ibrahim_madani': 'إبراهيم المدني.mp3',
    'hussein_shahat': 'حسين شحات.mp3',
    'suhail_hafez': 'سهيل حافظ.mp3',
    'rajhi': 'جامع الراجحي.mp3',
}
# Dedicated "two takbeers" recordings dropped into mp3/ (matched like above).
TAKBEER_SOURCES = {
    'dagriri': 'حمد الدغريري (تكبيراتان).mp3',
}
FULL_SR = 24000  # in-app full adhan (AAC); the notification clips stay 16 kHz
FULL_KBPS = 48
TARGET_LUFS = -10.5  # loud; the notification volume is the phone's
MAX_SECONDS = 28.0  # + 0.2 s tail: stays under iOS's 30 s notification limit


def decode(path, sr=None):
    """Any audio file -> mono float32 at SR (via ffmpeg)."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(sr or SR),
         '-f', 'f32le', '-'],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype='<f4').copy()


def frame_rms(x, ms=60, sr=None):
    n = int((sr or SR) * ms / 1000)
    k = len(x) // n
    return np.sqrt((x[: k * n].reshape(k, n) ** 2).mean(axis=1)), n


def trim_start(x, sr=None):
    sr = sr or SR
    rms, n = frame_rms(x, sr=sr)
    thr = max(rms.max() * 0.08, 1e-4)
    first = int(np.argmax(rms > thr))
    return x[max(0, first * n - int(0.15 * sr)):]


def cut(x, lo, hi):
    """End the clip at the quietest moment between lo..hi seconds."""
    if len(x) / SR <= hi:
        return x
    rms, n = frame_rms(x)
    a, b = int(lo * SR / n), int(hi * SR / n)
    smooth = np.convolve(rms, np.ones(3) / 3, mode='same')
    end = (a + int(np.argmin(smooth[a:b]))) * n
    return x[:end]


def first_line_end(x, min_start=8.0, max_start=24.0, min_gap=0.8):
    """Seconds at which "الله أكبر الله أكبر" (the opening two takbeers) ends:
    the first pause of at least `min_gap` s that begins after `min_start` s
    (two takbeers never fit in less). Best guess, not hearing-checked."""
    n = int(SR * 0.04)
    k = len(x) // n
    rms = np.sqrt((x[: k * n].reshape(k, n) ** 2).mean(axis=1))
    quiet = rms < rms.max() * 0.06
    i = 0
    while i < k and i * n / SR <= max_start:
        if quiet[i]:
            j = i
            while j < k and quiet[j]:
                j += 1
            start, length = i * n / SR, (j - i) * n / SR
            if start >= min_start and length >= min_gap:
                return start + 0.15
            i = j
        else:
            i += 1
    return None


def fade_clip(x, fade):
    """Short fade-in, `fade` seconds of fade-out."""
    fi, fo = int(0.04 * SR), int(fade * SR)
    x = x.copy()
    x[:fi] *= np.linspace(0, 1, fi)
    x[-fo:] *= np.linspace(1, 0, fo)
    return x


def with_tail(x):
    return np.concatenate([x, np.zeros(int(0.2 * SR))])


def write_wav(path, x, sr=None):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr or SR)
        w.writeframes(pcm.tobytes())


def _lufs(x, sr):
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        write_wav(t.name, x, sr)
        out = subprocess.run(
            ['ffmpeg', '-nostats', '-i', t.name, '-af', 'ebur128', '-f', 'null',
             '-'], capture_output=True, text=True).stderr
    return float(re.findall(r'I:\s+(-?[\d.]+) LUFS', out)[-1])


def _punch(x, rms_db, ceil=0.84, knee=0.3):
    """Gain to a speech-RMS of rms_db dBFS, then a soft limiter below ceil."""
    a = np.abs(x)
    act = x[a > a.max() * 0.05]
    y = x * (10 ** (rms_db / 20) / np.sqrt((act ** 2).mean()))
    m = np.abs(y)
    soft = np.sign(y) * (knee + (ceil - knee) * np.tanh((m - knee) / (ceil - knee)))
    return np.where(m < knee, y, soft)


def loudify(x, sr=None, target=TARGET_LUFS):
    """Makes the clip as loud as the notification can be: bisects the gain so
    the integrated loudness reaches `target` LUFS (soft-limited, never above
    -1 dBFS). Notification volume itself is controlled by the phone."""
    sr = sr or SR
    lo, hi = -24.0, -3.0
    for _ in range(7):
        mid = (lo + hi) / 2
        if _lufs(_punch(x, mid), sr) < target:
            lo = mid
        else:
            hi = mid
    y = _punch(x, hi)
    # Inter-sample peaks of a saturated wave can exceed the sample ceiling:
    # estimate the true peak (4x FFT upsample) and keep it below -0.5 dBFS.
    spec = np.fft.rfft(y)
    up = np.zeros(len(spec) * 4 - 3, complex)
    up[:len(spec)] = spec
    tp = np.abs(np.fft.irfft(up)).max() * 4
    return y * min(1.0, 0.94 / tp)


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


def _emit(name, x, preview):
    """Writes android raw wav + iOS caf (+ in-app preview wav)."""
    secs = len(x) / SR
    assert secs < 29, f'{name} is {secs:.1f}s (iOS limit is 30s)'
    raw = os.path.join(ROOT, 'android/app/src/main/res/raw')
    os.makedirs(raw, exist_ok=True)
    os.makedirs(os.path.join(ROOT, 'ios/Runner'), exist_ok=True)
    wav = os.path.join(raw, f'{name}.wav')
    write_wav(wav, x)
    if preview:
        os.makedirs(os.path.join(ROOT, 'assets/audio'), exist_ok=True)
        write_wav(os.path.join(ROOT, 'assets/audio', f'{name}.wav'), x)
    subprocess.run(['afconvert', '-f', 'caff', '-d', 'LEI16', wav,
                    os.path.join(ROOT, 'ios/Runner', f'{name}.caf')], check=True)
    register_in_xcode(f'{name}.caf')
    print(f'{name}: {secs:.1f}s')


def emit_full(sound_id, src):
    """The whole adhan for in-app playback: assets/audio/full/adhan_<id>.m4a."""
    x = trim_start(decode(src, FULL_SR), FULL_SR)
    x = loudify(fade_clip_sr(x, 2.5, FULL_SR), FULL_SR)
    out_dir = os.path.join(ROOT, 'assets/audio/full')
    os.makedirs(out_dir, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.wav') as t:
        write_wav(t.name, x, FULL_SR)
        out = os.path.join(out_dir, f'adhan_{sound_id}.m4a')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', t.name, '-c:a',
                        'aac', '-b:a', f'{FULL_KBPS}k', '-ac', '1', out],
                       check=True)
    print(f'adhan_{sound_id}.m4a: {len(x) / FULL_SR:.0f}s, '
          f'{os.path.getsize(out) / 1e6:.1f} MB')


def fade_clip_sr(x, fade, sr):
    fi, fo = int(0.04 * sr), int(fade * sr)
    x = x.copy()
    x[:fi] *= np.linspace(0, 1, fi)
    x[-fo:] *= np.linspace(1, 0, fo)
    return x


def build(sound_id, src, takbeer=False, fade=0.45, takbeer_src=None):
    """Notification clip (adhan_<id>, also the in-app preview), the two-takbeers
    clip (adhan_<id>_short; the app calls it "تكبيرتان") and the in-app full
    adhan. Each is chosen from the app settings."""
    x = trim_start(decode(src))
    full = cut(x, 5, 13) if takbeer else cut(x, 14, MAX_SECONDS)
    if takbeer_src:
        short = trim_start(decode(takbeer_src))
        how = 'dedicated file'
    else:
        end = first_line_end(x)
        short = x[: int(end * SR)] if end else cut(x, 10, 16)
        how = f'first pause at {end:.1f}s' if end else 'fallback 10-16 s'
    print(f'{sound_id}: two takbeers = {len(short) / SR:.1f}s ({how})')
    _emit(f'adhan_{sound_id}', with_tail(loudify(fade_clip(full, fade))), True)
    _emit(f'adhan_{sound_id}_short',
          with_tail(loudify(fade_clip(short, 0.7))), False)
    emit_full(sound_id, src)


if __name__ == '__main__':
    args = sys.argv[1:]
    if args[:1] == ['folder']:
        folder = os.path.join(ROOT, 'mp3')
        # macOS may store Arabic names decomposed / with odd spacing.
        norm = lambda n: ''.join(unicodedata.normalize('NFC', n).split())
        files = {norm(f): f for f in os.listdir(folder)}
        for sid, name in FOLDER_SOURCES.items():
            tk = TAKBEER_SOURCES.get(sid)
            build(sid, os.path.join(folder, files[norm(name)]), fade=2.0,
                  takbeer_src=os.path.join(folder, files[norm(tk)])
                  if tk else None)
    elif args[:1] == ['import'] and len(args) >= 3:
        build(args[1], args[2], takbeer='--takbeer' in args, fade=2.0)
    else:
        print(__doc__)
