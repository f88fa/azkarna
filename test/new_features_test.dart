import 'dart:io';

import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/notifications/domain/entities/adhan_sound.dart';
import 'package:azkarna/features/notifications/domain/entities/dhikr_reminder.dart';
import 'package:azkarna/features/quran/presentation/screens/kahf_reader_screen.dart';
import 'package:azkarna/features/settings/presentation/screens/settings_screen.dart';
import 'package:azkarna/features/tasbeeh/presentation/providers/tasbeeh_providers.dart';
import 'package:azkarna/features/tasbeeh/presentation/screens/tasbeeh_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(SharedPreferences prefs, Widget home) => ProviderScope(
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
    home: home,
  ),
);

Future<SharedPreferences> _prefs([Map<String, Object> v = const {}]) async {
  SharedPreferences.setMockInitialValues(v);
  return SharedPreferences.getInstance();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('muezzin sound files', () {
    test(
      'exist for Android/iOS/preview, are short, and iOS registers them',
      () {
        final pbx = File(
          'ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();
        for (final sound in AdhanSound.values) {
          final wav = File('assets/audio/${sound.file}.wav');
          expect(wav.existsSync(), isTrue, reason: '${sound.file}.wav');
          // 22.05 kHz mono 16-bit => 44.1 kB/s; iOS needs < 30 s.
          expect(wav.lengthSync() / 44100, lessThan(29));
          expect(
            File('android/app/src/main/res/raw/${sound.file}.wav').existsSync(),
            isTrue,
          );
          expect(File('ios/Runner/${sound.iosFile}').existsSync(), isTrue);
          // Referenced as file, build file and in the resources phase.
          expect(
            RegExp(RegExp.escape(sound.iosFile)).allMatches(pbx).length,
            greaterThanOrEqualTo(4),
            reason: '${sound.iosFile} must be bundled in project.pbxproj',
          );
        }
      },
    );

    test('labels match the requested names', () {
      expect(AdhanSound.values.map((s) => s.label), [
        'أذان الحرم المكي',
        'أذان الحرم المدني',
        'مشاري العفاسي',
        'نغمة تنبيه هادئة',
      ]);
    });
  });

  group('periodic dhikr', () {
    test('quiet hours wrap past midnight', () {
      const s = DhikrReminderSettings();
      expect(s.isQuiet(23, 0), isTrue);
      expect(s.isQuiet(2, 30), isTrue);
      expect(s.isQuiet(4, 59), isTrue);
      expect(s.isQuiet(5, 0), isFalse);
      expect(s.isQuiet(14, 0), isFalse);
      expect(s.copyWith(quietHoursEnabled: false).isQuiet(2, 0), isFalse);
    });

    test('messages rotate through all four kinds', () {
      final titles = {for (var i = 0; i < 4; i++) DhikrMessages.at(i).title};
      expect(titles, hasLength(4));
      expect(DhikrMessages.at(0).body, isNot(DhikrMessages.at(4).body));
    });

    test('intervals', () {
      expect(DhikrInterval.values.map((i) => i.minutes), [15, 30, 60, 180]);
      expect(DhikrInterval.fromMinutes(999), DhikrInterval.hour);
    });
  });

  group('tasbeeh', () {
    test(
      'counts, keeps totals on reset, persists, rolls the day over',
      () async {
        final prefs = await _prefs();
        var now = DateTime(2026, 10, 17, 10);
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(tasbeehProvider.notifier)
          ..clock = () => now;

        await notifier.selectDhikr(2);
        for (var i = 0; i < 33; i++) {
          await notifier.tap();
        }
        var s = container.read(tasbeehProvider);
        expect(s.dhikr, 'لا حول ولا قوة إلا بالله');
        expect((s.count, s.today, s.total), (33, 33, 33));
        expect(s.justCompleted, isTrue);
        expect(s.progress, 1);

        await notifier.reset();
        s = container.read(tasbeehProvider);
        expect((s.count, s.today, s.total), (0, 33, 33));

        // Changing dhikr starts a fresh round, totals untouched.
        await notifier.tap();
        await notifier.selectDhikr(0);
        s = container.read(tasbeehProvider);
        expect((s.count, s.today, s.total), (0, 34, 34));

        // Next day: today restarts, total keeps growing.
        now = DateTime(2026, 10, 18, 9);
        await notifier.tap();
        s = container.read(tasbeehProvider);
        expect((s.today, s.total), (1, 35));

        // A new container (app restart) restores everything.
        final again = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(again.dispose);
        expect(again.read(tasbeehProvider).total, 35);
      },
    );

    testWidgets('screen: tap the dial to count, reset button zeroes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(_app(prefs, const TasbeehScreen()));
      await tester.pumpAndSettle();

      expect(find.text('أستغفر الله'), findsWidgets);
      expect(find.text('اللهم صل على محمد'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('اضغط للتسبيح')));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp('اضغط للتسبيح')));
      await tester.pumpAndSettle();
      expect(prefs.getInt('tasbeeh_count'), 2);
      expect(prefs.getInt('tasbeeh_total'), 2);

      await tester.tap(find.text('تصفير العدّاد'));
      await tester.pumpAndSettle();
      expect(prefs.getInt('tasbeeh_count'), 0);
      expect(prefs.getInt('tasbeeh_total'), 2);
    });
  });

  testWidgets('Al-Kahf reader saves the reading position', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final prefs = await _prefs();
    await tester.pumpWidget(_app(prefs, const KahfReaderScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('سورة الكهف'), findsWidgets);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(prefs.getDouble('kahf_progress'), greaterThan(0));
  });

  testWidgets('settings shows muezzin voices and periodic dhikr', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 6400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final prefs = await _prefs();
    await tester.pumpWidget(_app(prefs, const SettingsScreen()));
    await tester.pumpAndSettle();

    for (final text in [
      'صوت المؤذن',
      'أذان الحرم المكي',
      'أذان الحرم المدني',
      'مشاري العفاسي',
      'نغمة تنبيه هادئة',
      'تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)',
      'تذكيرات الذكر الدورية',
      'كل ١٥ دقيقة',
      'كل نصف ساعة',
      'كل ساعة',
      'كل ٣ ساعات',
      'وقت الهدوء أثناء النوم',
      'تجربة إشعار ذكر الآن',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(4));

    await tester.tap(find.text('مشاري العفاسي'));
    await tester.pumpAndSettle();
    expect(prefs.getString('notif_adhan_sound'), 'afasy');
  });
}
