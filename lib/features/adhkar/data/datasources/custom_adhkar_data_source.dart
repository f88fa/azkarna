import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhkar_category.dart';

/// Stores the user's own adhkar as a JSON list in SharedPreferences.
class CustomAdhkarDataSource {
  const CustomAdhkarDataSource(this._prefs);

  static const String _key = 'custom_adhkar_v1';

  final SharedPreferences _prefs;

  List<Dhikr> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map && item['id'] is String && item['text'] is String)
            Dhikr(
              id: item['id'] as String,
              text: item['text'] as String,
              translation: '',
              count: item['count'] is int && (item['count'] as int) > 0
                  ? item['count'] as int
                  : 1,
              reference: '',
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<Dhikr> items) => _prefs.setString(
    _key,
    jsonEncode([
      for (final d in items) {'id': d.id, 'text': d.text, 'count': d.count},
    ]),
  );
}
