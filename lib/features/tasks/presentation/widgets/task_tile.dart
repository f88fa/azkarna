import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/task.dart';
import '../../../../core/utils/arabic_format.dart';
import 'animated_strike_text.dart';
import 'calendar_utils.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.day,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;

  /// The day being shown; completion of repeating tasks is per day.
  final DateTime day;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  void _toggle() {
    HapticFeedback.selectionClick();
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final done = task.isDoneOn(day);

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
            child: Row(
              children: [
                _CircleCheckbox(checked: done, color: primary, onTap: _toggle),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedStrikeText(
                        text: task.title,
                        struck: done,
                        lineColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        style: TextStyle(
                          fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: done
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                )
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (task.timeMinutes != null || task.isRepeating)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _MetaLine(task: task, dimmed: done),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleCheckbox extends StatelessWidget {
  const _CircleCheckbox({
    required this.checked,
    required this.color,
    required this.onTap,
  });

  final bool checked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? color : Colors.transparent,
              border: Border.all(
                color: checked ? color : color.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: AnimatedScale(
              scale: checked ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.task, required this.dimmed});

  final Task task;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        (dimmed ? theme.colorScheme.onSurface : theme.colorScheme.primary)
            .withValues(alpha: dimmed ? 0.35 : 0.9);
    final style = TextStyle(
      fontSize: 12.5,
      color: color,
      fontWeight: FontWeight.w600,
    );

    Widget chip(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    final minutes = task.timeMinutes;
    final repeat = task.isRepeating
        ? (task.repeatDays.length == 7
              ? 'كل يوم'
              : weekOrder
                    .where(task.repeatDays.contains)
                    .map((d) => weekdayNamesAr[d]!)
                    .join('، '))
        : null;

    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        if (minutes != null)
          chip(
            task.remind
                ? Icons.notifications_active_rounded
                : Icons.schedule_rounded,
            arTime(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60)),
          ),
        if (repeat != null) chip(Icons.repeat_rounded, repeat),
      ],
    );
  }
}
