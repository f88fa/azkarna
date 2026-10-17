import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/arabic_format.dart';

import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/task.dart';
import 'calendar_utils.dart';
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
  TimeOfDay? _time;
  bool _repeat = false;
  Set<int> _repeatDays = {};
  bool _remind = false;
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      helpText: 'وقت المهمة',
      cancelText: 'إلغاء',
      confirmText: 'تم',
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Picking a time turns the reminder on the first time.
      if (_time == null) _remind = true;
      _time = picked;
      _error = null;
    });
  }

  void _setRepeat(bool value) => setState(() {
    _repeat = value;
    if (value && _repeatDays.isEmpty) _repeatDays = {_date.weekday};
    _error = null;
  });

  Future<void> _setRemind(bool value) async {
    if (value && _time == null) {
      await _pickTime();
      return;
    }
    setState(() => _remind = value);
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'اكتب عنوان المهمة أولًا');
      return;
    }
    if (_repeat && _repeatDays.isEmpty) {
      setState(() => _error = 'اختر يومًا واحدًا على الأقل للتكرار');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final remind = _remind && _time != null;
      if (remind) {
        // Ask for notification permission when the first reminder is created.
        try {
          await ref
              .read(notificationSchedulerProvider)
              .requestPermissions(includeExactAlarms: true);
        } catch (_) {
          // The task is still saved; the reminder just won't be shown.
        }
      }
      await ref
          .read(tasksProvider.notifier)
          .add(
            title,
            dueDate: _date,
            timeMinutes: _time == null
                ? null
                : _time!.hour * 60 + _time!.minute,
            repeatDays: _repeat ? _repeatDays : const {},
            remind: remind,
          );
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.schedule_rounded,
                title: 'الوقت',
                trailing: _time == null
                    ? const Text('بدون وقت')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            arTime(
                              DateTime(2000, 1, 1, _time!.hour, _time!.minute),
                            ),
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            tooltip: 'إزالة الوقت',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              _time = null;
                              _remind = false;
                            }),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                onTap: _pickTime,
              ),
              _OptionTile(
                icon: Icons.repeat_rounded,
                title: 'تكرار المهمة',
                subtitle: _repeat ? 'تتكرر في نفس الوقت كل أسبوع' : null,
                trailing: Switch.adaptive(
                  value: _repeat,
                  onChanged: _setRepeat,
                ),
                onTap: () => _setRepeat(!_repeat),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _repeat
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 2),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final day in weekOrder)
                              FilterChip(
                                label: Text(weekdayNamesAr[day]!),
                                visualDensity: VisualDensity.compact,
                                selected: _repeatDays.contains(day),
                                showCheckmark: false,
                                onSelected: (on) => setState(() {
                                  final next = {..._repeatDays};
                                  on ? next.add(day) : next.remove(day);
                                  _repeatDays = next;
                                  _error = null;
                                }),
                              ),
                            ActionChip(
                              label: const Text('كل يوم'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _repeatDays = {...weekOrder}),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              _OptionTile(
                icon: Icons.notifications_active_rounded,
                title: 'تنبيه عند وقت المهمة',
                subtitle: _time == null ? 'حدّد وقتًا أولًا' : null,
                trailing: Switch.adaptive(
                  value: _remind && _time != null,
                  onChanged: _setRemind,
                ),
                onTap: () => _setRemind(!(_remind && _time != null)),
              ),
              const SizedBox(height: 14),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
