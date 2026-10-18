import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';

/// Surah Al-Kahf is number 18.
const int kahfSurahNumber = 18;

const String _progressKey = 'kahf_progress';
const String _fontKey = 'kahf_font_size';

/// How far through Al-Kahf the reader got (0 – 1), saved automatically.
final kahfProgressProvider = NotifierProvider<KahfProgressNotifier, double>(
  KahfProgressNotifier.new,
);

class KahfProgressNotifier extends Notifier<double> {
  @override
  double build() =>
      (ref.watch(sharedPreferencesProvider).getDouble(_progressKey) ?? 0).clamp(
        0.0,
        1.0,
      );

  Future<void> save(double value) async {
    if (!ref.mounted) return;
    final v = value.clamp(0.0, 1.0);
    if ((v - state).abs() < 0.001) return;
    state = v;
    await ref.read(sharedPreferencesProvider).setDouble(_progressKey, v);
  }
}

/// Reader font size, kept between sessions.
final kahfFontSizeProvider = NotifierProvider<KahfFontSizeNotifier, double>(
  KahfFontSizeNotifier.new,
);

class KahfFontSizeNotifier extends Notifier<double> {
  static const double min = 22;
  static const double max = 42;
  static const double initial = 30;

  @override
  double build() =>
      (ref.watch(sharedPreferencesProvider).getDouble(_fontKey) ?? initial)
          .clamp(min, max);

  Future<void> change(double delta) async {
    state = (state + delta).clamp(min, max);
    await ref.read(sharedPreferencesProvider).setDouble(_fontKey, state);
  }
}
