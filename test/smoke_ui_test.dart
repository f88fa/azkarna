import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/moon/presentation/widgets/moon_phase_card.dart';
import 'package:azkarna/features/prayer_times/presentation/widgets/prayer_times_card.dart';
import 'package:azkarna/features/settings/presentation/screens/settings_screen.dart';
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

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('settings: offsets stepper changes a prayer time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_app(prefs, const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('تعديل المواقيت يدويًا'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('العصر'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final plus = find.bySemanticsLabel('زيادة دقيقة');
    expect(plus, findsWidgets);
    await tester.ensureVisible(plus.at(3)); // Asr
    await tester.pumpAndSettle();
    await tester.tap(plus.at(3));
    await tester.pumpAndSettle();

    expect(find.text('+١ د'), findsOneWidget);
    expect(prefs.getInt('prayer_offset_asr'), 1);
  });

  testWidgets('prayer + moon cards render', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      _app(
        prefs,
        const Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [PrayerTimesCard(), MoonPhasePill()]),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('العصر'), findsWidgets);
    expect(find.text('أم القرى'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
