import 'dart:convert';
import 'dart:io';

import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/quran/data/models/surah_model.dart';
import 'package:azkarna/features/quran/domain/entities/quran_index.dart';
import 'package:azkarna/features/quran/presentation/screens/mushaf_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuranIndex _loadIndex() {
  final json = jsonDecode(File('assets/json/quran.json').readAsStringSync());
  return QuranIndex([for (final s in json as List) SurahModel.fromJson(s)]);
}

void main() {
  test('the whole Quran is bundled with Madani Mushaf page numbers', () {
    final index = _loadIndex();
    expect(index.surahs, hasLength(114));
    expect(index.surahs.fold<int>(0, (n, s) => n + s.ayahCount), 6236);

    // Well-known facts about the 604-page Madani Mushaf.
    expect(index.surah(1)!.startPage, 1);
    expect(index.surah(2)!.startPage, 2);
    expect(index.surah(2)!.ayahCount, 286);
    expect(index.surah(2)!.pageOf(255), 42); // Ayat al-Kursi
    expect(index.surah(18)!.startPage, 293); // Al-Kahf
    expect(index.surah(36)!.startPage, 440); // Ya-Sin
    expect(index.surah(67)!.startPage, 562); // Al-Mulk
    expect(index.surah(114)!.startPage, 604);

    for (var p = 1; p <= QuranIndex.pageCount; p++) {
      expect(index.page(p).segments, isNotEmpty, reason: 'page $p is empty');
    }
    expect(index.juzStart(1).page, 1);
    expect(index.juzStart(30).page, 582);
  });

  test('the Basmalah heading is not repeated inside the first ayah', () {
    final index = _loadIndex();
    final baqarah = index.surah(2)!;
    expect(baqarah.hasBismillahHeader, isTrue);
    expect(baqarah.ayahs.first.text, isNot(startsWith('بِسْمِ')));
    // Al-Fatihah keeps it as ayah 1, At-Tawbah has none.
    expect(index.surah(1)!.ayahs.first.text, startsWith('بِسْمِ'));
    expect(index.surah(9)!.hasBismillahHeader, isFalse);
  });

  test('page 2 shows the start of Al-Baqarah only', () {
    final page = _loadIndex().page(2);
    expect(page.segments.single.surah.number, 2);
    expect(page.segments.single.startsSurah, isTrue);
    expect(page.segments.single.ayahs.first.number, 1);
  });

  testWidgets('reader: tap an ayah and save the "where I stopped" bookmark', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const MushafReaderScreen(initialPage: 2),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('سورة البقرة'), findsWidgets);
    expect(find.text('٢'), findsWidgets); // page number
    expect(find.textContaining('الجزء ١'), findsOneWidget);

    await tester.tapOnText(find.textRange.ofSubstring('الٓمٓ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحة ٢ · الجزء ١'), findsOneWidget);

    await tester.tap(find.text('وقفت هنا · احفظ العلامة'));
    await tester.pumpAndSettle();

    final saved = jsonDecode(prefs.getString('khatmah_progress')!) as Map;
    expect(saved['surah'], 2);
    expect(saved['ayah'], 1);
    expect(find.textContaining('تم حفظ العلامة'), findsOneWidget);
  });
}
