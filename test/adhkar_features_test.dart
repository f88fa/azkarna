import 'dart:convert';
import 'dart:io';

import 'package:azkarna/features/adhkar/data/models/adhkar_model.dart';
import 'package:azkarna/core/storage/shared_preferences_provider.dart';
import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/adhkar/presentation/providers/adhkar_providers.dart';
import 'package:azkarna/features/adhkar/presentation/screens/adhkar_category_screen.dart';
import 'package:azkarna/features/notifications/data/datasources/notification_settings_local_data_source.dart';
import 'package:azkarna/features/notifications/data/repositories/notification_settings_repository_impl.dart';
import 'package:azkarna/features/notifications/data/services/noop_notification_scheduler.dart';
import 'package:azkarna/features/notifications/domain/entities/notification_settings.dart';
import 'package:azkarna/features/notifications/domain/usecases/sync_notifications.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:azkarna/features/prayer_times/domain/entities/prayer_times.dart';
import 'package:azkarna/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:azkarna/features/notifications/domain/entities/adhan_sound.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScheduler extends NoopNotificationScheduler {
  List<PrayerTimes>? adhkarDays;
  bool? morning;
  bool? evening;
  int adhkarCancels = 0;
  int adhanSchedules = 0;

  @override
  Future<void> scheduleAdhkarReminders(
    List<PrayerTimes> days, {
    required bool morning,
    required bool evening,
  }) async {
    adhkarDays = days;
    this.morning = morning;
    this.evening = evening;
  }

  @override
  Future<void> cancelAdhkarReminders() async => adhkarCancels++;

  @override
  Future<void> scheduleAdhan(
    List<PrayerTimes> days, {
    required AdhanSound sound,
  }) async => adhanSchedules++;
}

class _FakePrayerRepo implements PrayerTimesRepository {
  @override
  Future<PrayerTimes> getTodayPrayerTimes(PrayerLocation location) async =>
      (await getUpcomingPrayerTimes(location, days: 1)).first;

  @override
  Future<List<PrayerTimes>> getUpcomingPrayerTimes(
    PrayerLocation location, {
    int days = 7,
  }) async => [
    PrayerTimes(
      location: 'حائل',
      timeZone: 'Asia/Riyadh',
      utcOffset: const Duration(hours: 3),
      date: DateTime(2030, 1, 1),
      hijriDate: '',
      times: {
        Prayer.fajr: DateTime(2030, 1, 1, 5),
        Prayer.asr: DateTime(2030, 1, 1, 15),
      },
    ),
  ];
}

void main() {
  test('adhkar reminder delays are 30 min after Fajr and 20 after Asr', () {
    expect(AdhkarReminderDelays.morningAfterFajr, const Duration(minutes: 30));
    expect(AdhkarReminderDelays.eveningAfterAsr, const Duration(minutes: 20));
  });

  test('sync schedules adhkar reminders independently of the Adhan', () async {
    SharedPreferences.setMockInitialValues({'notif_adhan_enabled': false});
    final prefs = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler();
    final sync = SyncNotifications(
      NotificationSettingsRepositoryImpl(
        SharedPrefsNotificationSettingsDataSource(prefs),
      ),
      _FakePrayerRepo(),
      scheduler,
    );

    await sync(PrayerLocation.hail);

    expect(scheduler.adhanSchedules, 0);
    expect(scheduler.adhkarDays, hasLength(1));
    expect(scheduler.morning, isTrue);
    expect(scheduler.evening, isTrue);
  });

  test('sync cancels adhkar reminders when both are off', () async {
    SharedPreferences.setMockInitialValues({
      'notif_adhkar_morning_enabled': false,
      'notif_adhkar_evening_enabled': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler();
    await SyncNotifications(
      NotificationSettingsRepositoryImpl(
        SharedPrefsNotificationSettingsDataSource(prefs),
      ),
      _FakePrayerRepo(),
      scheduler,
    )(PrayerLocation.hail);

    expect(scheduler.adhkarCancels, 1);
    expect(scheduler.adhkarDays, isNull);
    expect(scheduler.adhanSchedules, 1);
  });

  test('custom adhkar are persisted, edited and removed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(customAdhkarProvider.notifier);
    await notifier.add('  لا إله إلا الله  ', 5);
    var items = container.read(customAdhkarProvider);
    expect(items.single.text, 'لا إله إلا الله');
    expect(items.single.count, 5);

    await notifier.edit(items.single.id, 'سبحان الله', 33);

    // A new container (app restart) sees the saved data.
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    items = restarted.read(customAdhkarProvider);
    expect(items.single.text, 'سبحان الله');
    expect(items.single.count, 33);

    await notifier.remove(items.single.id);
    expect(container.read(customAdhkarProvider), isEmpty);
  });

  testWidgets('custom category: add a dhikr from the sheet', (tester) async {
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
          home: const AdhkarCategoryScreen(categoryId: customAdhkarCategoryId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أذكار بعد'), findsOneWidget);

    await tester.tap(find.text('إضافة ذكر'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'اللهم صل على محمد');
    await tester.tap(find.byTooltip('زيادة'));
    await tester.pump();
    await tester.tap(find.text('إضافة الذكر'));
    await tester.pumpAndSettle();

    expect(find.text('اللهم صل على محمد'), findsOneWidget);
    expect(find.text('٠/٢'), findsOneWidget);
  });

  test('built-in adhkar include the well-known categories', () {
    final json = jsonDecode(File('assets/json/adhkar.json').readAsStringSync());
    final categories = [
      for (final c in (json as Map<String, dynamic>)['categories'] as List)
        AdhkarCategoryModel.fromJson(c),
    ];
    final ids = categories.map((c) => c.id).toList();
    expect(ids, containsAll(['morning', 'evening', 'after_prayer', 'sleep']));
    expect(categories.every((c) => c.adhkar.isNotEmpty), isTrue);
    final all = categories.expand((c) => c.adhkar).map((d) => d.id).toList();
    expect(all.toSet().length, all.length, reason: 'dhikr ids must be unique');
  });
}
