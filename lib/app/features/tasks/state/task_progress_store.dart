// lib/app/features/tasks/state/task_progress_store.dart
// Stores local task completion states and exposes goal progress helpers.
// Exists to keep task status state reusable across journey and home screens.
// RELEVANT FILES:lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/tasks/presentation/widgets/task_tile.dart,lib/app/features/home/presentation/screens/home_screen.dart

import 'package:flutter/foundation.dart';

enum TaskCompletionStatus {
  notDone,
  partial,
  completed,
}

extension TaskCompletionStatusLabel on TaskCompletionStatus {
  String get label {
    switch (this) {
      case TaskCompletionStatus.completed:
        return 'Completed';
      case TaskCompletionStatus.partial:
        return 'Partial';
      case TaskCompletionStatus.notDone:
        return 'Not done';
    }
  }
}

class TaskProgressStore extends ChangeNotifier {
  TaskProgressStore._();

  static final TaskProgressStore instance = TaskProgressStore._();

  final Map<String, Map<int, List<String>>> _taskKeysByGoalDay = {};
  final Map<String, Map<int, Map<String, TaskCompletionStatus>>>
      _statusByGoalDay = {};

  void registerTasksForDay({
    required String goalId,
    required int dayIndex,
    required List<String> taskKeys,
    Set<String> completedKeys = const <String>{},
  }) {
    final keys = List<String>.from(taskKeys);
    final tasksByDay = _taskKeysByGoalDay.putIfAbsent(goalId, () => {});
    final statusByDay = _statusByGoalDay.putIfAbsent(goalId, () => {});
    final existingKeys = tasksByDay[dayIndex];
    var changed = false;

    if (existingKeys == null || !_listEquals(existingKeys, keys)) {
      tasksByDay[dayIndex] = keys;
      changed = true;
    }

    final statusMap = statusByDay.putIfAbsent(dayIndex, () => {});
    for (final key in keys) {
      if (!statusMap.containsKey(key)) {
        statusMap[key] = completedKeys.contains(key)
            ? TaskCompletionStatus.completed
            : TaskCompletionStatus.notDone;
        changed = true;
      }
    }

    final keysSet = keys.toSet();
    for (final key in List<String>.from(statusMap.keys)) {
      if (!keysSet.contains(key)) {
        statusMap.remove(key);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  TaskCompletionStatus statusFor({
    required String goalId,
    required int dayIndex,
    required String taskKey,
  }) {
    return _statusByGoalDay[goalId]?[dayIndex]?[taskKey] ??
        TaskCompletionStatus.notDone;
  }

  void setStatus({
    required String goalId,
    required int dayIndex,
    required String taskKey,
    required TaskCompletionStatus status,
  }) {
    final statusMap = _statusByGoalDay
        .putIfAbsent(goalId, () => {})
        .putIfAbsent(dayIndex, () => {});
    if (statusMap[taskKey] == status) {
      return;
    }
    statusMap[taskKey] = status;
    notifyListeners();
  }

  int completedDaysForGoal({
    required String goalId,
    required int totalDays,
  }) {
    if (totalDays <= 0) return 0;
    final tasksByDay = _taskKeysByGoalDay[goalId] ?? {};
    final statusByDay = _statusByGoalDay[goalId] ?? {};
    var completedDays = 0;

    for (var dayIndex = 0; dayIndex < totalDays; dayIndex++) {
      final keys = tasksByDay[dayIndex];
      if (keys == null || keys.isEmpty) {
        continue;
      }
      final statusMap = statusByDay[dayIndex] ?? {};
      final isComplete = keys.every(
        (key) => statusMap[key] == TaskCompletionStatus.completed,
      );
      if (isComplete) {
        completedDays += 1;
      }
    }

    return completedDays;
  }

  double progressForGoal({
    required String goalId,
    required int totalDays,
  }) {
    if (totalDays <= 0) return 0;
    final completedDays = completedDaysForGoal(
      goalId: goalId,
      totalDays: totalDays,
    );
    return (completedDays / totalDays).clamp(0, 1);
  }

  bool _listEquals(List<String> left, List<String> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
