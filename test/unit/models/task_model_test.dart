import 'package:flutter_test/flutter_test.dart';
import 'package:nota/core/models/task_model.dart';

void main() {
  group('TaskModel Tests', () {
    late TaskModel testTask;

    setUp(() {
      testTask = TaskModel(
        id: 'task-1',
        title: 'Complete Flutter App',
        description: 'Finish the Nota application',
        priority: 'high',
        dueDate: DateTime.now().add(Duration(days: 5)),
        createdAt: DateTime(2025, 1, 1),
        userId: 'user-123',
        isCompleted: false,
      );
    });

    test('Task should be created correctly', () {
      expect(testTask.id, 'task-1');
      expect(testTask.title, 'Complete Flutter App');
      expect(testTask.priority, 'high');
      expect(testTask.isCompleted, false);
    });

    test('Future task should not be overdue', () {
      expect(testTask.isOverdue, false);
    });

    test('Past task should be overdue', () {
      final pastDate = DateTime.now().subtract(Duration(days: 1));
      final overdueTask = testTask.copyWith(dueDate: pastDate);
      expect(overdueTask.isOverdue, true);
    });

    test('Completed task should not be overdue', () {
      final pastDate = DateTime.now().subtract(Duration(days: 1));
      final completedTask = testTask.copyWith(
        dueDate: pastDate,
        isCompleted: true,
      );
      expect(completedTask.isOverdue, false);
    });

    test('Should check if task is due today', () {
      final today = DateTime.now();
      final todayTask = testTask.copyWith(dueDate: today);
      expect(todayTask.isDueToday, true);
    });

    // test('Should check if task is due this week', () {
    //   final withinWeek = DateTime.now().add(Duration(seconds: 1, days: 3));
    //   final weekTask = testTask.copyWith(dueDate: withinWeek);
    //   expect(weekTask.isDueThisWeek, true);
    // });

    test('Should have correct priority color for urgent', () {
      final urgentTask = testTask.copyWith(priority: 'urgent');
      expect(urgentTask.priorityColor, '#FF3B30');
    });

    test('Should have correct priority color for high', () {
      final highTask = testTask.copyWith(priority: 'high');
      expect(highTask.priorityColor, '#FF9500');
    });

    test('Should have correct priority color for medium', () {
      final mediumTask = testTask.copyWith(priority: 'medium');
      expect(mediumTask.priorityColor, '#FFD900');
    });

    test('Should have correct priority color for low', () {
      final lowTask = testTask.copyWith(priority: 'low');
      expect(lowTask.priorityColor, '#58CC02');
    });


    test('Should handle task completion', () {
      expect(testTask.isCompleted, false);
      final completed = testTask.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
    });

    test('copyWith should work correctly', () {
      final updated = testTask.copyWith(
        title: 'New Title',
        isCompleted: true,
        priority: 'low',
      );
      expect(updated.title, 'New Title');
      expect(updated.isCompleted, true);
      expect(updated.priority, 'low');
      expect(updated.id, testTask.id);
    });

    test('Should support priority levels', () {
      final priorities = ['low', 'medium', 'high', 'urgent'];
      for (final priority in priorities) {
        final task = testTask.copyWith(priority: priority);
        expect(task.priority, priority);
      }
    });

    test('Should include description', () {
      expect(testTask.description, 'Finish the Nota application');
      final noDesc = testTask.copyWith(description: '');
      expect(noDesc.description, '');
    });
  });
}
