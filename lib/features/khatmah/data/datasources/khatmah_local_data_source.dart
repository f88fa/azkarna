import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/khatmah_model.dart';

abstract interface class KhatmahLocalDataSource {
  Future<KhatmahModel> getProgress();
  Future<void> saveProgress(KhatmahModel progress);
}

class SharedPrefsKhatmahDataSource implements KhatmahLocalDataSource {
  const SharedPrefsKhatmahDataSource(this._prefs);

  static const String _key = 'khatmah_progress';

  final SharedPreferences _prefs;

  @override
  Future<KhatmahModel> getProgress() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return const KhatmahModel();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return KhatmahModel.fromJson(decoded);
      }
    } on FormatException {
      // Corrupted payload: fall through to defaults.
    }
    return const KhatmahModel();
  }

  @override
  Future<void> saveProgress(KhatmahModel progress) async {
    await _prefs.setString(_key, jsonEncode(progress.toJson()));
  }
}
