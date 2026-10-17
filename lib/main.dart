import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'core/widgets/app_error_widget.dart';
import 'features/notifications/data/services/local_notification_scheduler.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final scheduler = LocalNotificationScheduler();
  await scheduler.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const AzkarnaApp(),
    ),
  );
}

void _installGlobalErrorHandlers() {
  ErrorWidget.builder = AppErrorWidget.builder;

  // Framework errors: log, never crash the app.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Hook for a crash reporter (e.g. Crashlytics/Sentry) goes here.
  };

  // Uncaught async/platform errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
}
