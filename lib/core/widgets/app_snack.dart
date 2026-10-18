import 'package:flutter/material.dart';

/// Floating one-line message (works inside the pop-up sheets, which own a
/// Scaffold for this purpose).
void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(message),
      ),
    );
}
