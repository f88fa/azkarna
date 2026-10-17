import 'package:flutter/material.dart';

import '../error/failures.dart';

/// User-facing description of an error.
class ErrorInfo {
  const ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  factory ErrorInfo.from(Object error) => switch (error) {
    NetworkFailure() => const ErrorInfo(
      icon: Icons.wifi_off_rounded,
      title: 'لا يوجد اتصال بالإنترنت',
      message: 'تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.',
    ),
    ServerFailure() => const ErrorInfo(
      icon: Icons.cloud_off_rounded,
      title: 'الخدمة غير متاحة',
      message: 'تعذّر الوصول إلى الخادم. حاول مرة أخرى بعد قليل.',
    ),
    CacheFailure() => const ErrorInfo(
      icon: Icons.storage_rounded,
      title: 'البيانات غير متاحة',
      message: 'تعذّرت قراءة البيانات المخزّنة على هذا الجهاز.',
    ),
    _ => const ErrorInfo(
      icon: Icons.error_outline_rounded,
      title: 'حدث خطأ ما',
      message: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    ),
  };
}

/// Friendly error state with an optional retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = ErrorInfo.from(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                info.icon,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              info.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
