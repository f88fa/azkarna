import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/add_task_sheet.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';
import 'home_section_header.dart';

/// Today's tasks, checkable right on the home screen.
class HomeTasksSection extends ConsumerWidget {
  const HomeTasksSection({super.key});

  static const int _maxShown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider);
    final today = dateOnly(DateTime.now());
    final items = tasks.asData?.value ?? const <Task>[];
    final done = items.where((t) => t.isDoneOn(today)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'مهام اليوم',
          subtitle: items.isEmpty
              ? null
              : '${arNum(done)} من ${arNum(items.length)}',
          actionLabel: 'عرض الكل',
          onAction: () => context.push(AppRoutes.tasks),
        ),
        if (tasks.isLoading && items.isEmpty)
          const SizedBox(height: 90)
        else if (items.isEmpty)
          _Empty(onAdd: () => showAddTaskSheet(context))
        else ...[
          for (final task in items.take(_maxShown)) ...[
            TaskTile(
              task: task,
              day: today,
              onToggle: () =>
                  ref.read(tasksProvider.notifier).toggle(task, today),
              onDelete: () => ref.read(tasksProvider.notifier).remove(task.id),
            ),
            const SizedBox(height: 8),
          ],
          if (items.length > _maxShown)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.tasks),
                child: Text('و${arNum(items.length - _maxShown)} مهام أخرى'),
              ),
            ),
          _AddButton(onTap: () => showAddTaskSheet(context)),
        ],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size.fromHeight(46),
        backgroundColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'إضافة مهمة',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 38,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد مهام لليوم',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _AddButton(onTap: onAdd),
        ],
      ),
    );
  }
}
