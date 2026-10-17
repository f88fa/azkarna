import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import 'calendar_utils.dart';
import 'week_calendar_strip.dart';

/// Calendar header + a full month grid, collapsible into a one-week strip.
class TaskCalendar extends ConsumerStatefulWidget {
  const TaskCalendar({super.key, required this.tasks});

  final List<Task> tasks;

  @override
  ConsumerState<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends ConsumerState<TaskCalendar> {
  static const int _initialPage = 1000;
  static const double _rowHeight = 46;

  final DateTime _thisMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  late final PageController _controller;
  late DateTime _visibleMonth;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedTaskDateProvider);
    _visibleMonth = DateTime(selected.year, selected.month);
    _controller = PageController(initialPage: _pageFor(selected));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _pageFor(DateTime day) =>
      _initialPage +
      (day.year - _thisMonth.year) * 12 +
      (day.month - _thisMonth.month);

  DateTime _monthForPage(int page) =>
      DateTime(_thisMonth.year, _thisMonth.month + (page - _initialPage));

  void _goToMonth(int delta) {
    final page = (_controller.page ?? _pageFor(_visibleMonth).toDouble())
        .round();
    _controller.animateToPage(
      page + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedTaskDateProvider);
    final today = dateOnly(DateTime.now());

    ref.listen(selectedTaskDateProvider, (_, next) {
      final page = _pageFor(next);
      if (_expanded &&
          _controller.hasClients &&
          _controller.page?.round() != page) {
        _controller.animateToPage(
          page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final label = arDate('MMMM yyyy', _expanded ? _visibleMonth : selected);
    final showToday = !isSameDay(selected, today);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (_expanded)
                IconButton(
                  tooltip: 'الشهر السابق',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _goToMonth(-1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _expanded ? 0 : 8),
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_expanded)
                IconButton(
                  tooltip: 'الشهر التالي',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _goToMonth(1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              const Spacer(),
              if (showToday)
                TextButton(
                  onPressed: () =>
                      ref.read(selectedTaskDateProvider.notifier).select(today),
                  child: const Text('اليوم'),
                ),
              IconButton(
                tooltip: _expanded ? 'عرض الأسبوع فقط' : 'عرض التقويم كاملًا',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                  if (_expanded) {
                    final s = ref.read(selectedTaskDateProvider);
                    _visibleMonth = DateTime(s.year, s.month);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_controller.hasClients) {
                        _controller.jumpToPage(_pageFor(s));
                      }
                    });
                  }
                },
                icon: Icon(
                  _expanded
                      ? Icons.calendar_view_week_rounded
                      : Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  children: [
                    const _WeekdayHeader(),
                    SizedBox(
                      height: _rowHeight * 6,
                      child: PageView.builder(
                        controller: _controller,
                        onPageChanged: (page) =>
                            setState(() => _visibleMonth = _monthForPage(page)),
                        itemBuilder: (context, page) => _MonthGrid(
                          month: _monthForPage(page),
                          rowHeight: _rowHeight,
                          selected: selected,
                          today: today,
                          tasks: widget.tasks,
                          onSelect: (d) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(selectedTaskDateProvider.notifier)
                                .select(d);
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : WeekCalendarStrip(tasks: widget.tasks),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final weekday in weekOrder)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    weekdayNamesAr[weekday]!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.rowHeight,
    required this.selected,
    required this.today,
    required this.tasks,
    required this.onSelect,
  });

  final DateTime month;
  final double rowHeight;
  final DateTime selected;
  final DateTime today;
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Saturday-first week: Saturday -> 0 ... Friday -> 6.
    final offset = (DateTime(month.year, month.month, 1).weekday + 1) % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var row = 0; row < 6; row++)
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final dayNumber = row * 7 + col - offset + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          final day = DateTime(
                            month.year,
                            month.month,
                            dayNumber,
                          );
                          final isSelected = isSameDay(day, selected);
                          final isToday = isSameDay(day, today);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(day),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isToday && !isSelected
                                          ? primary
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    arNum(dayNumber),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                          ? primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: dayHasPending(tasks, day) ? 1 : 0,
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
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
