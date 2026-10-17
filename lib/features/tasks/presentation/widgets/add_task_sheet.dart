import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/arabic_format.dart';

import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';

/// Opens the "new task" bottom sheet above the whole app (including the
/// floating navigation bar). Returns true when a task was added.
Future<bool?> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AddTaskSheet(),
  );
}

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _controller = TextEditingController();
  late DateTime _date = ref.read(selectedTaskDateProvider);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
      locale: const Locale('ar'),
      helpText: 'تاريخ المهمة',
      cancelText: 'إلغاء',
      confirmText: 'تم',
    );
    if (picked != null && mounted) setState(() => _date = dateOnly(picked));
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'اكتب عنوان المهمة أولًا');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(tasksProvider.notifier).add(title, dueDate: _date);
      ref.read(selectedTaskDateProvider.notifier).select(_date);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'تعذّر حفظ المهمة، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final today = dateOnly(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final isCustom = !isSameDay(_date, today) && !isSameDay(_date, tomorrow);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مهمة جديدة',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'ماذا تريد أن تنجز؟',
                  errorText: _error,
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('اليوم'),
                    selected: isSameDay(_date, today),
                    onSelected: (_) => setState(() => _date = today),
                  ),
                  ChoiceChip(
                    label: const Text('غدًا'),
                    selected: isSameDay(_date, tomorrow),
                    onSelected: (_) => setState(() => _date = tomorrow),
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.event_rounded,
                      size: 18,
                      color: isCustom ? primary : null,
                    ),
                    label: Text(
                      isCustom ? arDate('EEEE d MMMM', _date) : 'تاريخ آخر',
                    ),
                    selected: isCustom,
                    onSelected: (_) => _pickDate(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إضافة المهمة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
