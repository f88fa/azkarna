import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';

const _weekdayNames = {
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
  DateTime.monday: 'الاثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
};

/// First day (Saturday) of the week containing [day].
DateTime startOfWeek(DateTime day) {
  final d = dateOnly(day);
  return DateTime(d.year, d.month, d.day - ((d.weekday + 1) % 7));
}

/// Swipeable weekly calendar strip used to switch the task day.
class WeekCalendarStrip extends ConsumerStatefulWidget {
  const WeekCalendarStrip({super.key});

  @override
  ConsumerState<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends ConsumerState<WeekCalendarStrip> {
  static const int _initialPage = 1000;

  final DateTime _todayWeek = startOfWeek(DateTime.now());
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedTaskDateProvider);
    _controller = PageController(initialPage: _pageFor(selected));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _pageFor(DateTime day) {
    final week = startOfWeek(day);
    // UTC dates avoid DST skew when counting whole days.
    final days = DateTime.utc(week.year, week.month, week.day)
        .difference(
          DateTime.utc(_todayWeek.year, _todayWeek.month, _todayWeek.day),
        )
        .inDays;
    return _initialPage + days ~/ 7;
  }

  DateTime _weekForPage(int page) => DateTime(
    _todayWeek.year,
    _todayWeek.month,
    _todayWeek.day + (page - _initialPage) * 7,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedTaskDateProvider);
    final pending = ref.watch(pendingTaskDaysProvider);
    final today = dateOnly(DateTime.now());

    // Keep the strip in sync when the day is changed from elsewhere.
    ref.listen(selectedTaskDateProvider, (_, next) {
      final page = _pageFor(next);
      if (_controller.hasClients && _controller.page?.round() != page) {
        _controller.animateToPage(
          page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                arDate('MMMM yyyy', selected),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: isSameDay(selected, today) ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: isSameDay(selected, today)
                      ? null
                      : () => ref
                            .read(selectedTaskDateProvider.notifier)
                            .select(today),
                  child: const Text('اليوم'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: PageView.builder(
            controller: _controller,
            itemBuilder: (context, page) {
              final start = _weekForPage(page);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _DayCell(
                          day: DateTime(start.year, start.month, start.day + i),
                          selected: selected,
                          today: today,
                          hasPending: pending.contains(
                            DateTime(start.year, start.month, start.day + i),
                          ),
                          onTap: (d) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(selectedTaskDateProvider.notifier)
                                .select(d);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.hasPending,
    required this.onTap,
  });

  final DateTime day;
  final DateTime selected;
  final DateTime today;
  final bool hasPending;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSelected = isSameDay(day, selected);
    final isToday = isSameDay(day, today);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(day),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _weekdayNames[day.weekday]!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : muted,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? primary : Colors.transparent,
              border: Border.all(
                color: isToday && !isSelected ? primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              arNum(day.day),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedOpacity(
            opacity: hasPending ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
