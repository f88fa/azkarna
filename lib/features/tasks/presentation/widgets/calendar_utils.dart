import '../../domain/entities/task.dart';

const weekdayNamesAr = {
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
  DateTime.monday: 'الاثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
};

/// Weekdays in display order (the week starts on Saturday).
const weekOrder = [
  DateTime.saturday,
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
];

/// First day (Saturday) of the week containing [day].
DateTime startOfWeek(DateTime day) {
  final d = dateOnly(day);
  return DateTime(d.year, d.month, d.day - ((d.weekday + 1) % 7));
}

/// Whether [day] has at least one unfinished task occurrence.
bool dayHasPending(List<Task> tasks, DateTime day) =>
    tasks.any((t) => t.occursOn(day) && !t.isDoneOn(day));
