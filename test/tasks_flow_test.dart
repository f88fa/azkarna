import 'package:azkarna/core/theme/app_theme.dart';
import 'package:azkarna/features/tasks/domain/entities/task.dart';
import 'package:azkarna/features/tasks/domain/repositories/task_repository.dart';
import 'package:azkarna/features/tasks/presentation/providers/task_providers.dart';
import 'package:azkarna/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _MemoryRepo implements TaskRepository {
  final Map<String, Task> _items = {};

  @override
  Future<List<Task>> getTasks() async => _items.values.toList();

  @override
  Future<void> saveTask(Task task) async => _items[task.id] = task;

  @override
  Future<void> deleteTask(String id) async => _items.remove(id);
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('FAB opens the sheet, adds a task and checking it works', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWith((ref) async => _MemoryRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مهام في هذا اليوم'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('مهمة جديدة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'قراءة وردي');
    await tester.tap(find.text('إضافة المهمة'));
    await tester.pumpAndSettle();

    expect(find.text('مهمة جديدة'), findsNothing);
    expect(find.text('قراءة وردي'), findsOneWidget);

    await tester.tap(find.text('قراءة وردي'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أُنجز'), findsOneWidget);
  });
}
