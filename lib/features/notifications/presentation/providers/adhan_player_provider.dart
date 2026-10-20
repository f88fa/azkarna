import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/adhan_sound.dart';
import 'sound_preview_provider.dart';

/// The adhan currently playing in full inside the app.
class AdhanPlayback {
  const AdhanPlayback(this.sound, this.prayerLabel);

  final AdhanSound sound;

  /// Empty when it was not started for a prayer.
  final String prayerLabel;

  String get title => prayerLabel.isEmpty ? 'الأذان' : 'أذان صلاة $prayerLabel';
}

/// Plays the whole adhan (2-5 minutes) of a muezzin inside the app. A
/// notification sound is cut at 30 s by iOS and by any other notification, so
/// tapping the notification starts the real adhan here, under an audio
/// session that other apps' notification sounds do not interrupt. The state
/// is what plays now (or null); `stop` ends it.
final adhanPlayerProvider =
    NotifierProvider<AdhanPlayerNotifier, AdhanPlayback?>(
      AdhanPlayerNotifier.new,
    );

class AdhanPlayerNotifier extends Notifier<AdhanPlayback?> {
  AudioPlayer? _player;

  @override
  AdhanPlayback? build() {
    ref.onDispose(() => _player?.dispose());
    return null;
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    // `playback`: audible with the silent switch on, and not stopped by the
    // sounds of other apps' notifications.
    await player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {},
        ),
      ),
    );
    player.onPlayerComplete.listen((_) {
      if (ref.mounted) state = null;
    });
    return _player = player;
  }

  /// Starts the full adhan; ignored when this one is already playing (a tap
  /// can be reported twice on a cold start).
  Future<void> play(AdhanSound sound, {String prayerLabel = ''}) async {
    final current = state;
    if (current != null && current.sound == sound) return;
    try {
      await ref.read(soundPreviewProvider.notifier).stop();
      final player = await _ensurePlayer();
      await player.stop();
      state = AdhanPlayback(sound, prayerLabel);
      await player.play(AssetSource(sound.fullAsset));
    } catch (_) {
      if (ref.mounted) state = null;
    }
  }

  Future<void> stop() async {
    if (ref.mounted) state = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
