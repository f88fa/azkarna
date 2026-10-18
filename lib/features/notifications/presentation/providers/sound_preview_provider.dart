import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/adhan_sound.dart';

/// Plays the in-app preview of an Adhan sound. The state is the sound that is
/// currently playing (or null), so the UI can show a play / stop button.
final soundPreviewProvider =
    NotifierProvider<SoundPreviewNotifier, AdhanSound?>(
      SoundPreviewNotifier.new,
    );

class SoundPreviewNotifier extends Notifier<AdhanSound?> {
  AudioPlayer? _player;

  @override
  AdhanSound? build() {
    ref.onDispose(() => _player?.dispose());
    return null;
  }

  /// Created lazily so nothing touches the platform until a preview is used.
  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    // `playback` ignores the iPhone's silent switch, so the preview is audible.
    await player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {},
        ),
      ),
    );
    player.onPlayerComplete.listen((_) => state = null);
    return _player = player;
  }

  /// Plays [sound], or stops it when it is already playing.
  Future<void> toggle(AdhanSound sound) async {
    try {
      final player = await _ensurePlayer();
      if (state == sound) {
        await player.stop();
        state = null;
        return;
      }
      await player.stop();
      state = sound;
      await player.play(AssetSource(sound.previewAsset));
    } catch (_) {
      state = null;
    }
  }

  Future<void> stop() async {
    state = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
