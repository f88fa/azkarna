import 'package:flutter/foundation.dart';

import 'adhan_sound.dart';

/// A tap on one of the app's notifications (its payload).
@immutable
class NotificationTap {
  const NotificationTap(this.payload);

  /// Compared by identity, so every tap is a new event for listeners.
  final String payload;
}

/// Taps reach the app from outside the widget tree (the notification plugin
/// calls back, or the app was launched by the tap). The latest tap waits here
/// until the UI listens, so a cold start by tapping the notification works.
abstract final class NotificationTaps {
  static final ValueNotifier<NotificationTap?> latest = ValueNotifier(null);

  static void add(String? payload) {
    if (payload == null || payload.isEmpty) return;
    latest.value = NotificationTap(payload);
  }
}

/// The payload carried by Adhan notifications: which muezzin is playing and
/// for which prayer, so that a tap plays the same adhan in full in the app.
@immutable
class AdhanPayload {
  const AdhanPayload(this.sound, this.prayerLabel, this.duration);

  static const _prefix = 'adhan|';

  final AdhanSound sound;
  final String prayerLabel;

  /// Only the full option plays the whole adhan in the app on a tap; with
  /// `short` the user asked for just the takbeers.
  final AdhanDuration duration;

  String encode() => '$_prefix${sound.id}|$prayerLabel|${duration.name}';

  /// Null when [payload] is not an Adhan payload.
  static AdhanPayload? tryParse(String? payload) {
    if (payload == null || !payload.startsWith(_prefix)) return null;
    final parts = payload.substring(_prefix.length).split('|');
    if (parts.isEmpty || parts.first.isEmpty) return null;
    return AdhanPayload(
      AdhanSound.fromId(parts.first),
      parts.length > 1 ? parts[1] : '',
      AdhanDuration.fromName(parts.length > 2 ? parts[2] : null),
    );
  }
}
