import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';

/// The four adhkar offered by the tasbeeh counter.
const List<String> tasbeehAdhkar = [
  'أستغفر الله',
  'سبحان الله وبحمده',
  'لا حول ولا قوة إلا بالله',
  'اللهم صل على محمد',
];

/// Session targets; 0 means "no target" (open counting).
const List<int> tasbeehTargets = [33, 99, 100, 0];

class TasbeehState {
  const TasbeehState({
    this.dhikrIndex = 0,
    this.target = 33,
    this.count = 0,
    this.today = 0,
    this.total = 0,
  });

  final int dhikrIndex;
  final int target;

  /// Current round (reset by the reset button or when changing dhikr).
  final int count;

  /// Taps recorded today / ever, across every dhikr.
  final int today;
  final int total;

  String get dhikr => tasbeehAdhkar[dhikrIndex];

  /// Progress inside the current round (0 – 1); a finished round shows full.
  double get progress {
    if (target <= 0 || count == 0) return 0;
    final r = count % target;
    return r == 0 ? 1 : r / target;
  }

  /// True right after the tap that completes a round.
  bool get justCompleted => target > 0 && count > 0 && count % target == 0;

  TasbeehState copyWith({
    int? dhikrIndex,
    int? target,
    int? count,
    int? today,
    int? total,
  }) => TasbeehState(
    dhikrIndex: dhikrIndex ?? this.dhikrIndex,
    target: target ?? this.target,
    count: count ?? this.count,
    today: today ?? this.today,
    total: total ?? this.total,
  );
}

final tasbeehProvider = NotifierProvider<TasbeehNotifier, TasbeehState>(
  TasbeehNotifier.new,
);

class TasbeehNotifier extends Notifier<TasbeehState> {
  static const _kDhikr = 'tasbeeh_dhikr';
  static const _kTarget = 'tasbeeh_target';
  static const _kCount = 'tasbeeh_count';
  static const _kTotal = 'tasbeeh_total';
  static const _kToday = 'tasbeeh_today';
  static const _kDay = 'tasbeeh_day';

  /// Overridable in tests.
  DateTime Function() clock = DateTime.now;

  String _dayKey() {
    final d = clock();
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  TasbeehState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final sameDay = prefs.getString(_kDay) == _dayKey();
    final index = prefs.getInt(_kDhikr) ?? 0;
    final target = prefs.getInt(_kTarget) ?? 33;
    return TasbeehState(
      dhikrIndex: index.clamp(0, tasbeehAdhkar.length - 1),
      target: tasbeehTargets.contains(target) ? target : 33,
      count: prefs.getInt(_kCount) ?? 0,
      today: sameDay ? (prefs.getInt(_kToday) ?? 0) : 0,
      total: prefs.getInt(_kTotal) ?? 0,
    );
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setInt(_kDhikr, state.dhikrIndex),
      prefs.setInt(_kTarget, state.target),
      prefs.setInt(_kCount, state.count),
      prefs.setInt(_kTotal, state.total),
      prefs.setInt(_kToday, state.today),
      prefs.setString(_kDay, _dayKey()),
    ]);
  }

  /// One tasbeeh. The day roll-over is checked on every tap.
  Future<void> tap() {
    final prefs = ref.read(sharedPreferencesProvider);
    final newDay = prefs.getString(_kDay) != _dayKey();
    state = state.copyWith(
      count: state.count + 1,
      today: (newDay ? 0 : state.today) + 1,
      total: state.total + 1,
    );
    return _save();
  }

  /// Zeroes the current round only; the daily and overall totals are kept.
  Future<void> reset() {
    state = state.copyWith(count: 0);
    return _save();
  }

  Future<void> selectDhikr(int index) {
    if (index == state.dhikrIndex) return Future.value();
    state = state.copyWith(dhikrIndex: index, count: 0);
    return _save();
  }

  Future<void> setTarget(int target) {
    state = state.copyWith(target: target);
    return _save();
  }
}
