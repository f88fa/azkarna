import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Writes the widget data where the iOS widget extension can read it.
abstract interface class WidgetBridge {
  /// False where there are no widgets to feed (web, Android, tests).
  bool get isSupported;

  /// Saves [json] and asks the system to refresh the widgets.
  Future<void> save(String json);
}

class NoopWidgetBridge implements WidgetBridge {
  const NoopWidgetBridge();

  @override
  bool get isSupported => false;

  @override
  Future<void> save(String json) async {}
}

/// Talks to `WidgetBridge` in `ios/Runner/AppDelegate.swift`.
class IosWidgetBridge implements WidgetBridge {
  const IosWidgetBridge();

  static const MethodChannel _channel = MethodChannel('awwab/widgets');

  @override
  bool get isSupported => true;

  @override
  Future<void> save(String json) async {
    try {
      await _channel.invokeMethod<bool>('save', json);
    } on MissingPluginException {
      // Older build without the native side: nothing to update.
    } on PlatformException catch (e) {
      debugPrint('Widget data was not saved: ${e.message}');
    }
  }
}

WidgetBridge createWidgetBridge() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return const IosWidgetBridge();
  }
  return const NoopWidgetBridge();
}
