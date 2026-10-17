import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/layout.dart';
import '../providers/task_providers.dart';
import '../widgets/task_tile.dart';
import '../../../../core/widgets/error_view.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(tasksProvider.notifier).add(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar.large(
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'Tasks',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _AddTaskField(
                  controller: _controller,
                  onSubmit: _submit,
                ),
              ),
            ),
            tasks.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(tasksProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: floatingNavBarInset(context),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 56,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    floatingNavBarInset(context),
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = items[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () =>
                            ref.read(tasksProvider.notifier).toggle(task),
                        onDelete: () =>
                            ref.read(tasksProvider.notifier).remove(task.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskField extends StatelessWidget {
  const _AddTaskField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.only(start: 18, end: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a new task',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onSubmit,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
