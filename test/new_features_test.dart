import 'dart:io';

import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/notifications/domain/entities/adhan_sound.dart';
import 'package:azkarna/features/notifications/domain/entities/dhikr_reminder.dart';
import 'package:azkarna/features/quran/presentation/screens/kahf_reader_screen.dart';
import 'package:azkarna/core/constants/app_constants.dart';
import 'package:azkarna/core/theme/theme_mode_provider.dart';
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

    test('the library has the 20 requested voices in 4 categories', () {
      expect(AdhanSound.values, hasLength(20));
      expect(AdhanSound.values.map((s) => s.id).toSet(), hasLength(20));
      expect(AdhanSound.values.map((s) => s.file).toSet(), hasLength(20));
      expect(AdhanSound.inCategory(AdhanCategory.haramain), hasLength(6));
      expect(AdhanSound.inCategory(AdhanCategory.reciters), hasLength(10));
      expect(AdhanSound.inCategory(AdhanCategory.countries), hasLength(2));
      expect(AdhanSound.inCategory(AdhanCategory.calm), hasLength(2));
      expect(AdhanSound.makkahMulla.label, 'أذان الحرم المكي (علي أحمد ملا)');
      expect(AdhanSound.aqsa.label, 'أذان المسجد الأقصى');
      expect(AdhanSound.takbeer.label, 'تكبيرات الأذان فقط (مختصر)');
      expect(AdhanSound.calm.label, 'نغمة تنبيه إسلامية هادئة');
    });

    test('search and legacy ids', () {
      expect(AdhanSound.values.where((s) => s.matches('العفاسي')), [
        AdhanSound.afasy,
      ]);
      expect(
        AdhanSound.values.where((s) => s.matches('الحرم المدني')),
        hasLength(2),
      );
      expect(AdhanSound.values.where((s) => s.matches('  ')), hasLength(20));
      expect(AdhanSound.fromId('makkah'), AdhanSound.makkahMulla);
      expect(AdhanSound.fromId('madinah'), AdhanSound.madinahBukhari);
      expect(AdhanSound.fromId('nope'), AdhanSound.defaultSound);
    });

    test('the sound generator covers exactly the app sounds', () {
      final script = File('tool/gen_sounds.py').readAsStringSync();
      final inScript = RegExp(
        r"^\s+'(adhan_\w+)':",
        multiLine: true,
      ).allMatches(script).map((m) => m.group(1)!).toSet();
      expect(inScript, AdhanSound.values.map((s) => s.file).toSet());
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
        'أذان الحرم المكي (علي أحمد ملا)',
        'تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)',
        'تذكيرات الذكر الدورية',
        'متوقف',
        'عن التطبيق',
        'أواب - صلاتي أذكاري ومهامي اليومية',
        'الإصدار 1.0.0 +6',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      // The long lists are NOT dumped on the main page any more.
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('كل ١٥ دقيقة'), findsNothing);
      expect(find.text('أذان المسجد الأقصى'), findsNothing);
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

    testWidgets('muezzin library: 20 voices, categories, search, check mark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2400, 12000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final prefs = await _prefs();
      await tester.pumpWidget(_app(prefs, const MuadhinPickerScreen()));
      await tester.pumpAndSettle();

      for (final c in AdhanCategory.values) {
        expect(find.text(c.label), findsOneWidget, reason: c.label);
      }
      for (final s in AdhanSound.values) {
        expect(find.text(s.label), findsOneWidget, reason: s.label);
      }
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(20));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Choose another muezzin: the check mark follows and it is saved.
      await tester.tap(find.text('مشاري راشد العفاسي'));
      await tester.pumpAndSettle();
      expect(prefs.getString('notif_adhan_sound'), 'afasy');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Search narrows the list.
      await tester.enterText(find.byType(EditableText), 'الأقصى');
      await tester.pumpAndSettle();
      expect(find.text('أذان المسجد الأقصى'), findsOneWidget);
      expect(find.text('مشاري راشد العفاسي'), findsNothing);
      expect(find.text('أذان الحرم المكي (علي أحمد ملا)'), findsNothing);

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
