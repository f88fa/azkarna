import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_calendar.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasks = ref.watch(selectedDayTasksProvider);
    final selected = ref.watch(selectedTaskDateProvider);

    return PopupScaffold(
      title: 'المهام',
      backdrop: false,
      background: isDark
          ? theme.scaffoldBackgroundColor
          : AppColors.tasksLightBackground,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_task_fab',
        tooltip: 'إضافة مهمة',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => showAddTaskSheet(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      child: Column(
        children: [
          TaskCalendar(
            tasks: ref.watch(tasksProvider).asData?.value ?? const [],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(tasksProvider),
              ),
              data: (items) => _TaskList(items: items, day: selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.items, required this.day});

  final List<Task> items;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: floatingNavBarInset(context)),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 60,
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 12),
                Text(
                  'لا توجد مهام في هذا اليوم',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط + لإضافة مهمة جديدة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final done = items.where((t) => t.isDoneOn(day)).length;

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, floatingNavBarInset(context)),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${arDate('EEEE d MMMM', day)} · '
              'أُنجز ${arNum(done)} من ${arNum(items.length)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          );
        }
        final task = items[index - 1];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          day: day,
          onToggle: () => ref.read(tasksProvider.notifier).toggle(task, day),
          onDelete: () => ref.read(tasksProvider.notifier).remove(task.id),
        );
      },
    );
  }
}
