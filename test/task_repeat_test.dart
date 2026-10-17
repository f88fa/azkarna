import 'package:azkarna/features/tasks/data/models/task_model.dart';
import 'package:azkarna/features/tasks/domain/entities/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-10-17 is a Saturday (DateTime.saturday == 6).
  final start = DateTime(2026, 10, 17);
  final task = Task(
    id: '1',
    title: 'ورد',
    createdAt: start,
    dueDate: start,
    timeMinutes: 8 * 60 + 30,
    repeatDays: const {DateTime.saturday, DateTime.monday},
    remind: true,
  );

  test('repeating task occurs only on chosen weekdays, not before start', () {
    expect(task.occursOn(DateTime(2026, 10, 17)), isTrue);
    expect(task.occursOn(DateTime(2026, 10, 19)), isTrue); // Monday
    expect(task.occursOn(DateTime(2026, 10, 18)), isFalse); // Sunday
    expect(task.occursOn(DateTime(2026, 10, 12)), isFalse); // before start
  });

  test('completion is tracked per day', () {
    final done = task.toggledOn(DateTime(2026, 10, 17));
    expect(done.isDoneOn(DateTime(2026, 10, 17)), isTrue);
    expect(done.isDoneOn(DateTime(2026, 10, 24)), isFalse);
    expect(done.toggledOn(DateTime(2026, 10, 17)).isDoneOn(start), isFalse);
  });

  test('model round-trips repeat, time and reminder', () {
    final back = TaskModel.fromMap(TaskModel.fromEntity(task).toMap());
    expect(back.repeatDays, task.repeatDays);
    expect(back.timeMinutes, 510);
    expect(back.remind, isTrue);
    final json = TaskModel.fromJson(TaskModel.fromEntity(task).toJson());
    expect(json.repeatDays, task.repeatDays);
  });
}
