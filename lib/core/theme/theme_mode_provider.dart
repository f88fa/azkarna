import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/shared_preferences_provider.dart';

const String themeModePrefsKey = 'theme_mode';

/// App-wide light / dark / follow-the-system choice, saved locally.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _decode(
    ref.watch(sharedPreferencesProvider).getString(themeModePrefsKey),
  );

  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(themeModePrefsKey, mode.name);
  }

  static ThemeMode _decode(String? name) => ThemeMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => ThemeMode.system,
  );
}
