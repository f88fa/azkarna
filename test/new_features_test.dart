import 'dart:io';

import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/home/presentation/widgets/home_feature_cards.dart';
import 'package:azkarna/features/notifications/domain/entities/adhan_sound.dart';
import 'package:azkarna/features/notifications/domain/entities/dhikr_reminder.dart';
import 'package:azkarna/features/notifications/domain/entities/notification_settings.dart';
import 'package:azkarna/features/notifications/presentation/providers/notification_providers.dart';
import 'package:azkarna/features/quran/presentation/screens/kahf_reader_screen.dart';
import 'package:azkarna/core/constants/app_constants.dart';
import 'package:azkarna/core/theme/theme_mode_provider.dart';
import 'package:azkarna/features/settings/presentation/screens/adhkar_reminders_screen.dart';
import 'package:azkarna/features/settings/presentation/screens/dhikr_settings_screen.dart';
import 'package:azkarna/features/settings/presentation/screens/muadhin_picker_screen.dart';
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

    test('the library is the 14 supplied muezzin recordings', () {
      expect(AdhanSound.values, hasLength(14));
      expect(AdhanSound.values.map((s) => s.id).toSet(), hasLength(14));
      expect(AdhanSound.defaultSound, AdhanSound.aliMulla);
      expect(AdhanSound.aliMulla.label, 'أذان علي بن أحمد ملا');
      expect(AdhanSound.dosari.label, 'أذان ياسر الدوسري');
    });

    test(
      'every recording is listed in CREDITS and is real, not a short tone',
      () {
        final credits = File('assets/audio/CREDITS.md').readAsStringSync();
        for (final s in AdhanSound.values) {
          expect(credits, contains(s.file), reason: s.file);
          // Voice recordings are 15 s – 28 s of audio.
          final kb = File('assets/audio/${s.file}.wav').lengthSync() / 1000;
          expect(kb, greaterThan(250), reason: s.file);
        }
      },
    );

    test('every sound is under 29 s and registered in the Xcode project', () {
      final pbx = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      for (final s in AdhanSound.values) {
        // 16 kHz mono 16-bit WAV: 32 000 bytes per second (+44-byte header).
        final bytes = File('assets/audio/${s.file}.wav').lengthSync();
        expect((bytes - 44) / 32000, lessThan(29), reason: s.file);
        for (final d in AdhanDuration.values) {
          expect(File('ios/Runner/${s.iosFileFor(d)}').existsSync(), isTrue);
          expect(
            File(
              'android/app/src/main/res/raw/${s.fileFor(d)}.wav',
            ).existsSync(),
            isTrue,
          );
          expect(
            RegExp(
              '${RegExp.escape(s.iosFileFor(d))} in Resources',
            ).hasMatch(pbx),
            isTrue,
            reason: s.iosFileFor(d),
          );
        }
        // The short version really is short (about 7 - 11 s).
        final shortBytes = File(
          'android/app/src/main/res/raw/${s.fileFor(AdhanDuration.short)}.wav',
        ).lengthSync();
        expect(
          (shortBytes - 44) / 32000,
          inInclusiveRange(6, 12),
          reason: s.id,
        );
      }
    });

    test('adhan duration is saved and defaults to the full version', () async {
      expect(const NotificationSettings().adhanDuration, AdhanDuration.full);
      expect(AdhanDuration.fromName('nope'), AdhanDuration.full);
      expect(
        AdhanSound.dosari.fileFor(AdhanDuration.short),
        'adhan_dosari_short',
      );
      expect(
        AdhanSound.dosari.iosFileFor(AdhanDuration.full),
        'adhan_dosari.caf',
      );
      final prefs = await _prefs();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      await c.read(notificationSettingsProvider.future);
      await c
          .read(notificationSettingsProvider.notifier)
          .setAdhanDuration(AdhanDuration.short);
      expect(prefs.getString('notif_adhan_duration'), 'short');
    });

    test('search and unknown ids', () {
      expect(AdhanSound.values.where((s) => s.matches('الدوسري')), [
        AdhanSound.dosari,
      ]);
      expect(AdhanSound.values.where((s) => s.matches('ملا')), [
        AdhanSound.aliMulla,
        AdhanSound.aliMulla2,
      ]);
      expect(AdhanSound.values.where((s) => s.matches('  ')), hasLength(14));
      // Ids saved by earlier builds fall back to the default.
      expect(AdhanSound.fromId('nabawi'), AdhanSound.defaultSound);
      expect(AdhanSound.fromId(null), AdhanSound.defaultSound);
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

    test('eight voiced adhkar rotate, each with its bundled sound files', () {
      expect(DhikrMessages.all, hasLength(8));
      final bodies = {for (var i = 0; i < 8; i++) DhikrMessages.at(i).body};
      expect(bodies, hasLength(8));
      expect(DhikrMessages.at(0).body, DhikrMessages.at(8).body);
      final pbx = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      for (final m in DhikrMessages.all) {
        expect(
          File('ios/Runner/${m.iosFile}').existsSync(),
          isTrue,
          reason: m.sound,
        );
        expect(
          File('android/app/src/main/res/raw/${m.sound}.wav').existsSync(),
          isTrue,
          reason: m.sound,
        );
        expect(pbx, contains('${m.iosFile} in Resources'), reason: m.sound);
      }
    });

    test('sound can be switched off and the choice is saved', () async {
      expect(const DhikrReminderSettings().soundEnabled, isTrue);
      final prefs = await _prefs();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      await c.read(notificationSettingsProvider.future);
      await c.read(notificationSettingsProvider.notifier).setDhikrSound(false);
      expect(prefs.getBool('notif_dhikr_sound'), isFalse);
      final again = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(again.dispose);
      expect(
        (await again.read(
          notificationSettingsProvider.future,
        )).dhikr.soundEnabled,
        isFalse,
      );
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

        for (var i = 0; i < 33; i++) {
          await notifier.tap();
        }
        var s = container.read(tasbeehProvider);
        expect((s.count, s.today, s.total), (33, 33, 33));
        expect(s.justCompleted, isTrue);
        expect(s.progress, 1);
        expect(s.rounds, 1);

        await notifier.reset();
        s = container.read(tasbeehProvider);
        expect((s.count, s.today, s.total), (0, 33, 33));

        // Reset never touches the daily / overall totals.
        await notifier.tap();
        await notifier.reset();
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

      // No dhikr picker any more: just the dial, targets and the buttons.
      expect(find.text('أستغفر الله'), findsNothing);
      expect(find.byType(ChoiceChip), findsNWidgets(tasbeehTargets.length));

      await tester.tap(find.bySemanticsLabel(RegExp('اضغط للتسبيح')));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp('اضغط للتسبيح')));
      await tester.pumpAndSettle();
      expect(prefs.getInt('tasbeeh_count'), 2);
      expect(prefs.getInt('tasbeeh_total'), 2);

      await tester.tap(find.byTooltip('تصفير العدّاد'));
      await tester.pumpAndSettle();
      expect(prefs.getInt('tasbeeh_count'), 0);
      expect(prefs.getInt('tasbeeh_total'), 2);

      // Vibration can be switched off and the choice is saved.
      await tester.tap(find.byTooltip('إيقاف الاهتزاز'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('tasbeeh_haptics'), isFalse);
      expect(find.byTooltip('تشغيل الاهتزاز'), findsOneWidget);
    });
  });

  testWidgets('home cards show the tasbeeh count and the Kahf reading line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final prefs = await _prefs({
      'tasbeeh_count': 25,
      'tasbeeh_target': 33,
      'kahf_progress': 0.5,
    });
    await tester.pumpWidget(
      _app(prefs, const Scaffold(body: HomeFeatureCards())),
    );
    await tester.pumpAndSettle();

    expect(find.text('وصلت إلى ٢٥ من ٣٣'), findsOneWidget);
    expect(find.textContaining('٥٠٪'), findsOneWidget);
    final lines = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((l) => l.value)
        .toList();
    expect(lines, hasLength(2));
    expect(lines[0], closeTo(25 / 33, 0.001)); // tasbeeh (first card)
    expect(lines[1], 0.5); // Al-Kahf
  });

  testWidgets('Kahf reminder settings: switch and 1h / 2h before Maghrib', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final prefs = await _prefs();
    await tester.pumpWidget(_app(prefs, const AdhkarRemindersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('سورة الكهف يوم الجمعة'), findsOneWidget);
    expect(find.text('تذكير سورة الكهف'), findsOneWidget);
    expect(find.text('قبل المغرب بساعة'), findsWidgets);

    // Default: on, one hour. Pick two hours.
    await tester.tap(find.text('قبل المغرب بساعتين'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('notif_kahf_lead_min'), 120);
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

  test('version shown in About matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(
        'version: ${AppConstants.appVersion}+${AppConstants.buildNumber}',
      ),
    );
  });

  group('settings', () {
    testWidgets('home shows the grouped sections and the build number', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 6400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(_app(prefs, const SettingsScreen()));
      await tester.pumpAndSettle();

      for (final text in [
        'المظهر والعرض',
        'نهاري',
        'ليلي',
        'تلقائي',
        'الموقع وطريقة الحساب',
        'إعدادات الأذان والمؤذنين',
        'إشعارات الصلوات الخمس',
        'صوت المؤذن',
        'أذان علي بن أحمد ملا',
        'مدة الأذان في الإشعار',
        'تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)',
        'تذكيرات الذكر الدورية',
        'متوقف',
        'عن التطبيق',
        'أواب - صلاتي أذكاري ومهامي اليومية',
        'الإصدار 1.0.0 +10',
        'التطبيق صدقة جارية للشيخ فريح التميمي رحمه الله',
        'برمجة وتطوير فارس التريباني',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      // The long lists are NOT dumped on the main page any more.
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('كل ١٥ دقيقة'), findsNothing);
      expect(find.text('أذان ياسر الدوسري'), findsNothing);
    });

    testWidgets('theme switch changes the whole app and is saved', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 6400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ref.watch(themeModeProvider),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
              home: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Brightness current() =>
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

      // The test device is light, so "auto" resolves to light.
      expect(current(), Brightness.light);

      await tester.tap(find.text('ليلي'));
      await tester.pumpAndSettle();
      expect(current(), Brightness.dark);
      expect(prefs.getString('theme_mode'), 'dark');

      await tester.tap(find.text('نهاري'));
      await tester.pumpAndSettle();
      expect(current(), Brightness.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('saved theme mode is restored', () async {
      final prefs = await _prefs({'theme_mode': 'dark'});
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('muezzin library: list, search, preview, check mark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 8000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(_app(prefs, const MuadhinPickerScreen()));
      await tester.pumpAndSettle();

      for (final s in AdhanSound.values) {
        expect(find.text(s.label), findsOneWidget, reason: s.label);
      }
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(14));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Choose another muezzin: the check mark follows and it is saved.
      await tester.tap(find.text('أذان حمد الدغريري'));
      await tester.pumpAndSettle();
      expect(prefs.getString('notif_adhan_sound'), 'dagriri');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Search narrows the list.
      await tester.enterText(find.byType(EditableText), 'القطامي');
      await tester.pumpAndSettle();
      expect(find.text('أذان ناصر القطامي'), findsOneWidget);
      expect(find.text('أذان حمد الدغريري'), findsNothing);
      expect(find.text('أذان علي بن أحمد ملا'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
    });

    testWidgets('dhikr sheet has frequency, quiet hours and the test button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 6400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(_app(prefs, const DhikrSettingsScreen()));
      await tester.pumpAndSettle();

      for (final text in [
        'تفعيل التذكير',
        'صوت الأذكار',
        'كل ١٥ دقيقة',
        'كل نصف ساعة',
        'كل ساعة',
        'كل ٣ ساعات',
        'وقت الهدوء أثناء النوم',
        'تجربة إشعار ذكر الآن',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
    });
  });
}
