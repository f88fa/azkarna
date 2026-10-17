import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Replaces Flutter's red error screen in release builds so a failing widget
/// never shows a stack trace to the user.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget(this.details, {super.key});

  final FlutterErrorDetails details;

  static Widget builder(FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget.withDetails(
        message: details.exceptionAsString(),
        error: details.exception is FlutterError
            ? details.exception as FlutterError
            : null,
      );
    }
    return AppErrorWidget(details);
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Icon(Icons.error_outline_rounded, color: Colors.grey),
        ),
      ),
    );
  }
}
