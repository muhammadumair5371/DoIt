import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/app_database.dart';
import '../data/repositories/task_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db);
});

final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks();
});

// Filter states
enum TaskFilter { all, today, upcoming, done }
enum TypeFilter { all, task, reminder, deadline, event }

final selectedFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final selectedTypeFilterProvider = StateProvider<TypeFilter>((ref) => TypeFilter.all);

// Filtered Tasks
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filter = ref.watch(selectedFilterProvider);
  final typeFilter = ref.watch(selectedTypeFilterProvider);

  return tasksAsync.when(
    data: (tasks) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Exclude tasks pending review from standard task list
      Iterable<Task> list = tasks.where((t) => !t.needsReview);

      // Type filter
      if (typeFilter != TypeFilter.all) {
        final typeName = typeFilter.name;
        list = list.where((t) => t.type.toLowerCase() == typeName);
      }

      // Time/Status filter
      switch (filter) {
        case TaskFilter.today:
          list = list.where((t) {
            if (t.isCompleted) return false;
            if (t.dueDate == null) return true; // Undated tasks show in Today
            return t.dueDate!.isAfter(todayStart.subtract(const Duration(days: 1))) &&
                t.dueDate!.isBefore(todayEnd.add(const Duration(days: 1)));
          });
          break;
        case TaskFilter.upcoming:
          list = list.where((t) {
            if (t.isCompleted) return false;
            if (t.dueDate == null) return false;
            return t.dueDate!.isAfter(todayEnd);
          });
          break;
        case TaskFilter.done:
          list = list.where((t) => t.isCompleted);
          break;
        case TaskFilter.all:
          list = list.where((t) => !t.isCompleted);
          break;
      }

      return list.toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Tasks that need review (confidence < 0.6)
final needsReviewTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  return tasksAsync.when(
    data: (tasks) => tasks.where((t) => t.needsReview && !t.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Stats for Hero Card
class TaskStats {
  final int totalToday;
  final int pendingToday;
  final int completedToday;
  final double completionPercentage;

  TaskStats({
    required this.totalToday,
    required this.pendingToday,
    required this.completedToday,
    required this.completionPercentage,
  });
}

final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final validTasks = tasks.where((t) => !t.needsReview).toList();

      final todayTasks = validTasks.where((t) {
        if (t.dueDate == null) return !t.isCompleted; // Undated pending tasks belong to today's focus
        return t.dueDate!.isAfter(todayStart.subtract(const Duration(days: 1))) &&
            t.dueDate!.isBefore(todayEnd);
      }).toList();

      final total = todayTasks.length;
      final completed = todayTasks.where((t) => t.isCompleted).length;
      final pending = total - completed;
      final percentage = total == 0 ? 1.0 : (completed / total).clamp(0.0, 1.0);

      return TaskStats(
        totalToday: total,
        pendingToday: pending,
        completedToday: completed,
        completionPercentage: percentage,
      );
    },
    loading: () => TaskStats(totalToday: 0, pendingToday: 0, completedToday: 0, completionPercentage: 0.0),
    error: (_, __) => TaskStats(totalToday: 0, pendingToday: 0, completedToday: 0, completionPercentage: 0.0),
  );
});
