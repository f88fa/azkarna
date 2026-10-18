import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../widgets/dhikr_reminders_section.dart';

/// Periodic dhikr reminders: on/off, frequency, quiet hours and a test.
class DhikrSettingsScreen extends ConsumerWidget {
  const DhikrSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return PopupScaffold(
      title: 'تذكيرات الذكر الدورية',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(top: 4, bottom: floatingNavBarInset(context)),
        child: settings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(notificationSettingsProvider),
          ),
          data: (data) => DhikrRemindersSection(settings: data.dhikr),
        ),
      ),
    );
  }
}
